-- ===========================================================================
--  rpg-factions — FRAMEWORK ADAPTER  (server)
--
--  SINGURUL fisier framework-dependent. Daca schimbi framework-ul, rescrii DOAR
--  functiile marcate cu "TODO FRAMEWORK". Restul resursei foloseste doar
--  Framework.* / Config / DB.
--
--  Legat acum la:  rpg-auth (users.id) · rpg-level (level) · rpg-hud (notify)
--                  rpg-characters (nume) · oxmysql (users.playtime / users.level)
--
--  CE TREBUIE SA CONECTEZI:
--    GetUserId(src)            -> users.id (PK; folosit peste tot ca "id de player")
--    GetIdentifier(src)        -> string identificator stabil (aici: license Cfx)
--    GetLevel(src)             -> level-ul playerului ONLINE
--    GetLevelByUserId(uid)     -> level dintr-un users.id (si offline)
--    GetPlaytimeSeconds*(...)  -> secunde de joc (online / dupa uid)
--    GetPlaytimeHours(src)     -> ore (conversie configurabila)
--    GetGroup(src) / SetGroup  -> citire/scriere users.`group` (id facțiune)
--    Notify(src, msg, kind)    -> notificare player
--    GetName(src) / GetNameByUserId(uid) -> nume afisat
--    GetSrcByUserId(uid)       -> src online al unui users.id (nil daca offline)
--    OnlineUserIds()           -> { [uid] = src } pt. toti conectatii
-- ===========================================================================

Framework = {}

local function account(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)     -- TODO FRAMEWORK
    return (ok and a) or nil
end

function Framework.GetUserId(src)
    local a = account(src)                                                             -- TODO FRAMEWORK
    return a and tonumber(a.id) or nil
end

function Framework.GetIdentifier(src)
    return (GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license')) or nil
end

function Framework.GetLevel(src)
    local ok, lvl = pcall(function() return exports['rpg-level']:getLevel(src) end)    -- TODO FRAMEWORK
    return (ok and tonumber(lvl)) or 0
end

function Framework.GetLevelByUserId(uid)
    if not uid then return 0 end
    local v = MySQL.scalar.await('SELECT level FROM users WHERE id = ? LIMIT 1', { uid })  -- TODO FRAMEWORK
    return tonumber(v) or 0
end

-- playtime BRUT (unitatea framework-ului). Aici: SECUNDE.
function Framework.GetPlaytimeSeconds(src)
    local uid = Framework.GetUserId(src)
    return Framework.GetPlaytimeSecondsByUserId(uid)
end
function Framework.GetPlaytimeSecondsByUserId(uid)
    if not uid then return 0 end
    local v = MySQL.scalar.await('SELECT playtime FROM users WHERE id = ? LIMIT 1', { uid })  -- TODO FRAMEWORK
    return tonumber(v) or 0
end

-- ORE de joc — conversie configurabila (Config.PlaytimeSecondsPerHour).
function Framework.GetPlaytimeHours(src)
    return Framework.GetPlaytimeSeconds(src) / (Config.PlaytimeSecondsPerHour or 3600)
end
function Framework.GetPlaytimeHoursByUserId(uid)
    return Framework.GetPlaytimeSecondsByUserId(uid) / (Config.PlaytimeSecondsPerHour or 3600)
end

-- users.`group` (id facțiune). Cache pe statebag + DB.
function Framework.GetGroup(src)
    local st = Player(src).state
    if st and st.faction ~= nil then return tonumber(st.faction) or 0 end
    local uid = Framework.GetUserId(src)
    if not uid then return 0 end
    local v = MySQL.scalar.await('SELECT `group` FROM users WHERE id = ? LIMIT 1', { uid })
    return tonumber(v) or 0
end
function Framework.SetGroup(src, groupId)
    local uid = Framework.GetUserId(src)
    if not uid then return false end
    local ok = pcall(function()
        MySQL.update.await('UPDATE users SET `group` = ? WHERE id = ?', { groupId or 0, uid })
    end)
    return ok
end

local NOTIFY_CH = { info = 'INFO', success = 'SUCCESS', error = 'ERROR', warn = 'STAFF' }
function Framework.Notify(src, msg, kind)
    if not src or src <= 0 then if Config.Debug then print(('[rpg-factions] %s'):format(msg)) end return end
    local ch = NOTIFY_CH[kind or 'info'] or 'INFO'
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = ch, text = msg })            -- TODO FRAMEWORK
    end)
    if not ok then TriggerClientEvent('chat:addMessage', src, { args = { 'FACTION', msg } }) end
    TriggerClientEvent('rpg-factions:notify', src, msg, kind or 'info')                  -- toast NUI (nu depinde de framework)
end

function Framework.GetName(src)
    local ok, c = pcall(function() return exports['rpg-characters']:getCharacter(src) end)  -- TODO FRAMEWORK
    if ok and c and c.username then return c.username end
    local a = account(src)
    return (a and a.username) or GetPlayerName(src) or ('src' .. tostring(src))
end
function Framework.GetNameByUserId(uid)
    if not uid then return '?' end
    local src = Framework.GetSrcByUserId(uid)
    if src then return Framework.GetName(src) end
    local v = MySQL.scalar.await('SELECT username FROM users WHERE id = ? LIMIT 1', { uid })  -- TODO FRAMEWORK
    return v or ('#' .. uid)
end

function Framework.GetSrcByUserId(uid)
    uid = tonumber(uid); if not uid then return nil end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if Framework.GetUserId(t) == uid then return t end
    end
    return nil
end

function Framework.OnlineUserIds()
    local map = {}
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local uid = Framework.GetUserId(t)
        if uid then map[uid] = t end
    end
    return map
end

-- staff global (administrare din afara ierarhiei de facțiune)
function Framework.IsAdmin(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function()
        return exports['rpg-auth']:hasStaffLevel(src, Config.Security.adminRank)         -- TODO FRAMEWORK
    end)
    return ok and allowed == true
end
