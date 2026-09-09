-- ===========================================================================
--  rpg-factions — PERMISSIONS  (server)
--  Rezolvarea permisiunilor EFECTIVE + verificarile de ierarhie.
--
--  Effective = Rank Permissions  ⊕  Supervisor/Tester sets  ⊕  Individual (group_permissions)
--    - Individual explicit (true/false) SUPRASCRIE tot.
--    - '*' (wildcard) acorda toate NE-critice.
--    - Permisiunile CRITICE (Config.CriticalPermissions) se acorda DOAR prin:
--         individual[perm] == true   SAU   rank.is_leader == 1
-- ===========================================================================

Perms = {}

-- context de membru dintr-un users.id (citit FRESH din DB). nil = nu e in facțiune.
function Perms.contextOf(uid)
    uid = tonumber(uid); if not uid then return nil end
    local u = DB.userRow(uid)
    if not u or (tonumber(u.group) or 0) == 0 then return nil end
    local fid = tonumber(u.group)
    if not Factions.exists(fid) then return nil end
    return {
        uid        = uid,
        fid        = fid,
        rankOrder  = tonumber(u.group_rank) or 0,
        supervisor = (tonumber(u.group_supervisor) or 0) == 1,
        tester     = (tonumber(u.group_tester) or 0) == 1,
        individual = DB.decode(u.group_permissions),
        warning    = tonumber(u.group_warning) or 0,
        level      = tonumber(u.level) or 0,
        name       = u.username,
        joinDate   = u.group_join,
    }
end

-- true/false pentru o singura permisiune
function Perms.has(ctx, perm)
    if not ctx then return false end
    local rank = Factions.rank(ctx.fid, ctx.rankOrder)
    local isLeaderRank = rank ~= nil and rank.isLeader

    -- 1. individual explicit -> castiga
    local ind = ctx.individual[perm]
    if type(ind) == 'boolean' then return ind end

    -- 2. permisiuni critice: doar leader-rank (individual explicit e deja tratat la pasul 1)
    if Config.CriticalPermissions[perm] then
        return isLeaderRank == true
    end

    -- 3. wildcard individual
    if ctx.individual['*'] == true then return true end

    -- 4. supervisor / tester
    if ctx.supervisor and Config.SupervisorPermissions[perm] then return true end
    if ctx.tester and Config.TesterPermissions[perm] then return true end

    -- 5. rank
    if rank then
        local rp = rank.perms[perm]
        if type(rp) == 'boolean' then return rp end
        if rank.perms['*'] == true then return true end
    end
    return false
end

-- setul complet de permisiuni efective (pt. UI)
function Perms.effective(ctx)
    local out = {}
    for _, p in ipairs(Config.Permissions) do out[p] = Perms.has(ctx, p) end
    return out
end

-- ---- IERARHIE -----------------------------------------------------
-- actorCtx poate acționa (kick/promote/demote/warning/perm) asupra targetului?
function Perms.canActOn(actorCtx, targetUid, targetRankOrder)
    if not actorCtx then return false end
    local e = Factions.get(actorCtx.fid); if not e then return false end
    -- liderul desemnat al facțiunii poate acționa asupra oricui (mai putin el insusi la unele op.)
    if e.row.leader == actorCtx.uid then
        return e.row.leader ~= targetUid or false   -- nu asupra propriei persoane pe aceasta cale
    end
    -- nimeni (in afara de leader) nu poate atinge userul-lider
    if e.row.leader == targetUid then return false end
    -- strict peste rank
    return actorCtx.rankOrder > (tonumber(targetRankOrder) or 0)
end

-- cel mai mare rank_order la care actorul poate promova pe cineva
function Perms.maxAssignableOrder(actorCtx)
    local e = Factions.get(actorCtx.fid); if not e then return 1 end
    if e.row.leader == actorCtx.uid then
        return math.max(1, e.leaderOrder - 1)   -- leaderul promoveaza pana la Co-Leader; Leader = transfer separat
    end
    return math.max(1, actorCtx.rankOrder - 1)
end

-- actorul incearca sa acorde `grantMap` (individual perms) unui target.
-- Returneaza (ok, badPerm). Nu poate acorda ce nu detine el insusi (§25.11).
function Perms.canGrantAll(actorCtx, grantMap)
    for k, v in pairs(grantMap or {}) do
        if k ~= '*' and not Config._PermSet[k] then return false, k end        -- cheie necunoscuta
        if v == true then
            if k == '*' then
                -- a acorda '*' cuiva necesita ca actorul sa fie leader-rank
                local rank = Factions.rank(actorCtx.fid, actorCtx.rankOrder)
                if not (rank and rank.isLeader) then return false, '*' end
            elseif not Perms.has(actorCtx, k) then
                return false, k
            end
        end
    end
    return true
end
