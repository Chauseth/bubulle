--[[
    Bubulle - UI/HUD.lua
    ------------------------------------------------------------------
    Le panneau de l'assistant, affiché pendant la pêche :

      ┌────────────────────────────────────────────┐
      │ ●  Bubulle · Mode pêche                ≡ ✕ │
      │  ╭─────╮  ┌──────────────────────────────┐ │
      │  │ 🐠  │ ◀│ Oh ! Une nouvelle espèce :   │ │
      │  │(img)│  │ Perche mordorée !            │ │
      │  ╰─────╯  └──────────────────────────────┘ │
      │ Forêt d'Elwynn · Lac Cristal               │
      │ ███████████████░░░░░░  Bouchon à l'eau 14 s│
      │    12        18        64        67%       │
      │  prises   lancers   / heure   réussite     │
      │ [■][■][■][■][■][■]   (dernières prises)    │
      │ Session 18:42   110 (+52) / 150 · Appât 9m │
      └────────────────────────────────────────────┘

    Il se déplace en tirant le bandeau du haut (sauf s'il est verrouillé).
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets
local c = Theme.color

local HUD = {}
ns.HUD = HUD

local WIDTH = 300
local HEIGHT = 268
local ICONS = 7
local ICON_SIZE = 28
local MODEL_SIZE = 88

local frame

local function BuildHeader()
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(26)
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    Theme.Fill(headerBg, c.header)

    frame.dot = header:CreateTexture(nil, "ARTWORK")
    frame.dot:SetSize(7, 7)
    frame.dot:SetPoint("LEFT", 10, 0)
    Theme.Fill(frame.dot, c.accent)

    local pulse = frame.dot:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.25)
    fade:SetDuration(0.6)
    frame.pulse = pulse

    frame.title = W.Text(header, Theme.font.body)
    frame.title:SetPoint("LEFT", frame.dot, "RIGHT", 8, 0)
    frame.title:SetText("Bubulle")

    frame.status = W.Text(header, Theme.font.tiny)
    frame.status:SetPoint("LEFT", frame.title, "RIGHT", 6, 0)

    local close = W.GlyphButton(header, "close", 18)
    close:SetPoint("RIGHT", -4, 0)
    close:SetScript("OnClick", function()
        if ns.Fishing.active then
            ns.Fishing:SetActive(false)
        end
        ns.db.settings.hudAlways = false
        HUD:UpdateVisibility()
    end)
    W.SetTooltip(close, L.HUD_CLOSE, L.HUD_CLOSE_TIP)

    local menu = W.GlyphButton(header, "menu", 18)
    menu:SetPoint("RIGHT", close, "LEFT", -2, 0)
    menu:SetScript("OnClick", function() ns.Window:Toggle() end)
    W.SetTooltip(menu, L.HUD_JOURNAL)

    W.MakeMovable(frame, "hud", header, function() return ns.db.settings.hudLocked end)
end

local function BuildAssistant()
    -- Bubulle (son illustration qui nage)
    frame.mascot = ns.Mascot:CreateModel(frame, MODEL_SIZE)
    frame.mascot:SetPoint("TOPLEFT", 4, -28)

    -- Bulle de dialogue
    local bubble = W.Panel(frame, c.bubble, c.border)
    bubble:SetPoint("TOPLEFT", MODEL_SIZE + 10, -36)
    bubble:SetPoint("TOPRIGHT", -10, -36)
    bubble:SetHeight(66)
    frame.bubble = bubble

    -- La petite pointe de la bulle, vers Bubulle
    local tailHolder = CreateFrame("Frame", nil, bubble)
    tailHolder:SetAllPoints()
    tailHolder:SetFrameLevel(bubble:GetFrameLevel() + 2)
    local tail = tailHolder:CreateTexture(nil, "OVERLAY")
    tail:SetSize(10, 10)
    tail:SetPoint("CENTER", bubble, "LEFT", 1, 0)
    tail:SetRotation(math.rad(45))
    Theme.Fill(tail, c.bubble)
    local tailEdge = tailHolder:CreateTexture(nil, "ARTWORK")
    tailEdge:SetSize(12, 12)
    tailEdge:SetPoint("CENTER", bubble, "LEFT", 0, 0)
    tailEdge:SetRotation(math.rad(45))
    Theme.Fill(tailEdge, c.border)

    local textHolder = CreateFrame("Frame", nil, bubble)
    textHolder:SetAllPoints()
    textHolder:SetFrameLevel(bubble:GetFrameLevel() + 3)
    frame.say = W.Text(textHolder, Theme.font.body)
    frame.say:SetPoint("TOPLEFT", 12, -8)
    frame.say:SetPoint("BOTTOMRIGHT", -10, 8)
    frame.say:SetJustifyV("MIDDLE")
    frame.say:SetWordWrap(true)
    frame.say:SetMaxLines(3)
    frame.say:SetSpacing(2)

    local appear = frame.say:CreateAnimationGroup()
    local alpha = appear:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.25)
    frame.sayAppear = appear

    -- Équipement (compétence, appât) à droite, lieu à gauche
    frame.location = W.Text(frame, Theme.font.small)
    frame.location:SetPoint("TOPLEFT", 12, -122)
    frame.location:SetPoint("RIGHT", -12, 0)
end

local function BuildStats()
    -- Barre du bouchon
    frame.bar = W.Bar(frame, 18)
    frame.bar:SetPoint("TOPLEFT", 10, -140)
    frame.bar:SetPoint("TOPRIGHT", -10, -140)

    frame.barText = W.Text(frame.bar, Theme.font.tiny)
    frame.barText:SetPoint("LEFT", 8, 0)
    frame.barText:SetPoint("RIGHT", -44, 0)
    Theme.Paint(frame.barText, c.text)

    frame.barTime = W.Text(frame.bar, Theme.font.numberTiny, "RIGHT")
    frame.barTime:SetPoint("RIGHT", -6, 0)

    -- Chiffres
    frame.stats = {}
    local labels = { L.STAT_CATCHES, L.STAT_CASTS, L.STAT_PER_HOUR, L.STAT_SUCCESS_SHORT }
    local cellWidth = (WIDTH - 20) / #labels
    for i, label in ipairs(labels) do
        local value = W.Text(frame, Theme.font.numberSmall, "CENTER")
        value:SetPoint("TOP", frame, "TOPLEFT", 10 + cellWidth * (i - 0.5), -166)
        value:SetText("0")
        local caption = W.Text(frame, Theme.font.tiny, "CENTER")
        caption:SetPoint("TOP", value, "BOTTOM", 0, -2)
        caption:SetText(label)
        frame.stats[i] = value
    end

    -- Dernières prises
    frame.icons = {}
    local gap = (WIDTH - 20 - ICONS * ICON_SIZE) / (ICONS - 1)
    for i = 1, ICONS do
        local icon = W.ItemIcon(frame, ICON_SIZE)
        icon:SetPoint("TOPLEFT", 10 + (i - 1) * (ICON_SIZE + gap), -206)
        icon:Hide()
        frame.icons[i] = icon
    end
    frame.noCatch = W.Text(frame, Theme.font.tiny, "CENTER")
    frame.noCatch:SetPoint("TOPLEFT", 10, -214)
    frame.noCatch:SetPoint("TOPRIGHT", -10, -214)
    frame.noCatch:SetText(L.HUD_NO_CATCH)

    -- Pied
    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("BOTTOMLEFT", 1, 24)
    divider:SetPoint("BOTTOMRIGHT", -1, 24)
    Theme.Fill(divider, c.border)

    frame.clock = W.Text(frame, Theme.font.tiny)
    frame.clock:SetPoint("BOTTOMLEFT", 12, 8)

    -- Compétence et appât, à droite du chrono
    frame.gear = W.Text(frame, Theme.font.tiny, "RIGHT")
    frame.gear:SetPoint("BOTTOMRIGHT", -12, 8)
end

local function Build()
    frame = CreateFrame("Frame", "BubulleHUD", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    Theme.Backdrop(frame, c.bg, c.border)
    frame:Hide()
    W.AttachFader(frame, 0.2)

    BuildHeader()
    BuildAssistant()
    BuildStats()

    -- Rafraîchissement régulier (barre, chrono, réplique)
    local elapsedSince, gearTimer = 0, 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        elapsedSince = elapsedSince + elapsed
        if elapsedSince < 0.05 then return end
        elapsedSince = 0
        HUD:UpdateBar()
        HUD:UpdateSpeech()
        gearTimer = gearTimer + 0.05
        if gearTimer > 5 then
            gearTimer = 0
            HUD:UpdateGear()
        end
    end)

    HUD:ApplySettings()
end

------------------------------------------------------------------------
-- Mises à jour
------------------------------------------------------------------------
function HUD:UpdateSpeech()
    local line = ns.Assistant:GetLine()
    if line ~= frame.shownLine then
        frame.shownLine = line
        frame.say:SetText(line)
        frame.sayAppear:Stop()
        frame.sayAppear:Play()
    end
end

function HUD:UpdateBar()
    local remaining, total = ns.Fishing:GetChannelProgress()
    if remaining then
        frame.bar:SetMinMaxValues(0, total)
        frame.bar:SetValue(remaining)
        local color = remaining < 4 and c.accent or c.water
        frame.bar:SetStatusBarColor(color[1], color[2], color[3], 1)
        frame.barText:SetText(L.HUD_BOBBER)
        frame.barTime:SetText(("%.1f s"):format(remaining))
    else
        frame.bar:SetValue(0)
        frame.barText:SetText(ns.Fishing.active and L.HUD_READY or L.MODE_OFF)
        frame.barTime:SetText("")
    end
    frame.clock:SetText(L.HUD_SESSION:format(ns.FormatClock(ns.session.seconds)))
end

function HUD:UpdateStatus()
    local active = ns.Fishing.active
    frame.status:SetText(active and L.MODE_ON or L.MODE_OFF)
    Theme.Paint(frame.status, active and c.accent or c.faint)
    Theme.Fill(frame.dot, active and c.accent or c.faint)
    if ns.Fishing.channeling then
        frame.pulse:Play()
    else
        frame.pulse:Stop()
        frame.dot:SetAlpha(1)
    end
end

function HUD:UpdateLocation()
    local _, zone, subZone = ns.Journal:GetLocation()
    if subZone then
        frame.location:SetText(zone .. "  |cff58676f·|r  " .. subZone)
    else
        frame.location:SetText(zone)
    end
end

function HUD:UpdateGear()
    local parts = {}
    local rank, bonus, maxRank = ns.Fishing:GetSkill()
    if rank then
        -- Compétence réelle, bonus entre parenthèses : "110 (+52) / 150"
        local text = tostring(rank)
        if bonus and bonus ~= 0 then
            text = text .. (" |cff4abedb(%+d)|r"):format(bonus)
        end
        if maxRank and maxRank > 0 then
            text = text .. " / " .. maxRank
        end
        parts[#parts + 1] = text
    end
    if ns.Fishing.OLD_SCHOOL then
        if not ns.Fishing:HasPole() then
            parts[#parts + 1] = "|cffe66262" .. L.HUD_NO_POLE .. "|r"
        else
            local lure = ns.Fishing:GetLureMinutes()
            parts[#parts + 1] = lure and L.HUD_LURE:format(lure) or ("|cff8b9daa" .. L.HUD_NO_LURE .. "|r")
        end
    end
    frame.gear:SetText(table.concat(parts, "  ·  "))
end

function HUD:UpdateStats()
    local session = ns.session
    frame.stats[1]:SetText(session.catches)
    frame.stats[2]:SetText(session.casts)
    local perHour = ns.Journal:CatchesPerHour()
    frame.stats[3]:SetText(perHour and ("%d"):format(perHour) or "–")

    local rate = ns.Journal:SuccessRate()
    frame.stats[4]:SetText(rate and ("%d%%"):format(rate * 100) or "–")

    for i, icon in ipairs(frame.icons) do
        local entry = session.recent[i]
        if entry then
            local info = ns.Journal:GetItem(entry.id)
            icon:SetItem(entry.id, info and info.i, info and info.q, entry.qty)
            icon:Show()
        else
            icon:Hide()
        end
    end
    frame.noCatch:SetShown(#session.recent == 0)
end

function HUD:Refresh()
    if not frame then return end
    self:UpdateStatus()
    self:UpdateLocation()
    self:UpdateGear()
    self:UpdateStats()
    self:UpdateBar()
    self:UpdateSpeech()
end

function HUD:UpdateVisibility()
    if not frame then return end
    local s = ns.db.settings
    local show = s.hudAlways or (s.hudAuto and ns.Fishing.active)
    if show then
        self:Refresh()
    end
    frame:FadeTo(show)
end

function HUD:ApplySettings()
    if not frame then return end
    frame:SetScale(ns.db.settings.hudScale)
    W.RestorePosition(frame, "hud", "CENTER", "CENTER", 300, -100)
    self:UpdateVisibility()
end

function HUD:ResetPosition()
    ns.db.positions.hud = nil
    self:ApplySettings()
end

--- /bubulle hud : affiche / masque le panneau en permanence.
function HUD:ToggleManual()
    local s = ns.db.settings
    s.hudAlways = not s.hudAlways
    self:UpdateVisibility()
    ns:Fire("SETTINGS_CHANGED")
end

------------------------------------------------------------------------
-- Branchements
------------------------------------------------------------------------
ns:Listen("LOGIN", function()
    Build()
    HUD:Refresh()
end)

ns:Listen("MODE_CHANGED", function()
    HUD:UpdateVisibility()
    HUD:Refresh()
end)

ns:Listen("ASSISTANT_SAY", function(_, hop)
    if not frame then return end
    HUD:UpdateSpeech()
    if hop and frame:IsShown() then
        frame.mascot:Hop()
    end
end)

ns:Listen("CHANNEL_START", function() HUD:Refresh() end)
ns:Listen("CHANNEL_STOP", function() HUD:Refresh() end)
ns:Listen("SESSION_UPDATED", function() HUD:Refresh() end)
ns:Listen("SETTINGS_CHANGED", function() HUD:Refresh() end)

ns:RegisterEvent("ZONE_CHANGED", function() HUD:Refresh() end)
ns:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", function() HUD:Refresh() end)
ns:RegisterEvent("SKILL_LINES_CHANGED", function() HUD:Refresh() end)
ns:RegisterEvent("ZONE_CHANGED_INDOORS", function() HUD:Refresh() end)
ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function() HUD:Refresh() end)
