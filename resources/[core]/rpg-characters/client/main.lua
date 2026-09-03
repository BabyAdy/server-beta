-- ===========================================================================
--  rpg-characters — client
--  Preview live pe propriul ped, camera scriptata, NUI in dreapta.
-- ===========================================================================

local appearance    = Appearance.default('male')
local creatorUser   = 'personaj'
local inCreator     = false
local cam           = nil
local camMode       = 'body'

-- ----- utilitare ped -----------------------------------------------------
local function loadModel(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 10000 do Wait(10) end
    return hash
end

local function switchModel(model, cb)
    local hash = loadModel(model)
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    Wait(50)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    ClearPedDecorations(ped)
    if cb then cb(ped) end
end

local function applyNude(ped)
    local set = Config.NudeComponents[appearance.model]
    if not set then return end
    for comp, v in pairs(set) do
        SetPedComponentVariation(ped, comp, v[1], v[2], 0)
    end
    ClearAllPedProps(ped)
end

local function applyHeritage(ped)
    local hb = appearance.headBlend
    SetPedHeadBlendData(ped,
        math.floor(hb.mother), math.floor(hb.father), 0,
        math.floor(hb.mother), math.floor(hb.father), 0,
        hb.shapeMix + 0.0, hb.skinMix + 0.0, 0.0, false)
    Wait(0)
    FinalizeHeadBlend(ped)
end

local function applyFace(ped)
    for i = 0, 19 do
        SetPedFaceFeature(ped, i, (appearance.faceFeatures[i + 1] or 0.0) + 0.0)
    end
end

local function applyOverlay(ped, oid)
    local o = appearance.headOverlays[oid + 1] or {}
    local style = o.style or 0
    if style < 0 then style = 0 end
    SetPedHeadOverlay(ped, oid, style, (o.opacity or 0.0) + 0.0)
    local def = Appearance.OVERLAYS[oid]
    if def and def.color then
        SetPedHeadOverlayColor(ped, oid, def.colorType, o.color or 0, o.secondColor or o.color or 0)
    end
end

local function applyHair(ped)
    SetPedComponentVariation(ped, 2, math.floor(appearance.hair.style or 0), 0, 0)
    SetPedHairColor(ped, math.floor(appearance.hair.color or 0), math.floor(appearance.hair.highlight or 0))
end

local function applyAll(ped)
    ped = ped or PlayerPedId()
    applyHeritage(ped)
    applyFace(ped)
    for oid = 0, 11 do applyOverlay(ped, oid) end
    applyHair(ped)
    SetPedEyeColor(ped, math.floor(appearance.eyeColor or 0))
    applyNude(ped)
end

-- ----- camera ----------------------------------------------------------
local function setupCam(mode)
    camMode = mode or camMode
    local m = Config.Cameras[camMode]
    local c = Config.Creator.coords
    local h = math.rad(c.w)
    local fx, fy = -math.sin(h), math.cos(h)
    local px, py, pz = c.x + fx * m.dist, c.y + fy * m.dist, c.z + m.z

    if not cam then
        cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', px, py, pz, 0.0, 0.0, 0.0, m.fov, false, 0)
        SetCamActive(cam, true)
        RenderScriptCams(true, true, 400, true, false)
    else
        SetCamCoord(cam, px, py, pz)
        SetCamFov(cam, m.fov)
    end
    PointCamAtCoord(cam, c.x, c.y, c.z + m.aimZ)
end

local function destroyCam()
    if cam then
        RenderScriptCams(false, true, 400, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
end

local function rotatePed(dir)
    local ped = PlayerPedId()
    SetEntityHeading(ped, (GetEntityHeading(ped) + dir * Config.RotateStep) % 360.0)
end

-- ----- intrare in creator --------------------------------------------
RegisterNetEvent('rpg-characters:openCreator', function(username)
    creatorUser = username or 'personaj'
    inCreator = true
    appearance = Appearance.default('male')

    DoScreenFadeOut(300)
    Wait(400)

    local c = Config.Creator.coords
    switchModel(appearance.model, function()
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
        SetEntityHeading(ped, (c.w + 180.0) % 360.0)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        applyAll(ped)
        setupCam('body')

        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', appearance = appearance, username = creatorUser })

        Wait(300)
        DoScreenFadeIn(500)
    end)
end)

-- ----- spawn final (dupa creare sau la revenire in server) ------------
RegisterNetEvent('rpg-characters:spawn', function(data, pos)
    inCreator = false
    appearance = data

    ShutdownLoadingScreenNui()   -- daca mai e activ ecranul de incarcare

    DoScreenFadeOut(400)
    Wait(450)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    destroyCam()

    switchModel(appearance.model, function()
        local ped = PlayerPedId()
        applyAll(ped)
        SetEntityCoordsNoOffset(ped, pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, false, false, false)
        SetEntityHeading(ped, (pos.h or 0.0) + 0.0)
        NetworkResurrectLocalPlayer(pos.x + 0.0, pos.y + 0.0, pos.z + 0.0, (pos.h or 0.0) + 0.0, true, false)
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        SetPlayerControl(PlayerId(), true, 0)

        Wait(200)
        DoScreenFadeIn(600)
        TriggerServerEvent('rpg-characters:spawned')
        TriggerEvent('core:characterSpawned', appearance)
    end)
end)

-- ----- NUI callbacks ------------------------------------------------
RegisterNUICallback('apply', function(data, cb)
    if data and data.appearance then
        appearance = data.appearance
        applyAll(PlayerPedId())
    end
    cb('ok')
end)

RegisterNUICallback('heritage', function(data, cb)
    appearance.headBlend = {
        mother   = data.mother or 0,
        father   = data.father or 0,
        shapeMix = data.shapeMix or 0.5,
        skinMix  = data.skinMix or 0.5,
    }
    applyHeritage(PlayerPedId())
    cb('ok')
end)

RegisterNUICallback('face', function(data, cb)
    local idx = tonumber(data.index) or 0
    appearance.faceFeatures[idx + 1] = data.value + 0.0
    SetPedFaceFeature(PlayerPedId(), idx, data.value + 0.0)
    cb('ok')
end)

RegisterNUICallback('overlay', function(data, cb)
    local oid = tonumber(data.id) or 0
    appearance.headOverlays[oid + 1] = {
        style       = data.style or 0,
        opacity     = data.opacity or 0.0,
        color       = data.color or 0,
        secondColor = data.secondColor or 0,
    }
    applyOverlay(PlayerPedId(), oid)
    cb('ok')
end)

RegisterNUICallback('hair', function(data, cb)
    appearance.hair = {
        style     = data.style or 0,
        color     = data.color or 0,
        highlight = data.highlight or 0,
    }
    applyHair(PlayerPedId())
    cb('ok')
end)

RegisterNUICallback('eyes', function(data, cb)
    appearance.eyeColor = tonumber(data.value) or 0
    SetPedEyeColor(PlayerPedId(), appearance.eyeColor)
    cb('ok')
end)

RegisterNUICallback('model', function(data, cb)
    local sex = (data.sex == 'female') and 'female' or 'male'
    appearance.sex = sex
    appearance.model = Appearance.MODELS[sex]
    local c = Config.Creator.coords
    switchModel(appearance.model, function()
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, c.x, c.y, c.z, false, false, false)
        SetEntityHeading(ped, (c.w + 180.0) % 360.0)
        FreezeEntityPosition(ped, true)
        applyAll(ped)
        setupCam(camMode)
        cb({ ok = true })
    end)
end)

RegisterNUICallback('camera', function(data, cb)
    if data.rotate then
        rotatePed(tonumber(data.rotate) or 1)
    elseif data.mode then
        setupCam(data.mode)
    end
    cb('ok')
end)

RegisterNUICallback('confirm', function(_, cb)
    cb('ok')
    TriggerServerEvent('rpg-characters:create', appearance)
end)

RegisterNetEvent('rpg-characters:createResult', function(ok, msg)
    if ok then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
    else
        SendNUIMessage({ action = 'toast', message = msg or 'Eroare.', kind = 'error' })
    end
end)

-- ----- blocare control cat timp e in creator -------------------------
CreateThread(function()
    while true do
        if inCreator then
            HideHudAndRadarThisFrame()
            DisableAllControlActions(0)
            ThefeedHideThisFrame()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ----- opreste spawn-ul automat -------------------------------------
CreateThread(function()
    Wait(500)
    pcall(function() exports.spawnmanager:setAutoSpawn(false) end)
end)
