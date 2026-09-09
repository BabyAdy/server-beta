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
    local actorCtx = Sec.gate({ src = source, event = 'listLogs', needPerm = 'view_logs' })
    if not actorCtx then return end
    TriggerClientEvent('rpg-factions:logsData', source, Logs.page(actorCtx.fid, page, Config.Security.maxLogsPerPage))
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
    local actorCtx = Sec.gate({ src = source, event = 'setLeader', needPerm = 'set_leader' })
    if not actorCtx then return end
    local ok, err = Factions.setLeader(actorCtx.fid, actorCtx.uid, uid)
    Framework.Notify(source, ok and 'Leadership transferred.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
    if ok then Members.pushState(source); local ts = Framework.GetSrcByUserId(tonumber(uid)); if ts then Members.pushState(ts) end end
end)

RegisterNetEvent('rpg-factions:setManager', function(uid)
    local actorCtx = Sec.gate({ src = source, event = 'setManager', needPerm = 'set_manager' })
    if not actorCtx then return end
    local ok, err = Factions.setManager(actorCtx.fid, actorCtx.uid, uid)
    Framework.Notify(source, ok and 'Manager updated.' or ('Failed: ' .. tostring(err)), ok and 'success' or 'error')
    if ok then Members.pushState(source) end
end)

RegisterNetEvent('rpg-factions:updateSettings', function(changes)
    local actorCtx = Sec.gate({ src = source, event = 'updateSettings', needPerm = 'manage_settings' })
    if not actorCtx then return end
    local ok = Factions.updateSettings(actorCtx.fid, actorCtx.uid, changes, 'via menu')
    Framework.Notify(source, ok and 'Settings updated.' or 'Update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(source) end
end)

RegisterNetEvent('rpg-factions:updateRank', function(order, changes)
    local actorCtx = Sec.gate({ src = source, event = 'updateRank', needPerm = 'manage_ranks' })
    if not actorCtx then return end
    local ok = Factions.rankUpdate(actorCtx.fid, actorCtx.uid, order, changes or {})
    Framework.Notify(source, ok and 'Rank updated.' or 'Update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(source) end
end)

RegisterNetEvent('rpg-factions:setHQ', function(payload)
    local actorCtx = Sec.gate({ src = source, event = 'setHQ', needPerm = 'manage_hq' })
    if not actorCtx then return end
    payload = payload or {}
    -- coords vin din pozitia SERVER a ped-ului (nu din client) daca payload.useMyPos
    local ped = GetPlayerPed(source)
    local c = GetEntityCoords(ped); local h = GetEntityHeading(ped)
    local here = { x = c.x, y = c.y, z = c.z, h = h }
    local e = Factions.get(actorCtx.fid)
    local enter = e.row.hq.enter
    local leave = e.row.hq.leave
    local vw    = e.row.hq.vw ~= 0 and e.row.hq.vw or (1000 + actorCtx.fid)
    if payload.point == 'enter' then enter = here
    elseif payload.point == 'leave' then leave = here
    elseif payload.vw ~= nil then vw = math.max(0, math.floor(tonumber(payload.vw) or 0)) end
    local ok = Factions.setHQ(actorCtx.fid, actorCtx.uid, enter, leave, vw)
    Framework.Notify(source, ok and 'HQ updated.' or 'HQ update failed.', ok and 'success' or 'error')
    if ok then Members.pushState(source) end
end)

RegisterNetEvent('rpg-factions:apply',             function(fid, msg) Applications.apply(source, fid, msg) end)
RegisterNetEvent('rpg-factions:cancelApplication', function(appId) Applications.cancel(source, appId) end)
RegisterNetEvent('rpg-factions:acceptApplication', function(appId) Applications.accept(source, appId) end)
RegisterNetEvent('rpg-factions:rejectApplication', function(appId, reason) Applications.reject(source, appId, reason) end)

RegisterNetEvent('rpg-factions:browseFactions', function()
    local rows = MySQL.query.await(
        "SELECT id, g_name, g_color, g_type, g_minlevel, g_minhours FROM factions WHERE g_application = 1 ORDER BY g_name ASC") or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { id = tonumber(r.id), name = r.g_name, color = r.g_color, type = r.g_type,
                          minLevel = tonumber(r.g_minlevel) or 0, minHours = tonumber(r.g_minhours) or 0 }
    end
    TriggerClientEvent('rpg-factions:factionsList', source, {
        factions = out,
        me = { level = Framework.GetLevel(source), hours = math.floor(Framework.GetPlaytimeHours(source) * 10) / 10,
               inFaction = (Framework.GetGroup(source) or 0) ~= 0 },
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

-- ---- exports (pt. alte resurse) ---------------------------------
exports('getFaction', function(src) return Framework.GetGroup(src) end)
exports('getRank', function(src) local st = Player(src).state return st and st.factionRank or 0 end)
exports('hasPermission', function(src, perm)
    local ctx = Perms.contextOf(Framework.GetUserId(src)); return ctx and Perms.has(ctx, perm) or false
end)
exports('getFactionData', function(fid) local e = Factions.get(fid); return e and e.row or nil end)
