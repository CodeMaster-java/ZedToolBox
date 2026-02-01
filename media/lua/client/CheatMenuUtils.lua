local CheatMenuLogger = require "CheatMenuLogger"

local CheatMenuUtils = {}

local SPEED_MIN = 0.5
local SPEED_MAX = 5
local CLEAR_RADIUS_MIN = 1
local CLEAR_RADIUS_MAX = 50
local CLEAR_RADIUS_DEFAULT = 15

local state = {
    godMode = false,
    hitKill = false,
    speedMultiplier = 1,
    infiniteStamina = false,
    instantBuild = false,
    noNegativeEffects = false,
    noHungerThirst = false,
    clearRadius = CLEAR_RADIUS_DEFAULT,
    lastGodMode = false,
    lastSpeedMultiplier = 1,
    lastStaminaBoost = false,
    lastInstantBuild = false,
    instantBuildBackup = nil,
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

local function refreshStamina(player, enabled)
    if state.lastStaminaBoost ~= enabled then
        if player.setUnlimitedEndurance then
            player:setUnlimitedEndurance(enabled)
        end
        state.lastStaminaBoost = enabled
    end
    if not enabled then
        return
    end
    local stats = player.getStats and player:getStats()
    if stats then
        if stats.setEndurance then stats:setEndurance(1) end
        if stats.setEnduranceRecharging then stats:setEnduranceRecharging(true) end
    end
end

local function clearNeeds(player)
    local stats = player.getStats and player:getStats()
    if stats then
        if stats.setHunger then stats:setHunger(0) end
        if stats.setThirst then stats:setThirst(0) end
    end
end

local function clearNegativeEffects(player)
    local stats = player.getStats and player:getStats()
    if stats then
        if stats.setFatigue then stats:setFatigue(0) end
        if stats.setPain then stats:setPain(0) end
        if stats.setStress then stats:setStress(0) end
        if stats.setBoredom then stats:setBoredom(0) end
        if stats.setAnger then stats:setAnger(0) end
        if stats.setPanic then stats:setPanic(0) end
        if stats.setDrunkenness then stats:setDrunkenness(0) end
        if stats.setUnhappyness then stats:setUnhappyness(0) end
        if stats.setMorale then stats:setMorale(1) end
    end
    local bodyDamage = player.getBodyDamage and player:getBodyDamage()
    if bodyDamage then
        if bodyDamage.setFoodSicknessLevel then bodyDamage:setFoodSicknessLevel(0) end
        if bodyDamage.setInfectionLevel then bodyDamage:setInfectionLevel(0) end
        if bodyDamage.setInfected then bodyDamage:setInfected(false) end
        if bodyDamage.setColdStrength then bodyDamage:setColdStrength(0) end
        if bodyDamage.setWetness then bodyDamage:setWetness(0) end
        if bodyDamage.setUnhappynessLevel then bodyDamage:setUnhappynessLevel(0) end
        if bodyDamage.setBoredomLevel then bodyDamage:setBoredomLevel(0) end
        if bodyDamage.setSicknessLevel then bodyDamage:setSicknessLevel(0) end
        if bodyDamage.setPainReduction then bodyDamage:setPainReduction(1) end
        if bodyDamage.setTemperature then bodyDamage:setTemperature(37) end
    end
end

local function fullHeal(player)
    refreshStamina(player, true)
    clearNeeds(player)
    clearNegativeEffects(player)
    if player.setHealth then
        player:setHealth(100)
    end
    local bodyDamage = player.getBodyDamage and player:getBodyDamage()
    if bodyDamage then
        if bodyDamage.RestoreToFullHealth then bodyDamage:RestoreToFullHealth() end
        if bodyDamage.setOverallBodyHealth then bodyDamage:setOverallBodyHealth(100) end
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
    if state.godMode then
        fullHeal(player)
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

local function applyInstantBuildCheat(enabled)
    local buildMenu = _G.ISBuildMenu
    local moveMenu = _G.ISMoveableMenu
    local craftingUI = _G.ISCraftingUI

    if enabled and not state.instantBuildBackup then
        state.instantBuildBackup = {
            buildMenu = buildMenu and {
                cheat = buildMenu.cheat,
                cheatMenu = buildMenu.cheatMenu,
                cheatBuild = buildMenu.cheatBuild,
                cheatAll = buildMenu.cheatAll
            } or nil,
            moveMenu = moveMenu and {
                cheat = moveMenu.cheat
            } or nil,
            craftingUI = craftingUI and {
                Cheat = craftingUI.Cheat
            } or nil
        }
    end

    if type(buildMenu) == "table" then
        local target = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.buildMenu and state.instantBuildBackup.buildMenu.cheat) or false)
        local targetMenu = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.buildMenu and state.instantBuildBackup.buildMenu.cheatMenu) or false)
        local targetBuild = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.buildMenu and state.instantBuildBackup.buildMenu.cheatBuild) or false)
        local targetAll = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.buildMenu and state.instantBuildBackup.buildMenu.cheatAll) or false)
        buildMenu.cheat = target
        buildMenu.cheatMenu = targetMenu
        buildMenu.cheatBuild = targetBuild
        buildMenu.cheatAll = targetAll
        if buildMenu.setCheat then
            pcall(buildMenu.setCheat, buildMenu, target)
        end
    end

    if type(moveMenu) == "table" then
        local target = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.moveMenu and state.instantBuildBackup.moveMenu.cheat) or false)
        moveMenu.cheat = target
        if moveMenu.setCheat then
            pcall(moveMenu.setCheat, moveMenu, target)
        end
    end

    if type(craftingUI) == "table" then
        local target = enabled and true or ((state.instantBuildBackup and state.instantBuildBackup.craftingUI and state.instantBuildBackup.craftingUI.Cheat) or false)
        craftingUI.Cheat = target
    end

    if not enabled then
        state.instantBuildBackup = nil
    end
end

local function updateInstantBuildCheat()
    if state.forceRefresh or state.lastInstantBuild ~= state.instantBuild then
        applyInstantBuildCheat(state.instantBuild)
        state.lastInstantBuild = state.instantBuild
    end
end

local function ensurePlayerState(player)
    updateInstantBuildCheat()
    if not player then
        return
    end
    if player ~= state.lastPlayer then
        state.lastPlayer = player
        state.forceRefresh = true
    end

    local staminaEnabled = state.godMode or state.infiniteStamina
    refreshStamina(player, staminaEnabled)

    if state.forceRefresh or state.lastGodMode ~= state.godMode then
        state.lastGodMode = state.godMode
        applyGodMode(player)
    elseif state.godMode then
        fullHeal(player)
    else
        if state.noHungerThirst then
            clearNeeds(player)
        end
        if state.noNegativeEffects then
            clearNegativeEffects(player)
        end
    end

    local needsSpeedUpdate = state.forceRefresh or math.abs(state.lastSpeedMultiplier - state.speedMultiplier) > 0.001
    if needsSpeedUpdate then
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
    updateInstantBuildCheat()
end

local function onCreatePlayer(index, player)
    if index ~= 0 then
        return
    end
    requestRefresh()
    updateInstantBuildCheat()
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

function CheatMenuUtils.setInfiniteStamina(enabled)
    state.infiniteStamina = enabled and true or false
    requestRefresh()
end

function CheatMenuUtils.setInstantBuild(enabled)
    state.instantBuild = enabled and true or false
    requestRefresh()
end

function CheatMenuUtils.setNoNegativeEffects(enabled)
    state.noNegativeEffects = enabled and true or false
    requestRefresh()
end

function CheatMenuUtils.setNoHungerThirst(enabled)
    state.noHungerThirst = enabled and true or false
    requestRefresh()
end

function CheatMenuUtils.setSpeedMultiplier(multiplier)
    state.speedMultiplier = clamp(multiplier or 1, SPEED_MIN, SPEED_MAX)
    requestRefresh()
    return state.speedMultiplier
end

function CheatMenuUtils.setClearRadius(value)
    state.clearRadius = clamp(value or CLEAR_RADIUS_DEFAULT, CLEAR_RADIUS_MIN, CLEAR_RADIUS_MAX)
    return state.clearRadius
end

function CheatMenuUtils.healPlayer()
    local player = getPlayer()
    if not player then
        return false
    end
    fullHeal(player)
    return true
end

local function killZombie(player, zombie)
    if not zombie or zombie:isDead() then
        return false
    end
    if zombie.Kill then
        zombie:Kill(player)
        return true
    end
    if zombie.setHealth then
        zombie:setHealth(0)
        return true
    end
    return false
end

function CheatMenuUtils.clearZombies(radius)
    local player = getPlayer()
    if not player then
        return 0
    end
    local targetRadius = clamp(radius or state.clearRadius, CLEAR_RADIUS_MIN, CLEAR_RADIUS_MAX)
    local sqrRadius = targetRadius * targetRadius
    local cell = getCell()
    if not cell or not cell.getZombieList then
        return 0
    end
    local zombies = cell:getZombieList()
    if not zombies then
        return 0
    end
    local cleared = 0
    for i = zombies:size() - 1, 0, -1 do
        local zombie = zombies:get(i)
        if zombie and not zombie:isDead() then
            local dx = (zombie:getX() or 0) - (player:getX() or 0)
            local dy = (zombie:getY() or 0) - (player:getY() or 0)
            local distanceSq = (dx * dx) + (dy * dy)
            if distanceSq <= sqrRadius then
                if killZombie(player, zombie) then
                    cleared = cleared + 1
                end
            end
        end
    end
    return cleared
end

function CheatMenuUtils.applyConfig(config)
    config = config or {}
    CheatMenuUtils.setGodMode(config.godMode)
    CheatMenuUtils.setHitKill(config.hitKill)
    CheatMenuUtils.setInfiniteStamina(config.infiniteStamina)
    CheatMenuUtils.setInstantBuild(config.instantBuild)
    CheatMenuUtils.setNoNegativeEffects(config.noNegativeEffects)
    CheatMenuUtils.setNoHungerThirst(config.noHungerThirst)
    CheatMenuUtils.setSpeedMultiplier(config.speedMultiplier)
    CheatMenuUtils.setClearRadius(config.clearRadius)
end

function CheatMenuUtils.getState()
    return {
        godMode = state.godMode,
        hitKill = state.hitKill,
        speedMultiplier = state.speedMultiplier,
        infiniteStamina = state.infiniteStamina,
        instantBuild = state.instantBuild,
        noNegativeEffects = state.noNegativeEffects,
        noHungerThirst = state.noHungerThirst,
        clearRadius = state.clearRadius
    }
end

return CheatMenuUtils
