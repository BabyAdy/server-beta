-- ===========================================================================
--  rpg-garages — server / tuning
--  Persistenta tuning in `vehicle_tunning.data` (JSON). TOT ce vine de la client
--  este trecut prin Tuning.sanitize (whitelist + clamp). Query-uri parametrizate
--  -> fara SQL injection. O linie per vehicul (uniq_vehicle).
-- ===========================================================================

Tuning = Tuning or {}

-- ---- schema de scalari: cheie -> { min, max, int? } -------------------
local SCALARS = {
    plateIndex        = { 0, 5,  true },
    primaryColor      = { 0, 160, true },
    secondaryColor    = { 0, 160, true },
    pearlescentColor  = { 0, 160, true },
    wheelColor        = { 0, 160, true },
    dashboardColor    = { 0, 160, true },
    interiorColor     = { 0, 160, true },
    wheelType         = { 0, 7,  true },
    windowTint        = { 0, 6,  true },
    xenonColor        = { -1, 12, true },
    livery            = { -1, 30, true },
    roofLivery        = { -1, 30, true },
}

local function rgb(t)
    if type(t) ~= 'table' then return nil end
    return {
        Utils.clampInt(t.r or t[1], 0, 255, 0),
        Utils.clampInt(t.g or t[2], 0, 255, 0),
        Utils.clampInt(t.b or t[3], 0, 255, 0),
    }
end

-- ---------------------------------------------------------------------------
--  SANITIZE — sursa de adevar pentru forma stocata
-- ---------------------------------------------------------------------------
function Tuning.sanitize(raw)
    if type(raw) ~= 'table' then return {} end
    local out = {}

    for key, rule in pairs(SCALARS) do
        if raw[key] ~= nil then
            out[key] = Utils.clampInt(raw[key], rule[1], rule[2], rule[1])
        end
    end

    -- placa: doar A-Z 0-9 spatiu, max 8
    if raw.plate ~= nil then
        local p = tostring(raw.plate):upper():gsub('[^A-Z0-9 ]', ''):sub(1, 8)
        if p ~= '' then out.plate = p end
    end

    -- booleeni simpli
    for _, key in ipairs({ 'xenon', 'bulletproofTyres', 'customTyres' }) do
        if raw[key] ~= nil then out[key] = raw[key] == true end
    end

    -- culori custom RGB (nil = folosim index-ul de mai sus)
    if raw.customPrimary   then out.customPrimary   = rgb(raw.customPrimary) end
    if raw.customSecondary then out.customSecondary = rgb(raw.customSecondary) end
    if raw.neonColor       then out.neonColor       = rgb(raw.neonColor) end
    if raw.tyreSmokeColor  then out.tyreSmokeColor  = rgb(raw.tyreSmokeColor) end

    -- neon: 4 laturi (0 = left, 1 = right, 2 = front, 3 = back)
    if type(raw.neonEnabled) == 'table' then
        local n = {}
        for i = 0, 3 do
            local v = raw.neonEnabled[i] ; if v == nil then v = raw.neonEnabled[tostring(i)] end
            n[i] = v == true
        end
        out.neonEnabled = n
    end

    -- extras 1..20
    if type(raw.extras) == 'table' then
        local e = {}
        for i = 0, 20 do
            local v = raw.extras[i] ; if v == nil then v = raw.extras[tostring(i)] end
            if v ~= nil then e[i] = v == true end
        end
        out.extras = e
    end

    -- mods 0..48 -> index (-1 = stock, altfel 0..49)
    if type(raw.mods) == 'table' then
        local m = {}
        for k, v in pairs(raw.mods) do
            local mt = tonumber(k)
            if mt and mt >= 0 and mt <= 48 then
                m[mt] = Utils.clampInt(v, -1, 60, -1)
            end
        end
        out.mods = m
    end

    -- toggle mods (17..22): { [id] = bool }
    if type(raw.modToggles) == 'table' then
        local t = {}
        for k, v in pairs(raw.modToggles) do
            local mt = tonumber(k)
            if mt and mt >= 17 and mt <= 22 then t[mt] = v == true end
        end
        out.modToggles = t
    end

    -- roti custom fata/spate (mod 23 / 24)
    if type(raw.wheelMods) == 'table' then
        out.wheelMods = {
            front = Utils.clampInt(raw.wheelMods.front, -1, 60, -1),
            rear  = Utils.clampInt(raw.wheelMods.rear,  -1, 60, -1),
        }
    end

    return out
end

-- ---------------------------------------------------------------------------
--  LOAD / SAVE
-- ---------------------------------------------------------------------------
function Tuning.load(pvId)
    local row = MySQL.single.await(
        'SELECT data FROM vehicle_tunning WHERE vehicle_id = ? LIMIT 1', { pvId })
    if not row or not row.data or row.data == '' then return {} end
    local ok, decoded = pcall(json.decode, row.data)
    return (ok and type(decoded) == 'table') and decoded or {}
end

-- upsert (linia se creeaza la Vehicle.create, dar facem upsert defensiv)
function Tuning.save(pvId, ownerId, cleanTable)
    local payload = json.encode(cleanTable or {})
    MySQL.update.await([[
        INSERT INTO vehicle_tunning (vehicle_id, owner_id, data)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data), owner_id = VALUES(owner_id)
    ]], { pvId, ownerId, payload })
end

function Tuning.initRow(pvId, ownerId)
    MySQL.update.await([[
        INSERT INTO vehicle_tunning (vehicle_id, owner_id, data)
        VALUES (?, ?, NULL)
        ON DUPLICATE KEY UPDATE owner_id = VALUES(owner_id)
    ]], { pvId, ownerId })
end
