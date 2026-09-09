-- ===========================================================================
--  rpg-doors — SERVER (autoritatea starii de incuiere)
--
--  Serverul detine lista de usi + starea locked. O trimite TUTUROR clientilor
--  (TriggerClientEvent -1), indiferent de routing bucket -> incuietoarea se
--  aplica in toate lumile virtuale. Nu se deseneaza niciun text / lacat in
--  lume; starea se vede doar in meniul NUI (/doors).
-- ===========================================================================

local DBG   = Config.Debug
local Doors = {}   -- [id] = { id, label, model, x, y, z, heading, locked }

local function log(...) if DBG then print('[rpg-doors]', ...) end end

local function isManager(src)
    if src == 0 then return true end
    local ok, allowed = pcall(function()
        return exports['rpg-auth']:hasStaffLevel(src, Config.ManageRank)
    end)
    return ok and allowed == true
end

local function accountId(src)
    local ok, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and acc and acc.id) or nil
end

-- ---- schema ------------------------------------------------------------
local function ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/rpg_doors.sql')
    if not sql then return end
    for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
        local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
        if s ~= '' then MySQL.query.await(s) end
    end
    log('schema OK')
end

local function rowToDoor(r)
    return {
        id      = tonumber(r.id),
        label   = r.label or 'Usa',
        model   = tonumber(r.model),
        x       = tonumber(r.x) + 0.0,
        y       = tonumber(r.y) + 0.0,
        z       = tonumber(r.z) + 0.0,
        heading = tonumber(r.heading) + 0.0,
        locked  = (tonumber(r.locked) or 0) ~= 0,
    }
end

local function loadAll()
    Doors = {}
    local rows = MySQL.query.await('SELECT * FROM doors') or {}
    for _, r in ipairs(rows) do
        local d = rowToDoor(r)
        if d.id and d.model then Doors[d.id] = d end
    end
    log(('%d usi incarcate'):format(#rows))
end

local function listPayload()
    local out = {}
    for _, d in pairs(Doors) do out[#out + 1] = d end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function syncAll(target)
    TriggerClientEvent('rpg-doors:sync', target or -1, listPayload())
end

-- ---- boot ------------------------------------------------------------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(500)
    ensureSchema()
    loadAll()
    syncAll(-1)
    log('gata')
end)

AddEventHandler('core:characterLoaded', function(src)
    TriggerClientEvent('rpg-doors:sync', src, listPayload())
end)

RegisterNetEvent('rpg-doors:requestList', function()
    TriggerClientEvent('rpg-doors:sync', source, listPayload())
end)

-- ---- CRUD (staff-gated) --------------------------------------------
RegisterNetEvent('rpg-doors:add', function(payload)
    local src = source
    if not isManager(src) then return end
    if type(payload) ~= 'table' then return end

    local model = tonumber(payload.model)
    local x, y, z = tonumber(payload.x), tonumber(payload.y), tonumber(payload.z)
    if not model or not x or not y or not z then return end
    local heading = tonumber(payload.heading) or 0.0
    local label = tostring(payload.label or 'Usa')
    label = label:gsub('%s+$', ''):sub(1, 64)
    if label == '' then label = 'Usa' end

    local id = MySQL.insert.await(
        'INSERT INTO doors (label, model, x, y, z, heading, locked, created_by) VALUES (?, ?, ?, ?, ?, ?, 1, ?)',
        { label, model, x, y, z, heading, accountId(src) })
    if not id then return end

    Doors[id] = {
        id = id, label = label, model = model,
        x = x + 0.0, y = y + 0.0, z = z + 0.0, heading = heading + 0.0, locked = true,
    }
    syncAll(-1)
    TriggerClientEvent('rpg-doors:toast', src, ('Usa "%s" (#%d) adaugata si incuiata.'):format(label, id))
    log(('src %s a adaugat usa #%d "%s" model %s'):format(src, id, label, model))
end)

RegisterNetEvent('rpg-doors:setLocked', function(id, locked)
    local src = source
    if not isManager(src) then return end
    id = tonumber(id)
    local d = id and Doors[id]
    if not d then return end
    d.locked = locked == true
    MySQL.update.await('UPDATE doors SET locked = ? WHERE id = ?', { d.locked and 1 or 0, id })
    syncAll(-1)
end)

RegisterNetEvent('rpg-doors:rename', function(id, label)
    local src = source
    if not isManager(src) then return end
    id = tonumber(id)
    local d = id and Doors[id]
    if not d then return end
    label = tostring(label or ''):gsub('%s+$', ''):sub(1, 64)
    if label == '' then return end
    d.label = label
    MySQL.update.await('UPDATE doors SET label = ? WHERE id = ?', { label, id })
    syncAll(-1)
end)

RegisterNetEvent('rpg-doors:remove', function(id)
    local src = source
    if not isManager(src) then return end
    id = tonumber(id)
    if not id or not Doors[id] then return end
    Doors[id] = nil
    MySQL.update.await('DELETE FROM doors WHERE id = ?', { id })
    TriggerClientEvent('rpg-doors:removed', -1, id)
    syncAll(-1)
    log(('src %s a sters usa #%d'):format(src, id))
end)

-- ---- API pt. alte resurse ----------------------------------------
exports('isLocked', function(id)
    local d = Doors[tonumber(id or 0)]
    return d and d.locked or false
end)
exports('getDoors', function() return listPayload() end)
exports('setLocked', function(id, locked)
    id = tonumber(id)
    local d = id and Doors[id]
    if not d then return false end
    d.locked = locked == true
    MySQL.update.await('UPDATE doors SET locked = ? WHERE id = ?', { d.locked and 1 or 0, id })
    syncAll(-1)
    return true
end)
