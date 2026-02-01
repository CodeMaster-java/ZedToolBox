local ok, CheatMenuUI = pcall(require, "CheatMenuUI")
if not ok then
    CheatMenuUI = nil
end

local CheatMenuLogger = require "CheatMenuLogger"

local CheatMenuMain = {}

local MODDATA_KEY = "ZedToolbox"
local DEFAULT_TOGGLE_KEY = Keyboard.KEY_INSERT

CheatMenuMain.Config = {
    toggleKey = DEFAULT_TOGGLE_KEY
}

local function persistToggleKey(keyCode)
    if not ModData or not ModData.getOrCreate or type(keyCode) ~= "number" then
        return
    end
    local ok, data = pcall(ModData.getOrCreate, MODDATA_KEY)
    if not ok or type(data) ~= "table" then
        return
    end
    data.config = data.config or {}
    if data.config.toggleKey ~= keyCode then
        data.config.toggleKey = keyCode
        if ModData.transmit then
            ModData.transmit(MODDATA_KEY)
        end
    end
end

local function readToggleKeyFromModData()
    if not ModData or not ModData.getOrCreate then
        return nil
    end
    local ok, data = pcall(ModData.getOrCreate, MODDATA_KEY)
    if not ok or type(data) ~= "table" then
        return nil
    end
    data.config = data.config or {}
    local stored = data.config.toggleKey
    if type(stored) == "number" then
        return stored
    end
    return nil
end

function CheatMenuMain.syncToggleKey()
    local stored = readToggleKeyFromModData()
    if type(stored) == "number" then
        CheatMenuMain.Config.toggleKey = stored
        CheatMenuMain._cachedToggleKey = stored
    elseif type(CheatMenuMain.Config.toggleKey) ~= "number" then
        CheatMenuMain.Config.toggleKey = DEFAULT_TOGGLE_KEY
    end
end

function CheatMenuMain.setToggleKey(keyCode)
    if type(keyCode) == "number" then
        CheatMenuMain.Config.toggleKey = keyCode
        CheatMenuMain._cachedToggleKey = keyCode
        persistToggleKey(keyCode)
    end
end

local function isSingleplayer()
    if isMultiplayer and isMultiplayer() then
        return false
    end
    return not isClient() and not isServer()
end

local function playerReady()
    return getSpecificPlayer(0) ~= nil
end

local function resolveUIClass()
    if type(CheatMenuUI) == "table" then
        return CheatMenuUI
    end
    local ok, uiClass = pcall(require, "CheatMenuUI")
    if ok and type(uiClass) == "table" then
        CheatMenuUI = uiClass
        return CheatMenuUI
    end
    print("[ZedToolbox] CheatMenuUI unavailable; retrying later")
    return nil
end

local function safeInvoke(context, fn, ...)
    if CheatMenuLogger and type(CheatMenuLogger.safeCall) == "function" then
        return CheatMenuLogger.safeCall(context, fn, ...)
    end
    return pcall(fn, ...)
end

function CheatMenuMain.canUse()
    return isSingleplayer()
end

function CheatMenuMain.ensureMenu()
    if CheatMenuMain.menu then
        return CheatMenuMain.menu
    end
    if not playerReady() then
        return nil
    end
    local uiClass = resolveUIClass()
    if not uiClass then
        return nil
    end
    local core = getCore()
    local screenW = core and core:getScreenWidth() or 1280
    local screenH = core and core:getScreenHeight() or 720
    local width = uiClass.Width or 900
    local height = uiClass.Height or 540
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 3)
    local menu = uiClass:new(x, y)
    menu:initialise()
    menu:addToUIManager()
    menu:setVisible(false)
    CheatMenuMain.menu = menu
    return menu
end

function CheatMenuMain.hideMenu()
    if CheatMenuMain.menu then
        CheatMenuMain.menu:close()
    end
end

function CheatMenuMain.toggleMenu()
    local menu = CheatMenuMain.ensureMenu()
    if not menu then
        return
    end
    if menu:getIsVisible() then
        menu:close()
    else
        menu:show()
    end
end

function CheatMenuMain.onKeyPressed(key)
    if key ~= CheatMenuMain.Config.toggleKey then
        return
    end
    if not CheatMenuMain.canUse() then
        CheatMenuMain:notifyBlocked()
        return
    end
    if not playerReady() then
        return
    end
    CheatMenuMain.toggleMenu()
end

function CheatMenuMain.onGameStart()
    if not CheatMenuMain.canUse() then
        CheatMenuMain.hideMenu()
        return
    end
    if playerReady() then
        CheatMenuMain.ensureMenu()
    end
end

function CheatMenuMain.onPlayerCreated(playerIndex, playerObj)
    if playerIndex ~= 0 then
        return
    end
    if not CheatMenuMain.canUse() then
        CheatMenuMain.hideMenu()
    elseif CheatMenuMain.menu and CheatMenuMain.menu:getIsVisible() then
        CheatMenuMain.menu:show()
    end
end

function CheatMenuMain:notifyBlocked()
    if self.warned then
        return
    end
    print("[CheatMenu] Disabled in multiplayer sessions")
    self.warned = true
end

function CheatMenuMain.bindEvents()
    if CheatMenuMain._eventsBound then
        return
    end
    CheatMenuMain._eventsBound = true

    Events.OnKeyPressed.Add(function(key)
        safeInvoke("OnKeyPressed", CheatMenuMain.onKeyPressed, key)
    end)

    Events.OnGameStart.Add(function()
        safeInvoke("OnGameStart", CheatMenuMain.onGameStart)
    end)

    Events.OnCreatePlayer.Add(function(playerIndex, playerObj)
        safeInvoke("OnCreatePlayer", CheatMenuMain.onPlayerCreated, playerIndex, playerObj)
    end)
end

CheatMenuMain.syncToggleKey()
CheatMenuMain.bindEvents()

return CheatMenuMain
