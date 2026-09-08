-- ===========================================================================
--  rpg-jobs — SECURITY / SHIFT STATE MACHINE  (server)
--
--  TOATA logica de tura + minigame + reward traieste AICI, server-side.
--  Clientul trimite DOAR intentie: "am ajuns la task N", "am terminat minigame-ul
--  cu token T si rezultatul R". Serverul detine:
--    - lista de task-uri (aleasa din Config, nu de client)
--    - task-ul curent + faza (travel / minigame)
--    - solutia minigame-ului (client-ul NU o primeste)
--    - token-uri single-use pt. fiecare minigame
--    - toate cooldown-urile
--  si CALCULEAZA singur reward-ul la finalul turei.
-- ===========================================================================

Security = {}

local Shift    = {}   -- [src] = tura activa (vezi startShift)
local EndedAt  = {}   -- [src] = GetGameTimer() cand s-a terminat/anulat ultima tura (cooldown)

local function now() return GetGameTimer() end

local function newToken()
    return ('%x%x%x'):format(math.random(0, 0xFFFFFF), math.random(0, 0xFFFFFF), now() % 0xFFFF)
end

-- ---- LOGGING --------------------------------------------------------
local function log(msg) print(('[Electrician] %s'):format(msg)) end
local function suspect(src, event, reason)
    local uid = Framework.GetUserId(src)
    print(('[Electrician][SUSPECT] src=%s uid=%s event=%s reason=%s')
        :format(tostring(src), tostring(uid), tostring(event), tostring(reason)))
end
Security.log = log
Security.suspect = suspect

-- ---- helpers ------------------------------------------------------
function Security.isWorking(src)
    return Shift[src] ~= nil
end

local function pedCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function nearNpc(src, job)
    local c = pedCoords(src); if not c then return false end
    return #(c - vector3(job.npc.coords.x, job.npc.coords.y, job.npc.coords.z)) <= Config.Interaction.radius
end

-- rate-limit generic pe actiunile de tura
local function actionAllowed(src)
    local s = Shift[src]; if not s then return false end
    if now() - (s.lastActionAt or 0) < Config.Security.actionCooldownMs then return false end
    s.lastActionAt = now()
    return true
end

-- ---- triangle wave pt. minigame-ul VOLTAGE (0 -> 1 -> 0, perioada 2) ----
local function tri(x)
    x = x % 2.0
    if x < 0 then x = x + 2.0 end
    return (x < 1.0) and x or (2.0 - x)
end

-- ---- alege si genereaza un minigame server-side ---------------------
local function issueMinigame(src)
    local s = Shift[src]
    local job = Config.Jobs[s.jobId]
    local skillCfg = Config.SkillCfg(job, s.skill)

    -- alterneaza minigame-urile jobului (ciclic), cu offset random pe tura
    local names = job.minigames
    local pick = names[((s.index - 1 + (s.mgOffset or 0)) % #names) + 1]

    local token = newToken()
    local base = { id = pick, token = token, issuedAt = now() }

    if pick == 'circuit' then
        local n = skillCfg.circuit.segments
        local TYPES = { 'straight', 'corner', 'tee' }
        local solution, start, types = {}, {}, {}
        local anyDiff = false
        for i = 1, n do
            solution[i] = math.random(0, 3)
            start[i]    = math.random(0, 3)
            types[i]    = TYPES[math.random(1, #TYPES)]
            if start[i] ~= solution[i] then anyDiff = true end
        end
        if not anyDiff then                      -- garanteaza ca playerul trebuie sa actioneze
            start[1] = (solution[1] + 1) % 4
        end
        base.timeMs   = skillCfg.circuit.timeMs
        base.solution = solution
        s.mg = base
        -- `target` = orientarea-tinta AFISATA jucatorului (nu e un "raspuns ascuns"):
        -- e obiectivul vizibil. Serverul re-valideaza egalitatea + timing-ul (clock propriu).
        TriggerClientEvent('rpg-jobs:minigame', src, {
            game = 'circuit', token = token,
            params = { n = n, types = types, start = start, target = solution, timeMs = base.timeMs },
        })

    else -- voltage
        local zw   = skillCfg.voltage.zone
        local zs   = math.floor(math.random() * (0.90 - zw - 0.10) * 1000) / 1000 + 0.10
        local ph0  = math.floor(math.random() * 2000) / 1000
        base.timeMs   = skillCfg.voltage.timeMs
        base.zoneStart = zs
        base.zoneWidth = zw
        base.speed     = skillCfg.voltage.speed
        base.phase0    = ph0
        s.mg = base
        TriggerClientEvent('rpg-jobs:minigame', src, {
            game = 'voltage', token = token,
            params = { zoneStart = zs, zoneWidth = zw, speed = base.speed, phase0 = ph0, timeMs = base.timeMs },
        })
    end
end

-- ---- trimite task-ul curent catre client -------------------------
local function pushTask(src)
    local s = Shift[src]
    local job = Config.Jobs[s.jobId]
    local locIdx = s.tasks[s.index]
    s.taskCoords = job.workLocations[locIdx]
    s.phase = 'travel'
    s.mg = nil
    TriggerClientEvent('rpg-jobs:task', src, {
        index = s.index, total = #s.tasks,
        x = s.taskCoords.x, y = s.taskCoords.y, z = s.taskCoords.z,
    })
end

-- ===========================================================================
--  START SHIFT
-- ===========================================================================
function Security.startShift(src)
    local jobId = Framework.GetJob(src)
    local job = Config.Jobs[jobId]
    if not job then
        Framework.Notify(src, "You don't have this job.", 'error')
        suspect(src, 'startShift', 'no_job')
        return
    end
    if Shift[src] then
        Framework.Notify(src, 'You are already working.', 'error'); return
    end
    if now() - (EndedAt[src] or 0) < Config.Security.shiftCooldownMs then
        Framework.Notify(src, 'Wait a moment before starting a new shift.', 'error'); return
    end
    if not nearNpc(src, job) then
        Framework.Notify(src, 'You must be at the job site.', 'error')
        suspect(src, 'startShift', 'far_from_npc')
        return
    end

    -- progres persistent
    local d = DB.getOrCreate(src, jobId)
    if not d then Framework.Notify(src, 'Job data error.', 'error'); return end

    -- alege `requiredTasks` locatii distincte, amestecate
    local pool = {}
    for i = 1, #job.workLocations do pool[i] = i end
    for i = #pool, 2, -1 do
        local j = math.random(i); pool[i], pool[j] = pool[j], pool[i]
    end
    local count = math.min(job.shift.requiredTasks, #pool)
    local tasks = {}
    for i = 1, count do tasks[i] = pool[i] end

    Shift[src] = {
        jobId = jobId, skill = d.skill,
        tasks = tasks, index = 1, phase = 'travel',
        startedAt = now(), lastActionAt = 0, retryAt = 0,
        mgOffset = math.random(0, 3),
    }

    -- "tura pornita" — audit persistent (chiar daca playerul pica)
    d.total_shifts = d.total_shifts + 1
    DB.save(src, jobId)

    log(('Player %s (uid %s) started shift — %d tasks, skill %d')
        :format(Framework.GetName(src), tostring(Framework.GetUserId(src)), count, d.skill))
    TriggerClientEvent('rpg-jobs:shiftStarted', src, { jobId = jobId, total = count })
    pushTask(src)
end

-- ===========================================================================
--  REACHED TASK  (client: "am ajuns la panoul N")
-- ===========================================================================
function Security.reachedTask(src, index)
    local s = Shift[src]
    if not s then suspect(src, 'reachedTask', 'no_shift'); return end
    if s.phase ~= 'travel' then suspect(src, 'reachedTask', 'wrong_phase:' .. tostring(s.phase)); return end
    if tonumber(index) ~= s.index then suspect(src, 'reachedTask', ('bad_index c=%s s=%s'):format(tostring(index), s.index)); return end
    if now() < (s.retryAt or 0) then
        Framework.Notify(src, 'Recalibrating… try again in a moment.', 'info'); return
    end
    if not actionAllowed(src) then return end

    local c = pedCoords(src)
    if not c or #(c - s.taskCoords) > Config.Security.taskRadius then
        suspect(src, 'reachedTask', 'distance')
        Framework.Notify(src, 'You are not at the panel.', 'error')
        return
    end

    s.phase = 'minigame'
    issueMinigame(src)
end

-- ===========================================================================
--  SUBMIT MINIGAME
-- ===========================================================================
local function validateCircuit(mg, result)
    if type(result) ~= 'table' or type(result.rot) ~= 'table' then return false end
    if #result.rot ~= #mg.solution then return false end
    local miss = 0
    for i = 1, #mg.solution do
        local r = tonumber(result.rot[i])
        if r == nil or r < 0 or r > 3 or (r % 1) ~= 0 then return false end
        if r ~= mg.solution[i] then miss = miss + 1 end
    end
    return miss <= (Config.Security.circuitGrace or 0)
end

local function validateVoltage(mg, result, serverElapsed)
    if type(result) ~= 'table' then return false end
    local stop = tonumber(result.stop)
    local elapsedMs = tonumber(result.elapsedMs)
    if not stop or not elapsedMs then return false end
    if stop < 0 or stop > 1 then return false end
    if elapsedMs < Config.Security.minigameMinMs then return false end
    if elapsedMs > serverElapsed + 500 then return false end   -- nu poti "consuma" mai mult timp decat a trecut real

    -- pozitia indicatorului e DETERMINISTA din timp -> recalculeaza si compara
    local expected = tri(mg.phase0 + (elapsedMs / 1000.0) * mg.speed)
    if math.abs(expected - stop) > Config.Security.voltageEpsilon then return false end

    -- si sa fie in zona verde
    return stop >= mg.zoneStart and stop <= (mg.zoneStart + mg.zoneWidth)
end

function Security.submitMinigame(src, token, result)
    local s = Shift[src]
    if not s then suspect(src, 'submitMinigame', 'no_shift'); return end
    if s.phase ~= 'minigame' or not s.mg then suspect(src, 'submitMinigame', 'no_minigame'); return end
    if tostring(token) ~= s.mg.token then suspect(src, 'submitMinigame', 'bad_token'); return end
    if not actionAllowed(src) then return end

    local mg = s.mg
    s.mg = nil   -- token consumat IMEDIAT (single-use; un al doilea submit gaseste nil)

    local serverElapsed = now() - mg.issuedAt   -- CLOCK-UL SERVERULUI (nefalsificabil)
    local ok = false

    if serverElapsed < Config.Security.minigameMinMs then
        suspect(src, 'submitMinigame', 'too_fast ' .. serverElapsed .. 'ms')          -- anti "instant complete"
    elseif serverElapsed > (mg.timeMs + Config.Security.minigameGraceMs) then
        suspect(src, 'submitMinigame', 'timeout ' .. serverElapsed .. 'ms')
    elseif result and result.aborted then
        -- NUI a inchis minigame-ul fara rezultat -> fail curat
    else
        if mg.id == 'circuit' then ok = validateCircuit(mg, result)
        elseif mg.id == 'voltage' then ok = validateVoltage(mg, result, serverElapsed) end
    end

    if ok then
        log(('Player uid %s completed task %d/%d (%s)')
            :format(tostring(Framework.GetUserId(src)), s.index, #s.tasks, mg.id))
        TriggerClientEvent('rpg-jobs:taskDone', src, { index = s.index, total = #s.tasks })
        s.index = s.index + 1
        if s.index > #s.tasks then
            Security.completeShift(src)
        else
            pushTask(src)
        end
    else
        s.phase = 'travel'
        s.retryAt = now() + Config.Security.retryCooldownMs
        TriggerClientEvent('rpg-jobs:minigameFailed', src, { index = s.index, retryMs = Config.Security.retryCooldownMs })
        log(('Player uid %s FAILED task %d (%s)')
            :format(tostring(Framework.GetUserId(src)), s.index, mg.id))
    end
end

-- ===========================================================================
--  COMPLETE SHIFT  (singurul loc unde se dau bani)
-- ===========================================================================
function Security.completeShift(src)
    local s = Shift[src]
    if not s then return end
    local jobId = s.jobId
    local job = Config.Jobs[jobId]

    local d = DB.getOrCreate(src, jobId)
    if not d then Shift[src] = nil; return end

    -- skill-ul folosit la plata = cel de la INCEPUTUL turei (server), nu ce zice clientul
    local skill = s.skill
    local reward, base = Jobs.calcReward(job, skill)

    d.completed_shifts = d.completed_shifts + 1
    d.total_earnings   = d.total_earnings + reward

    -- avansare skill (poate sari mai multe niveluri daca pragurile sunt apropiate)
    local before = d.skill
    d.skill = Jobs.recomputeSkill(job, d.completed_shifts)
    local leveledUp = d.skill > before

    DB.save(src, jobId)
    Framework.AddMoney(src, reward)

    EndedAt[src] = now()
    Shift[src] = nil

    local newMult = Jobs.multiplier(d.skill)
    log(('Player uid %s completed SHIFT — reward $%d (base $%d x%.2f, skill %d, total shifts %d)')
        :format(tostring(Framework.GetUserId(src)), reward, base, Jobs.multiplier(skill), skill, d.completed_shifts))

    TriggerClientEvent('rpg-jobs:shiftComplete', src, {
        reward          = reward,
        completedShifts = d.completed_shifts,
        skill           = d.skill,
        leveledUp       = leveledUp,
        newMultiplier   = newMult,
        newPct          = math.floor((newMult - 1) * 100 + 0.5),
        jobLabel        = job.label,
    })

    if leveledUp then
        log(('Player uid %s leveled up: Skill %d -> %d'):format(tostring(Framework.GetUserId(src)), before, d.skill))
        Framework.Notify(src, ('Congratulations! You reached %s Skill %d. Your income multiplier is now +%d%%.')
            :format(job.label, d.skill, math.floor((newMult - 1) * 100 + 0.5)), 'success')
    end
end

-- ===========================================================================
--  ABORT SHIFT  (quit job / disconnect / job change) — FARA reward
-- ===========================================================================
function Security.abortShift(src, reason)
    if not Shift[src] then return end
    Shift[src] = nil
    EndedAt[src] = now()
    log(('Shift aborted for uid %s (%s) — no reward'):format(tostring(Framework.GetUserId(src)), tostring(reason)))
    TriggerClientEvent('rpg-jobs:shiftAborted', src, { reason = reason or 'aborted' })
end

function Security.cleanup(src)
    Shift[src] = nil
    EndedAt[src] = nil
end
