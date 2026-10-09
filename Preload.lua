local env = select(2, ...)
local Sound = env.modules:Import("packages\\sound")
local CallbackRegistry = env.modules:Import("packages\\callback-registry")
local UIFont = env.modules:Import("packages\\ui-font")
local SavedVariables = env.modules:Import("packages\\saved-variables")
local Path = env.modules:Import("packages\\path")
local InputHandler = env.modules:Import("packages\\input-handler")
local WoWClient = env.modules:Import("packages\\wow-client")


env.NAME = "Lorewalker"
env.ICON = Path.Root .. "\\Art\\Icons\\Logo"
env.ICON_ALT = Path.Root .. "\\Art\\Icons\\Logo-White"
env.VERSION_STRING = "Beta 6"
env.VERSION_NUMBER = 000006
env.DEBUG_MODE = false


local L = {}; env.L = L


local Enum = {}; env.Enum = Enum
do
    Enum.Theme = {
        Light = 1,
        Dark  = 2
    }
    Enum.FrameTheme = {
        Default = 1,
        Forever = 2
    }
    Enum.Mode = {
        Classic   = 1,
        Immersive = 2,
        Story     = 3
    }
    Enum.CameraEffectsPreset = {
        None     = 1,
        Full     = 2,
        Balanced = 3,
        Custom   = 4
    }
    Enum.Actions = {
        Confirm        = 1,
        Close          = 2,
        ScrollDown     = 3,
        ScrollUp       = 4,
        ScrollLeft     = 5,
        ScrollRight    = 6,
        PreviousDialog = 7,
        NextDialog     = 8,
        SelectOption1  = 9,
        SelectOption2  = 10,
        SelectOption3  = 11,
        SelectOption4  = 12,
        SelectOption5  = 13,
        SelectOption6  = 14,
        SelectOption7  = 15,
        SelectOption8  = 16,
        SelectOption9  = 17
    }
    Enum.DefaultKeybindings = {
        [Enum.Actions.Confirm]        = {
            [InputHandler.Enum.InputDevices.KBM]     = "SPACE",
            [InputHandler.Enum.InputDevices.GamePad] = "PAD1"
        },
        [Enum.Actions.Close]          = {
            [InputHandler.Enum.InputDevices.KBM]     = "ESCAPE",
            [InputHandler.Enum.InputDevices.GamePad] = "PAD2"
        },
        [Enum.Actions.ScrollDown]     = {
            [InputHandler.Enum.InputDevices.KBM]     = "DOWN",
            [InputHandler.Enum.InputDevices.GamePad] = "PADDDOWN"
        },
        [Enum.Actions.ScrollUp]       = {
            [InputHandler.Enum.InputDevices.KBM]     = "UP",
            [InputHandler.Enum.InputDevices.GamePad] = "PADDUP"
        },
        [Enum.Actions.ScrollLeft]     = {
            [InputHandler.Enum.InputDevices.KBM]     = "LEFT",
            [InputHandler.Enum.InputDevices.GamePad] = "PADDLEFT"
        },
        [Enum.Actions.ScrollRight]    = {
            [InputHandler.Enum.InputDevices.KBM]     = "RIGHT",
            [InputHandler.Enum.InputDevices.GamePad] = "PADDRIGHT"
        },
        [Enum.Actions.PreviousDialog] = {
            [InputHandler.Enum.InputDevices.KBM]     = "Q",
            [InputHandler.Enum.InputDevices.GamePad] = "PADLSHOULDER"
        },
        [Enum.Actions.NextDialog]     = {
            [InputHandler.Enum.InputDevices.KBM]     = "E",
            [InputHandler.Enum.InputDevices.GamePad] = "PADRSHOULDER"
        },
        [Enum.Actions.SelectOption1]  = {
            [InputHandler.Enum.InputDevices.KBM] = "1"
        },
        [Enum.Actions.SelectOption2]  = {
            [InputHandler.Enum.InputDevices.KBM] = "2"
        },
        [Enum.Actions.SelectOption3]  = {
            [InputHandler.Enum.InputDevices.KBM] = "3"
        },
        [Enum.Actions.SelectOption4]  = {
            [InputHandler.Enum.InputDevices.KBM] = "4"
        },
        [Enum.Actions.SelectOption5]  = {
            [InputHandler.Enum.InputDevices.KBM] = "5"
        },
        [Enum.Actions.SelectOption6]  = {
            [InputHandler.Enum.InputDevices.KBM] = "6"
        },
        [Enum.Actions.SelectOption7]  = {
            [InputHandler.Enum.InputDevices.KBM] = "7"
        },
        [Enum.Actions.SelectOption8]  = {
            [InputHandler.Enum.InputDevices.KBM] = "8"
        },
        [Enum.Actions.SelectOption9]  = {
            [InputHandler.Enum.InputDevices.KBM] = "9"
        }
    }
end


local Config = {}; env.Config = Config
do
    Config.DBGlobal = nil
    Config.DBGlobalPersistent = nil
    Config.DBLocal = nil
    Config.DBLocalPersistent = nil

    local NAME_GLOBAL = "LorewalkerDB_Global"
    local NAME_GLOBAL_PERSISTENT = "LorewalkerDB_Global_Persistent"
    local NAME_LOCAL = "LorewalkerDB_Local"
    local NAME_LOCAL_PERSISTENT = "LorewalkerDB_Local_Persistent"

    ---@format disable
    local DB_GLOBAL_DEFAULTS            = {
        lastLoadedVersion = nil,
        fontPath = nil,
        dialogFrameBounds = {
            point = nil,
            x = nil,
            y = nil,
            width = nil,
            height = nil,
        },
        immersiveChatBubbleBounds = {
            point = nil,
            x = nil,
            y = nil,
        },
        storyDialogBoxBounds = {
            point = nil,
            x = nil,
            y = nil,
        },
        userKeybinds = {},

        Theme                                              = Enum.Theme.Light,
        FrameTheme                                         = WoWClient.IS_FOREVER and Enum.FrameTheme.Forever or Enum.FrameTheme.Default,
        ActiveMode                                         = Enum.Mode.Classic,
        BindingDevice                                      = InputHandler.Enum.InputDevices.KBM,

        DialogFontSizeOffset                               = 1, --100%
        ChatBubbleFontSizeOffset                           = 1, --100%
        LockFramePositions                                 = false,
        ConfirmUseInteractKey                              = false,

        HideUI                                             = false,
        CameraEffectsPreset                                = Enum.CameraEffectsPreset.None,
        CameraEffects_Zoom                                 = nil,
        CameraEffects_ShowVignette                         = nil,
        CameraEffects_PitchLimit                           = nil,
        CameraEffects_Fov                                  = nil,
        CameraEffects_Pan                                  = nil,
        CameraEffects_ShoulderOffset                       = nil,
        CameraEffects_HeadMovementStrength                 = nil,
        CameraEffects_FocusInteractTarget                  = nil,
        CameraEffects_FocusInteractTargetPitchStrength     = nil,
        CameraEffects_FocusInteractTargetYawStrength       = nil,

        ForceGossip                                        = false,
        ShowQuestLevel                                     = WoWClient.IS_FOREVER or WoWClient.IS_CLASSIC_ERA,
        CloseToPreviousPage                                = false,
        RightClickToClose                                  = true,
        Immersive_SplitParagraphs                          = true,
        Immersive_Playback                                 = false,
        Immersive_PlaybackSpeed                            = 1,
        Immersive_PlaybackAutoProgress                     = true,
        Immersive_PlaybackAutoProgressDelay                = 1,
        Immersive_PlaybackPunctuationPausing               = true,
        Immersive_PlaybackAutoClose                        = true,
        Immersive_ContentPreviewAlpha                      = .5,
        Story_PlaybackSpeed                                = 1,

        AudioGlobal                                        = true,
    }
    local DB_GLOBAL_PERSISTENT_DEFAULTS = {}
    local DB_LOCAL_DEFAULTS             = {}
    local DB_LOCAL_PERSISTENT_DEFAULTS  = {}
    ---@format enable

    local DB_GLOBAL_MIGRATION           = {}

    function Config.LoadDB()
        if LorewalkerDB_Global and LorewalkerDB_Global.lastLoadedVersion == env.VERSION_NUMBER then
            -- Same version, skip migration
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS)
        else
            -- Migrate if new version
            SavedVariables.RegisterDatabase(NAME_GLOBAL).defaults(DB_GLOBAL_DEFAULTS).migrationPlan(DB_GLOBAL_MIGRATION)
            SavedVariables.RegisterDatabase(NAME_GLOBAL_PERSISTENT).defaults(DB_GLOBAL_PERSISTENT_DEFAULTS)
        end

        SavedVariables.RegisterDatabase(NAME_LOCAL).defaults(DB_LOCAL_DEFAULTS)
        SavedVariables.RegisterDatabase(NAME_LOCAL_PERSISTENT).defaults(DB_LOCAL_PERSISTENT_DEFAULTS)

        Config.DBGlobal = SavedVariables.GetDatabase(NAME_GLOBAL)
        Config.DBGlobalPersistent = SavedVariables.GetDatabase(NAME_GLOBAL_PERSISTENT)
        Config.DBLocal = SavedVariables.GetDatabase(NAME_LOCAL)
        Config.DBLocalPersistent = SavedVariables.GetDatabase(NAME_LOCAL_PERSISTENT)

        CallbackRegistry.Trigger("Preload.DatabaseReady")
    end
end


local SoundHandler = {}
do
    local function UpdateMainSoundLayer()
        local Settings_AudioGlobal = Config.DBGlobal:GetVariable("AudioGlobal")

        if Settings_AudioGlobal == true then
            Sound.SetEnabled("Main", true)
        elseif Settings_AudioGlobal == false then
            Sound.SetEnabled("Main", false)
        end
    end

    SavedVariables.OnChange("LorewalkerDB_Global", "AudioGlobal", UpdateMainSoundLayer)

    function SoundHandler.Load()
        UpdateMainSoundLayer()
    end
end


local FontHandler = {}
do
    local function UpdateFontSizes()
        local dialogFontSizeOffset = Config.DBGlobal:GetVariable("DialogFontSizeOffset")
        local chatBubbleFontSizeOffset = Config.DBGlobal:GetVariable("ChatBubbleFontSizeOffset")

        UIFont.ImmersiveChatBubbleFont:SetFontHeight(UIFont.LWFontSizeDef.ImmersiveChatBubbleFont * chatBubbleFontSizeOffset)
        UIFont.ParchmentText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentText * dialogFontSizeOffset)
        UIFont.ParchmentOptionText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentOptionText * dialogFontSizeOffset)
        UIFont.ParchmentItemText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentItemText * dialogFontSizeOffset)
        UIFont.ParchmentCategoryLabelText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentCategoryLabelText * dialogFontSizeOffset)
        UIFont.ParchmentHeaderPrimaryText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentHeaderPrimaryText * dialogFontSizeOffset)
        UIFont.ParchmentHeaderSecondaryText:SetFontHeight(UIFont.LWFontSizeDef.ParchmentHeaderSecondaryText * dialogFontSizeOffset)
    end

    local function UpdateFonts()
        UIFont.CustomFont:RefreshFontList()

        local fontPath = Config.DBGlobal:GetVariable("fontPath")
        if fontPath == nil or not UIFont.CustomFont.FontExists(fontPath) then
            fontPath = UIFont.CustomFont.GetFontPathForIndex(1)
        end

        UIFont.ImmersiveChatBubbleFont:SetFontFile(fontPath)
        UIFont.ParchmentText:SetFontFile(fontPath)
        UIFont.ParchmentOptionText:SetFontFile(fontPath)
        UIFont.ParchmentItemText:SetFontFile(fontPath)
        UIFont.ParchmentRewardTagText:SetFontFile(fontPath)
        UIFont.ParchmentCategoryLabelText:SetFontFile(fontPath)
        UIFont.ParchmentHeaderPrimaryText:SetFontFile(fontPath)
        UIFont.ParchmentHeaderSecondaryText:SetFontFile(fontPath)

        UIFont.SetNormalFont(fontPath)
        Config.DBGlobal:SetVariable("fontPath", fontPath)
    end

    SavedVariables.OnChange("LorewalkerDB_Global", "fontPath", UpdateFonts)
    SavedVariables.OnChange("LorewalkerDB_Global", "DialogFontSizeOffset", UpdateFontSizes)
    SavedVariables.OnChange("LorewalkerDB_Global", "ChatBubbleFontSizeOffset", UpdateFontSizes)

    function FontHandler.Load()
        UpdateFonts()
        UpdateFontSizes()
    end
end


do --Input
    InputHandler.Keybindings = InputHandler.NewBindingManager(Enum.Actions, Enum.DefaultKeybindings, function() return Config.DBGlobal end, "userKeybinds")
end


local function LoadAddon()
    Config.LoadDB()
    SoundHandler.Load()

    Config.DBGlobal:SetVariable("lastLoadedVersion", env.VERSION_NUMBER)
    CallbackRegistry.Trigger("Preload.AddonReady")
end

CallbackRegistry.Add("WoWClient.OnAddonLoaded", LoadAddon)
CallbackRegistry.Add("WoWClient.OnPlayerLogin", FontHandler.Load)
