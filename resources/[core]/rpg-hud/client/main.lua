-- ===========================================================================
--  rpg-hud — client bootstrap: NUI, state machine de vizibilitate, hooks core.
--  Data flow:  Game/Core -> Client -> NUI. NUI nu atinge DB-ul.
-- ===========================================================================

HUD = {
    nuiReady = false,   -- pagina NUI incarcata
    visible  = false,   -- HUD vizibil (personaj in joc)
    chatOpen = false,
}

function HUD.send(msg) SendNUIMessage(msg) end

local function pushConfig()
    HUD.send({ mod = 'root', action = 'config', value = {
        chat = {
            placeholder     = Config.Chat.inputPlaceholder,
            channels        = Config.Chat.channels,
            lifetime        = Config.Chat.messageLifetime,
            fade            = Config.Chat.fadeDuration,
            maxMessages     = Config.Chat.maxMessages,
            visibleInactive = Config.Chat.visibleInactive,
            viewportHeight  = Config.Chat.viewportHeight,
            width           = Config.Chat.width,
            lines           = Config.Chat.lines,
            font            = Config.Chat.font,
        },
        speedo = { unit = Config.Speedo.unit, maxSpeed = Config.Speedo.maxSpeed },
    }})
end

function HUD.setVisible(state)
    state = state == true
    HUD.visible = state
    HUD.send({ mod = 'root', action = 'visible', value = state })
end

-- ----- NUI semnaleaza ca s-a incarcat --------------------------------
RegisterNUICallback('ready', function(_, cb)
    HUD.nuiReady = true
    pushConfig()
    HUD.send({ mod = 'root', action = 'visible', value = HUD.visible })
    cb('ok')
end)

-- ----- vizibilitate legata de flow-ul de personaj -------------------
AddEventHandler('core:characterSpawned', function()
    HUD.setVisible(true)
    TriggerEvent('rpg-hud:startFeeders')
end)

RegisterNetEvent('hud:setVisible', function(v) HUD.setVisible(v) end)
RegisterNetEvent('hud:updateVisible', function(v) HUD.setVisible(v) end)

-- carlig optional: rpg-inventory poate emite 'hud:inventory' (open/close)
AddEventHandler('hud:inventory', function(open)
    if Config.Hud.hideOnInventory then HUD.setVisible(not open) end
end)

-- ----- exports -----------------------------------------------------
exports('setHudVisible', function(v) HUD.setVisible(v) end)
exports('isHudVisible',  function() return HUD.visible end)
exports('isChatOpen',    function() return HUD.chatOpen end)

-- ----- cleanup la stop -------------------------------------------
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and HUD.chatOpen then
        SetNuiFocus(false, false)
    end
end)
