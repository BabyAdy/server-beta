-- ===========================================================================
--  rpg-jobs — SERVER BOOTSTRAP + NET EVENT ROUTER
--  Handler-ele sunt SUBTIRI: valideaza minim si deleaga la Jobs / Security.
--  Toata autoritatea e in jobs.lua / security.lua. Nimic framework-dependent aici.
-- ===========================================================================

local DBG = Config.Debug

-- ---- BOOT -----------------------------------------------------------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(500)
    DB.ensureSchema()
    DB.seedJobs()

    -- validare config (previne greseli de setup)
    for _, job in pairs(Config.Jobs) do
        assert(job.id and job.name and job.label, '[rpg-jobs] job invalid in Config.Jobs')
        assert(#job.workLocations >= job.shift.requiredTasks,
            ('[rpg-jobs] job "%s": prea putine workLocations (%d) pentru requiredTasks (%d)')
                :format(job.name, #job.workLocations, job.shift.requiredTasks))
    end

    -- playeri deja conectati (restart de resursa)
    for _, pid in ipairs(GetPlayers()) do
        local src = tonumber(pid)
        Framework.LoadJob(src)
        DB.loadPlayer(src)
        TriggerClientEvent('rpg-jobs:bootstrap', src, { job = Config.Job, hasJob = Framework.GetJob(src) == Config.Job.id })
    end
    if DBG then print('[rpg-jobs] gata.') end
end)

-- ---- CICLU DE VIATA -----------------------------------------------
AddEventHandler('core:characterLoaded', function(src)
    Framework.LoadJob(src)
    DB.loadPlayer(src)
    TriggerClientEvent('rpg-jobs:bootstrap', src, { job = Config.Job, hasJob = Framework.GetJob(src) == Config.Job.id })
end)

AddEventHandler('playerDropped', function()
    local src = source
    -- tura activa la deconectare -> ANULATA, fara reward (spec §21)
    Security.abortShift(src, 'disconnect')
    Security.cleanup(src)
    DB.clear(src)
    Framework.ClearCache(src)
end)

-- ---- ROUTER (client -> server) ----------------------------------
--  Toate re-verifica jobul / tura server-side; clientul e neincrezator.

RegisterNetEvent('rpg-jobs:requestMenu', function()
    local src = source
    local data = Jobs.menuData(src, Config.Job.id)
    if data then TriggerClientEvent('rpg-jobs:menuData', src, data) end
end)

RegisterNetEvent('rpg-jobs:getJob', function()
    local src = source
    local ok, key = Jobs.getJob(src, Config.Job.id)
    local MSG = {
        ok        = { 'You are now an Electrician.', 'success' },
        has_job   = { 'You already have this job.', 'error' },
        low_level = { ('You need level %d for this job.'):format(Config.Job.minLevel or 1), 'error' },
        no_job_def = { 'This job does not exist.', 'error' },
        db_error  = { 'Could not save your job. Try again.', 'error' },
    }
    local m = MSG[key] or MSG.db_error
    Framework.Notify(src, m[1], m[2])
    if ok then
        Security.log(('Player uid %s got job electrician'):format(tostring(Framework.GetUserId(src))))
    end
    local data = Jobs.menuData(src, Config.Job.id)
    if data then TriggerClientEvent('rpg-jobs:menuData', src, data) end
end)

RegisterNetEvent('rpg-jobs:quitJob', function()
    local src = source
    local ok, key = Jobs.quitJob(src, Config.Job.id)
    local MSG = {
        ok           = { 'You quit the Electrician job.', 'info' },
        not_this_job = { "You don't have this job.", 'error' },
        no_job_def   = { 'This job does not exist.', 'error' },
        db_error     = { 'Could not update your job. Try again.', 'error' },
    }
    local m = MSG[key] or MSG.db_error
    Framework.Notify(src, m[1], m[2])
    if ok then
        Security.log(('Player uid %s quit job electrician'):format(tostring(Framework.GetUserId(src))))
    end
    local data = Jobs.menuData(src, Config.Job.id)
    if data then TriggerClientEvent('rpg-jobs:menuData', src, data) end
end)

RegisterNetEvent('rpg-jobs:startWork', function()
    Security.startShift(source)
end)

RegisterNetEvent('rpg-jobs:reachedTask', function(index)
    Security.reachedTask(source, index)
end)

RegisterNetEvent('rpg-jobs:submitMinigame', function(token, result)
    Security.submitMinigame(source, token, result)
end)

RegisterNetEvent('rpg-jobs:cancelWork', function()
    Security.abortShift(source, 'player_cancel')
end)

-- rezerva pentru alte resurse (viitor)
exports('getJob', function(src) return Framework.GetJob(src) end)
exports('isWorking', function(src) return Security.isWorking(src) end)
