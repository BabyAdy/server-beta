-- ===========================================================================
--  rpg-duty — SERVER
--
--  /duty  -> toggle ON/OFF, DOAR daca esti intr-o factiune si te afli in HQ-ul ei
--            (raza Config.HqRange fata de punctul EXIT + acelasi routing bucket).
--  ON  -> anunt de proximitate + aplica outfit-ul salvat (client) + lock haine.
--  OFF -> anunt de proximitate + revine la hainele din inventar (client).
--
--  Outfit-ul se face la punctul din Config.FactionPoints[fid].outfit (tasta E,
--  ulterior Y). Se salveaza in `faction_outfits` per (char_id, faction_id).
--
--  FAZA 2 (mesaj separat): loadout de arme pe rank + snapshot fast-slot +
--  restrictiile de drop/mutare/job cat esti pe duty.
-- ===========================================================================

local DBG = Config.Debug
local outfits = {}   -- cache: [charId] = { [factionId] = outfitTable }

local function log(...) if DBG then print('[rpg-duty]', ...) end end

local function charIdOf(src)
    local ok, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    return (ok and ch and ch.id) and tonumber(ch.id) or nil
end
local function nameOf(src)
    local ok, ch = pcall(function() return exports['rpg-characters']:getCharacter(src) end)
    if ok and ch and ch.username then return ch.username end
    return GetPlayerName(src) or ('src' .. src)
end
local function factionOf(src)
    local ok, fid = pcall(function() return exports['rpg-factions']:getFaction(src) end)
    return (ok and tonumber(fid)) or 0
end
local function factionData(fid)
    local ok, row = pcall(function() return exports['rpg-factions']:getFactionData(fid) end)
    return (ok and row) or nil
end

-- ---- schema -------------------------------------------------------
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(200) end
    Wait(600)
    local sql = LoadResourceFile(GetCurrentResourceName(), 'sql/rpg_duty.sql')
    if sql then
        for stmt in (sql .. '\n'):gmatch('(.-);%s*\n') do
            local s = stmt:gsub('%-%-[^\n]*', ''):gsub('^%s+', ''):gsub('%s+$', '')
            if s ~= '' then MySQL.query.await(s) end
        end
    end
    log('schema OK')
end)

-- ---- outfit store ----------------------------------------------
local function loadOutfit(charId, fid)
    if outfits[charId] and outfits[charId][fid] ~= nil then
        return outfits[charId][fid] or nil
    end
    local row = MySQL.single.await(
        'SELECT outfit FROM faction_outfits WHERE char_id = ? AND faction_id = ? LIMIT 1', { charId, fid })
    local o = nil
    if row and row.outfit then
        local ok, dec = pcall(json.decode, row.outfit)
        if ok and type(dec) == 'table' then o = dec end
    end
    outfits[charId] = outfits[charId] or {}
    outfits[charId][fid] = o or false
    return o
end

local function saveOutfit(charId, fid, outfit)
    outfits[charId] = outfits[charId] or {}
    outfits[charId][fid] = outfit
    MySQL.update.await([[
        INSERT INTO faction_outfits (char_id, faction_id, outfit) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE outfit = VALUES(outfit)
    ]], { charId, fid, json.encode(outfit) })
end

-- validare / sanitizare a payload-ului de outfit primit din NUI
local function sanitizeOutfit(raw)
    if type(raw) ~= 'table' then return nil end
    local out = { comp = {}, prop = {} }
    local function pull(dst, src)
        if type(src) ~= 'table' then return end
        for k, v in pairs(src) do
            local id = tonumber(k)
            if id and type(v) == 'table' then
                local d = math.floor(tonumber(v.d) or 0)
                local t = math.floor(tonumber(v.t) or 0)
                if d >= -1 and d <= 4000 and t >= 0 and t <= 400 then
                    dst[tostring(id)] = { d = d, t = t }
                end
            end
        end
    end
    pull(out.comp, raw.comp)
    pull(out.prop, raw.prop)
    if next(out.comp) == nil and next(out.prop) == nil then return nil end
    return out
end

-- ---- HQ gate ----------------------------------------------------
local function inHqForDuty(src, fid)
    local row = factionData(fid)
    if not row or not row.hq or (row.hq.vw or 0) == 0 then return false, 'Faction has no HQ configured.' end
    local exit = row.hq.leave or row.hq.enter
    if not exit then return false, 'Faction HQ has no exit point.' end

    if GetPlayerRoutingBucket(src) ~= (row.hq.vw or 0) then
        return false, 'You must be inside the faction HQ.'
    end
    local ped = GetPlayerPed(src)
    local c = ped and ped ~= 0 and GetEntityCoords(ped) or nil
    if not c then return false, 'Position error.' end
    if #(vector3(c.x, c.y, c.z) - vector3(exit.x + 0.0, exit.y + 0.0, exit.z + 0.0)) > (Config.HqRange or 50.0) then
        return false, 'You must be inside the faction HQ to change duty.'
    end
    return true
end

-- ---- proximity announce (raza AnnounceRange) -----------------
local function announce(src, text)
    local ped = GetPlayerPed(src)
    local c = ped and ped ~= 0 and GetEntityCoords(ped) or nil
    if not c then return end
    local col = Config.AnnounceColor or '#6E77FA'
    for _, pid in ipairs(GetPlayers()) do
        local t = tonumber(pid)
        local tp = GetPlayerPed(t)
        if tp and tp ~= 0 and #(GetEntityCoords(tp) - c) <= (Config.AnnounceRange or 10.0) then
            TriggerClientEvent('rpg-hud:chatMessage', t, { text = text, color = col, time = os.date('%H:%M') })
        end
    end
end

-- ---- state helpers -------------------------------------------
local function isOnDuty(src)
    local okp, st = pcall(function() return Player(src).state end)
    return okp and st and st.duty == true
end
local function setDuty(src, on, fid)
    local okp, st = pcall(function() return Player(src).state end)
    if not okp or not st then return end
    st:set('duty', on == true, true)
    st:set('dutyFaction', on and fid or 0, true)
end

-- ===========================================================================
--  /duty
-- ===========================================================================
RegisterCommand(Config.DutyCommand, function(src)
    if src <= 0 then return end

    local fid = factionOf(src)
    if fid == 0 then
        return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = 'You are not in a faction.' })
    end

    local turningOn = not isOnDuty(src)

    -- ON: nu poti intra pe duty daca esti in mijlocul unui job
    if turningOn then
        local working = false
        pcall(function() working = exports['rpg-jobs']:isWorking(src) == true end)
        if working then
            return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = 'Finish your current job before going on duty.' })
        end
    end

    local ok, why = inHqForDuty(src, fid)
    if not ok then
        return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = why or 'You cannot do that here.' })
    end

    local charId = charIdOf(src)
    if not charId then
        return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = 'Character error.' })
    end

    local outfit = loadOutfit(charId, fid)
    if turningOn and not outfit then
        return exports['rpg-hud']:addChatMessage(src, {
            channel = 'ERROR',
            text = 'Set up your faction outfit first (press E at the wardrobe point in the HQ).'
        })
    end

    setDuty(src, turningOn, fid)
    local nm = nameOf(src)
    announce(src, ('%s is now %s duty!'):format(nm, turningOn and 'on' or 'off'))

    -- clientul aplica / scoate outfit-ul (+ FAZA 2: loadout arme, fast-slot snapshot)
    TriggerClientEvent('rpg-duty:apply', src, { on = turningOn, outfit = turningOn and outfit or nil })

    log(('%s (char %s) -> duty %s (faction #%d)'):format(nm, charId, turningOn and 'ON' or 'OFF', fid))
end, false)

-- ===========================================================================
--  OUTFIT — salvare din editorul NUI
-- ===========================================================================
RegisterNetEvent('rpg-duty:saveOutfit', function(raw)
    local src = source
    local fid = factionOf(src)
    if fid == 0 then return end
    local charId = charIdOf(src)
    if not charId then return end
    if isOnDuty(src) then
        return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = 'You cannot change your outfit while on duty.' })
    end

    local outfit = sanitizeOutfit(raw)
    if not outfit then
        return exports['rpg-hud']:addChatMessage(src, { channel = 'ERROR', text = 'Invalid outfit.' })
    end

    saveOutfit(charId, fid, outfit)
    exports['rpg-hud']:addChatMessage(src, { channel = 'SUCCESS', text = 'Faction outfit saved. Use /duty at the HQ to go on duty.' })
    TriggerClientEvent('rpg-duty:outfitState', src, { has = true })
    log(('%s (char %s) saved outfit for faction #%d'):format(nameOf(src), charId, fid))
end)

-- clientul cere daca are outfit salvat (la spawn / la intrarea in factiune)
RegisterNetEvent('rpg-duty:requestOutfitState', function()
    local src = source
    local fid = factionOf(src)
    local charId = charIdOf(src)
    local has = false
    if fid ~= 0 and charId then has = loadOutfit(charId, fid) ~= nil end
    TriggerClientEvent('rpg-duty:outfitState', src, { has = has })
end)

-- ---- lifecycle ---------------------------------------------
AddEventHandler('playerDropped', function()
    local src = source
    local cid = charIdOf(src)
    if cid then outfits[cid] = nil end
end)

-- daca cineva iese din factiune cat e pe duty -> il fortam OFF
CreateThread(function()
    while true do
        Wait(5000)
        for _, pid in ipairs(GetPlayers()) do
            local t = tonumber(pid)
            if isOnDuty(t) then
                local okp, st = pcall(function() return Player(t).state end)
                local df = okp and st and st.dutyFaction or 0
                if factionOf(t) ~= df or df == 0 then
                    setDuty(t, false, 0)
                    announce(t, ('%s is now off duty!'):format(nameOf(t)))
                    TriggerClientEvent('rpg-duty:apply', t, { on = false })
                end
            end
        end
    end
end)

-- ===========================================================================
--  EXPORTS  (folosite de rpg-inventory / rpg-jobs in FAZA 2)
-- ===========================================================================
exports('isOnDuty',  function(src) return isOnDuty(src) end)
exports('getDutyFaction', function(src)
    local okp, st = pcall(function() return Player(src).state end)
    return (okp and st and st.dutyFaction) or 0
end)
exports('hasOutfit', function(charId, fid)
    charId, fid = tonumber(charId), tonumber(fid)
    if not charId or not fid then return false end
    return loadOutfit(charId, fid) ~= nil
end)
