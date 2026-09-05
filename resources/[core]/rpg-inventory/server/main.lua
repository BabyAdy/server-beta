-- ===========================================================================
--  rpg-inventory — server bootstrap: evenimente, exports (API), persistenta.
-- ===========================================================================

-- ----- ciclu de viata personaj ---------------------------------------
AddEventHandler('core:characterLoaded', function(src, charId)
    Inventory.loadCharacter(src, charId)
end)

AddEventHandler('playerDropped', function()
    local src = source
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    if okc and ch then
        Inventory.saveCharacter(ch.id, true)
    end
end)

-- ----- cereri de la client ------------------------------------------
RegisterNetEvent('rpg-inventory:request', function(action, reqId, payload)
    local src = source
    local okc, res = pcall(Inventory.handle, src, action, payload)
    if not okc then
        if Config.Debug then print('[rpg-inventory] handler error:', res) end
        res = { ok = false, error = 'Eroare internă.' }
    end
    TriggerClientEvent('rpg-inventory:result', src, reqId, res)
end)

-- scaderea durabilitatii la tras (apelat de weapon system-ul viitor)
RegisterNetEvent('rpg-inventory:weaponShot', function(slot, rounds)
    local src = source
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    if okc and ch then
        Inventory.damageDurability(ch.id, slot, rounds or 1)
    end
end)

-- ----- autosave ----------------------------------------------------
CreateThread(function()
    while true do
        Wait(Config.SaveInterval * 1000)
        Inventory.saveAllDirty()
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, c in pairs(Containers.all()) do
        if c.type == 'char' then Inventory.saveCharacter(c.ownerId, false) end
    end
end)

-- ===========================================================================
--  API public (folosibil de orice alta resursa)
--    exports['rpg-inventory']:Add(charId, 'water', 3)
-- ===========================================================================
exports('Get',         function(charId) return Inventory.snapshot(charId) end)
exports('Add',         function(charId, itemId, qty, meta) return Inventory.apiAdd(charId, itemId, qty, meta) end)
exports('Remove',      function(charId, itemId, qty) return Inventory.apiRemove(charId, itemId, qty) end)
exports('Has',         function(charId, itemId, qty) return Inventory.apiHas(charId, itemId, qty) end)
exports('Count',       function(charId, itemId) return Inventory.apiCount(charId, itemId) end)
exports('Move',        function(src, from, to, qty) return Inventory.move(src, from, to, qty) end)
exports('Use',         function(src, slot) return Inventory.use(src, slot) end)
exports('Drop',        function(src, slot, qty) return Inventory.drop(src, slot, qty) end)
exports('Give',        function(src, slot, qty, target) return Inventory.give(src, slot, qty, target) end)
exports('GetCapacity',  function(charId) return Inventory.capacity(charId) end)  -- total sloturi
exports('GetUsedSlots', function(charId) return Inventory.usedSlots(charId) end)
exports('GetFreeSlots', function(charId) return Inventory.freeSlots(charId) end)
exports('DamageDurability', function(charId, slot, amount) return Inventory.damageDurability(charId, slot, amount) end)

exports('RegisterItem', function(def)
    Items.register(def)
    for charId in pairs(Inventory.online) do Inventory.pushSync(charId) end
end)
exports('RegisterUsable', function(id, cb)
    Inventory.usables[id] = cb
end)

-- ===========================================================================
--  /giveitem [sql id] [item name] [count]   — staff >= manager
--  "sql id" = SQL id de PERSONAJ (ca la /setstaff), rezolvat prin rpg-characters.
--  Tinta trebuie sa fie ONLINE (inventarul trebuie incarcat in memorie).
--  Broadcast rosu catre staff (Staff.BROADCAST_COLOR).
-- ===========================================================================
local GIVEITEM_RANK      = 'manager'      -- cine poate folosi comanda
local GIVEITEM_BROADCAST = 'trialadmin'   -- cine vede mesajul pe chat

local function giFeedback(src, text)
    if src <= 0 then return print('[rpg-inventory] ' .. text) end
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = 'INVENTORY', text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 190, 130, 255 }, args = { 'INVENTORY', text } })
    end
end

local function giIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local name = GetPlayerName(src) or ('src' .. src)
    local oka, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    if oka and acc and acc.username then name = acc.username end
    local label = 'Staff'
    local okl, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if okl and l and l ~= '' then label = l end
    return name, label
end

local function giStaffBroadcast(text)
    local color = (Staff and Staff.BROADCAST_COLOR) or '#ff5555'
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, GIVEITEM_BROADCAST) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = color, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-inventory][staff] %s'):format(text))
end

RegisterCommand('giveitem', function(src, args)
    if src > 0 then
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, GIVEITEM_RANK) end)
        if not (ok and allowed == true) then
            return giFeedback(src, 'Nu ai acces la această comandă.')
        end
    end

    local charId = tonumber(args[1])
    local itemId = args[2]
    local count  = tonumber(args[3]) or 1
    if not charId or not itemId then
        return giFeedback(src, 'Folosire: /giveitem [sql id] [item name] [count]')
    end
    count = math.floor(count)
    if count < 1 then return giFeedback(src, 'Count invalid.') end
    if not Items.get(itemId) then
        return giFeedback(src, ('Item necunoscut: %s'):format(itemId))
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return giFeedback(src, 'SQL id inexistent.') end
    if not target.src then
        return giFeedback(src, 'Personajul nu este online (inventarul nu e încărcat).')
    end

    local added, why = Inventory.apiAdd(charId, itemId, count)
    if not added then
        return giFeedback(src, ('Nu s-a putut adăuga itemul (%s).'):format(tostring(why or 'eroare')))
    end

    local issuerName, issuerLabel = giIssuer(src)
    local targetName = target.username or ('#' .. charId)

    giFeedback(src, ('Ai dat %s x%d lui %s [%s].'):format(itemId, count, targetName, charId))
    if target.src then
        giFeedback(target.src, ('Ai primit %s x%d de la staff.'):format(itemId, count))
    end
    giStaffBroadcast(('Staff: %s %s gived to  %s [%s], item %s x%d.')
        :format(issuerLabel, issuerName, targetName, charId, itemId, count))

    print(('[rpg-inventory] /giveitem: %s(#%s) -> char #%s : %s x%d')
        :format(issuerName, src, charId, itemId, count))
end, false)
