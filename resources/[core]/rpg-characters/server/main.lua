-- ===========================================================================
--  rpg-characters — server
--  Flux:
--    rpg-auth  -> core:playerLoggedIn(src, accountId, username)
--       are personaj  -> rpg-characters:spawn
--       nu are        -> routing bucket privat + rpg-characters:openCreator
--    client confirma  -> rpg-characters:create -> INSERT -> spawn
-- ===========================================================================

local chars = {}   -- [src] = { accountId, username, id?, creating? }

local function bucketFor(src)
    return Config.Creator.bucketBase + src
end

local function spawnPayload(row)
    local pos
    if row and row.position then
        local ok, decoded = pcall(json.decode, row.position)
        if ok then pos = decoded end
    end
    if not pos then
        local s = Config.SpawnAfterCreate
        pos = { x = s.x, y = s.y, z = s.z, h = s.w }
    end
    return pos
end

-- ----- intrare in flux (dupa login) --------------------------------------
AddEventHandler('core:playerLoggedIn', function(src, accountId, username)
    local row = MySQL.single.await(
        'SELECT id, appearance, position FROM characters WHERE account_id = ? LIMIT 1',
        { accountId }
    )

    if row then
        chars[src] = { accountId = accountId, username = username, id = row.id }
        SetPlayerRoutingBucket(src, 0)

        local appearance = json.decode(row.appearance)
        TriggerClientEvent('rpg-characters:spawn', src, appearance, spawnPayload(row))
        TriggerEvent('core:characterLoaded', src, row.id, username)
    else
        chars[src] = { accountId = accountId, username = username, creating = true }
        SetPlayerRoutingBucket(src, bucketFor(src))
        TriggerClientEvent('rpg-characters:openCreator', src, username)
    end
end)

-- ----- creare personaj -------------------------------------------------
RegisterNetEvent('rpg-characters:create', function(payload)
    local src = source
    local c = chars[src]
    if not c or not c.creating then return end

    local appearance = Appearance.sanitize(payload)
    if not appearance then
        return TriggerClientEvent('rpg-characters:createResult', src, false, 'Date de aspect invalide.')
    end

    -- protectie dubla creare / race
    if MySQL.scalar.await('SELECT 1 FROM characters WHERE account_id = ? LIMIT 1', { c.accountId }) then
        c.creating = nil
        return TriggerClientEvent('rpg-characters:createResult', src, false, 'Ai deja un personaj.')
    end

    local s = Config.SpawnAfterCreate
    local pos = { x = s.x, y = s.y, z = s.z, h = s.w }

    local id = MySQL.insert.await(
        'INSERT INTO characters (account_id, username, appearance, position) VALUES (?, ?, ?, ?)',
        { c.accountId, c.username, json.encode(appearance), json.encode(pos) }
    )

    if not id then
        return TriggerClientEvent('rpg-characters:createResult', src, false, 'Eroare la salvare. Incearca din nou.')
    end

    c.id = id
    c.creating = nil
    SetPlayerRoutingBucket(src, 0)

    TriggerClientEvent('rpg-characters:createResult', src, true)
    TriggerClientEvent('rpg-characters:spawn', src, appearance, pos)
    TriggerEvent('core:characterLoaded', src, id, c.username)

    print(('[rpg-characters] Personaj #%d creat pentru cont #%d (%s)'):format(id, c.accountId, c.username))
end)

-- ----- confirmarea ca playerul a intrat efectiv in lume ------------------
RegisterNetEvent('rpg-characters:spawned', function()
    SetPlayerRoutingBucket(source, 0)
end)

-- ----- salvare aspect ulterioara (ex. viitor frizer/chirurgie) ----------
RegisterNetEvent('rpg-characters:saveAppearance', function(payload)
    local src = source
    local c = chars[src]
    if not c or not c.id then return end
    local appearance = Appearance.sanitize(payload)
    if not appearance then return end
    MySQL.update.await('UPDATE characters SET appearance = ? WHERE id = ?', { json.encode(appearance), c.id })
end)

AddEventHandler('playerDropped', function()
    chars[source] = nil
end)

-- ----- exports -----------------------------------------------------------
exports('getCharacter', function(src)
    return chars[src]
end)

exports('hasCharacter', function(src)
    local c = chars[src]
    return c ~= nil and c.id ~= nil
end)
