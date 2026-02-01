return function(CheatMenuUI, deps)
    local PADDING = deps.constants.PADDING
    local COLUMN_GAP = deps.constants.COLUMN_GAP
    local LIST_TOP = deps.constants.LIST_TOP
    local TAB_HEIGHT = deps.constants.TAB_HEIGHT
    local TAB_GAP = deps.constants.TAB_GAP
    local BOTTOM_HEIGHT = deps.constants.BOTTOM_HEIGHT
    local LEFT_WIDTH = deps.constants.LEFT_WIDTH
    local CENTER_WIDTH = deps.constants.CENTER_WIDTH
    local RIGHT_WIDTH = deps.constants.RIGHT_WIDTH
    local BUTTON_HEIGHT = deps.constants.BUTTON_HEIGHT
    local BUTTON_GAP = deps.constants.BUTTON_GAP
    local BUTTON_ROW_GAP = deps.constants.BUTTON_ROW_GAP
    local SECTION_GAP = deps.constants.SECTION_GAP
    local PRIMARY_BUTTON_HEIGHT = deps.constants.PRIMARY_BUTTON_HEIGHT
    local SECTION_BG_ALPHA = deps.constants.SECTION_BG_ALPHA
    local SECTION_BORDER_ALPHA = deps.constants.SECTION_BORDER_ALPHA

    local clamp = deps.clamp
    local trim = deps.trim
    local lower = deps.lower
    local getListSelection = deps.getListSelection
    local CheatMenuText = deps.CheatMenuText
    local CheatMenuUtils = deps.CheatMenuUtils
    local getPlayerCharacter = deps.getPlayerCharacter
    local getPlayerSkillLevel = deps.getPlayerSkillLevel
    local applySkillLevel = deps.applySkillLevel

    local function copyUtilsConfig(utils)
        local source = utils or {}
        return {
            godMode = source.godMode and true or false,
            hitKill = source.hitKill and true or false,
            infiniteStamina = source.infiniteStamina and true or false,
            instantBuild = source.instantBuild and true or false,
            noNegativeEffects = source.noNegativeEffects and true or false,
            noHungerThirst = source.noHungerThirst and true or false,
            speedMultiplier = clamp(source.speedMultiplier or 1, 0.5, 5),
            clearRadius = source.clearRadius or 15
        }
    end

    local function captureSkillLevels(self)
        local player = getPlayerCharacter()
        if not player then
            return {}
        end
        local result = {}
        for _, definition in ipairs(self:getSkillDefinitions()) do
            if definition and definition.id then
                result[definition.id] = getPlayerSkillLevel(player, definition)
            end
        end
        return result
    end

    local function applySkillLevels(self, profileSkills)
        local player = getPlayerCharacter()
        if not player then
            return false
        end
        local anyApplied = false
        local skills = profileSkills or {}
        for _, definition in ipairs(self:getSkillDefinitions()) do
            local target = skills[definition.id]
            if target ~= nil then
                if applySkillLevel(player, definition, target) then
                    anyApplied = true
                end
            end
        end
        self:syncSkillUI()
        return anyApplied
    end

    function CheatMenuUI:refreshProfilesUI()
        if not self.profilesList then
            return
        end
        self.profilesList:clear()
        local profiles = self.profiles or {}
        for _, profile in ipairs(profiles) do
            self.profilesList:addItem(profile.name or "Profile", profile)
        end
        if self.profilesList.items and #self.profilesList.items > 0 then
            self.profilesList.selected = 1
        else
            self.profilesList.selected = 0
        end
        local current = self:getSelectedProfile()
        self:setProfileNameInput(current and current.name or "")
    end

    function CheatMenuUI:getSelectedProfile()
        local entry = getListSelection(self.profilesList)
        return entry and entry.item or nil
    end

    function CheatMenuUI:setProfileNameInput(name)
        if self.profileNameBox then
            self.profileNameBox:setText(name or "")
        end
    end

    function CheatMenuUI:captureCurrentProfile(name)
        self:ensureUtilsConfig()
        local profile = {
            name = name,
            utils = copyUtilsConfig(self.config and self.config.utils),
            skills = captureSkillLevels(self)
        }
        return profile
    end

    function CheatMenuUI:onProfileCreate()
        if not self.profileNameBox then
            return
        end
        local name = trim(self.profileNameBox:getInternalText() or "")
        if name == "" then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_NameRequired", "Enter a profile name."))
            return
        end
        self.profiles = self.profiles or {}
        for _, profile in ipairs(self.profiles) do
            if lower(profile.name or "") == lower(name) then
                self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_NameExists", "Profile name already exists."))
                return
            end
        end
        local profile = self:captureCurrentProfile(name)
        table.insert(self.profiles, profile)
        self:refreshProfilesUI()
        self:flushPersistentData()
        self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Profile_Saved", "Profile saved."))
    end

    function CheatMenuUI:onProfileApply()
        local profile = self:getSelectedProfile()
        if not profile then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_Select", "Select a profile first."))
            return
        end
        local player = getPlayerCharacter()
        if not player then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_ErrorPlayer", "Player not ready"))
            return
        end
        self.config = self.config or {}
        self.config.utils = copyUtilsConfig(profile.utils)
        self:ensureUtilsConfig()
        self:populateUtilsOptions()
        self:syncUtilsUI()
        local skillsApplied = applySkillLevels(self, profile.skills)
        self:flushPersistentData()
        local message = CheatMenuText.get("UI_ZedToolbox_Profile_Applied", "Profile applied.")
        if not skillsApplied then
            message = CheatMenuText.get("UI_ZedToolbox_Profile_AppliedNoSkills", "Profile applied (skills unchanged).")
        end
        self:setStatus(true, message)
    end

    function CheatMenuUI:onProfileRename()
        local profile = self:getSelectedProfile()
        if not profile or not self.profileNameBox then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_Select", "Select a profile first."))
            return
        end
        local newName = trim(self.profileNameBox:getInternalText() or "")
        if newName == "" then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_NameRequired", "Enter a profile name."))
            return
        end
        for _, other in ipairs(self.profiles or {}) do
            if other ~= profile and lower(other.name or "") == lower(newName) then
                self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_NameExists", "Profile name already exists."))
                return
            end
        end
        profile.name = newName
        self:refreshProfilesUI()
        self:flushPersistentData()
        self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Profile_Renamed", "Profile renamed."))
    end

    function CheatMenuUI:onProfileDelete()
        local profile = self:getSelectedProfile()
        if not profile then
            self:setStatus(false, CheatMenuText.get("UI_ZedToolbox_Profile_Select", "Select a profile first."))
            return
        end
        for index, entry in ipairs(self.profiles or {}) do
            if entry == profile then
                table.remove(self.profiles, index)
                break
            end
        end
        self:refreshProfilesUI()
        self:flushPersistentData()
        self:setStatus(true, CheatMenuText.get("UI_ZedToolbox_Profile_Deleted", "Profile deleted."))
    end

    function CheatMenuUI:buildProfilesUI()
        local listTop = LIST_TOP + TAB_HEIGHT + TAB_GAP
        local listHeight = self.height - listTop - BOTTOM_HEIGHT

        self.profilesList = ISScrollingListBox:new(PADDING, listTop, LEFT_WIDTH, listHeight)
        self.profilesList:initialise()
        self.profilesList:instantiate()
        self.profilesList.itemheight = 24
        self.profilesList.font = UIFont.Small
        self.profilesList.doDrawItem = function(list, y, item)
            local isSelected = list.selected == item.index
            if isSelected then
                list:drawRect(0, y, list.width, item.height, 0.25, 0.2, 0.6, 0.9)
            end
            local tint = isSelected and 1 or 0.9
            list:drawText(item.text, 10, y + 5, tint, tint, tint, 1, UIFont.Small)
            return y + item.height
        end
        self.profilesList.onMouseDown = function(list, x, y)
            ISScrollingListBox.onMouseDown(list, x, y)
            local entry = getListSelection(list)
            if entry and entry.item then
                self:setProfileNameInput(entry.item.name)
            end
        end
        self:addChild(self.profilesList)
        self:addToTab("profiles", self.profilesList)
        self.profilesListLabelPos = { x = PADDING, y = listTop - 20 }

        local contentX = PADDING + LEFT_WIDTH + COLUMN_GAP
        local contentWidth = self.width - contentX - PADDING
        local nameWidth = math.max(220, math.min(contentWidth, CENTER_WIDTH + RIGHT_WIDTH - COLUMN_GAP))
        self.profileNameBox = ISTextEntryBox:new("", contentX, listTop, nameWidth, 26)
        self.profileNameBox:initialise()
        self.profileNameBox:instantiate()
        self:addChild(self.profileNameBox)
        self:addToTab("profiles", self.profileNameBox)
        self.profileNameLabelPos = { x = contentX, y = listTop - 18 }

        local buttonsTop = self.profileNameBox.y + self.profileNameBox.height + BUTTON_ROW_GAP
        local buttonWidth = 140
        self.createProfileBtn = ISButton:new(contentX, buttonsTop, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Profile_Create", "Create"), self, CheatMenuUI.onProfileCreate)
        self.createProfileBtn:initialise()
        self.createProfileBtn:instantiate()
        self:addChild(self.createProfileBtn)
        self:addToTab("profiles", self.createProfileBtn)

        self.renameProfileBtn = ISButton:new(contentX + buttonWidth + BUTTON_GAP, buttonsTop, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Profile_Rename", "Rename"), self, CheatMenuUI.onProfileRename)
        self.renameProfileBtn:initialise()
        self.renameProfileBtn:instantiate()
        self:addChild(self.renameProfileBtn)
        self:addToTab("profiles", self.renameProfileBtn)

        self.deleteProfileBtn = ISButton:new(contentX + (buttonWidth + BUTTON_GAP) * 2, buttonsTop, buttonWidth, BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Profile_Delete", "Delete"), self, CheatMenuUI.onProfileDelete)
        self.deleteProfileBtn:initialise()
        self.deleteProfileBtn:instantiate()
        self:addChild(self.deleteProfileBtn)
        self:addToTab("profiles", self.deleteProfileBtn)

        local applyTop = buttonsTop + BUTTON_HEIGHT + BUTTON_ROW_GAP
        local applyWidth = buttonWidth + 80
        self.applyProfileBtn = ISButton:new(contentX, applyTop, applyWidth, PRIMARY_BUTTON_HEIGHT, CheatMenuText.get("UI_ZedToolbox_Profile_Apply", "Apply Profile"), self, CheatMenuUI.onProfileApply)
        self.applyProfileBtn:initialise()
        self.applyProfileBtn:instantiate()
        self:addChild(self.applyProfileBtn)
        self:addToTab("profiles", self.applyProfileBtn)

        local sectionTop = listTop - 30
        local sectionBottom = applyTop + PRIMARY_BUTTON_HEIGHT + SECTION_GAP
        self.profilesSection = {
            x = PADDING,
            y = sectionTop,
            w = self.width - (2 * PADDING),
            h = sectionBottom - sectionTop
        }

        self:refreshProfilesUI()
    end
end
