local env = select(2, ...)
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local ControlCenter_Preload = env.modules:Import("@\\Dialog\\ControlCenter\\Preload")
local ControlCenter_ContextIcon = env.modules:Import("@\\Dialog\\ControlCenter\\ContextIcon")
local ControlCenter_DataProvider = env.modules:Import("@\\Dialog\\ControlCenter\\DataProvider")
local ControlCenter_Director = env.modules:Import("@\\Dialog\\ControlCenter\\Director")
local ControlCenter = env.modules:New("@\\Dialog\\ControlCenter")

local GetCampaignInfo = C_CampaignInfo and C_CampaignInfo.GetCampaignInfo
local C_GossipInfo_SelectAvailableQuest = C_GossipInfo.SelectAvailableQuest
local C_GossipInfo_SelectActiveQuest = C_GossipInfo.SelectActiveQuest
local SelectAvailableQuest = SelectAvailableQuest
local SelectActiveQuest = SelectActiveQuest
local UnitXPMax = UnitXPMax
local floor = math.floor
local format = string.format
local GetQuestPortraitGiver = GetQuestPortraitGiver
local GetQuestPortraitTurnIn = GetQuestPortraitTurnIn
local IsQuestCompletable = IsQuestCompletable


ControlCenter.gossipInfo = nil
ControlCenter.questInfo = nil
ControlCenter.rewardChoiceIndex = nil
ControlCenter.isGossipQuest = false

local function SetGossipQuest(isGossipQuest)
    ControlCenter.isGossipQuest = isGossipQuest
end

local function ResetCache()
    ControlCenter_DataProvider.ReleaseAllPools()
    ControlCenter.gossipInfo = nil
    ControlCenter.questInfo = nil
    ControlCenter.rewardChoiceIndex = nil
end

do --Events
    local function OnShowGossip()
        CallbackRegistry.Trigger("ControlCenter.ShowGossip")
    end

    local function OnHideGossip(_, interactionIsContinuing)
        CallbackRegistry.Trigger("ControlCenter.HideGossip", interactionIsContinuing)
    end

    local function OnShowQuest()
        CallbackRegistry.Trigger("ControlCenter.ShowQuest", ControlCenter_Director.questSessionType)
    end

    local function OnHideQuest()
        CallbackRegistry.Trigger("ControlCenter.HideQuest")
    end

    CallbackRegistry.Add("QUEST_GREETING", OnShowGossip)
    CallbackRegistry.Add("QUEST_GREETING_CLOSED", OnHideGossip)
    CallbackRegistry.Add("GOSSIP_SHOW", OnShowGossip)
    CallbackRegistry.Add("GOSSIP_CLOSED", OnHideGossip)
    CallbackRegistry.Add("QUEST_DETAIL", OnShowQuest)
    CallbackRegistry.Add("QUEST_PROGRESS", OnShowQuest)
    CallbackRegistry.Add("QUEST_COMPLETE", OnShowQuest)
    CallbackRegistry.Add("QUEST_FINISHED", OnHideQuest)
    CallbackRegistry.Add("QUEST_FINISHED", function() SetGossipQuest(false) end)
    CallbackRegistry.Add("GOSSIP_SHOW", function() SetGossipQuest(false) end)
end

do --Caching
    local function CacheInfo(event)
        local gossipSessionType, questSessionType = ControlCenter_Director.gossipSessionType, ControlCenter_Director.questSessionType

        if event == "ControlCenter.Update" then
            if gossipSessionType and ControlCenter.gossipInfo then
                local incomplete = ControlCenter.gossipInfo.gossipIncompleteQuests
                if incomplete and #incomplete > 0 then
                    ControlCenter.gossipInfo = ControlCenter_DataProvider.BuildGossipInfo()
                    CallbackRegistry.Trigger("ControlCenter.UpdateGossip")
                end
            end
            if questSessionType then
                local questID = ControlCenter.questInfo and ControlCenter.questInfo.questID
                local rewardChoiceIndex = ControlCenter.rewardChoiceIndex
                local rewardChoices = ControlCenter.questInfo and ControlCenter.questInfo.questRewardsChoice
                local rewardInfo = rewardChoices and rewardChoices[rewardChoiceIndex or 0]
                local rewardID = rewardInfo and rewardInfo.rewardID
                local rewardType = rewardInfo and rewardInfo.uk_poolElementType
                ResetCache()
                ControlCenter.questInfo = ControlCenter_DataProvider.BuildFullQuestInfoFromCurrentQuest()
                rewardChoices = ControlCenter.questInfo.questRewardsChoice
                rewardInfo = rewardChoices and rewardChoices[rewardChoiceIndex or 0]
                if questID == ControlCenter.questInfo.questID and rewardID and rewardInfo and rewardInfo.rewardID == rewardID and rewardInfo.uk_poolElementType == rewardType then
                    ControlCenter.rewardChoiceIndex = rewardChoiceIndex
                end
                CallbackRegistry.Trigger("ControlCenter.UpdateQuest")
            end
        else
            ResetCache()
            if gossipSessionType then
                ControlCenter.gossipInfo = ControlCenter_DataProvider.BuildGossipInfo()
            end
            if questSessionType then
                ControlCenter.questInfo = ControlCenter_DataProvider.BuildFullQuestInfoFromCurrentQuest()
                ControlCenter.rewardChoiceIndex = 0
            end
        end
    end

    CallbackRegistry.Add("ControlCenter.ShowGossip", CacheInfo)
    CallbackRegistry.Add("ControlCenter.ShowQuest", CacheInfo)
    CallbackRegistry.Add("ControlCenter.Update", CacheInfo)
end


do --Session
    function ControlCenter.IsInSession()
        return ControlCenter_Director.isInSession
    end

    function ControlCenter.GetGossipSessionType()
        return ControlCenter_Director.gossipSessionType
    end

    function ControlCenter.GetQuestSessionType()
        return ControlCenter_Director.questSessionType
    end

    function ControlCenter.IsGossipQuest()
        return ControlCenter.isGossipQuest
    end

    function ControlCenter.CloseSession()
        if ControlCenter_Director.questSessionType == ControlCenter_Preload.Enum.SessionType.Detail and ControlCenter.IsQuestAutoAccept() then return end
        ControlCenter_Director.EndSession(true)
    end
end

do --General
    function ControlCenter.GetNPCGUID()
        if not ControlCenter_Director.isInSession then return end
        return UnitGUID("questnpc") or UnitGUID("npc")
    end

    function ControlCenter.GetNPCName()
        if not ControlCenter_Director.isInSession then return end
        return UnitName("questnpc") or UnitName("npc")
    end

    function ControlCenter.SetUnitPortrait(textureObject)
        if ControlCenter_DataProvider.IsInteractingWithGameObject() then
            textureObject:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon")
        else
            SetPortraitTexture(textureObject, ControlCenter_DataProvider.GetInteractUnitID())
        end
    end
end

do --Gossip
    function ControlCenter.SelectGossipOption(optionType, optionKey)
        local sessionType = ControlCenter_Director.gossipSessionType
        local isGossip = sessionType == ControlCenter_Preload.Enum.SessionType.Gossip
        local isGreeting = sessionType == ControlCenter_Preload.Enum.SessionType.GossipGreeting

        if optionType == ControlCenter_Preload.Enum.OptionType.QuestAvailable then
            if isGossip then
                C_GossipInfo_SelectAvailableQuest(optionKey)
            elseif isGreeting then
                SelectAvailableQuest(optionKey)
            end
            SetGossipQuest(true)

        elseif optionType == ControlCenter_Preload.Enum.OptionType.QuestIncomplete or optionType == ControlCenter_Preload.Enum.OptionType.QuestComplete then
            if isGossip then
                C_GossipInfo_SelectActiveQuest(optionKey)
            elseif isGreeting then
                SelectActiveQuest(optionKey)
            end
            SetGossipQuest(true)

        elseif optionType == ControlCenter_Preload.Enum.OptionType.Gossip then
            ControlCenter_Director.SelectGossipOption(optionKey)
            SetGossipQuest(false)
        end
    end
end

do --Quest
    function ControlCenter.GetQuestPortrait()
        local questSessionType = ControlCenter_Director.questSessionType
        if questSessionType == ControlCenter_Preload.Enum.SessionType.Detail then
            return GetQuestPortraitGiver()
        elseif questSessionType == ControlCenter_Preload.Enum.SessionType.Complete then
            local portraitDisplayID, text, name = GetQuestPortraitTurnIn()
            return portraitDisplayID, text, name, 0, nil
        end
    end

    function ControlCenter.GetCampaignName()
        local questInfo = ControlCenter.questInfo
        if not questInfo or not questInfo.questCampaignID then return end
        local campaignInfo = GetCampaignInfo(questInfo.questCampaignID)
        return campaignInfo and campaignInfo.name
    end

    function ControlCenter.GetRewardXP()
        local questInfo = ControlCenter.questInfo
        if not questInfo then return end
        local xp = questInfo.questRewardExperience or 0
        local maxXP = UnitXPMax("player")
        local pct = maxXP > 0 and format("%0.1f", (xp / maxXP) * 100) or "0"
        return xp, pct
    end

    function ControlCenter.GetRewardMoney()
        local questInfo = ControlCenter.questInfo
        if not questInfo then return false, 0, 0, 0 end
        local money = questInfo.questRewardMoney or 0
        if money == 0 then return false, 0, 0, 0 end
        return true, money % 100, floor(money / 100) % 100, floor(money / 10000)
    end

    function ControlCenter.GetRewardMoneyFormatted()
        local valid, copper, silver, gold = ControlCenter.GetRewardMoney()
        if not valid then return end
        local _, iconSize = UIFont.ParchmentItemText:GetFont()
        iconSize = iconSize + 4
        local moneyText = gold > 0 and gold .. " |T" .. ControlCenter_ContextIcon.TexDef.Gold.path .. ":" .. iconSize .. ":" .. iconSize .. ":0:-2|t" or ""
        if silver > 0 then moneyText = moneyText .. (moneyText ~= "" and " " or "") .. silver .. " |T" .. ControlCenter_ContextIcon.TexDef.Silver.path .. ":" .. iconSize .. ":" .. iconSize .. ":0:-2|t" end
        if copper > 0 then moneyText = moneyText .. (moneyText ~= "" and " " or "") .. copper .. " |T" .. ControlCenter_ContextIcon.TexDef.Copper.path .. ":" .. iconSize .. ":" .. iconSize .. ":0:-2|t" end
        return moneyText
    end

    function ControlCenter.IsRewardSelected()
        local questInfo = ControlCenter.questInfo
        if not questInfo then return end
        local numChoices = questInfo.questRewardNumChoice or 0
        if numChoices <= 1 then return true end
        local rewardChoiceIndex = ControlCenter.rewardChoiceIndex
        return rewardChoiceIndex and rewardChoiceIndex > 0 and rewardChoiceIndex <= numChoices
    end

    function ControlCenter.CanContinueQuest()
        return ControlCenter_Director.questSessionType == ControlCenter_Preload.Enum.SessionType.Progress and IsQuestCompletable()
    end
end

do --Quest Actions
    function ControlCenter.AcceptQuest()
        if ControlCenter_Director.questSessionType ~= ControlCenter_Preload.Enum.SessionType.Detail then return end
        if ControlCenter.IsQuestAutoAccept() then
            AcknowledgeAutoAcceptQuest()
        else
            AcceptQuest()
        end
    end

    function ControlCenter.ContinueQuest()
        if ControlCenter.CanContinueQuest() then CompleteQuest() end
    end

    function ControlCenter.CompleteQuest()
        if ControlCenter_Director.questSessionType == ControlCenter_Preload.Enum.SessionType.Complete and ControlCenter.IsRewardSelected() then
            local rewardChoiceIndex = ControlCenter.rewardChoiceIndex or 0
            if ControlCenter.questInfo and ControlCenter.questInfo.questRewardNumChoice == 1 then
                rewardChoiceIndex = 1
            end
            GetQuestReward(rewardChoiceIndex)
        end
    end

    function ControlCenter.DeclineQuest()
        if ControlCenter_Director.questSessionType then DeclineQuest() end
    end

    function ControlCenter.SelectReward(index)
        if ControlCenter_Director.questSessionType ~= ControlCenter_Preload.Enum.SessionType.Complete then return end
        local rewardChoices = ControlCenter.questInfo and ControlCenter.questInfo.questRewardsChoice
        if not rewardChoices or not rewardChoices[index] then return end
        ControlCenter.rewardChoiceIndex = index
        CallbackRegistry.Trigger("ControlCenter.QuestRewardChoiceSelected", index)
    end
end

do --Dialog Options
    function ControlCenter.SelectDialogOption(optionIndex)
        if not optionIndex or optionIndex < 1 or optionIndex > 9 then return false end

        if ControlCenter_Director.gossipSessionType then
            local gossipInfo = ControlCenter.gossipInfo
            if not gossipInfo then return false end

            local gossipQuests = gossipInfo.gossipQuests
            local optionInfo = gossipQuests[optionIndex]
            if not optionInfo then
                local gossipOptions = gossipInfo.gossipOptions
                optionInfo = gossipOptions[optionIndex - #gossipQuests]
            end
            if not optionInfo then return false end

            ControlCenter.SelectGossipOption(optionInfo.optionType, optionInfo.optionKey)
            return true
        end

        if ControlCenter_Director.questSessionType == ControlCenter_Preload.Enum.SessionType.Complete then
            local questInfo = ControlCenter.questInfo
            local rewardChoices = questInfo and questInfo.questRewardsChoice
            local rewardInfo = rewardChoices and rewardChoices[optionIndex]
            if not rewardInfo or not rewardInfo.questRewardIndex then return false end

            ControlCenter.SelectReward(rewardInfo.questRewardIndex)
            return true
        end

        return false
    end
end

do --Retrieval API
    ControlCenter.GetCachedGossipInfo = function() return ControlCenter.gossipInfo end
    ControlCenter.GetCachedQuestInfo = function() return ControlCenter.questInfo end
    ControlCenter.GetGossipText = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipLore end
    ControlCenter.GetGossipOptions = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipOptions end
    ControlCenter.GetGossipOptionsQuestQuest = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipQuests end
    ControlCenter.GetGossipOptionsQuestQuestComplete = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipCompleteQuests end
    ControlCenter.GetGossipOptionsQuestQuestIncomplete = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipIncompleteQuests end
    ControlCenter.GetGossipOptionsQuestQuestAvailable = function() return ControlCenter.gossipInfo and ControlCenter.gossipInfo.gossipAvailableQuests end
    ControlCenter.HasGossipOptions = function()
        local gossipInfo = ControlCenter.gossipInfo
        if not gossipInfo then return false end
        return (gossipInfo.gossipOptions and gossipInfo.gossipOptions[1] ~= nil) or (gossipInfo.gossipAvailableQuests and gossipInfo.gossipAvailableQuests[1] ~= nil) or (gossipInfo.gossipIncompleteQuests and gossipInfo.gossipIncompleteQuests[1] ~= nil) or (gossipInfo.gossipCompleteQuests and gossipInfo.gossipCompleteQuests[1] ~= nil)
    end
    ControlCenter.IsGossipValidForUpdate = function()
        local gossipInfo = ControlCenter.gossipInfo
        if not gossipInfo then return false end
        return (gossipInfo.gossipIncompleteQuests and #gossipInfo.gossipIncompleteQuests > 0) or (gossipInfo.gossipCompleteQuests and #gossipInfo.gossipCompleteQuests > 0)
    end
    ControlCenter.IsQuestComplete = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsComplete end
    ControlCenter.IsQuestCompleteWarband = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsCompleteWarband end
    ControlCenter.IsQuestFailed = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsFailed end
    ControlCenter.IsQuestTrivial = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsTrivial end
    ControlCenter.IsQuestAccount = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsAccount end
    ControlCenter.IsQuestAutoAccept = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsAutoAccept end
    ControlCenter.IsQuestPartySync = function() return ControlCenter.questInfo and ControlCenter.questInfo.questIsPartySync end
    ControlCenter.GetQuestTimeLeft = function() return ControlCenter.questInfo and ControlCenter.questInfo.questTimeLeft end
    ControlCenter.GetQuestResetTime = function() return ControlCenter.questInfo and ControlCenter.questInfo.questResetTime end
    ControlCenter.GetQuestCampaignID = function() return ControlCenter.questInfo and ControlCenter.questInfo.questCampaignID end
    ControlCenter.GetQuestCampaignName = ControlCenter.GetCampaignName
    ControlCenter.GetQuestBackground = function() return ControlCenter.questInfo and ControlCenter.questInfo.questBackground end
    ControlCenter.GetQuestTagID = function() return ControlCenter.questInfo and ControlCenter.questInfo.questTagID end
    ControlCenter.GetQuestTagName = function() return ControlCenter.questInfo and ControlCenter.questInfo.questTagName end
    ControlCenter.GetQuestType = function() return ControlCenter.questInfo and ControlCenter.questInfo.questType end
    ControlCenter.GetQuestName = function() return ControlCenter.questInfo and ControlCenter.questInfo.questName end
    ControlCenter.GetQuestText = function() return ControlCenter.questInfo and ControlCenter.questInfo.questLore end
    ControlCenter.GetQuestObjectives = function() return ControlCenter.questInfo and ControlCenter.questInfo.questObjectives end
    ControlCenter.GetQuestObjectiveText = function() return ControlCenter.questInfo and ControlCenter.questInfo.questObjectiveText end
    ControlCenter.GetQuestSpellObjective = function() return ControlCenter.questInfo and ControlCenter.questInfo.questSpellObjective end
    ControlCenter.GetQuestRequired = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRequired end
    ControlCenter.GetQuestRequiredCurrencies = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRequiredCurrencies end
    ControlCenter.GetQuestRequiredMoney = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRequiredMoney end
    ControlCenter.GetQuestRewardChoice = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardsChoice end
    ControlCenter.GetQuestRewardReceive = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardReceive end
    ControlCenter.GetQuestRewardSpell = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardsSpell end
    ControlCenter.GetQuestRewardSkill = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardSkill end
    ControlCenter.GetQuestSelectedChoiceRewardIndex = function() return ControlCenter.rewardChoiceIndex end
    ControlCenter.IsQuestRewardSelected = ControlCenter.IsRewardSelected
    ControlCenter.GetQuestRewardCurrencies = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardCurrencies end
    ControlCenter.GetQuestRewardXP = ControlCenter.GetRewardXP
    ControlCenter.GetQuestRewardHonor = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardHonor end
    ControlCenter.GetQuestRewardMoney = ControlCenter.GetRewardMoney
    ControlCenter.GetQuestRewardMoneyFormatted = ControlCenter.GetRewardMoneyFormatted
    ControlCenter.GetQuestRewardArtifactInfo = function()
        local q = ControlCenter.questInfo
        return q and q.questRewardArtifactXP, q and q.questRewardArtifactCategory
    end
    ControlCenter.GetQuestRewardWarModeBonus = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardWarModeBonus end
    ControlCenter.GetQuestRewardMajorFactionReputationReward = function() return ControlCenter.questInfo and ControlCenter.questInfo.questRewardMajorFactionReputationReward end
    ControlCenter.AcceptCurrentQuest = ControlCenter.AcceptQuest
    ControlCenter.ContinueCurrentQuest = ControlCenter.ContinueQuest
    ControlCenter.CompleteCurrentQuest = ControlCenter.CompleteQuest
    ControlCenter.DeclineCurrentQuest = ControlCenter.DeclineQuest
    ControlCenter.SelectQuestReward = ControlCenter.SelectReward
end
