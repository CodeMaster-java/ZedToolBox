return function(CheatMenuUI, deps)
	local clearControl = deps.clearControl
	local getListSelection = deps.getListSelection
	local getItemDisplayName = deps.getItemDisplayName
	local getCategoryLabel = deps.getCategoryLabel
	local lower = deps.lower
	local trim = deps.trim
	local CheatMenuItems = deps.CheatMenuItems
	local CheatMenuText = deps.CheatMenuText
	local CheatMenuSpawner = deps.CheatMenuSpawner

	function CheatMenuUI:refreshCatalog()
		self.catalog = CheatMenuItems.getCatalog()
		self:populateCategories()
		self:applyFilters()
	end

	function CheatMenuUI:populateCategories()
		clearControl(self.categoryList)
		local order = CheatMenuItems.getCategoryOrder()
		local previous = self.selectedCategory
		local added = {}
		for _, category in ipairs(order) do
			if not added[category] then
				self.catalog[category] = self.catalog[category] or {}
				self.categoryList:addItem(getCategoryLabel(category), category)
				added[category] = true
			end
		end
		if not added.Misc then
			self.catalog.Misc = self.catalog.Misc or {}
			self.categoryList:addItem(getCategoryLabel("Misc"), "Misc")
		end
		self.categoryList.selected = 1
		if previous then
			local items = self.categoryList.items or {}
			for index, item in ipairs(items) do
				local value = item.item or item.data
				if value == previous then
					self.categoryList.selected = index
					break
				end
			end
		end
		local first = getListSelection(self.categoryList)
		local initial = first and (first.item or first.data)
		self.selectedCategory = initial or order[1] or "Misc"
	end

	function CheatMenuUI:applyFilters()
		clearControl(self.itemsList)
		local category = self.selectedCategory or "Misc"
		local list = self.catalog[category] or {}
		local query = self:getSearchText()
		for _, entry in ipairs(list) do
			local displayName = getItemDisplayName(entry)
			local nameMatch = query == "" or string.find(lower(displayName), query, 1, true) or string.find(lower(entry.name or ""), query, 1, true)
			local idMatch = query ~= "" and string.find(lower(entry.fullType), query, 1, true)
			if nameMatch or idMatch then
				local label = string.format("%s (%s)", displayName, entry.fullType)
				self.itemsList:addItem(label, entry)
			end
		end
		if #(self.itemsList.items or {}) > 0 then
			self.itemsList.selected = 1
		else
			self.itemsList.selected = 0
		end
		self:onItemSelected()
	end

	function CheatMenuUI:refreshFavoritesUI()
		if not self.favoritesCombo then
			return
		end
		self.favoritesCombo:clear()
		for _, entry in ipairs(self.favorites or {}) do
			local display = getItemDisplayName({ name = entry.label or entry.baseId, fullType = entry.baseId })
			local label = string.format("%s (%s)", display, entry.baseId)
			self.favoritesCombo:addOptionWithData(label, entry)
		end
		if self.favoritesCombo.options and #self.favoritesCombo.options > 0 then
			self.favoritesCombo.selected = 1
		else
			self.favoritesCombo.selected = 0
		end
	end

	function CheatMenuUI:refreshPresetsUI()
		if not self.presetsCombo then
			return
		end
		self.presetsCombo:clear()
		for _, entry in ipairs(self.presets or {}) do
			local label = string.format("%s [%s x%s]", entry.name, entry.baseId, entry.quantity)
			self.presetsCombo:addOptionWithData(label, entry)
		end
		if self.presetsCombo.options and #self.presetsCombo.options > 0 then
			self.presetsCombo.selected = 1
		else
			self.presetsCombo.selected = 0
		end
	end

	function CheatMenuUI:onCategoryChanged()
		local selected = getListSelection(self.categoryList)
		local category = selected and (selected.item or selected.data)
		if category then
			self.selectedCategory = category
			self:applyFilters()
		end
	end

	function CheatMenuUI:onItemSelected()
		local selected = getListSelection(self.itemsList)
		if selected and selected.item then
			self.baseIdBox:setText(selected.item.fullType)
		end
	end

	function CheatMenuUI:selectItemByFullType(fullType)
		if not fullType or not self.itemsList or not self.itemsList.items then
			return
		end
		for index, entry in ipairs(self.itemsList.items) do
			local value = entry.item or entry.data
			if value and value.fullType == fullType then
				self.itemsList.selected = index
				self:onItemSelected()
				return
			end
		end
	end

	function CheatMenuUI:onFilterChanged()
		self:applyFilters()
	end

	function CheatMenuUI:getSearchText()
		return lower(trim(self.searchBox:getInternalText() or ""))
	end

	function CheatMenuUI:getTargetSelection()
		local option = self.targetCombo.options and self.targetCombo.options[self.targetCombo.selected]
		return option and option.data or "inventory"
	end

	function CheatMenuUI:setTargetSelection(target)
		if not self.targetCombo.options then
			return
		end
		for index, option in ipairs(self.targetCombo.options) do
			if option.data == target then
				self.targetCombo.selected = index
				return
			end
		end
		self.targetCombo.selected = 1
	end

	function CheatMenuUI:getSelectedFavorite()
		if not self.favoritesCombo or not self.favoritesCombo.options then
			return nil
		end
		local option = self.favoritesCombo.options[self.favoritesCombo.selected]
		return option and option.data or nil
	end

	function CheatMenuUI:getSelectedPreset()
		if not self.presetsCombo or not self.presetsCombo.options then
			return nil
		end
		local option = self.presetsCombo.options[self.presetsCombo.selected]
		return option and option.data or nil
	end

	function CheatMenuUI:onAddFavorite()
		local baseId = trim(self.baseIdBox:getInternalText() or "")
		if baseId == "" then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusBaseMissing", "Enter a BaseID before saving."))
			return
		end
		self.favorites = self.favorites or {}
		for _, entry in ipairs(self.favorites) do
			if entry.baseId == baseId then
				self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteExists", "Favorite already exists."))
				return
			end
		end
		local selected = getListSelection(self.itemsList)
		local label
		if selected and selected.item and selected.item.fullType == baseId then
			label = selected.item.name
		end
		table.insert(self.favorites, { baseId = baseId, label = label })
		self:refreshFavoritesUI()
		self:flushPersistentData()
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteSaved", "Favorite saved."))
	end

	function CheatMenuUI:onFavoriteSelected()
		local entry = self:getSelectedFavorite()
		if entry then
			self.baseIdBox:setText(entry.baseId)
		end
	end

	function CheatMenuUI:onUseFavorite()
		local entry = self:getSelectedFavorite()
		if not entry then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteMissing", "Select a favorite first."))
			return
		end
		self.baseIdBox:setText(entry.baseId)
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteLoaded", "Favorite applied."))
	end

	function CheatMenuUI:onSpawnFavorite()
		local entry = self:getSelectedFavorite()
		if not entry then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteMissing", "Select a favorite first."))
			return
		end
		local success, message = CheatMenuSpawner.spawn(entry.baseId, self.quantityBox:getInternalText(), self:getTargetSelection())
		self:setStatus(success, message)
	end

	function CheatMenuUI:onRemoveFavorite()
		local entry = self:getSelectedFavorite()
		if not entry then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteMissing", "Select a favorite first."))
			return
		end
		for index, value in ipairs(self.favorites) do
			if value == entry or value.baseId == entry.baseId then
				table.remove(self.favorites, index)
				break
			end
		end
		self:refreshFavoritesUI()
		self:flushPersistentData()
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusFavoriteRemoved", "Favorite removed."))
	end

	function CheatMenuUI:onSavePreset()
		local name = trim(self.presetNameBox:getInternalText())
		local baseId = trim(self.baseIdBox:getInternalText())
		if name == "" or baseId == "" then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusPresetMissing", "Name and BaseID are required."))
			return
		end
		local quantity = tonumber(self.quantityBox:getInternalText()) or 1
		local target = self:getTargetSelection()
		local updated = false
		for _, preset in ipairs(self.presets) do
			if preset.name == name then
				preset.baseId = baseId
				preset.quantity = quantity
				preset.target = target
				updated = true
				break
			end
		end
		if not updated then
			table.insert(self.presets, { name = name, baseId = baseId, quantity = quantity, target = target })
		end
		self:refreshPresetsUI()
		self:flushPersistentData()
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusPresetSaved", "Preset saved."))
	end

	function CheatMenuUI:onPresetSelected()
		local preset = self:getSelectedPreset()
		if preset then
			self.baseIdBox:setText(preset.baseId)
			self.quantityBox:setText(tostring(preset.quantity))
			self:setTargetSelection(preset.target)
		end
	end

	function CheatMenuUI:onApplyPreset()
		local preset = self:getSelectedPreset()
		if not preset then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusPresetMissingSelect", "Select a preset first."))
			return
		end
		self.baseIdBox:setText(preset.baseId)
		self.quantityBox:setText(tostring(preset.quantity))
		self:setTargetSelection(preset.target)
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusPresetLoaded", "Preset applied."))
	end

	function CheatMenuUI:onSpawnPreset()
		local preset = self:getSelectedPreset()
		if not preset then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusPresetMissingSelect", "Select a preset first."))
			return
		end
		local success, message = CheatMenuSpawner.spawn(preset.baseId, preset.quantity, preset.target)
		self:setStatus(success, message)
	end

	function CheatMenuUI:onRemovePreset()
		local preset = self:getSelectedPreset()
		if not preset then
			self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusPresetMissingSelect", "Select a preset first."))
			return
		end
		for index, entry in ipairs(self.presets) do
			if entry == preset or entry.name == preset.name then
				table.remove(self.presets, index)
				break
			end
		end
		self:refreshPresetsUI()
		self:flushPersistentData()
		self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_StatusPresetRemoved", "Preset removed."))
	end

	function CheatMenuUI:onSpawnClicked()
		local baseId = trim(self.baseIdBox:getInternalText() or "")
		local success, message = CheatMenuSpawner.spawn(baseId, self.quantityBox:getInternalText(), self:getTargetSelection())
		self:setStatus(success, message)
	end
end
