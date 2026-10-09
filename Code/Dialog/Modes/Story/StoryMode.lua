local env = select(2, ...)
local L = env.L
local Config = env.Config
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local UIAnim = env.modules:Import("packages\\ui-anim")
local ControlCenter = env.modules:Import("@\\Dialog\\ControlCenter")
local ControlCenter_ContextIcon = env.modules:Import("@\\Dialog\\ControlCenter\\ContextIcon")
local DialogFrame = env.modules:Import("@\\Dialog\\DialogFrame")
local SharedUtil = env.modules:Import("@\\Dialog\\SharedUtil")
local TextPlaybackUtil = env.modules:Import("@\\Dialog\\TextPlaybackUtil")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local StoryMode_Preload = env.modules:Import("@\\Dialog\\Modes\\Story\\Preload")
local StoryMode = env.modules:New("@\\Dialog\\Modes\\StoryMode")

local Mixin = Mixin
local ipairs = ipairs
local wipe = wipe
local gsub = string.gsub
local max = math.max
local min = math.min

local GOODBYE_OPTION = {
    name = L["GOODBYE"],
    contextIcon = ControlCenter_ContextIcon.TexDef.GossipExit.path,
    optionType = "Goodbye",
    optionKey = 0
}


StoryMode.isActive = false
StoryMode.state = nil
StoryMode.npcGUID = nil


local function CloseSession()
    ControlCenter.CloseSession()
    CallbackRegistry.Trigger("DialogFrame.CloseSession")
end

local ACTION_HANDLERS = {
    [DialogFrame.Enum.Action.Goodbye]    = CloseSession,
    [DialogFrame.Enum.Action.Cancel]     = function()
        if ControlCenter.IsGossipQuest() then
            ControlCenter.DeclineCurrentQuest()
        else
            CloseSession()
        end
    end,
    [DialogFrame.Enum.Action.Accept]     = ControlCenter.AcceptCurrentQuest,
    [DialogFrame.Enum.Action.AutoAccept] = ControlCenter.AcceptCurrentQuest,
    [DialogFrame.Enum.Action.Continue]   = ControlCenter.ContinueCurrentQuest,
    [DialogFrame.Enum.Action.Complete]   = ControlCenter.CompleteCurrentQuest
}

local function ShowGossipOptions()
    StoryMode.state = StoryMode_Preload.Enum.PlaybackState.Options
    LWStoryDialogBox.AnimGroup:Stop()
    LWStoryDialogBox.AnimGroup:Play(LWStoryDialogBox, "OPTIONS")
    LWStoryDialogBox:SetArrowShown(false)
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close(true)
    LWStoryOptionsBox:RefreshOptions()
    LWStoryOptionsBox:Open()
end

local function ShowQuestState()
    StoryMode.state = StoryMode_Preload.Enum.PlaybackState.Quest
    LWStoryOptionsBox:CloseImmediately()
    LWStoryDialogBox:SetArrowShown(false)
    LWStoryDialogBox:Close()
    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame:Open()
    LWDialogFrame.QuestFrame.ScrollContainer:SetVerticalScroll(0, true)
    LWDialogFrame.QuestFrame:_Render()
    LWDialogFrame:RefreshEdgeFade()
end

local function OnDialogueFinished()
    if not StoryMode.isActive then return end

    if ControlCenter.GetQuestSessionType() then
        ShowQuestState()
    elseif ControlCenter.GetGossipSessionType() then
        ShowGossipOptions()
    end
end

local function ShowDialogue(text, dividerText)
    if not LWStoryDialogBox.isLoaded then return end
    LWStoryOptionsBox:CloseImmediately()

    local npcGUID = ControlCenter.GetNPCGUID()
    if StoryMode.npcGUID ~= npcGUID then
        LWStoryDialogBox:CloseImmediately()
        StoryMode.npcGUID = npcGUID
    end

    StoryMode.state = StoryMode_Preload.Enum.PlaybackState.Dialogue
    LWStoryDialogBox:SetArrowShown(true)
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close(true)
    LWStoryDialogBox:SetTitle(ControlCenter.GetNPCName())
    LWStoryDialogBox:SetDividerText(dividerText)

    LWStoryDialogBox.AnimGroup:Stop()
    if LWStoryDialogBox:SetMessage(text, true) then
        LWStoryDialogBox:Open()
    else
        OnDialogueFinished()
    end
end

local function Refresh()
    if ControlCenter.GetGossipSessionType() then
        StoryMode.OnShowGossip()
    elseif ControlCenter.GetQuestSessionType() then
        StoryMode.OnShowQuest()
    else
        StoryMode.state = nil
        LWStoryDialogBox:Close()
        LWStoryOptionsBox:Close()
        LWDialogFrame:HideQuestModelFrame()
        LWDialogFrame:Close()
    end
end

function StoryMode.Activate()
    StoryMode.isActive = true
    LWDialogFrame:SetDefaultTextShown(false)
    Refresh()
end

function StoryMode.Deactivate()
    StoryMode.isActive = false
    StoryMode.state = nil
    StoryMode.npcGUID = nil
    LWStoryDialogBox:Close()
    LWStoryOptionsBox:CloseImmediately()
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function StoryMode.OnQuestRewardChoiceSelected()
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Quest then return end
    LWDialogFrame:UpdateFooterButtons()
end

function StoryMode.OnSessionEnd()
    if not StoryMode.isActive then return end
    StoryMode.state = nil
    StoryMode.npcGUID = nil
    LWStoryDialogBox:CloseImmediately()
    LWStoryOptionsBox:CloseImmediately()
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function StoryMode.OnShowGossip()
    if not StoryMode.isActive then return end
    ShowDialogue(ControlCenter.GetGossipText())
end

function StoryMode.OnHideGossip(_, interactionIsContinuing)
    if not StoryMode.isActive then return end
    LWStoryOptionsBox:CloseImmediately()
    LWDialogFrame:Close(interactionIsContinuing)

    if not interactionIsContinuing then
        StoryMode.state = nil
        LWStoryDialogBox:Close()
    end
end

function StoryMode.OnUpdateGossip()
    if not StoryMode.isActive then return end

    if StoryMode.state == StoryMode_Preload.Enum.PlaybackState.Dialogue then
        if LWStoryDialogBox.isFinished then
            OnDialogueFinished()
        end
        return
    end

    if StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Options then return end
    if not ControlCenter.IsGossipValidForUpdate() then return end
    LWStoryOptionsBox:RefreshOptions()
    LWStoryOptionsBox:Open()
end

function StoryMode.OnShowQuest()
    if not StoryMode.isActive then return end
    ShowDialogue(ControlCenter.GetQuestText(), ControlCenter.GetQuestName())
end

function StoryMode.OnHideQuest()
    if not StoryMode.isActive then return end
    StoryMode.state = nil
    LWStoryDialogBox:Close()
    LWStoryOptionsBox:CloseImmediately()
    LWDialogFrame:HideQuestModelFrame()
    LWDialogFrame:Close()
end

function StoryMode.OnUpdateQuest()
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Quest then return end
    if not ControlCenter.GetQuestSessionType() then return end
    LWDialogFrame:RefreshQuestFrame()
    LWDialogFrame:RefreshQuestModelFrame()
    LWDialogFrame.QuestFrame:_Render()
end

function StoryMode.OnPortraitUpdate()
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Quest then return end
    if not ControlCenter.GetQuestSessionType() then return end
    LWDialogFrame:RefreshQuestModelFrame()
end

function StoryMode.OnCloseSessionRequested()
    if not StoryMode.isActive then return end
    CloseSession()
end

function StoryMode.OnActionRequested(_, action)
    if not StoryMode.isActive then return end

    local handler = ACTION_HANDLERS[action]
    if handler then handler() end
end

function StoryMode.OnGossipOptionSelectionRequested(_, optionType, optionKey)
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Options then return end
    if optionType == GOODBYE_OPTION.optionType then
        CloseSession()
    else
        ControlCenter.SelectGossipOption(optionType, optionKey)
    end
end

function StoryMode.OnQuestRewardSelectionRequested(_, rewardIndex)
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Quest then return end
    ControlCenter.SelectQuestReward(rewardIndex)
end


local StoryDialogBoxMixin = {}

function StoryDialogBoxMixin:OnLoad()
    self.isLoaded = true
    self.messages = nil
    self.messageIndex = nil
    self.sourceText = nil
    self.splitParagraphs = nil
    self.isFinished = false
    self.textPlaybackState = nil
    self.autoProgressTimer = nil

    self:SetScript("OnMouseUp", self.OnMouseUp)
    self:SetScript("OnUpdate", self.OnUpdate)
    SharedUtil.InitializeBoundsForFrame(self, "storyDialogBoxBounds", self, 1)

    self:RestorePosition()
    self:SetArrowShown(true)
    self:Hide()
end

function StoryDialogBoxMixin:OnMouseUp(button)
    if button ~= "LeftButton" or self.isDragging then return end
    self:NextDialog()
end

function StoryDialogBoxMixin:OnUpdate(elapsed)
    if self.AnimGroup:IsPlaying(self, "HIDE") then return end
    self:OnTextPlaybackUpdate(elapsed)
end

function StoryDialogBoxMixin:NextDialog()
    if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Dialogue then return false end

    if self.textPlaybackState then
        self:CancelAutoProgress()
        self:StopTextPlayback(true)
        return true
    end

    return self:ShowNextMessage()
end

function StoryDialogBoxMixin:RestorePosition()
    SharedUtil.RestoreBounds(self)
end

function StoryDialogBoxMixin:GetDefaultPosition()
    return "BOTTOM", UIParent, "BOTTOM", 0, 20
end

function StoryDialogBoxMixin:SetDefaultPosition()
    local point, relativeTo, relativePoint, x, y = self:GetDefaultPosition()
    self:ClearAllPoints()
    self:SetPoint(point, relativeTo, relativePoint, x, y)
end

function StoryDialogBoxMixin:SetTitle(title)
    self.TitleText:SetText(title or "")
end

function StoryDialogBoxMixin:SetDividerText(text)
    self.Divider:SetText(text)
end

function StoryDialogBoxMixin:SetText(text)
    self.ContentText:SetText(text or "")
    self.ContentText:ClearAlphaGradient()
    self:_Render()
end

function StoryDialogBoxMixin:SetArrowShown(shown)
    local arrow = self.Arrow
    self.ArrowAnimGroup:Stop()

    if shown then
        arrow:ClearAllPoints()
        arrow:SetPoint("CENTER", self.ArrowFrame, "CENTER", 0, 0)
        arrow:Show()
        self.ArrowAnimGroup:Play(arrow, "SHOW"):onFinish(function()
            if arrow:IsVisible() then self.ArrowAnimGroup:Play(arrow, "BOB") end
        end)
    elseif arrow:IsShown() then
        self.ArrowAnimGroup:Play(arrow, "HIDE"):onFinish(function() arrow:Hide() end)
    end
end

function StoryDialogBoxMixin:HasMessage()
    return self.messages and self.messages[1] ~= nil
end

function StoryDialogBoxMixin:CancelAutoProgress()
    if not self.autoProgressTimer then return end

    self.autoProgressTimer:Cancel()
    self.autoProgressTimer = nil
end

function StoryDialogBoxMixin:StopTextPlayback(showFullText)
    local playbackState = self.textPlaybackState
    self.textPlaybackState = nil
    TextPlaybackUtil.StopAlphaGradientPlayback()
    self.ContentText:ClearAlphaGradient()

    if showFullText and playbackState then
        self:SetText(playbackState.text)
        self.ContentText:SetAlpha(1)
    end
end

function StoryDialogBoxMixin:ScheduleAutoProgress()
    self:CancelAutoProgress()

    local delay = TextPlaybackUtil.GetAutoProgressDelay()
    local sourceText = self.sourceText
    local messageIndex = self.messageIndex

    self.autoProgressTimer = C_Timer.NewTimer(delay, function()
        self.autoProgressTimer = nil
        if not StoryMode.isActive or StoryMode.state ~= StoryMode_Preload.Enum.PlaybackState.Dialogue then return end
        if not self:IsShown() or self.isFinished then return end
        if self.sourceText ~= sourceText or self.messageIndex ~= messageIndex then return end

        self:ShowNextMessage()
    end)
end

function StoryDialogBoxMixin:OnTextPlaybackFinished()
    local playbackState = self.textPlaybackState
    if not playbackState then return end

    self:StopTextPlayback(true)
    self:ScheduleAutoProgress()
end

function StoryDialogBoxMixin:OnTextPlaybackUpdate(elapsed)
    local playbackState = self.textPlaybackState
    if not playbackState then return end

    if TextPlaybackUtil.UpdateAlphaGradient(playbackState, self.ContentText, elapsed) then
        self:OnTextPlaybackFinished()
    end
end

function StoryDialogBoxMixin:StartTextPlayback(text)
    self.ContentText:SetAlpha(0)

    self:CancelAutoProgress()
    self:StopTextPlayback()
    self:SetText(text)

    local playbackSpeed = Config.DBGlobal:GetVariable("Story_PlaybackSpeed")
    self.textPlaybackState = TextPlaybackUtil.CreateAlphaGradientState(text, playbackSpeed, function()
        self.ContentText:SetAlpha(1)
    end)
end

function StoryDialogBoxMixin:SetMessageToIndex(index)
    local message = self.messages and self.messages[index]
    if not message then return false end

    self.messageIndex = index
    self:StartTextPlayback(message)
    return true
end

function StoryDialogBoxMixin:SetMessage(text, restartDialog)
    local splitParagraphs = TextPlaybackUtil.ShouldSplitParagraphs()
    local messages = TextPlaybackUtil.SplitText(text, splitParagraphs)
    if not messages or not messages[1] then
        self.messages = nil
        self.messageIndex = nil
        self.sourceText = text
        self.splitParagraphs = splitParagraphs
        self.isFinished = false
        self:CancelAutoProgress()
        self:StopTextPlayback()
        return false
    end

    if restartDialog or self.sourceText ~= text or self.splitParagraphs ~= splitParagraphs then
        for index = 1, #messages do
            messages[index] = gsub(gsub(messages[index], "[<>]", ""), "%.%.%.", "…")
        end

        self.messages = messages
        self.messageIndex = nil
        self.sourceText = text
        self.splitParagraphs = splitParagraphs
        self.isFinished = false
        self:SetMessageToIndex(1)
        return true
    end

    return true
end

function StoryDialogBoxMixin:ShowNextMessage()
    if not self:IsShown() or not self:HasMessage() then return false end

    if self.messageIndex >= #self.messages then
        self.isFinished = true
        self:CancelAutoProgress()
        self:StopTextPlayback(true)
        OnDialogueFinished()
        return true
    end

    self.ArrowAnimGroup:Stop()
    self.ArrowAnimGroup:Play(self.Arrow, "INTERACT"):onFinish(function()
        if self.Arrow:IsVisible() then self.ArrowAnimGroup:Play(self.Arrow, "BOB") end
    end)
    return self:SetMessageToIndex(self.messageIndex + 1)
end

function StoryDialogBoxMixin:Open()
    local wasShown = self:IsShown()
    self:Show()
    self.AnimGroup:Stop()

    if wasShown then
        self:SetAlpha(1)
    else
        self.AnimGroup:Play(self, "SHOW")
    end
end

function StoryDialogBoxMixin:Close()
    self:CancelAutoProgress()
    self:StopTextPlayback(true)
    if not self:IsShown() or self.AnimGroup:IsPlaying(self, "HIDE") then return end
    self.AnimGroup:Stop()
    self.AnimGroup:Play(self, "HIDE"):onFinish(function() self:Hide() end)
end

function StoryDialogBoxMixin:CloseImmediately()
    self:CancelAutoProgress()
    self:StopTextPlayback(true)
    self.AnimGroup:Stop()
    self:Hide()
end

StoryDialogBoxMixin.AnimGroup = UIAnim.New()
do
    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):from(0):to(1)
    StoryDialogBoxMixin.AnimGroup:State("SHOW", function(frame)
        FadeIn:Play(frame)
        if not frame.textPlaybackState then frame.ContentText:SetAlpha(1) end
    end)

    local FadeToOptions = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):to(0.5)
    StoryDialogBoxMixin.AnimGroup:State("OPTIONS", function(frame)
        FadeToOptions:Play(frame)
        FadeToOptions:Play(frame.ContentText)
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(0)
    StoryDialogBoxMixin.AnimGroup:State("HIDE", function(frame)
        FadeOut:Play(frame)
        FadeOut:Play(frame.ContentText)
    end)
end

StoryDialogBoxMixin.ArrowAnimGroup = UIAnim.New()
do
    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):from(0):to(1)
    StoryDialogBoxMixin.ArrowAnimGroup:State("SHOW", function(frame)
        FadeIn:Play(frame)
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(0)
    StoryDialogBoxMixin.ArrowAnimGroup:State("HIDE", function(frame)
        FadeOut:Play(frame)
    end)

    local Bob = UIAnim.Animate():property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.SineInOut):duration(0.6):from(0):to(-4):loop(UIAnim.Enum.Looping.Yoyo)
    StoryDialogBoxMixin.ArrowAnimGroup:State("BOB", function(frame)
        Bob:Play(frame)
    end)

    local InteractMoveOut = UIAnim.Animate():property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.SineIn):duration(0.25)
    local InteractMoveIn = UIAnim.Animate():wait(0.25):property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.SineOut):duration(0.25):from(5):to(0)
    local InteractFadeIn = UIAnim.Animate():wait(0.25):property(UIAnim.Enum.Property.Alpha):duration(0.125):to(1)
    StoryDialogBoxMixin.ArrowAnimGroup:State("INTERACT", function(frame)
        local _, _, _, _, offsetY = frame:GetPoint()
        InteractMoveOut:to(offsetY - 5):Play(frame)
        FadeOut:Play(frame)
        InteractMoveIn:Play(frame)
        InteractFadeIn:Play(frame)
    end)
end


Mixin(LWStoryDialogBox, StoryDialogBoxMixin)


local StoryOptionsBoxMixin = {}

function StoryOptionsBoxMixin:OnLoad()
    self.isLoaded = true
    self.options = {}
    self.selectedIndex = nil
    self.selectedElement = nil
    self.isSelectingOption = false

    self.HitRect:AddOnMouseUp(function(button)
        if button == "RightButton" and Config.DBGlobal:GetVariable("RightClickToClose") then
            CloseSession()
        end
    end)
    SharedUtil.InitializeBoundsForFrame(self, "storyOptionsBoxBounds", self.HitRect, 2)

    CallbackRegistry.Add("InputHandler.InputDeviceChanged", function()
        if self:IsActive() then self:RefreshOptions() end
    end)
    SavedVariables.OnChange("LorewalkerDB_Global", "ShowQuestLevel", function()
        if self:IsActive() then self:RefreshOptions() end
    end)
    CallbackRegistry.Add("WoWClient.OnUIScaleChanged", function()
        if self:IsVisible() then
            self:_Render()
        end
    end)

    self:RestorePosition()
    self:Hide()
end

function StoryOptionsBoxMixin:IsActive()
    return StoryMode.isActive and StoryMode.state == StoryMode_Preload.Enum.PlaybackState.Options and self:IsShown() and not self.AnimGroup:IsPlaying(self, "HIDE")
end

function StoryOptionsBoxMixin:RestorePosition()
    SharedUtil.RestoreBounds(self)
end

function StoryOptionsBoxMixin:GetDefaultPosition(index)
    local point = index == 2 and "LEFT" or "RIGHT"
    local x = UIParent:GetWidth() * 0.09

    if index ~= 2 then x = -x end
    return point, UIParent, point, x, 0
end

function StoryOptionsBoxMixin:SetDefaultPosition(index)
    local point, relativeTo, relativePoint, x, y = self:GetDefaultPosition(index)
    self:ClearAllPoints()
    self:SetPoint(point, relativeTo, relativePoint, x, y)
end

function StoryOptionsBoxMixin:ResetSelection()
    if self.selectedElement then self.selectedElement:OnLeave() end
    self.selectedIndex = nil
    self.selectedElement = nil
end

function StoryOptionsBoxMixin:SetSelection(index)
    local option = self.options[index]
    if not option then return false end

    self:ResetSelection()
    self.selectedIndex = index
    self.selectedElement = self.OptionsList:GetElement(index, "Default")
    self.selectedElement:OnEnter()
    return true
end

function StoryOptionsBoxMixin:RefreshOptions()
    if not self.isLoaded or not ControlCenter.GetGossipSessionType() then return end

    self.isSelectingOption = false
    local selectedOption = self.selectedIndex and self.options[self.selectedIndex]
    local selectedType = selectedOption and selectedOption.optionType
    local selectedKey = selectedOption and selectedOption.optionKey
    self:ResetSelection()
    wipe(self.options)

    for _, option in ipairs(ControlCenter.GetGossipOptionsQuestQuest()) do
        self.options[#self.options + 1] = option
    end
    for _, option in ipairs(ControlCenter.GetGossipOptions()) do
        self.options[#self.options + 1] = option
    end
    self.options[#self.options + 1] = GOODBYE_OPTION
    for index, option in ipairs(self.options) do
        option.dialogOptionIndex = index <= 9 and index or nil
    end

    self.OptionsList:SetData(self.options)
    self:_Render()

    if selectedKey then
        for index, option in ipairs(self.options) do
            if option.optionType == selectedType and option.optionKey == selectedKey then
                self:SetSelection(index)
                break
            end
        end
    end

    if #self.options == 0 then self:Close() end
end

function StoryOptionsBoxMixin:SelectNextOption()
    if not self:IsActive() then return false end
    local index = self.selectedIndex and min(self.selectedIndex + 1, #self.options) or 1
    return self:SetSelection(index)
end

function StoryOptionsBoxMixin:SelectPreviousOption()
    if not self:IsActive() then return false end
    local index = self.selectedIndex and max(self.selectedIndex - 1, 1) or #self.options
    return self:SetSelection(index)
end

function StoryOptionsBoxMixin:ConfirmSelection()
    if not self:IsActive() then return false end
    if self.isSelectingOption then return true end
    if not self.selectedElement then return false end
    self.selectedElement:OnClick()
    return true
end

function StoryOptionsBoxMixin:SelectDialogOption(optionIndex)
    if not self:IsActive() then return false end
    if self.isSelectingOption then return true end

    local option = self.options[optionIndex]
    if not option then return false end
    local element = self.OptionsList:GetElement(optionIndex, "Default")

    self.isSelectingOption = true
    element:PlayPushedAnimation(function()
        self.isSelectingOption = false
        if not self:IsActive() or self.options[optionIndex] ~= option then return end
        DialogFrame.RequestGossipOptionSelection(option.optionType, option.optionKey)
    end)
    return true
end

function StoryOptionsBoxMixin:Open()
    if not self.isLoaded or #self.options == 0 then return end
    local wasShown = self:IsShown()
    self:Show()
    self.AnimGroup:Stop()

    if wasShown then
        self:SetAlpha(1)
    else
        self.AnimGroup:Play(self, "SHOW")
    end
end

function StoryOptionsBoxMixin:Close()
    self.isSelectingOption = false
    self:ResetSelection()
    if not self:IsShown() or self.AnimGroup:IsPlaying(self, "HIDE") then return end
    self.AnimGroup:Stop()
    self.AnimGroup:Play(self, "HIDE"):onFinish(function() self:Hide() end)
end

function StoryOptionsBoxMixin:CloseImmediately()
    self.isSelectingOption = false
    self:ResetSelection()
    self.AnimGroup:Stop()
    self:Hide()
end

StoryOptionsBoxMixin.AnimGroup = UIAnim.New()
do
    local FadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.25):from(0):to(1)
    local OptionFadeIn = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.5):from(0):to(1)
    local OptionMoveIn = UIAnim.Animate():property(UIAnim.Enum.Property.PosY):easing(UIAnim.Enum.Easing.SineOut):duration(0.5):from(-5):to(0)
    StoryOptionsBoxMixin.AnimGroup:State("SHOW", function(frame)
        FadeIn:Play(frame)
        for index = 1, #frame.options do
            local element = frame.OptionsList:GetElement(index, "Default")
            local delay = (index - 1) * 0.05
            element:SetAlpha(0)
            OptionFadeIn:wait(delay):Play(element)
            OptionMoveIn:wait(delay):Play(element.ContainerFrame)
        end
    end)

    local FadeOut = UIAnim.Animate():property(UIAnim.Enum.Property.Alpha):duration(0.125):to(0)
    StoryOptionsBoxMixin.AnimGroup:State("HIDE", function(frame)
        FadeOut:Play(frame)
    end)
end

Mixin(LWStoryOptionsBox, StoryOptionsBoxMixin)
CallbackRegistry.Add("Preload.AddonReady", function()
    LWStoryDialogBox:OnLoad()
    LWStoryOptionsBox:OnLoad()
    if StoryMode.isActive then Refresh() end
end)



CallbackRegistry.Add("ControlCenter.QuestRewardChoiceSelected", StoryMode.OnQuestRewardChoiceSelected)
CallbackRegistry.Add("ControlCenter.SessionEnd", StoryMode.OnSessionEnd)
CallbackRegistry.Add("ControlCenter.ShowGossip", StoryMode.OnShowGossip)
CallbackRegistry.Add("ControlCenter.HideGossip", StoryMode.OnHideGossip)
CallbackRegistry.Add("ControlCenter.UpdateGossip", StoryMode.OnUpdateGossip)
CallbackRegistry.Add("ControlCenter.ShowQuest", StoryMode.OnShowQuest)
CallbackRegistry.Add("ControlCenter.HideQuest", StoryMode.OnHideQuest)
CallbackRegistry.Add("ControlCenter.UpdateQuest", StoryMode.OnUpdateQuest)
CallbackRegistry.Add("UNIT_PORTRAIT_UPDATE", StoryMode.OnPortraitUpdate)
CallbackRegistry.Add("PORTRAITS_UPDATED", StoryMode.OnPortraitUpdate)
CallbackRegistry.Add(DialogFrame.Events.CloseSessionRequested, StoryMode.OnCloseSessionRequested)
CallbackRegistry.Add(DialogFrame.Events.ActionRequested, StoryMode.OnActionRequested)
CallbackRegistry.Add(DialogFrame.Events.GossipOptionSelectionRequested, StoryMode.OnGossipOptionSelectionRequested)
CallbackRegistry.Add(DialogFrame.Events.QuestRewardSelectionRequested, StoryMode.OnQuestRewardSelectionRequested)


Modes_ModeHandler.RegisterMode(env.Enum.Mode.Story, StoryMode)
