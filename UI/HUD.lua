--[[
    Bubulle - UI/HUD.lua
    ------------------------------------------------------------------
    Le panneau affiché pendant la pêche : une fiche de papier sombre,
    scotchée en haut, où Bubulle griffonne ses commentaires.

          ▂▂▂▂▂▂ (scotch)
      ┌────────────────────────────────────────────┐
      │ ◆ MODE PÊCHE                           ≡ ✕ │
      │  (Bubulle)   Ça mord !                     │
      │              Vas-y, ferre !                │
      │ Lac Cristal, Forêt d'Elwynn                │
      │ Bouchon à l'eau                      12 s  │
      │ ───────────────────●- - - - - - - - - - -  │
      │    24        31        18       77 %       │
      │  prises   lancers   / heure   réussite     │
      │ [■][■][■][■][■]     (dernières prises)     │
      │ ────────────────────────────────────────── │
      │ Session 18:42      110 (+52) / 150 · Appât │
      └────────────────────────────────────────────┘

    Il se déplace en le tirant à la souris (sauf s'il est verrouillé).
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets
local c = Theme.color

local HUD = {}
ns.HUD = HUD

local WIDTH = 300
local HEIGHT = 262
local PAD = 14
local ICONS = 7
local ICON_SIZE = 26
local MODEL_SIZE = 72

local frame

local function BuildHeader()
    -- Bout de scotch qui "tient" la fiche
    if Theme.deco.tape then
        local tape = frame:CreateTexture(nil, "OVERLAY")
        tape:SetSize(84, 20)
        tape:SetPoint("CENTER", frame, "TOP", 18, 0)
        Theme.Fill(tape, c.tape)
        tape:SetRotation(math.rad(-2.5))
    end

    frame.dot = frame:CreateTexture(nil, "ARTWORK")
    frame.dot:SetSize(6, 6)
    frame.dot:SetPoint("TOPLEFT", PAD + 1, -17)
    frame.dot:SetRotation(math.rad(45))
    Theme.Fill(frame.dot, c.gold)

    local pulse = frame.dot:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.25)
    fade:SetDuration(0.6)
    frame.pulse = pulse

    frame.status = W.Text(frame, Theme.font.kicker)
    frame.status:SetPoint("LEFT", frame.dot, "RIGHT", 8, 0)

    local close = W.GlyphButton(frame, "close", 18)
    close:SetPoint("TOPRIGHT", -8, -10)
    close:SetScript("OnClick", function()
        if ns.Fishing.active then
            ns.Fishing:SetActive(false)
        end
        ns.db.settings.hudAlways = false
        HUD:UpdateVisibility()
    end)
    W.SetTooltip(close, L.HUD_CLOSE, L.HUD_CLOSE_TIP)

    local menu = W.GlyphButton(frame, "menu", 18)
    menu:SetPoint("RIGHT", close, "LEFT", -2, 0)
    menu:SetScript("OnClick", function() ns.Window:Toggle() end)
    W.SetTooltip(menu, L.HUD_JOURNAL)

    W.MakeMovable(frame, "hud", frame, function() return ns.db.settings.hudLocked end)
end

local function BuildAssistant()
    -- Bubulle (son illustration qui nage)
    frame.mascot = ns.Mascot:CreateModel(frame, MODEL_SIZE)
    frame.mascot:SetPoint("TOPLEFT", 6, -30)

    -- Ce qu'il dit, écrit à la main à côté de lui
    frame.say = W.Text(frame, Theme.font.handSmall)
    frame.say:SetPoint("TOPLEFT", MODEL_SIZE + 12, -34)
    frame.say:SetPoint("RIGHT", -PAD, 0)
    frame.say:SetHeight(64)
    frame.say:SetJustifyV("MIDDLE")
    frame.say:SetWordWrap(true)
    frame.say:SetMaxLines(3)

    local appear = frame.say:CreateAnimationGroup()
    local alpha = appear:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0)
    alpha:SetToAlpha(1)
    alpha:SetDuration(0.25)
    frame.sayAppear = appear

    frame.location = W.Text(frame, Theme.font.small)
    frame.location:SetPoint("TOPLEFT", PAD, -106)
    frame.location:SetPoint("RIGHT", -PAD, 0)
end

local function BuildStats()
    -- Le bouchon qui file le long de sa ligne
    frame.barText = W.Text(frame, Theme.font.tiny)
    frame.barText:SetPoint("TOPLEFT", PAD, -126)
    frame.barText:SetPoint("RIGHT", -60, 0)

    frame.barTime = W.Text(frame, Theme.font.numberSmall, "RIGHT")
    frame.barTime:SetPoint("TOPRIGHT", -PAD, -124)

    frame.bar = W.Bar(frame, 2)
    frame.bar:SetPoint("TOPLEFT", PAD, -150)
    frame.bar:SetPoint("TOPRIGHT", -PAD, -150)
    frame.bar:SetStatusBarColor(c.ink[1], c.ink[2], c.ink[3], 0.85)

    frame.bobber = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.bobber:SetSize(16, 16)
    frame.bobber:SetTexture(Theme.tex.bobber)
    frame.bobber:SetPoint("CENTER", frame.bar, "LEFT", 0, 0)
    frame.bobber:Hide()

    -- Chiffres
    frame.stats = {}
    local labels = { L.STAT_CATCHES, L.STAT_CASTS, L.STAT_PER_HOUR, L.STAT_SUCCESS_SHORT }
    local cellWidth = (WIDTH - PAD * 2) / #labels
    for i, label in ipairs(labels) do
        local value = W.Text(frame, Theme.font.numberSmall, "CENTER")
        value:SetPoint("TOP", frame, "TOPLEFT", PAD + cellWidth * (i - 0.5), -162)
        value:SetText("0")
        local caption = W.Text(frame, Theme.font.tiny, "CENTER")
        caption:SetPoint("TOP", value, "BOTTOM", 0, 0)
        caption:SetText(label)
        frame.stats[i] = value
    end

    -- Dernières prises
    frame.icons = {}
    for i = 1, ICONS do
        local icon = W.ItemIcon(frame, ICON_SIZE)
        icon:SetPoint("TOPLEFT", PAD + (i - 1) * (ICON_SIZE + 6), -204)
        icon:Hide()
        frame.icons[i] = icon
    end
    frame.noCatch = W.Text(frame, Theme.font.tiny)
    frame.noCatch:SetPoint("TOPLEFT", PAD, -210)
    frame.noCatch:SetPoint("RIGHT", -PAD, 0)
    frame.noCatch:SetText(L.HUD_NO_CATCH)

    -- Pied
    local divider = W.Line(frame, c.line)
    divider:SetPoint("BOTTOMLEFT", PAD, 28)
    divider:SetPoint("BOTTOMRIGHT", -PAD, 28)

    frame.clock = W.Text(frame, Theme.font.tiny)
    frame.clock:SetPoint("BOTTOMLEFT", PAD, 10)

    -- Compétence et appât, à droite du chrono
    frame.gear = W.Text(frame, Theme.font.tiny, "RIGHT")
    frame.gear:SetPoint("BOTTOMRIGHT", -PAD, 10)
end

local function Build()
    frame = CreateFrame("Frame", "BubulleHUD", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    Theme.Surface(frame, "card")
    frame:Hide()
    W.AttachFader(frame, 0.2)

    -- Filet doré intérieur et ombre portée : une vraie fiche posée à l'écran
    local inner = CreateFrame("Frame", nil, frame)
    inner:SetPoint("TOPLEFT", 4, -4)
    inner:SetPoint("BOTTOMRIGHT", -4, 4)
    W.GiltFrame(inner, nil, { c.goldDk[1], c.goldDk[2], c.goldDk[3], 0.5 }, "BORDER")
    if Theme.deco.drop then
        local drop = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
        drop:SetPoint("TOPLEFT", -3, 1)
        drop:SetPoint("BOTTOMRIGHT", 5, -6)
        drop:SetColorTexture(0, 0, 0, 0.4)
    end

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
        frame.bobber:SetPoint("CENTER", frame.bar, "LEFT", (frame.bar:GetWidth() or 0) * remaining / total, 0)
        frame.bobber:Show()
        Theme.Paint(frame.barTime, remaining < 4 and c.danger or c.ink)
        frame.barText:SetText(L.HUD_BOBBER)
        frame.barTime:SetText(("%d s"):format(math.ceil(remaining)))
    else
        frame.bar:SetValue(0)
        frame.bobber:Hide()
        frame.barText:SetText(ns.Fishing.active and L.HUD_READY or L.MODE_OFF)
        frame.barTime:SetText("")
    end
    frame.clock:SetText(L.HUD_SESSION:format(ns.FormatClock(ns.session.seconds)))
end

function HUD:UpdateStatus()
    local active = ns.Fishing.active
    frame.status:SetText(active and L.MODE_ON or L.MODE_OFF)
    Theme.Paint(frame.status, active and c.gold or c.inkFaint)
    Theme.Fill(frame.dot, active and c.gold or c.inkFaint)
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
        frame.location:SetText(subZone .. ", " .. zone)
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
            text = text .. (" |cff" .. Theme.WATER_HEX .. "(%+d)|r"):format(bonus)
        end
        if maxRank and maxRank > 0 then
            text = text .. " / " .. maxRank
        end
        parts[#parts + 1] = text
    end
    if ns.Fishing.OLD_SCHOOL then
        if not ns.Fishing:HasPole() then
            parts[#parts + 1] = "|cff" .. Theme.Hex(c.danger) .. L.HUD_NO_POLE .. "|r"
        else
            local lure = ns.Fishing:GetLureMinutes()
            parts[#parts + 1] = lure and L.HUD_LURE:format(lure) or ("|cff" .. Theme.FAINT_HEX .. L.HUD_NO_LURE .. "|r")
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
    frame.stats[4]:SetText(rate and ("%d %%"):format(rate * 100) or "–")

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
