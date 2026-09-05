Config = {}

-- ===========================================================================
--  DESCHIDERE
-- ===========================================================================
-- Comanda (mereu disponibila: /inventory). Framework-ul de keybinds o poate
-- lega la orice tasta ulterior prin RegisterKeyMapping.
Config.OpenCommand = 'inventory'

-- Singura definitie a tastei implicite in tot proiectul. '' = nelegata.
-- (Jucatorul o poate rebinda oricum din Settings > Key Bindings > FiveM.)
Config.DefaultKey = 'I'

-- Taste slot rapid (1..5). Active DOAR cand inventarul e inchis.
Config.FastSlotKeys = { '1', '2', '3', '4', '5' }
Config.FastSlotCount = 5

-- ===========================================================================
--  GRID / CAPACITATE
--  Capacitatea e pe SLOTURI, nu pe greutate. Indicatorul din UI e "X / N".
-- ===========================================================================
Config.Grid = { columns = 5 }             -- coloane in UI (grid-ul are scroll)
Config.GridSlots = 100                    -- capacitate implicita per personaj (sloturi)

Config.Nearby = { columns = 5, rows = 4 }
Config.NearbySlots = Config.Nearby.columns * Config.Nearby.rows

-- ===========================================================================
--  CONTAINERE / DROP
-- ===========================================================================
Config.DropRadius            = 2.0   -- m: raza in care vezi loot-ul de pe jos
Config.ContainerAccessRadius = 2.5   -- m: raza de acces la stash/portbagaj/etc.
Config.GroundMergeRadius     = 0.8   -- m: drop-uri mai apropiate se contopesc
Config.GiveRadius            = 2.5   -- m: raza pentru "GIVE"

-- Confirmare la aruncare daca itemul e "valoros"
Config.DropConfirm = {
    minValue   = 500,                 -- def.value >= => confirmare
    categories = { weapon = true },   -- sau categoria e in lista
}

-- ===========================================================================
--  ECHIPAMENT  (pregatit pentru clothing system-ul de mai tarziu)
--  key      = identificatorul slotului
--  accept   = ce categorii de iteme accepta slotul
--  component/prop = referinta GTA (folosita de clothing system ulterior)
-- ===========================================================================
Config.EquipmentSlots = {
    { key = 'hat',     label = 'Pălărie',    accept = { 'clothing' }, prop = 0 },
    { key = 'mask',    label = 'Mască',      accept = { 'clothing' }, component = 1 },
    { key = 'glasses', label = 'Ochelari',   accept = { 'clothing' }, prop = 1 },
    { key = 'shirt',   label = 'Tricou',     accept = { 'clothing' }, component = 11 },
    { key = 'armor',   label = 'Vestă',      accept = { 'armor' },    component = 9 },
    { key = 'pants',   label = 'Pantaloni',  accept = { 'clothing' }, component = 4 },
    { key = 'shoes',   label = 'Încălț.',    accept = { 'clothing' }, component = 6 },
}

-- client/clothing.lua aplica pe ped componenta/prop-ul din EquipmentSlots la
-- echiparea unui item de tip clothing. Slotul 'armor' e ignorat (n-are model addon).
Config.ClothingApply = {
    ignoreSlots      = { armor = true },
    reassertInterval = 4000,   -- ms: re-aplica periodic (protectie la respawn/alte scripturi)
}

-- ===========================================================================
--  GARDEROBA STAFF — drawable/texture addon per gen, pe id de item.
--  Componenta vine din EquipmentSlots dupa equipSlot-ul itemului
--  (mask_* -> comp 1, shirt_*/jacket_* -> comp 11).
--  Fisierele addon trebuie streamuite separat (resources/[clothing]/...):
--    mp_m_freemode_01^jbib_<idx>_u.ydd  +  ^jbib_diff_<idx>_<a|b|...>_uni.ytd
--    mp_f_freemode_01^jbib_<idx>_u.ydd  +  ...
--  <idx> de mai jos = indexul REAL din joc dupa streaming
--  (in joc: GetNumberOfPedDrawableVariations(ped, 11) - ale tale sunt ultimele).
-- ===========================================================================
Config.StaffClothingModels = {
    -- OWNER
    mask_staff_owner     = { male = { drawable = 0,   texture = 0 }, female = { drawable = 0,   texture = 0 } },
    shirt_staff_owner    = { male = { drawable = 0,   texture = 0 }, female = { drawable = 0,   texture = 0 } },
    jacket_staff_owner   = { male = { drawable = 0,   texture = 0 }, female = { drawable = 999, texture = 0 } },

    -- MANAGER
    mask_staff_manager   = { male = { drawable = 0,   texture = 0 }, female = { drawable = 0,   texture = 0 } },
    shirt_staff_manager  = { male = { drawable = 0,   texture = 0 }, female = { drawable = 0,   texture = 0 } },
    jacket_staff_manager = { male = { drawable = 0,   texture = 1 }, female = { drawable = 999, texture = 1 } },

    -- DEVELOPER (nu e un grad rpg-auth; doar item, se poate da prin /giveitem)
    jacket_staff_developer = { male = { drawable = 0, texture = 2 }, female = { drawable = 999, texture = 2 } },
}

-- ===========================================================================
--  PERSISTENTA
-- ===========================================================================
Config.SaveInterval = 120   -- secunde: autosave inventare marcate "dirty"

Config.Debug = true
