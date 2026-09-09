-- ===========================================================================
--  rpg-jobs — SECURITY / WORK SESSION STATE MACHINE  (server)
--
--  TOATA logica de lucru + minigame + reward traieste AICI, server-side.
--  Clientul trimite DOAR intentie: "am ajuns la panoul N (apas E)", "am terminat
--  minigame-ul cu token T si rezultatul R", "incerc codul G". Serverul detine:
--    - checkpoint-ul curent (ales din Config, NU de client), fara repetare imediata
--    - faza (travel / minigame)
--    - solutia minigame-ului (client-ul NU o primeste)
--    - token-uri single-use pentru fiecare minigame
--    - toate cooldown-urile si CLOCK-ul de timing
--  si CREDITEAZA reward-ul dupa FIECARE panou (nu exista limita de panouri).
--
--  Sesiunea de lucru se termina cand playerul: /stopwork, Quit Job din meniu,
--  moare, sau se deconecteaza. La /stopwork / Quit Job / moarte banii deja
--  incasati raman (per-panou); la deconectare doar se curata starea.
-- ===========================================================================

Security = {}

local Shift   = {}   -- [src] = sesiune activa (vezi startShift)
local EndedAt = {}   -- [src] = GetGameTimer() cand s-a oprit ultima sesiune (cooldown)

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

local function inVehicle(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return GetVehiclePedIsIn(ped, false) ~= 0
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

local function shuffledCopy(t)
    local a = {}
    for i = 1, #t do a[i] = t[i] end
    for i = #a, 2, -1 do
        local j = math.random(i)
        a[i], a[j] = a[j], a[i]
    end
    return a
end

-- ---- alege si genereaza un minigame server-side ---------------------
--  Toate cele 3 sunt server-authoritative: serverul detine solutia, un token
--  single-use si masoara timpul cu clock-ul PROPRIU (mg.issuedAt).
local WIRE_COLORS = { 'RED', 'YELLOW', 'BLUE', 'PURPLE', 'GREEN' }

local function issueMinigame(src)
    local s = Shift[src]
    local job = Config.Jobs[s.jobId]
    local skillCfg = Config.SkillCfg(job, s.skill)

    -- alterneaza minigame-urile jobului (ciclic), cu offset random pe sesiune
    local names = job.minigames
    local pick = names[((s.index - 1 + (s.mgOffset or 0)) % #names) + 1]

    local token = newToken()
    local base = { id = pick, token = token, issuedAt = now() }

    if pick == 'wires' then
        -- 5 fire colorate. Coloana STANGA si coloana DREAPTA au fiecare culorile
        -- intr-o ordine random. Playerul leaga fiecare terminal stang de terminalul
        -- de ACEEASI culoare din dreapta.
        local left  = shuffledCopy(WIRE_COLORS)
        local right = shuffledCopy(WIRE_COLORS)
        -- garanteaza ca nu e "totul pe orizontala" (macar 3 pozitii diferite)
        local sameCnt = 0
        for i = 1, #left do if left[i] == right[i] then sameCnt = sameCnt + 1 end end
        if sameCnt >= #left - 1 then right[1], right[2] = right[2], right[1] end

        base.left, base.right = left, right
        base.timeMs = (skillCfg.wires and skillCfg.wires.timeMs) or 22000
        s.mg = base
        TriggerClientEvent('rpg-jobs:minigame', src, {
            game = 'wires', token = token,
            params = { left = left, right = right, timeMs = base.timeMs },
        })

    elseif pick == 'flow' then
        -- lant de N tuburi intre tubul START (fix) si tubul END (fix). Fiecare tub
        -- porneste rotit random; conduce doar pe orizontala (rotatie para). Cand
        -- toate conduc, fluxul merge START -> END si minigame-ul se incheie.
        local n = (skillCfg.flow and skillCfg.flow.n) or 5
        local start = {}
        local anyBroken = false
        for i = 1, n do
            start[i] = math.random(0, 3)
            if start[i] % 2 ~= 0 then anyBroken = true end
        end
        if not anyBroken then start[1] = 1 end   -- forteaza macar o actiune

        base.n = n
        base.timeMs = (skillCfg.flow and skillCfg.flow.timeMs) or 18000
        s.mg = base
        TriggerClientEvent('rpg-jobs:minigame', src, {
            game = 'flow', token = token,
            params = { n = n, start = start, timeMs = base.timeMs },
        })

    else -- 'code' — Search the code
        -- cod random din 3 cifre. Playerul incearca combinatii (ENTER). Cifra aflata
        -- in pozitia corecta se BLOCHEAZA (verde). Serverul tine `locked` si cifrele;
        -- clientul primeste doar ce pozitii s-au blocat.
        local code = { math.random(0, 9), math.random(0, 9), math.random(0, 9) }
        base.code     = code
        base.locked   = { false, false, false }
        base.attempts = 0
        base.timeMs   = (skillCfg.code and skillCfg.code.timeMs) or 28000
        s.mg = base
        TriggerClientEvent('rpg-jobs:minigame', src, {
            game = 'code', token = token,
            params = { digits = 3, timeMs = base.timeMs },
        })
    end
end

-- ---- trimite urmatorul checkpoint catre client ------------------
local function pushTask(src)
    local s = Shift[src]
    local job = Config.Jobs[s.jobId]
    local n = #job.workLocations

    local idx = math.random(n)
    if n > 1 then
        local guard = 0
        while idx == (s.lastLoc or 0) and guard < 20 do idx = math.random(n); guard = guard + 1 end
    end
    s.lastLoc    = idx
    s.taskCoords = job.workLocations[idx]
    s.phase      = 'travel'
    s.mg         = nil

    TriggerClientEvent('rpg-jobs:task', src, {
        index = s.index,
        x = s.taskCoords.x, y = s.taskCoords.y, z = s.taskCoords.z,
    })
end

-- ---- un panou reparat: bani IMEDIAT + progres + urmatorul checkpoint --
local function completeTask(src, mgId)
    local s = Shift[src]
    if not s then return end
    local job = Config.Jobs[s.jobId]

    local reward = Jobs.calcReward(job, s.skill)
    s.done   = (s.done or 0) + 1
    s.earned = (s.earned or 0) + reward
    Framework.AddMoney(src, reward)

    -- progres persistent per PANOU (dryver-ul de skill)
    local d = DB.getOrCreate(src, s.jobId)
    if d then
        d.completed_shifts = d.completed_shifts + 1
        d.total_earnings   = d.total_earnings + reward
        local before = d.skill
        d.skill = Jobs.recomputeSkill(job, d.completed_shifts)
        s.skill = d.skill
        DB.save(src, s.jobId)
        if d.skill > before then
            local lo, hi = Jobs.payRange(d.skill)
            log(('Player uid %s leveled up: Skill %d -> %d'):format(tostring(Framework.GetUserId(src)), before, d.skill))
            Framework.Notify(src, ('Skill up! %s Skill %d — pay per checkpoint $%d–$%d.')
                :format(job.label, d.skill, lo, hi), 'success')
        end
    end

    log(('Player uid %s repaired panel #%d (%s) — +$%d (session $%d)')
        :format(tostring(Framework.GetUserId(src)), s.done, tostring(mgId or '?'), reward, s.earned))

    TriggerClientEvent('rpg-jobs:taskDone', src, { done = s.done, earned = s.earned, reward = reward })

    s.index = s.index + 1
    pushTask(src)
end

-- ===========================================================================
--  START WORK SESSION
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
        Framework.Notify(src, 'Wait a moment before starting work again.', 'error'); return
    end
    if not nearNpc(src, job) then
        Framework.Notify(src, 'You must be at the job site.', 'error')
        suspect(src, 'startShift', 'far_from_npc')
        return
    end
    if inVehicle(src) then
        Framework.Notify(src, 'Get out of the vehicle first.', 'error'); return
    end

    local d = DB.getOrCreate(src, jobId)
    if not d then Framework.Notify(src, 'Job data error.', 'error'); return end

    Shift[src] = {
        jobId = jobId, skill = d.skill,
        index = 1,                 -- numarul panoului curent (NELIMITAT)
        done = 0, earned = 0,      -- statistici sesiune (afisaj / ecran final)
        lastLoc = 0,               -- ultimul checkpoint (anti-repetare imediata)
        phase = 'travel',
        startedAt = now(), lastActionAt = 0, retryAt = 0, lastGuessAt = 0,
        mgOffset = math.random(0, #job.minigames - 1),
    }

    d.total_shifts = d.total_shifts + 1   -- audit: cate sesiuni a inceput
    DB.save(src, jobId)

    log(('Player %s (uid %s) started working — skill %d')
        :format(Framework.GetName(src), tostring(Framework.GetUserId(src)), d.skill))
    TriggerClientEvent('rpg-jobs:shiftStarted', src, { jobId = jobId })
    pushTask(src)
end

-- ===========================================================================
--  REACHED TASK  (client: "am ajuns la checkpoint si am apasat E, pe jos")
-- ===========================================================================
function Security.reachedTask(src, index)
    local s = Shift[src]
    if not s then suspect(src, 'reachedTask', 'no_shift'); return end
    if s.phase ~= 'travel' then suspect(src, 'reachedTask', 'wrong_phase:' .. tostring(s.phase)); return end
    if tonumber(index) ~= s.index then
        suspect(src, 'reachedTask', ('bad_index c=%s s=%s'):format(tostring(index), s.index)); return
    end
    if now() < (s.retryAt or 0) then
        Framework.Notify(src, 'Recalibrating… try again in a moment.', 'info'); return
    end
    if not actionAllowed(src) then return end

    if inVehicle(src) then
        suspect(src, 'reachedTask', 'in_vehicle')
        Framework.Notify(src, 'You must be on foot to work on the panel.', 'error')
        return
    end

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
--  VALIDATORI MINIGAME
-- ===========================================================================
-- Wires: `links[i]` = randul din dreapta (1..n) legat de terminalul stang i.
-- Corect = fiecare terminal legat de un rand din dreapta de ACEEASI culoare,
-- fiecare rand din dreapta folosit o singura data.
local function validateWires(mg, result)
    if type(result) ~= 'table' or type(result.links) ~= 'table' then return false end
    local n = #mg.left
    if #result.links ~= n then return false end
    local usedRight = {}
    for i = 1, n do
        local r = tonumber(result.links[i])
        if r == nil or r < 1 or r > n or (r % 1) ~= 0 then return false end
        if usedRight[r] then return false end
        usedRight[r] = true
        if mg.right[r] ~= mg.left[i] then return false end
    end
    return true
end

-- Flow: `rot[i]` = rotatia finala a tubului i (0..3). Conduce doar pe orizontala
-- (rotatie para). Corect = toate tuburile conduc.
local function validateFlow(mg, result)
    if type(result) ~= 'table' or type(result.rot) ~= 'table' then return false end
    if #result.rot ~= mg.n then return false end
    for i = 1, mg.n do
        local r = tonumber(result.rot[i])
        if r == nil or r < 0 or r > 3 or (r % 1) ~= 0 then return false end
        if (r % 2) ~= 0 then return false end
    end
    return true
end

-- ===========================================================================
--  SUBMIT MINIGAME  (wires / flow — un singur submit; code merge pe codeGuess)
-- ===========================================================================
function Security.submitMinigame(src, token, result)
    local s = Shift[src]
    if not s then suspect(src, 'submitMinigame', 'no_shift'); return end
    if s.phase ~= 'minigame' or not s.mg then suspect(src, 'submitMinigame', 'no_minigame'); return end
    if tostring(token) ~= s.mg.token then suspect(src, 'submitMinigame', 'bad_token'); return end
    if not actionAllowed(src) then return end

    local mg = s.mg
    s.mg = nil   -- token consumat IMEDIAT (single-use)

    local serverElapsed = now() - mg.issuedAt   -- CLOCK-UL SERVERULUI (nefalsificabil)
    local ok = false

    if serverElapsed < Config.Security.minigameMinMs then
        suspect(src, 'submitMinigame', 'too_fast ' .. serverElapsed .. 'ms')
    elseif serverElapsed > (mg.timeMs + Config.Security.minigameGraceMs) then
        suspect(src, 'submitMinigame', 'timeout ' .. serverElapsed .. 'ms')
    elseif result and result.aborted then
        -- NUI a inchis minigame-ul fara rezultat -> fail curat
    else
        if mg.id == 'wires' then ok = validateWires(mg, result)
        elseif mg.id == 'flow' then ok = validateFlow(mg, result) end
    end

    if ok then
        completeTask(src, mg.id)
    else
        s.phase = 'travel'
        s.retryAt = now() + Config.Security.retryCooldownMs
        TriggerClientEvent('rpg-jobs:minigameFailed', src, { retryMs = Config.Security.retryCooldownMs })
        log(('Player uid %s FAILED panel (%s)'):format(tostring(Framework.GetUserId(src)), mg.id))
    end
end

-- ===========================================================================
--  CODE GUESS  (Search the code — cate o incercare pe rand)
-- ===========================================================================
function Security.codeGuess(src, token, guess)
    local s = Shift[src]
    if not s then suspect(src, 'codeGuess', 'no_shift'); return end
    if s.phase ~= 'minigame' or not s.mg or s.mg.id ~= 'code' then
        suspect(src, 'codeGuess', 'no_minigame'); return
    end
    if tostring(token) ~= s.mg.token then suspect(src, 'codeGuess', 'bad_token'); return end
    if now() - (s.lastGuessAt or 0) < Config.Security.codeGuessCooldownMs then return end
    s.lastGuessAt = now()

    local mg = s.mg
    local function failOut(reason)
        s.mg = nil
        s.phase = 'travel'
        s.retryAt = now() + Config.Security.retryCooldownMs
        TriggerClientEvent('rpg-jobs:minigameFailed', src, { retryMs = Config.Security.retryCooldownMs })
        log(('Player uid %s FAILED panel (code:%s)'):format(tostring(Framework.GetUserId(src)), tostring(reason)))
    end

    if now() - mg.issuedAt > (mg.timeMs + Config.Security.minigameGraceMs) then
        return failOut('timeout')
    end
    if type(guess) ~= 'table' then return end

    mg.attempts = (mg.attempts or 0) + 1
    for i = 1, 3 do
        if not mg.locked[i] then
            local g = tonumber(guess[i])
            if g ~= nil and (g % 1) == 0 and g == mg.code[i] then
                mg.locked[i] = true
            end
        end
    end

    local solved = mg.locked[1] and mg.locked[2] and mg.locked[3]
    if solved then
        local tok = mg.token
        s.mg = nil   -- consumat; ramanem pe faza 'minigame' pana ruleaza completeTask
        TriggerClientEvent('rpg-jobs:codeResult', src, { token = tok, locked = { true, true, true }, solved = true })
        -- mica pauza ca sa se vada animatia de lacat care se deschide
        SetTimeout(950, function()
            if Shift[src] == s and s.phase == 'minigame' then completeTask(src, 'code') end
        end)
        return
    end

    if mg.attempts >= Config.Security.codeMaxAttempts then
        return failOut('max_attempts')
    end

    TriggerClientEvent('rpg-jobs:codeResult', src, {
        token = mg.token, locked = mg.locked, solved = false, attempts = mg.attempts,
    })
end

-- ===========================================================================
--  STOP WORK  (/stopwork, Quit Job, moarte) — banii per-panou raman incasati
-- ===========================================================================
function Security.stopShift(src, reason)
    local s = Shift[src]
    if not s then return end
    local job = Config.Jobs[s.jobId]
    local done, earned = s.done or 0, s.earned or 0

    EndedAt[src] = now()
    Shift[src] = nil

    log(('Player uid %s stopped working (%s) — %d panels, $%d this session')
        :format(tostring(Framework.GetUserId(src)), tostring(reason), done, earned))

    TriggerClientEvent('rpg-jobs:shiftComplete', src, {
        panels   = done,
        earned   = earned,
        reason   = reason or 'stop',
        jobLabel = job and job.label or 'Electrician',
    })
end

-- ===========================================================================
--  ABORT  (doar deconectare) — nimic de platit, doar curatare
-- ===========================================================================
function Security.abortShift(src, reason)
    if not Shift[src] then return end
    Shift[src] = nil
    EndedAt[src] = now()
    log(('Shift aborted for uid %s (%s)'):format(tostring(Framework.GetUserId(src)), tostring(reason)))
    TriggerClientEvent('rpg-jobs:shiftAborted', src, { reason = reason or 'aborted' })
end

function Security.cleanup(src)
    Shift[src] = nil
    EndedAt[src] = nil
end
