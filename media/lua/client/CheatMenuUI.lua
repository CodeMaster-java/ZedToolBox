require "ISUI/ISPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISComboBox"
require "ISUI/ISButton"

local CheatMenuItems = require "CheatMenuItems"
local CheatMenuSpawner = require "CheatMenuSpawner"
local CheatMenuText = require "CheatMenuText"
local CheatMenuLogger = require "CheatMenuLogger"
local CheatMenuUtils = require "CheatMenuUtils"

local CheatMenuUI = ISPanel:derive("CheatMenuUI")

local PANEL_WIDTH = 1100
local PANEL_HEIGHT = 600
local PADDING = 16
local COLUMN_GAP = 14
local LIST_TOP = 86
local TAB_HEIGHT = 28
local TAB_BUTTON_WIDTH = 160
local TAB_GAP = 10
local BOTTOM_HEIGHT = 190
local LEFT_WIDTH = 180
local CENTER_WIDTH = 440
local RIGHT_WIDTH = PANEL_WIDTH - (PADDING * 2) - LEFT_WIDTH - CENTER_WIDTH - (COLUMN_GAP * 2)
local MODDATA_KEY = "ZedToolbox"
local BUTTON_HEIGHT = 22
local BUTTON_GAP = 4
local BUTTON_ROW_GAP = 12
local SECTION_GAP = 16
local PRESET_NAME_HEIGHT = 24
local PRESET_NAME_GAP = 6
local SPAWN_BUTTON_WIDTH = 220
local MIN_FAVORITES_HEIGHT = 140
local MIN_PRESETS_HEIGHT = 120
local SECTION_BG_ALPHA = 0.22
local SECTION_BORDER_ALPHA = 0.38
local BOTTOM_PANEL_PADDING = 14
local PRIMARY_BUTTON_HEIGHT = 34
local REMOVE_BUTTON_EXTRA_GAP = 6
local SEARCH_LABEL_WIDTH = 60
local SEARCH_FIELD_WIDTH = 280
local PRESET_HEADER_GAP = 10
local CREDIT_TEXT = "by CodeMaster"

local HOTKEY_SOURCE = {
    { label = "Insert", code = Keyboard.KEY_INSERT },
    { label = "Delete", code = Keyboard.KEY_DELETE },
    { label = "Home", code = Keyboard.KEY_HOME },
    { label = "End", code = Keyboard.KEY_END },
    { label = "F1", code = Keyboard.KEY_F1 },
    { label = "F2", code = Keyboard.KEY_F2 },
    { label = "F3", code = Keyboard.KEY_F3 },
    { label = "F4", code = Keyboard.KEY_F4 },
    { label = "F5", code = Keyboard.KEY_F5 },
    { label = "F6", code = Keyboard.KEY_F6 },
    { label = "F7", code = Keyboard.KEY_F7 },
    { label = "F8", code = Keyboard.KEY_F8 },
    { label = "F9", code = Keyboard.KEY_F9 },
    { label = "F10", code = Keyboard.KEY_F10 },
    { label = "F11", code = Keyboard.KEY_F11 },
    { label = "F12", code = Keyboard.KEY_F12 },
    { label = "Q", code = Keyboard.KEY_Q },
    { label = "E", code = Keyboard.KEY_E },
    { label = "R", code = Keyboard.KEY_R },
    { label = "T", code = Keyboard.KEY_T },
    { label = "Y", code = Keyboard.KEY_Y },
    { label = "U", code = Keyboard.KEY_U },
    { label = "I", code = Keyboard.KEY_I },
    { label = "O", code = Keyboard.KEY_O },
    { label = "P", code = Keyboard.KEY_P },
    { label = "K", code = Keyboard.KEY_K },
    { label = "L", code = Keyboard.KEY_L },
    { label = "Z", code = Keyboard.KEY_Z },
    { label = "X", code = Keyboard.KEY_X },
    { label = "C", code = Keyboard.KEY_C },
    { label = "V", code = Keyboard.KEY_V },
    { label = "B", code = Keyboard.KEY_B }
}

local HOTKEY_OPTIONS_CACHE = nil

local function clamp(value, min, max)
    value = tonumber(value) or min
    if value < min then return min end
    if value > max then return max end
    return value
end


local function getHotkeyOptions()
    if not HOTKEY_OPTIONS_CACHE then
        HOTKEY_OPTIONS_CACHE = {}
        for _, entry in ipairs(HOTKEY_SOURCE) do
            if type(entry.code) == "number" then
                table.insert(HOTKEY_OPTIONS_CACHE, entry)
            end
        end
    end
    return HOTKEY_OPTIONS_CACHE
end

local function getCheatMenuMain()
    if package and package.loaded then
        local loaded = package.loaded["CheatMenuMain"]
        if type(loaded) == "table" then
            return loaded
        end
    end
    local ok, main = pcall(require, "CheatMenuMain")
    if ok and type(main) == "table" then
        return main
    end
    return nil
end

CheatMenuUI.Width = PANEL_WIDTH
CheatMenuUI.Height = PANEL_HEIGHT

local STATUS_SUCCESS = { r = 0.55, g = 0.85, b = 0.55 }
local STATUS_ERROR = { r = 0.93, g = 0.4, b = 0.4 }

local function lower(text)
    if not text then
        return ""
    end
    return string.lower(text)
end

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function clearControl(control)
    if not control then
        return
    end
    if type(control.clear) == "function" then
        control:clear()
        return
    end
    if type(control.clearItems) == "function" then
        control:clearItems()
        return
    end
    if control.items then
        control.items = {}
    end
    if control.options then
        control.options = {}
    end
    control.selected = 0
    if type(control.setScrollHeight) == "function" then
        control:setScrollHeight(0)
    end
end

local function getListSelection(list)
    if not list or not list.items then
        return nil
    end
    local index = list.selected or 0
    if index < 1 then
        return nil
    end
    return list.items[index]
end

local function getItemDisplayName(entry)
    if not entry then
        return ""
    end
    if entry.localizedName and entry.localizedName ~= "" then
        return entry.localizedName
    end
    if entry.name and entry.name ~= "" then
        return entry.name
    end
    local fullType = entry.fullType or entry.baseId
    if fullType and ScriptManager and ScriptManager.instance then
        local scriptItem = ScriptManager.instance:FindItem(fullType)
        if scriptItem then
            local display = scriptItem.getDisplayName and scriptItem:getDisplayName()
            if display and display ~= "" then
                return display
            end
            local rawName = scriptItem.getName and scriptItem:getName()
            if rawName and rawName ~= "" then
                return rawName
            end
            local fullName = scriptItem.getFullName and scriptItem:getFullName()
            if fullName and fullName ~= "" then
                return fullName
            end
        end
    end
    return tostring(fullType or "")
end

local CATEGORY_LABEL_FALLBACKS = {
    Weapons = "Weapons",
    Ammo = "Ammo",
    Bags = "Bags",
    Food = "Food",
    Medical = "Medical",
    Misc = "Misc"
}

local function getCategoryLabel(category)
    local normalized = CATEGORY_LABEL_FALLBACKS[category] and category or "Misc"
    local fallback = CATEGORY_LABEL_FALLBACKS[normalized] or tostring(category or "Misc")
    local key = string.format("UI_ZedToolbox_Category_%s", normalized)
    return CheatMenuText.get(key, fallback)
end

local CheatMenuTutorialPanel = ISPanel:derive("CheatMenuTutorialPanel")

local function wrapTutorialText(font, text, maxWidth)
    local tm = getTextManager and getTextManager()
    if not tm or maxWidth <= 0 then
        return { text or "" }
    end
    local lines = {}
    local current = ""
    for word in tostring(text or ""):gmatch("%S+") do
        local candidate = current ~= "" and (current .. " " .. word) or word
        if tm:MeasureStringX(font, candidate) > maxWidth and current ~= "" then
            table.insert(lines, current)
            current = word
        else
            current = candidate
        end
    end
    if current ~= "" then
        table.insert(lines, current)
    end
    if #lines == 0 then
        table.insert(lines, "")
    end
    return lines
end

function CheatMenuTutorialPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    o.borderColor = { r = 1, g = 1, b = 1, a = 0 }
    o.padding = 18
    o.scrollY = 0
    o.sections = {}
    o.lines = {}
    o.contentHeight = 0
    return o
end

function CheatMenuTutorialPanel:setWidth(width)
    if width == self.width then
        return
    end
    ISPanel.setWidth(self, width)
    self:rebuild()
end

function CheatMenuTutorialPanel:setHeight(height)
    if height == self.height then
        return
    end
    ISPanel.setHeight(self, height)
    self:rebuild()
end

function CheatMenuTutorialPanel:setSections(sections)
    self.sections = sections or {}
    self.scrollY = 0
    self:rebuild()
end

function CheatMenuTutorialPanel:rebuild()
    local tm = getTextManager and getTextManager()
    local textWidth = math.max(0, self.width - (self.padding * 2))
    local titleFont = UIFont.Medium
    local bodyFont = UIFont.Small
    local titleHeight = tm and tm:MeasureStringY(titleFont, "A") or 20
    local bodyHeight = tm and tm:MeasureStringY(bodyFont, "A") or 18
    self.lines = {}
    self.contentHeight = self.padding

    for index, section in ipairs(self.sections) do
        local title = section.title or ""
        local body = section.body or ""
        if title ~= "" then
            table.insert(self.lines, {
                text = title,
                font = titleFont,
                color = { r = 0.94, g = 0.94, b = 0.94, a = 1 },
                height = titleHeight,
                spacing = 6
            })
            self.contentHeight = self.contentHeight + titleHeight + 6
        end
        if body ~= "" then
            local wrapped = wrapTutorialText(bodyFont, body, textWidth)
            for _, line in ipairs(wrapped) do
                table.insert(self.lines, {
                    text = line,
                    font = bodyFont,
                    color = { r = 0.82, g = 0.82, b = 0.82, a = 1 },
                    height = bodyHeight,
                    spacing = 4
                })
                self.contentHeight = self.contentHeight + bodyHeight + 4
            end
        end
        if index < #self.sections then
            table.insert(self.lines, { text = nil, height = 12, spacing = 6 })
            self.contentHeight = self.contentHeight + 18
        end
    end
    self.contentHeight = math.max(self.contentHeight, self.padding + self.height)
end

function CheatMenuTutorialPanel:onMouseWheel(del)
    if self.contentHeight <= self.height then
        return false
    end
    local step = 40
    self.scrollY = self.scrollY - (del * step)
    if self.scrollY < 0 then
        self.scrollY = 0
    end
    local maxScroll = self.contentHeight - self.height
    if self.scrollY > maxScroll then
        self.scrollY = maxScroll
    end
    return true
end

function CheatMenuTutorialPanel:prerender()
    ISPanel.prerender(self)
    self:setStencilRect(0, 0, self.width, self.height)
    local y = self.padding - self.scrollY
    local x = self.padding
    for _, line in ipairs(self.lines) do
        if line.text and line.font then
            local color = line.color or { r = 0.85, g = 0.85, b = 0.85, a = 1 }
            self:drawText(line.text, x, y, color.r, color.g, color.b, color.a or 1, line.font)
            y = y + line.height + (line.spacing or 0)
        else
            y = y + (line.height or 0) + (line.spacing or 0)
        end
    end
    self:clearStencilRect()
end

function CheatMenuUI:buildTutorialSections()
    local sections = {}
    sections[1] = {
        title = CheatMenuText.get("UI_ZedToolbox_Tutorial_Header", "Guia rápido do Zed Toolbox"),
        body = ""
    }
    local definitions = {
        {
            titleKey = "UI_ZedToolbox_Tutorial_AccessTitle",
            fallbackTitle = "Abrindo o menu",
            bodyKey = "UI_ZedToolbox_Tutorial_AccessBody",
            fallbackBody = "Use a tecla configurada para abrir o Zed Toolbox e escolha a aba desejada no seletor superior para acessar cada conjunto de funções."
        },
        {
            titleKey = "UI_ZedToolbox_Tutorial_ItemsTitle",
            fallbackTitle = "Aba de itens",
            bodyKey = "UI_ZedToolbox_Tutorial_ItemsBody",
            fallbackBody = "Procure por itens, escolha a categoria e use as ações para gerar itens, salvar favoritos ou criar presets para reaplicar configurações rapidamente."
        },
        {
            titleKey = "UI_ZedToolbox_Tutorial_UtilsTitle",
            fallbackTitle = "Aba de utilidades",
            bodyKey = "UI_ZedToolbox_Tutorial_UtilsBody",
            fallbackBody = "Ative truques como God Mode, kill instantâneo, ajustes de velocidade e mantenha seus status sob controle. Use os botões de cura e limpeza de zumbis quando precisar de um respiro."
        },
        {
            titleKey = "UI_ZedToolbox_Tutorial_ConfigTitle",
            fallbackTitle = "Aba de configuração",
            bodyKey = "UI_ZedToolbox_Tutorial_ConfigBody",
            fallbackBody = "Troque o idioma do mod e defina a tecla global para abrir o menu sempre que quiser."
        },
        {
            titleKey = "UI_ZedToolbox_Tutorial_TipsTitle",
            fallbackTitle = "Dicas rápidas",
            bodyKey = "UI_ZedToolbox_Tutorial_TipsBody",
            fallbackBody = "Combine presets e favoritos para montar kits completos, e revise os status exibidos na parte inferior para confirmar cada ação."
        }
    }
    for _, definition in ipairs(definitions) do
        sections[#sections + 1] = {
            title = CheatMenuText.get(definition.titleKey, definition.fallbackTitle),
            body = CheatMenuText.get(definition.bodyKey, definition.fallbackBody)
        }
    end
    return sections
end

function CheatMenuUI:updateTutorialContent()
    if not self.tutorialPanel then
        return
    end
    CheatMenuText.setLanguage(CheatMenuText.getCurrentLanguage())
    self.tutorialPanel:setSections(self:buildTutorialSections())
end

function CheatMenuUI:new(x, y)
    local o = ISPanel:new(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    o:noBackground()
    o.status = { message = "", color = STATUS_SUCCESS }
    o.catalog = {}
    o.selectedCategory = nil
    o.favorites = {}
    o.presets = {}
    o.config = {}
    o.activeTab = "items"
    o.tabSelector = nil
    o.tabButtons = {}
    o.tabDefinitions = {
        { id = "items", labelKey = "UI_ZedToolbox_TabItems", fallback = "Item Spawns" },
        { id = "utils", labelKey = "UI_ZedToolbox_TabUtils", fallback = "Utils" },
        { id = "config", labelKey = "UI_ZedToolbox_TabConfig", fallback = "Config" },
        { id = "tutorial", labelKey = "UI_ZedToolbox_TabTutorial", fallback = "Tutorial" }
    }
    o.tabControls = { items = {}, utils = {}, config = {}, tutorial = {} }
    o.utilsSpeedValues = { 1, 1.5, 2, 3, 4, 5 }
    o.utilsLabelPositions = {}
    o.tutorialPanel = nil
    o.tutorialSection = nil
    return o
end

function CheatMenuUI:addToTab(tabId, control)
    if not control then
        return
    end
    self.tabControls[tabId] = self.tabControls[tabId] or {}
    table.insert(self.tabControls[tabId], control)
end

function CheatMenuUI:populateTabSelector(selectedId)
    if not self.tabSelector then
        return
    end
    local target = selectedId or self.activeTab or "items"
    local fallbackIndex = 1
    if self.tabSelector.clear then
        self.tabSelector:clear()
    end
    for index, definition in ipairs(self.tabDefinitions or {}) do
        local label = CheatMenuText.get(definition.labelKey, definition.fallback)
        if self.tabSelector.addOptionWithData then
            self.tabSelector:addOptionWithData(label, definition.id)
        else
            self.tabSelector:addOption(label)
        end
        if definition.id == target then
            fallbackIndex = index
        end
    end
    self.isUpdatingTabSelector = true
    self.tabSelector.selected = fallbackIndex
    self.isUpdatingTabSelector = false
end

function CheatMenuUI:onTabSelectionChanged(combo)
    if self.isUpdatingTabSelector then
        return
    end
    local source = combo or self.tabSelector
    if not source or not source.options then
        return
    end
    local index = source.selected or 1
    local option = source.options[index]
    local targetId = option and option.data
    if not targetId and self.tabDefinitions then
        local definition = self.tabDefinitions[index]
        targetId = definition and definition.id or targetId
    end
    if targetId and targetId ~= self.activeTab then
        self:setActiveTab(targetId)
    end
end

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

function CheatMenuUI:initialise()
    ISPanel.initialise(self)
    self:createChildren()
    self:refreshCatalog()
    self:loadPersistentData()
    self:refreshFavoritesUI()
    self:refreshPresetsUI()
    self:populateHotkeyOptions(self.config and self.config.toggleKey)
    self:populateLanguageOptions()
    self:applyTranslations()
end

function CheatMenuUI:createChildren()
    ISPanel.createChildren(self)

    self.closeBtn = ISButton:new(self.width - 36, 12, 24, 24, "X", self, CheatMenuUI.onClose)
    self.closeBtn:initialise()
    self.closeBtn:instantiate()
    self:addChild(self.closeBtn)

    local tabX = PADDING
    local tabY = PADDING

    self.tabSelector = ISComboBox:new(tabX, tabY, TAB_BUTTON_WIDTH, TAB_HEIGHT, self, nil)
    self.tabSelector:initialise()
    self.tabSelector:instantiate()
    self.tabSelector.onChange = function()
        self:onTabSelectionChanged()
    end
    self:addChild(self.tabSelector)
    self:populateTabSelector(self.activeTab)

    local searchLabelX = PADDING
    local searchFieldY = tabY + TAB_HEIGHT + TAB_GAP
    local searchFieldX = searchLabelX + SEARCH_LABEL_WIDTH + 8
    local searchWidth = math.min(SEARCH_FIELD_WIDTH, self.width - searchFieldX - PADDING)
    self.searchBox = ISTextEntryBox:new("", searchFieldX, searchFieldY, searchWidth, 22)
    self.searchBox:initialise()
    self.searchBox:instantiate()
    self.searchBox.onTextChange = function()
        self:onFilterChanged()
    end
    self:addChild(self.searchBox)
    self.searchLabelPos = { x = searchLabelX, y = searchFieldY + 3 }
    self:addToTab("items", self.searchBox)

    local listTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
    local listHeight = self.height - listTop - BOTTOM_HEIGHT

    self.categoryList = ISScrollingListBox:new(PADDING, listTop, LEFT_WIDTH, listHeight)
    self.categoryList:initialise()
    self.categoryList:instantiate()
    self.categoryList.itemheight = 24
    self.categoryList.font = UIFont.Small
    self.categoryList.doDrawItem = function(list, y, item)
        local isSelected = list.selected == item.index
        if isSelected then
            list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
        end
        local tint = isSelected and 1 or 0.9
        list:drawText(item.text, 10, y + 5, tint, tint, tint, 1, UIFont.Small)
        return y + item.height
    end
    self.categoryList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        self:onCategoryChanged()
    end
    self:addChild(self.categoryList)
    self:addToTab("items", self.categoryList)

    self.itemsList = ISScrollingListBox:new(PADDING + LEFT_WIDTH + COLUMN_GAP, listTop, CENTER_WIDTH, listHeight)
    self.itemsList:initialise()
    self.itemsList:instantiate()
    self.itemsList.itemheight = 26
    self.itemsList.font = UIFont.Small
    self.itemsList.doDrawItem = function(list, y, item)
        local isSelected = list.selected == item.index
        if isSelected then
            list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
        end
        local tint = isSelected and 1 or 0.9
        list:drawText(item.text, 10, y + 5, tint, tint, tint, 1, UIFont.Small)
        return y + item.height
    end
    self.itemsList.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        self:onItemSelected()
    end
    self.itemsList.onMouseDoubleClick = function()
        self:onSpawnClicked()
    end
    self:addChild(self.itemsList)
    self:addToTab("items", self.itemsList)

    local rightX = PADDING + LEFT_WIDTH + COLUMN_GAP + CENTER_WIDTH + COLUMN_GAP
    local dualColumnGap = COLUMN_GAP * 2
    local favoritesWidth = math.floor((RIGHT_WIDTH - dualColumnGap) / 2)
    local presetsWidth = RIGHT_WIDTH - favoritesWidth - dualColumnGap
    local favoriteButtonRowWidth = math.floor((favoritesWidth - BUTTON_GAP) / 2)
    local presetButtonRowWidth = math.floor((presetsWidth - BUTTON_GAP) / 2)
    local labelOffset = 18

    local favoritesX = rightX
    local presetsX = favoritesX + favoritesWidth + dualColumnGap

    local favoritesSectionTop = listTop - 30
    self.favoritesCombo = ISComboBox:new(favoritesX, listTop, favoritesWidth, 24, self, nil)
    self.favoritesCombo:initialise()
    self.favoritesCombo:instantiate()
    self.favoritesCombo.onChange = function()
        self:onFavoriteSelected()
    end
    self:addChild(self.favoritesCombo)
    self.favoritesLabelPos = { x = favoritesX, y = self.favoritesCombo.y - 18 }
    self:addToTab("items", self.favoritesCombo)

    local favBtnY = self.favoritesCombo.y + self.favoritesCombo.height + BUTTON_ROW_GAP
    self.addFavoriteBtn = ISButton:new(favoritesX, favBtnY, favoriteButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_AddFavorite", "Add Favorite"), self, CheatMenuUI.onAddFavorite)
    self.addFavoriteBtn:initialise()
    self.addFavoriteBtn:instantiate()
    self:addChild(self.addFavoriteBtn)
    self:addToTab("items", self.addFavoriteBtn)

    self.useFavoriteBtn = ISButton:new(favoritesX + favoriteButtonRowWidth + BUTTON_GAP, favBtnY, favoriteButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_UseFavorite", "Use Favorite"), self, CheatMenuUI.onUseFavorite)
    self.useFavoriteBtn:initialise()
    self.useFavoriteBtn:instantiate()
    self:addChild(self.useFavoriteBtn)
    self:addToTab("items", self.useFavoriteBtn)

    local favSecondRowY = favBtnY + BUTTON_HEIGHT + BUTTON_ROW_GAP
    self.spawnFavoriteBtn = ISButton:new(favoritesX, favSecondRowY, favoritesWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SpawnFavorite", "Spawn Favorite"), self, CheatMenuUI.onSpawnFavorite)
    self.spawnFavoriteBtn:initialise()
    self.spawnFavoriteBtn:instantiate()
    self:addChild(self.spawnFavoriteBtn)
    self:addToTab("items", self.spawnFavoriteBtn)

    local favFinalRowY = self.spawnFavoriteBtn.y + self.spawnFavoriteBtn.height + BUTTON_ROW_GAP + REMOVE_BUTTON_EXTRA_GAP
    self.removeFavoriteBtn = ISButton:new(favoritesX, favFinalRowY, favoritesWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_RemoveFavorite", "Remove Favorite"), self, CheatMenuUI.onRemoveFavorite)
    self.removeFavoriteBtn:initialise()
    self.removeFavoriteBtn:instantiate()
    self:addChild(self.removeFavoriteBtn)
    self:addToTab("items", self.removeFavoriteBtn)

    local favoritesSectionBottom = self.removeFavoriteBtn.y + self.removeFavoriteBtn.height + SECTION_GAP
    self.favoritesSection = {
        x = favoritesX - 8,
        y = favoritesSectionTop,
        w = favoritesWidth + 16,
        h = favoritesSectionBottom - favoritesSectionTop
    }

    local presetNameTop = listTop
    self.presetNameBox = ISTextEntryBox:new("", presetsX, presetNameTop, presetsWidth, PRESET_NAME_HEIGHT)
    self.presetNameBox:initialise()
    self.presetNameBox:instantiate()
    self:addChild(self.presetNameBox)
    self:addToTab("items", self.presetNameBox)

    local presetsSectionTop = listTop - 30
    local presetLabelY = self.presetNameBox.y + PRESET_NAME_HEIGHT + PRESET_NAME_GAP
    local presetComboY = presetLabelY + labelOffset
    self.presetsCombo = ISComboBox:new(presetsX, presetComboY, presetsWidth, 24, self, nil)
    self.presetsCombo:initialise()
    self.presetsCombo:instantiate()
    self.presetsCombo.onChange = function()
        self:onPresetSelected()
    end
    self:addChild(self.presetsCombo)
    self.presetsLabelPos = { x = presetsX, y = presetLabelY }
    self:addToTab("items", self.presetsCombo)

    local presetBtnY = self.presetsCombo.y + self.presetsCombo.height + BUTTON_GAP
    self.savePresetBtn = ISButton:new(presetsX, presetBtnY, presetButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SavePreset", "Save Preset"), self, CheatMenuUI.onSavePreset)
    self.savePresetBtn:initialise()
    self.savePresetBtn:instantiate()
    self:addChild(self.savePresetBtn)
    self:addToTab("items", self.savePresetBtn)

    self.applyPresetBtn = ISButton:new(presetsX + presetButtonRowWidth + BUTTON_GAP, presetBtnY, presetButtonRowWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_ApplyPreset", "Apply Preset"), self, CheatMenuUI.onApplyPreset)
    self.applyPresetBtn:initialise()
    self.applyPresetBtn:instantiate()
    self:addChild(self.applyPresetBtn)
    self:addToTab("items", self.applyPresetBtn)

    local presetSecondRowY = presetBtnY + BUTTON_HEIGHT + BUTTON_ROW_GAP
    self.spawnPresetBtn = ISButton:new(presetsX, presetSecondRowY, presetsWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SpawnPreset", "Spawn Preset"), self, CheatMenuUI.onSpawnPreset)
    self.spawnPresetBtn:initialise()
    self.spawnPresetBtn:instantiate()
    self:addChild(self.spawnPresetBtn)
    self:addToTab("items", self.spawnPresetBtn)

    local presetFinalRowY = self.spawnPresetBtn.y + self.spawnPresetBtn.height + BUTTON_ROW_GAP + REMOVE_BUTTON_EXTRA_GAP
    self.removePresetBtn = ISButton:new(presetsX, presetFinalRowY, presetsWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_RemovePreset", "Remove Preset"), self, CheatMenuUI.onRemovePreset)
    self.removePresetBtn:initialise()
    self.removePresetBtn:instantiate()
    self:addChild(self.removePresetBtn)
    self:addToTab("items", self.removePresetBtn)

    local presetsSectionBottom = self.removePresetBtn.y + self.removePresetBtn.height + SECTION_GAP
    self.presetsSection = {
        x = presetsX - 8,
        y = presetsSectionTop,
        w = presetsWidth + 16,
        h = presetsSectionBottom - presetsSectionTop
    }

    local bottomTop = self.height - BOTTOM_HEIGHT + PADDING
    local bottomInnerX = PADDING + BOTTOM_PANEL_PADDING
    local bottomInnerWidth = self.width - (2 * PADDING) - (BOTTOM_PANEL_PADDING * 2)
    local bottomInnerY = bottomTop + BOTTOM_PANEL_PADDING
    local fieldGap = 12

    local baseInputY = bottomInnerY + labelOffset
    local baseIdWidth = math.max(280, bottomInnerWidth - SPAWN_BUTTON_WIDTH - 32)
    self.baseIdBox = ISTextEntryBox:new("", bottomInnerX, baseInputY, baseIdWidth, 26)
    self.baseIdBox:initialise()
    self.baseIdBox:instantiate()
    self:addChild(self.baseIdBox)
    self:addToTab("items", self.baseIdBox)

    local nextRowTop = self.baseIdBox.y + self.baseIdBox.height + fieldGap
    local quantityY = nextRowTop + labelOffset
    local quantityWidth = 130
    self.quantityBox = ISTextEntryBox:new("1", bottomInnerX, quantityY, quantityWidth, 26)
    self.quantityBox:initialise()
    self.quantityBox:instantiate()
    self.quantityBox:setOnlyNumbers(true)
    self:addChild(self.quantityBox)
    self:addToTab("items", self.quantityBox)

    local targetGap = 18
    local targetX = self.quantityBox.x + quantityWidth + targetGap
    local targetWidth = math.max(220, bottomInnerWidth - quantityWidth - targetGap)
    self.targetCombo = ISComboBox:new(targetX, quantityY, targetWidth, 26, self, nil)
    self.targetCombo:initialise()
    self.targetCombo:instantiate()
    self:addChild(self.targetCombo)
    self:addToTab("items", self.targetCombo)

    local spawnX = self.baseIdBox.x + self.baseIdBox.width + 16
    local spawnY = self.baseIdBox.y - 2
    self.spawnBtn = ISButton:new(spawnX, spawnY, SPAWN_BUTTON_WIDTH, PRIMARY_BUTTON_HEIGHT + 4, CheatMenuText.get("UI_ZedToolbox_Spawn", "Spawn"), self, CheatMenuUI.onSpawnClicked)
    self.spawnBtn:initialise()
    self.spawnBtn:instantiate()
    self:addChild(self.spawnBtn)
    self:addToTab("items", self.spawnBtn)

    local bottomContentBottom = math.max(self.spawnBtn.y + self.spawnBtn.height, self.targetCombo.y + self.targetCombo.height)
    local bottomSectionBottom = bottomContentBottom + BOTTOM_PANEL_PADDING
    self.bottomSection = {
        x = PADDING,
        y = bottomTop,
        w = self.width - (2 * PADDING),
        h = bottomSectionBottom - bottomTop
    }

    local utilsSectionTop = listTop - 30
    local utilsComboWidth = 240
    local utilsSpacing = 48
    local utilsX = PADDING

    local godModeY = listTop
    self.utilsLabelPositions.godMode = { x = utilsX, y = godModeY - 18 }
    self.godModeCombo = ISComboBox:new(utilsX, godModeY, utilsComboWidth, 24, self, nil)
    self.godModeCombo:initialise()
    self.godModeCombo:instantiate()
    self.godModeCombo.onChange = function()
        self:onGodModeChanged()
    end
    self:addChild(self.godModeCombo)
    self:addToTab("utils", self.godModeCombo)

    local hitKillY = godModeY + utilsSpacing
    self.utilsLabelPositions.hitKill = { x = utilsX, y = hitKillY - 18 }
    self.hitKillCombo = ISComboBox:new(utilsX, hitKillY, utilsComboWidth, 24, self, nil)
    self.hitKillCombo:initialise()
    self.hitKillCombo:instantiate()
    self.hitKillCombo.onChange = function()
        self:onHitKillChanged()
    end
    self:addChild(self.hitKillCombo)
    self:addToTab("utils", self.hitKillCombo)

    local infiniteY = hitKillY + utilsSpacing
    self.utilsLabelPositions.infiniteStamina = { x = utilsX, y = infiniteY - 18 }
    self.infiniteStaminaCombo = ISComboBox:new(utilsX, infiniteY, utilsComboWidth, 24, self, nil)
    self.infiniteStaminaCombo:initialise()
    self.infiniteStaminaCombo:instantiate()
    self.infiniteStaminaCombo.onChange = function()
        self:onInfiniteStaminaChanged()
    end
    self:addChild(self.infiniteStaminaCombo)
    self:addToTab("utils", self.infiniteStaminaCombo)

    local instantBuildY = infiniteY + utilsSpacing
    self.utilsLabelPositions.instantBuild = { x = utilsX, y = instantBuildY - 18 }
    self.instantBuildCombo = ISComboBox:new(utilsX, instantBuildY, utilsComboWidth, 24, self, nil)
    self.instantBuildCombo:initialise()
    self.instantBuildCombo:instantiate()
    self.instantBuildCombo.onChange = function()
        self:onInstantBuildChanged()
    end
    self:addChild(self.instantBuildCombo)
    self:addToTab("utils", self.instantBuildCombo)

    local noNegativeY = instantBuildY + utilsSpacing
    self.utilsLabelPositions.noNegativeEffects = { x = utilsX, y = noNegativeY - 18 }
    self.noNegativeEffectsCombo = ISComboBox:new(utilsX, noNegativeY, utilsComboWidth, 24, self, nil)
    self.noNegativeEffectsCombo:initialise()
    self.noNegativeEffectsCombo:instantiate()
    self.noNegativeEffectsCombo.onChange = function()
        self:onNoNegativeEffectsChanged()
    end
    self:addChild(self.noNegativeEffectsCombo)
    self:addToTab("utils", self.noNegativeEffectsCombo)

    local noHungerY = noNegativeY + utilsSpacing
    self.utilsLabelPositions.noHungerThirst = { x = utilsX, y = noHungerY - 18 }
    self.noHungerThirstCombo = ISComboBox:new(utilsX, noHungerY, utilsComboWidth, 24, self, nil)
    self.noHungerThirstCombo:initialise()
    self.noHungerThirstCombo:instantiate()
    self.noHungerThirstCombo.onChange = function()
        self:onNoHungerThirstChanged()
    end
    self:addChild(self.noHungerThirstCombo)
    self:addToTab("utils", self.noHungerThirstCombo)

    local speedY = noHungerY + utilsSpacing
    self.utilsLabelPositions.speed = { x = utilsX, y = speedY - 18 }
    self.speedCombo = ISComboBox:new(utilsX, speedY, utilsComboWidth, 24, self, nil)
    self.speedCombo:initialise()
    self.speedCombo:instantiate()
    self.speedCombo.onChange = function()
        self:onSpeedChanged()
    end
    self:addChild(self.speedCombo)
    self:addToTab("utils", self.speedCombo)

    local healY = speedY + utilsSpacing + 6
    self.healButton = ISButton:new(utilsX, healY, 180, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Utils_Heal", "Heal Player"), self, CheatMenuUI.onHealClicked)
    self.healButton:initialise()
    self.healButton:instantiate()
    self:addChild(self.healButton)
    self:addToTab("utils", self.healButton)

    local clearY = healY + BUTTON_HEIGHT + BUTTON_GAP
    local clearRadius = (CheatMenuUtils.getState() and CheatMenuUtils.getState().clearRadius) or 15
    local clearLabel = CheatMenuText.get("UI_ZedToolbox_Utils_ClearZombiesLabel", "Clear Nearby Zombies (%1 tiles)", clearRadius)
    self.clearZombiesButton = ISButton:new(utilsX, clearY, utilsComboWidth, BUTTON_HEIGHT, clearLabel, self, CheatMenuUI.onClearZombiesClicked)
    self.clearZombiesButton:initialise()
    self.clearZombiesButton:instantiate()
    self:addChild(self.clearZombiesButton)
    self:addToTab("utils", self.clearZombiesButton)

    local utilsSectionBottom = self.clearZombiesButton.y + self.clearZombiesButton.height + 40
    self.utilsSection = {
        x = utilsX - 8,
        y = utilsSectionTop,
        w = self.width - (2 * PADDING) + 16,
        h = utilsSectionBottom - utilsSectionTop
    }

    local configContentTop = listTop
    local configComboWidth = 220
    self.languageLabelPos = { x = PADDING, y = configContentTop - 18 }
    self.languageCombo = ISComboBox:new(PADDING, configContentTop, configComboWidth, 24, self, nil)
    self.languageCombo:initialise()
    self.languageCombo:instantiate()
    self:addChild(self.languageCombo)
    self:addToTab("config", self.languageCombo)

    local applyBtnX = PADDING + configComboWidth + BUTTON_GAP
    self.applyLanguageBtn = ISButton:new(applyBtnX, configContentTop, 120, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Apply", "Apply"), self, CheatMenuUI.onApplyLanguage)
    self.applyLanguageBtn:initialise()
    self.applyLanguageBtn:instantiate()
    self:addChild(self.applyLanguageBtn)
    self:addToTab("config", self.applyLanguageBtn)

    local hotkeyY = configContentTop + 44
    self.hotkeyLabelPos = { x = PADDING, y = hotkeyY - 18 }
    self.hotkeyCombo = ISComboBox:new(PADDING, hotkeyY, configComboWidth, 24, self, nil)
    self.hotkeyCombo:initialise()
    self.hotkeyCombo:instantiate()
    self:addChild(self.hotkeyCombo)
    self:addToTab("config", self.hotkeyCombo)

    self.applyHotkeyBtn = ISButton:new(applyBtnX, hotkeyY, 120, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_SetHotkey", "Set Key"), self, CheatMenuUI.onApplyHotkey)
    self.applyHotkeyBtn:initialise()
    self.applyHotkeyBtn:instantiate()
    self:addChild(self.applyHotkeyBtn)
    self:addToTab("config", self.applyHotkeyBtn)

    local tutorialTop = listTop - 30
    local tutorialHeight = self.height - tutorialTop - PADDING
    self.tutorialPanel = CheatMenuTutorialPanel:new(PADDING, tutorialTop, self.width - (PADDING * 2), tutorialHeight)
    self:addChild(self.tutorialPanel)
    self:addToTab("tutorial", self.tutorialPanel)

    self.tutorialSection = {
        x = self.tutorialPanel.x - 8,
        y = tutorialTop,
        w = self.tutorialPanel.width + 16,
        h = tutorialHeight
    }

    self:updateTutorialContent()
    self:setActiveTab(self.activeTab)
end

function CheatMenuUI:getModData()
    local data = ModData.getOrCreate(MODDATA_KEY)
    data.favorites = data.favorites or {}
    data.presets = data.presets or {}
    data.config = data.config or {}
    return data
end

function CheatMenuUI:loadPersistentData()
    local data = self:getModData()
    self.favorites = data.favorites
    self.presets = data.presets
    self.config = data.config or {}
    local needsFlush = false
    local utilsChanged = self:ensureUtilsConfig()
    if utilsChanged then
        needsFlush = true
    end
    local toggleKey = tonumber(self.config.toggleKey)
    if not toggleKey then
        toggleKey = self:getDefaultToggleKey()
        self.config.toggleKey = toggleKey
        needsFlush = true
    end
    local main = getCheatMenuMain()
    if main and type(main.setToggleKey) == "function" then
        main.setToggleKey(toggleKey)
    end
    local preferredLanguage = self.config.language or CheatMenuText.getCurrentLanguage() or CheatMenuText.getDefaultLanguage()
    CheatMenuText.setLanguage(preferredLanguage)
    self.config.language = CheatMenuText.getCurrentLanguage()
    if needsFlush then
        self:flushPersistentData()
    end
end

function CheatMenuUI:getDefaultToggleKey()
    local main = getCheatMenuMain()
    if main and type(main.Config) == "table" and type(main.Config.toggleKey) == "number" then
        return main.Config.toggleKey
    end
    return Keyboard.KEY_INSERT
end

function CheatMenuUI:setActiveTab(tabId)
    local target = tabId or "items"
    if not self.tabControls[target] then
        target = "items"
    end
    self.activeTab = target

    for id, controls in pairs(self.tabControls) do
        local visible = id == target
        for _, control in ipairs(controls) do
            if control.setVisible then
                control:setVisible(visible)
            else
                control.visible = visible
            end
            if control.clearStencil then
                control:clearStencil()
            end
        end
    end

    if self.tabSelector then
        self:populateTabSelector(target)
    end
end

function CheatMenuUI:onTabButtonClicked(button)
    if not button or not button.internal then
        return
    end
    if button.internal ~= self.activeTab then
        self:setActiveTab(button.internal)
    end
end

function CheatMenuUI:onApplyLanguage()
    if not self.languageCombo or not self.languageCombo.options then
        return
    end
    local option = self.languageCombo.options[self.languageCombo.selected]
    if not option or not option.data then
        self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusLanguageMissing", "Select a language first."))
        return
    end
    local previous = self.config and self.config.language or CheatMenuText.getCurrentLanguage()
    CheatMenuText.setLanguage(option.data)
    self.config = self.config or {}
    self.config.language = CheatMenuText.getCurrentLanguage()
    self:flushPersistentData()
    self:populateLanguageOptions(self.config.language)
    local selectedItem = getListSelection(self.itemsList)
    local selectedFullType = selectedItem and selectedItem.item and selectedItem.item.fullType or nil
    CheatMenuItems.refresh()
    self:refreshCatalog()
    if selectedFullType then
        self:selectItemByFullType(selectedFullType)
    end
    self:refreshFavoritesUI()
    self:refreshPresetsUI()
    self:applyTranslations()
    local changed = self.config.language ~= previous
    local messageKey = changed and "UI_ZedToolbox_StatusLanguageApplied" or "UI_ZedToolbox_StatusLanguageApplied"
    self:setStatus(true, CheatMenuText.get(messageKey, "Language updated."))
end

function CheatMenuUI:onApplyHotkey()
    if not self.hotkeyCombo or not self.hotkeyCombo.options then
        return
    end
    local option = self.hotkeyCombo.options[self.hotkeyCombo.selected]
    if not option or not option.data then
        self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_StatusHotkeyMissing", "Select a key first."))
        return
    end
    local keyCode = option.data
    self.config = self.config or {}
    local changed = self.config.toggleKey ~= keyCode
    self.config.toggleKey = keyCode
    self:flushPersistentData()
    local main = getCheatMenuMain()
    if main and type(main.setToggleKey) == "function" then
        main.setToggleKey(keyCode)
    end
    self:populateHotkeyOptions(keyCode)
    local messageKey = changed and "UI_ZedToolbox_StatusHotkeyApplied" or "UI_ZedToolbox_StatusHotkeyApplied"
    self:setStatus(true, CheatMenuText.get(messageKey, "Hotkey updated."))
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

function CheatMenuUI:populateLanguageOptions(selectedId)
    if not self.languageCombo then
        return
    end
    local targetId = selectedId or (self.config and self.config.language) or CheatMenuText.getCurrentLanguage()
    local options = CheatMenuText.getLanguages()
    self.languageCombo:clear()
    local fallbackIndex = 1
    for index, entry in ipairs(options) do
        self.languageCombo:addOptionWithData(entry.label, entry.id)
        if entry.id == targetId then
            fallbackIndex = index
        end
    end
    self.languageCombo.selected = fallbackIndex
end

function CheatMenuUI:populateHotkeyOptions(selectedKey)
    if not self.hotkeyCombo then
        return
    end
    local targetKey = tonumber(selectedKey) or tonumber(self.config and self.config.toggleKey) or self:getDefaultToggleKey()
    self.hotkeyCombo:clear()
    local index = 1
    local fallbackIndex = 1
    for _, option in ipairs(getHotkeyOptions()) do
        self.hotkeyCombo:addOptionWithData(option.label, option.code)
        if option.code == targetKey then
            fallbackIndex = index
        end
        index = index + 1
    end
    self.hotkeyCombo.selected = fallbackIndex
end

function CheatMenuUI:refreshTargetCombo()
    if not self.targetCombo then
        return
    end
    local previous = self:getTargetSelection()
    self.targetCombo:clear()
    self.targetCombo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_TargetInventory", "Inventory"), "inventory")
    self.targetCombo:addOptionWithData(CheatMenuText.get("UI_ZedToolbox_TargetGround", "Ground"), "ground")
    self:setTargetSelection(previous)
end

function CheatMenuUI:applyTranslations()
    self:populateTabSelector(self.activeTab)
    if self.addFavoriteBtn then
        self.addFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_AddFavorite", "Add Favorite"))
    end
    if self.useFavoriteBtn then
        self.useFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_UseFavorite", "Use Favorite"))
    end
    if self.spawnFavoriteBtn then
        self.spawnFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SpawnFavorite", "Spawn Favorite"))
    end
    if self.removeFavoriteBtn then
        self.removeFavoriteBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_RemoveFavorite", "Remove Favorite"))
    end
    if self.savePresetBtn then
        self.savePresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SavePreset", "Save Preset"))
    end
    if self.applyPresetBtn then
        self.applyPresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_ApplyPreset", "Apply Preset"))
    end
    if self.spawnPresetBtn then
        self.spawnPresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SpawnPreset", "Spawn Preset"))
    end
    if self.removePresetBtn then
        self.removePresetBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_RemovePreset", "Remove Preset"))
    end
    if self.spawnBtn then
        self.spawnBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Spawn", "Spawn"))
    end
    if self.applyLanguageBtn then
        self.applyLanguageBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_Apply", "Apply"))
    end
    if self.applyHotkeyBtn then
        self.applyHotkeyBtn:setTitle(CheatMenuText.get("UI_ZedToolbox_SetHotkey", "Set Key"))
    end
    if self.healButton then
        self.healButton:setTitle(CheatMenuText.get("UI_ZedToolbox_Utils_Heal", "Heal Player"))
    end
    if self.clearZombiesButton then
        self.clearZombiesButton:setTitle(CheatMenuText.get("UI_ZedToolbox_Utils_ClearZombies", "Clear Nearby Zombies"))
    end
    self:updateTutorialContent()
    self:refreshTargetCombo()
    self:refreshCategoryLabels()
    self:populateUtilsOptions()
    self:populateLanguageOptions(self.config and self.config.language)
    self:populateHotkeyOptions(self.config and self.config.toggleKey)
    self:syncUtilsUI()
end

function CheatMenuUI:refreshCategoryLabels()
    if not self.categoryList or not self.categoryList.items then
        return
    end
    for _, item in ipairs(self.categoryList.items) do
        if item and item.item then
            item.text = getCategoryLabel(item.item)
        end
    end
end

function CheatMenuUI:flushPersistentData()
    local data = self:getModData()
    data.favorites = self.favorites
    data.presets = self.presets
    data.config = self.config
    if ModData.transmit then
        ModData.transmit(MODDATA_KEY)
    end
end

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

function CheatMenuUI:setStatus(success, message)
    self.status.message = message or ""
    self.status.color = success and STATUS_SUCCESS or STATUS_ERROR
end

function CheatMenuUI:show()
    self:setVisible(true)
    self:bringToTop()
    self:refreshCatalog()
    self:loadPersistentData()
    self:refreshFavoritesUI()
    self:refreshPresetsUI()
    self:populateLanguageOptions(self.config and self.config.language)
    self:populateHotkeyOptions(self.config and self.config.toggleKey)
    self:applyTranslations()
    self:setActiveTab(self.activeTab)
    if self.activeTab == "items" then
        self.searchBox:focus()
    end
end

function CheatMenuUI:close()
    self:setVisible(false)
    self:clearStatus()
end

function CheatMenuUI:clearStatus()
    self.status.message = ""
end

function CheatMenuUI:onClose()
    self:close()
end

function CheatMenuUI:prerender()
    ISPanel.prerender(self)
    self:drawRect(0, 0, self.width, self.height, 0.92, 0, 0, 0)
    self:drawRectBorder(0, 0, self.width, self.height, 0.9, 0.8, 0.8, 0.8)

    local function drawSection(panel, section)
        if not section then
            return
        end
        panel:drawRect(section.x, section.y, section.w, section.h, SECTION_BG_ALPHA, 0, 0, 0)
        panel:drawRectBorder(section.x, section.y, section.w, section.h, SECTION_BORDER_ALPHA, 0.6, 0.6, 0.6)
    end

    if self.activeTab == "items" then
        drawSection(self, self.favoritesSection)
        drawSection(self, self.presetsSection)
        drawSection(self, self.bottomSection)
    elseif self.activeTab == "utils" then
        drawSection(self, self.utilsSection)
    elseif self.activeTab == "tutorial" then
        drawSection(self, self.tutorialSection)
    end

    if self.status.message ~= "" then
        self:drawText(self.status.message, PADDING, self.height - 36, self.status.color.r, self.status.color.g, self.status.color.b, 1, UIFont.Small)
    end

    self:drawTextRight(CREDIT_TEXT, self.width - PADDING, self.height - 20, 0.7, 0.7, 0.7, 1, UIFont.Small)

    self:drawTextCentre(CheatMenuText.get("UI_ZedToolbox_Title", "Zed Tool"), self.width / 2, 12, 1, 1, 1, 1, UIFont.Medium)
    if self.activeTab == "items" and self.searchLabelPos then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Search", "Search"), self.searchLabelPos.x, self.searchLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "items" then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Categories", "Categories"), self.categoryList.x, self.categoryList.y - 20, 0.8, 0.8, 0.8, 1, UIFont.Small)
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Items", "Items"), self.itemsList.x, self.itemsList.y - 20, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "items" and self.favoritesLabelPos then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Favorites", "Favorites"), self.favoritesLabelPos.x, self.favoritesLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "items" then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_PresetName", "Preset Name"), self.presetNameBox.x, self.presetNameBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "items" and self.presetsLabelPos then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Presets", "Presets"), self.presetsLabelPos.x, self.presetsLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "items" then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_BaseId", "Base ID"), self.baseIdBox.x, self.baseIdBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Quantity", "Quantity"), self.quantityBox.x, self.quantityBox.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Target", "Target"), self.targetCombo.x, self.targetCombo.y - 18, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.godMode then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_GodMode", "God Mode"), self.utilsLabelPositions.godMode.x, self.utilsLabelPositions.godMode.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.hitKill then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_HitKill", "Hit Kill"), self.utilsLabelPositions.hitKill.x, self.utilsLabelPositions.hitKill.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.infiniteStamina then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_InfiniteStamina", "Infinite Stamina"), self.utilsLabelPositions.infiniteStamina.x, self.utilsLabelPositions.infiniteStamina.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.instantBuild then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_InstantBuild", "Instant Build"), self.utilsLabelPositions.instantBuild.x, self.utilsLabelPositions.instantBuild.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.noNegativeEffects then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_NoNegativeEffects", "No Negative Effects"), self.utilsLabelPositions.noNegativeEffects.x, self.utilsLabelPositions.noNegativeEffects.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.noHungerThirst then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_NoHungerThirst", "No Hunger & Thirst"), self.utilsLabelPositions.noHungerThirst.x, self.utilsLabelPositions.noHungerThirst.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "utils" and self.utilsLabelPositions.speed then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_Utils_Speed", "Speed"), self.utilsLabelPositions.speed.x, self.utilsLabelPositions.speed.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "config" and self.languageLabelPos then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_ConfigLanguage", "Language"), self.languageLabelPos.x, self.languageLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    if self.activeTab == "config" and self.hotkeyLabelPos then
        self:drawText(CheatMenuText.get("UI_ZedToolbox_ConfigHotkey", "Toggle Hotkey"), self.hotkeyLabelPos.x, self.hotkeyLabelPos.y, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
end

local GUARD_METHODS = {
    "onCategoryChanged",
    "onItemSelected",
    "onFilterChanged",
    "onFavoriteSelected",
    "onAddFavorite",
    "onUseFavorite",
    "onSpawnFavorite",
    "onRemoveFavorite",
    "onSavePreset",
    "onPresetSelected",
    "onApplyPreset",
    "onSpawnPreset",
    "onRemovePreset",
    "onApplyHotkey",
    "onSpawnClicked",
    "onGodModeChanged",
    "onHitKillChanged",
    "onInfiniteStaminaChanged",
    "onInstantBuildChanged",
    "onNoNegativeEffectsChanged",
    "onNoHungerThirstChanged",
    "onSpeedChanged",
    "onHealClicked",
    "onClearZombiesClicked"
}

for _, methodName in ipairs(GUARD_METHODS) do
    CheatMenuLogger.wrap(CheatMenuUI, methodName, "UI." .. methodName)
end

return CheatMenuUI