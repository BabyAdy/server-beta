-- ===========================================================================
--  rpg-jobs — JOB LOGIC  (server)
--  Get Job / Quit Job, calcul skill & plata, date pentru meniu.
--  NIMIC framework-dependent aici (foloseste Framework.* si Config).
-- ===========================================================================

Jobs = {}

function Jobs.def(jobId)
    return Config.Jobs[tonumber(jobId or 0)]
end

-- ---- SKILL --------------------------------------------------------------
-- pragul (ture cumulate) pentru skill-ul urmator, sau nil daca e la max
function Jobs.nextSkillThreshold(job, skill)
    local nxt = Config.Skills[skill + 1]
    if not nxt or skill >= job.maxSkill then return nil end
    return nxt.requiredShifts
end

-- recalculeaza skill-ul din completed_shifts (poate sari mai multe niveluri)
function Jobs.recomputeSkill(job, completedShifts)
    local skill = 1
    for s = 2, job.maxSkill do
        local sc = Config.Skills[s]
        if sc and completedShifts >= sc.requiredShifts then skill = s else break end
    end
    return skill
end

function Jobs.multiplier(skill)
    return Config.SkillMultiplier(skill)
end

-- ---- PLATA (server-side, singura sursa) -------------------------------
-- reward = random(pay.min, pay.max) * multiplier(skill), rotunjit
function Jobs.calcReward(job, skill)
    local base = math.random(job.pay.min, job.pay.max)
    return math.floor(base * Jobs.multiplier(skill) + 0.5), base
end

-- ---- GET JOB ---------------------------------------------------------
-- returneaza (ok, msgKey)  msgKey: 'ok' | 'has_job' | 'other_job' | 'low_level' | 'no_job_def'
function Jobs.getJob(src, jobId)
    local job = Jobs.def(jobId)
    if not job then return false, 'no_job_def' end

    local cur = Framework.GetJob(src)
    if cur == job.id then return false, 'has_job' end

    if Framework.GetLevel(src) < (job.minLevel or 1) then
        return false, 'low_level'
    end

    if not Framework.SetJob(src, job.id) then return false, 'db_error' end

    -- asigura randul de progres (persistent). NU reseteaza progresul existent.
    DB.getOrCreate(src, job.id)
    return true, 'ok'
end

-- ---- QUIT JOB ------------------------------------------------------
function Jobs.quitJob(src, jobId)
    local job = Jobs.def(jobId)
    if not job then return false, 'no_job_def' end
    if Framework.GetJob(src) ~= job.id then return false, 'not_this_job' end

    -- opreste orice tura activa a acestui job (Security defineste functia)
    if Security and Security.abortShift then
        Security.abortShift(src, 'quit')
    end

    if not Framework.SetJob(src, 0) then return false, 'db_error' end
    return true, 'ok'
end

-- ---- MENU DATA (pt. NUI) ------------------------------------------
function Jobs.menuData(src, jobId)
    local job = Jobs.def(jobId)
    if not job then return nil end

    local curId  = Framework.GetJob(src)
    local hasJob = (curId == job.id)
    local level  = Framework.GetLevel(src)

    -- progres (doar citit; se creeaza abia la Get Job)
    local d = DB.peek(src, job.id)
    local skill = d and d.skill or 1
    local completed = d and d.completed_shifts or 0
    local mult  = Jobs.multiplier(skill)
    local nextT = Jobs.nextSkillThreshold(job, skill)

    local curLabel = 'Unemployed'
    if curId ~= 0 then
        local cj = Jobs.def(curId)
        curLabel = cj and cj.label or ('Job #' .. curId)
    end

    return {
        jobId          = job.id,
        jobLabel       = job.label,
        jobName        = job.name,
        minLevel       = job.minLevel or 1,
        playerLevel    = level,
        hasJob         = hasJob,
        currentJobLabel = curLabel,

        skill          = skill,
        maxSkill       = job.maxSkill,
        completedShifts = completed,
        totalShifts    = d and d.total_shifts or 0,
        totalEarnings  = d and d.total_earnings or 0,
        nextSkill      = (nextT and (skill + 1)) or nil,
        nextSkillShifts = nextT,               -- prag cumulat pt. skill-ul urmator
        multiplier     = mult,
        multiplierPct  = math.floor((mult - 1) * 100 + 0.5),

        payMin         = job.pay.min,
        payMax         = job.pay.max,
        estMin         = math.floor(job.pay.min * mult + 0.5),
        estMax         = math.floor(job.pay.max * mult + 0.5),

        requiredTasks  = job.shift.requiredTasks,
        isWorking      = (Security and Security.isWorking and Security.isWorking(src)) or false,
    }
end
