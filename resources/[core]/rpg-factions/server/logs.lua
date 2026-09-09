-- ===========================================================================
--  rpg-factions — LOGS  (server)
--  Audit complet in `faction_logs`. Fiecare mutatie importanta scrie un rand.
--  Tentativele de exploit se logheaza cu action = INVALID_*.
-- ===========================================================================

Logs = {}

-- opts = { faction, actor, target, action, reason, old, new }
--  actor/target = users.id (0 daca lipsesc). old/new = table (JSON) sau nil.
function Logs.write(opts)
    opts = opts or {}
    local fid = tonumber(opts.faction) or 0
    if fid == 0 and not tostring(opts.action or ''):find('^INVALID') then
        -- log fara facțiune valabil doar pt. tentative de exploit
        fid = 0
    end
    MySQL.insert.await([[
        INSERT INTO faction_logs (faction_id, actor_id, target_id, action, reason, old_data, new_data)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        fid,
        tonumber(opts.actor) or 0,
        tonumber(opts.target) or 0,
        tostring(opts.action or 'UNKNOWN'):sub(1, 48),
        tostring(opts.reason or ''):sub(1, 255),
        opts.old ~= nil and DB.encode(opts.old) or nil,
        opts.new ~= nil and DB.encode(opts.new) or nil,
    })
    if Config.Debug then
        print(('[rpg-factions][log] f=%d actor=%s target=%s %s %s')
            :format(fid, tostring(opts.actor or 0), tostring(opts.target or 0),
                    tostring(opts.action), tostring(opts.reason or '')))
    end
end

-- tentativa suspecta / respinsa. `code` ∈ INVALID_PERMISSION / INVALID_FACTION /
-- INVALID_TARGET / INVALID_RANK / INVALID_WARNING / INVALID_REQUEST
function Logs.suspect(src, code, detail, faction, target)
    local uid = Framework.GetUserId(src) or 0
    print(('[rpg-factions][SUSPECT] src=%s uid=%s code=%s detail=%s')
        :format(tostring(src), tostring(uid), tostring(code), tostring(detail or '')))
    if Config.Security.logSuspicious then
        MySQL.insert.await([[
            INSERT INTO faction_logs (faction_id, actor_id, target_id, action, reason)
            VALUES (?, ?, ?, ?, ?)
        ]], { tonumber(faction) or 0, uid, tonumber(target) or 0, tostring(code):sub(1, 48), tostring(detail or ''):sub(1, 255) })
    end
end

-- ---- pagination (LIMIT/OFFSET) ----------------------------------
function Logs.page(fid, page, perPage)
    perPage = math.min(tonumber(perPage) or Config.Security.maxLogsPerPage, Config.Security.maxLogsPerPage)
    page = math.max(1, tonumber(page) or 1)
    local offset = (page - 1) * perPage

    local total = tonumber(MySQL.scalar.await(
        'SELECT COUNT(*) FROM faction_logs WHERE faction_id = ?', { fid })) or 0

    local rows = MySQL.query.await([[
        SELECT id, actor_id, target_id, action, reason, old_data, new_data, created_at
        FROM faction_logs WHERE faction_id = ?
        ORDER BY id DESC LIMIT ? OFFSET ?
    ]], { fid, perPage, offset }) or {}

    local out = {}
    for _, r in ipairs(rows) do
        out[#out + 1] = {
            id       = tonumber(r.id),
            actor    = r.actor_id ~= 0 and { id = tonumber(r.actor_id), name = Framework.GetNameByUserId(r.actor_id) } or nil,
            target   = r.target_id ~= 0 and { id = tonumber(r.target_id), name = Framework.GetNameByUserId(r.target_id) } or nil,
            action   = r.action,
            reason   = r.reason,
            old      = r.old_data and DB.decode(r.old_data) or nil,
            new      = r.new_data and DB.decode(r.new_data) or nil,
            date     = tostring(r.created_at),
        }
    end
    return { rows = out, page = page, perPage = perPage, total = total, pages = math.ceil(total / perPage) }
end
