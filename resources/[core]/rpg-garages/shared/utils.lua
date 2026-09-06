-- ===========================================================================
--  rpg-garages — utilitare partajate (client + server)
-- ===========================================================================
Utils = {}

-- ---- tip garage valid? ------------------------------------------------
function Utils.isValidGarageType(t)
    return t ~= nil and Config.GarageTypes[t] ~= nil
end

-- ---- vehicle_type dintr-un model (fallback pt. /vcreate) --------------
-- Prioritate: catalog dealership > Config.VehicleTypeByModel > 'Vehicle'.
function Utils.vehicleTypeForModel(model)
    model = tostring(model or ''):lower()
    for _, e in ipairs(Config.Catalog) do
        if e.model:lower() == model then return e.type end
    end
    return Config.VehicleTypeByModel[model] or 'Vehicle'
end

-- ---- clasa GTA -> tip garage (client-side, cand avem GetVehicleClass) --
--  Clase: 8 = Motorcycles, 13 = Cycles, 14 = Boats, 15 = Helicopters, 16 = Planes.
function Utils.garageTypeFromClass(class)
    if class == 14 then return 'Boat' end
    if class == 15 or class == 16 then return 'Heli' end
    return 'Vehicle'
end

-- ---- placa random -------------------------------------------------
function Utils.randomPlate()
    local chars, out = Config.Plate.chars, {}
    for i = 1, (Config.Plate.len or 8) do
        local n = math.random(1, #chars)
        out[i] = chars:sub(n, n)
    end
    return table.concat(out)
end

-- ---- status semantic --------------------------------------------
Utils.STATUS_LOCKED   = 0
Utils.STATUS_UNLOCKED = 1
function Utils.statusLabel(v)
    return (Utils.toBit(v) == Utils.STATUS_UNLOCKED) and 'Unlocked' or 'Locked'
end

-- oxmysql poate returna coloanele TINYINT(1) ca boolean (true/false), iar
-- tonumber(true) == nil. Normalizam ORICE valoare de bit citita din DB la 0/1.
function Utils.toBit(v)
    if v == true then return 1 end
    if v == false or v == nil then return 0 end
    return tonumber(v) or 0
end

-- ---- clamp numeric -------------------------------------------------
function Utils.clampInt(v, lo, hi, dflt)
    v = tonumber(v)
    if v == nil then return dflt end
    v = math.floor(v)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end
function Utils.clampNum(v, lo, hi, dflt)
    v = tonumber(v)
    if v == nil then return dflt end
    if v < lo then return lo elseif v > hi then return hi end
    return v + 0.0
end

-- ===========================================================================
--  FACTION HOOK
--  Server-side. Nu exista sistem de facțiuni -> foloseste placeholder-ul din
--  config. Cand adaugi unul real, inlocuieste corpul cu apelul catre el
--  (ex. exports['rpg-factions']:isMember(src, slug)).
-- ===========================================================================
function Utils.isFactionMember(src, slug)
    if not slug or slug == '' then return false end
    if not IsDuplicityVersion or not IsDuplicityVersion() then return false end -- doar server

    local ok, acc = pcall(function() return exports['rpg-auth']:getAccount(src) end)
    local uid = (ok and acc) and acc.id or nil
    if not uid then return false end

    local list = Config.FactionMembersByUserId[uid]
    if type(list) == 'table' then
        for _, f in ipairs(list) do
            if f == slug then return true end
        end
    end
    return false
end

return true
