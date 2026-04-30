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

local attachItemsSection = require "ui/CheatMenuUI_Items"
local attachUtilsSection = require "ui/CheatMenuUI_Utils"
local attachSkillsSection = require "ui/CheatMenuUI_Skills"
local attachMoodlesSection = require "ui/CheatMenuUI_Moodles"
local attachZombiesSection = require "ui/CheatMenuUI_Zombies"
local attachWorldSection = require "ui/CheatMenuUI_World"
local attachTraitsSection = require "ui/CheatMenuUI_Traits"
local attachProfilesSection = require "ui/CheatMenuUI_Profiles"
local attachLifecycleSection = require "ui/helpers/CheatMenuUI_Lifecycle"
local Helpers = require "ui/helpers/CheatMenuUI_Helpers"

local CheatMenuUI = ISPanel:derive("CheatMenuUI")

local PANEL_WIDTH  = 1100
local PANEL_HEIGHT = 600
local PADDING      = 20
local COLUMN_GAP   = 14
local LIST_TOP     = 86
local TAB_HEIGHT        = 28
local TAB_BTN_GAP       = 4
local TAB_GAP           = 10
local BOTTOM_HEIGHT     = 190
local LEFT_WIDTH    = 180
local CENTER_WIDTH  = 440
local RIGHT_WIDTH   = PANEL_WIDTH - (PADDING * 2) - LEFT_WIDTH - CENTER_WIDTH - (COLUMN_GAP * 2)
local MODDATA_KEY   = "ZedToolbox"

local BUTTON_HEIGHT         = 28
local BUTTON_GAP            = 8
local BUTTON_ROW_GAP        = 16
local SECTION_GAP           = 22
local PRESET_NAME_HEIGHT    = 26
local PRESET_NAME_GAP       = 8
local SPAWN_BUTTON_WIDTH    = 220
local MIN_FAVORITES_HEIGHT  = 140
local MIN_PRESETS_HEIGHT    = 120
local BOTTOM_PANEL_PADDING  = 18
local PRIMARY_BUTTON_HEIGHT = 38
local REMOVE_BUTTON_EXTRA_GAP = 8
local SEARCH_LABEL_WIDTH    = 60
local SEARCH_FIELD_WIDTH    = 280
local PRESET_HEADER_GAP     = 12
local CREDIT_TEXT           = "by CodeMaster"

local SECTION_BG_ALPHA     = 0.28
local SECTION_BORDER_ALPHA = 0.55

local ACCENT         = { r = 0.78, g = 0.66, b = 0.29 }
local LABEL_COLOR    = { r = 0.85, g = 0.85, b = 0.85 }
local LABEL_DIM_COLOR = { r = 0.58, g = 0.58, b = 0.58 }
local SELECTION_COLOR = { r = 0.22, g = 0.42, b = 0.18 }

CheatMenuUI.Width  = PANEL_WIDTH
CheatMenuUI.Height = PANEL_HEIGHT

local STATUS_SUCCESS = { r = 0.45, g = 0.82, b = 0.45 }
local STATUS_WARNING = { r = 0.93, g = 0.75, b = 0.25 }
local STATUS_ERROR   = { r = 0.93, g = 0.38, b = 0.38 }
local clamp = Helpers.clamp
local getHotkeyOptions = Helpers.getHotkeyOptions
local getCheatMenuMain = Helpers.getCheatMenuMain
local lower = Helpers.lower
local trim = Helpers.trim
local clearControl = Helpers.clearControl
local getListSelection = Helpers.getListSelection
local getItemDisplayName = Helpers.getItemDisplayName
local getCategoryLabel = Helpers.getCategoryLabel
local MAX_SKILL_LEVEL = Helpers.MAX_SKILL_LEVEL
local DEFAULT_SKILL_ENTRIES = Helpers.DEFAULT_SKILL_ENTRIES
local getPlayerCharacter = Helpers.getPlayerCharacter
local buildSkillDefinitions = Helpers.buildSkillDefinitions
local clampSkillLevel = Helpers.clampSkillLevel
local getPlayerSkillLevel = Helpers.getPlayerSkillLevel
local applySkillLevel = Helpers.applySkillLevel

local LIFECYCLE_CONSTANTS = {
    PADDING             = PADDING,
    COLUMN_GAP          = COLUMN_GAP,
    LIST_TOP            = LIST_TOP,
    TAB_HEIGHT          = TAB_HEIGHT,
    TAB_BTN_GAP         = TAB_BTN_GAP,
    TAB_GAP             = TAB_GAP,
    BOTTOM_HEIGHT       = BOTTOM_HEIGHT,
    LEFT_WIDTH          = LEFT_WIDTH,
    CENTER_WIDTH        = CENTER_WIDTH,
    RIGHT_WIDTH         = RIGHT_WIDTH,
    MODDATA_KEY         = MODDATA_KEY,
    BUTTON_HEIGHT       = BUTTON_HEIGHT,
    BUTTON_GAP          = BUTTON_GAP,
    BUTTON_ROW_GAP      = BUTTON_ROW_GAP,
    SECTION_GAP         = SECTION_GAP,
    PRESET_NAME_HEIGHT  = PRESET_NAME_HEIGHT,
    PRESET_NAME_GAP     = PRESET_NAME_GAP,
    SPAWN_BUTTON_WIDTH  = SPAWN_BUTTON_WIDTH,
    MIN_FAVORITES_HEIGHT    = MIN_FAVORITES_HEIGHT,
    MIN_PRESETS_HEIGHT      = MIN_PRESETS_HEIGHT,
    SECTION_BG_ALPHA        = SECTION_BG_ALPHA,
    SECTION_BORDER_ALPHA    = SECTION_BORDER_ALPHA,
    BOTTOM_PANEL_PADDING    = BOTTOM_PANEL_PADDING,
    PRIMARY_BUTTON_HEIGHT   = PRIMARY_BUTTON_HEIGHT,
    REMOVE_BUTTON_EXTRA_GAP = REMOVE_BUTTON_EXTRA_GAP,
    SEARCH_LABEL_WIDTH  = SEARCH_LABEL_WIDTH,
    SEARCH_FIELD_WIDTH  = SEARCH_FIELD_WIDTH,
    PRESET_HEADER_GAP   = PRESET_HEADER_GAP,
    CREDIT_TEXT         = CREDIT_TEXT,
    ACCENT              = ACCENT,
    LABEL_COLOR         = LABEL_COLOR,
    LABEL_DIM_COLOR     = LABEL_DIM_COLOR,
    SELECTION_COLOR     = SELECTION_COLOR,
    STATUS_SUCCESS      = STATUS_SUCCESS,
    STATUS_WARNING      = STATUS_WARNING,
    STATUS_ERROR        = STATUS_ERROR,
}

function CheatMenuUI:new(x, y)
    local o = ISPanel:new(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.moveWithMouse = true
    o:noBackground()
    o.status = { message = "", color = LABEL_DIM_COLOR }
    o.catalog = {}
    o.selectedCategory = nil
    o.favorites = {}
    o.presets = {}
    o.profiles = {}
    o.config = {}
    o.activeTab = "items"
    o.tabButtons = {}
    o.tabDefinitions = {
        { id = "items", labelKey = "UI_ZedToolbox_TabItems", fallback = "Item Spawns" },
        { id = "utils", labelKey = "UI_ZedToolbox_TabUtils", fallback = "Utils" },
        { id = "zombies", labelKey = "UI_ZedToolbox_TabZombies", fallback = "Zombies" },
        { id = "world", labelKey = "UI_ZedToolbox_TabWorld", fallback = "World" },
        { id = "skills", labelKey = "UI_ZedToolbox_TabSkills", fallback = "Skills" },
        { id = "moodles", labelKey = "UI_ZedToolbox_TabMoodles", fallback = "Moodles" },
        { id = "traits", labelKey = "UI_ZedToolbox_TabTraits", fallback = "Traits" },
        { id = "profiles", labelKey = "UI_ZedToolbox_TabProfiles", fallback = "Profiles" },
        { id = "config", labelKey = "UI_ZedToolbox_TabConfig", fallback = "Config" }
    }
    o.tabControls = { items = {}, utils = {}, zombies = {}, world = {}, skills = {}, moodles = {}, traits = {}, config = {}, profiles = {} }
    o.utilsSpeedValues = { 1, 1.5, 2, 3, 4, 5 }
    o.utilsLabelPositions = {}
    o.skillDefinitions = buildSkillDefinitions()
    o.skillCurrentLevelText = ""
    return o
end

function CheatMenuUI:addToTab(tabId, control)
    if not control then
        return
    end
    self.tabControls[tabId] = self.tabControls[tabId] or {}
    table.insert(self.tabControls[tabId], control)
end

function CheatMenuUI:updateTabButtonStates()
    for _, btn in ipairs(self.tabButtons) do
        local isActive = btn.internal == self.activeTab
        if isActive then
            btn.backgroundColor = { r = 0.20, g = 0.16, b = 0.05, a = 0.95 }
            btn.borderColor     = { r = ACCENT.r, g = ACCENT.g, b = ACCENT.b, a = 1 }
        else
            btn.backgroundColor = { r = 0.10, g = 0.10, b = 0.11, a = 0.88 }
            btn.borderColor     = { r = 0.28, g = 0.22, b = 0.08, a = 0.70 }
        end
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

attachItemsSection(CheatMenuUI, {
    clearControl = clearControl,
    getListSelection = getListSelection,
    getItemDisplayName = getItemDisplayName,
    getCategoryLabel = getCategoryLabel,
    lower = lower,
    trim = trim,
    CheatMenuItems = CheatMenuItems,
    CheatMenuText = CheatMenuText,
    CheatMenuSpawner = CheatMenuSpawner
})

attachUtilsSection(CheatMenuUI, {
    clamp = clamp,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils
})

attachZombiesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils,
    clamp = clamp,
    getPlayerCharacter = getPlayerCharacter
})

attachWorldSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    clamp = clamp,
    getPlayerCharacter = getPlayerCharacter
})

attachSkillsSection(CheatMenuUI, {
    buildSkillDefinitions = buildSkillDefinitions,
    clampSkillLevel = clampSkillLevel,
    MAX_SKILL_LEVEL = MAX_SKILL_LEVEL,
    CheatMenuText = CheatMenuText,
    getPlayerCharacter = getPlayerCharacter,
    getPlayerSkillLevel = getPlayerSkillLevel,
    applySkillLevel = applySkillLevel
})

attachMoodlesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    getPlayerCharacter = getPlayerCharacter,
    getListSelection = getListSelection
})

attachTraitsSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    CheatMenuText = CheatMenuText,
    lower = lower,
    getPlayerCharacter = getPlayerCharacter,
    getListSelection = getListSelection
})

attachProfilesSection(CheatMenuUI, {
    constants = LIFECYCLE_CONSTANTS,
    clamp = clamp,
    trim = trim,
    lower = lower,
    getListSelection = getListSelection,
    CheatMenuText = CheatMenuText,
    CheatMenuUtils = CheatMenuUtils,
    getPlayerCharacter = getPlayerCharacter,
    getPlayerSkillLevel = getPlayerSkillLevel,
    applySkillLevel = applySkillLevel
})

attachLifecycleSection(CheatMenuUI, {
    clamp = clamp,
    CheatMenuItems = CheatMenuItems,
    CheatMenuUtils = CheatMenuUtils,
    CheatMenuText = CheatMenuText,
    getHotkeyOptions = getHotkeyOptions,
    getCheatMenuMain = getCheatMenuMain,
    getListSelection = getListSelection,
    getCategoryLabel = getCategoryLabel,
    constants = LIFECYCLE_CONSTANTS
})

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
    "onClearZombiesClicked",
    "onZombiesKillNearby",
    "onZombiesKillScreen",
    "onZombiesFreeze",
    "onZombiesUnfreeze",
    "onZombiesIgnore",
    "onZombiesRestore",
    "onZombiesSpawn",
    "onWorldSetTime",
    "onWorldSkipHours",
    "onWorldSkipDays",
    "onWorldFreeze",
    "onWorldUnfreeze",
    "onWorldApplyMultiplier",
    "onWorldApplyWeather",
    "onWorldApplyEvent",
    "onTraitSelected",
    "onTraitAdd",
    "onTraitRemove",
    "onTraitAddAllPositive",
    "onTraitAddAllNegative",
    "onTraitsReset",
    "onProfileCreate",
    "onProfileApply",
    "onProfileRename",
    "onProfileDelete",
    "onMoodleSelected",
    "onMoodleSetMin",
    "onMoodleSetMax",
    "onMoodleNormalize",
    "onMoodlesClearNegative",
    "onMoodlesMaxAll",
}

for _, methodName in ipairs(GUARD_METHODS) do
    CheatMenuLogger.wrap(CheatMenuUI, methodName, "UI." .. methodName)
end

return CheatMenuUI
