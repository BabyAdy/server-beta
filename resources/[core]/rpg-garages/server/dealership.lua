-- ===========================================================================
--  rpg-garages — server / dealership (spec §17)
--  Nu exista un dealership in codebase -> il implementam aici, minimal si
--  server-authoritative. Categoriile: Vehicle / Heli / Boat (din Config.Dealers).
--  Cumpararea foloseste EXACT aceeasi cale de creare ca /vcreate: createVehicle.
-- ===========================================================================

local DBG = Config.Debug

-- dealer valid + playerul e langa el?
local function dealerNear(src, dealerIdx)
    local d = Config.Dealers[tonumber(dealerIdx or 0)]
    if not d then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    local c = GetEntityCoords(ped)
    if #(vector3(c.x, c.y, c.z) - d.coords) > Config.Distance.serverGate then return nil end
    return d
end

local function catalogFor(categories)
    local set = {}
    for _, c in ipairs(categories) do set[c] = true end
    local out = {}
    for _, e in ipairs(Config.Catalog) do
        if set[e.type] then
            out[#out + 1] = { model = e.model, name = e.name, type = e.type, price = e.price }
        end
    end
    return out
end

RegisterNetEvent('rpg-garages:requestCatalog', function(dealerIdx)
    local src = source
    local d = dealerNear(src, dealerIdx)
    if not d then return Garages.feedback(src, 'ERROR', 'Nu ești la un dealership.') end
    TriggerClientEvent('rpg-garages:showCatalog', src, {
        dealerIdx  = tonumber(dealerIdx),
        label      = d.label,
        categories = d.categories,
        items      = catalogFor(d.categories),
        payFrom    = Config.PayFrom,
    })
end)

-- ---- economie -------------------------------------------------------------
local function balanceOf(src)
    if Config.PayFrom == 'cash' then
        return tonumber(exports['rpg-level']:getMoney(src)) or 0
    end
    return tonumber(exports['rpg-level']:getBank(src)) or 0
end
local function chargePlayer(src, amount)
    if Config.PayFrom == 'cash' then return exports['rpg-level']:addMoney(src, -amount) end
    return exports['rpg-level']:addBank(src, -amount)
end
local function refundPlayer(src, amount)
    if Config.PayFrom == 'cash' then return exports['rpg-level']:addMoney(src, amount) end
    return exports['rpg-level']:addBank(src, amount)
end

RegisterNetEvent('rpg-garages:buyRequest', function(dealerIdx, model)
    local src = source
    model = tostring(model or ''):lower()

    local d = dealerNear(src, dealerIdx)
    if not d then return Garages.feedback(src, 'ERROR', 'Nu ești la un dealership.') end

    -- entry-ul din catalog e SURSA DE ADEVAR (pret/tip/nume). Clientul trimite doar `model`.
    local entry
    for _, e in ipairs(Config.Catalog) do
        if e.model:lower() == model then entry = e break end
    end
    if not entry then return Garages.feedback(src, 'ERROR', 'Model indisponibil.') end

    -- dealership-ul asta vinde categoria?
    local sells = false
    for _, c in ipairs(d.categories) do if c == entry.type then sells = true break end end
    if not sells then return Garages.feedback(src, 'ERROR', 'Acest dealership nu vinde această categorie.') end

    local uid = Garages.accId(src)
    if not uid then return Garages.feedback(src, 'ERROR', 'Cont neîncărcat.') end

    -- fonduri (verificare + scadere, fara yield intre ele -> efectiv atomic pe tick)
    if balanceOf(src) < entry.price then
        return Garages.feedback(src, 'ERROR', ('Fonduri insuficiente (%s: %d$).')
            :format(Config.PayFrom == 'cash' and 'cash' or 'bancă', entry.price))
    end
    if not chargePlayer(src, entry.price) then
        return Garages.feedback(src, 'ERROR', 'Tranzacție eșuată.')
    end

    local pvId, meta = Garages.createVehicle({
        ownerId     = uid,
        model       = entry.model,
        displayName = entry.name,
        type        = entry.type,
        fuel        = Config.DefaultFuel,
        status      = Config.DefaultStatus,
    })
    if not pvId then
        refundPlayer(src, entry.price)   -- rollback
        return Garages.feedback(src, 'ERROR', ('Eroare la creare (%s). Ai fost rambursat.'):format(meta or '?'))
    end

    Garages.feedback(src, 'SUCCESS', ('Ai cumpărat %s pentru %d$. E în garage-ul %s (placa %s).')
        :format(entry.name, entry.price, entry.type, meta.plate))
    TriggerClientEvent('rpg-garages:bought', src, { pvId = pvId, name = entry.name, type = entry.type })

    if DBG then print(('[rpg-garages] BUY: uid#%d %s -%d$ -> pv#%d'):format(uid, entry.model, entry.price, pvId)) end
end)
