--[[
    Bubulle - UI/Window.lua
    ------------------------------------------------------------------
    La grande fenêtre (/bubulle), avec trois onglets :

      • Session : tes chiffres du jour, la liste de tes prises, et
        Bubulle qui te fait le bilan.
      • Carnet  : toutes tes prises, zone par zone, avec les pourcentages
        (pratique pour savoir où pêcher tel poisson).
      • Options : tous les réglages, appliqués immédiatement.
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets
local c = Theme.color

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 680, 540
local PAD = 14

local frame
local pages = {}
Window.pages = pages
local selectedZone = false -- false = toutes les zones

------------------------------------------------------------------------
-- Ligne de liste "poisson" (icône, nom, barre de %, quantité)
------------------------------------------------------------------------
local function CreateFishRow(list)
    local row = CreateFrame("Frame", nil, list)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    Theme.Fill(hover, c.panelHi)
    hover:Hide()

    row.icon = W.ItemIcon(row, 24)
    row.icon:SetPoint("LEFT", 6, 0)

    row.name = W.Text(row, Theme.font.body)
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, 0)
    row.name:SetPoint("RIGHT", -90, 0)

    row.bar = W.Bar(row, 3)
    row.bar:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1)
    row.bar:SetPoint("RIGHT", -90, 0)

    row.count = W.Text(row, Theme.font.numberSmall, "RIGHT")
    row.count:SetPoint("RIGHT", -38, 0)

    row.pct = W.Text(row, Theme.font.tiny, "RIGHT")
    row.pct:SetPoint("RIGHT", -4, 0)

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        hover:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        hover:Hide()
        GameTooltip:Hide()
    end)
    return row
end

local function UpdateFishRow(row, entry)
    local info = ns.Journal:GetItem(entry.id)
    local quality = info and info.q or 1
    row.itemID = entry.id
    row.icon:SetItem(entry.id, info and info.i, quality)
    row.name:SetText(ns.Journal:GetItemName(entry.id))
    row.name:SetTextColor(ns.QualityRGB(quality))
    row.bar:SetValue(entry.pct)
    row.count:SetText(entry.count)
    row.pct:SetText(("%d %%"):format(entry.pct * 100 + 0.5))
end

------------------------------------------------------------------------
-- Page "Session"
------------------------------------------------------------------------
local function BuildSessionPage(page)
    -- Tuiles
    local tiles = {}
    local labels = { L.STAT_CATCHES_LONG, L.STAT_CASTS_LONG, L.STAT_SUCCESS, L.STAT_PER_HOUR_LONG }
    local tileWidth = (WIDTH - PAD * 2 - 3 * 10) / 4
    for i, label in ipairs(labels) do
        local tile = W.StatTile(page, label)
        tile:SetSize(tileWidth, 66)
        tile:SetPoint("TOPLEFT", (i - 1) * (tileWidth + 10), 0)
        tiles[i] = tile
    end
    page.tiles = tiles

    -- Carte de Bubulle (à droite)
    local card = W.Panel(page)
    card:SetPoint("TOPRIGHT", 0, -78)
    card:SetPoint("BOTTOMRIGHT", 0, 0)
    card:SetWidth(230)

    page.mascot = ns.Mascot:CreateModel(card, 130)
    page.mascot:SetPoint("TOP", 0, -6)

    page.summary = W.Text(card, Theme.font.body, "CENTER")
    page.summary:SetPoint("TOPLEFT", 14, -140)
    page.summary:SetPoint("TOPRIGHT", -14, -140)
    page.summary:SetWordWrap(true)
    page.summary:SetSpacing(3)

    page.toggle = W.Button(card, "", 200, 28, "primary")
    page.toggle:SetPoint("BOTTOM", 0, 48)
    page.toggle:SetScript("OnClick", function()
        ns.Fishing:Toggle()
    end)

    page.reset = W.Button(card, L.BTN_NEW_SESSION, 200, 24)
    page.reset:SetPoint("BOTTOM", 0, 16)
    page.reset:SetScript("OnClick", function()
        ns.Journal:ResetSession()
    end)

    -- Liste des prises (à gauche)
    local listPanel = W.Panel(page)
    listPanel:SetPoint("TOPLEFT", 0, -78)
    listPanel:SetPoint("BOTTOMRIGHT", card, "BOTTOMLEFT", -10, 0)

    local header = W.SectionHeader(listPanel, L.SESSION_LIST)
    header:SetPoint("TOPLEFT", 12, -10)
    header:SetPoint("TOPRIGHT", -12, -10)

    page.list = W.List(listPanel, 34, CreateFishRow, UpdateFishRow)
    page.list:SetPoint("TOPLEFT", 8, -38)
    page.list:SetPoint("BOTTOMRIGHT", -6, 8)
    page.list:SetEmptyText(L.SESSION_EMPTY)
end

local function RefreshSessionPage(page)
    local session = ns.session
    local Journal = ns.Journal

    page.tiles[1]:SetValue(session.catches)
    page.tiles[2]:SetValue(session.casts)
    local rate = Journal:SuccessRate()
    page.tiles[3]:SetValue(rate and ("%d %%"):format(rate * 100) or "–")
    local perHour = Journal:CatchesPerHour()
    page.tiles[4]:SetValue(perHour and ("%d"):format(perHour) or "–", ns.FormatClock(session.seconds))

    local fish = Journal:GetSessionFish()
    page.list:SetData(fish)

    -- Le bilan de Bubulle
    if session.catches == 0 then
        page.summary:SetText(L.SUMMARY_EMPTY)
    else
        local best = fish[1]
        local bestName = best and ns.Journal:GetItemName(best.id) or "?"
        page.summary:SetText(L.SUMMARY:format(session.catches, ns.FormatClock(session.seconds), bestName))
    end

    page.toggle:SetLabel(ns.Fishing.active and L.BTN_STOP or L.BTN_START)
end

------------------------------------------------------------------------
-- Page "Carnet"
------------------------------------------------------------------------
local function CreateZoneRow(list)
    local row = CreateFrame("Button", nil, list)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    Theme.Fill(row.bg, c.panelHi)
    row.bg:Hide()

    row.stripe = row:CreateTexture(nil, "ARTWORK")
    row.stripe:SetPoint("TOPLEFT")
    row.stripe:SetPoint("BOTTOMLEFT")
    row.stripe:SetWidth(3)
    Theme.Fill(row.stripe, c.accent)

    row.name = W.Text(row, Theme.font.body)
    row.name:SetPoint("TOPLEFT", 12, -5)
    row.name:SetPoint("RIGHT", -8, 0)

    row.sub = W.Text(row, Theme.font.tiny)
    row.sub:SetPoint("BOTTOMLEFT", 12, 5)

    row:SetScript("OnClick", function(self)
        ns.PlayUISound("IG_MAINMENU_OPTION_CHECKBOX_ON")
        selectedZone = self.mapID
        Window:Refresh()
    end)
    row:SetScript("OnEnter", function(self) if not self.selected then self.bg:Show() end end)
    row:SetScript("OnLeave", function(self) if not self.selected then self.bg:Hide() end end)
    return row
end

local function UpdateZoneRow(row, entry)
    row.mapID = entry.mapID
    row.selected = selectedZone == entry.mapID
    row.bg:SetShown(row.selected)
    row.stripe:SetShown(row.selected)
    row.name:SetText(entry.name)
    Theme.Paint(row.name, row.selected and c.text or { 0.80, 0.85, 0.88, 1 })
    row.sub:SetText(L.ZONE_ROW:format(entry.catches, entry.total))
end

local function BuildJournalPage(page)
    local zonePanel = W.Panel(page)
    zonePanel:SetPoint("TOPLEFT", 0, 0)
    zonePanel:SetPoint("BOTTOMLEFT", 0, 30)
    zonePanel:SetWidth(220)

    local zoneHeader = W.SectionHeader(zonePanel, L.JOURNAL_ZONES)
    zoneHeader:SetPoint("TOPLEFT", 12, -10)
    zoneHeader:SetPoint("TOPRIGHT", -12, -10)

    page.zones = W.List(zonePanel, 40, CreateZoneRow, UpdateZoneRow)
    page.zones:SetPoint("TOPLEFT", 6, -38)
    page.zones:SetPoint("BOTTOMRIGHT", -4, 6)
    page.zones:SetEmptyText(L.JOURNAL_NO_ZONE)

    local detail = W.Panel(page)
    detail:SetPoint("TOPLEFT", zonePanel, "TOPRIGHT", 10, 0)
    detail:SetPoint("BOTTOMRIGHT", 0, 30)

    page.zoneTitle = W.Text(detail, Theme.font.title)
    page.zoneTitle:SetPoint("TOPLEFT", 14, -12)
    page.zoneTitle:SetPoint("RIGHT", -14, 0)

    page.zoneSub = W.Text(detail, Theme.font.small)
    page.zoneSub:SetPoint("TOPLEFT", page.zoneTitle, "BOTTOMLEFT", 0, -4)
    page.zoneSub:SetPoint("RIGHT", -14, 0)

    local line = detail:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 12, -52)
    line:SetPoint("TOPRIGHT", -12, -52)
    Theme.Fill(line, c.border)

    page.fish = W.List(detail, 34, CreateFishRow, UpdateFishRow)
    page.fish:SetPoint("TOPLEFT", 8, -58)
    page.fish:SetPoint("BOTTOMRIGHT", -6, 8)
    page.fish:SetEmptyText(L.JOURNAL_EMPTY)

    page.totals = W.Text(page, Theme.font.small)
    page.totals:SetPoint("BOTTOMLEFT", 2, 8)
    page.totals:SetPoint("BOTTOMRIGHT", -2, 8)
end

local function RefreshJournalPage(page)
    local Journal = ns.Journal
    local zones = Journal:GetZones()

    local allCatches, allTotal = 0, 0
    for _, z in ipairs(zones) do
        allCatches = allCatches + z.catches
        allTotal = allTotal + z.total
    end
    if #zones > 0 then
        table.insert(zones, 1, { mapID = false, name = L.JOURNAL_ALL, catches = allCatches, total = allTotal })
    end

    -- La zone choisie n'existe plus (carnet vidé) : retour à "toutes".
    if selectedZone and not ns.db.zones[selectedZone] then
        selectedZone = false
    end
    page.zones:SetData(zones)

    local fish, total
    if selectedZone then
        local zone = ns.db.zones[selectedZone]
        fish, total = Journal:GetZoneFish(selectedZone)
        page.zoneTitle:SetText(zone.name or UNKNOWN)
        local last = zone.last and date(L.DATE_FORMAT, zone.last) or "–"
        page.zoneSub:SetText(L.ZONE_DETAIL:format(zone.catches or 0, total, #fish, last))
    else
        fish, total = Journal:GetZoneFish(nil)
        page.zoneTitle:SetText(L.JOURNAL_ALL)
        page.zoneSub:SetText(L.ZONE_DETAIL_ALL:format(allCatches, total, #fish, #zones > 0 and #zones - 1 or 0))
    end
    page.fish:SetData(fish)

    local totals = ns.db.totals
    page.totals:SetText(L.JOURNAL_TOTALS:format(
        totals.catches, totals.casts, ns.FormatClock(totals.seconds), Journal:CountSpecies()))
end

------------------------------------------------------------------------
-- Page "Options"
------------------------------------------------------------------------
local function BuildOptionsPage(page)
    local s = function() return ns.db.settings end
    page.controls = {}

    local function Changed()
        ns.Fishing:RefreshSettings()
        ns.HUD:ApplySettings()
        ns:Fire("SETTINGS_CHANGED")
        Window:RefreshOptions()
    end

    local function Check(key, label, tip)
        local box = W.Checkbox(page, label, tip,
            function() return s()[key] end,
            function(v) s()[key] = v; Changed() end)
        page.controls[#page.controls + 1] = box
        return box
    end

    local function Slide(key, label, minV, maxV, step, fmt)
        local slider = W.Slider(page, label, minV, maxV, step, fmt,
            function() return s()[key] end,
            function(v) s()[key] = v; Changed() end)
        page.controls[#page.controls + 1] = slider
        return slider
    end

    local percent = function(v) return ("%d %%"):format(v * 100 + 0.5) end
    local columnWidth = (WIDTH - PAD * 2 - 30) / 2

    -- Place une liste d'éléments les uns sous les autres.
    local function Stack(x, items)
        local y = 0
        for _, item in ipairs(items) do
            item.widget:SetPoint("TOPLEFT", x, -y)
            item.widget:SetWidth(columnWidth)
            y = y + (item.space or item.widget:GetHeight() + 2)
        end
    end

    -- Colonne de gauche ------------------------------------------------
    page.doubleClick = Check("doubleClick", L.OPT_DOUBLECLICK, L.OPT_DOUBLECLICK_TIP)
    page.doubleClickAlways = Check("doubleClickAlways", L.OPT_DOUBLECLICK_ALWAYS, L.OPT_DOUBLECLICK_ALWAYS_TIP)
    page.delay = Slide("doubleClickDelay", L.OPT_DELAY, 0.2, 0.7, 0.05,
        function(v) return ("%.2f s"):format(v) end)

    local keyRow = CreateFrame("Frame", nil, page)
    keyRow:SetHeight(46)
    local keyLabel = W.Text(keyRow, Theme.font.small)
    keyLabel:SetPoint("TOPLEFT", 0, 0)
    keyLabel:SetText(L.OPT_ONEKEY)
    page.keyButton = W.KeyButton(keyRow,
        function() return s().oneKey end,
        function(v) s().oneKey = v; Changed() end, 150)
    page.keyButton:SetPoint("TOPLEFT", 0, -18)
    local keyHelp = W.Text(keyRow, Theme.font.tiny)
    keyHelp:SetPoint("LEFT", page.keyButton, "RIGHT", 10, 0)
    keyHelp:SetPoint("RIGHT", 0, 0)
    keyHelp:SetWordWrap(true)
    keyHelp:SetText(L.OPT_ONEKEY_HELP)
    W.SetTooltip(page.keyButton, L.OPT_ONEKEY, L.OPT_ONEKEY_TIP)

    page.oneKeyAlways = Check("oneKeyAlways", L.OPT_ONEKEY_ALWAYS, L.OPT_ONEKEY_ALWAYS_TIP)

    page.idle = Slide("idleTimeout", L.OPT_IDLE, 0, 300, 15,
        function(v) return v == 0 and L.NEVER or ("%d s"):format(v) end)
    page.autoLoot = Check("autoLoot", L.OPT_AUTOLOOT, L.OPT_AUTOLOOT_TIP)
    page.talk = Check("talk", L.OPT_TALK, L.OPT_TALK_TIP)
    page.newAlert = Check("newSpeciesAlert", L.OPT_ALERT_NEW)
    page.rareAlert = Check("rareAlert", L.OPT_ALERT_RARE)
    page.alertSound = Check("alertSound", L.OPT_ALERT_SOUND)
    page.minimap = Check("minimapButton", L.OPT_MINIMAP, L.OPT_MINIMAP_TIP)

    Stack(0, {
        { widget = W.SectionHeader(page, L.SECTION_CAST), space = 24 },
        { widget = keyRow, space = 52 },
        { widget = page.oneKeyAlways },
        { widget = page.doubleClick },
        { widget = page.doubleClickAlways },
        { widget = page.delay, space = 48 },
        { widget = W.SectionHeader(page, L.SECTION_BUBULLE), space = 24 },
        { widget = page.talk },
        { widget = page.newAlert },
        { widget = page.rareAlert },
        { widget = page.alertSound },
        { widget = page.minimap },
    })

    -- Colonne de droite ------------------------------------------------
    page.sound = Check("sound", L.OPT_SOUND, L.OPT_SOUND_TIP)
    page.sfx = Slide("sfxVolume", L.OPT_SFX, 0.3, 1, 0.05, percent)
    page.muteMusic = Check("muteMusic", L.OPT_MUTE_MUSIC)
    page.muteAmbience = Check("muteAmbience", L.OPT_MUTE_AMBIENCE)
    page.background = Check("soundInBackground", L.OPT_BACKGROUND, L.OPT_BACKGROUND_TIP)
    page.hudAuto = Check("hudAuto", L.OPT_HUD_AUTO)
    page.hudAlways = Check("hudAlways", L.OPT_HUD_ALWAYS)
    page.hudLocked = Check("hudLocked", L.OPT_HUD_LOCK)
    page.hudScale = Slide("hudScale", L.OPT_HUD_SCALE, 0.7, 1.5, 0.05, percent)

    local x = columnWidth + 30
    Stack(x, {
        { widget = W.SectionHeader(page, L.SECTION_SOUND), space = 24 },
        { widget = page.sound },
        { widget = page.sfx, space = 48 },
        { widget = page.muteMusic },
        { widget = page.muteAmbience },
        { widget = page.background },
        { widget = W.SectionHeader(page, L.SECTION_BEHAVIOUR), space = 24 },
        { widget = page.idle, space = 48 },
        { widget = page.autoLoot },
        { widget = W.SectionHeader(page, L.SECTION_DISPLAY), space = 24 },
        { widget = page.hudAuto },
        { widget = page.hudAlways },
        { widget = page.hudLocked },
        { widget = page.hudScale, space = 48 },
    })

    -- Pied de page
    local footer = W.Text(page, Theme.font.tiny)
    footer:SetPoint("BOTTOMLEFT", 0, 4)
    footer:SetText(L.OPT_FOOTER:format(ns.version))

    local resetPos = W.Button(page, L.BTN_RESET_POSITION, 170, 22)
    resetPos:SetPoint("BOTTOMRIGHT", 0, 0)
    resetPos:SetScript("OnClick", function() ns.HUD:ResetPosition() end)
end

function Window:RefreshOptions()
    local page = pages.options
    if not page then return end
    for _, control in ipairs(page.controls) do
        control:Refresh()
    end
    page.keyButton:Refresh()

    -- Griser ce qui ne sert à rien avec les réglages actuels
    local s = ns.db.settings
    page.doubleClickAlways:SetActive(s.doubleClick)
    page.oneKeyAlways:SetActive(s.oneKey and true or false)
    page.delay:SetActive(s.doubleClick)
    page.sfx:SetActive(s.sound)
    page.muteMusic:SetActive(s.sound)
    page.muteAmbience:SetActive(s.sound)
    page.background:SetActive(s.sound)
end

------------------------------------------------------------------------
-- Écran d'accueil (première ouverture) : choisir sa touche de pêche
------------------------------------------------------------------------
local function BuildWelcome()
    local overlay = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    overlay:SetPoint("TOPLEFT", 1, -1)
    overlay:SetPoint("BOTTOMRIGHT", -1, 1)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 20)
    overlay:EnableMouse(true) -- bloque les clics vers la fenêtre dessous
    Theme.Backdrop(overlay, { c.bg[1], c.bg[2], c.bg[3], 1 }, c.bg)

    local glow = overlay:CreateTexture(nil, "BACKGROUND", nil, 1)
    glow:SetPoint("TOPLEFT")
    glow:SetPoint("BOTTOMLEFT")
    glow:SetWidth(260)
    glow:SetColorTexture(1, 1, 1, 1)
    glow:SetGradient("HORIZONTAL", CreateColor(0.10, 0.20, 0.26, 1), CreateColor(c.bg[1], c.bg[2], c.bg[3], 1))

    overlay.mascot = ns.Mascot:CreateModel(overlay, 220)
    overlay.mascot:SetPoint("LEFT", 24, 10)

    local x = 270
    local title = W.Text(overlay, Theme.font.title)
    title:SetPoint("TOPLEFT", x, -70)
    title:SetText(L.WELCOME_TITLE)
    Theme.Paint(title, c.accent)

    local text = W.Text(overlay, Theme.font.body)
    text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -14)
    text:SetPoint("RIGHT", -40, 0)
    text:SetWordWrap(true)
    text:SetSpacing(4)
    text:SetText(L.WELCOME_TEXT)

    local keyLabel = W.Text(overlay, Theme.font.heading)
    keyLabel:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -26)
    keyLabel:SetText(L.WELCOME_KEY)

    local keyButton = W.KeyButton(overlay,
        function() return ns.db.settings.oneKey end,
        function(v)
            ns.db.settings.oneKey = v
            ns.Fishing:RefreshSettings()
            ns:Fire("SETTINGS_CHANGED")
        end, 200)
    keyButton:SetHeight(30)
    keyButton:SetPoint("TOPLEFT", keyLabel, "BOTTOMLEFT", 0, -10)
    overlay.keyButton = keyButton

    local tip = W.Text(overlay, Theme.font.small)
    tip:SetPoint("TOPLEFT", keyButton, "BOTTOMLEFT", 0, -10)
    tip:SetPoint("RIGHT", -40, 0)
    tip:SetWordWrap(true)
    tip:SetText(L.WELCOME_TIP)

    local function Close()
        ns.db.welcomed = true
        overlay:Hide()
        Window:Refresh()
    end

    local go = W.Button(overlay, L.WELCOME_GO, 180, 30, "primary")
    go:SetPoint("BOTTOMLEFT", x, 40)
    go:SetScript("OnClick", Close)

    local later = W.Button(overlay, L.WELCOME_LATER, 130, 30)
    later:SetPoint("LEFT", go, "RIGHT", 10, 0)
    later:SetScript("OnClick", Close)

    overlay:SetScript("OnShow", function() keyButton:Refresh() end)
    overlay:Hide()
    return overlay
end

function Window:ShowWelcome()
    self:Open()
    frame.welcome:Show()
end

------------------------------------------------------------------------
-- Fenêtre
------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Frame", "BubulleWindow", UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    Theme.Backdrop(frame, c.bg, c.border)
    frame:Hide()
    tinsert(UISpecialFrames, "BubulleWindow") -- Échap ferme la fenêtre

    -- Bandeau
    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(84)
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    Theme.Fill(headerBg, c.header)
    local headerLine = header:CreateTexture(nil, "ARTWORK")
    headerLine:SetHeight(1)
    headerLine:SetPoint("BOTTOMLEFT")
    headerLine:SetPoint("BOTTOMRIGHT")
    Theme.Fill(headerLine, c.border)

    local ring = W.Panel(header, c.panel, c.accent)
    ring:SetSize(40, 40)
    ring:SetPoint("TOPLEFT", PAD, -10)
    frame.portrait = ring:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetPoint("TOPLEFT", 2, -2)
    frame.portrait:SetPoint("BOTTOMRIGHT", -2, 2)

    local title = W.Text(header, Theme.font.title)
    title:SetPoint("TOPLEFT", ring, "TOPRIGHT", 12, -4)
    title:SetText("Bubulle")
    Theme.Paint(title, c.accent)

    local subtitle = W.Text(header, Theme.font.small)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetText(L.WINDOW_SUBTITLE)

    local close = W.GlyphButton(header, "close", 22)
    close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() frame:Hide() end)

    W.MakeMovable(frame, "window", header)

    -- Pages
    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", PAD, -84 - PAD)
    content:SetPoint("BOTTOMRIGHT", -PAD, PAD)

    local builders = {
        session = BuildSessionPage,
        journal = BuildJournalPage,
        options = BuildOptionsPage,
    }
    for key, build in pairs(builders) do
        local page = CreateFrame("Frame", nil, content)
        page:SetAllPoints()
        page:Hide()
        build(page)
        pages[key] = page
    end

    frame.tabs = W.Tabs(header, {
        { key = "session", label = L.TAB_SESSION },
        { key = "journal", label = L.TAB_JOURNAL },
        { key = "options", label = L.TAB_OPTIONS },
    }, function(key)
        for pageKey, page in pairs(pages) do
            page:SetShown(pageKey == key)
        end
        frame.currentTab = key
        Window:Refresh()
    end)
    frame.tabs:SetPoint("BOTTOMLEFT", PAD - 8, 0)

    frame:SetScript("OnShow", function()
        ns.Mascot:SetPortrait(frame.portrait)
        ns.PlayUISound("IG_MAINMENU_OPEN")
        Window:Refresh()
    end)
    frame:SetScript("OnHide", function()
        ns.PlayUISound("IG_MAINMENU_CLOSE")
    end)

    frame.welcome = BuildWelcome()

    W.RestorePosition(frame, "window", "CENTER", "CENTER", 0, 40)
    frame.tabs:Select("session")
end

function Window:Refresh()
    if not frame or not frame:IsShown() then return end
    local tab = frame.currentTab
    if tab == "session" then
        RefreshSessionPage(pages.session)
    elseif tab == "journal" then
        RefreshJournalPage(pages.journal)
    elseif tab == "options" then
        self:RefreshOptions()
    end
end

function Window:Open(tab)
    if not frame then Build() end
    frame:Show()
    -- Première ouverture : Bubulle se présente et propose de choisir la touche.
    if not ns.db.welcomed then
        frame.welcome:Show()
    end
    if tab then
        frame.tabs:Select(tab)
    end
end

function Window:Toggle()
    if frame and frame:IsShown() then
        frame:Hide()
    else
        self:Open()
    end
end

ns:Listen("SESSION_UPDATED", function() Window:Refresh() end)
ns:Listen("MODE_CHANGED", function() Window:Refresh() end)
ns:Listen("SETTINGS_CHANGED", function()
    if frame and frame.currentTab ~= "options" then Window:Refresh() end
end)
