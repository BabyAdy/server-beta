-- ===========================================================================
--  rpg-duty — CLIENT
--
--  - Punct de outfit (Config.FactionPoints[fid].outfit): E creeaza / Y modifica.
--  - Editor de outfit NUI: derulezi drawable + textura pe fiecare slot, live pe
--    ped, apoi Save -> se trimite la server.
--  - /duty ON  -> aplica outfit-ul salvat si il "blocheaza" (re-assert la 2s).
--    /duty OFF -> readuce hainele din inventar (rpg-characters base + rpg-inventory).
--
--  Nota: comanda /duty e SERVER-only (ca /a, /f, /pc). Aici NU o inregistram,
--  altfel ar umbri comanda de pe server.
-- ===========================================================================

local RES        = GetCurrentResourceName()
local dutyOn     = false
local dutyOutfit = nil
local hasOutfit  = false
local editorOpen = false
local snapshot   = nil

-- ---- helpers ped -------------------------------------------
local function pedComp(ped, id) return GetPedDrawableVariation(ped, id), GetPedTextureVariation(ped, id) end
local function pedProp(ped, id) return GetPedPropIndex(ped, id), GetPedPropTextureIndex(ped, id) end

local function setComp(ped, id, d, t) SetPedComponentVariation(ped, id, d, t, 0) end
local function setProp(ped, id, d, t)
    if d == nil or d < 0 then ClearPedProp(ped, id)
    else SetPedPropIndex(ped, id, d, t, true) end
end

local function applyOutfit(o)
    if type(o) ~= 'table' then return end
    local ped = PlayerPedId()
    for k, v in pairs(o.comp or {}) do
        local id = tonumber(k)
        if id and type(v) == 'table' then setComp(ped, id, math.floor(v.d or 0), math.floor(v.t or 0)) end
    end
    for k, v in pairs(o.prop or {}) do
        local id = tonumber(k)
        if id and type(v) == 'table' then setProp(ped, id, math.floor(v.d or -1), math.floor(v.t or 0)) end
    end
end

local function takeSnapshot()
    local ped = PlayerPedId()
    local s = { comp = {}, prop = {} }
    for _, c in ipairs(Config.OutfitComponents) do
        local d, t = pedComp(ped, c.id); s.comp[c.id] = { d = d, t = t }
    end
    for _, p in ipairs(Config.OutfitProps) do
        local d, t = pedProp(ped, p.id); s.prop[p.id] = { d = d, t = t }
    end
    return s
end

local function restoreBaseClothes()
    -- readuce baza personajului; rpg-inventory re-aplica hainele echipate (reassert ~4s)
    pcall(function() exports['rpg-characters']:reapplyClothingBase() end)
end

local function helpText(txt)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(txt)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function myFaction() return LocalPlayer.state.faction or 0 end

-- ---- server -> client ------------------------------------
RegisterNetEvent('rpg-duty:apply', function(d)
    d = d or {}
    dutyOn = d.on == true
    dutyOutfit = d.on and d.outfit or nil
    if dutyOn and dutyOutfit then
        applyOutfit(dutyOutfit)
    elseif not dutyOn then
        restoreBaseClothes()
    end
end)

RegisterNetEvent('rpg-duty:outfitState', function(d)
    hasOutfit = (d and d.has) == true
end)

-- re-assert outfit-ul cat esti pe duty (nu poti scoate hainele)
CreateThread(function()
    while true do
        if dutyOn and dutyOutfit then
            applyOutfit(dutyOutfit)
            Wait(2000)
        else
            Wait(1000)
        end
    end
end)

-- cere starea outfit-ului la spawn si cand se schimba factiunea
AddEventHandler('core:characterSpawned', function()
    SetTimeout(2500, function() TriggerServerEvent('rpg-duty:requestOutfitState') end)
end)
AddStateBagChangeHandler('faction', nil, function(bag)
    if bag == ('player:' .. GetPlayerServerId(PlayerId())) then
        SetTimeout(500, function() TriggerServerEvent('rpg-duty:requestOutfitState') end)
    end
end)

-- ===========================================================================
--  EDITOR DE OUTFIT (NUI)
-- ===========================================================================
local function openEditor()
    if editorOpen or dutyOn then return end
    if dutyOn then return end
    editorOpen = true
    snapshot = takeSnapshot()

    local ped = PlayerPedId()
    local comps, props = {}, {}
    for _, c in ipairs(Config.OutfitComponents) do
        local dd, tt = pedComp(ped, c.id)
        comps[#comps + 1] = { id = c.id, label = c.label, d = dd, t = tt,
            maxD = math.max(0, GetNumberOfPedDrawableVariations(ped, c.id) - 1),
            maxT = math.max(0, GetNumberOfPedTextureVariations(ped, c.id, dd) - 1) }
    end
    for _, p in ipairs(Config.OutfitProps) do
        local dd, tt = pedProp(ped, p.id)
        props[#props + 1] = { id = p.id, label = p.label, d = dd, t = tt,
            maxD = GetNumberOfPedPropDrawableVariations(ped, p.id) - 1,
            maxT = math.max(0, GetNumberOfPedPropTextureVariations(ped, p.id, dd < 0 and 0 or dd) - 1) }
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openEditor', comps = comps, props = props })
end

local function closeEditor(restore)
    if not editorOpen then return end
    editorOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeEditor' })
    if restore and snapshot then
        local ped = PlayerPedId()
        for id, v in pairs(snapshot.comp) do setComp(ped, id, v.d, v.t) end
        for id, v in pairs(snapshot.prop) do setProp(ped, id, v.d, v.t) end
        restoreBaseClothes()
    end
    snapshot = nil
end

RegisterNUICallback('outfitStep', function(data, cb)
    local ped   = PlayerPedId()
    local kind  = data and data.kind
    local id    = tonumber(data and data.id)
    local field = data and data.field
    local dir   = tonumber(data and data.dir) or 0
    if not id or (field ~= 'd' and field ~= 't') then return cb({}) end

    if kind == 'comp' then
        local d, t = pedComp(ped, id)
        if field == 'd' then
            local maxD = math.max(0, GetNumberOfPedDrawableVariations(ped, id) - 1)
            d = d + dir; if d < 0 then d = maxD elseif d > maxD then d = 0 end
            t = 0
        else
            local maxT = math.max(0, GetNumberOfPedTextureVariations(ped, id, d) - 1)
            t = t + dir; if t < 0 then t = maxT elseif t > maxT then t = 0 end
        end
        setComp(ped, id, d, t)
        cb({ d = d, t = t,
             maxD = math.max(0, GetNumberOfPedDrawableVariations(ped, id) - 1),
             maxT = math.max(0, GetNumberOfPedTextureVariations(ped, id, d) - 1) })
    elseif kind == 'prop' then
        local d, t = pedProp(ped, id)
        if field == 'd' then
            local maxD = GetNumberOfPedPropDrawableVariations(ped, id) - 1
            d = d + dir; if d < -1 then d = maxD elseif d > maxD then d = -1 end
            t = 0
        else
            local base = d < 0 and 0 or d
            local maxT = math.max(0, GetNumberOfPedPropTextureVariations(ped, id, base) - 1)
            t = t + dir; if t < 0 then t = maxT elseif t > maxT then t = 0 end
        end
        setProp(ped, id, d, t)
        cb({ d = d, t = t,
             maxD = GetNumberOfPedPropDrawableVariations(ped, id) - 1,
             maxT = math.max(0, GetNumberOfPedPropTextureVariations(ped, id, d < 0 and 0 or d) - 1) })
    else
        cb({})
    end
end)

RegisterNUICallback('outfitSave', function(_, cb)
    local ped = PlayerPedId()
    local o = { comp = {}, prop = {} }
    for _, c in ipairs(Config.OutfitComponents) do
        local d, t = pedComp(ped, c.id); o.comp[tostring(c.id)] = { d = d, t = t }
    end
    for _, p in ipairs(Config.OutfitProps) do
        local d, t = pedProp(ped, p.id); o.prop[tostring(p.id)] = { d = d, t = t }
    end
    TriggerServerEvent('rpg-duty:saveOutfit', o)
    hasOutfit = true
    closeEditor(false)
    cb('ok')
end)

RegisterNUICallback('outfitCancel', function(_, cb)
    closeEditor(true)
    cb('ok')
end)

-- ---- punct de outfit: marker + tasta --------------------
CreateThread(function()
    while true do
        local wait = 800
        local fid = myFaction()
        local pt  = (fid ~= 0 and Config.FactionPoints) and Config.FactionPoints[fid] or nil
        if pt and pt.outfit and not editorOpen and not dutyOn then
            local p  = pt.outfit
            local pc = GetEntityCoords(PlayerPedId())
            local d  = #(pc - vector3(p.x, p.y, p.z))
            if d < 20.0 then
                wait = 0
                DrawMarker(1, p.x, p.y, p.z - 0.98, 0,0,0, 0,0,0, 1.0, 1.0, 0.6,
                    110, 119, 250, 120, false, false, 2, false, nil, nil, false)
                if d < 1.6 then
                    local key = hasOutfit and Config.KeyModify or Config.KeyCreate
                    helpText(hasOutfit and 'Apasă ~INPUT_MP_TEXT_CHAT_TEAM~ pentru a modifica outfit-ul'
                                        or  'Apasă ~INPUT_CONTEXT~ pentru a-ți face outfit-ul')
                    if IsControlJustReleased(0, key) then openEditor() end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == RES and editorOpen then SetNuiFocus(false, false) end
end)
