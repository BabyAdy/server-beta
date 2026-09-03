-- ===========================================================================
--  Registru de containere (in memorie).
--  Tipuri active: 'char', 'ground'. Pregatit pentru: 'stash', 'trunk',
--  'glovebox', 'business', 'faction'.
--
--  container = {
--     id, type, ownerId,
--     maxWeight (nil = nelimitat),
--     slots,
--     pos = { x, y, z } | nil,
--     items = { [rowId] = { id, itemId, slot, quantity, metadata } },
--     fastSlots = { [1..5] = gridSlot | false },   -- doar 'char'
--     dirty = bool,
--  }
-- ===========================================================================

Containers = {}

local registry = {}

function Containers.key(ctype, ownerId)
    return ('%s:%s'):format(ctype, tostring(ownerId))
end

function Containers.get(id)
    return registry[id]
end

function Containers.all()
    return registry
end

function Containers.register(c)
    registry[c.id] = c
    return c
end

function Containers.unregister(id)
    registry[id] = nil
end

function Containers.character(charId)
    return registry[Containers.key('char', charId)]
end

-- ---- acces --------------------------------------------------------------
-- src poate atinge containerul? (ownership pentru 'char', distanta pentru rest)
function Containers.canAccess(src, container, playerPos)
    if not container then return false end

    if container.type == 'char' then
        local ok, ch = pcall(function()
            return exports['rpg-characters']:getCharacter(src)
        end)
        return ok and ch ~= nil and ch.id == container.ownerId
    end

    -- ground / stash / trunk / ... -> validare de proximitate
    if container.pos and playerPos then
        return Validation.distance(container.pos, playerPos, Config.ContainerAccessRadius)
    end
    return false
end

-- toate containerele 'ground' din raza data fata de o pozitie
function Containers.groundNear(pos, radius)
    local out = {}
    radius = radius or Config.DropRadius
    for _, c in pairs(registry) do
        if c.type == 'ground' and c.pos and Validation.distance(c.pos, pos, radius) then
            out[#out + 1] = c
        end
    end
    return out
end

function Containers.isEmpty(container)
    return next(container.items) == nil
end
