-- ===========================================================================
--  rpg-factions — NUI BRIDGE (client)
--  NUI callback -> event server.  Event server (date) -> SendNUIMessage.
--  NU expune actiuni administrative "din scurt" — fiecare callback declanseaza
--  DOAR un event server, care re-valideaza totul.
-- ===========================================================================

local function fwd(name, ...)   -- helper: trimite un event server + args
    local a = { ... }
    return function() TriggerServerEvent(name, table.unpack(a)) end
end

RegisterNUICallback('close', function(_, cb) FX.closeMenu() cb('ok') end)

-- meniuri / liste
RegisterNUICallback('members',      function(_, cb) TriggerServerEvent('rpg-factions:listMembers') cb('ok') end)
RegisterNUICallback('applications', function(_, cb) TriggerServerEvent('rpg-factions:listApplications') cb('ok') end)
RegisterNUICallback('logs',         function(d, cb) TriggerServerEvent('rpg-factions:listLogs', tonumber(d and d.page) or 1) cb('ok') end)
RegisterNUICallback('browse',       function(_, cb) TriggerServerEvent('rpg-factions:browseFactions') cb('ok') end)
RegisterNUICallback('myApplications', function(_, cb) TriggerServerEvent('rpg-factions:myApplications') cb('ok') end)

-- actiuni membru (target = users.id)
RegisterNUICallback('kick',    function(d, cb) TriggerServerEvent('rpg-factions:kick',    tonumber(d.userId), tostring(d.reason or '')) cb('ok') end)
RegisterNUICallback('promote', function(d, cb) TriggerServerEvent('rpg-factions:promote', tonumber(d.userId), tostring(d.reason or '')) cb('ok') end)
RegisterNUICallback('demote',  function(d, cb) TriggerServerEvent('rpg-factions:demote',  tonumber(d.userId), tostring(d.reason or '')) cb('ok') end)
RegisterNUICallback('warning', function(d, cb) TriggerServerEvent('rpg-factions:warning', tonumber(d.userId), tonumber(d.delta) or 0, tostring(d.reason or '')) cb('ok') end)
RegisterNUICallback('supervisor', function(d, cb) TriggerServerEvent('rpg-factions:setSupervisor', tonumber(d.userId), d.value == true) cb('ok') end)
RegisterNUICallback('tester',     function(d, cb) TriggerServerEvent('rpg-factions:setTester',     tonumber(d.userId), d.value == true) cb('ok') end)
RegisterNUICallback('permissions', function(d, cb) TriggerServerEvent('rpg-factions:setPermissions', tonumber(d.userId), d.perms or {}) cb('ok') end)
RegisterNUICallback('setLeader',  function(d, cb) TriggerServerEvent('rpg-factions:setLeader',  tonumber(d.userId)) cb('ok') end)
RegisterNUICallback('setManager', function(d, cb) TriggerServerEvent('rpg-factions:setManager', tonumber(d.userId) or 0) cb('ok') end)

-- invite (target = server id al playerului cel mai apropiat / ales)
RegisterNUICallback('invitePlayer', function(d, cb)
    local id = tonumber(d and d.serverId)
    if not id then
        -- fara id -> invita playerul din fata (cel mai apropiat, < 3m)
        id = FX.nearestPlayerServerId and FX.nearestPlayerServerId(3.0) or nil
    end
    if id then TriggerServerEvent('rpg-factions:invite', id) end
    cb('ok')
end)

-- settings / ranks / hq
RegisterNUICallback('updateSettings', function(d, cb) TriggerServerEvent('rpg-factions:updateSettings', d or {}) cb('ok') end)
RegisterNUICallback('updateRank', function(d, cb) TriggerServerEvent('rpg-factions:updateRank', tonumber(d.order), d.changes or {}) cb('ok') end)
RegisterNUICallback('setHQ', function(d, cb) TriggerServerEvent('rpg-factions:setHQ', d or {}) cb('ok') end)

-- applications
RegisterNUICallback('apply',  function(d, cb) TriggerServerEvent('rpg-factions:apply', tonumber(d.factionId), tostring(d.message or '')) cb('ok') end)
RegisterNUICallback('cancelApplication', function(d, cb) TriggerServerEvent('rpg-factions:cancelApplication', tonumber(d.id)) cb('ok') end)
RegisterNUICallback('acceptApplication', function(d, cb) TriggerServerEvent('rpg-factions:acceptApplication', tonumber(d.id)) cb('ok') end)
RegisterNUICallback('rejectApplication', function(d, cb) TriggerServerEvent('rpg-factions:rejectApplication', tonumber(d.id), tostring(d.reason or '')) cb('ok') end)

-- leave
RegisterNUICallback('leaveFaction', function(_, cb) TriggerServerEvent('rpg-factions:leave') cb('ok') end)

-- ---- Faction Creator (admin) --------------------------------
RegisterNUICallback('creatorCapture', function(d, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    SendNUIMessage({
        action = 'creatorCaptured',
        which  = d and d.which,
        coords = { x = c.x, y = c.y, z = c.z, h = GetEntityHeading(ped) },
    })
    cb('ok')
end)
RegisterNUICallback('creatorSubmit', function(d, cb)
    TriggerServerEvent('rpg-factions:adminCreate', d or {})
    FX.closeCreator()
    cb('ok')
end)
RegisterNUICallback('creatorClose', function(_, cb)
    FX.closeCreator()
    cb('ok')
end)

-- HQ din meniu (buton)
RegisterNUICallback('hqEnter', function(_, cb) FX.closeMenu() TriggerServerEvent('rpg-factions:hqEnter') cb('ok') end)

-- invite popup accept/decline
RegisterNUICallback('inviteResponse', function(d, cb)
    local acc = d and d.accept == true
    if acc and FX.pendingInvite then TriggerServerEvent('rpg-factions:acceptInvite', FX.pendingInvite.fid) end
    FX.pendingInvite = nil
    if FX.menuOpen == 'invite' then FX.menuOpen = false; FX.setFocus(false) end
    SendNUIMessage({ action = 'invite', data = nil })
    cb('ok')
end)

-- ---- server data -> NUI --------------------------------------
RegisterNetEvent('rpg-factions:membersData',      function(d) SendNUIMessage({ action = 'membersData', data = d }) end)
RegisterNetEvent('rpg-factions:applicationsData', function(d) SendNUIMessage({ action = 'applicationsData', data = d }) end)
RegisterNetEvent('rpg-factions:logsData',         function(d) SendNUIMessage({ action = 'logsData', data = d }) end)
RegisterNetEvent('rpg-factions:factionsList',     function(d) SendNUIMessage({ action = 'factionsList', data = d }) end)
RegisterNetEvent('rpg-factions:myApplications',   function(d) SendNUIMessage({ action = 'myApplications', data = d }) end)
