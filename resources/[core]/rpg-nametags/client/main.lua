-- ===========================================================================
--  rpg-nametags — client
--  Nametag 3D custom, randat prin NUI (div pozitionat din GetScreenCoordFromWorldCoord),
--  la fel ca etichetele din rpg-housing.
--
--  DE CE NU SARE la intrarea in masina:
--    ancora nu e un "MP gamer tag" (care are un offset bugat pe vehicul), ci
--    OSUL CAPULUI ped-ului: GetPedBoneCoords(ped, 0x796E, ...). Osul urmareste
--    exact modelul, pe jos sau asezat in masina -> tag-ul ramane lipit de cap.
--
--  Date (fara sync nou — totul e deja in statebag-uri replicate):
--    Player(sid).state.charId       -> [sql id]        (rpg-characters)
--    Player(sid).state.accountName  -> Username        (rpg-auth)
--    Player(sid).state.staff        -> slug de grad    (rpg-auth)
--    Player(sid).state.noclip       -> ascunde         (rpg-world)
-- ===========================================================================

local HEAD_BONE = 0x796E   -- SKEL_Head

local function headAnchor(ped)
    local h = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0)
    if h.x == 0.0 and h.y == 0.0 and h.z == 0.0 then
        local c = GetEntityCoords(ped)
        h = vector3(c.x, c.y, c.z + 1.0)   -- fallback
    end
    return vector3(h.x, h.y, h.z + Config.HeadOffsetZ)
end

CreateThread(function()
    if not Config.Enabled then return end

    while true do
        local wait = Config.IdleWaitMs
        local myId = PlayerId()
        local myPed = PlayerPedId()
        local myPos = GetEntityCoords(myPed)
        local list = {}

        for _, pi in ipairs(GetActivePlayers()) do
            if pi ~= myId or Config.ShowSelf then
                local ped = GetPlayerPed(pi)
                if ped and ped ~= 0 and DoesEntityExist(ped)
                   and not (Config.HideWhenDead and IsPedDeadOrDying(ped, true)) then

                    local sid = GetPlayerServerId(pi)
                    local st  = Player(sid).state

                    local hidden = (st and st.noclip == true) or GetEntityAlpha(ped) <= 100
                    if not hidden then
                        local anchor = headAnchor(ped)
                        local dist = #(myPos - anchor)

                        if dist <= Config.MaxDistance then
                            -- ACELASI native ca rpg-housing (World3dToScreen2d nu exista aici)
                            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(anchor.x, anchor.y, anchor.z)
                            local visible = onScreen
                            if visible and Config.Occlusion then
                                visible = HasEntityClearLosToEntity(myPed, ped, 17)
                            end

                            if visible then
                                wait = 0

                                local scale = Config.RefDistance / math.max(dist, 0.1)
                                if scale < Config.MinScale then scale = Config.MinScale end
                                if scale > Config.MaxScale then scale = Config.MaxScale end

                                local alpha = 1.0
                                if dist > Config.FadeStart then
                                    alpha = 1.0 - (dist - Config.FadeStart) / (Config.MaxDistance - Config.FadeStart)
                                    if alpha < 0.0 then alpha = 0.0 end
                                end

                                local slug = (st and st.staff) or ''
                                local hasRank = slug ~= '' and Staff.RANKS[slug] ~= nil

                                -- iconuri de subscriptie ACTIVE, in ordinea Legend | Platinum | Gold.
                                -- Langa iconul de staff (daca e staff), altfel in locul lui.
                                local subs = nil
                                local sm = st and st.subs
                                if type(sm) == 'table' then
                                    for _, key in ipairs(Subs.ORDER) do
                                        if sm[key] == true then
                                            local d = Subs.TYPES[key]
                                            if d then
                                                subs = subs or {}
                                                subs[#subs + 1] = { icon = d.icon, color = d.color }
                                            end
                                        end
                                    end
                                end

                                list[#list + 1] = {
                                    id    = sid,
                                    sqlId = (st and st.charId) or '?',
                                    name  = (st and st.accountName) or GetPlayerName(pi) or 'Player',
                                    icon  = hasRank and Staff.iconSvg(slug) or nil,
                                    color = hasRank and Staff.color(slug) or nil,
                                    subs  = subs,
                                    talk  = NetworkIsPlayerTalking(pi) and true or false,  -- difuzor animat deasupra
                                    x     = sx,
                                    y     = sy,
                                    s     = math.floor(scale * 1000) / 1000,
                                    a     = math.floor(alpha * 100) / 100,
                                }
                            end
                        end
                    end
                end
            end
        end

        SendNUIMessage({ action = 'tags', list = list })
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        SendNUIMessage({ action = 'tags', list = {} })
    end
end)
