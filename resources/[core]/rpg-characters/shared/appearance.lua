-- ===========================================================================
--  Structura de aspect (appearance) + valori implicite + limite.
--  Folosita atat pe client (aplicare pe ped) cat si pe server (sanitizare).
--
--  Indexi:
--    faceFeatures : 0..19  (SetPedFaceFeature)            -> array 1..20
--    headOverlays : 0..11  (SetPedHeadOverlay)            -> array 1..12
--    headBlend    : mother/father 0..45, mix 0.0..1.0
-- ===========================================================================

Appearance = {}

Appearance.MODELS = {
    male   = 'mp_m_freemode_01',
    female = 'mp_f_freemode_01',
}

-- id overlay -> are culoare? ce tip? (1 = culori par, 2 = culori machiaj)
Appearance.OVERLAYS = {
    [0]  = { color = false },                    -- imperfectiuni piele
    [1]  = { color = true,  colorType = 1 },     -- barba
    [2]  = { color = true,  colorType = 1 },     -- sprancene
    [3]  = { color = false },                    -- imbatranire
    [4]  = { color = true,  colorType = 2 },     -- machiaj
    [5]  = { color = true,  colorType = 2 },     -- fard obraji
    [6]  = { color = false },                    -- ten
    [7]  = { color = false },                    -- arsura solara
    [8]  = { color = true,  colorType = 2 },     -- ruj
    [9]  = { color = false },                    -- pistrui / alunite
    [10] = { color = true,  colorType = 1 },     -- par piept
    [11] = { color = false },                    -- pete corp
}

Appearance.LIMITS = {
    parent   = { 0, 45 },
    mix      = { 0.0, 1.0 },
    face     = { -1.0, 1.0 },
    hairStyle = { 0, 200 },
    palette  = { 0, 63 },
    eye      = { 0, 63 },
    ovStyle  = { 0, 255 },
    opacity  = { 0.0, 1.0 },
}

function Appearance.default(sex)
    sex = (sex == 'female') and 'female' or 'male'

    local faceFeatures = {}
    for i = 1, 20 do faceFeatures[i] = 0.0 end

    local headOverlays = {}
    for i = 1, 12 do
        headOverlays[i] = { style = 0, opacity = 0.0, color = 0, secondColor = 0 }
    end
    -- sprancene vizibile implicit (overlay id 2 -> index 3)
    headOverlays[3] = { style = 0, opacity = 1.0, color = 0, secondColor = 0 }

    return {
        sex          = sex,
        model        = Appearance.MODELS[sex],
        headBlend    = { mother = 0, father = 0, shapeMix = 0.5, skinMix = 0.5 },
        faceFeatures = faceFeatures,
        headOverlays = headOverlays,
        hair         = { style = 0, color = 0, highlight = 0 },
        eyeColor     = 0,
    }
end

local function clamp(v, lo, hi)
    v = tonumber(v)
    if not v then return lo end
    if v < lo then return lo elseif v > hi then return hi end
    return v
end

-- Curata / valideaza un table primit de la client inainte de salvare
function Appearance.sanitize(a)
    if type(a) ~= 'table' then return nil end
    local L = Appearance.LIMITS
    local sex = (a.sex == 'female') and 'female' or 'male'
    local hb = a.headBlend or {}
    local hair = a.hair or {}

    local out = {
        sex   = sex,
        model = Appearance.MODELS[sex],
        headBlend = {
            mother   = math.floor(clamp(hb.mother, L.parent[1], L.parent[2])),
            father   = math.floor(clamp(hb.father, L.parent[1], L.parent[2])),
            shapeMix = clamp(hb.shapeMix, L.mix[1], L.mix[2]),
            skinMix  = clamp(hb.skinMix, L.mix[1], L.mix[2]),
        },
        faceFeatures = {},
        headOverlays = {},
        hair = {
            style     = math.floor(clamp(hair.style, L.hairStyle[1], L.hairStyle[2])),
            color     = math.floor(clamp(hair.color, L.palette[1], L.palette[2])),
            highlight = math.floor(clamp(hair.highlight, L.palette[1], L.palette[2])),
        },
        eyeColor = math.floor(clamp(a.eyeColor, L.eye[1], L.eye[2])),
    }

    local ff = a.faceFeatures or {}
    for i = 1, 20 do
        out.faceFeatures[i] = clamp(ff[i], L.face[1], L.face[2])
    end

    local ov = a.headOverlays or {}
    for i = 1, 12 do
        local o = ov[i] or {}
        out.headOverlays[i] = {
            style       = math.floor(clamp(o.style, L.ovStyle[1], L.ovStyle[2])),
            opacity     = clamp(o.opacity, L.opacity[1], L.opacity[2]),
            color       = math.floor(clamp(o.color, L.palette[1], L.palette[2])),
            secondColor = math.floor(clamp(o.secondColor, L.palette[1], L.palette[2])),
        }
    end

    return out
end
