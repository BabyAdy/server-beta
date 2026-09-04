-- ===========================================================================
--  rpg-inventory — nucleul logic (server-authoritative)
--
--  Clientul CERE actiuni. Serverul valideaza, aplica, salveaza, si trimite
--  inapoi noul inventar. Clientul nu creeaza / nu duplica / nu decide nimic.
-- ===========================================================================

Inventory = {}
Inventory.online  = {}   -- [charId] = src
Inventory.usables = {}   -- [itemId] = function(src, charId, item) -> false ca sa NU consume

local C   = Containers
local V   = Validation
local DBG = Config.Debug

-- ---- utilitare interne ------------------------------------------------
local rowSeq = 0
local function rid()
    rowSeq = rowSeq + 1
    return ('r%d'):format(rowSeq)
end

local uidSeq = 0
local function uid()
    uidSeq = uidSeq + 1
    return ('%d_%d'):format(os.time(), uidSeq)
end

local function ok(extra)
    local r = { ok = true }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    return r
end
local function err(msg)
    return { ok = false, error = msg or 'Actiune invalida.' }
end

local function deepcopy(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = deepcopy(v) end
    return o
end

local function defOf(itemId) return Items.get(itemId) end

local function charOf(src)
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    return (okc and ch) and ch.id or nil
end

local function srcOfChar(charId)
    return Inventory.online[charId]
end

local function playerPos(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local v = GetEntityCoords(ped)
    return { x = v.x, y = v.y, z = v.z }
end

-- ---- greutate / capacitate ------------------------------------------
local function weightOf(container)
    local w = 0.0
    for _, it in pairs(container.items) do
        local d = defOf(it.itemId)
        if d then w = w + d.weight * it.quantity end
    end
    return w
end

local function round1(n) return math.floor(n * 10 + 0.5) / 10 end

-- ---- cautare in container ------------------------------------------
local function bySlot(container, slot)
    for _, it in pairs(container.items) do
        if it.slot == slot then return it end
    end
    return nil
end

local function freeGridSlot(container)
    local used = {}
    for _, it in pairs(container.items) do
        if type(it.slot) == 'number' then used[it.slot] = true end
    end
    for s = 1, container.slots do
        if not used[s] then return s end
    end
    return nil
end

-- ---- proiectie pentru NUI ----------------------------------------
local function view(it)
    local d = defOf(it.itemId) or { label = it.itemId, category = 'misc', weight = 0, maxStack = 1, stats = {} }
    local md = it.metadata or {}
    local durability = md.durability
    return {
        rowId        = it.id,
        itemId       = it.itemId,
        slot         = it.slot,
        label        = d.label,
        category     = d.category,
        quantity     = it.quantity,
        weight       = d.weight,
        totalWeight  = round1(d.weight * it.quantity),
        icon         = d.icon,
        stackable    = d.stackable == true,
        maxStack     = d.maxStack,
        usable       = d.usable == true,
        equipable    = d.equipable == true,
        equipSlot    = d.equipSlot,
        durable      = d.durable == true,
        durability   = durability,
        maxDurability = d.maxDurability,
        broken       = (d.durable and durability ~= nil and durability <= 0) or false,
        equipped     = md.equipped == true,
        stats        = d.stats,
        metadata     = md,
        context      = Items.contextFor(it.itemId, it),
    }
end

function Inventory.snapshot(charId)
    local c = C.character(charId)
    if not c then return nil end
    local grid, equipment = {}, {}
    for _, it in pairs(c.items) do
        if type(it.slot) == 'number' then
            grid[tostring(it.slot)] = view(it)
        elseif type(it.slot) == 'string' then
            equipment[it.slot] = view(it)
        end
    end
    local fast = {}
    for i = 1, Config.FastSlotCount do fast[tostring(i)] = c.fastSlots[i] or false end

    local used = 0
    for _, it in pairs(c.items) do
        if type(it.slot) == 'number' then used = used + 1 end
    end

    return {
        container   = c.id,
        slots       = c.slots,   -- capacitate totala (sloturi)
        used        = used,      -- sloturi ocupate
        grid        = grid,
        equipment   = equipment,
        fastSlots   = fast,
        definitions = Items.defs,
    }
end

function Inventory.nearbySnapshot(src)
    local pos = playerPos(src)
    local items = {}
    if pos then
        for _, gc in ipairs(C.groundNear(pos, Config.DropRadius + 0.25)) do
            for _, it in pairs(gc.items) do
                local v = view(it)
                v.container = gc.id
                items[#items + 1] = v
            end
        end
    end
    return { items = items, radius = Config.DropRadius, slots = Config.NearbySlots }
end

-- ---- push catre client(i) ----------------------------------------
function Inventory.pushSync(charId)
    local src = srcOfChar(charId)
    if src then
        TriggerClientEvent('rpg-inventory:sync', src, Inventory.snapshot(charId))
    end
end

function Inventory.pushNearby(src)
    if src then
        TriggerClientEvent('rpg-inventory:nearby', src, Inventory.nearbySnapshot(src))
    end
end

-- reimprospateaza "nearby" pentru toti jucatorii aproape de o pozitie
local function refreshNearbyAround(pos)
    for _, pid in ipairs(GetPlayers()) do
        local s = tonumber(pid)
        local pp = playerPos(s)
        if pp and V.distance(pp, pos, Config.DropRadius + 6.0) then
            Inventory.pushNearby(s)
        end
    end
end

local function markDirty(container)
    if container.type == 'char' then container.dirty = true end
end

-- ---- rezolvarea unei referinte de container ---------------------
-- ref.container: 'char:<id>' | 'ground:<uid>' | 'drop' (sentinel: pila noua la picioare)
local function resolveContainer(src, containerId, allowDrop)
    if containerId == 'drop' then
        if not allowDrop then return nil, 'Destinatie invalida.' end
        local pos = playerPos(src)
        if not pos then return nil, 'Pozitie invalida.' end
        -- contopeste cu o pila existenta din raza mica
        for _, gc in ipairs(C.groundNear(pos, Config.GroundMergeRadius)) do
            return gc
        end
        local c = C.register({
            id = 'ground:' .. uid(), type = 'ground', ownerId = 'ground',
            maxWeight = nil, slots = Config.NearbySlots,
            pos = pos, items = {}, dirty = false,
        })
        return c
    end

    local c = C.get(containerId)
    if not c then return nil, 'Container inexistent.' end
    if not C.canAccess(src, c, playerPos(src)) then
        return nil, 'Acces refuzat sau prea departe.'
    end
    return c
end

-- ===========================================================================
--  MOVE — operatia universala (slot<->slot, slot<->equip, slot<->nearby,
--  nearby<->slot, slot<->drop). Stack / split / swap incluse.
-- ===========================================================================
function Inventory.move(src, from, to, quantity)
    if type(from) ~= 'table' or type(to) ~= 'table' then return err() end

    local sC, sErr = resolveContainer(src, from.container)
    if not sC then return err(sErr) end
    local dC, dErr = resolveContainer(src, to.container, true)
    if not dC then return err(dErr) end

    -- item sursa
    local srcItem = from.rowId and sC.items[from.rowId] or bySlot(sC, from.slot)
    if not srcItem then return err('Articolul nu mai există.') end
    local d = defOf(srcItem.itemId)
    if not d then return err('Item necunoscut.') end

    -- cantitate
    local moveQty = quantity and V.quantity(quantity, srcItem.quantity) or srcItem.quantity
    if not moveQty then return err('Cantitate invalidă.') end

    -- slot destinatie
    local destSlot = to.slot
    if type(destSlot) == 'string' and V.isEquipKey(destSlot) then
        if dC.type ~= 'char' then return err('Slot invalid.') end
        if not V.canEquip(destSlot, d) then return err('Articol incompatibil cu slotul.') end
        if moveQty ~= srcItem.quantity or srcItem.quantity ~= 1 then
            return err('Poți echipa o singură bucată.')
        end
    elseif destSlot ~= nil and not V.gridSlot(destSlot) then
        if type(destSlot) ~= 'number' or destSlot < 1 or destSlot > dC.slots then
            return err('Slot invalid.')
        end
    end
    if destSlot == nil then
        destSlot = freeGridSlot(dC)
        if not destSlot then return err('Nu e loc liber în destinație.') end
    end

    -- no-op
    if sC == dC and srcItem.slot == destSlot then return ok() end

    local destItem = bySlot(dC, destSlot)

    -- capacitatea e pe sloturi: daca s-a ajuns aici cu un destSlot valid,
    -- fie e liber (freeGridSlot a gasit loc), fie il vom contopi / interschimba.

    if destItem then
        -- contopire in stack
        if destItem.itemId == srcItem.itemId and V.stackCompatible(d, srcItem, destItem) then
            local space = d.maxStack - destItem.quantity
            if space <= 0 then return err('Stack-ul destinație e plin.') end
            local put = math.min(space, moveQty)
            destItem.quantity = destItem.quantity + put
            srcItem.quantity  = srcItem.quantity - put
            if srcItem.quantity <= 0 then sC.items[srcItem.id] = nil end
        else
            -- swap (doar mutare completa)
            if moveQty ~= srcItem.quantity then return err('Slotul e ocupat.') end
            -- daca sursa e slot de echipament, itemul mutat inapoi trebuie compatibil
            if type(srcItem.slot) == 'string' and V.isEquipKey(srcItem.slot) then
                local dd = defOf(destItem.itemId)
                if not V.canEquip(srcItem.slot, dd) then return err('Nu se poate schimba în slotul de echipament.') end
            end
            local sSlot = srcItem.slot
            srcItem.slot  = destSlot
            destItem.slot = sSlot
            if sC ~= dC then
                sC.items[srcItem.id]  = nil
                dC.items[srcItem.id]  = srcItem
                dC.items[destItem.id] = nil
                sC.items[destItem.id] = destItem
            end
        end
    else
        if moveQty == srcItem.quantity then
            srcItem.slot = destSlot
            if sC ~= dC then
                sC.items[srcItem.id] = nil
                dC.items[srcItem.id] = srcItem
            end
        else
            -- split
            srcItem.quantity = srcItem.quantity - moveQty
            local nw = {
                id = rid(), itemId = srcItem.itemId, slot = destSlot,
                quantity = moveQty, metadata = deepcopy(srcItem.metadata) or {},
            }
            dC.items[nw.id] = nw
        end
    end

    -- starea "equipped" dupa mutarea in / din echipament
    Inventory._syncEquippedFlags(src, sC)
    if sC ~= dC then Inventory._syncEquippedFlags(src, dC) end

    markDirty(sC); markDirty(dC)
    Inventory._afterChange(src, sC, dC)
    return ok()
end

-- marcheaza itemele din sloturile de echipament ca equipped, restul nu
function Inventory._syncEquippedFlags(src, container)
    if container.type ~= 'char' then return end
    for _, it in pairs(container.items) do
        local isEquip = type(it.slot) == 'string' and V.isEquipKey(it.slot)
        it.metadata = it.metadata or {}
        if isEquip and not it.metadata.equipped then
            it.metadata.equipped = true
            TriggerEvent('rpg-inventory:equipped', src, container.ownerId, it.slot, view(it))
        elseif not isEquip and it.metadata.equipped then
            it.metadata.equipped = nil
            TriggerEvent('rpg-inventory:unequipped', src, container.ownerId, it.itemId, view(it))
        end
    end
end

function Inventory._afterChange(src, sC, dC)
    local groundTouched
    for _, cont in ipairs({ sC, dC }) do
        if cont.type == 'char' then
            Inventory.pushSync(cont.ownerId)
        elseif cont.type == 'ground' then
            groundTouched = cont
            if C.isEmpty(cont) then C.unregister(cont.id) end
        end
    end
    if groundTouched and groundTouched.pos then
        refreshNearbyAround(groundTouched.pos)
    end
end

-- ===========================================================================
--  USE / EQUIP / DROP / GIVE / SPLIT / FAST SLOTS
-- ===========================================================================
function Inventory.use(src, slot)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    local it = bySlot(c, V.gridSlot(slot) and tonumber(slot) or slot)
    if not it then return err('Slot gol.') end
    local d = defOf(it.itemId)
    if not d or not d.usable then return err('Articol neutilizabil.') end
    if d.durable then
        local cur = it.metadata and it.metadata.durability or d.maxDurability
        if cur ~= nil and cur <= 0 then return err('Articol stricat.') end
    end

    local consume = true
    local cb = Inventory.usables[it.itemId]
    if cb then
        local okc, res = pcall(cb, src, charId, view(it))
        if okc and res == false then consume = false end
    end
    TriggerEvent('rpg-inventory:used', src, charId, it.itemId, it.metadata or {})

    if d.durable then
        it.metadata = it.metadata or {}
        local cur = it.metadata.durability ~= nil and it.metadata.durability or d.maxDurability
        it.metadata.durability = math.max(0, cur - 1)
    elseif consume and d.category == 'consumable' then
        it.quantity = it.quantity - 1
        if it.quantity <= 0 then c.items[it.id] = nil end
    end

    markDirty(c); Inventory.pushSync(charId)
    return ok()
end

-- scade durabilitatea (folosit de weapon system la fiecare glont tras)
function Inventory.damageDurability(charId, slot, amount)
    local c = C.character(charId); if not c then return false end
    local it = bySlot(c, tonumber(slot) or slot); if not it then return false end
    local d = defOf(it.itemId); if not d or not d.durable then return false end
    it.metadata = it.metadata or {}
    local cur = it.metadata.durability ~= nil and it.metadata.durability or d.maxDurability
    it.metadata.durability = math.max(0, cur - (tonumber(amount) or 1))
    markDirty(c); Inventory.pushSync(charId)
    return true
end

function Inventory.equip(src, slot)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    local it = bySlot(c, tonumber(slot) or slot)
    if not it then return err('Slot gol.') end
    local d = defOf(it.itemId)
    if not d then return err('Item necunoscut.') end

    if d.category == 'weapon' then
        local willEquip = not it.metadata.equipped
        if willEquip then
            -- rpg-licences: fara weapon_licence_hours > 0 nu poti ECHIPA o arma.
            -- fail-open daca resursa lipseste/e oprita (nu blocam gameplay-ul din cauza unei dependinte).
            local licOk = true
            pcall(function() licOk = exports['rpg-licences']:hasWeaponLicence(src) end)
            if not licOk then return err('Ai nevoie de licență de arme pentru a echipa asta.') end
        end
        it.metadata = it.metadata or {}
        it.metadata.equipped = willEquip and true or nil
        TriggerEvent(it.metadata.equipped and 'rpg-inventory:equipWeapon' or 'rpg-inventory:unequipWeapon',
            src, charId, it.itemId, view(it))
        markDirty(c); Inventory.pushSync(charId)
        return ok()
    end

    if not d.equipSlot then return err('Articol neechipabil.') end
    return Inventory.move(src,
        { container = c.id, slot = tonumber(slot) or slot },
        { container = c.id, slot = d.equipSlot }, 1)
end

function Inventory.unequip(src, slotKey)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    if not V.isEquipKey(slotKey) then return err('Slot invalid.') end
    local it = bySlot(c, slotKey)
    if not it then return err('Slotul e gol.') end
    local free = freeGridSlot(c)
    if not free then return err('Nu e loc în inventar.') end
    return Inventory.move(src,
        { container = c.id, slot = slotKey },
        { container = c.id, slot = free }, 1)
end

function Inventory.drop(src, slot, quantity)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    local target = V.gridSlot(slot) and tonumber(slot) or slot
    return Inventory.move(src,
        { container = c.id, slot = target },
        { container = 'drop' }, quantity)
end

function Inventory.give(src, slot, quantity, targetSrc)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or targetSrc == src then return err('Țintă invalidă.') end

    local sp, tp = playerPos(src), playerPos(targetSrc)
    if not sp or not tp or not V.distance(sp, tp, Config.GiveRadius) then
        return err('Jucătorul e prea departe.')
    end
    local tChar = charOf(targetSrc)
    if not tChar then return err('Ținta nu are personaj.') end
    if not C.character(tChar) then return err('Inventarul țintei nu e încărcat.') end

    local sc = C.character(charId)
    return Inventory.move(src,
        { container = sc.id, slot = (V.gridSlot(slot) and tonumber(slot) or slot) },
        { container = C.character(tChar).id }, quantity)
end

-- ---- fast slots ------------------------------------------------------
function Inventory.bindFast(src, index, gridSlot)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    index = tonumber(index)
    if not index or index < 1 or index > Config.FastSlotCount then return err('Index invalid.') end
    if gridSlot ~= nil and gridSlot ~= false then
        if not V.gridSlot(gridSlot) then return err('Slot invalid.') end
        c.fastSlots[index] = tonumber(gridSlot)
    else
        c.fastSlots[index] = false
    end
    markDirty(c); Inventory.pushSync(charId)
    return ok()
end

function Inventory.useFast(src, index)
    local charId = charOf(src); if not charId then return err('Fără personaj.') end
    local c = C.character(charId); if not c then return err('Inventar neîncărcat.') end
    index = tonumber(index)
    local gs = index and c.fastSlots[index]
    if not gs then return err('Slot rapid gol.') end
    local it = bySlot(c, gs)
    if not it then return err('Nimic pe slotul rapid.') end
    local d = defOf(it.itemId)
    if d and d.equipSlot then
        return Inventory.equip(src, gs)
    end
    return Inventory.use(src, gs)
end

-- ===========================================================================
--  API pentru alte resurse (prin exports in server/main.lua)
-- ===========================================================================
function Inventory.ensureLoaded(charId)
    return C.character(charId) ~= nil
end

function Inventory.apiHas(charId, itemId, qty)
    local c = C.character(charId); if not c then return false end
    local total = 0
    for _, it in pairs(c.items) do
        if it.itemId == itemId then total = total + it.quantity end
    end
    return total >= (tonumber(qty) or 1)
end

function Inventory.apiCount(charId, itemId)
    local c = C.character(charId); if not c then return 0 end
    local total = 0
    for _, it in pairs(c.items) do
        if it.itemId == itemId then total = total + it.quantity end
    end
    return total
end

function Inventory.apiAdd(charId, itemId, qty, metadata)
    local c = C.character(charId); if not c then return false, 'no-inventory' end
    local d = defOf(itemId); if not d then return false, 'unknown-item' end
    qty = tonumber(qty) or 1
    if qty < 1 then return false, 'bad-qty' end

    -- completeaza stack-uri existente
    if d.stackable and not metadata then
        for _, it in pairs(c.items) do
            if it.itemId == itemId and type(it.slot) == 'number'
               and V.stackCompatible(d, it, { metadata = {} }) then
                local space = d.maxStack - it.quantity
                if space > 0 then
                    local put = math.min(space, qty)
                    it.quantity = it.quantity + put
                    qty = qty - put
                    if qty <= 0 then break end
                end
            end
        end
    end

    while qty > 0 do
        local slot = freeGridSlot(c)
        if not slot then
            markDirty(c); Inventory.pushSync(charId)
            return false, 'no-space'
        end
        local put = math.min(d.maxStack, qty)
        local id = rid()
        c.items[id] = {
            id = id, itemId = itemId, slot = slot, quantity = put,
            metadata = Items.freshMetadata(itemId, metadata),
        }
        qty = qty - put
    end

    markDirty(c); Inventory.pushSync(charId)
    return true
end

function Inventory.apiRemove(charId, itemId, qty)
    local c = C.character(charId); if not c then return false end
    qty = tonumber(qty) or 1
    if not Inventory.apiHas(charId, itemId, qty) then return false end
    for _, it in pairs(c.items) do
        if it.itemId == itemId and qty > 0 then
            local take = math.min(it.quantity, qty)
            it.quantity = it.quantity - take
            qty = qty - take
            if it.quantity <= 0 then c.items[it.id] = nil end
        end
    end
    markDirty(c); Inventory.pushSync(charId)
    return true
end

function Inventory.usedSlots(charId)
    local c = C.character(charId)
    if not c then return 0 end
    local n = 0
    for _, it in pairs(c.items) do
        if type(it.slot) == 'number' then n = n + 1 end
    end
    return n
end

function Inventory.capacity(charId)
    local c = C.character(charId)
    return c and c.slots or Config.GridSlots
end

function Inventory.freeSlots(charId)
    local c = C.character(charId)
    if not c then return 0 end
    return c.slots - Inventory.usedSlots(charId)
end

-- ===========================================================================
--  DISPATCH cereri client
-- ===========================================================================
local HANDLERS = {
    open = function(src)
        local charId = charOf(src); if not charId then return err('Fără personaj.') end
        if not C.character(charId) then return err('Inventar neîncărcat.') end
        Inventory.online[charId] = src
        Inventory.pushSync(charId)
        Inventory.pushNearby(src)
        return ok()
    end,
    close = function() return ok() end,
    scanNearby = function(src) Inventory.pushNearby(src); return ok() end,
    move   = function(src, p) return Inventory.move(src, p.from, p.to, p.quantity) end,
    split  = function(src, p) return Inventory.move(src, p.from, p.to, p.quantity) end,
    use    = function(src, p) return Inventory.use(src, p.slot) end,
    equip  = function(src, p) return Inventory.equip(src, p.slot) end,
    unequip = function(src, p) return Inventory.unequip(src, p.slot) end,
    drop   = function(src, p) return Inventory.drop(src, p.slot, p.quantity) end,
    give   = function(src, p) return Inventory.give(src, p.slot, p.quantity, p.target) end,
    bindFast = function(src, p) return Inventory.bindFast(src, p.index, p.slot) end,
    useFast  = function(src, p) return Inventory.useFast(src, p.index) end,
    inspect  = function(src, p)
        TriggerEvent('rpg-inventory:inspect', src, charOf(src), p and p.slot)
        return ok()
    end,
}

function Inventory.handle(src, action, payload)
    local h = HANDLERS[action]
    if not h then return err('Acțiune necunoscută.') end
    return h(src, payload or {})
end

-- ===========================================================================
--  PERSISTENTA
-- ===========================================================================
function Inventory.loadCharacter(src, charId)
    Inventory.online[charId] = src
    local id = C.key('char', charId)

    if C.get(id) then
        Inventory.pushSync(charId)
        Inventory.pushNearby(src)
        return
    end

    local row = MySQL.single.await(
        'SELECT slots, fast_slots FROM inventories WHERE id = ?', { id })

    if not row then
        MySQL.insert.await(
            'INSERT INTO inventories (id, owner_type, owner_id, slots, fast_slots) VALUES (?, ?, ?, ?, ?)',
            { id, 'character', tostring(charId), Config.GridSlots, json.encode({}) })
        row = { slots = Config.GridSlots, fast_slots = '{}' }
    end

    local c = C.register({
        id = id, type = 'char', ownerId = charId,
        slots = tonumber(row.slots) or Config.GridSlots,
        items = {}, fastSlots = {}, dirty = false,
    })
    for i = 1, Config.FastSlotCount do c.fastSlots[i] = false end
    local fs = row.fast_slots and json.decode(row.fast_slots) or {}
    for k, v in pairs(fs) do
        local i = tonumber(k)
        if i and v then c.fastSlots[i] = tonumber(v) or false end
    end

    local rows = MySQL.query.await(
        'SELECT item_id, slot, quantity, metadata FROM inventory_items WHERE inventory_id = ?', { id }) or {}
    for _, r in ipairs(rows) do
        if defOf(r.item_id) then
            local slot = tonumber(r.slot) or r.slot
            local newId = rid()
            c.items[newId] = {
                id = newId, itemId = r.item_id, slot = slot,
                quantity = tonumber(r.quantity) or 1,
                metadata = (r.metadata and json.decode(r.metadata)) or {},
            }
        end
    end

    if DBG then print(('[rpg-inventory] Incarcat inventar char #%s (%d iteme)'):format(charId, #rows)) end
    Inventory.pushSync(charId)
    Inventory.pushNearby(src)
end

function Inventory.saveCharacter(charId, dropCache)
    local c = C.character(charId)
    if not c then return end

    local fs = {}
    for i = 1, Config.FastSlotCount do
        if c.fastSlots[i] then fs[tostring(i)] = c.fastSlots[i] end
    end
    MySQL.update.await('UPDATE inventories SET fast_slots = ?, updated_at = NOW() WHERE id = ?',
        { json.encode(fs), c.id })

    MySQL.update.await('DELETE FROM inventory_items WHERE inventory_id = ?', { c.id })
    local params = {}
    for _, it in pairs(c.items) do
        params[#params + 1] = { c.id, it.itemId, tostring(it.slot), it.quantity, json.encode(it.metadata or {}) }
    end
    if #params > 0 then
        MySQL.prepare.await(
            'INSERT INTO inventory_items (inventory_id, item_id, slot, quantity, metadata) VALUES (?, ?, ?, ?, ?)',
            params)
    end

    c.dirty = false
    if dropCache then
        C.unregister(c.id)
        Inventory.online[charId] = nil
    end
    if DBG then print(('[rpg-inventory] Salvat inventar char #%s'):format(charId)) end
end

function Inventory.saveAllDirty()
    for _, c in pairs(C.all()) do
        if c.type == 'char' and c.dirty then
            Inventory.saveCharacter(c.ownerId, false)
        end
    end
end
