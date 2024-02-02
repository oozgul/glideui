-- GlideUI Settings
local GlideUISettings = {
    enableLootFrame = true,
    enableXPFrame = true,
    enableMoneyFrame = true
}

local lootCheck, xpCheck, moneyCheck

local function OnAddonLoaded(self, event, addonName)
    if addonName == "GlideUI" then
        if type(GlideUISettingsSaved) == "table" then
            for key, value in pairs(GlideUISettingsSaved) do
                GlideUISettings[key] = value
            end
            GlideUISettings = GlideUISettingsSaved  -- make this assignment within the OnAddonLoaded function
        end
        self:UnregisterEvent(event)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", OnAddonLoaded)
    -- Set the checkbox state to match the saved settings


-- Function to create a checkbox for our settings
local function CreateCheckbox(parent, id, label, description, onClick, defaultState)
    local check = CreateFrame("CheckButton", "GlideUI"..id.."Check", parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT")
    check.Text:SetText(label)  -- Set the text label
    check.tooltip = description
    check:SetChecked(defaultState)  -- Sets default state while creation
    check:SetScript("OnClick", onClick)
    return check
end

local function UpdateSavedSettings()
    _G['GlideUISettingsSaved'] = GlideUISettingsSaved or {}
    _G['GlideUISettingsSaved'].enableLootFrame = GlideUISettings.enableLootFrame
    _G['GlideUISettingsSaved'].enableXPFrame = GlideUISettings.enableXPFrame
    _G['GlideUISettingsSaved'].enableMoneyFrame = GlideUISettings.enableMoneyFrame
  --  print("GlideUISettings: ", GlideUISettings.enableLootFrame, GlideUISettings.enableXPFrame, GlideUISettings.enableMoneyFrame)
-- print("GlideUISettingsSaved: ", GlideUISettingsSaved.enableLootFrame, GlideUISettingsSaved.enableXPFrame, GlideUISettingsSaved.enableMoneyFrame)
end


-- Function to initialize the options panel
local function InitializeOptionsPanel(panel)

    panel.name = "GlideUI"
    InterfaceOptions_AddCategory(panel)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", -16, -322)

    -- Now 'lootCheck', 'xpCheck', and 'moneyCheck' are accessible in the global scope
    lootCheck = CreateCheckbox(panel, "LootFrame", "Disable Loot Frame", "Toggle visibility of the loot frames", function(self)
        GlideUISettings.enableLootFrame = not self:GetChecked()
        UpdateSavedSettings()  -- Save settings when checkbox is clicked
    end)

    xpCheck = CreateCheckbox(panel, "XPFrame", "Disable XP Frame", "Toggle visibility of the XP frames", function(self)
        GlideUISettings.enableXPFrame = not self:GetChecked()
        UpdateSavedSettings()  -- Save settings when checkbox clicked
    end)
    xpCheck:SetPoint("TOPLEFT", lootCheck, "BOTTOMLEFT")

    moneyCheck = CreateCheckbox(panel, "MoneyFrame", "Disable Money Frame", "Toggle visibility of the money frames", function(self)
        GlideUISettings.enableMoneyFrame = not self:GetChecked()
        UpdateSavedSettings()  -- Save settings when checkbox clicked
    end)
    moneyCheck:SetPoint("TOPLEFT", xpCheck, "BOTTOMLEFT")


    local function UpdateCheckboxStates()
        lootCheck:SetChecked(not GlideUISettings.enableLootFrame)
        xpCheck:SetChecked(not GlideUISettings.enableXPFrame)
        moneyCheck:SetChecked(not GlideUISettings.enableMoneyFrame)
    end
    
    -- Add this within InitializeOptionsPanel
    GlideUIOptionsPanel:SetScript("OnShow", UpdateCheckboxStates)


    local btn = CreateFrame("Button", "GlideUIAnchorButton", panel, "GameMenuButtonTemplate")
    btn:SetSize(240, 40)
    btn:SetText("Toggle Moving Mode")
    btn:SetPoint("TOPLEFT", moneyCheck, "BOTTOMLEFT", 0, -10) -- Adjust as needed
    btn:SetScript("OnClick", function()
        SlashCmdList["GlideUIAnchor"]()
        HideUIPanel(InterfaceOptionsFrame) -- This is meant to hide the Interface Options
    end)
end




-- Creating a frame for our options panel
local GlideUIOptionsPanel = CreateFrame("Frame", "GlideUIOptionsPanel", UIParent)
InitializeOptionsPanel(GlideUIOptionsPanel)
SlashCmdList["GLIDEUI"] = function(msg)
    -- Update the checkboxes' states before showing the panel
    if PanelTemplates_GetSelectedTab(InterfaceOptionsFrame.panel) == GlideUIOptionsPanel then
        UpdateCheckboxStates()
    end
    InterfaceOptionsFrame_OpenToCategory(GlideUIOptionsPanel)
    InterfaceOptionsFrame_OpenToCategory(GlideUIOptionsPanel) -- Calling this twice because of a Blizzard's bug
end



local frameStack = {}
local MAX_FRAMES = 6
local LOOT_FRAME_HEIGHT = 50
local LOOT_FRAME_WIDTH = 250
local BASE_Y_OFFSET = 550
local Y_OFFSET_INCREMENT = 55
local FRAME_FADE_TIME = 1
local FRAME_FADE_DELAY = 3
local SCREEN_WIDTH = GetScreenWidth()
local SCREEN_HEIGHT = GetScreenHeight()
local X_OFFSET = SCREEN_WIDTH * 0.35 -- 50 percent off the center to the right


-- Create the anchor frame
local anchorFrame = CreateFrame("Frame", "GlideUIFrameAnchor", UIParent)
anchorFrame:SetSize(100, 100)  -- This size should make it reasonably easy to click
anchorFrame:SetPoint("CENTER", UIParent, "CENTER", 300, -180)  -- Initially place it at the bottom of the screen
anchorFrame:SetMovable(true)
anchorFrame:EnableMouse(true)
anchorFrame:RegisterForDrag("LeftButton")
anchorFrame:SetScript("OnDragStart", anchorFrame.StartMoving)
anchorFrame:SetScript("OnDragStop", anchorFrame.StopMovingOrSizing)

-- Create a placeholder frame to indicate where actual frames will appear
local placeholderFrame = CreateFrame("Frame", "GlideUIPlaceholderFrame", UIParent)
placeholderFrame:SetPoint("BOTTOM", anchorFrame, "BOTTOM", 80, Y_OFFSET_INCREMENT * (MAX_FRAMES-1))  -- Position it at the same place
placeholderFrame:SetSize(LOOT_FRAME_WIDTH, Y_OFFSET_INCREMENT * MAX_FRAMES)  -- Set it to cover all frames
placeholderFrame.texture = placeholderFrame:CreateTexture()  -- Assign the texture to an identifier
placeholderFrame.texture:SetAllPoints()
placeholderFrame.texture:SetColorTexture(0.3, 0.3, 0.3, 0.3)  -- Set it to a semi-transparent grey so it's visible without obstructing
placeholderFrame:Hide()  -- Hide it initially

-- Give it a size and a texture
anchorFrame.texture = anchorFrame:CreateTexture()
anchorFrame.texture:SetAllPoints(anchorFrame)
anchorFrame.texture:SetColorTexture(1, 0, 0, 0.5) -- This will give it a red semi-transparent color

anchorFrame:Hide()  -- Hide it initially

SLASH_GlideUIAnchor1 = "/glideuianchor"
-- Update the glideuianchor slash command function to show/hide the placeholder frame alongside the anchor frame
SlashCmdList["GlideUIAnchor"] = function(msg)
    if anchorFrame:IsShown() then
      anchorFrame:Hide()
      placeholderFrame:Hide()  -- Hide placeholder frame
    else
      anchorFrame:Show()
      placeholderFrame:Show()  -- Show placeholder frame
      anchorFrame.texture:SetColorTexture(1, 1, 1, 0.5)  -- This will give it a white (red=1, green=1, blue=1) semi-transparent (alpha=0.5) color
    end
end

local anchorText = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
anchorText:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
anchorText:SetText("MOVE THIS")

local placeholderText = placeholderFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
placeholderText:SetPoint("CENTER", placeholderFrame, "CENTER", 0, 0)
placeholderText:SetText("WHERE THE FRAMES WILL APPEAR")


-- XPFrame

local function CreateXPFrame(xpg)
    if not GlideUISettings.enableXPFrame then return end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(125, LOOT_FRAME_HEIGHT)
    frame:SetPoint("BOTTOMRIGHT", GlideUIFrameAnchor, "BOTTOM", X_OFFSET/2 - LOOT_FRAME_WIDTH / 2, BASE_Y_OFFSET/2 + ((#frameStack) * Y_OFFSET_INCREMENT))

    

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 24, edgeSize = 24,
        insets = {left = 7, right = 7, top = 7, bottom = 7}
    })

    frame:SetBackdropBorderColor(0.5, 0, 0.5, 0.8)  -- Blue border to indicate XP
    frame:SetBackdropColor(0, 0, 0, 0.9)  -- Slight blue background to indicate XP

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1) -- White text for better readability
    text:SetText('+' .. xpg .. "XP")  -- Display XP amount

    frame:Show()
    return frame
end


-- GoldFrame

local function CreateMoneyFrame(amount)
    if not GlideUISettings.enableMoneyFrame then return end
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(125, LOOT_FRAME_HEIGHT)
    frame:SetPoint("BOTTOMRIGHT", GlideUIFrameAnchor, "BOTTOM", X_OFFSET/2 - LOOT_FRAME_WIDTH / 2, BASE_Y_OFFSET/2 + ((#frameStack) * Y_OFFSET_INCREMENT))

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 24, edgeSize = 24,
        insets = {left = 7, right = 7, top = 7, bottom = 7}
    })

    frame:SetBackdropBorderColor(0.9, 0.9, 0.0)  -- Gold border to indicate money
    frame:SetBackdropColor(0.9, 0.9, 0.0, 0.8)  -- Slight gold background to indicate money

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1) -- White text for better readability
    text:SetText('+' .. GetCoinTextureString(amount))  -- Display money amount in gold, silver, and copper

    frame:Show()
    return frame
end
-- ItemColorMatching
local function ConvertRGBtoDecimal(hexColor)
  local a, r, g, b = string.match(hexColor, "|c(%x%x)(%x%x)(%x%x)(%x%x)")
  if not a then
      return 1, 1, 1 -- default to white if pattern matching fails
  end
  return tonumber(r, 16)/255, tonumber(g, 16)/255, tonumber(b, 16)/255
end

-- LootFrame

local function CreateLootFrame(itemLink)
    if not GlideUISettings.enableLootFrame then return end
    local MAX_TEXT_LENGTH =  25  -- Set the maximum text length
    
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(LOOT_FRAME_WIDTH, LOOT_FRAME_HEIGHT)
    frame:SetPoint("BOTTOMRIGHT", GlideUIFrameAnchor, "BOTTOM", X_OFFSET/2 - LOOT_FRAME_WIDTH / 2, BASE_Y_OFFSET/2 + ((#frameStack) * Y_OFFSET_INCREMENT))
  
    frame:SetScript("OnEnter", function()
      frame.isMouseOver = true  -- stops fading in 'OnUpdate' script, freezes transparency
      GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
      GameTooltip:SetHyperlink(itemLink)
      GameTooltip:Show()
    end)
  
    frame:SetScript("OnLeave", function()
      frame.isMouseOver = false -- resume fading in 'OnUpdate' script,
      GameTooltip:Hide()
    end)
    
    local itemName, _, itemQuality = GetItemInfo(itemLink)
    local itemRarityColor = select(4, GetItemQualityColor(itemQuality))  -- Use select to get the fourth return value (color hex code)
  
    -- Convert RGB color values correctly, ensuring they are between 0 and 1 for SetTextColor
    local r, g, b, hex = GetItemQualityColor(itemQuality)
  
    frame:SetBackdrop({})
    frame:SetBackdropBorderColor(r, g, b)
    frame:SetBackdropColor(r, g, b, 0.3)
  
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 24, edgeSize = 24,
      insets = {left = 7, right = 7, top = 7, bottom = 7}
    })
    
    local texture = frame:CreateTexture(nil, "ARTWORK")
    texture:SetSize(32, 32)
    texture:SetPoint("LEFT", frame, "LEFT", 10, 0)
    texture:SetTexture(GetItemIcon(itemLink))
  
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", texture, "RIGHT", 10, 0)
    text:SetTextColor(r, g, b)  -- Set the item rarity color correctly for the text
  
    local displayedItemName = itemName
    -- Trim the displayed name if necessary and add ellipsis
    if itemName and string.len(itemName) > MAX_TEXT_LENGTH then
        displayedItemName = string.sub(itemName, 1, MAX_TEXT_LENGTH) .. "..."  -- Trim the displayed name and add ellipsis
    end
    text:SetText(displayedItemName)  -- Set the trimmed item name text
  
    frame:Show()
    return frame
  end

-- Function to handle the fading and removal of the frame
local function FadeFrame(frame, startTime, frameType)
        
    if not GlideUISettings[frameType] then
        -- Add a print statement here to check if the function is correctly exited
        -- print("FadeFrame exited because " .. frameType .. " is disabled.")
        return
    end

    local fadeTime = FRAME_FADE_TIME
    
    frame:SetScript("OnUpdate", function(self, elapsed)
        local timePassed = GetTime() - startTime
        if timePassed > FRAME_FADE_DELAY then
            local alpha = math.max(0, 1 - ((timePassed - FRAME_FADE_DELAY) / fadeTime))
            
            self:SetAlpha(alpha)
            if timePassed < fadeTime + FRAME_FADE_DELAY and not self.isMouseOver then 
            
            else
                if not self.isMouseOver then
                    self:SetScript("OnUpdate", nil)
                    self:Hide()
                    for i=1, #frameStack do
                        if frameStack[i] == self then
                            table.remove(frameStack, i)
                            break
                        end
                    end

                    -- The part of recalculating Y positions of frames when one frame is removed
                    for i=1, #frameStack do
                        frameStack[i]:ClearAllPoints() -- Clear all points before setting a new one.
                        frameStack[i]:SetPoint("BOTTOMRIGHT", GlideUIFrameAnchor, "BOTTOM", X_OFFSET/2 - LOOT_FRAME_WIDTH / 2, BASE_Y_OFFSET/2 + ((i-1) * Y_OFFSET_INCREMENT))
                    end
                end
            end
        end
    end)
end


local eventHandler = CreateFrame("Frame") 
eventHandler:RegisterEvent("CHAT_MSG_MONEY") 
eventHandler:RegisterEvent("CHAT_MSG_LOOT") 
eventHandler:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN") 
eventHandler:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_MONEY" then 
        local message = ...
        if string.find(message, "You loot") or string.find(message, "You received") then
            local gold = string.match(message, "(%d+) Gold") or "0" 
            local silver = string.match(message, "(%d+) Silver") or "0" 
            local copper = string.match(message, "(%d+) Copper") or "0" 
            local amount = (tonumber(gold) * 10000) + (tonumber(silver) * 100) + tonumber(copper) 
            if #frameStack < MAX_FRAMES then 
                local moneyFrame = CreateMoneyFrame(amount) 
                table.insert(frameStack, moneyFrame) 
                FadeFrame(moneyFrame, GetTime(), "enableMoneyFrame") 
            end 
        end
    elseif event == "CHAT_MSG_LOOT" then 
        local message = ...
        if string.find(message, "You receive") then
            local itemLink = string.match(message, "|cff%x+|Hitem:.-|h.-|h|r") 
            if itemLink and #frameStack < MAX_FRAMES then 
                local lootFrame = CreateLootFrame(itemLink) 
                table.insert(frameStack, lootFrame) 
                FadeFrame(lootFrame, GetTime(), "enableLootFrame") 
            end 
        end
    elseif event == "CHAT_MSG_COMBAT_XP_GAIN" then 
        local message = ... 
        local stringXP = string.match(string.match(message, "%d+ experience"), "%d+") 
        local xpg = tostring(stringXP)
        
        if xpg and #frameStack < MAX_FRAMES then 
            local XPFrame = CreateXPFrame(xpg) 
            table.insert(frameStack, XPFrame) 
            FadeFrame(XPFrame, GetTime(), "enableXPFrame") 
        end 
    end 
end) 

  SLASH_TESTLOOT1 = "/testloot"
  SlashCmdList.TESTLOOT = function(itemID)
    local itemName, itemLink, itemQuality = GetItemInfo(itemID)
    if itemLink and #frameStack < MAX_FRAMES then
        local lootFrame = CreateLootFrame(itemLink)
        table.insert(frameStack, lootFrame) 
        FadeFrame(lootFrame, GetTime(), "enableLootFrame") -- Updated here
    end
  end
  
  SLASH_TESTMONEY1 = "/testmoney"
  SlashCmdList.TESTMONEY = function(msg)
      local amount = tonumber(msg) or 12345  -- Default amount to display if no amount is given
      local moneyFrame = CreateMoneyFrame(amount)
      table.insert(frameStack, moneyFrame)
      FadeFrame(moneyFrame, GetTime(), "enableMoneyFrame") -- And here
  end
  
  SLASH_TESTXP1 = "/testxp"
  SlashCmdList.TESTXP = function(msg)
      local xpg = tostring(msg) or 12345  -- Default amount to display if no amount is given
      local XPFrame = CreateXPFrame(xpg)
      table.insert(frameStack, XPFrame)
      FadeFrame(XPFrame, GetTime(), "enableXPFrame") -- And here
  end