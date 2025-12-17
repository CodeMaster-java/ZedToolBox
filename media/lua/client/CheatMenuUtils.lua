local CheatMenuLogger = require "CheatMenuLogger"

local CheatMenuUtils = {}

local SPEED_MIN = 0.5
local SPEED_MAX = 5

local state = {
    godMode = false,
    hitKill = false,
    speedMultiplier = 1,
    lastGodMode = false,
    lastSpeedMultiplier = 1,
    lastPlayer = nil,
    forceRefresh = true
}

local function clamp(value, minValue, maxValue)
    local number = tonumber(value) or 0
    if number < minValue then
        return minValue
    end
    if number > maxValue then
        return maxValue
    end
    return number
end

local function getPlayer()
    if not getSpecificPlayer then
        return nil
    end
    return getSpecificPlayer(0)
end

local function maintainStats(player)
    local stats = player.getStats and player:getStats()
    if stats then
        if stats.setEndurance then stats:setEndurance(1) end
        if stats.setEnduranceRecharging then stats:setEnduranceRecharging(true) end
        if stats.setHunger then stats:setHunger(0) end
        if stats.setThirst then stats:setThirst(0) end
        if stats.setFatigue then stats:setFatigue(0) end
        if stats.setPain then stats:setPain(0) end
        if stats.setStress then stats:setStress(0) end
        if stats.setBoredom then stats:setBoredom(0) end
        if stats.setAnger then stats:setAnger(0) end
        if stats.setPanic then stats:setPanic(0) end
        if stats.setDrunkenness then stats:setDrunkenness(0) end
    end
    if player.setHealth then
        player:setHealth(100)
    end
    local bodyDamage = player.getBodyDamage and player:getBodyDamage()
    if bodyDamage then
        if bodyDamage.RestoreToFullHealth then bodyDamage:RestoreToFullHealth() end
        if bodyDamage.setOverallBodyHealth then bodyDamage:setOverallBodyHealth(100) end
        if bodyDamage.setInfectionLevel then bodyDamage:setInfectionLevel(0) end
        if bodyDamage.setInfected then bodyDamage:setInfected(false) end
        if bodyDamage.setFoodSicknessLevel then bodyDamage:setFoodSicknessLevel(0) end
        if bodyDamage.setBoredomLevel then bodyDamage:setBoredomLevel(0) end
        if bodyDamage.setUnhappynessLevel then bodyDamage:setUnhappynessLevel(0) end
        if bodyDamage.setWetness then bodyDamage:setWetness(0) end
        if bodyDamage.setColdStrength then bodyDamage:setColdStrength(0) end
        if bodyDamage.setTemperature then bodyDamage:setTemperature(37) end
        if bodyDamage.setSicknessLevel then bodyDamage:setSicknessLevel(0) end
        if bodyDamage.setPainReduction then bodyDamage:setPainReduction(1) end
    end
end

local function applyGodMode(player)
    if player.setGodMod then
        player:setGodMod(state.godMode)
    end
    if player.setNoDamage then
        player:setNoDamage(state.godMode)
    end
    if player.setUnlimitedCarry then
        player:setUnlimitedCarry(state.godMode)
    end
    if player.setUnlimitedEndurance then
        player:setUnlimitedEndurance(state.godMode)
    end
    if state.godMode then
        maintainStats(player)
    end
end

local function applySpeed(player)
    local multiplier = state.speedMultiplier
    if player.setMoveSpeedModifier then
        player:setMoveSpeedModifier(multiplier)
    end
    if player.setWalkSpeedModifier then
        player:setWalkSpeedModifier(multiplier)
    end
    if player.setRunSpeedModifier then
        player:setRunSpeedModifier(multiplier)
    end
    if player.setSprintSpeedModifier then
        player:setSprintSpeedModifier(multiplier)
    end
    if player.setClimbSpeedModifier then
        player:setClimbSpeedModifier(multiplier)
    end
    if player.setForceSprint then
        player:setForceSprint(multiplier > 1.5)
    end
end

local function ensurePlayerState(player)
    if not player then
        return
    end
    if player ~= state.lastPlayer then
        state.lastPlayer = player
        state.forceRefresh = true
    end
    if state.forceRefresh or state.lastGodMode ~= state.godMode then
        state.lastGodMode = state.godMode
        applyGodMode(player)
    elseif state.godMode then
        maintainStats(player)
    end
    if state.forceRefresh or math.abs(state.lastSpeedMultiplier - state.speedMultiplier) > 0.001 then
        state.lastSpeedMultiplier = state.speedMultiplier
        applySpeed(player)
    end
    state.forceRefresh = false
end

local function onPlayerUpdate(player)
    if player ~= getPlayer() then
        return
    end
    ensurePlayerState(player)
end

local function onWeaponHitCharacter(player, target)
    if not state.hitKill then
        return
    end
    if player ~= getPlayer() then
        return
    end
    if not target or target:isDead() then
        return
    end
    if target.Kill then
        target:Kill(player)
        return
    end
    if target.setHealth then
        target:setHealth(0)
    end
    local bodyDamage = target.getBodyDamage and target:getBodyDamage()
    if bodyDamage and bodyDamage.setOverallBodyHealth then
        bodyDamage:setOverallBodyHealth(0)
    end
end

local function requestRefresh()
    state.forceRefresh = true
end

local function onGameStart()
    requestRefresh()
end

local function onCreatePlayer(index, player)
    if index ~= 0 then
        return
    end
    requestRefresh()
    if player == getPlayer() then
        ensurePlayerState(player)
    end
end

local function bind(event, name, handler)
    if not event or not event.Add then
        return
    end
    event.Add(function(...)
        CheatMenuLogger.safeCall("Utils." .. name, handler, ...)
    end)
end

bind(Events and Events.OnPlayerUpdate, "OnPlayerUpdate", onPlayerUpdate)
bind(Events and Events.OnWeaponHitCharacter, "OnWeaponHitCharacter", onWeaponHitCharacter)
bind(Events and Events.OnGameStart, "OnGameStart", onGameStart)
bind(Events and Events.OnCreatePlayer, "OnCreatePlayer", onCreatePlayer)

function CheatMenuUtils.setGodMode(enabled)
    state.godMode = enabled and true or false
    requestRefresh()
end

function CheatMenuUtils.setHitKill(enabled)
    state.hitKill = enabled and true or false
end

function CheatMenuUtils.setSpeedMultiplier(multiplier)
    state.speedMultiplier = clamp(multiplier or 1, SPEED_MIN, SPEED_MAX)
    requestRefresh()
    return state.speedMultiplier
end

function CheatMenuUtils.applyConfig(config)
    config = config or {}
    CheatMenuUtils.setGodMode(config.godMode)
    CheatMenuUtils.setHitKill(config.hitKill)
    CheatMenuUtils.setSpeedMultiplier(config.speedMultiplier)
end

function CheatMenuUtils.getState()
    return {
        godMode = state.godMode,
        hitKill = state.hitKill,
        speedMultiplier = state.speedMultiplier
    }
end

return CheatMenuUtils
