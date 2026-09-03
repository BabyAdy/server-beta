-- ===========================================================================
--  rpg-auth — client
--  Deschide NUI-ul de login la intrarea în server, blochează playerul până
--  la autentificare, apoi predă controlul framework-ului prin evenimente.
-- ===========================================================================

local Auth = {
    open   = false,
    authed = false,
}

-- ----- request/response către server (cu id, ca să putem lega răspunsul) ----
local pending = {}
local reqSeq  = 0

local function serverRequest(name, payload, cb)
    reqSeq = reqSeq + 1
    local id = reqSeq
    pending[id] = cb or function() end
    TriggerServerEvent('rpg-auth:request', name, id, payload)
end

RegisterNetEvent('rpg-auth:response', function(id, ok, message, data)
    local cb = pending[id]
    if not cb then return end
    pending[id] = nil
    cb(ok, message, data)
end)

-- ----- lock / unlock player -------------------------------------------------
local function lockPlayer(state)
    local ped = PlayerPedId()
    SetEntityVisible(ped, not state, false)
    FreezeEntityPosition(ped, state)
    SetEntityInvincible(ped, state)
    SetPlayerControl(PlayerId(), not state, 0)
    if state then
        SetEntityCoordsNoOffset(ped, Config.SpawnCoords.x, Config.SpawnCoords.y, Config.SpawnCoords.z, false, false, false)
        SetEntityHeading(ped, Config.SpawnCoords.w)
    end
end

-- ----- cameră fixă -------------------------------------------------------------
local cam
local function toggleCam(state)
    if not Config.UseCamera then return end
    if state and not cam then
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
            Config.Camera.pos.x, Config.Camera.pos.y, Config.Camera.pos.z,
            0.0, 0.0, 0.0, Config.Camera.fov + 0.0, false, 0)
        PointCamAtCoord(cam, Config.Camera.look.x, Config.Camera.look.y, Config.Camera.look.z)
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false)
    elseif not state and cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
end

-- ----- open / close ------------------------------------------------------------
function OpenAuth(screen)
    if Auth.open or Auth.authed then return end
    Auth.open = true

    DoScreenFadeIn(0)
    lockPlayer(true)
    toggleCam(true)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        screen = screen or 'login',
        config = {
            minUsername = Config.MinUsername,
            maxUsername = Config.MaxUsername,
            minPassword = Config.MinPassword,
            logo        = Config.LogoUrl,
        },
    })
end

function CloseAuth()
    Auth.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    toggleCam(false)
    lockPlayer(false)
end

-- ----- NUI callbacks ---------------------------------------------------------
RegisterNUICallback('ready', function(_, cb)
    cb('ok')
end)

RegisterNUICallback('login', function(data, cb)
    serverRequest('login', data, function(ok, message)
        cb({ ok = ok, message = message })
        if ok then
            Auth.authed = true
            SetTimeout(700, function()
                CloseAuth()
                TriggerServerEvent('rpg-auth:finalize')
                -- Hook pentru framework-ul custom:
                TriggerEvent('core:playerAuthed', message)
            end)
        end
    end)
end)

RegisterNUICallback('register', function(data, cb)
    serverRequest('register', data, function(ok, message)
        cb({ ok = ok, message = message })
    end)
end)

RegisterNUICallback('recover', function(data, cb)
    serverRequest('recover', data, function(ok, message)
        cb({ ok = ok, message = message })
    end)
end)

-- ----- HUD / control blocking cât timp UI-ul e deschis ----------------------
CreateThread(function()
    while true do
        if Auth.open then
            HideHudAndRadarThisFrame()
            DisableAllControlActions(0)
            ThefeedHideThisFrame()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ----- pornire -------------------------------------------------------------
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    if not Auth.authed then OpenAuth('login') end
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    Wait(300)
    if not Auth.authed then OpenAuth('login') end
end)
