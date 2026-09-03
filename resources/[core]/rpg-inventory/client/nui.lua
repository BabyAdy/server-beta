-- ===========================================================================
--  rpg-inventory — puntea NUI <-> client <-> server.
--  NUI cere; clientul retransmite catre server; serverul e autoritatea.
--  NUI nu atinge niciodata DB-ul.
-- ===========================================================================

local pending = {}
local seq = 0

-- request(action, payload[, cb]) — cb(result) optional
function Inv.request(action, payload, cb)
    seq = seq + 1
    local id = ('c%d'):format(seq)
    if cb then pending[id] = cb end
    TriggerServerEvent('rpg-inventory:request', action, id, payload or {})
    return id
end

RegisterNetEvent('rpg-inventory:result', function(reqId, res)
    local cb = pending[reqId]
    if cb then
        pending[reqId] = nil
        cb(res)
    end
end)

-- ----- callbacks NUI ----------------------------------------------
-- actiune generica: NUI trimite {action, payload}; primeste inapoi rezultatul
RegisterNUICallback('request', function(data, cb)
    Inv.request(data.action, data.payload, function(res)
        cb(res or { ok = false })
    end)
end)

RegisterNUICallback('close', function(_, cb)
    Inv.closeUI()
    cb('ok')
end)

-- rotire ped in preview
RegisterNUICallback('rotate', function(data, cb)
    local ped = PlayerPedId()
    local delta = tonumber(data.delta) or 0.0
    SetEntityHeading(ped, (GetEntityHeading(ped) + delta) % 360.0)
    -- reasaza camera pe noua orientare
    if Inv.cam then
        DestroyCam(Inv.cam, false)
        Inv.cam = nil
    end
    -- recreeaza cu acelasi helper
    local coords = GetEntityCoords(ped)
    local rad = math.rad(GetEntityHeading(ped))
    local fwdX, fwdY = -math.sin(rad), math.cos(rad)
    local rightX, rightY = math.cos(rad), math.sin(rad)
    local p = Config.Preview
    Inv.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA',
        coords.x + fwdX * p.forward + rightX * p.side,
        coords.y + fwdY * p.forward + rightY * p.side,
        coords.z + p.height, 0.0, 0.0, 0.0, p.fov, false, 0)
    PointCamAtCoord(Inv.cam, coords.x + rightX * (p.side * 1.2), coords.y + rightY * (p.side * 1.2), coords.z + p.height)
    SetCamActive(Inv.cam, true)
    RenderScriptCams(true, false, 0, true, false)
    cb('ok')
end)

-- lista jucatorilor din raza pentru "GIVE"
RegisterNUICallback('nearbyPlayers', function(_, cb)
    local ped = PlayerPedId()
    local myCoords = GetEntityCoords(ped)
    local out = {}
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local tPed = GetPlayerPed(pid)
            if #(myCoords - GetEntityCoords(tPed)) <= (Config.GiveRadius + 0.5) then
                local sid = GetPlayerServerId(pid)
                out[#out + 1] = {
                    serverId = sid,                                  -- necesar intern pentru RPC
                    sqlId = Player(sid).state.charId,                -- SQL id (afisat)
                    name = GetPlayerName(pid),
                }
            end
        end
    end
    cb(out)
end)
