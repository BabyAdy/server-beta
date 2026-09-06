-- ===========================================================================
--  rpg-garages — client / tuning  (VehicleProps)
--  Citeste TOATA configuratia relevanta a unui vehicul si o re-aplica identic.
--  Acopera: culori (primary/secondary/pearl/wheel/dashboard/interior + custom RGB),
--  wheels + wheel type, window tint, neon, xenon, tyre smoke, livery, roof livery,
--  extras, placa + plate index, si TOATE mod-urile (0..48) + toggle mods (17..22).
--  Nicio pierdere de tuning intre spawn si park (spec §6).
-- ===========================================================================

Tuning = Tuning or {}

local function getCustomRGB(getterCustom, isCustom, veh)
    if not isCustom(veh) then return nil end
    local r, g, b = getterCustom(veh)
    return { r = r, g = g, b = b }
end

-- ---------------------------------------------------------------------------
--  GET
-- ---------------------------------------------------------------------------
function Tuning.get(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return {} end
    SetVehicleModKit(veh, 0)

    local p = {}

    p.plate      = GetVehicleNumberPlateText(veh)
    p.plateIndex = GetVehicleNumberPlateTextIndex(veh)

    local prim, sec = GetVehicleColours(veh)
    p.primaryColor, p.secondaryColor = prim, sec
    local pearl, wheelC = GetVehicleExtraColours(veh)
    p.pearlescentColor, p.wheelColor = pearl, wheelC
    p.dashboardColor = GetVehicleDashboardColour(veh)
    p.interiorColor  = GetVehicleInteriorColour(veh)

    p.customPrimary = getCustomRGB(
        function(v) return GetVehicleCustomPrimaryColour(v) end,
        function(v) return GetIsVehiclePrimaryColourCustom(v) end, veh)
    p.customSecondary = getCustomRGB(
        function(v) return GetVehicleCustomSecondaryColour(v) end,
        function(v) return GetIsVehicleSecondaryColourCustom(v) end, veh)

    p.wheelType  = GetVehicleWheelType(veh)
    p.windowTint = GetVehicleWindowTint(veh)

    p.livery     = GetVehicleLivery(veh)
    p.roofLivery = GetVehicleRoofLivery(veh)

    -- neon
    local neon = {}
    for i = 0, 3 do neon[i] = IsVehicleNeonLightEnabled(veh, i) end
    p.neonEnabled = neon
    local nr, ng, nb = GetVehicleNeonLightsColour(veh)
    p.neonColor = { r = nr, g = ng, b = nb }

    -- xenon (toggle = mod 22) + culoare
    p.xenon      = IsToggleModOn(veh, 22)
    p.xenonColor = GetVehicleXenonLightsColor(veh)

    -- tyre smoke
    local tr, tg, tb = GetVehicleTyreSmokeColor(veh)
    p.tyreSmokeColor = { r = tr, g = tg, b = tb }
    p.bulletproofTyres = not GetVehicleTyresCanBurst(veh)
    p.customTyres = GetVehicleModVariation(veh, 23)

    -- extras 0..20
    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(veh, i) then extras[i] = IsVehicleExtraTurnedOn(veh, i) end
    end
    p.extras = extras

    -- mod-uri 0..48 (fara toggle-urile 17..22)
    local mods = {}
    for i = 0, 48 do
        if i < 17 or i > 22 then mods[i] = GetVehicleMod(veh, i) end
    end
    p.mods = mods
    p.wheelMods = { front = GetVehicleMod(veh, 23), rear = GetVehicleMod(veh, 24) }

    -- toggle mods 17..22
    local tg2 = {}
    for i = 17, 22 do tg2[i] = IsToggleModOn(veh, i) end
    p.modToggles = tg2

    return p
end

-- ---------------------------------------------------------------------------
--  APPLY
-- ---------------------------------------------------------------------------
local function num(v, dflt) v = tonumber(v); if v == nil then return dflt end return v end

function Tuning.apply(veh, p)
    if not veh or veh == 0 or not DoesEntityExist(veh) or type(p) ~= 'table' then return end
    SetVehicleModKit(veh, 0)

    if p.plate and p.plate ~= '' then SetVehicleNumberPlateText(veh, p.plate) end
    if p.plateIndex ~= nil then SetVehicleNumberPlateTextIndex(veh, num(p.plateIndex, 0)) end

    SetVehicleColours(veh, num(p.primaryColor, 0), num(p.secondaryColor, 0))
    SetVehicleExtraColours(veh, num(p.pearlescentColor, 0), num(p.wheelColor, 0))
    if p.dashboardColor ~= nil then SetVehicleDashboardColour(veh, num(p.dashboardColor, 0)) end
    if p.interiorColor ~= nil then SetVehicleInteriorColour(veh, num(p.interiorColor, 0)) end

    if type(p.customPrimary) == 'table' then
        SetVehicleCustomPrimaryColour(veh, num(p.customPrimary.r or p.customPrimary[1], 0),
            num(p.customPrimary.g or p.customPrimary[2], 0), num(p.customPrimary.b or p.customPrimary[3], 0))
    end
    if type(p.customSecondary) == 'table' then
        SetVehicleCustomSecondaryColour(veh, num(p.customSecondary.r or p.customSecondary[1], 0),
            num(p.customSecondary.g or p.customSecondary[2], 0), num(p.customSecondary.b or p.customSecondary[3], 0))
    end

    if p.wheelType ~= nil then SetVehicleWheelType(veh, num(p.wheelType, 0)) end
    if p.windowTint ~= nil then SetVehicleWindowTint(veh, num(p.windowTint, 0)) end

    -- extras (SetVehicleExtra: al 2-lea arg true = OPRIT)
    if type(p.extras) == 'table' then
        for k, on in pairs(p.extras) do
            local id = tonumber(k)
            if id and DoesExtraExist(veh, id) then SetVehicleExtra(veh, id, on and 0 or 1) end
        end
    end

    -- mod-uri
    local customTyres = p.customTyres == true
    if type(p.mods) == 'table' then
        for k, v in pairs(p.mods) do
            local mt = tonumber(k)
            if mt and (mt < 17 or mt > 22) then SetVehicleMod(veh, mt, num(v, -1), customTyres) end
        end
    end
    if type(p.wheelMods) == 'table' then
        SetVehicleMod(veh, 23, num(p.wheelMods.front, -1), customTyres)
        SetVehicleMod(veh, 24, num(p.wheelMods.rear, -1), customTyres)
    end
    if type(p.modToggles) == 'table' then
        for k, on in pairs(p.modToggles) do
            local mt = tonumber(k)
            if mt and mt >= 17 and mt <= 22 then ToggleVehicleMod(veh, mt, on == true) end
        end
    end

    -- neon
    if type(p.neonEnabled) == 'table' then
        for i = 0, 3 do
            local v = p.neonEnabled[i] ; if v == nil then v = p.neonEnabled[tostring(i)] end
            SetVehicleNeonLightEnabled(veh, i, v == true)
        end
    end
    if type(p.neonColor) == 'table' then
        SetVehicleNeonLightsColour(veh, num(p.neonColor.r or p.neonColor[1], 255),
            num(p.neonColor.g or p.neonColor[2], 255), num(p.neonColor.b or p.neonColor[3], 255))
    end

    -- xenon
    if p.xenon ~= nil then ToggleVehicleMod(veh, 22, p.xenon == true) end
    if p.xenonColor ~= nil then SetVehicleXenonLightsColor(veh, num(p.xenonColor, -1)) end

    -- tyre smoke / bulletproof
    if type(p.tyreSmokeColor) == 'table' then
        SetVehicleTyreSmokeColor(veh, num(p.tyreSmokeColor.r or p.tyreSmokeColor[1], 255),
            num(p.tyreSmokeColor.g or p.tyreSmokeColor[2], 255), num(p.tyreSmokeColor.b or p.tyreSmokeColor[3], 255))
    end
    if p.bulletproofTyres ~= nil then SetVehicleTyresCanBurst(veh, not (p.bulletproofTyres == true)) end

    -- livery
    if p.livery ~= nil and num(p.livery, -1) >= 0 then SetVehicleLivery(veh, num(p.livery, -1)) end
    if p.roofLivery ~= nil and num(p.roofLivery, -1) >= 0 then SetVehicleRoofLivery(veh, num(p.roofLivery, -1)) end
end
