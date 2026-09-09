-- ===========================================================================
--  rpg-factions — MEMBERS  (server)
--  invite / join / leave / kick / promote / demote / warning / supervisor /
--  tester / permissions + lista de membri. Toate trec prin Sec.gate.
--  Scrierile pe users.* sunt conditionate (WHERE ... AND `group`=? AND group_rank=?)
--  -> concurenta sigura (§37): daca starea s-a schimbat, 0 randuri afectate.
-- ===========================================================================

Members = {}

local RESET_SQL = [[
    UPDATE users SET `group`=0, group_rank=0, group_join=NULL, group_warning=0,
        group_supervisor=0, group_tester=0, group_permissions=NULL
    WHERE id=? AND `group`=?
]]

-- ---- helper: seteaza statebag-urile pt. un src online -------------
function Members.pushState(src)
    if not src or src <= 0 then return end
    local uid = Framework.GetUserId(src); if not uid then return end
    local u = DB.userRow(uid)
    local st = Player(src).state
    local fid = tonumber(u and u.group) or 0
    st:set('faction', fid, true)
    st:set('factionRank', tonumber(u and u.group_rank) or 0, true)
    st:set('factionSupervisor', (tonumber(u and u.group_supervisor) or 0) == 1, true)
    st:set('factionTester', (tonumber(u and u.group_tester) or 0) == 1, true)
    TriggerClientEvent('rpg-factions:sync', src, Members.selfPayload(uid))
end

-- ---- payload "eu" (pt. NUI dashboard) -------------------------
function Members.selfPayload(uid)
    local ctx = Perms.contextOf(uid)
    if not ctx then return { inFaction = false } end
    local e = Factions.get(ctx.fid)
    local rank = Factions.rank(ctx.fid, ctx.rankOrder)
    return {
        inFaction  = true,
        faction    = { id = e.row.id, name = e.row.name, color = e.row.color, type = e.row.type,
                       hasHQ = (e.row.hq.vw or 0) ~= 0, members = DB.memberCount(ctx.fid),
                       leader = e.row.leader, manager = e.row.manager,
                       minLevel = e.row.minLevel, minHours = e.row.minHours,
                       maxMembers = e.row.maxMembers, application = e.row.application,
                       hq = { enter = e.row.hq.enter, leave = e.row.hq.leave, vw = e.row.hq.vw } },
        rank       = { order = ctx.rankOrder, label = rank and rank.label or ('Rank ' .. ctx.rankOrder),
                       isLeader = rank and rank.isLeader or false, isColeader = rank and rank.isColeader or false },
        supervisor = ctx.supervisor,
        tester     = ctx.tester,
        warning    = ctx.warning,
        warningMax = Config.Warning.max,
        joinDate   = tostring(ctx.joinDate or ''),
        perms      = Perms.effective(ctx),
        ranks      = (function() local o = {}; for _, ord in ipairs(Factions.rankOrders(ctx.fid)) do
                        local rk = Factions.rank(ctx.fid, ord); o[#o+1] = { order = ord, label = rk.label } end return o end)(),
        permKeys   = Config.Permissions,
    }
end

-- ===========================================================================
--  INVITE  (§20)  — actorul invita un player ONLINE
-- ===========================================================================
function Members.invite(src, targetSrc)
    local actorCtx = Sec.gate({ src = src, event = 'invite', needPerm = 'invite' })
    if not actorCtx then return end

    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(targetSrc) then
        return Framework.Notify(src, 'Player not found / offline.', 'error')
    end
    local tuid = Framework.GetUserId(targetSrc)
    if not tuid then return Framework.Notify(src, 'Player not found.', 'error') end
    if tuid == actorCtx.uid then return Framework.Notify(src, 'You cannot invite yourself.', 'error') end

    if (Framework.GetGroup(targetSrc) or 0) ~= 0 then
        return Framework.Notify(src, 'That player is already in a faction.', 'error')
    end

    local e = Factions.get(actorCtx.fid)
    if e.row.maxMembers > 0 and DB.memberCount(actorCtx.fid) >= e.row.maxMembers then
        return Framework.Notify(src, 'Faction is full.', 'error')
    end
    if Framework.GetLevel(targetSrc) < e.row.minLevel then
        return Framework.Notify(src, ('Player needs level %d.'):format(e.row.minLevel), 'error')
    end
    if Framework.GetPlaytimeHours(targetSrc) < e.row.minHours then
        return Framework.Notify(src, ('Player needs %d hours played.'):format(e.row.minHours), 'error')
    end

    -- invitatie pending catre target (acceptare = client trimite rpg-factions:acceptInvite)
    TriggerClientEvent('rpg-factions:invited', targetSrc, {
        fid = e.row.id, name = e.row.name, color = e.row.color, by = Framework.GetName(src),
    })
    Framework.Notify(src, ('Invite sent to %s.'):format(Framework.GetName(targetSrc)), 'success')
    Logs.write({ faction = actorCtx.fid, actor = actorCtx.uid, target = tuid, action = 'MEMBER_INVITED',
                 reason = Framework.GetName(targetSrc) })
end

-- target accepta invitatia -> JOIN
function Members.acceptInvite(src, fid)
    fid = tonumber(fid)
    local e = Factions.get(fid)
    if not e then return Framework.Notify(src, 'Faction no longer exists.', 'error') end
    if (Framework.GetGroup(src) or 0) ~= 0 then
        return Framework.Notify(src, 'You are already in a faction.', 'error')
    end
    if e.row.maxMembers > 0 and DB.memberCount(fid) >= e.row.maxMembers then
        return Framework.Notify(src, 'Faction is full.', 'error')
    end
    -- re-verifica eligibilitatea (invitatia poate fi veche)
    if Framework.GetLevel(src) < e.row.minLevel or Framework.GetPlaytimeHours(src) < e.row.minHours then
        return Framework.Notify(src, 'You no longer meet the requirements.', 'error')
    end
    Members._join(src, fid, e.row.initialRank, nil, 'MEMBER_JOINED', 'invite accepted')
end

-- ---- JOIN intern (folosit de acceptInvite + applications.accept) ----
function Members._join(src, fid, rankOrder, actorUid, action, reason)
    local uid = Framework.GetUserId(src)
    if not uid then return false end
    local e = Factions.get(fid); if not e then return false end
    rankOrder = e.ranks[tonumber(rankOrder)] and tonumber(rankOrder) or e.row.initialRank

    local affected = MySQL.update.await([[
        UPDATE users SET `group`=?, group_rank=?, group_join=NOW(), group_warning=0,
            group_supervisor=0, group_tester=0, group_permissions='{}'
        WHERE id=? AND `group`=0
    ]], { fid, rankOrder, uid })
    if not affected or affected < 1 then
        Framework.Notify(src, 'Join failed (already in a faction?).', 'error')
        return false
    end

    Members.pushState(src)
    Framework.Notify(src, ('You joined %s.'):format(e.row.name), 'success')
    Logs.write({ faction = fid, actor = actorUid or uid, target = uid, action = action or 'MEMBER_JOINED',
                 reason = reason or '', new = { group = fid, group_rank = rankOrder } })
    return true
end

-- ===========================================================================
--  LEAVE (self)  /  KICK (actor -> target)
-- ===========================================================================
function Members.leave(src)
    local uid = Framework.GetUserId(src)
    local fid = Framework.GetGroup(src) or 0
    if fid == 0 then return Framework.Notify(src, 'You are not in a faction.', 'error') end
    local e = Factions.get(fid)
    if e and e.row.leader == uid then
        return Framework.Notify(src, 'Transfer leadership before leaving.', 'error')
    end
    local affected = MySQL.update.await(RESET_SQL, { uid, fid })
    if affected and affected >= 1 then
        if e and e.row.manager == uid then MySQL.update.await('UPDATE factions SET manager=0 WHERE id=?', { fid }); Factions.invalidate(fid) end
        Members.pushState(src)
        Framework.Notify(src, 'You left the faction.', 'info')
        Logs.write({ faction = fid, actor = uid, target = uid, action = 'MEMBER_LEFT' })
    end
end

function Members.kick(src, targetUid, reason)
    local actorCtx, targetCtx = Sec.gate({ src = src, event = 'kick', needPerm = 'kick', targetUserId = targetUid })
    if not actorCtx then return end
    local fid = actorCtx.fid
    local affected = MySQL.update.await(RESET_SQL, { targetCtx.uid, fid })
    if affected and affected >= 1 then
        local e = Factions.get(fid)
        if e and e.row.manager == targetCtx.uid then MySQL.update.await('UPDATE factions SET manager=0 WHERE id=?', { fid }); Factions.invalidate(fid) end
        local tsrc = Framework.GetSrcByUserId(targetCtx.uid)
        if tsrc then Members.pushState(tsrc); Framework.Notify(tsrc, 'You were removed from the faction.', 'error') end
        Framework.Notify(src, ('%s was kicked.'):format(targetCtx.name), 'success')
        Logs.write({ faction = fid, actor = actorCtx.uid, target = targetCtx.uid, action = 'MEMBER_KICKED',
                     reason = tostring(reason or ''):sub(1, 255), old = { group_rank = targetCtx.rankOrder } })
    end
end

-- ===========================================================================
--  PROMOTE / DEMOTE
-- ===========================================================================
local function changeRank(src, targetUid, dir, reason)
    local event = dir > 0 and 'promote' or 'demote'
    local actorCtx, targetCtx = Sec.gate({ src = src, event = event, needPerm = event, targetUserId = targetUid })
    if not actorCtx then return end

    local fid = actorCtx.fid
    local orders = Factions.rankOrders(fid)
    -- urmatorul rank in directia ceruta
    local cur = targetCtx.rankOrder
    local newOrder
    for i, o in ipairs(orders) do
        if o == cur then
            newOrder = orders[i + dir]
            break
        end
    end
    if not newOrder then return Framework.Notify(src, dir > 0 and 'Already at the top.' or 'Already at the bottom.', 'error') end

    if dir > 0 then
        local maxAssign = Perms.maxAssignableOrder(actorCtx)
        if newOrder > maxAssign then
            Logs.suspect(src, 'INVALID_RANK', ('promote above cap (%d>%d)'):format(newOrder, maxAssign), fid, targetCtx.uid)
            return Framework.Notify(src, 'You cannot promote that high.', 'error')
        end
        local nrk = Factions.rank(fid, newOrder)
        if nrk and nrk.isLeader then
            return Framework.Notify(src, 'Use "Set Leader" to transfer leadership.', 'error')
        end
    end

    -- scriere conditionata (concurenta): rank-ul target trebuie sa fie inca `cur`
    local affected = MySQL.update.await(
        'UPDATE users SET group_rank=? WHERE id=? AND `group`=? AND group_rank=?',
        { newOrder, targetCtx.uid, fid, cur })
    if not affected or affected < 1 then
        return Framework.Notify(src, 'Member rank changed meanwhile. Retry.', 'error')
    end

    local tsrc = Framework.GetSrcByUserId(targetCtx.uid)
    if tsrc then Members.pushState(tsrc) end
    local nrk = Factions.rank(fid, newOrder)
    Framework.Notify(src, ('%s -> %s.'):format(targetCtx.name, nrk and nrk.label or ('Rank ' .. newOrder)), 'success')
    Logs.write({ faction = fid, actor = actorCtx.uid, target = targetCtx.uid,
                 action = dir > 0 and 'MEMBER_PROMOTED' or 'MEMBER_DEMOTED',
                 reason = tostring(reason or ''):sub(1, 255),
                 old = { group_rank = cur }, new = { group_rank = newOrder } })
end
function Members.promote(src, t, r) changeRank(src, t, 1, r) end
function Members.demote(src, t, r) changeRank(src, t, -1, r) end

-- ===========================================================================
--  WARNING (§23)  — delta clamped, log obligatoriu
-- ===========================================================================
function Members.warning(src, targetUid, delta, reason)
    local actorCtx, targetCtx = Sec.gate({ src = src, event = 'warning', needPerm = 'manage_warnings',
                                           targetUserId = targetUid })
    if not actorCtx then return end
    delta = math.floor(tonumber(delta) or 0)
    if delta == 0 or delta < -Config.Warning.max or delta > Config.Warning.max then
        Logs.suspect(src, 'INVALID_WARNING', 'delta ' .. tostring(delta), actorCtx.fid, targetCtx.uid)
        return Framework.Notify(src, 'Invalid warning amount.', 'error')
    end
    local old = targetCtx.warning
    local new = math.max(Config.Warning.min, math.min(Config.Warning.max, old + delta))
    if new == old then return Framework.Notify(src, 'No change (already at bound).', 'info') end

    -- conditionat pe valoarea veche (concurenta)
    local affected = MySQL.update.await(
        'UPDATE users SET group_warning=? WHERE id=? AND `group`=? AND group_warning=?',
        { new, targetCtx.uid, actorCtx.fid, old })
    if not affected or affected < 1 then
        return Framework.Notify(src, 'Warning changed meanwhile. Retry.', 'error')
    end

    local tsrc = Framework.GetSrcByUserId(targetCtx.uid)
    if tsrc then
        Members.pushState(tsrc)
        Framework.Notify(tsrc, ('Warning points: %d -> %d (%s)'):format(old, new, reason or 'no reason'),
            delta > 0 and 'error' or 'info')
    end
    Framework.Notify(src, ('%s warnings: %d -> %d.'):format(targetCtx.name, old, new), 'success')
    Logs.write({ faction = actorCtx.fid, actor = actorCtx.uid, target = targetCtx.uid,
                 action = delta > 0 and 'WARNING_ADDED' or 'WARNING_REMOVED',
                 reason = tostring(reason or ''):sub(1, 255),
                 old = { group_warning = old }, new = { group_warning = new } })
end

-- ===========================================================================
--  SUPERVISOR / TESTER  (0/1)
-- ===========================================================================
local function setFlag(src, targetUid, column, value, permName, addAction, remAction)
    local actorCtx, targetCtx = Sec.gate({ src = src, event = column, needPerm = permName, targetUserId = targetUid })
    if not actorCtx then return end
    value = value and 1 or 0
    MySQL.update.await(('UPDATE users SET %s=? WHERE id=? AND `group`=?'):format(column),
        { value, targetCtx.uid, actorCtx.fid })
    local tsrc = Framework.GetSrcByUserId(targetCtx.uid)
    if tsrc then Members.pushState(tsrc) end
    Framework.Notify(src, ('%s %s: %s.'):format(targetCtx.name, column, value == 1 and 'YES' or 'NO'), 'success')
    Logs.write({ faction = actorCtx.fid, actor = actorCtx.uid, target = targetCtx.uid,
                 action = value == 1 and addAction or remAction,
                 old = { [column] = value == 1 and 0 or 1 }, new = { [column] = value } })
end
function Members.setSupervisor(src, t, v) setFlag(src, t, 'group_supervisor', v, 'manage_supervisors', 'SUPERVISOR_ADDED', 'SUPERVISOR_REMOVED') end
function Members.setTester(src, t, v)     setFlag(src, t, 'group_tester',     v, 'manage_testers',     'TESTER_ADDED',     'TESTER_REMOVED') end

-- ===========================================================================
--  INDIVIDUAL PERMISSIONS  (§25.10, §25.11)
-- ===========================================================================
function Members.setPermissions(src, targetUid, permMap)
    local actorCtx, targetCtx = Sec.gate({ src = src, event = 'setPermissions', needPerm = 'manage_permissions',
                                           targetUserId = targetUid })
    if not actorCtx then return end
    if type(permMap) ~= 'table' then return end

    -- normalizeaza + valideaza cheile
    local clean = {}
    for k, v in pairs(permMap) do
        if k == '*' or Config._PermSet[k] then clean[k] = (v == true) end
    end
    -- actorul poate acorda doar ce detine (§25.11)
    local ok, bad = Perms.canGrantAll(actorCtx, clean)
    if not ok then
        Logs.suspect(src, 'INVALID_PERMISSION', 'grant not owned: ' .. tostring(bad), actorCtx.fid, targetCtx.uid)
        return Framework.Notify(src, ('You cannot grant "%s".'):format(tostring(bad)), 'error')
    end

    local old = targetCtx.individual
    MySQL.update.await('UPDATE users SET group_permissions=? WHERE id=? AND `group`=?',
        { DB.encode(clean), targetCtx.uid, actorCtx.fid })
    local tsrc = Framework.GetSrcByUserId(targetCtx.uid)
    if tsrc then Members.pushState(tsrc) end
    Framework.Notify(src, ('Updated permissions for %s.'):format(targetCtx.name), 'success')
    Logs.write({ faction = actorCtx.fid, actor = actorCtx.uid, target = targetCtx.uid,
                 action = 'PERMISSION_UPDATED', old = old, new = clean })
end

-- ===========================================================================
--  LISTA DE MEMBRI  (§31)  — necesita view_members
-- ===========================================================================
function Members.list(src)
    local actorCtx = Sec.gate({ src = src, event = 'listMembers', needPerm = 'view_members' })
    if not actorCtx then return end
    local fid = actorCtx.fid
    local online = Framework.OnlineUserIds()

    local rows = MySQL.query.await([[
        SELECT id, username, level, playtime, group_rank, group_join,
               group_warning, group_supervisor, group_tester, group_permissions
        FROM users WHERE `group` = ? ORDER BY group_rank DESC, username ASC
    ]], { fid }) or {}

    local out = {}
    for _, r in ipairs(rows) do
        local rk = Factions.rank(fid, tonumber(r.group_rank))
        out[#out + 1] = {
            id         = tonumber(r.id),
            name       = r.username,
            rank       = rk and rk.label or ('Rank ' .. tostring(r.group_rank)),
            rankOrder  = tonumber(r.group_rank),
            joinDate   = tostring(r.group_join or ''),
            warning    = tonumber(r.group_warning) or 0,
            supervisor = (tonumber(r.group_supervisor) or 0) == 1,
            tester     = (tonumber(r.group_tester) or 0) == 1,
            level      = tonumber(r.level) or 0,
            hours      = math.floor((tonumber(r.playtime) or 0) / (Config.PlaytimeSecondsPerHour or 3600)),
            online     = online[tonumber(r.id)] ~= nil,
            individual = DB.decode(r.group_permissions),
        }
    end
    TriggerClientEvent('rpg-factions:membersData', src, { members = out })
end
