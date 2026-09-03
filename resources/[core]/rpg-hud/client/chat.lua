-- ===========================================================================
--  rpg-hud — CHAT
--  Chat-ul e MEREU LOCAL: mesajele fara comanda ajung doar la jucatorii din
--  raza (Config.Chat.localRange, 100m). Fara canale GLOBAL / LOCAL de ales.
--  NUI -> Client -> (Command System | Server) -> broadcast -> Client -> NUI
-- ===========================================================================

local function fmtTime() return os.date('%H:%M') end

-- ----- open / close ---------------------------------------------------
local function openChat(prefill)
    if HUD.chatOpen or not HUD.visible then return end
    HUD.chatOpen = true
    SetNuiFocus(true, true)
    HUD.send({ mod = 'chat', action = 'open', value = { prefill = prefill or '' } })
end

local function closeChat()
    if not HUD.chatOpen then return end
    HUD.chatOpen = false
    SetNuiFocus(false, false)
    HUD.send({ mod = 'chat', action = 'close' })
end

-- ----- NUI callbacks -----------------------------------------------
RegisterNUICallback('chatClose', function(_, cb)
    closeChat()
    cb('ok')
end)

RegisterNUICallback('chatSubmit', function(data, cb)
    closeChat()
    local text = tostring(data.text or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if text ~= '' then
        if text:sub(1, 1) == '/' then
            -- catre Command System-ul existent (client + fallback server): /a /hc /setstaff ...
            ExecuteCommand(text:sub(2))
        else
            TriggerServerEvent('rpg-hud:chatSend', text)
        end
    end
    cb('ok')
end)

-- ----- intrare mesaje --------------------------------------------
local function addMessage(payload)
    if type(payload) ~= 'table' then return end
    payload.time = payload.time or fmtTime()
    if payload.channel then payload.channel = tostring(payload.channel):upper() end
    HUD.send({ mod = 'chat', action = 'message', value = payload })
end
HUD.addChatMessage = addMessage

RegisterNetEvent('rpg-hud:chatMessage', function(payload) addMessage(payload) end)

-- compat cu conventia Cfx `chat:addMessage`
RegisterNetEvent('chat:addMessage', function(msg)
    if type(msg) ~= 'table' then return end
    local author, text
    if type(msg.args) == 'table' then
        if #msg.args >= 2 then
            author, text = tostring(msg.args[1]), tostring(msg.args[2])
        elseif #msg.args == 1 then
            text = tostring(msg.args[1])
        end
    end
    addMessage({
        channel = msg.channel and tostring(msg.channel):upper() or (author and nil or 'SYSTEM'),
        author  = author,
        text    = text or '',
    })
end)

-- compat cu semnatura clasica Cfx `chatMessage` (author, color, text)
RegisterNetEvent('chatMessage', function(author, _color, text)
    if text == nil then
        addMessage({ channel = 'SYSTEM', text = tostring(author or '') })
    else
        addMessage({
            author = (type(author) == 'string' and author ~= '') and author or nil,
            text   = tostring(text),
        })
    end
end)

-- ----- exports -------------------------------------------------
exports('addMessage', function(payload) addMessage(payload) end)
exports('clearChat',  function() HUD.send({ mod = 'chat', action = 'clear' }) end)
exports('openChat',   function() openChat() end)
exports('closeChat',  function() closeChat() end)

-- ----- keybind -----------------------------------------------
RegisterCommand('rpgChatOpen', function() openChat() end, false)
RegisterKeyMapping('rpgChatOpen', 'Chat: deschide', 'keyboard', Config.Chat.openKey)

-- ----- comanda de test --------------------------------------
RegisterCommand('hudmsg', function(_, args)
    addMessage({
        channel = (args[1] and args[1] ~= '-') and args[1]:upper() or nil,
        author  = (args[2] and args[2] ~= '-') and args[2] or nil,
        text    = table.concat(args, ' ', 3),
    })
end, false)
