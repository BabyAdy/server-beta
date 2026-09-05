-- ===========================================================================
--  rpg-inventory — CLOTHING APPLIER (client)
--  Pune pe ped componenta / prop-ul unui item de tip "clothing" cand e
--  echipat intr-un slot din Config.EquipmentSlots. La dezechipare readuce
--  baza (rpg-characters:reapplyClothingBase) si re-aplica ce a mai ramas.
--
--  Drawable/texture:
--    - item in Config.StaffClothingModels  -> varianta male/female (haine addon staff)
--    - altfel                        -> item.metadata.drawable / .texture
-- ===========================================================================

local FEMALE_HASH = GetHashKey('mp_f_freemode_01')

local slotDefByKey = {}
for _, s in ipairs(Config.EquipmentSlots or {}) do slotDefByKey[s.key] = s end

local charReady = false
local applied   = {}   -- [slotKey] = { isProp, id, drawable, texture }

local function isPedFemale()
    return GetEntityModel(PlayerPedId()) == FEMALE_HASH
end

-- ce trebuie aplicat pentru un item dintr-un slot de echipament (sau nil)
local function resolve(slotKey, item)
    local def = slotDefByKey[slotKey]
    if not def then return nil end
    if Config.ClothingApply and Config.ClothingApply.ignoreSlots
       and Config.ClothingApply.ignoreSlots[slotKey] then return nil end

    local isProp = def.prop ~= nil
    local id     = isProp and def.prop or def.component
    if id == nil then return nil end

    local drawable, texture = 0, 0
    local w = Config.StaffClothingModels and Config.StaffClothingModels[item.itemId]
    if w then
        local v = (isPedFemale() and w.female) or w.male or w.female
        if v then drawable, texture = v.drawable or 0, v.texture or 0 end
    else
        local md = item.metadata or {}
        drawable = tonumber(md.drawable) or 0
        texture  = tonumber(md.texture) or 0
    end

    return { isProp = isProp, id = id, drawable = drawable, texture = texture }
end

local function put(ped, e)
    if e.isProp then
        if e.drawable < 0 then
            ClearPedProp(ped, e.id)
        else
            SetPedPropIndex(ped, e.id, e.drawable, e.texture, true)
        end
    else
        SetPedComponentVariation(ped, e.id, e.drawable, e.texture, 0)
    end
end

local function apply()
    if not charReady then return end
    local ped  = PlayerPedId()
    local snap = Inv and Inv.snapshot or nil
    local equip = (snap and snap.equipment) or {}

    -- ce vrem acum
    local desired = {}
    for slotKey, item in pairs(equip) do
        if type(item) == 'table' and item.itemId then
            local e = resolve(slotKey, item)
            if e then desired[slotKey] = e end
        end
    end

    -- s-a scos ceva fata de starea anterioara? -> readu baza, apoi re-pune tot
    local removed = false
    for slotKey in pairs(applied) do
        if not desired[slotKey] then removed = true break end
    end
    if removed then
        pcall(function() exports['rpg-characters']:reapplyClothingBase() end)
        ped = PlayerPedId()
    end

    for _, e in pairs(desired) do put(ped, e) end
    applied = desired
end

-- re-aplica doar (fara logica de "removed") — pt. reassert periodic
local function reassert()
    if not charReady or not next(applied) then return end
    local ped = PlayerPedId()
    for _, e in pairs(applied) do put(ped, e) end
end

-- ----- carlige -------------------------------------------------------------
AddEventHandler('core:characterSpawned', function()
    charReady = true
    applied = {}
    SetTimeout(600, apply)
end)

RegisterNetEvent('rpg-inventory:sync', function()
    -- Inv.snapshot e deja actualizat de client/main.lua (acelasi eveniment)
    SetTimeout(0, apply)
end)

CreateThread(function()
    local iv = (Config.ClothingApply and Config.ClothingApply.reassertInterval) or 4000
    if iv <= 0 then return end
    while true do
        Wait(iv)
        reassert()
    end
end)

exports('refreshClothing', apply)
