-- ===========================================================================
--  rpg-hud — server
--  - broadcast chat (GLOBAL / LOCAL) + compat cu conventiile Cfx
--  - impinge catre client datele "de cont": username, SQL id, cash, bank, online
--  Economy / Paycheck / Survival reale se conecteaza prin exports + events.
-- ===========================================================================

local players = {}   -- [src] = { name, id, cash, bank }
local lastMsg = {}   -- [src] = tick
local online  = 0

-- ----- helpers -----------------------------------------------------
-- identitatea unui player pentru chat: nume + SQL id (id de personaj).
-- NU se foloseste server id-ul (session id) nicaieri.
local function chatIdentity(src)
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    if okc and ch then
        return ch.username or GetPlayerName(src) or '?', ch.id
    end
    return GetPlayerName(src) or '?', nil
end

local function nameOf(src)
    local n = chatIdentity(src)
    return n
end

local function pushPlayer(src)
    local p = players[src]; if not p then return end
    TriggerClientEvent('hud:updatePlayer', src, { username = p.name, id = p.id })
    TriggerClientEvent('hud:updateMoney',  src, p.cash)
    TriggerClientEvent('hud:updateBank',   src, p.bank)
    TriggerClientEvent('hud:updateOnline', src, online)
end

local function broadcastOnline()
    TriggerClientEvent('hud:updateOnline', -1, online)
end

-- ----- ciclu de viata --------------------------------------------
AddEventHandler('core:characterLoaded', function(src, charId, username)
    players[src] = {
        name = username or nameOf(src),
        id   = charId,
        cash = Config.Hud.startMoney.cash,
        bank = Config.Hud.startMoney.bank,
    }
    pushPlayer(src)
end)

AddEventHandler('playerJoining', function()
    online = online + 1
    broadcastOnline()
end)

AddEventHandler('playerDropped', function()
    local src = source
    players[src] = nil
    lastMsg[src] = nil
    online = math.max(0, online - 1)
    broadcastOnline()
end)

-- corectie / resync periodic
CreateThread(function()
    while true do
        Wait(30000)
        local n = #GetPlayers()
        if n ~= online then online = n; broadcastOnline() end
    end
end)
CreateThread(function()
    Wait(1500)
    online = #GetPlayers()
    broadcastOnline()
end)

-- ===========================================================================
--  CHAT  — mereu LOCAL (raza Config.Chat.localRange)
-- ===========================================================================
local function sendLocal(src, payload)
    local sp = GetPlayerPed(src)
    if not sp or sp == 0 then return end
    local pc = GetEntityCoords(sp)
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local tp = GetPlayerPed(t)
        if tp and tp ~= 0 and #(GetEntityCoords(tp) - pc) <= Config.Chat.localRange then
            TriggerClientEvent('rpg-hud:chatMessage', t, payload)
        end
    end
end

RegisterNetEvent('rpg-hud:chatSend', function(text)
    local src = source
    text = tostring(text or ''):sub(1, Config.Chat.maxLength)
    if text:gsub('%s', '') == '' then return end

    local now = GetGameTimer()
    if lastMsg[src] and now - lastMsg[src] < Config.Chat.rateLimit then return end
    lastMsg[src] = now

    -- mesaj normal de jucator:  (sql id) Nume: text   — fara tag de canal
    local name, id = chatIdentity(src)
    sendLocal(src, { author = name, id = id, text = text, time = os.date('%H:%M') })

    if Config.Debug then
        print(('[rpg-hud][local] (%s) %s: %s'):format(tostring(id), name, text))
    end
end)

-- compat: unele scripturi vechi declanseaza `chatMessage` (server event) — local
AddEventHandler('chatMessage', function(src, name, message)
    CancelEvent()
    local n, id = chatIdentity(src)
    sendLocal(src, {
        author = (name and name ~= '') and name or n,
        id     = id,
        text   = tostring(message),
        time   = os.date('%H:%M'),
    })
end)

-- ===========================================================================
--  STAFF CHAT  ( /a  ·  /hc )  +  MANAGEMENT  ( /setstaff /removestaff )
--  +  /getbeta
-- ===========================================================================
local function notify(src, channel, text)
    if src <= 0 then
        print(('[rpg-hud] %s: %s'):format(channel or 'INFO', text))
        return
    end
    TriggerClientEvent('rpg-hud:chatMessage', src, { channel = channel, text = text, time = os.date('%H:%M') })
end

local function staffInfo(src)
    if src <= 0 then
        return { rank = 'owner', label = 'Consolă', color = Staff.color('owner'), id = 0, name = 'Consolă', kind = 'admin', level = 999 }
    end
    local rank = exports['rpg-auth']:getStaff(src)
    local name, id = chatIdentity(src)
    return {
        rank  = rank,
        label = Staff.label(rank),
        color = Staff.color(rank),
        id    = id or 0,
        name  = name,
        kind  = Staff.kind(rank),
        level = Staff.level(rank),
    }
end

local function staffChat(src, kind, text)
    text = tostring(text or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then return end

    local minRank = (kind == 'admin') and Staff.MIN_ADMIN_CHAT or Staff.MIN_HELPER_CHAT
    if src > 0 and not exports['rpg-auth']:hasStaffLevel(src, minRank) then
        return notify(src, 'ERROR', 'Nu ai acces la acest chat.')
    end

    local info = staffInfo(src)
    local payload = {
        channel = (kind == 'admin') and 'STAFF_ADMIN' or 'STAFF_HELPER',
        author  = info.name,
        text    = text,
        time    = os.date('%H:%M'),
        color   = (kind == 'admin') and Config.Chat.adminChatColor or Config.Chat.helperChatColor,
        staff   = { label = info.label, color = info.color, id = info.id, kind = kind },
    }

    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if exports['rpg-auth']:hasStaffLevel(t, minRank) then
            TriggerClientEvent('rpg-hud:chatMessage', t, payload)
        end
    end
    print(('[%s-chat] [%s] %s (%s): %s'):format(kind, info.label, info.name, tostring(info.id), text))
end

RegisterCommand('a', function(src, args, raw)
    staffChat(src, 'admin', raw:match('^%S+%s+(.*)$') or '')
end, false)

RegisterCommand('hc', function(src, args, raw)
    staffChat(src, 'helper', raw:match('^%S+%s+(.*)$') or '')
end, false)

RegisterCommand('setstaff', function(src, args)
    if src > 0 and not exports['rpg-auth']:hasStaffLevel(src, Staff.MIN_MANAGE_STAFF) then return end

    local charId = tonumber(args[1])
    local rank   = tostring(args[2] or ''):lower()
    if not charId or not Staff.exists(rank) then
        return notify(src, 'ERROR', 'Folosire: /setstaff [sql id] [grad]')
    end

    local setterLevel = (src <= 0) and 999 or exports['rpg-auth']:getStaffLevel(src)
    if Staff.level(rank) >= setterLevel then
        return notify(src, 'ERROR', 'Nu poți acorda un grad egal sau superior gradului tău.')
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return notify(src, 'ERROR', 'SQL id inexistent.') end

    exports['rpg-auth']:setStaff(target.accountId, rank)
    notify(src, 'SUCCESS', ('Grad setat: %s (%s) -> %s'):format(target.username or '?', charId, Staff.label(rank)))
    if target.src then
        notify(target.src, 'STAFF', ('Ai primit gradul de staff: %s.'):format(Staff.label(rank)))
    end
    print(('[rpg-hud] setstaff: %s -> %s de catre src %d'):format(charId, rank, src))
end, false)

RegisterCommand('removestaff', function(src, args)
    if src > 0 and not exports['rpg-auth']:hasStaffLevel(src, Staff.MIN_MANAGE_STAFF) then return end

    local charId = tonumber(args[1])
    if not charId then
        return notify(src, 'ERROR', 'Folosire: /removestaff [sql id]')
    end

    local target = exports['rpg-characters']:resolveCharacter(charId)
    if not target then return notify(src, 'ERROR', 'SQL id inexistent.') end

    local targetRank  = exports['rpg-auth']:getStaffByAccountId(target.accountId)
    local setterLevel = (src <= 0) and 999 or exports['rpg-auth']:getStaffLevel(src)
    if targetRank and Staff.level(targetRank) >= setterLevel then
        return notify(src, 'ERROR', 'Nu poți retrage gradul acestei persoane.')
    end

    exports['rpg-auth']:setStaff(target.accountId, '')
    notify(src, 'SUCCESS', ('Grad retras de la %s (%s).'):format(target.username or '?', charId))
    if target.src then
        notify(target.src, 'STAFF', 'Gradul tău de staff a fost retras.')
    end
end, false)

RegisterCommand('getbeta', function(src, args)
    if src <= 0 then return end
    local code = tostring(args[1] or '')
    if code == '' then return notify(src, 'ERROR', 'Folosire: /getbeta [cod]') end

    local res = exports['rpg-auth']:redeemBeta(src, code)
    if res and res.ok then
        notify(src, 'SUCCESS', ('Cod valid! Recompensă: %s.'):format(res.rewardLabel or res.reward))
    else
        notify(src, 'ERROR', (res and res.error) or 'Cod invalid.')
    end
end, false)

-- ===========================================================================
--  API (pentru Economy / Paycheck / Survival / Voice / Notify)
-- ===========================================================================
exports('addChatMessage', function(target, payload)
    if type(payload) ~= 'table' then return end
    payload.time = payload.time or os.date('%H:%M')
    TriggerClientEvent('rpg-hud:chatMessage', target or -1, payload)
end)
exports('broadcastChat', function(payload)
    if type(payload) ~= 'table' then return end
    payload.time = payload.time or os.date('%H:%M')
    TriggerClientEvent('rpg-hud:chatMessage', -1, payload)
end)

exports('setMoney', function(src, cash, bank)
    local p = players[src]; if not p then return end
    if cash ~= nil then p.cash = cash; TriggerClientEvent('hud:updateMoney', src, cash) end
    if bank ~= nil then p.bank = bank; TriggerClientEvent('hud:updateBank',  src, bank) end
end)
exports('getMoney', function(src)
    local p = players[src]
    return p and { cash = p.cash, bank = p.bank } or nil
end)
exports('setPaycheck', function(src, seconds, running)
    TriggerClientEvent('hud:updatePaycheck', src, { seconds = seconds, running = running ~= false })
end)
exports('setActivity', function(src, data) TriggerClientEvent('hud:updateActivity', src, data) end)
exports('clearActivity', function(src) TriggerClientEvent('hud:clearActivity', src) end)
exports('getOnline', function() return online end)

-- ===========================================================================
--  COMENZI DE TEST  (ACE: ph.admin sau ruleaza din consola serverului)
-- ===========================================================================
local function admin(src) return src == 0 or IsPlayerAceAllowed(src, 'ph.admin') end

RegisterCommand('hudmoney', function(src, args)
    if not admin(src) then return end
    local cash, bank = tonumber(args[1]), tonumber(args[2])
    local p = players[src]
    if p and cash then p.cash = cash; TriggerClientEvent('hud:updateMoney', src, cash) end
    if p and bank then p.bank = bank; TriggerClientEvent('hud:updateBank', src, bank) end
end, false)

RegisterCommand('hudactivity', function(src, args)
    if not admin(src) then return end
    TriggerClientEvent('hud:updateActivity', src, {
        title = args[1] and args[1]:gsub('_', ' ') or 'EXTRACȚIE PETROL',
        timer = tonumber(args[2]) or 175,
    })
end, false)

RegisterCommand('hudclearactivity', function(src)
    if not admin(src) then return end
    TriggerClientEvent('hud:clearActivity', src)
end, false)

RegisterCommand('hudpaycheck', function(src, args)
    if not admin(src) then return end
    TriggerClientEvent('hud:updatePaycheck', src, { seconds = tonumber(args[1]) or 60, running = true })
end, false)
