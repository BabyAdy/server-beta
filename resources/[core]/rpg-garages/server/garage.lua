-- ===========================================================================
--  rpg-garages — server / garage
--  Cache `rpg_garages` + sync catre client (blip/marker/prompt fara restart).
-- ===========================================================================

function Garages.countGarages()
    local n = 0
    for _ in pairs(Garages.garages) do n = n + 1 end
    return n
end

local function shape(row)
    return {
        id   = tonumber(row.id),
        type = row.type,
        x    = row.x + 0.0,
        y    = row.y + 0.0,
        z    = row.z + 0.0,
        h    = (row.h or 0.0) + 0.0,
        faction = Config.FactionGarages[tonumber(row.id)] or '',
    }
end

function Garages.loadGarages()
    local rows = MySQL.query.await('SELECT id, type, x, y, z, h FROM rpg_garages') or {}
    Garages.garages = {}
    for _, r in ipairs(rows) do Garages.garages[tonumber(r.id)] = shape(r) end
end

-- lista trimisa clientului (fara `faction` — clientul nu are nevoie de logica de facțiune)
local function clientList()
    local out = {}
    for _, g in pairs(Garages.garages) do
        out[#out + 1] = { id = g.id, type = g.type, x = g.x, y = g.y, z = g.z, h = g.h }
    end
    return out
end

function Garages.syncAll(target)
    TriggerClientEvent('rpg-garages:syncGarages', target or -1, clientList())
end

-- ---- creare (comanda /creategarage) ----------------------------------
function Garages.createGarage(src, gtype)
    if not Utils.isValidGarageType(gtype) then
        return nil, ('Tip invalid. Valide: %s'):format('Vehicle, Heli, Boat')
    end
    if src <= 0 then return nil, 'Comanda necesita un player (foloseste pozitia lui).' end

    local ped = GetPlayerPed(src)
    local c   = GetEntityCoords(ped)
    local h   = GetEntityHeading(ped)

    local id = MySQL.insert.await([[
        INSERT INTO rpg_garages (type, x, y, z, h, created_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { gtype, c.x + 0.0, c.y + 0.0, c.z + 0.0, h + 0.0, Garages.accId(src) })
    if not id then return nil, 'Eroare la salvare.' end

    Garages.garages[id] = shape({ id = id, type = gtype, x = c.x, y = c.y, z = c.z, h = h })
    Garages.syncAll(-1)   -- toti clientii primesc noul garage -> blip/marker/prompt fara restart
    return id
end

-- ---- stergere (comanda /deletegarage) -------------------------------
function Garages.removeGarage(id)
    id = tonumber(id)
    if not id or not Garages.garages[id] then return false, ('Garage #%s inexistent.'):format(tostring(id)) end
    MySQL.update.await('DELETE FROM rpg_garages WHERE id = ?', { id })
    -- vehiculele parcate acolo raman valide (garage_id devine referinta moarta -> le mutam pe NULL)
    MySQL.update.await('UPDATE personal_vehicle SET garage_id = NULL WHERE garage_id = ?', { id })
    Garages.garages[id] = nil
    Garages.syncAll(-1)   -- clientii elimina blip/marker/prompt fara restart
    return true
end
