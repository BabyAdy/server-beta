-- ===========================================================================
--  rpg-factions — SECURITY GATE  (server)
--  Sec.gate{...} = poarta prin care trece FIECARE mutatie. Face verificarile
--  §25 (actor exista / in facțiune / permisiune / target valid / ierarhie) +
--  rate-limit §26, si logheaza tentativele respinse (INVALID_*).
-- ===========================================================================

Sec = {}

local lastEvent = {}   -- [src] = { [event] = tick }

function Sec.rate(src, event)
    local now = GetGameTimer()
    local t = lastEvent[src]; if not t then t = {}; lastEvent[src] = t end
    if now - (t[event] or 0) < Config.Security.eventCooldownMs then return false end
    t[event] = now
    return true
end

-- opts:
--   src            (obligatoriu)
--   event          (nume, pt. log + rate-limit)
--   needPerm       string | { string, ... }  (macar UNA trebuie sa fie true)
--   targetUserId   users.id tinta (optional) -> intoarce targetCtx
--   allowSelf      = true  ca sa permiti target == actor
--   needOutrank    = false ca sa NU ceri ierarhie (default: cere)
-- return: actorCtx, targetCtx   SAU   nil (deja logat + notificat)
function Sec.gate(opts)
    local src = opts.src
    if not src or src <= 0 then return nil end
    if not Sec.rate(src, opts.event or 'x') then return nil end

    local actorUid = Framework.GetUserId(src)
    if not actorUid then Logs.suspect(src, 'INVALID_REQUEST', 'no_uid'); return nil end

    local actorCtx = Perms.contextOf(actorUid)
    if not actorCtx then
        Logs.suspect(src, 'INVALID_FACTION', 'actor_not_in_faction')
        Framework.Notify(src, 'You are not in a faction.', 'error')
        return nil
    end

    if opts.needPerm then
        local list = type(opts.needPerm) == 'table' and opts.needPerm or { opts.needPerm }
        local okAny = false
        for _, p in ipairs(list) do if Perms.has(actorCtx, p) then okAny = true; break end end
        if not okAny then
            Logs.suspect(src, 'INVALID_PERMISSION', (opts.event or '?') .. ' <' .. table.concat(list, '/') .. '>', actorCtx.fid)
            Framework.Notify(src, 'You do not have permission.', 'error')
            return nil
        end
    end

    local targetCtx = nil
    if opts.targetUserId ~= nil then
        local tuid = tonumber(opts.targetUserId)
        if not tuid then
            Logs.suspect(src, 'INVALID_TARGET', 'bad_id', actorCtx.fid)
            return nil
        end
        if tuid == actorUid and opts.allowSelf ~= true then
            Logs.suspect(src, 'INVALID_TARGET', 'self', actorCtx.fid, tuid)
            Framework.Notify(src, 'You cannot do this to yourself.', 'error')
            return nil
        end
        targetCtx = Perms.contextOf(tuid)
        if not targetCtx or targetCtx.fid ~= actorCtx.fid then
            Logs.suspect(src, 'INVALID_TARGET', 'not_same_faction', actorCtx.fid, tuid)
            Framework.Notify(src, 'Target is not in your faction.', 'error')
            return nil
        end
        if opts.needOutrank ~= false and not Perms.canActOn(actorCtx, tuid, targetCtx.rankOrder) then
            Logs.suspect(src, 'INVALID_RANK', 'cannot_outrank', actorCtx.fid, tuid)
            Framework.Notify(src, 'You cannot act on that member.', 'error')
            return nil
        end
    end

    return actorCtx, targetCtx
end

function Sec.cleanup(src)
    lastEvent[src] = nil
end
