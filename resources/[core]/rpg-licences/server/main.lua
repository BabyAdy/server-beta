-- ===========================================================================
--  rpg-licences — server
--  Autoritate: users.driving_licence_hours / weapon_licence_hours /
--              flying_licence_hours / sailing_licence_hours.
--  Orele NU scad automat -- sunt un credit persistent, acordat de staff prin
--  /agl. 0 ore = fara licenta. Nu inventam decadere in timp (nu a fost cerut).
-- ===========================================================================

local DBG = true
local cache = {}   -- [src] = { accountId, username, driving, weapon, flying, sailing }

local FIELD = {
    driving = 'driving_licence_hours',
    weapon  = 'weapon_licence_hours',
    flying  = 'flying_licence_hours',
    sailing = 'sailing_licence_hours',
}

-- ---- helperi -----------------------------------------------------------
local function accOf(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    return (ok and a) and a or nil
end

local function feedback(src, channel, text)
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = channel, text = text })
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 190, 130, 255 }, args = { 'LICENTE', text } })
    end
end

local function pushSync(src)
    local s = cache[src]; if not s then return end
    TriggerClientEvent('rpg-licences:sync', src,
        { driving = s.driving, weapon = s.weapon, flying = s.flying, sailing = s.sailing })
end

-- ===========================================================================
--  INCARCARE (la fiecare login de personaj, ca in rpg-level)
-- ===========================================================================
local Licences = {}
function Licences.load(src)
    local acc = accOf(src)
    if not acc then return end
    local row = MySQL.single.await([[
        SELECT driving_licence_hours, weapon_licence_hours, flying_licence_hours, sailing_licence_hours
        FROM users WHERE id = ? LIMIT 1
    ]], { acc.id })
    if not row then return end

    cache[src] = {
        accountId = acc.id,
        username  = acc.username,
        driving   = tonumber(row.driving_licence_hours) or 0,
        weapon    = tonumber(row.weapon_licence_hours) or 0,
        flying    = tonumber(row.flying_licence_hours) or 0,
        sailing   = tonumber(row.sailing_licence_hours) or 0,
    }
    pushSync(src)

    if DBG then
        local s = cache[src]
        print(('[rpg-licences] Încărcat cont #%s: driving %dh, weapon %dh, flying %dh, sailing %dh')
            :format(acc.id, s.driving, s.weapon, s.flying, s.sailing))
    end
end

local examBypass = {}   -- [src] = true  -- ex. testul practic de la Driving School (rpg-drivingschool)

AddEventHandler('core:characterLoaded', function(src) Licences.load(src) end)
AddEventHandler('playerDropped', function()
    cache[source] = nil
    examBypass[source] = nil
end)

-- ===========================================================================
--  API (pentru alte resurse — ex. rpg-inventory la echiparea armelor,
--       rpg-drivingschool la acordarea licenței / bypass in timpul examenului)
-- ===========================================================================
local function hoursOf(src, kind)
    local s = cache[src]
    return (s and s[kind]) or 0
end

exports('getLicenceHours',   function(src, kind) return hoursOf(src, kind) end)
exports('hasLicence',        function(src, kind) return hoursOf(src, kind) > 0 end)
exports('hasDrivingLicence', function(src) return hoursOf(src, 'driving') > 0 end)
exports('hasWeaponLicence',  function(src) return hoursOf(src, 'weapon') > 0 end)
exports('hasFlyingLicence',  function(src) return hoursOf(src, 'flying') > 0 end)
exports('hasSailingLicence', function(src) return hoursOf(src, 'sailing') > 0 end)

-- adaugă ore unui player ONLINE (ex. recompensa de la Driving School). true/false.
exports('addLicenceHours', function(src, kind, hours)
    local col = FIELD[kind]
    local s = cache[src]
    if not col or not s or not hours then return false end
    hours = math.floor(tonumber(hours) or 0)
    MySQL.update.await(
        ('UPDATE users SET `%s` = GREATEST(0, `%s` + ?) WHERE id = ?'):format(col, col),
        { hours, s.accountId })
    Licences.load(src)
    return true
end)

-- bypass temporar (ex. testul practic -> jucătorul conduce fără să aibă încă licența)
exports('setExamBypass', function(src, on) examBypass[src] = on and true or nil end)

-- ===========================================================================
--  VEHICUL — clientul cere validare cand devine SOFER/PILOT
--  (decizia ramane pe server; ejectarea efectiva e client-side, vezi client/main.lua)
-- ===========================================================================
RegisterNetEvent('rpg-licences:checkVehicle', function(vehClass)
    local src = source
    if examBypass[src] then return end              -- ex. testul practic in curs
    local kind = Config.VehicleClassLicence[tonumber(vehClass)]
    if not kind then return end                     -- clasa asta nu e restricționată
    if hoursOf(src, kind) > 0 then return end        -- are licența -> ok, nu facem nimic
    TriggerClientEvent('rpg-licences:deny', src, kind)
end)

-- ===========================================================================
--  /agl [sql id] [driving|weapon|flying|sailing|all] [ore]  — staff >= manager
--  ADAUGĂ ore (ca /give din rpg-level); "sql id" = SQL id de PERSONAJ (ca la
--  /setstaff), rezolvat prin rpg-characters -> functioneaza si pe offline.
-- ===========================================================================
local function canStaffCmd(src, minRank)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, minRank) end)
    return ok and allowed == true
end

local function cmdIssuer(src)
    if src <= 0 then return 'Consolă', 'Consolă' end
    local s = cache[src]
    local name = (s and s.username) or GetPlayerName(src) or ('src' .. src)
    local label = 'Staff'
    local ok, l = pcall(function() return exports['rpg-auth']:getStaffLabel(src) end)
    if ok and l and l ~= '' then label = l end
    return name, label
end

-- trimite un mesaj în chat DOAR staff-ului online cu grad >= minRank (mereu roșu)
local function staffBroadcast(minRank, text)
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(t, minRank) end)
        if ok and allowed == true then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = Staff.BROADCAST_COLOR, time = os.date('%H:%M') })
        end
    end
    print(('[rpg-licences][staff] %s'):format(text))
end

RegisterCommand('agl', function(src, args)
    if not canStaffCmd(src, Config.MinAglRank) then
        return feedback(src, 'ERROR', 'Nu ai acces la această comandă.')
    end

    local charId = tonumber(args[1])
    local kind   = tostring(args[2] or ''):lower()
    local hours  = tonumber(args[3])

    if not charId or not hours or (kind ~= 'all' and not FIELD[kind]) then
        return feedback(src, 'ERROR', 'Folosire: /agl [sql id] [driving|weapon|flying|sailing|all] [ore]')
    end
    hours = math.floor(hours)

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return feedback(src, 'ERROR', 'SQL id inexistent.') end

    local kinds = (kind == 'all') and { 'driving', 'weapon', 'flying', 'sailing' } or { kind }
    for _, k in ipairs(kinds) do
        local col = FIELD[k]
        MySQL.update.await(
            ('UPDATE users SET `%s` = GREATEST(0, `%s` + ?) WHERE id = ?'):format(col, col),
            { hours, target.accountId })
    end

    if target.src then Licences.load(target.src) end   -- resincronizează dacă e online

    local giverName, giverLabel = cmdIssuer(src)
    local kindLabel = (kind == 'all') and 'toate licențele' or kind

    feedback(src, 'SUCCESS',
        ('Ai dat %s (%s) %d ore pentru [%s].'):format(target.username or '?', charId, hours, kindLabel))
    if target.src then
        feedback(target.src, 'INFO', ('Ai primit %d ore pentru [%s].'):format(hours, kindLabel))
    end

    -- broadcast: staff >= trialadmin, mereu roșu
    staffBroadcast(Config.MinBroadcastRank,
        ('Staff: %s %s has given %s[%s] license %s for %s hours!')
            :format(giverLabel, giverName, target.username or '?', charId, kind, hours))

    print(('[rpg-licences] /agl: %s(#%s) -> %s(#%s) +%dh %s')
        :format(giverName, src, target.username or '?', charId, hours, kind))
end, false)
