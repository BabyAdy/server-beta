-- ===========================================================================
--  rpg-factions — FACTIONS  (server)
--  Cache (faction + ranks), consistency checks la boot, CRUD facțiune / rank-uri
--  / HQ / leader / manager. DB = source of truth; cache-ul se invalideaza la
--  fiecare scriere.
-- ===========================================================================

Factions = {}
Factions.cache = {}   -- [fid] = { row, ranks = { [order] = rankObj }, leaderOrder, coleaderOrder }

local DBG = Config.Debug

-- ---- shaping -------------------------------------------------------
local function shapeFaction(r)
    return {
        id = tonumber(r.id), name = r.g_name, color = r.g_color, type = r.g_type,
        minLevel = tonumber(r.g_minlevel) or 0, minHours = tonumber(r.g_minhours) or 0,
        application = (tonumber(r.g_application) or 0) == 1,
        maxMembers = tonumber(r.g_maxmembers) or 0,
        leader = tonumber(r.leader) or 0, manager = tonumber(r.manager) or 0,
        initialRank = tonumber(r.initial_rank) or Config.DefaultInitialRank,
        hq = {
            enter = r.hq_enter_x ~= nil and { x = r.hq_enter_x + 0.0, y = r.hq_enter_y + 0.0, z = r.hq_enter_z + 0.0, h = (r.hq_enter_h or 0.0) + 0.0 } or nil,
            leave = r.hq_leave_x ~= nil and { x = r.hq_leave_x + 0.0, y = r.hq_leave_y + 0.0, z = r.hq_leave_z + 0.0, h = (r.hq_leave_h or 0.0) + 0.0 } or nil,
            vw = tonumber(r.hq_vw) or 0,
        },
    }
end
local function shapeRank(r)
    return {
        id = tonumber(r.id), order = tonumber(r.rank_order), name = r.name, label = r.label,
        perms = DB.decode(r.permissions), salary = tonumber(r.salary) or 0,
        isLeader = (tonumber(r.is_leader) or 0) == 1,
        isColeader = (tonumber(r.is_coleader) or 0) == 1,
    }
end

-- ---- cache ------------------------------------------------------
function Factions.load(fid)
    fid = tonumber(fid); if not fid then return nil end
    local frow = DB.factionRow(fid)
    if not frow then Factions.cache[fid] = nil; return nil end

    local entry = { row = shapeFaction(frow), ranks = {}, leaderOrder = 0, coleaderOrder = 0 }
    for _, rr in ipairs(DB.rankRows(fid)) do
        local rk = shapeRank(rr)
        entry.ranks[rk.order] = rk
        if rk.isLeader   and rk.order > entry.leaderOrder   then entry.leaderOrder   = rk.order end
        if rk.isColeader and rk.order > entry.coleaderOrder then entry.coleaderOrder = rk.order end
    end
    -- fallback: daca nimeni nu e marcat is_leader, cel mai mare order = leader
    if entry.leaderOrder == 0 then
        local mx = 0
        for o in pairs(entry.ranks) do if o > mx then mx = o end end
        entry.leaderOrder = mx
    end
    Factions.cache[fid] = entry
    return entry
end

function Factions.get(fid)
    fid = tonumber(fid); if not fid or fid == 0 then return nil end
    return Factions.cache[fid] or Factions.load(fid)
end

function Factions.invalidate(fid)
    Factions.cache[tonumber(fid)] = nil
    Factions.load(fid)
    TriggerEvent('rpg-factions:_factionChanged', tonumber(fid))
end

function Factions.rank(fid, order)
    local e = Factions.get(fid)
    return e and e.ranks[tonumber(order)] or nil
end
function Factions.leaderOrder(fid)
    local e = Factions.get(fid); return e and e.leaderOrder or 0
end
function Factions.exists(fid)
    return Factions.get(fid) ~= nil
end
function Factions.rankOrders(fid)
    local e = Factions.get(fid); local list = {}
    if e then for o in pairs(e.ranks) do list[#list + 1] = o end end
    table.sort(list)
    return list
end

-- ---- BOOT: consistency checks (§35) --------------------------------
function Factions.audit()
    -- incarca toate facțiunile
    local frows = MySQL.query.await('SELECT id FROM factions') or {}
    local valid = {}
    for _, r in ipairs(frows) do valid[tonumber(r.id)] = true; Factions.load(r.id) end

    -- Caz 2: user.group pointeaza catre o facțiune inexistenta -> reset
    local orphans = MySQL.query.await(
        'SELECT id, `group` FROM users WHERE `group` <> 0') or {}
    for _, u in ipairs(orphans) do
        local fid = tonumber(u.group)
        if not valid[fid] then
            MySQL.update.await([[
                UPDATE users SET `group`=0, group_rank=0, group_join=NULL, group_warning=0,
                    group_supervisor=0, group_tester=0, group_permissions=NULL WHERE id=?
            ]], { u.id })
            print(('[rpg-factions][audit] user #%s: facțiunea #%s inexistenta -> unemployed'):format(u.id, tostring(fid)))
        else
            -- Caz 3: group_rank invalid -> initial_rank
            local e = Factions.cache[fid]
            local urow = MySQL.single.await('SELECT group_rank FROM users WHERE id=?', { u.id })
            local ro = tonumber(urow and urow.group_rank) or 0
            if not (e and e.ranks[ro]) then
                MySQL.update.await('UPDATE users SET group_rank=? WHERE id=?', { e.row.initialRank, u.id })
                print(('[rpg-factions][audit] user #%s: rank %s invalid -> %d'):format(u.id, tostring(ro), e.row.initialRank))
            end
        end
    end

    -- Caz 1 & 4: leader/manager inconsistenti
    for fid in pairs(valid) do
        local e = Factions.cache[fid]
        for _, key in ipairs({ 'leader', 'manager' }) do
            local uid = e.row[key]
            if uid ~= 0 then
                local urow = MySQL.single.await('SELECT id, `group`, group_rank FROM users WHERE id=?', { uid })
                if not urow then
                    MySQL.update.await(('UPDATE factions SET %s=0 WHERE id=?'):format(key), { fid })
                    print(('[rpg-factions][audit] faction #%d: %s #%d inexistent -> 0'):format(fid, key, uid))
                elseif tonumber(urow.group) ~= fid then
                    MySQL.update.await(('UPDATE factions SET %s=0 WHERE id=?'):format(key), { fid })
                    print(('[rpg-factions][audit] faction #%d: %s #%d in alta facțiune -> 0'):format(fid, key, uid))
                elseif key == 'leader' and tonumber(urow.group_rank) ~= e.leaderOrder then
                    MySQL.update.await('UPDATE users SET group_rank=? WHERE id=?', { e.leaderOrder, uid })
                    print(('[rpg-factions][audit] faction #%d: leader #%d rank corectat -> %d'):format(fid, uid, e.leaderOrder))
                end
            end
        end
        Factions.invalidate(fid)
    end

    if DBG then print(('[rpg-factions] audit done — %d facțiuni'):format(#frows)) end
end

-- ---- CREATE (admin / consola) ------------------------------------
function Factions.create(actorUid, data)
    data = data or {}
    local name = tostring(data.name or ''):sub(1, 64)
    if name == '' then return nil, 'name_required' end
    if MySQL.scalar.await('SELECT 1 FROM factions WHERE g_name = ? LIMIT 1', { name }) then
        return nil, 'name_taken'
    end
    local color = tostring(data.color or '#3498db'):sub(1, 9)
    local ftype = tostring(data.type or 'other'):sub(1, 32)

    local fid = MySQL.insert.await([[
        INSERT INTO factions (g_name, g_color, g_type, g_minlevel, g_minhours, g_application, g_maxmembers, initial_rank)
        VALUES (?, ?, ?, ?, ?, 0, ?, ?)
    ]], {
        name, color, ftype,
        tonumber(data.minLevel) or 0, tonumber(data.minHours) or 0,
        tonumber(data.maxMembers) or 0, Config.DefaultInitialRank,
    })
    if not fid then return nil, 'db_error' end

    for _, rk in ipairs(Config.DefaultRanks) do
        MySQL.insert.await([[
            INSERT INTO faction_ranks (faction_id, rank_order, name, label, permissions, salary, is_leader, is_coleader)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        ]], {
            fid, rk.order, rk.name, rk.label, DB.encode(rk.permissions or {}),
            rk.salary or 0, rk.is_leader and 1 or 0, rk.is_coleader and 1 or 0,
        })
    end

    Factions.load(fid)
    Logs.write({ faction = fid, actor = actorUid or 0, action = 'FACTION_CREATED', reason = name,
                 new = { name = name, type = ftype, color = color } })
    return fid
end

-- ---- UPDATE SETTINGS -------------------------------------------
local SETTING_FIELDS = {
    name = { col = 'g_name', clamp = function(v) return tostring(v):sub(1, 64) end },
    color = { col = 'g_color', clamp = function(v) return tostring(v):sub(1, 9) end },
    type = { col = 'g_type', clamp = function(v) return tostring(v):sub(1, 32) end },
    minLevel = { col = 'g_minlevel', clamp = function(v) return math.max(0, math.floor(tonumber(v) or 0)) end },
    minHours = { col = 'g_minhours', clamp = function(v) return math.max(0, math.floor(tonumber(v) or 0)) end },
    application = { col = 'g_application', clamp = function(v) return (v == true or v == 1 or v == '1') and 1 or 0 end },
    maxMembers = { col = 'g_maxmembers', clamp = function(v) return math.max(0, math.floor(tonumber(v) or 0)) end },
}

function Factions.updateSettings(fid, actorUid, changes, reason)
    local e = Factions.get(fid); if not e then return false, 'no_faction' end
    local sets, params, old, new = {}, {}, {}, {}
    for key, rawVal in pairs(changes or {}) do
        local f = SETTING_FIELDS[key]
        if f then
            local v = f.clamp(rawVal)
            sets[#sets + 1] = ('`%s` = ?'):format(f.col)
            params[#params + 1] = v
            new[key] = v
        end
    end
    if #sets == 0 then return false, 'nothing' end
    -- old snapshot
    for k in pairs(new) do
        old[k] = ({
            name = e.row.name, color = e.row.color, type = e.row.type,
            minLevel = e.row.minLevel, minHours = e.row.minHours,
            application = e.row.application and 1 or 0, maxMembers = e.row.maxMembers,
        })[k]
    end
    params[#params + 1] = fid
    MySQL.update.await(('UPDATE factions SET %s WHERE id = ?'):format(table.concat(sets, ', ')), params)
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid, action = 'FACTION_SETTINGS_UPDATED', reason = reason or '', old = old, new = new })
    return true
end

-- ---- HQ --------------------------------------------------------
function Factions.setHQ(fid, actorUid, enter, leave, vw)
    local e = Factions.get(fid); if not e then return false, 'no_faction' end
    local function n(v) v = tonumber(v); return v end
    MySQL.update.await([[
        UPDATE factions SET
            hq_enter_x=?, hq_enter_y=?, hq_enter_z=?, hq_enter_h=?,
            hq_leave_x=?, hq_leave_y=?, hq_leave_z=?, hq_leave_h=?,
            hq_vw=?
        WHERE id=?
    ]], {
        enter and n(enter.x), enter and n(enter.y), enter and n(enter.z), enter and n(enter.h or 0),
        leave and n(leave.x), leave and n(leave.y), leave and n(leave.z), leave and n(leave.h or 0),
        math.max(0, math.floor(tonumber(vw) or 0)), fid,
    })
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid, action = 'HQ_UPDATED',
                 old = { hq = e.row.hq }, new = { enter = enter, leave = leave, vw = tonumber(vw) or 0 } })
    return true
end

-- ---- LEADER / MANAGER (tranzactional) --------------------------
function Factions.setLeader(fid, actorUid, newLeaderUid)
    local e = Factions.get(fid); if not e then return false, 'no_faction' end
    newLeaderUid = tonumber(newLeaderUid)
    if not newLeaderUid then return false, 'bad_target' end

    local nu = MySQL.single.await('SELECT id, `group` FROM users WHERE id=?', { newLeaderUid })
    if not nu or tonumber(nu.group) ~= fid then return false, 'target_not_member' end

    local leaderOrder = e.leaderOrder
    local demoteOrder = e.coleaderOrder ~= 0 and e.coleaderOrder or math.max(1, leaderOrder - 1)
    local oldLeaderUid = e.row.leader

    local q = {}
    if oldLeaderUid ~= 0 and oldLeaderUid ~= newLeaderUid then
        q[#q + 1] = { 'UPDATE users SET group_rank=? WHERE id=? AND `group`=?', { demoteOrder, oldLeaderUid, fid } }
    end
    q[#q + 1] = { 'UPDATE users SET group_rank=? WHERE id=? AND `group`=?', { leaderOrder, newLeaderUid, fid } }
    q[#q + 1] = { 'UPDATE factions SET leader=? WHERE id=?', { newLeaderUid, fid } }

    if not DB.transaction(q) then return false, 'db_error' end
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid, target = newLeaderUid, action = 'LEADER_CHANGED',
                 old = { leader = oldLeaderUid }, new = { leader = newLeaderUid } })
    return true
end

function Factions.setManager(fid, actorUid, newManagerUid)
    local e = Factions.get(fid); if not e then return false, 'no_faction' end
    newManagerUid = tonumber(newManagerUid) or 0
    if newManagerUid ~= 0 then
        local nu = MySQL.single.await('SELECT id, `group` FROM users WHERE id=?', { newManagerUid })
        if not nu or tonumber(nu.group) ~= fid then return false, 'target_not_member' end
    end
    local oldManagerUid = e.row.manager
    MySQL.update.await('UPDATE factions SET manager=? WHERE id=?', { newManagerUid, fid })
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid, target = newManagerUid, action = 'MANAGER_CHANGED',
                 old = { manager = oldManagerUid }, new = { manager = newManagerUid } })
    return true
end

-- ---- RANK UPDATE (label / salary / permissions) --------------
function Factions.rankUpdate(fid, actorUid, order, changes)
    local rk = Factions.rank(fid, order); if not rk then return false, 'no_rank' end
    local sets, params = {}, {}
    local old, new = {}, {}
    if changes.label ~= nil then sets[#sets+1] = 'label=?'; params[#params+1] = tostring(changes.label):sub(1,48); old.label = rk.label; new.label = params[#params] end
    if changes.salary ~= nil then sets[#sets+1] = 'salary=?'; params[#params+1] = math.max(0, math.floor(tonumber(changes.salary) or 0)); old.salary = rk.salary; new.salary = params[#params] end
    if type(changes.permissions) == 'table' then
        -- filtreaza doar cheile cunoscute + '*'
        local clean = {}
        for k, v in pairs(changes.permissions) do
            if k == '*' or Config._PermSet[k] then clean[k] = v == true end
        end
        sets[#sets+1] = 'permissions=?'; params[#params+1] = DB.encode(clean)
        old.permissions = rk.perms; new.permissions = clean
    end
    if #sets == 0 then return false, 'nothing' end
    params[#params+1] = rk.id
    MySQL.update.await(('UPDATE faction_ranks SET %s WHERE id=?'):format(table.concat(sets, ', ')), params)
    Factions.invalidate(fid)
    Logs.write({ faction = fid, actor = actorUid, action = 'PERMISSION_UPDATED', reason = ('rank %s'):format(rk.label),
                 old = old, new = new })
    return true
end

-- ---- DELETE FACTION -------------------------------------------
function Factions.delete(fid, actorUid)
    local e = Factions.get(fid); if not e then return false, 'no_faction' end
    -- reset toti membrii + sterge facțiunea (CASCADE: ranks, applications)
    local q = {
        { [[UPDATE users SET `group`=0, group_rank=0, group_join=NULL, group_warning=0,
             group_supervisor=0, group_tester=0, group_permissions=NULL WHERE `group`=?]], { fid } },
        { 'DELETE FROM factions WHERE id=?', { fid } },
    }
    if not DB.transaction(q) then return false, 'db_error' end
    Logs.write({ faction = fid, actor = actorUid, action = 'FACTION_DELETED', reason = e.row.name,
                 old = { name = e.row.name } })
    Factions.cache[fid] = nil
    TriggerEvent('rpg-factions:_factionChanged', fid)
    return true
end
