-- ===========================================================================
--  rpg-jobs — FRAMEWORK ADAPTER  (server)
--
--  ACESTA E SINGURUL FISIER FRAMEWORK-DEPENDENT.
--  Daca schimbi framework-ul, rescrii DOAR functiile de mai jos. Restul
--  sistemului (jobs.lua / security.lua / main.lua / client / nui) NU se atinge.
--
--  In serverul actual e legat la:
--    rpg-auth        -> exports:getAccount(src)   { id = users.id, username, ... }
--    rpg-level       -> exports:getLevel / getMoney / getBank / addMoney / addBank
--    rpg-hud         -> exports:addChatMessage(src, { channel, text })
--    rpg-characters  -> exports:getCharacter(src) { id, username, ... }
--    oxmysql         -> MySQL.*.await  (users.job citire/scriere)
--
--  CE TREBUIE SA CONECTEZI daca ai alt framework (cauta "TODO FRAMEWORK"):
--    1. GetUserId      -> ID-ul stabil, unic, care e si PK in `users` (FK din player_job_data)
--    2. GetLevel       -> level-ul playerului (pt. minLevel al jobului)
--    3. GetLicense     -> optional (string license Cfx), daca ai nevoie
--    4. LoadJob/GetJob -> citirea `users.job`
--    5. SetJob         -> scrierea `users.job`
--    6. AddMoney       -> acordarea platii (respecta Config.PayTo)
--    7. Notify         -> notificare catre player (chat / toast)
--    8. GetName        -> numele afisat al playerului (logging / UI)
-- ===========================================================================

Framework = {}

Framework._job = {}   -- [src] = users.job (cache; sursa de adevar = DB)

local function accountOf(src)
    local ok, a = pcall(function() return exports['rpg-auth']:getAccount(src) end)   -- TODO FRAMEWORK
    return (ok and a) or nil
end

-- 1. ID stabil de player = users.id (FK-ul din player_job_data)
function Framework.GetUserId(src)
    local a = accountOf(src)                                                          -- TODO FRAMEWORK
    return a and tonumber(a.id) or nil
end

-- alias cerut de spec ("get player identifier"); aici = users.id
function Framework.GetIdentifier(src)
    return Framework.GetUserId(src)
end

-- 3. license Cfx (optional)
function Framework.GetLicense(src)
    return GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license') or nil
end

-- 2. level-ul playerului
function Framework.GetLevel(src)
    local ok, lvl = pcall(function() return exports['rpg-level']:getLevel(src) end)   -- TODO FRAMEWORK
    return (ok and tonumber(lvl)) or 0
end

-- 8. nume afisat
function Framework.GetName(src)
    local ok, c = pcall(function() return exports['rpg-characters']:getCharacter(src) end)  -- TODO FRAMEWORK
    if ok and c and c.username then return c.username end
    local a = accountOf(src)
    return (a and a.username) or (GetPlayerName(src)) or ('src' .. tostring(src))
end

-- "get character data"
function Framework.GetCharacterData(src)
    local ok, c = pcall(function() return exports['rpg-characters']:getCharacter(src) end)  -- TODO FRAMEWORK
    return (ok and c) or nil
end

-- 4a. incarca users.job in cache (apelat la conectare / characterLoaded)
function Framework.LoadJob(src)
    local uid = Framework.GetUserId(src)
    if not uid then Framework._job[src] = 0; return 0 end
    local job = 0
    local ok, res = pcall(function()
        return MySQL.scalar.await('SELECT job FROM users WHERE id = ? LIMIT 1', { uid })    -- TODO FRAMEWORK
    end)
    if ok then job = tonumber(res) or 0 end   -- coloana `job` poate lipsi in prima secunda de boot
    Framework._job[src] = job
    return job
end

-- 4b. jobul curent (0 = unemployed)
function Framework.GetJob(src)
    return Framework._job[src] or 0
end

-- 5. seteaza jobul (persistent) + cache
function Framework.SetJob(src, jobId)
    local uid = Framework.GetUserId(src)
    if not uid then return false end
    jobId = tonumber(jobId) or 0
    local ok = pcall(function()
        MySQL.update.await('UPDATE users SET job = ? WHERE id = ?', { jobId, uid })   -- TODO FRAMEWORK
    end)
    if not ok then return false end
    Framework._job[src] = jobId
    return true
end

-- 6. plata (server-side, calculata deja de jobs.lua). Config.PayTo = 'money' | 'bank'
function Framework.AddMoney(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local ok = pcall(function()
        if Config.PayTo == 'bank' then
            exports['rpg-level']:addBank(src, amount)                                  -- TODO FRAMEWORK
        else
            exports['rpg-level']:addMoney(src, amount)                                 -- TODO FRAMEWORK
        end
    end)
    return ok
end

-- 7. notificare. kind: 'info' | 'success' | 'error'
local NOTIFY_CH = { info = 'INFO', success = 'SUCCESS', error = 'ERROR' }
function Framework.Notify(src, text, kind)
    local ch = NOTIFY_CH[kind or 'info'] or 'INFO'
    local ok = pcall(function()
        exports['rpg-hud']:addChatMessage(src, { channel = ch, text = text })          -- TODO FRAMEWORK
    end)
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { color = { 246, 190, 0 }, args = { 'JOB', text } })
    end
    -- si un toast in NUI-ul resursei (nu depinde de framework)
    TriggerClientEvent('rpg-jobs:notify', src, text, kind or 'info')
end

function Framework.ClearCache(src)
    Framework._job[src] = nil
end
