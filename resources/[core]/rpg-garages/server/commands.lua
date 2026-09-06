-- ===========================================================================
--  rpg-garages — server / commands  (spec §9)
--  Permisiuni: sistemul EXISTENT (rpg-auth) — hasStaffLevel(src, Config.StaffRank).
--  Nimic hardcodat: rank-ul minim vine din Config.StaffRank ('manager').
-- ===========================================================================

local function deny(src) Garages.feedback(src, 'ERROR', 'Nu ai acces la această comandă.') end

-- ---------------------------------------------------------------------------
--  /vcreate [users.id] [model_name] [type?]
--    type? optional: Vehicle | Heli | Boat  (altfel dedus din model/catalog)
--  Foloseste EXACT createVehicle (aceeasi cale ca dealership-ul).
-- ---------------------------------------------------------------------------
RegisterCommand('vcreate', function(src, args)
    if not Garages.canStaff(src) then return deny(src) end

    local uid   = tonumber(args[1])
    local model = tostring(args[2] or ''):lower()
    local vtype = args[3] and tostring(args[3]) or nil
    if not uid or model == '' then
        return Garages.feedback(src, 'ERROR', 'Folosire: /vcreate [users.id] [model_name] [Vehicle|Heli|Boat]')
    end
    if vtype and not Utils.isValidGarageType(vtype) then
        return Garages.feedback(src, 'ERROR', 'Tip invalid. Valide: Vehicle, Heli, Boat')
    end

    local username = Garages.usernameOf(uid)
    if not username then return Garages.feedback(src, 'ERROR', ('users.id %d inexistent.'):format(uid)) end

    local pvId, meta = Garages.createVehicle({
        ownerId = uid, ownerName = username, model = model, type = vtype,
        fuel = Config.DefaultFuel, status = Config.DefaultStatus,
    })
    if not pvId then return Garages.feedback(src, 'ERROR', ('Eroare: %s'):format(meta or '?')) end

    local giverName, giverLabel = Garages.cmdIssuer(src)
    Garages.feedback(src, 'SUCCESS', ('Vehicul %s (%s) creat pentru %s [%d] — pv#%d, placa %s. E în garage.')
        :format(model, meta.type, username, uid, pvId, meta.plate))

    local osrc = Garages.srcOfAccount(uid)
    if osrc then
        Garages.feedback(osrc, 'INFO', ('Ai primit un vehicul personal: %s. Îl găsești într-un garage %s.')
            :format(meta.displayName, meta.type))
    end
    Garages.staffBroadcast(('Staff: %s %s created vehicle %s (#%d) for %s [%d].')
        :format(giverLabel, giverName, model, pvId, username, uid))
end, false)

-- ---------------------------------------------------------------------------
--  /vdelete [vehicle id]
-- ---------------------------------------------------------------------------
RegisterCommand('vdelete', function(src, args)
    if not Garages.canStaff(src) then return deny(src) end

    local pvId = tonumber(args[1])
    if not pvId then return Garages.feedback(src, 'ERROR', 'Folosire: /vdelete [vehicle id]') end

    local ok, rowOrErr = Garages.deleteVehicle(pvId)
    if not ok then return Garages.feedback(src, 'ERROR', rowOrErr) end

    local giverName, giverLabel = Garages.cmdIssuer(src)
    Garages.feedback(src, 'SUCCESS', ('Vehicul %s (pv#%d) al lui %s [%s] șters (+ tuning).')
        :format(rowOrErr.model_name, pvId, rowOrErr.owner_name or '?', tostring(rowOrErr.owner_id)))
    Garages.staffBroadcast(('Staff: %s %s deleted vehicle %s (#%d) of %s [%s].')
        :format(giverLabel, giverName, rowOrErr.model_name, pvId, rowOrErr.owner_name or '?', tostring(rowOrErr.owner_id)))
end, false)

-- ---------------------------------------------------------------------------
--  /creategarage [Vehicle|Heli|Boat]  — la pozitia staff-ului
-- ---------------------------------------------------------------------------
RegisterCommand('creategarage', function(src, args)
    if not Garages.canStaff(src) then return deny(src) end

    local gtype = args[1] and tostring(args[1]) or ''
    local id, err = Garages.createGarage(src, gtype)
    if not id then return Garages.feedback(src, 'ERROR', err) end

    local giverName, giverLabel = Garages.cmdIssuer(src)
    Garages.feedback(src, 'SUCCESS', ('Garage #%d (%s) creat la poziția ta. Blip/marker vizibile imediat.'):format(id, gtype))
    Garages.staffBroadcast(('Staff: %s %s created garage #%d (%s).'):format(giverLabel, giverName, id, gtype))
end, false)

-- ---------------------------------------------------------------------------
--  /deletegarage [garage id]
-- ---------------------------------------------------------------------------
RegisterCommand('deletegarage', function(src, args)
    if not Garages.canStaff(src) then return deny(src) end

    local id = tonumber(args[1])
    if not id then return Garages.feedback(src, 'ERROR', 'Folosire: /deletegarage [garage id]') end

    local ok, err = Garages.removeGarage(id)
    if not ok then return Garages.feedback(src, 'ERROR', err) end

    local giverName, giverLabel = Garages.cmdIssuer(src)
    Garages.feedback(src, 'SUCCESS', ('Garage #%d șters. Blip/marker eliminate imediat.'):format(id))
    Garages.staffBroadcast(('Staff: %s %s deleted garage #%d.'):format(giverLabel, giverName, id))
end, false)
