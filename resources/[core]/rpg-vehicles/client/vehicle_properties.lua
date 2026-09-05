-- ===========================================================================
--  rpg-vehicles — VehicleProps.get / VehicleProps.set
--  Serializeaza / aplica tuning-ul complet al unui vehicul (culori, toate
--  sloturile de mod 0..48, roti, extras, neon, xenon, fum, geamuri, placuta,
--  livery). Implementarea standard, folosita in mii de scripturi FiveM.
-- ===========================================================================

VehicleProps = {}

function VehicleProps.get(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimary = GetIsVehiclePrimaryColourCustom(vehicle)
    local customPrimary
    if hasCustomPrimary then
        local r, g, b = GetVehicleCustomPrimaryColour(vehicle)
        customPrimary = { r, g, b }
    end
    local hasCustomSecondary = GetIsVehicleSecondaryColourCustom(vehicle)
    local customSecondary
    if hasCustomSecondary then
        local r, g, b = GetVehicleCustomSecondaryColour(vehicle)
        customSecondary = { r, g, b }
    end

    local extras = {}
    for id = 0, 20 do
        if DoesExtraExist(vehicle, id) then
            extras[tostring(id)] = IsVehicleExtraTurnedOn(vehicle, id) == 1
        end
    end

    local mods = {}
    for i = 0, 48 do
        mods[tostring(i)] = GetVehicleMod(vehicle, i)
    end

    local neon = {}
    for i = 0, 3 do
        neon[i + 1] = IsVehicleNeonLightEnabled(vehicle, i)
    end
    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local tr, tg, tb = GetVehicleTyreSmokeColor(vehicle)

    return {
        model             = GetEntityModel(vehicle),
        plate             = GetVehicleNumberPlateText(vehicle),
        plateIndex        = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth        = math.floor(GetVehicleBodyHealth(vehicle) + 0.5),
        engineHealth      = math.floor(GetVehicleEngineHealth(vehicle) + 0.5),
        tankHealth        = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5),
        dirtLevel         = math.floor(GetVehicleDirtLevel(vehicle) + 0.5),

        color1            = colorPrimary,
        color2            = colorSecondary,
        customPrimaryColor   = customPrimary,
        customSecondaryColor = customSecondary,
        pearlescentColor  = pearlescentColor,
        wheelColor        = wheelColor,
        dashboardColor    = GetVehicleDashboardColour(vehicle),
        interiorColor     = GetVehicleInteriorColour(vehicle),

        wheels            = GetVehicleWheelType(vehicle),
        windowTint        = GetVehicleWindowTint(vehicle),
        xenonColor        = GetVehicleXenonLightsColour(vehicle),

        neonEnabled       = neon,
        neonColor         = { nr, ng, nb },
        tyreSmokeColor    = { tr, tg, tb },

        modTurbo          = IsToggleModOn(vehicle, 18),
        modXenon          = IsToggleModOn(vehicle, 22),
        modTyreSmoke      = IsToggleModOn(vehicle, 20),
        modFrontWheels    = GetVehicleMod(vehicle, 23),
        modBackWheels     = GetVehicleMod(vehicle, 24),
        modCustomTiresF   = GetVehicleModVariation(vehicle, 23),
        modCustomTiresR   = GetVehicleModVariation(vehicle, 24),
        modLivery         = GetVehicleLivery(vehicle),
        modRoofLivery     = GetVehicleRoofLivery(vehicle),

        mods              = mods,
        extras            = extras,
    }
end

function VehicleProps.set(vehicle, props)
    if not DoesEntityExist(vehicle) or type(props) ~= 'table' then return end

    SetVehicleModKit(vehicle, 0)

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end

    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end

    if props.color1 ~= nil and props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1, props.color2)
    end
    if props.customPrimaryColor then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end
    if props.customSecondaryColor then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end
    if props.pearlescentColor ~= nil and props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor)
    end
    if props.dashboardColor ~= nil then SetVehicleDashboardColour(vehicle, props.dashboardColor) end
    if props.interiorColor ~= nil then SetVehicleInteriorColour(vehicle, props.interiorColor) end

    if props.wheels ~= nil then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint ~= nil then SetVehicleWindowTint(vehicle, props.windowTint) end
    if props.xenonColor ~= nil then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end

    if props.extras then
        for id, on in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(id), on and 0 or 1)   -- 0 = pornit (contraintuitiv), 1 = oprit
        end
    end

    if props.neonEnabled then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] and true or false)
        end
    end
    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo and true or false) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon and true or false) end
    if props.modTyreSmoke ~= nil then ToggleVehicleMod(vehicle, 20, props.modTyreSmoke and true or false) end

    if props.mods then
        for i = 0, 48 do
            local v = props.mods[tostring(i)]
            if v ~= nil and v ~= -1 then SetVehicleMod(vehicle, i, v, false) end
        end
    end

    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomTiresF and true or false)
    end
    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomTiresR and true or false)
    end
    if props.modLivery ~= nil and props.modLivery ~= -1 then SetVehicleLivery(vehicle, props.modLivery) end
    if props.modRoofLivery ~= nil and props.modRoofLivery ~= -1 then SetVehicleRoofLivery(vehicle, props.modRoofLivery) end
end
