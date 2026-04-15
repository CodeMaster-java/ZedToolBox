local CheatMenuSession = {}

function CheatMenuSession.isMultiplayerSession()
    if type(isMultiplayer) == "function" and isMultiplayer() then
        return true
    end
    if type(isClient) == "function" and isClient() then
        return true
    end
    if type(isServer) == "function" and isServer() then
        return true
    end
    return false
end

function CheatMenuSession.isSingleplayerSession()
    return not CheatMenuSession.isMultiplayerSession()
end

function CheatMenuSession.isPlayerReady()
    return CheatMenuSession.getPlayerObject() ~= nil
end

function CheatMenuSession.getPlayerObject()
    if type(getSpecificPlayer) == "function" then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok and player then
            return player
        end
    end
    if type(getPlayer) == "function" then
        local ok, player = pcall(getPlayer)
        if ok and player then
            return player
        end
    end
    return nil
end

function CheatMenuSession.ensureSingleplayer(target, message)
    if CheatMenuSession.isSingleplayerSession() then
        return true
    end
    if target and type(target.setStatus) == "function" then
        target:setStatus(false, message or "This menu is available only in singleplayer.")
    end
    return false
end

return CheatMenuSession
