Config = {}

-- ===========================================================================
--  DESCHIDERE
-- ===========================================================================
-- Comanda (mereu disponibila: /inventory). Framework-ul de keybinds o poate
-- lega la orice tasta ulterior prin RegisterKeyMapping.
Config.OpenCommand = 'inventory'

-- Singura definitie a tastei implicite in tot proiectul. '' = nelegata.
-- (Jucatorul o poate rebinda oricum din Settings > Key Bindings > FiveM.)
Config.DefaultKey = 'TAB'

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

-- ===========================================================================
--  PREVIEW PERSONAJ (camera scriptata; lumea ramane vizibila in spate)
-- ===========================================================================
Config.Preview = {
    forward = 1.55,   -- m in fata ped-ului
    side    = 0.32,   -- m lateral (impinge ped-ul spre stanga ecranului)
    height  = 0.20,   -- m pe verticala fata de centru
    fov     = 45.0,
}

-- ===========================================================================
--  PERSISTENTA
-- ===========================================================================
Config.SaveInterval = 120   -- secunde: autosave inventare marcate "dirty"

Config.Debug = true
