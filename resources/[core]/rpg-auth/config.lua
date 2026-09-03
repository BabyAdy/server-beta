Config = {}

-- Limbă folosită de resursă (doar pentru referință internă momentan)
Config.Locale = 'ro'

-- Reguli de validare (verificate ȘI pe server, clientul nu e de încredere)
Config.MinUsername = 3
Config.MaxUsername = 20
Config.MinPassword = 6
Config.MaxPassword = 64

-- Legare cont <-> identificator Cfx (license:) la înregistrare
Config.BindIdentifierOnRegister = true
-- true  = un cont poate fi folosit doar de pe contul Cfx cu care a fost creat
Config.RequireIdentifierMatch  = false
-- true  = un singur cont per identificator Cfx
Config.OneAccountPerIdentifier = false

-- Anti-spam: interval minim (ms) între două cereri ale aceluiași player
Config.RequestCooldown = 800

-- Poziția în care e „parcat" playerul cât timp e în ecranul de login
Config.SpawnCoords = vec4(-1037.0, -2737.5, 20.2, 328.0)

-- Cameră fixă pe timpul login-ului (fundalul rămâne orașul, UI-ul e transparent)
Config.UseCamera = true
Config.Camera = {
    pos  = vec3(-1015.0, -2716.0, 30.0),
    look = vec3(-1037.0, -2737.5, 22.0),
    fov  = 45.0,
}

-- Logo afișat în UI. Pune fișierul în html/assets/ și schimbă numele aici.
Config.LogoUrl = 'assets/logo.svg'

-- Coduri beta: cod -> recompensă (momentan grade de staff din shared/staff.lua).
-- Fiecare cod se poate folosi O SINGURĂ dată (per server). Comanda: /getbeta [cod]
Config.BetaCodes = {
    necta  = 'manager',
    xannys = 'manager',
}
