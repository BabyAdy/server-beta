-- ===========================================================================
--  rpg-tickets — configuratie partajata (client + server)
-- ===========================================================================
Config = {}

-- ---- ACCES --------------------------------------------------------------
-- Gradul minim (slug din rpg-auth/shared/staff.lua) pentru a deschide meniul de staff.
Config.StaffOpenRank   = 'trialhelper'   -- orice grad >= Trial Helper
-- Gradul minim pentru a putea prelua/inchide tichete.
Config.StaffClaimRank  = 'trialhelper'
-- Gradul minim pentru TP / Bring.
Config.StaffTeleportRank = 'trialhelper'

-- ---- KEYBINDS / COMENZI ----------------------------------------------
Config.Commands = {
    playerMenu = 'ticket',      -- /ticket           (jucatori)
    staffMenu  = 'tk',          -- /tk               (staff)
    staffMenuAlt = 'reports',   -- alias optional; pune '' ca sa-l dezactivezi
    tpTo       = 'tpto',        -- /tpto  [ticketId | serverId]
    bring      = 'bring',       -- /bring [ticketId | serverId]
}
Config.PlayerMenuKey = ''       -- fara keybind pt. player (doar /ticket)
Config.StaffMenuKey  = 'F4'     -- keybind pt. /tk

-- ---- CATEGORII TICHETE (trebuie sa fie in sync cu <select> din NUI) ----
Config.Categories = {
    'General Problem / Confusion',
    'Player Report',
    'Bug / Technical Issues',
    'Item Pick-up / Losses',
    'Other',
}

-- ---- LIMITE -----------------------------------------------------------
Config.MaxOpenTicketsPerPlayer = 2       -- cate tichete non-inchise poate avea un jucator
Config.MinReasonLength  = 10
Config.MaxReasonLength  = 800
Config.MaxMessageLength = 500
Config.MessageRateLimitMs = 800          -- anti-spam pe mesaje

-- ---- REWARDS --------------------------------------------------------
-- Payout in $ per ticket INCHIS, pe familii de grad (Staff.kind + level).
-- Cheia = pragul minim de Staff.level; se alege cel mai mare prag <= level-ul staff-ului.
Config.Rewards = {
    enabled = true,

    -- $ / ticket in functie de Staff.level (vezi staff.lua: helper=20, trialadmin=40, manager=90 ...)
    payoutByLevel = {
        [0]  = 0,       -- fara grad (nu ar trebui sa ajunga aici)
        [10] = 500,     -- Trial Helper / Helper family
        [40] = 700,     -- Trial Admin .. Lead Admin family
        [90] = 900,     -- Manager / Owner
    },

    -- FPT (FPLAYT points): 1 FPT la fiecare N tichete inchise (lunar).
    fptPerTickets = 100,

    -- Bonus la prag lunar: cand tickets_closed_monthly ATINGE `milestone`, se acorda `milestoneFptByLevel`.
    milestone = 1000,
    milestoneFptByLevel = {
        [10] = 10,
        [40] = 15,
        [90] = 20,
    },

    -- La revendicare (butonul CLAIM) suma (money_accrued - money_claimed) se vireaza in users.bank.
    claimToBank = true,
    minClaim = 1,           -- suma minima revendicabila
}

-- ---- HAINE STAFF (Dashboard) ------------------------------------------------
-- Butoanele "Mască / Tricou / Hanorac Staff" NU mai echipeaza direct: serverul
-- verifica gradul si BAGA itemul potrivit in inventarul jucatorului; el il
-- echipeaza singur (rpg-inventory aplica modelul addon, male/female).
-- Aceleasi iteme se pot da si prin /giveitem.
--
-- Cheia = slug de grad (rpg-auth/shared/staff.lua). Daca gradul jucatorului nu
-- e aici, se coboara la cel mai apropiat grad INFERIOR care are o intrare.
-- Drawable/texture pe gen se regleaza in rpg-inventory (Config.StaffWardrobe).
Config.StaffWardrobe = {
    owner   = { mask = 'mask_staff_owner',   tshirt = 'shirt_staff_owner',   hoodie = 'jacket_staff_owner'   },
    manager = { mask = 'mask_staff_manager', tshirt = 'shirt_staff_manager', hoodie = 'jacket_staff_manager' },
}

-- ---- DIVERSE --------------------------------------------------------
Config.Debug = true
Config.RefreshStaffListMs = 0   -- 0 = doar prin evenimente realtime; >0 = si polling de siguranta
