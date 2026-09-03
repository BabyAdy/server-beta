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
--  TEST — /giveitem <id> [qty]   (necesita ACE: ph.admin sau command.giveitem)
-- ===========================================================================
RegisterCommand('giveitem', function(src, args)
    if src > 0 and not (IsPlayerAceAllowed(src, 'ph.admin') or IsPlayerAceAllowed(src, 'command.giveitem')) then
        return
    end
    local target = src
    local itemId = args[1]
    local qty = tonumber(args[2]) or 1
    if not itemId or not Items.get(itemId) then
        print('[rpg-inventory] giveitem: item necunoscut: ' .. tostring(itemId))
        return
    end
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(target) end)
    if not okc or not ch then return end
    local added = Inventory.apiAdd(ch.id, itemId, qty)
    print(('[rpg-inventory] giveitem %s x%d -> char #%s : %s'):format(itemId, qty, ch.id, tostring(added)))
end, false)
