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

-- intervalul de plata / checkpoint pentru un skill: (minTotal, maxTotal, base)
function Jobs.payRange(skill)
    local p = Config.SkillPay(skill)
    return p.base + p.min, p.base + p.max, p.base
end

-- ---- PLATA (server-side, singura sursa) -------------------------------
-- reward / CHECKPOINT = pay.base + random(pay.min, pay.max)   (per skill)
function Jobs.calcReward(_, skill)
    local p = Config.SkillPay(skill)
    local rnd = math.random(p.min, p.max)
    return p.base + rnd, p.base
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

    -- opreste sesiunea de lucru activa (banii per-panou raman incasati)
    if Security and Security.stopShift then
        Security.stopShift(src, 'quit')
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
    local payMin, payMax = Jobs.payRange(skill)
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

        payMin         = payMin,               -- plata minima / checkpoint la skill-ul curent
        payMax         = payMax,               -- plata maxima / checkpoint la skill-ul curent
        estMin         = payMin,
        estMax         = payMax,
        avgPay         = math.floor((payMin + payMax) / 2 + 0.5),

        isWorking      = (Security and Security.isWorking and Security.isWorking(src)) or false,
    }
end
