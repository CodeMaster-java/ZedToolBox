return function(CheatMenuUI, deps)
	local buildSkillDefinitions = deps.buildSkillDefinitions
	local clampSkillLevel = deps.clampSkillLevel
	local MAX_SKILL_LEVEL = deps.MAX_SKILL_LEVEL
	local CheatMenuText = deps.CheatMenuText
	local getPlayerCharacter = deps.getPlayerCharacter
	local getPlayerSkillLevel = deps.getPlayerSkillLevel
	local applySkillLevel = deps.applySkillLevel

	function CheatMenuUI:getSkillDefinitions()
		if not self.skillDefinitions or #self.skillDefinitions == 0 then
			self.skillDefinitions = buildSkillDefinitions()
		end
		return self.skillDefinitions or {}
	end

	function CheatMenuUI:refreshSkillDefinitions()
		self.skillDefinitions = buildSkillDefinitions()
	end

	function CheatMenuUI:getSelectedSkillDefinition()
		if not self.skillCombo or not self.skillCombo.options then
			return nil
		end
		local index = self.skillCombo.selected or 1
		local definitions = self:getSkillDefinitions()
		return definitions[index]
	end

	function CheatMenuUI:getSelectedSkillLevel()
		if not self.skillLevelCombo or not self.skillLevelCombo.options then
			return 0
		end
		local option = self.skillLevelCombo.options[self.skillLevelCombo.selected]
		return clampSkillLevel(option and option.data)
	end

	function CheatMenuUI:populateSkillOptions(selectedType)
		if not self.skillCombo then
			return
		end
		self:refreshSkillDefinitions()
		self.skillCombo:clear()
		local definitions = self:getSkillDefinitions()
		local fallbackIndex = 1
		for index, definition in ipairs(definitions) do
			local label = tostring(definition.label or definition.id or "Skill")
			self.skillCombo:addOptionWithData(label, definition.type)
			if selectedType and definition.type == selectedType then
				fallbackIndex = index
			end
		end
		if #definitions == 0 then
			self.skillCombo:addOption(CheatMenuText.get("UI_ZedToolbox_Skills_None", "No skills available"))
		end
		local optionCount = self.skillCombo.options and #self.skillCombo.options or 0
		if optionCount > 0 then
			if fallbackIndex > optionCount then
				fallbackIndex = optionCount
			end
			self.skillCombo.selected = fallbackIndex
		else
			self.skillCombo.selected = 1
		end
	end

	function CheatMenuUI:populateSkillLevelOptions(selectedLevel)
		if not self.skillLevelCombo then
			return
		end
		self.skillLevelCombo:clear()
		local fallbackIndex = 1
		local level = clampSkillLevel(selectedLevel)
		for value = 0, MAX_SKILL_LEVEL do
			local label = tostring(value)
			self.skillLevelCombo:addOptionWithData(label, value)
			if value == level then
				fallbackIndex = value + 1
			end
		end
		self.skillLevelCombo.selected = fallbackIndex
	end

	function CheatMenuUI:updateSkillCurrentLevelText()
		local player = getPlayerCharacter()
		local definition = self:getSelectedSkillDefinition()
		local currentLevel = getPlayerSkillLevel(player, definition)
		self.skillCurrentLevelText = CheatMenuText.get("UI_ZedToolbox_Skills_CurrentLevel", "Current Level: %1", currentLevel)
		return currentLevel
	end

	function CheatMenuUI:syncSkillUI()
		local player = getPlayerCharacter()
		local definition = self:getSelectedSkillDefinition()
		local currentLevel = getPlayerSkillLevel(player, definition)
		self:populateSkillLevelOptions(currentLevel)
		if self.skillCombo and self.skillCombo.options and #self.skillCombo.options > 0 then
			self.skillCombo.selected = math.max(1, self.skillCombo.selected or 1)
		end
		self:updateSkillCurrentLevelText()
	end

	function CheatMenuUI:onSkillSelectionChanged()
		self:syncSkillUI()
	end

	function CheatMenuUI:onSkillApplyLevel()
		local definition = self:getSelectedSkillDefinition()
		if not definition then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Skills_StatusNoSkill", "Select a skill first."))
			return
		end
		local targetLevel = self:getSelectedSkillLevel()
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local success = applySkillLevel(player, definition, targetLevel)
		if success then
			self:syncSkillUI()
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSkillUpdated", "%1 set to level %2.", tostring(definition.label or definition.id), targetLevel))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillFailed", "Could not update skills."))
		end
	end

	function CheatMenuUI:onSkillIncrease()
		local definition = self:getSelectedSkillDefinition()
		if not definition then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Skills_StatusNoSkill", "Select a skill first."))
			return
		end
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local currentLevel = getPlayerSkillLevel(player, definition)
		if currentLevel >= MAX_SKILL_LEVEL then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillAtMax", "Skill already at maximum."))
			return
		end
		local success = applySkillLevel(player, definition, currentLevel + 1)
		if success then
			self:syncSkillUI()
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSkillUpdated", "%1 set to level %2.", tostring(definition.label or definition.id), currentLevel + 1))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillFailed", "Could not update skills."))
		end
	end

	function CheatMenuUI:onSkillDecrease()
		local definition = self:getSelectedSkillDefinition()
		if not definition then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Skills_StatusNoSkill", "Select a skill first."))
			return
		end
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local currentLevel = getPlayerSkillLevel(player, definition)
		if currentLevel <= 0 then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillAtMin", "Skill already at minimum."))
			return
		end
		local success = applySkillLevel(player, definition, currentLevel - 1)
		if success then
			self:syncSkillUI()
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSkillUpdated", "%1 set to level %2.", tostring(definition.label or definition.id), currentLevel - 1))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillFailed", "Could not update skills."))
		end
	end

	function CheatMenuUI:onSkillMaxSelected()
		local definition = self:getSelectedSkillDefinition()
		if not definition then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Skills_StatusNoSkill", "Select a skill first."))
			return
		end
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local success = applySkillLevel(player, definition, MAX_SKILL_LEVEL)
		if success then
			self:syncSkillUI()
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSkillUpdated", "%1 set to level %2.", tostring(definition.label or definition.id), MAX_SKILL_LEVEL))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillFailed", "Could not update skills."))
		end
	end

	function CheatMenuUI:onSkillResetSelected()
		local definition = self:getSelectedSkillDefinition()
		if not definition then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Skills_StatusNoSkill", "Select a skill first."))
			return
		end
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local success = applySkillLevel(player, definition, 0)
		if success then
			self:syncSkillUI()
			self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusSkillUpdated", "%1 set to level %2.", tostring(definition.label or definition.id), 0))
		else
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusSkillFailed", "Could not update skills."))
		end
	end

	function CheatMenuUI:onSkillMaxAll()
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local anySuccess = false
		for _, definition in ipairs(self:getSkillDefinitions()) do
			if applySkillLevel(player, definition, MAX_SKILL_LEVEL) then
				anySuccess = true
			end
		end
		self:syncSkillUI()
		local messageKey = anySuccess and "UI_ZedToolbox_StatusSkillMaxAll" or "UI_ZedToolbox_StatusSkillFailed"
		self:setStatus(anySuccess, CheatMenuText.get(messageKey, anySuccess and "All skills maxed." or "Could not update skills."))
	end

	function CheatMenuUI:onSkillResetAll()
		local player = getPlayerCharacter()
		if not player then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
			return
		end
		local anySuccess = false
		for _, definition in ipairs(self:getSkillDefinitions()) do
			if applySkillLevel(player, definition, 0) then
				anySuccess = true
			end
		end
		self:syncSkillUI()
		local messageKey = anySuccess and "UI_ZedToolbox_StatusSkillResetAll" or "UI_ZedToolbox_StatusSkillFailed"
		self:setStatus(anySuccess, CheatMenuText.get(messageKey, anySuccess and "All skills reset." or "Could not update skills."))
	end
end
