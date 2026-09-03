-- ===========================================================================
--  Registru de definitii de iteme (static) — separat de instantele din inventar.
--
--  ItemDefinition (aici)          InventoryItem (in DB / runtime)
--  { id, label, category, ... }   { rowId, itemId, slot, quantity, metadata }
--
--  Alte resurse adauga iteme prin:
--     exports['rpg-inventory']:RegisterItem({ id = '...', ... })
--  si carlige de folosire prin:
--     exports['rpg-inventory']:RegisterUsable('bandage', function(src, charId, item) ... end)
-- ===========================================================================

Items = {}
Items.defs = {}

-- context implicit per categorie (poate fi suprascris cu def.context)
local CATEGORY_CONTEXT = {
    consumable = { 'use', 'drop', 'give', 'inspect' },
    weapon     = { 'equip', 'drop', 'give', 'inspect' },
    clothing   = { 'equip', 'drop', 'give', 'inspect' },
    armor      = { 'equip', 'drop', 'give', 'inspect' },
    misc       = { 'use', 'drop', 'give', 'inspect' },
}

function Items.register(def)
    assert(type(def) == 'table' and def.id, 'RegisterItem: lipseste id')

    def.label     = def.label or def.id
    def.category  = def.category or 'misc'
    def.weight    = tonumber(def.weight) or 0.1          -- kg
    def.maxStack  = tonumber(def.maxStack) or 1
    def.stackable = def.maxStack > 1
    def.usable    = def.usable == true
    def.value     = tonumber(def.value) or 0
    def.icon      = def.icon or (def.id .. '.png')
    def.stats     = def.stats or {}

    -- durabilitate: contor intreg x/y, -1 la fiecare folosire / glont tras
    def.durable       = def.durable == true
    def.maxDurability = def.durable and (tonumber(def.maxDurability) or 100) or nil

    -- echipabil in unul din Config.EquipmentSlots (clothing/armor) -> def.equipSlot
    -- armele se "echipeaza" separat (in mana), nu intr-un slot din grid
    def.equipSlot = def.equipSlot
    def.equipable = def.equipable == true
        or def.category == 'weapon'
        or def.equipSlot ~= nil

    -- sablon de metadata aplicat la crearea unei instante noi (ex. clothing)
    def.metadataTemplate = def.metadataTemplate or def.metadata_template

    if not def.context then
        def.context = CATEGORY_CONTEXT[def.category] or CATEGORY_CONTEXT.misc
    end

    Items.defs[def.id] = def
    return def
end

function Items.get(id)
    return Items.defs[id]
end

-- lista de actiuni pentru context menu, in functie de item + instanta
function Items.contextFor(itemId, item)
    local d = Items.defs[itemId]
    if not d then return { 'inspect', 'drop' } end

    local list = {}
    for _, a in ipairs(d.context) do list[#list + 1] = a end

    -- SPLIT doar daca e stackabil si avem > 1 bucata
    if d.stackable and item and (item.quantity or 1) > 1 then
        local hasSplit = false
        for _, a in ipairs(list) do if a == 'split' then hasSplit = true end end
        if not hasSplit then table.insert(list, math.min(2, #list + 1), 'split') end
    end

    -- EQUIP <-> UNEQUIP dupa starea instantei
    if item and item.metadata and item.metadata.equipped then
        for i, a in ipairs(list) do if a == 'equip' then list[i] = 'unequip' end end
    end

    return list
end

-- metadata initiala pentru o instanta noua a itemului
function Items.freshMetadata(itemId, extra)
    local d = Items.defs[itemId]
    local md = {}
    if d then
        if d.durable then md.durability = d.maxDurability end
        if d.metadataTemplate then
            for k, v in pairs(d.metadataTemplate) do md[k] = v end
        end
    end
    if extra then
        for k, v in pairs(extra) do md[k] = v end
    end
    return md
end

-- ===========================================================================
--  SET DE BAZA (demo / test). Extinde din alte resurse cu RegisterItem.
-- ===========================================================================
Items.register{ id = 'water',        label = 'Sticlă cu apă', category = 'consumable', weight = 0.50, maxStack = 24, usable = true, value = 5 }
Items.register{ id = 'bread',        label = 'Baton',         category = 'consumable', weight = 0.40, maxStack = 16, usable = true, value = 6 }
Items.register{ id = 'bandage',      label = 'Bandaj',        category = 'consumable', weight = 0.20, maxStack = 20, usable = true, value = 15 }
Items.register{ id = 'medkit',       label = 'Trusă medicală',category = 'consumable', weight = 1.20, maxStack = 5,  usable = true, value = 120 }

Items.register{ id = 'phone',        label = 'Telefon',       category = 'misc', weight = 0.30, maxStack = 1, usable = true, value = 400,
                metadataTemplate = { phoneNumber = nil } }
Items.register{ id = 'lockpick',     label = 'Șperaclu',      category = 'misc', weight = 0.30, maxStack = 5, usable = true, value = 40,  durable = true, maxDurability = 12 }
Items.register{ id = 'repairkit',    label = 'Set reparații', category = 'misc', weight = 2.00, maxStack = 3, usable = true, value = 150, durable = true, maxDurability = 6 }
Items.register{ id = 'radio',        label = 'Stație radio',  category = 'misc', weight = 0.60, maxStack = 1, usable = true, value = 200 }

Items.register{ id = 'weapon_pistol',label = 'Pistol compact',category = 'weapon', weight = 1.10, maxStack = 1, value = 1200,
                durable = true, maxDurability = 40, stats = { damage = 32, caliber = '9mm' } }
Items.register{ id = 'ammo_pistol',  label = 'Cartușe 9mm',   category = 'misc',   weight = 0.02, maxStack = 250, value = 2 }

Items.register{ id = 'armor_plate',  label = 'Vestă antiglonț', category = 'armor', weight = 3.50, maxStack = 1, value = 800,
                equipSlot = 'armor', equipable = true, durable = true, maxDurability = 100 }

Items.register{ id = 'tshirt',       label = 'Tricou simplu',  category = 'clothing', weight = 0.40, maxStack = 1, value = 45,
                equipSlot = 'shirt', equipable = true, metadataTemplate = { component = 11, drawable = 0, texture = 0 } }
Items.register{ id = 'cap',          label = 'Șapcă',          category = 'clothing', weight = 0.20, maxStack = 1, value = 35,
                equipSlot = 'hat',  equipable = true, metadataTemplate = { prop = 0, drawable = 0, texture = 0 } }
Items.register{ id = 'jeans',        label = 'Blugi',          category = 'clothing', weight = 0.60, maxStack = 1, value = 55,
                equipSlot = 'pants', equipable = true, metadataTemplate = { component = 4, drawable = 0, texture = 0 } }
Items.register{ id = 'sneakers',     label = 'Adidași',        category = 'clothing', weight = 0.70, maxStack = 1, value = 60,
                equipSlot = 'shoes', equipable = true, metadataTemplate = { component = 6, drawable = 0, texture = 0 } }
