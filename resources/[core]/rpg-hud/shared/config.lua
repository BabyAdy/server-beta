Config = {}
Config.Debug = true

-- ===========================================================================
--  CHAT
-- ===========================================================================
Config.Chat = {
    openKey          = 'T',            -- singura definitie a tastei (rebindabila din Settings)

    -- ISTORIC / VIEWPORT
    maxMessages      = 100,            -- MAX_HISTORY_MESSAGES: mesaje pastrate in DOM
    visibleInactive  = 6,             -- MAX_VISIBLE_MESSAGES_INACTIVE: cate se vad in inactive
    lineHeight       = 1.45,          -- line-height mesaje; intra si in calculul inaltimii viewport-ului
    width            = 470,           -- px la 1920x1080: latimea chat-ului
    -- inaltimea viewport-ului activ NU e fixa: = linii × font × lineHeight + padding (calc in CSS)

    messageLifetime  = 5000,           -- ms pana incepe fade-ul (doar in inactive)
    fadeDuration     = 1000,           -- ms durata fade-ului
    inputPlaceholder = "Scrie un mesaj  ·  '/' pentru comenzi",
    maxLength        = 256,
    rateLimit        = 500,            -- ms minim intre doua mesaje / player

    -- CHAT-ul E MEREU LOCAL: mesajele scrise fara comanda ajung doar la
    -- jucatorii aflati in aceasta raza (metri).
    localRange       = 100.0,

    -- culorile chat-urilor de staff (mesajul in sine)
    adminChatColor   = '#F5B427',      -- /a
    helperChatColor  = '#F5E427',      -- /hc

    -- setari reglabile de jucator din rotita de setari (persistente in NUI)
    lines = { default = 6,    min = 3,  max = 14 },   -- mesaje vizibile in inactive
    font  = { default = 12.5, min = 10, max = 18 },   -- px, marimea textului din chat

    -- accentul vizual per tip de mesaj (mesajele normale de jucator NU au tag)
    -- GLOBAL / LOCAL sunt aici doar pentru exports:addMessage({ channel = ... }),
    -- jucatorii nu aleg canalul (chat-ul e mereu local).
    channels = {
        GLOBAL       = { label = 'GLOBAL', color = '#a78bfa' },
        LOCAL        = { label = 'LOCAL',  color = '#7fb3ff' },
        SYSTEM       = { label = 'SISTEM', color = '#9aa0aa' },
        STAFF        = { label = 'STAFF',  color = '#f0a85b' },
        ANNOUNCEMENT = { label = 'ANUNȚ',  color = '#f5c451' },
        ERROR        = { label = 'EROARE', color = '#f0576f' },
        SUCCESS      = { label = 'OK',     color = '#46d6a2' },
        INFO         = { label = 'INFO',   color = '#a78bfa' },
    },
}

-- ===========================================================================
--  HUD
-- ===========================================================================
Config.Hud = {
    hideOnInventory = false,           -- "vom decide ulterior" -> ramane vizibil
    healthPollMs    = 500,
    voicePollMs     = 200,

    -- NEEDS (Survival) — mock pana la sistemul real
    mockNeeds      = true,
    startNeeds     = { food = 100.0, water = 100.0 },
    mockDrainPerMin = { food = 0.9, water = 1.3 },

    -- PAYCHECK — UI + API reale, sistemul e stub
    paycheckInterval = 1800,           -- secunde

    -- MONEY — vine din Economy/Core; pana atunci:
    startMoney = { cash = 0, bank = 0 },
}

-- ===========================================================================
--  SPEEDOMETER  (100% client-side)
-- ===========================================================================
Config.Speedo = {
    updateMs   = 50,                   -- ~20 fps cat timp esti in vehicul
    idleMs     = 500,                  -- pe jos
    maxSpeed   = 300,                  -- km/h, pentru umplerea gauge-ului
    speedDelta = 1,                    -- km/h minim ca sa trimitem update
    unit       = 'KM/H',
    mockFuel   = true,                 -- native GetVehicleFuelLevel ca mock
    seatbeltKey = 'B',                 -- doar toggle UI + event (fara sistem)
}
