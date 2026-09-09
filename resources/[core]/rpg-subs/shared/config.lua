-- ===========================================================================
--  rpg-subs — configuratie
-- ===========================================================================
Config = {}

-- Grad minim pentru /debugsub si /removesub.
Config.AdminRank = 'owner'

-- Grad minim considerat "staff" pentru accesul la chat-ul VIP (/vip).
-- (orice grad de staff -> level > 0; il lasam configurabil oricum)
Config.StaffChatRank = 'trialhelper'

-- Culoarea chat-ului VIP (mov).
Config.ChatColor = '#b57bff'

-- Comanda chat-ului VIP.
Config.ChatCommand = 'pc'

-- /shop — pret in Premium Points / ZI, per tip. Legend NU e cumparabil.
Config.ShopPricePerDay = {
    gold     = 8,
    platinum = 20,
}
Config.ShopMinDays = 1
Config.ShopMaxDays = 365

-- La cate secunde se re-evalueaza expirarea si se re-impinge statebag-ul.
Config.RefreshSec = 60

Config.Debug = true
