-- ===========================================================================
--  Validari pure (fara stare). Toate mutatiile trec prin astea inainte de a
--  atinge cache-ul sau DB-ul. Clientul NU e niciodata autoritate.
-- ===========================================================================

Validation = {}

function Validation.isNumber(v)
    return type(v) == 'number' and v == v and v ~= math.huge and v ~= -math.huge
end

function Validation.gridSlot(s)
    s = tonumber(s)
    return s ~= nil and math.floor(s) == s and s >= 1 and s <= Config.GridSlots
end

function Validation.isEquipKey(s)
    if type(s) ~= 'string' then return false end
    for _, e in ipairs(Config.EquipmentSlots) do
        if e.key == s then return true end
    end
    return false
end

function Validation.equipSlotDef(key)
    for _, e in ipairs(Config.EquipmentSlots) do
        if e.key == key then return e end
    end
    return nil
end

-- clasifica un identificator de slot: 'grid' + numar | 'equip' + cheie | nil
function Validation.classifySlot(s)
    if Validation.gridSlot(s) then return 'grid', tonumber(s) end
    if Validation.isEquipKey(s) then return 'equip', s end
    return nil
end

-- itemul (definitia) poate intra in slotul de echipament dat?
function Validation.canEquip(slotKey, def)
    if not def then return false end
    local e = Validation.equipSlotDef(slotKey)
    if not e then return false end
    if def.equipSlot ~= slotKey then return false end
    for _, cat in ipairs(e.accept) do
        if cat == def.category then return true end
    end
    return false
end

function Validation.quantity(q, max)
    q = tonumber(q)
    if not q or math.floor(q) ~= q or q < 1 then return nil end
    if max and q > max then return nil end
    return q
end

function Validation.distance(a, b, max)
    if not a or not b then return false end
    local dx, dy, dz = (a.x - b.x), (a.y - b.y), (a.z - b.z)
    return (dx * dx + dy * dy + dz * dz) <= (max * max)
end

-- doua instante ale aceluiasi item pot fi contopite intr-un stack?
function Validation.stackCompatible(def, a, b)
    if not def or not def.stackable then return false end
    -- iteme cu metadata "unica" (durabilitate, munitie, serial, telefon) nu se
    -- contopesc; consumabilele simple da.
    local function unique(md)
        if not md then return false end
        return md.durability ~= nil or md.ammo ~= nil or md.phoneNumber ~= nil
            or md.serial ~= nil or md.component ~= nil
    end
    return not unique(a.metadata) and not unique(b.metadata)
end
