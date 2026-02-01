return function(CheatMenuUI, deps)
	local clamp = deps.clamp
	local CheatMenuText = deps.CheatMenuText
	local CheatMenuUtils = deps.CheatMenuUtils

	function CheatMenuUI:ensureUtilsConfig()
		self.config = self.config or {}
		local raw = type(self.config.utils) == "table" and self.config.utils or {}
		local speedValue = tonumber(raw.speedMultiplier) or 1
		local speedClamped = clamp(speedValue, 0.5, 5)
		local normalized = {
			godMode = raw.godMode and true or false,
			hitKill = raw.hitKill and true or false,
			infiniteStamina = raw.infiniteStamina and true or false,
			instantBuild = raw.instantBuild and true or false,
			noNegativeEffects = raw.noNegativeEffects and true or false,
			noHungerThirst = raw.noHungerThirst and true or false,
			speedMultiplier = speedClamped,
			clearRadius = (CheatMenuUtils.getState() and CheatMenuUtils.getState().clearRadius) or 15
		}
		local changed = raw.godMode ~= normalized.godMode
			or raw.hitKill ~= normalized.hitKill
			or (raw.infiniteStamina and true or false) ~= normalized.infiniteStamina
			or (raw.instantBuild and true or false) ~= normalized.instantBuild
			or (raw.noNegativeEffects and true or false) ~= normalized.noNegativeEffects
			or (raw.noHungerThirst and true or false) ~= normalized.noHungerThirst
			or math.abs(speedValue - speedClamped) > 0.001
		self.config.utils = normalized
		CheatMenuUtils.applyConfig(normalized)
		return changed
	end

	function CheatMenuUI:populateToggleCombo(combo, enabled)
		if not combo then
			return
		end
		local selected = enabled and true or false
		if combo.clear then
			combo:clear()
		end
		if combo.addOptionWithData then
			combo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_Utils_Disabled", "Disabled"), false)
			combo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_Utils_Enabled", "Enabled"), true)
		else
			combo:addOption(CheatMenuText.get("UI_ZedToolbox_Utils_Disabled", "Disabled"))
			combo:addOption(CheatMenuText.get("UI_ZedToolbox_Utils_Enabled", "Enabled"))
		end
		combo.selected = selected and 2 or 1
	end

	function CheatMenuUI:setToggleComboSelection(combo, enabled)
		if not combo or not combo.options then
			return
		end
		local target = enabled and true or false
		for index, option in ipairs(combo.options) do
			if option.data == target then
				combo.selected = index
				return
			end
		end
	end

	function CheatMenuUI:populateSpeedCombo(multiplier)
		if not self.speedCombo then
			return
		end
		local current = clamp(multiplier or 1, 0.5, 5)
		if self.speedCombo.clear then
			self.speedCombo:clear()
		end
		local fallbackIndex = 1
		for index, value in ipairs(self.utilsSpeedValues or {}) do
			local label = CheatMenuText.get("UI_ZedToolbox_Utils_SpeedValue", "%1x", value)
			self.speedCombo:addOptionWithData(label, value)
			if math.abs(value - current) < 0.001 then
				fallbackIndex = index
			end
		end
		self.speedCombo.selected = fallbackIndex
	end

	function CheatMenuUI:populateUtilsOptions()
		local utils = (self.config and self.config.utils) or {
			godMode = false,
			hitKill = false,
			infiniteStamina = false,
			instantBuild = false,
			noNegativeEffects = false,
			noHungerThirst = false,
			speedMultiplier = 1,
			clearRadius = 15
		}
		self:populateToggleCombo(self.godModeCombo, utils.godMode)
		self:populateToggleCombo(self.hitKillCombo, utils.hitKill)
		self:populateToggleCombo(self.infiniteStaminaCombo, utils.infiniteStamina)
		self:populateToggleCombo(self.instantBuildCombo, utils.instantBuild)
		self:populateToggleCombo(self.noNegativeEffectsCombo, utils.noNegativeEffects)
		self:populateToggleCombo(self.noHungerThirstCombo, utils.noHungerThirst)
		self:populateSpeedCombo(utils.speedMultiplier)
	end

	function CheatMenuUI:syncUtilsUI()
		local utils = (self.config and self.config.utils) or {
			godMode = false,
			hitKill = false,
			infiniteStamina = false,
			instantBuild = false,
			noNegativeEffects = false,
			noHungerThirst = false,
			speedMultiplier = 1,
			clearRadius = 15
		}
		self:setToggleComboSelection(self.godModeCombo, utils.godMode)
		self:setToggleComboSelection(self.hitKillCombo, utils.hitKill)
		self:setToggleComboSelection(self.infiniteStaminaCombo, utils.infiniteStamina)
		self:setToggleComboSelection(self.instantBuildCombo, utils.instantBuild)
		self:setToggleComboSelection(self.noNegativeEffectsCombo, utils.noNegativeEffects)
		self:setToggleComboSelection(self.noHungerThirstCombo, utils.noHungerThirst)
		if self.speedCombo and self.speedCombo.options then
			local target = clamp(utils.speedMultiplier or 1, 0.5, 5)
			for index, option in ipairs(self.speedCombo.options) do
				if math.abs((option.data or 0) - target) < 0.001 then
					self.speedCombo.selected = index
					break
				end
			end
		end
		if self.clearZombiesButton then
			local radius = utils.clearRadius or 15
			self.clearZombiesButton:setTitle(CheatMenuText.get("UI_ZedToolbox_Utils_ClearZombiesLabel", "Clear Nearby Zombies (%1 tiles)", radius))
		end
	end

	function CheatMenuUI:updateUtilsConfig(field, value)
		self.config = self.config or {}
		self.config.utils = self.config.utils or {}
		local changed = self.config.utils[field] ~= value
		self.config.utils[field] = value
		if changed then
			self:flushPersistentData()
		end
		return changed
	end

	function CheatMenuUI:onGodModeChanged()
		if not self.godModeCombo or not self.godModeCombo.options then
			return
		end
		local option = self.godModeCombo.options[self.godModeCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("godMode", enabled)
		CheatMenuUtils.setGodMode(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusGodModeOn" or "UI_ZedToolbox_StatusGodModeOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "God Mode enabled." or "God Mode disabled."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onHitKillChanged()
		if not self.hitKillCombo or not self.hitKillCombo.options then
			return
		end
		local option = self.hitKillCombo.options[self.hitKillCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("hitKill", enabled)
		CheatMenuUtils.setHitKill(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusHitKillOn" or "UI_ZedToolbox_StatusHitKillOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Hit Kill enabled." or "Hit Kill disabled."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onInfiniteStaminaChanged()
		if not self.infiniteStaminaCombo or not self.infiniteStaminaCombo.options then
			return
		end
		local option = self.infiniteStaminaCombo.options[self.infiniteStaminaCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("infiniteStamina", enabled)
		CheatMenuUtils.setInfiniteStamina(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusInfiniteStaminaOn" or "UI_ZedToolbox_StatusInfiniteStaminaOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Infinite stamina enabled." or "Infinite stamina disabled."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onInstantBuildChanged()
		if not self.instantBuildCombo or not self.instantBuildCombo.options then
			return
		end
		local option = self.instantBuildCombo.options[self.instantBuildCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("instantBuild", enabled)
		CheatMenuUtils.setInstantBuild(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusInstantBuildOn" or "UI_ZedToolbox_StatusInstantBuildOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Instant build enabled." or "Instant build disabled."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onNoNegativeEffectsChanged()
		if not self.noNegativeEffectsCombo or not self.noNegativeEffectsCombo.options then
			return
		end
		local option = self.noNegativeEffectsCombo.options[self.noNegativeEffectsCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("noNegativeEffects", enabled)
		CheatMenuUtils.setNoNegativeEffects(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusNoNegativeEffectsOn" or "UI_ZedToolbox_StatusNoNegativeEffectsOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Negative effects cleared automatically." or "Negative effect protection disabled."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onNoHungerThirstChanged()
		if not self.noHungerThirstCombo or not self.noHungerThirstCombo.options then
			return
		end
		local option = self.noHungerThirstCombo.options[self.noHungerThirstCombo.selected]
		local enabled = option and option.data and true or false
		self:updateUtilsConfig("noHungerThirst", enabled)
		CheatMenuUtils.setNoHungerThirst(enabled)
		local messageKey = enabled and "UI_ZedToolbox_StatusNoHungerThirstOn" or "UI_ZedToolbox_StatusNoHungerThirstOff"
		self:setStatus(true, CheatMenuText.get(messageKey, enabled and "Hunger and thirst disabled." or "Hunger and thirst restored to normal."))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onSpeedChanged()
		if not self.speedCombo or not self.speedCombo.options then
			return
		end
		local option = self.speedCombo.options[self.speedCombo.selected]
		local multiplier = clamp(option and option.data or 1, 0.5, 5)
		self:updateUtilsConfig("speedMultiplier", multiplier)
		CheatMenuUtils.setSpeedMultiplier(multiplier)
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSpeedApplied", "Speed set to %1x.", multiplier))
		self:syncUtilsUI()
	end

	function CheatMenuUI:onHealClicked()
		local success = CheatMenuUtils.healPlayer()
		if success then
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusHealed", "Player fully healed."))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusHealFailed", "Player not ready."))
		end
	end

	function CheatMenuUI:onClearZombiesClicked()
		local utilsState = CheatMenuUtils.getState() or {}
		local finalRadius = utilsState.clearRadius or 15
		local cleared = CheatMenuUtils.clearZombies(finalRadius)
		if cleared > 0 then
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusClearZombies", "%1 zombies removed within %2 tiles.", cleared, finalRadius))
		else
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusClearZombiesNone", "No zombies found within %1 tiles.", finalRadius))
		end
	end
end
