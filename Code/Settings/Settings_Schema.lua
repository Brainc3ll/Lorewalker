--[[
    widgetName:                         string
    widgetDecsription:                  Settings_Define.Descriptor
    widgetType:                         Settings_Enum.WidgetType
    widgetTransparent:                  boolean

    Shared:
        key:                            string
        set:                            function

    Tab:
        widgetTab_isFooter:             boolean

    Title:
        widgetTitle_info:               Settings_Define.TitleInfo

    Container:
        widgetContainer_isNested:       boolean

    Text:

    Range:
        widgetRange_min:                number|function
        widgetRange_max:                number|function
        widgetRange_step:               number|function
        widgetRange_textFormatting      string (%s: value)
        widgetRange_textFormattingFunc: function

    Button:
        widgetButton_text:              string
        widgetButton_refreshOnClick:    boolean

    CheckButton:

    SelectionMenu:
        widgetSelectionMenu_data:       table|function
        widgetSelectionMenu_get:        function
        widgetSelectionMenu_set:        function

    Color Input:

    Input:
        widgetInput_placeholder:        string|function

    Binding Button:
        widgetBindingButton_action:     env.Enum.Actions

    disableWhen:                        function
    showWhen:                           function
    indent:                             number
    children:                           table
]]

local env = select(2, ...)
local Config = env.Config
local L = env.L
local UIFont = env.modules:Import("packages\\ui-font")
local InputHandler = env.modules:Import("packages\\input-handler")
local SharedUtil = env.modules:Import("@\\Dialog\\SharedUtil")
local Modes_ModeHandler = env.modules:Import("@\\Dialog\\Modes\\ModeHandler")
local Settings_Define = env.modules:Import("@\\Settings\\Define")
local Settings_Enum = env.modules:Import("@\\Settings\\Enum")
local Settings_Preload = env.modules:Import("@\\Settings\\Preload")
local Settings_Schema = env.modules:New("@\\Settings\\Schema")

Settings_Schema.BINDING_BUTTON_OPTIONS = {
    manager = InputHandler.Keybindings,
    textFormattingFunc = SharedUtil.GetHotkeyText,
    getDevice = function()
        return Config.DBGlobal:GetVariable("BindingDevice")
    end,
    isAllowed = function(key, device)
        return device == Config.DBGlobal:GetVariable("BindingDevice") and not key:find("BUTTON%d+") and not key:find("MOUSEWHEEL")
    end
}

local SettingsPrompt = _G[Settings_Preload.FRAME_NAME].Prompt

local function HandleAccept()
    Config.DBGlobal:Wipe()
    ReloadUI()
end

local function HandleRestorePositionsAccept()
    Config.DBGlobal:SetVariable("dialogFrameBounds", nil)
    Config.DBGlobal:SetVariable("immersiveChatBubbleBounds", nil)
    Config.DBGlobal:SetVariable("storyDialogBoxBounds", nil)
    ReloadUI()
end

local RESET_PROMPT = {
    text         = L["CONFIG_GENERAL_OTHER_RESETPROMPT"],
    options      = {
        {
            text     = L["CONFIG_GENERAL_OTHER_RESETPROMPT_YES"],
            callback = HandleAccept
        },
        {
            text     = L["CONFIG_GENERAL_OTHER_RESETPROMPT_NO"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}

local RESTORE_POSITIONS_PROMPT = {
    text         = L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT"],
    options      = {
        {
            text     = L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT_YES"],
            callback = HandleRestorePositionsAccept
        },
        {
            text     = L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS_PROMPT_NO"],
            callback = nil
        }
    },
    hideOnEscape = true,
    timeout      = 10
}

do -- Schema
    local function FormatPercentage(value) return string.format("%0.0f", value * 100) .. "%" end
    local function FormatSeconds(value) return string.format(L["FORMAT_SECONDS"], value) end
    local function IsKeyboardBindingDevice() return Config.DBGlobal:GetVariable("BindingDevice") == InputHandler.Enum.InputDevices.KBM end
    local function IsImmersivePlaybackDisabled() return not Config.DBGlobal:GetVariable("Immersive_Playback") end

    Settings_Schema.SCHEMA = {
        {
            widgetName = L["CONFIG_GENERAL"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_GENERAL_PREFERENCES"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName               = L["CONFIG_GENERAL_PREFERENCES_FONT"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = function()
                                UIFont.CustomFont:RefreshFontList()
                                return UIFont.CustomFont:GetFontNames()
                            end,
                            widgetSelectionMenu_get  = function(value)
                                return UIFont.CustomFont.GetFontIndexForPath(value)
                            end,
                            widgetSelectionMenu_set  = function(index)
                                return UIFont.CustomFont.GetFontPathForIndex(index)
                            end,
                            key                      = "fontPath"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_GENERAL_OTHER"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName        = nil,
                            widgetType        = Settings_Enum.WidgetType.Button,
                            widgetButton_text = L["CONFIG_GENERAL_OTHER_RESETBUTTON"],
                            set               = function() SettingsPrompt:Open(RESET_PROMPT) end
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_DIALOGUE"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                    widgetTransparent        = true,
                    widgetSelectionMenu_data = {
                        L["CONFIG_DIALOGUE_MODE_CLASSIC"],
                        L["CONFIG_DIALOGUE_MODE_IMMERSIVE"]
                        -- L["CONFIG_DIALOGUE_MODE_STORY"]
                    },
                    widgetSelectionMenu_set  = function(index)
                        Modes_ModeHandler.SetMode(index)
                        return Modes_ModeHandler.GetMode()
                    end,
                    key                      = "ActiveMode"
                },
                {
                    widgetName = L["CONFIG_DIALOGUE_PREFERENCES"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_DIALOGUE_PREFERENCES_FORCEGOSSIP"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "ForceGossip"
                        },
                        {
                            widgetName = L["CONFIG_DIALOGUE_PREFERENCES_SHOWQUESTLEVEL"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "ShowQuestLevel"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_DIALOGUE_FRAME"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_DIALOGUE_RIGHTCLICKTOCLOSE"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "RightClickToClose"
                        },
                        {
                            widgetName        = L["CONFIG_DIALOGUE_CLOSETOPREVIOUSPAGE"],
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONFIG_DIALOGUE_CLOSETOPREVIOUSPAGE_DESCRIPTION"] },
                            widgetType        = Settings_Enum.WidgetType.CheckButton,
                            key               = "CloseToPreviousPage"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_DIALOGUE_IMMERSIVE"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    showWhen   = function() return Config.DBGlobal:GetVariable("ActiveMode") == env.Enum.Mode.Immersive end,
                    children   = {
                        {
                            widgetName        = L["CONFIG_DIALOGUE_IMMERSIVE_SPLITPARAGRAPHS"],
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONFIG_DIALOGUE_IMMERSIVE_SPLITPARAGRAPHS_DESCRIPTION"] },
                            widgetType        = Settings_Enum.WidgetType.CheckButton,
                            key               = "Immersive_SplitParagraphs"
                        },
                        {
                            widgetName        = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACK"],
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACK_DESCRIPTION"] },
                            widgetType        = Settings_Enum.WidgetType.CheckButton,
                            key               = "Immersive_Playback"
                        },
                        {
                            widgetName                     = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKSPEED"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0.5,
                            widgetRange_max                = 2,
                            widgetRange_step               = 0.1,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "Immersive_PlaybackSpeed",
                            indent                         = 1,
                            disableWhen                    = IsImmersivePlaybackDisabled
                        },
                        {
                            widgetName  = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOPROGRESS"],
                            widgetType  = Settings_Enum.WidgetType.CheckButton,
                            key         = "Immersive_PlaybackAutoProgress",
                            indent      = 1,
                            disableWhen = IsImmersivePlaybackDisabled
                        },
                        {
                            widgetName                     = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOPROGRESSDELAY"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0,
                            widgetRange_max                = 5,
                            widgetRange_step               = 0.5,
                            widgetRange_textFormattingFunc = FormatSeconds,
                            key                            = "Immersive_PlaybackAutoProgressDelay",
                            indent                         = 2,
                            disableWhen                    = function() return IsImmersivePlaybackDisabled() or not Config.DBGlobal:GetVariable("Immersive_PlaybackAutoProgress") end
                        },
                        {
                            widgetName  = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKPUNCTUATIONPAUSING"],
                            widgetType  = Settings_Enum.WidgetType.CheckButton,
                            key         = "Immersive_PlaybackPunctuationPausing",
                            indent      = 1,
                            disableWhen = IsImmersivePlaybackDisabled
                        },
                        {
                            widgetName        = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOCLOSE"],
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONFIG_DIALOGUE_IMMERSIVE_PLAYBACKAUTOCLOSE_DESCRIPTION"] },
                            widgetType        = Settings_Enum.WidgetType.CheckButton,
                            key               = "Immersive_PlaybackAutoClose",
                            indent            = 1,
                            disableWhen       = IsImmersivePlaybackDisabled
                        },
                        {
                            widgetName                     = L["CONFIG_DIALOGUE_IMMERSIVE_CONTENTPREVIEWALPHA"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0,
                            widgetRange_max                = 1,
                            widgetRange_step               = 0.05,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "Immersive_ContentPreviewAlpha",
                            indent                         = 1,
                            disableWhen                    = IsImmersivePlaybackDisabled
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_EFFECTS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_EFFECTS"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_EFFECTS_HIDEUI"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "HideUI"
                        },
                        {
                            widgetName               = L["CONFIG_EFFECTS_CAMERA"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = {
                                L["CONFIG_EFFECTS_CAMERA_NONE"],
                                L["CONFIG_EFFECTS_CAMERA_FULL"],
                                L["CONFIG_EFFECTS_CAMERA_BALANCED"]
                            },
                            key                      = "CameraEffectsPreset"
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_TTS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["WIP"],
                    widgetType = Settings_Enum.WidgetType.Text
                }
            }
        },
        {
            widgetName = L["CONFIG_KEYBINDINGS"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                    widgetTransparent        = true,
                    widgetSelectionMenu_data = {
                        L["CONFIG_KEYBINDINGS_DEVICE_KBM"],
                        L["CONFIG_KEYBINDINGS_DEVICE_GAMEPAD"]
                    },
                    key                      = "BindingDevice"
                },
                {
                    widgetName = L["CONFIG_KEYBINDINGS_ACTIONS"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_CONFIRM"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.Confirm,
                            disableWhen                = function() return Config.DBGlobal:GetVariable("ConfirmUseInteractKey") end
                        },
                        {
                            widgetName = L["CONFIG_KEYBINDINGS_CONFIRM_USEINTERACTKEY"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "ConfirmUseInteractKey",
                            indent     = 1
                        },
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_CLOSE"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.Close
                        },
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_SCROLLDOWN"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.ScrollDown
                        },
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_SCROLLUP"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.ScrollUp
                        },
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_PREVIOUSDIALOG"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.PreviousDialog
                        },
                        {
                            widgetName                 = L["CONFIG_KEYBINDINGS_NEXTDIALOG"],
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.NextDialog
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 1),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption1,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 2),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption2,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 3),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption3,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 4),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption4,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 5),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption5,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 6),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption6,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 7),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption7,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 8),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption8,
                            showWhen                   = IsKeyboardBindingDevice
                        },
                        {
                            widgetName                 = string.format(L["CONFIG_KEYBINDINGS_SELECTOPTION"], 9),
                            widgetType                 = Settings_Enum.WidgetType.BindingButton,
                            widgetBindingButton_action = env.Enum.Actions.SelectOption9,
                            showWhen                   = IsKeyboardBindingDevice
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_APPEARANCE"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_APPEARANCE_POSITION"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_APPEARANCE_POSITION_LOCKFRAMEPOSITIONS"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "LockFramePositions"
                        },
                        {
                            widgetName        = nil,
                            widgetType        = Settings_Enum.WidgetType.Button,
                            widgetButton_text = L["CONFIG_APPEARANCE_POSITION_RESTOREPOSITIONS"],
                            set               = function() SettingsPrompt:Open(RESTORE_POSITIONS_PROMPT) end
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_APPEARANCE_DIALOG"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName               = L["CONFIG_APPEARANCE_DIALOG_THEME"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = {
                                L["CONFIG_APPEARANCE_DIALOG_THEME_LIGHT"],
                                L["CONFIG_APPEARANCE_DIALOG_THEME_DARK"]
                            },
                            key                      = "Theme"
                        },
                        {
                            widgetName               = L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME"],
                            widgetType               = Settings_Enum.WidgetType.SelectionMenu,
                            widgetSelectionMenu_data = {
                                L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME_DEFAULT"],
                                L["CONFIG_APPEARANCE_DIALOG_FRAMETHEME_FOREVER"]
                            },
                            key                      = "FrameTheme"
                        },
                        {
                            widgetName                     = L["CONFIG_APPEARANCE_DIALOG_FONTSIZE"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0.8,
                            widgetRange_max                = 1.2,
                            widgetRange_step               = 0.1,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "DialogFontSizeOffset"
                        }
                    }
                },
                {
                    widgetName = L["CONFIG_APPEARANCE_IMMERSIVE"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    showWhen   = function() return Config.DBGlobal:GetVariable("ActiveMode") == env.Enum.Mode.Immersive end,
                    children   = {
                        {
                            widgetName                     = L["CONFIG_APPEARANCE_IMMERSIVE_FONTSIZE"],
                            widgetType                     = Settings_Enum.WidgetType.Range,
                            widgetRange_min                = 0.8,
                            widgetRange_max                = 1.2,
                            widgetRange_step               = 0.1,
                            widgetRange_textFormattingFunc = FormatPercentage,
                            key                            = "ChatBubbleFontSizeOffset"
                        }
                    }
                }
            }
        },
        {
            widgetName = L["CONFIG_AUDIO"],
            widgetType = Settings_Enum.WidgetType.Tab,
            children   = {
                {
                    widgetName = L["CONFIG_AUDIO_GENERAL"],
                    widgetType = Settings_Enum.WidgetType.Container,
                    children   = {
                        {
                            widgetName = L["CONFIG_AUDIO_GENERAL_ENABLEGLOBALAUDIO"],
                            widgetType = Settings_Enum.WidgetType.CheckButton,
                            key        = "AudioGlobal"
                        }
                    }
                }
            }
        },
        {
            widgetName         = L["CONFIG_ABOUT"],
            widgetType         = Settings_Enum.WidgetType.Tab,
            widgetTab_isFooter = true,
            children           = {
                {
                    widgetName       = L["CONFIG_ABOUT"],
                    widgetType       = Settings_Enum.WidgetType.Title,
                    widgetTitle_info = Settings_Define.TitleInfo{ imagePath = env.ICON_ALT, text = env.NAME, subtext = env.VERSION_STRING }
                },
                {
                    widgetName        = L["CONFIG_ABOUT_CONTRIBUTORS"],
                    widgetType        = Settings_Enum.WidgetType.Container,
                    widgetTransparent = true,
                    children          = {
                        {
                            widgetName        = L["CONTRIBUTORS_ZAMESTOTV"],
                            widgetType        = Settings_Enum.WidgetType.Text,
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONTRIBUTORS_ZAMESTOTV_DESCRIPTION"] },
                            widgetTransparent = true
                        },
                        {
                            widgetName        = L["CONTRIBUTORS_CRAZYYOUNGS"],
                            widgetType        = Settings_Enum.WidgetType.Text,
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONTRIBUTORS_CRAZYYOUNGS_DESCRIPTION"] },
                            widgetTransparent = true
                        },
                        {
                            widgetName        = L["CONTRIBUTORS_LANJIAN625"],
                            widgetType        = Settings_Enum.WidgetType.Text,
                            widgetDescription = Settings_Define.Descriptor{ description = L["CONTRIBUTORS_LANJIAN625_DESCRIPTION"] },
                            widgetTransparent = true
                        }
                    }
                },
                {
                    widgetName        = L["CONFIG_ABOUT_DEVELOPER"],
                    widgetType        = Settings_Enum.WidgetType.Container,
                    widgetTransparent = true,
                    children          = {
                        {
                            widgetName        = L["CONFIG_ABOUT_DEVELOPER_ADAPTIVEX"],
                            widgetType        = Settings_Enum.WidgetType.Text,
                            widgetTransparent = true
                        }
                    }
                }
            }
        }
    }
end
