-- ===========================================================================
--  rpg-jobs — DATABASE  (server)
--  Schema install/migratie, seed `jobs` din Config, load/save `player_job_data`.
--  Cache in memorie: PJD[src][jobId] = { skill, completed_shifts, total_shifts,
--  total_earnings } — sursa de adevar ramane DB, cache-ul se salveaza la ture /
--  la deconectare.
-- ===========================================================================

DB = {}
PJD = {}   -- [src] = { [jobId] = row }

local DBG = Config.Debug

-- ---- schema ------------------------------------------------------------
function DB.ensureSchema()
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/electrician_job.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end

    -- users.job — adaugat conditionat (DB existent)
    local has = MySQL.scalar.await([[
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'users' AND COLUMN_NAME = 'job'
    ]])
    if (tonumber(has) or 0) == 0 then
        MySQL.query.await("ALTER TABLE `users` ADD COLUMN `job` INT UNSIGNED NOT NULL DEFAULT 0")
        print('[rpg-jobs] Coloana users.job adaugata.')
    end

    if DBG then print('[rpg-jobs] schema OK') end
end

-- ---- seed `jobs` din Config (upsert) --------------------------------
function DB.seedJobs()
    for _, job in pairs(Config.Jobs) do
        local shiftsCsv = {}
        for s = 1, job.maxSkill do
            local sc = Config.Skills[s]
            shiftsCsv[#shiftsCsv + 1] = tostring(sc and sc.requiredShifts or 0)
        end
        -- informativ in tabelul `jobs`: intervalul de plata / checkpoint la Skill 1
        local p1 = Config.SkillPay(1)
        MySQL.update.await([[
            INSERT INTO jobs (id, name, label, min_level, base_pay_min, base_pay_max,
                              required_tasks, max_skill, skill_shifts)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
                name = VALUES(name), label = VALUES(label), min_level = VALUES(min_level),
                base_pay_min = VALUES(base_pay_min), base_pay_max = VALUES(base_pay_max),
                required_tasks = VALUES(required_tasks), max_skill = VALUES(max_skill),
                skill_shifts = VALUES(skill_shifts)
        ]], {
            job.id, job.name, job.label, job.minLevel,
            p1.base + p1.min, p1.base + p1.max, 0, job.maxSkill,   -- required_tasks: nefolosit (panouri nelimitate)
            table.concat(shiftsCsv, ',')
        })
    end
    if DBG then print(('[rpg-jobs] %d job(uri) seeded in `jobs`.'):format(#Config.Jobs)) end
end

-- ---- player_job_data -------------------------------------------------
local function rowShape(r)
    return {
        id               = tonumber(r.id),
        job_id           = tonumber(r.job_id),
        skill            = math.max(1, tonumber(r.skill) or 1),
        completed_shifts = tonumber(r.completed_shifts) or 0,
        total_shifts     = tonumber(r.total_shifts) or 0,
        total_earnings   = tonumber(r.total_earnings) or 0,
    }
end

-- incarca TOATE randurile de progres ale playerului (poate avea progres pe mai multe joburi)
function DB.loadPlayer(src)
    local uid = Framework.GetUserId(src)
    PJD[src] = {}
    if not uid then return end
    local rows = MySQL.query.await(
        'SELECT * FROM player_job_data WHERE user_id = ?', { uid }) or {}
    for _, r in ipairs(rows) do
        PJD[src][tonumber(r.job_id)] = rowShape(r)
    end
end

-- ia (sau creeaza in DB) randul de progres pt. (player, job)
function DB.getOrCreate(src, jobId)
    jobId = tonumber(jobId)
    PJD[src] = PJD[src] or {}
    if PJD[src][jobId] then return PJD[src][jobId] end

    local uid = Framework.GetUserId(src)
    if not uid then return nil end

    MySQL.update.await([[
        INSERT INTO player_job_data (user_id, job_id, skill, completed_shifts, total_shifts, total_earnings)
        VALUES (?, ?, 1, 0, 0, 0)
        ON DUPLICATE KEY UPDATE user_id = user_id
    ]], { uid, jobId })

    local r = MySQL.single.await(
        'SELECT * FROM player_job_data WHERE user_id = ? AND job_id = ? LIMIT 1', { uid, jobId })
    if not r then return nil end
    PJD[src][jobId] = rowShape(r)
    return PJD[src][jobId]
end

-- doar citeste din cache (nu creeaza)
function DB.peek(src, jobId)
    return PJD[src] and PJD[src][tonumber(jobId)] or nil
end

-- persista un rand de progres
function DB.save(src, jobId)
    local uid = Framework.GetUserId(src)
    local d = DB.peek(src, jobId)
    if not uid or not d then return end
    MySQL.update.await([[
        UPDATE player_job_data
        SET skill = ?, completed_shifts = ?, total_shifts = ?, total_earnings = ?, last_shift_at = NOW()
        WHERE user_id = ? AND job_id = ?
    ]], { d.skill, d.completed_shifts, d.total_shifts, d.total_earnings, uid, jobId })
end

function DB.clear(src)
    PJD[src] = nil
end
