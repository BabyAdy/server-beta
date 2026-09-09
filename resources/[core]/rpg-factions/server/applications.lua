-- ===========================================================================
--  rpg-factions — APPLICATIONS  (server)  §14–§15
--  apply / cancel (self)  +  accept / reject (autorizat).
--  Concurenta (§37): "claiming" aplicatiei prin UPDATE conditionat
--  (WHERE status='pending') — doar UN actor obtine affected=1.
-- ===========================================================================

Applications = {}

-- ---- APPLY (self) ----------------------------------------------
function Applications.apply(src, fid, message)
    fid = tonumber(fid)
    local uid = Framework.GetUserId(src)
    if not uid then return end
    local e = Factions.get(fid)
    if not e then return Framework.Notify(src, 'Faction not found.', 'error') end

    if not e.row.application then
        return Framework.Notify(src, 'Applications are closed for this faction.', 'error')
    end
    if (Framework.GetGroup(src) or 0) ~= 0 then
        return Framework.Notify(src, 'You are already in a faction.', 'error')
    end

    local lvl = Framework.GetLevel(src)
    local hrs = Framework.GetPlaytimeHours(src)
    if lvl < e.row.minLevel then
        return Framework.Notify(src, ('You need level %d (you are %d).'):format(e.row.minLevel, lvl), 'error')
    end
    if hrs < e.row.minHours then
        return Framework.Notify(src, ('You need %d hours played (you have %.1f).'):format(e.row.minHours, hrs), 'error')
    end

    -- o singura aplicatie pending per (faction, user)
    local pending = MySQL.scalar.await(
        "SELECT id FROM faction_applications WHERE faction_id=? AND user_id=? AND status='pending' LIMIT 1",
        { fid, uid })
    if pending then
        return Framework.Notify(src, 'You already have a pending application.', 'error')
    end

    local appId = MySQL.insert.await([[
        INSERT INTO faction_applications (faction_id, user_id, status, message, snapshot)
        VALUES (?, ?, 'pending', ?, ?)
    ]], { fid, uid, tostring(message or ''):sub(1, 500), DB.encode({ level = lvl, hours = math.floor(hrs * 10) / 10 }) })

    Framework.Notify(src, ('Application sent to %s.'):format(e.row.name), 'success')
    Logs.write({ faction = fid, actor = uid, target = uid, action = 'APPLICATION_CREATED',
                 new = { level = lvl, hours = math.floor(hrs * 10) / 10 } })
    return appId
end

-- ---- CANCEL (self) -------------------------------------------
function Applications.cancel(src, appId)
    appId = tonumber(appId)
    local uid = Framework.GetUserId(src); if not uid or not appId then return end
    local affected = MySQL.update.await(
        "UPDATE faction_applications SET status='cancelled', updated_at=NOW() WHERE id=? AND user_id=? AND status='pending'",
        { appId, uid })
    if affected and affected >= 1 then
        local fid = MySQL.scalar.await('SELECT faction_id FROM faction_applications WHERE id=?', { appId })
        Framework.Notify(src, 'Application cancelled.', 'info')
        Logs.write({ faction = tonumber(fid) or 0, actor = uid, target = uid, action = 'APPLICATION_CANCELLED' })
    end
end

-- ---- ACCEPT (autorizat) -------------------------------------
function Applications.accept(src, appId)
    local actorCtx = Sec.gate({ src = src, event = 'acceptApp', needPerm = 'manage_applications' })
    if not actorCtx then return end
    appId = tonumber(appId); if not appId then return end
    local fid = actorCtx.fid

    local app = MySQL.single.await(
        "SELECT id, faction_id, user_id, status FROM faction_applications WHERE id=? LIMIT 1", { appId })
    if not app or tonumber(app.faction_id) ~= fid then
        Logs.suspect(src, 'INVALID_REQUEST', 'app not in faction', fid)
        return Framework.Notify(src, 'Application not found.', 'error')
    end
    if app.status ~= 'pending' then
        return Framework.Notify(src, 'Application already handled.', 'error')
    end
    local tuid = tonumber(app.user_id)

    local e = Factions.get(fid)
    if e.row.maxMembers > 0 and DB.memberCount(fid) >= e.row.maxMembers then
        return Framework.Notify(src, 'Faction is full.', 'error')
    end

    -- 1) "claim" aplicatia (conditionat pe pending) — un singur actor reuseste
    local claimed = MySQL.update.await(
        "UPDATE faction_applications SET status='accepted', reviewed_by=?, reviewed_at=NOW(), updated_at=NOW() WHERE id=? AND status='pending'",
        { actorCtx.uid, appId })
    if not claimed or claimed < 1 then
        return Framework.Notify(src, 'Application already handled by someone else.', 'error')
    end

    -- 2) baga userul in facțiune (conditionat pe `group`=0)
    local joined = MySQL.update.await([[
        UPDATE users SET `group`=?, group_rank=?, group_join=NOW(), group_warning=0,
            group_supervisor=0, group_tester=0, group_permissions='{}'
        WHERE id=? AND `group`=0
    ]], { fid, e.row.initialRank, tuid })

    if not joined or joined < 1 then
        -- compensare: userul a intrat deja altundeva -> revenim la pending
        MySQL.update.await("UPDATE faction_applications SET status='pending', reviewed_by=NULL, reviewed_at=NULL WHERE id=?", { appId })
        return Framework.Notify(src, 'Applicant joined another faction meanwhile.', 'error')
    end

    -- 3) auto-reject celelalte aplicatii pending ale userului
    MySQL.update.await(
        "UPDATE faction_applications SET status='rejected', updated_at=NOW() WHERE user_id=? AND status='pending'", { tuid })

    Logs.write({ faction = fid, actor = actorCtx.uid, target = tuid, action = 'APPLICATION_ACCEPTED' })
    Logs.write({ faction = fid, actor = actorCtx.uid, target = tuid, action = 'MEMBER_JOINED',
                 reason = 'application', new = { group = fid, group_rank = e.row.initialRank } })

    local tsrc = Framework.GetSrcByUserId(tuid)
    if tsrc then
        Members.pushState(tsrc)
        Framework.Notify(tsrc, ('Your application to %s was accepted.'):format(e.row.name), 'success')
    end
    Framework.Notify(src, 'Application accepted.', 'success')
end

-- ---- REJECT (autorizat) -----------------------------------
function Applications.reject(src, appId, reason)
    local actorCtx = Sec.gate({ src = src, event = 'rejectApp', needPerm = 'manage_applications' })
    if not actorCtx then return end
    appId = tonumber(appId); if not appId then return end

    local app = MySQL.single.await(
        "SELECT faction_id, user_id, status FROM faction_applications WHERE id=? LIMIT 1", { appId })
    if not app or tonumber(app.faction_id) ~= actorCtx.fid then
        return Framework.Notify(src, 'Application not found.', 'error')
    end
    local affected = MySQL.update.await(
        "UPDATE faction_applications SET status='rejected', reviewed_by=?, reviewed_at=NOW(), updated_at=NOW() WHERE id=? AND status='pending'",
        { actorCtx.uid, appId })
    if not affected or affected < 1 then
        return Framework.Notify(src, 'Application already handled.', 'error')
    end
    Logs.write({ faction = actorCtx.fid, actor = actorCtx.uid, target = tonumber(app.user_id),
                 action = 'APPLICATION_REJECTED', reason = tostring(reason or ''):sub(1, 255) })
    local tsrc = Framework.GetSrcByUserId(tonumber(app.user_id))
    if tsrc then Framework.Notify(tsrc, 'Your faction application was rejected.', 'error') end
    Framework.Notify(src, 'Application rejected.', 'info')
end

-- ---- LIST (autorizat) — §32 --------------------------------
function Applications.list(src)
    local actorCtx = Sec.gate({ src = src, event = 'listApps', needPerm = 'view_applications' })
    if not actorCtx then return end
    local rows = MySQL.query.await([[
        SELECT id, user_id, message, snapshot, created_at
        FROM faction_applications WHERE faction_id=? AND status='pending'
        ORDER BY id ASC LIMIT 100
    ]], { actorCtx.fid }) or {}

    local canManage = Perms.has(actorCtx, 'manage_applications')
    local out = {}
    for _, r in ipairs(rows) do
        local snap = DB.decode(r.snapshot)
        out[#out + 1] = {
            id      = tonumber(r.id),
            userId  = tonumber(r.user_id),
            name    = Framework.GetNameByUserId(r.user_id),
            level   = snap.level or Framework.GetLevelByUserId(r.user_id),
            hours   = snap.hours or math.floor(Framework.GetPlaytimeHoursByUserId(r.user_id) * 10) / 10,
            message = r.message or '',
            date    = tostring(r.created_at),
        }
    end
    TriggerClientEvent('rpg-factions:applicationsData', src, { applications = out, canManage = canManage })
end

-- aplicatiile PROPRII pending (pt. UI-ul de aplicare al playerului)
function Applications.mine(src)
    local uid = Framework.GetUserId(src); if not uid then return end
    local rows = MySQL.query.await([[
        SELECT a.id, a.faction_id, a.status, a.created_at, f.g_name
        FROM faction_applications a JOIN factions f ON f.id = a.faction_id
        WHERE a.user_id=? AND a.status='pending' ORDER BY a.id DESC
    ]], { uid }) or {}
    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = { id = tonumber(r.id), factionId = tonumber(r.faction_id), faction = r.g_name, date = tostring(r.created_at) }
    end
    TriggerClientEvent('rpg-factions:myApplications', src, { list = out })
end
