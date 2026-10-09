local env = select(2, ...)
local L = env.L
local Config = env.Config
local LazyTimer = env.modules:Import("packages\\lazy-timer")
local TextPlaybackUtil = env.modules:New("@\\Dialog\\TextPlaybackUtil")

local strlenutf8 = strlenutf8
local gmatch = string.gmatch
local gsub = string.gsub
local byte = string.byte
local find = string.find
local format = string.format
local sub = string.sub
local floor = math.floor
local max = math.max
local min = math.min
local tonumber = tonumber
local type = type


local TEXT_PLAYBACK_INTERVAL = 0.05
local TEXT_PLAYBACK_PAUSE_DURATION = 0.125
local TEXT_PLAYBACK_ALPHA_GRADIENT_LENGTH = 20

local AlphaGradientFirstFrameTimer = LazyTimer.New()


local function GetPlaybackInterval(playbackSpeed)
    playbackSpeed = max(tonumber(playbackSpeed) or 1, 0.1)
    local playbackSpeedModifier = tonumber(L["PLAYBACK_SPEED_MODIFIER"]) or 1
    return TEXT_PLAYBACK_INTERVAL / (playbackSpeed * playbackSpeedModifier)
end


function TextPlaybackUtil.GetCharacterStartIndex(text, characterIndex)
    local byteIndex = 1
    local currentCharacterIndex = 0

    while byteIndex <= #text do
        local characterStartIndex = byteIndex
        local characterByte = byte(text, byteIndex)
        if characterByte <= 127 then
            byteIndex = byteIndex + 1
        elseif characterByte <= 223 then
            byteIndex = byteIndex + 2
        elseif characterByte <= 239 then
            byteIndex = byteIndex + 3
        elseif characterByte <= 247 then
            byteIndex = byteIndex + 4
        else
            byteIndex = byteIndex + 1
        end

        currentCharacterIndex = currentCharacterIndex + 1
        if currentCharacterIndex == characterIndex then return characterStartIndex end
    end
end

function TextPlaybackUtil.GetCharacterEndIndex(text, characterIndex)
    local startIndex = TextPlaybackUtil.GetCharacterStartIndex(text, characterIndex)
    if not startIndex then return end

    local characterByte = byte(text, startIndex)
    if characterByte <= 127 then return startIndex end
    if characterByte <= 223 then return startIndex + 1 end
    if characterByte <= 239 then return startIndex + 2 end
    if characterByte <= 247 then return startIndex + 3 end
end

function TextPlaybackUtil.GetSubstring(text, firstCharacter, lastCharacter)
    local startIndex = TextPlaybackUtil.GetCharacterStartIndex(text, firstCharacter)
    local endIndex = TextPlaybackUtil.GetCharacterEndIndex(text, lastCharacter)
    return startIndex and endIndex and sub(text, startIndex, endIndex) or ""
end

function TextPlaybackUtil.AdjustForEscapeSequences(text, characterCount)
    if characterCount >= strlenutf8(text) then return characterCount end

    local currentText = TextPlaybackUtil.GetSubstring(text, 1, characterCount)
    local textureStartIndex = find(currentText, "|T[^|]*$")
    if textureStartIndex then
        local textureEndIndex = find(text, "|t", textureStartIndex)
        if textureEndIndex then
            return strlenutf8(sub(text, 1, textureEndIndex + 1))
        end
    end

    local atlasStartIndex = find(currentText, "|A[^|]*$")
    if atlasStartIndex then
        local atlasEndIndex = find(text, "|a", atlasStartIndex)
        if atlasEndIndex then
            return strlenutf8(sub(text, 1, atlasEndIndex + 1))
        end
    end

    return characterCount
end

function TextPlaybackUtil.IsPauseCharacter(character)
    local pauseCharacters = L["PLAYBACK_PAUSE_CHARACTERS"]
    for index = 1, #pauseCharacters do
        if find(pauseCharacters[index], character, 1, true) then
            return true
        end
    end
    return false
end

function TextPlaybackUtil.IsPlaybackEnabled()
    return Config.DBGlobal:GetVariable("Immersive_Playback")
end

function TextPlaybackUtil.IsAutoProgressEnabled()
    return Config.DBGlobal:GetVariable("Immersive_PlaybackAutoProgress")
end

function TextPlaybackUtil.GetAutoProgressDelay()
    return max(tonumber(Config.DBGlobal:GetVariable("Immersive_PlaybackAutoProgressDelay")) or 1, 0)
end

function TextPlaybackUtil.ShouldSplitParagraphs()
    return Config.DBGlobal:GetVariable("Immersive_SplitParagraphs")
end

function TextPlaybackUtil.SplitText(text, splitParagraphs)
    if not text or type(text) ~= "string" then return end

    text = gsub(text, " %s+", " ")
    text = gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = gsub(text, "|r", "")
    text = splitParagraphs and gsub(text, "\n+", "\n") or gsub(text, "([\\.|>|<|!|?|\n])%s+", "%1\n")

    local lines = {}
    for segment in gmatch(text, "[^\n]+") do
        segment = gsub(segment, "^%s*(.-)%s*$", "%1")
        if segment ~= "" then
            lines[#lines + 1] = segment
        end
    end

    return lines
end

function TextPlaybackUtil.CreateState(text, playbackSpeed)
    return {
        text           = text,
        elapsed        = 0,
        interval       = GetPlaybackInterval(playbackSpeed),
        pauseEnabled   = Config.DBGlobal:GetVariable("Immersive_PlaybackPunctuationPausing"),
        pauseActive    = false,
        pauseElapsed   = 0,
        lastPauseIndex = nil
    }
end

function TextPlaybackUtil.Update(state, elapsed)
    if state.pauseActive then
        state.pauseElapsed = state.pauseElapsed + elapsed
        if state.pauseElapsed < TEXT_PLAYBACK_PAUSE_DURATION then return end

        state.pauseActive = false
        state.pauseElapsed = 0
    end

    state.elapsed = state.elapsed + elapsed

    local textLength = strlenutf8(state.text)
    local characterCount = min(floor(state.elapsed / state.interval) + 1, textLength)
    characterCount = TextPlaybackUtil.AdjustForEscapeSequences(state.text, characterCount)

    if state.pauseEnabled and state.lastPauseIndex ~= characterCount then
        local lastCharacter = TextPlaybackUtil.GetSubstring(state.text, characterCount, characterCount)
        if TextPlaybackUtil.IsPauseCharacter(lastCharacter) then
            state.lastPauseIndex = characterCount
            state.pauseActive = true
        end
    end

    local currentText = TextPlaybackUtil.GetSubstring(state.text, 1, characterCount)
    local remainingText = TextPlaybackUtil.GetSubstring(state.text, characterCount + 1, textLength)
    return currentText, remainingText, characterCount >= textLength
end

function TextPlaybackUtil.CreateAlphaGradientState(text, playbackSpeed, firstFrameCallback)
    AlphaGradientFirstFrameTimer:Stop()

    return {
        text               = text,
        elapsed            = 0,
        interval           = GetPlaybackInterval(playbackSpeed),
        firstFrameCallback = firstFrameCallback
    }
end

function TextPlaybackUtil.UpdateAlphaGradient(state, fontString, elapsed)
    state.elapsed = state.elapsed + elapsed
    local characterProgress = state.elapsed / state.interval
    local gradientLength = min(max(characterProgress, 1), TEXT_PLAYBACK_ALPHA_GRADIENT_LENGTH)
    local isFinished = not fontString:SetAlphaGradient(characterProgress, gradientLength)

    local firstFrameCallback = state.firstFrameCallback
    state.firstFrameCallback = nil
    if firstFrameCallback then
        AlphaGradientFirstFrameTimer:SetAction(firstFrameCallback)
        AlphaGradientFirstFrameTimer:Start(0)
    end

    return isFinished
end

function TextPlaybackUtil.StopAlphaGradientPlayback()
    AlphaGradientFirstFrameTimer:Stop()
end

function TextPlaybackUtil.GetPreviewHexColor(fontString)
    local previewAlpha = Config.DBGlobal:GetVariable("Immersive_ContentPreviewAlpha")
    if previewAlpha == 0 then return "000000" end

    local previewModifier = 0.2 + min(max(tonumber(previewAlpha) or 0.5, 0), 1) / 1.25
    local red, green, blue = fontString:GetTextColor()

    red = min(max(floor(red * previewModifier * 255), 0), 255)
    green = min(max(floor(green * previewModifier * 255), 0), 255)
    blue = min(max(floor(blue * previewModifier * 255), 0), 255)
    return format("%02x%02x%02x", red, green, blue)
end
