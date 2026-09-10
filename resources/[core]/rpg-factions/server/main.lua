-- ===========================================================================
--  rpg-factions — SERVER BOOTSTRAP + NET EVENT ROUTER + ADMIN COMMANDS
--  Handler-ele sunt SUBTIRI. Toata autoritatea e in members/applications/
--  factions/permissions/security. Nimic framework-dependent aici.
-- ===========================================================================

local DBG = Config.Debug
local hqOccupants = {}   -- [src] = fid (in interiorul HQ)

-- ---- BOOT ---------------------------------------------------------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(500)
    DB.ensureSchema()
    Factions.audit()

    for _, pid in ipairs(GetPlayers()) do
        Members.pushState(tonumber(pid))
    end
    if DBG then print('[rpg-factions] gata.') end
end)

AddEventHandler('core:characterLoaded', function(src)
    Members.pushState(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if hqOccupants[src] then
        SetPlayerRoutingBucket(src, 0)
        hqOccupants[src] = nil
    end
    Sec.cleanup(src)
end)

-- ===========================================================================
--  ROUTER (client -> server)  — toate re-verifica server-side prin Sec.gate
-- ===========================================================================
RegisterNetEvent('rpg-factions:requestSelf',   function() Members.pushState(source) end)
RegisterNetEvent('rpg-factions:listMembers',   function() Members.list(source) end)
RegisterNetEvent('rpg-factions:listApplications', function() Applications.list(source) end)
RegisterNetEvent('rpg-factions:myApplications', function() Applications.mine(source) end)

RegisterNetEvent('rpg-factions:listLogs', function(page)
    local src = source   -- `source` nu supravietuieste await-urilor din Sec.gate
    local actorCtx = Sec.gate({ src = src, event = 'listLogs', needPerm = 'view_logs' })
    if not actorCtx then return end
    TriggerClientEvent('rpg-factions:logsData', src, Logs.page(actorCtx.fid, page, Config.Security.maxLogsPerPage))
end)

RegisterNetEvent('rpg-factions:invite',        function(targetServerId) Members.invite(source, targetServerId) end)
RegisterNetEvent('rpg-factions:acceptInvite',  function(fid) Members.acceptInvite(source, fid) end)
RegisterNetEvent('rpg-factions:leave',         function() Members.leave(source) end)
RegisterNetEvent('rpg-factions:kick',          function(uid, reason) Members.kick(source, uid, reason) end)
RegisterNetEvent('rpg-factions:promote',       function(uid, reason) Members.promote(source, uid, reason) end)
RegisterNetEvent('rpg-factions:demote',        function(uid, reason) Members.demote(source, uid, reason) end)
RegisterNetEvent('rpg-factions:warning',       function(uid, delta, reason) Members.warning(source, uid, delta, reason) end)
RegisterNetEvent('rpg-factions:setSupervisor', function(uid, v) Members.setSupervisor(source, uid, v == true) end)
RegisterNetEvent('rpg-factions:setTester',     function(uid, v) Members.setTester(source, uid, v == true) end)
RegisterNetEvent('rpg-factions:setPermissions', function(uid, map) Members.setPermissions(source, uid, map) end)

RegisterNetEvent('rpg-factions:setLeader', function(uid)
    local src = source
    local actorCtx = Sec.gate({ src = src, event = 'setLeader', needPerm = 'set_leader' })
    if not actorCtx then return end
    local ok, err = Factions.setLeader(actorCtx.fid, actorCtx.uid, uid)
    Framework.Notify(src, ok and 'Leadership transferred.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
    if ok then Members.pushState(src); local ts = Framework.GetSrcByUserId(tonumber(uid)); if ts then Members.pushState(ts) end end
end)

RegisterNetEvent('rpg-factions:setManager', function(uid)
    local src = source
    local actorCtx = Sec.gate({ src = src, event = 'setManager', needPerm = 'set_manager' })
    if not actorCtx then return end
    local ok, err = Factions.setManager(actorCtx.fid, actorCtx.uid, uid)
    Framework.Notify(src, ok and 'Manager updated.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
    if ok then Members.pushState(src) end
end)

RegisterNetEvent('rpg-factions:updateSettings', function(changes)
    local src = source
    local actorCtx = Sec.gate({ src = src, event = 'updateSettings', needPerm = 'manage_settings' })
    if not actorCtx then return end
    local ok = Factions.updateSettings(actorCtx.fid, actorCtx.uid, changes, 'via menu')
    Framework.Notify(src, ok and 'Settings updated.' or 'Update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(src) end
end)

RegisterNetEvent('rpg-factions:updateRank', function(order, changes)
    local src = source
    local actorCtx = Sec.gate({ src = src, event = 'updateRank', needPerm = 'manage_ranks' })
    if not actorCtx then return end
    local ok = Factions.rankUpdate(actorCtx.fid, actorCtx.uid, order, changes or {})
    Framework.Notify(src, ok and 'Rank updated.' or 'Update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(src) end
end)

RegisterNetEvent('rpg-factions:setHQ', function(payload)
    local src = source
    -- pozitia ped-ului se ia INAINTE de Sec.gate (await-urile invalideaza `source`)
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped); local h = GetEntityHeading(ped)
    local actorCtx = Sec.gate({ src = src, event = 'setHQ', needPerm = 'manage_hq' })
    if not actorCtx then return end
    payload = payload or {}
    local here = { x = c.x, y = c.y, z = c.z, h = h }
    local e = Factions.get(actorCtx.fid)
    local enter = e.row.hq.enter
    local leave = e.row.hq.leave
    local vw    = e.row.hq.vw ~= 0 and e.row.hq.vw or (1000 + actorCtx.fid)
    if payload.point == 'enter' then enter = here
    elseif payload.point == 'leave' then leave = here
    elseif payload.vw ~= nil then vw = math.max(0, math.floor(tonumber(payload.vw) or 0)) end
    local ok = Factions.setHQ(actorCtx.fid, actorCtx.uid, enter, leave, vw)
    Framework.Notify(src, ok and 'HQ updated.' or 'HQ update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(src) end
end)

RegisterNetEvent('rpg-factions:apply',             function(fid, msg) Applications.apply(source, fid, msg) end)
RegisterNetEvent('rpg-factions:cancelApplication', function(appId) Applications.cancel(source, appId) end)
RegisterNetEvent('rpg-factions:acceptApplication', function(appId) Applications.accept(source, appId) end)
RegisterNetEvent('rpg-factions:rejectApplication', function(appId, reason) Applications.reject(source, appId, reason) end)

RegisterNetEvent('rpg-factions:browseFactions', function()
    local src = source   -- capturat INAINTE de await; `source` devine 0 dupa MySQL.*.await
    local rows = MySQL.query.await(
        "SELECT id, g_name, g_color, g_type, g_minlevel, g_minhours FROM factions WHERE g_application = 1 ORDER BY g_name ASC") or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { id = tonumber(r.id), name = r.g_name, color = r.g_color, type = r.g_type,
                          minLevel = tonumber(r.g_minlevel) or 0, minHours = tonumber(r.g_minhours) or 0 }
    end
    TriggerClientEvent('rpg-factions:factionsList', src, {
        factions = out,
        me = { level = Framework.GetLevel(src), hours = math.floor(Framework.GetPlaytimeHours(src) * 10) / 10,
               inFaction = (Framework.GetGroup(src) or 0) ~= 0 },
    })
end)

-- ---- HQ (§24) ---------------------------------------------------
RegisterNetEvent('rpg-factions:hqEnter', function()
    local src = source
    if not Sec.rate(src, 'hqEnter') then return end
    local uid = Framework.GetUserId(src)
    local ctx = Perms.contextOf(uid)
    if not ctx then return Framework.Notify(src, 'You are not in a faction.', 'error') end
    local e = Factions.get(ctx.fid)
    if not e or e.row.hq.vw == 0 or not e.row.hq.enter then
        return Framework.Notify(src, 'Your faction has no HQ configured.', 'error')
    end
    local c = GetEntityCoords(GetPlayerPed(src))
    if #(vector3(c.x, c.y, c.z) - vector3(e.row.hq.enter.x, e.row.hq.enter.y, e.row.hq.enter.z)) > Config.Security.hqRadius then
        Logs.suspect(src, 'INVALID_REQUEST', 'hqEnter far', ctx.fid)
        return
    end
    SetPlayerRoutingBucket(src, e.row.hq.vw)
    hqOccupants[src] = ctx.fid
    local dest = e.row.hq.leave or e.row.hq.enter
    TriggerClientEvent('rpg-factions:hqTeleport', src, dest, 'in')
    Logs.write({ faction = ctx.fid, actor = uid, action = 'HQ_UPDATED', reason = 'enter' })
end)

RegisterNetEvent('rpg-factions:hqLeave', function()
    local src = source
    if not Sec.rate(src, 'hqLeave') then return end
    local fid = hqOccupants[src]
    if not fid then return end
    local e = Factions.get(fid)
    local back = (e and e.row.hq.enter) or nil
    SetPlayerRoutingBucket(src, 0)
    hqOccupants[src] = nil
    if back then TriggerClientEvent('rpg-factions:hqTeleport', src, back, 'out') end
end)

-- re-sync la restart de resursa (client cere)
RegisterNetEvent('rpg-factions:clientReady', function() Members.pushState(source) end)

-- ===========================================================================
--  COMENZI ADMIN (staff global — Framework.IsAdmin)
-- ===========================================================================
local function adminOnly(src) if Framework.IsAdmin(src) then return true end Framework.Notify(src, 'No access.', 'error') return false end

RegisterCommand('fcreate', function(src, args)
    if not adminOnly(src) then return end
    local name = args[1] and args[1]:gsub('_', ' ') or ''
    if name == '' then return Framework.Notify(src, 'Usage: /fcreate [Name_With_Underscores] [type]', 'error') end
    local fid, err = Factions.create(src > 0 and Framework.GetUserId(src) or 0, { name = name, type = args[2] or 'other' })
    Framework.Notify(src, fid and ('Faction #%d created: %s'):format(fid, name) or ('Failed: ' .. tostring(err)), fid and 'success' or 'error')
end, false)

RegisterCommand('fdelete', function(src, args)
    if not adminOnly(src) then return end
    local fid = tonumber(args[1]); if not fid then return Framework.Notify(src, 'Usage: /fdelete [id]', 'error') end
    local ok = Factions.delete(fid, src > 0 and Framework.GetUserId(src) or 0)
    Framework.Notify(src, ok and ('Faction #%d deleted.'):format(fid) or 'Failed.', ok and 'success' or 'error')
    -- re-sync toti membrii afectati (au fost resetati in DB)
    for _, pid in ipairs(GetPlayers()) do Members.pushState(tonumber(pid)) end
end, false)

RegisterCommand('faddmember', function(src, args)
    if not adminOnly(src) then return end
    local uid, fid, rank = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]) or Config.DefaultInitialRank
    if not uid or not fid then return Framework.Notify(src, 'Usage: /faddmember [userId] [factionId] [rankOrder]', 'error') end
    local e = Factions.get(fid); if not e then return Framework.Notify(src, 'Faction not found.', 'error') end
    if not e.ranks[rank] then rank = e.row.initialRank end
    local affected = MySQL.update.await([[
        UPDATE users SET `group`=?, group_rank=?, group_join=NOW(), group_warning=0,
            group_supervisor=0, group_tester=0, group_permissions='{}'
        WHERE id=? AND `group`=0
    ]], { fid, rank, uid })
    if affected and affected >= 1 then
        Logs.write({ faction = fid, actor = src > 0 and Framework.GetUserId(src) or 0, target = uid,
                     action = 'MEMBER_JOINED', reason = 'admin add', new = { group = fid, group_rank = rank } })
        local ts = Framework.GetSrcByUserId(uid); if ts then Members.pushState(ts) end
        Framework.Notify(src, ('User #%d added to faction #%d (rank %d).'):format(uid, fid, rank), 'success')
    else
        Framework.Notify(src, 'User is already in a faction or does not exist.', 'error')
    end
end, false)

RegisterCommand('fsetleader', function(src, args)
    if not adminOnly(src) then return end
    local fid, uid = tonumber(args[1]), tonumber(args[2])
    if not fid or not uid then return Framework.Notify(src, 'Usage: /fsetleader [factionId] [userId]', 'error') end
    local ok, err = Factions.setLeader(fid, src > 0 and Framework.GetUserId(src) or 0, uid)
    Framework.Notify(src, ok and 'Leader set.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
    local ts = Framework.GetSrcByUserId(uid); if ts then Members.pushState(ts) end
end, false)

RegisterCommand('fsethq', function(src, args)
    if not adminOnly(src) then return end
    if src <= 0 then return end
    local fid, point = tonumber(args[1]), tostring(args[2] or '')
    if not fid or (point ~= 'enter' and point ~= 'leave') then
        return Framework.Notify(src, 'Usage: /fsethq [factionId] [enter|leave]  (uses your position)', 'error')
    end
    local e = Factions.get(fid); if not e then return Framework.Notify(src, 'Faction not found.', 'error') end
    local c = GetEntityCoords(GetPlayerPed(src)); local h = GetEntityHeading(GetPlayerPed(src))
    local here = { x = c.x, y = c.y, z = c.z, h = h }
    local enter = point == 'enter' and here or e.row.hq.enter
    local leave = point == 'leave' and here or e.row.hq.leave
    local vw = e.row.hq.vw ~= 0 and e.row.hq.vw or (1000 + fid)
    Factions.setHQ(fid, src > 0 and Framework.GetUserId(src) or 0, enter, leave, vw)
    Framework.Notify(src, ('HQ %s point set for faction #%d (vw %d).'):format(point, fid, vw), 'success')
    for _, pid in ipairs(GetPlayers()) do Members.pushState(tonumber(pid)) end
end, false)

RegisterCommand('flist', function(src)
    if not adminOnly(src) then return end
    local rows = MySQL.query.await('SELECT id, g_name, g_type, leader, manager FROM factions ORDER BY id') or {}
    for _, r in ipairs(rows) do
        Framework.Notify(src, ('#%d %s [%s] leader=%s manager=%s'):format(r.id, r.g_name, r.g_type, tostring(r.leader), tostring(r.manager)), 'info')
    end
    if #rows == 0 then Framework.Notify(src, 'No factions.', 'info') end
end, false)

-- ===========================================================================
--  COMENZI ADMIN NOI  —  /createfaction (owner) · /setfmember /setleader /fpk (manager)
--  [sql id] = id de PERSONAJ (ca la /setstaff). Rezolvat -> users.id (contul).
--  Fallback: daca nu e id de personaj valid, numarul e tratat DIRECT ca users.id.
-- ===========================================================================
local function ownerOnly(src)
    if src <= 0 then return true end
    local ok, allowed = pcall(function() return exports['rpg-auth']:hasStaffLevel(src, 'owner') end)
    if ok and allowed == true then return true end
    Framework.Notify(src, 'No access (owner only).', 'error')
    return false
end
local function actorUid(src) return (src and src > 0) and (Framework.GetUserId(src) or 0) or 0 end

local function resolveUid(id)
    id = tonumber(id); if not id then return nil end
    local ok, ch = pcall(function() return exports['rpg-characters']:resolveCharacter(id) end)
    if ok and ch and ch.accountId then return tonumber(ch.accountId) end
    local row = MySQL.single.await('SELECT id FROM users WHERE id = ? LIMIT 1', { id })
    return row and tonumber(row.id) or nil
end

-- /setfmember [sql id] [rank] [faction id]  — group = fid, group_rank = rank
RegisterCommand('setfmember', function(src, args)
    if not adminOnly(src) then return end
    local sqlId, rank, fid = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
    if not sqlId or not rank or not fid then
        return Framework.Notify(src, 'Usage: /setfmember [sql id] [rank] [faction id]', 'error')
    end
    local uid = resolveUid(sqlId)
    if not uid then return Framework.Notify(src, 'SQL id not found.', 'error') end
    local e = Factions.get(fid)
    if not e then return Framework.Notify(src, ('Faction #%d not found.'):format(fid), 'error') end
    rank = math.floor(rank)
    if not e.ranks[rank] then
        return Framework.Notify(src, ('Rank %d does not exist in faction #%d.'):format(rank, fid), 'error')
    end

    MySQL.update.await(
        'UPDATE users SET `group`=?, group_rank=?, group_join=COALESCE(group_join, NOW()) WHERE id=?',
        { fid, rank, uid })
    -- daca era leader/manager in ALTA facțiune, elibereaza coloana acolo
    MySQL.update.await('UPDATE factions SET leader=0  WHERE leader=?  AND id<>?', { uid, fid })
    MySQL.update.await('UPDATE factions SET manager=0 WHERE manager=? AND id<>?', { uid, fid })
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid(src), target = uid, action = 'MEMBER_SET',
                 reason = 'admin /setfmember', new = { group = fid, group_rank = rank } })
    local ts = Framework.GetSrcByUserId(uid); if ts then Members.pushState(ts) end
    Framework.Notify(src, ('User #%d -> faction #%d, rank %d.'):format(uid, fid, rank), 'success')
end, false)

-- /setleader [sql id] [faction id]  — group = fid, group_rank = leader, factions.leader = uid
RegisterCommand('setleader', function(src, args)
    if not adminOnly(src) then return end
    local sqlId, fid = tonumber(args[1]), tonumber(args[2])
    if not sqlId or not fid then
        return Framework.Notify(src, 'Usage: /setleader [sql id] [faction id]', 'error')
    end
    local uid = resolveUid(sqlId)
    if not uid then return Framework.Notify(src, 'SQL id not found.', 'error') end
    local e = Factions.get(fid)
    if not e then return Framework.Notify(src, ('Faction #%d not found.'):format(fid), 'error') end

    local leaderRank = (e.leaderOrder ~= 0 and e.leaderOrder) or 7
    local oldLeader  = e.row.leader
    local demote     = (e.coleaderOrder ~= 0 and e.coleaderOrder) or math.max(1, leaderRank - 1)

    local tx = {}
    if oldLeader ~= 0 and oldLeader ~= uid then
        tx[#tx + 1] = { 'UPDATE users SET group_rank=? WHERE id=? AND `group`=?', { demote, oldLeader, fid } }
    end
    tx[#tx + 1] = { 'UPDATE users SET `group`=?, group_rank=?, group_join=COALESCE(group_join, NOW()) WHERE id=?',
                    { fid, leaderRank, uid } }
    tx[#tx + 1] = { 'UPDATE factions SET leader=? WHERE id=?', { uid, fid } }
    tx[#tx + 1] = { 'UPDATE factions SET leader=0 WHERE leader=? AND id<>?', { uid, fid } }

    if not DB.transaction(tx) then return Framework.Notify(src, 'DB error.', 'error') end
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid(src), target = uid, action = 'LEADER_CHANGED',
                 reason = 'admin /setleader', old = { leader = oldLeader }, new = { leader = uid } })
    for _, u in ipairs({ uid, oldLeader }) do
        if u and u ~= 0 then local ts = Framework.GetSrcByUserId(u); if ts then Members.pushState(ts) end end
    end
    Framework.Notify(src, ('User #%d is now LEADER of faction #%d (rank %d).'):format(uid, fid, leaderRank), 'success')
end, false)

-- /fpk [sql id] [reason]  — scoate din facțiune + reset complet
RegisterCommand('fpk', function(src, args)
    if not adminOnly(src) then return end
    local sqlId = tonumber(args[1])
    if not sqlId then return Framework.Notify(src, 'Usage: /fpk [sql id] [reason]', 'error') end
    local reason = table.concat(args, ' ', 2):gsub('^%s+', ''):gsub('%s+$', '')
    if reason == '' then reason = 'no reason' end

    local uid = resolveUid(sqlId)
    if not uid then return Framework.Notify(src, 'SQL id not found.', 'error') end

    local row = MySQL.single.await('SELECT `group` FROM users WHERE id=?', { uid })
    local wasFid = row and tonumber(row.group) or 0

    -- toate permisiunile individuale -> false (explicit)
    local falsePerms = {}
    for _, p in ipairs(Config.Permissions) do falsePerms[p] = false end

    MySQL.update.await([[
        UPDATE users SET `group`=0, group_rank=0, group_permissions=?,
            group_supervisor=0, group_tester=0, group_warning=0, group_join=NULL
        WHERE id=?
    ]], { DB.encode(falsePerms), uid })

    if wasFid ~= 0 then
        MySQL.update.await('UPDATE factions SET leader=0  WHERE id=? AND leader=?',  { wasFid, uid })
        MySQL.update.await('UPDATE factions SET manager=0 WHERE id=? AND manager=?', { wasFid, uid })
        Factions.invalidate(wasFid)
        Logs.write({ faction = wasFid, actor = actorUid(src), target = uid, action = 'MEMBER_PK',
                     reason = reason, old = { group = wasFid } })
    end

    local ts = Framework.GetSrcByUserId(uid)
    if ts then Members.pushState(ts) end
    Framework.Notify(src, ('User #%d PK-ed from faction #%d. Reason: %s'):format(uid, wasFid, reason), 'success')
    if ts then Framework.Notify(ts, ('You were removed from your faction (%s).'):format(reason), 'error') end
end, false)

-- /createfaction (owner)  — deschide Faction Creator Menu (NUI)
RegisterCommand('createfaction', function(src)
    if not ownerOnly(src) then return end
    if src <= 0 then return print('[rpg-factions] /createfaction e disponibila doar in joc.') end
    local nextId = tonumber(MySQL.scalar.await([[
        SELECT `AUTO_INCREMENT` FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'factions'
    ]]))
    if not nextId then
        nextId = (tonumber(MySQL.scalar.await('SELECT MAX(id) FROM factions')) or 0) + 1
    end
    TriggerClientEvent('rpg-factions:openCreator', src, {
        nextId = nextId,
        types  = Config.FactionTypes,
    })
end, false)

RegisterNetEvent('rpg-factions:adminCreate', function(payload)
    local src = source
    if not ownerOnly(src) then return end
    payload = (type(payload) == 'table') and payload or {}
    local actor = actorUid(src)

    local name = tostring(payload.name or ''):gsub('^%s+', ''):gsub('%s+$', ''):sub(1, 64)
    if name == '' then return Framework.Notify(src, 'Faction name is required.', 'error') end

    local fid, err = Factions.create(actor, {
        name       = name,
        color      = payload.color,
        type       = payload.type,
        minLevel   = payload.minLevel,
        minHours   = payload.minHours,
        maxMembers = payload.maxMembers,
    })
    if not fid then
        return Framework.Notify(src, 'Create failed: ' .. tostring(err), 'error')
    end

    local enter = (type(payload.enter) == 'table') and payload.enter or nil
    local exitp = (type(payload.exit)  == 'table') and payload.exit  or nil
    local vw    = math.max(0, math.floor(tonumber(payload.vw) or 0))
    if enter or exitp or vw ~= 0 then
        Factions.setHQ(fid, actor, enter, exitp, vw ~= 0 and vw or (1000 + fid))
    end

    Framework.Notify(src, ('Faction #%d created: %s.'):format(fid, name), 'success')
    for _, pid in ipairs(GetPlayers()) do Members.pushState(tonumber(pid)) end
end)

-- ===========================================================================
--  /editfaction (owner)  — Faction Editor Menu (NUI): alegi o facțiune si-i
--  editezi setarile + checkpoint-urile HQ.
-- ===========================================================================
RegisterCommand('editfaction', function(src)
    if not ownerOnly(src) then return end
    if src <= 0 then return print('[rpg-factions] /editfaction e disponibila doar in joc.') end
    local rows = MySQL.query.await('SELECT id, g_name FROM factions ORDER BY id ASC') or {}
    local list = {}
    for _, r in ipairs(rows) do list[#list + 1] = { id = tonumber(r.id), name = r.g_name } end
    TriggerClientEvent('rpg-factions:openEditor', src, {
        factions = list,
        types    = Config.FactionTypes,
    })
end, false)

-- clientul a ales o facțiune -> ii trimitem datele curente
RegisterNetEvent('rpg-factions:editRequest', function(fid)
    local src = source
    if not ownerOnly(src) then return end
    fid = tonumber(fid)
    local e = fid and Factions.get(fid) or nil
    if not e then return Framework.Notify(src, 'Faction not found.', 'error') end
    local row = e.row
    TriggerClientEvent('rpg-factions:editorData', src, {
        id         = row.id,
        name       = row.name,
        color      = row.color,
        type       = row.type,
        minLevel   = row.minLevel,
        minHours   = row.minHours,
        maxMembers = row.maxMembers,
        vw         = (row.hq and row.hq.vw) or 0,
        enter      = row.hq and row.hq.enter or nil,
        exit       = row.hq and row.hq.leave or nil,
    })
end)

RegisterNetEvent('rpg-factions:adminEdit', function(payload)
    local src = source
    if not ownerOnly(src) then return end
    payload = (type(payload) == 'table') and payload or {}
    local fid = tonumber(payload.id)
    local e = fid and Factions.get(fid) or nil
    if not e then return Framework.Notify(src, 'Faction not found.', 'error') end
    local actor = actorUid(src)

    local changes = {}
    if type(payload.name) == 'string' and payload.name:gsub('%s', '') ~= '' then changes.name = payload.name:sub(1, 64) end
    if payload.color      ~= nil then changes.color = payload.color end
    if payload.type       ~= nil then changes.type = payload.type end
    if payload.minLevel   ~= nil then changes.minLevel = payload.minLevel end
    if payload.minHours   ~= nil then changes.minHours = payload.minHours end
    if payload.maxMembers ~= nil then changes.maxMembers = payload.maxMembers end
    if next(changes) then
        Factions.updateSettings(fid, actor, changes, 'admin /editfaction')
    end

    -- HQ: aplicam doar daca s-a trimis ceva (enter/exit ca {x,y,z,h} sau vw)
    local enter = (type(payload.enter) == 'table') and payload.enter or e.row.hq and e.row.hq.enter or nil
    local exitp = (type(payload.exit)  == 'table') and payload.exit  or e.row.hq and e.row.hq.leave or nil
    local vw    = tonumber(payload.vw)
    if type(payload.enter) == 'table' or type(payload.exit) == 'table' or vw ~= nil then
        vw = math.max(0, math.floor(vw or (e.row.hq and e.row.hq.vw) or 0))
        Factions.setHQ(fid, actor, enter, exitp, vw ~= 0 and vw or (1000 + fid))
    end

    Framework.Notify(src, ('Faction #%d updated.'):format(fid), 'success')
    for _, pid in ipairs(GetPlayers()) do Members.pushState(tonumber(pid)) end
end)

RegisterNetEvent('rpg-factions:adminDelete', function(fid)
    local src = source
    if not ownerOnly(src) then return end
    fid = tonumber(fid)
    if not fid then return end
    local ok = Factions.delete(fid, actorUid(src))
    Framework.Notify(src, ok and ('Faction #%d deleted.'):format(fid) or 'Delete failed.', ok and 'success' or 'error')
    for _, pid in ipairs(GetPlayers()) do Members.pushState(tonumber(pid)) end
end)

-- ---- exports (pt. alte resurse) ---------------------------------
exports('getFaction', function(src) return Framework.GetGroup(src) end)
exports('getRank', function(src)
    src = tonumber(src); if not src or src <= 0 then return 0 end
    local okp, st = pcall(function() return Player(src).state end)
    return (okp and st and st.factionRank) or 0
end)
exports('hasPermission', function(src, perm)
    local ctx = Perms.contextOf(Framework.GetUserId(src)); return ctx and Perms.has(ctx, perm) or false
end)
exports('getFactionData', function(fid) local e = Factions.get(fid); return e and e.row or nil end)
exports('getRankLabel', function(fid, order)
    local rk = Factions.rank(tonumber(fid) or 0, tonumber(order) or 0)
    return rk and rk.label or ('Rank ' .. tostring(order))
end)
exports('onlineMembers', function(fid)
    fid = tonumber(fid) or 0
    local out = {}
    if fid == 0 then return out end
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if Framework.GetGroup(t) == fid then out[#out + 1] = t end
    end
    return out
end)

-- ===========================================================================
--  /f [text]  — CHAT DE FACTIUNE  (culoare = culoarea factiunii)
--  Render (rpg-hud):  [/f] [numar rank] RankLabel Username (id): text
-- ===========================================================================
local function factionChat(src, text)
    text = tostring(text or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if text == '' then return end

    local fid = Framework.GetGroup(src)
    if not fid or fid == 0 then
        return Framework.Notify(src, 'You are not in a faction.', 'error')
    end
    local e = Factions.get(fid); if not e then return end

    local uid = Framework.GetUserId(src)
    local ctx = uid and Perms.contextOf(uid) or nil
    local rankOrder = (ctx and ctx.rankOrder) or 0
    local rk = Factions.rank(fid, rankOrder)

    local name = Framework.GetName(src)
    local charId = 0
    local okc, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    if okc and ch and ch.id then charId = ch.id end

    local payload = {
        channel     = 'FCHAT',
        factionChat = true,
        color       = e.row.color or '#3498db',
        rankNum     = rankOrder,
        rankLabel   = (rk and rk.label) or ('Rank ' .. rankOrder),
        author      = name,
        id          = charId,
        text        = text,
        time        = os.date('%H:%M'),
    }

    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        if Framework.GetGroup(t) == fid then
            TriggerClientEvent('rpg-hud:chatMessage', t, payload)
        end
    end
    print(('[faction-chat #%d] %s (%s): %s'):format(fid, name, tostring(charId), text))
end

RegisterCommand('f', function(src, args, raw)
    if src <= 0 then return end
    factionChat(src, raw:match('^%S+%s+(.*)$') or '')
end, false)
