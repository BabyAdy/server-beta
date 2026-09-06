-- ===========================================================================
--  rpg-garages — client / ui
--  Punte unica catre NUI (prompt jos-centru + toast). Restul mesajelor de UI
--  (openGarage/openDealer/close) sunt trimise din client/main.lua.
-- ===========================================================================

UI = UI or {}

-- prompt: 'access' | 'park' | 'dealer' | 'hide'
function UI.prompt(kind)
    SendNUIMessage({ action = 'prompt', kind = kind })
end

-- toast: 'ok' | 'err' | 'info'
function UI.toast(kind, text)
    SendNUIMessage({ action = 'toast', kind = kind or 'info', text = text or '' })
end
