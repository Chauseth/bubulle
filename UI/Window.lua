--[[
    Bubulle - UI/Window.lua
    ------------------------------------------------------------------
    La grande fenêtre (/bubulle) : un carnet de pêche ouvert, relié de
    cuir, avec trois marque-pages sur le côté :

      • Session  : à gauche tes chiffres du jour et tes dernières prises,
                   à droite le détail de ce que tu as pêché.
      • Carnet   : à gauche tes coins de pêche, à droite ce qu'on y trouve
                   (pratique pour savoir où pêcher tel poisson).
      • Réglages : tous les réglages, appliqués immédiatement.

    Chaque onglet remplit les deux pages : une "double page".
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets
local c = Theme.color

local Window = {}
ns.Window = Window

-- Dimensions du carnet
local BOOK_W, BOOK_H = 880, 580
local COVER = 16                 -- épaisseur du cuir visible autour des pages
local SPINE = 14                 -- espace entre les deux pages (la reliure)
local PAGE_W = (BOOK_W - COVER * 2 - SPINE) / 2
local MARGIN = 30                -- marge intérieure des pages
local CONTENT_W = PAGE_W - MARGIN * 2

local frame
local pages = {}
Window.pages = pages
local selectedZone = false -- false = toutes les zones

------------------------------------------------------------------------
-- Petits outils
------------------------------------------------------------------------

--- "il y a 3 min"
local function Ago(timestamp)
    if not timestamp then return "" end
    local minutes = math.floor((time() - timestamp) / 60)
    if minutes < 1 then
        return L.AGO_NOW
    elseif minutes < 60 then
        return L.AGO_MIN:format(minutes)
    end
    return L.AGO_HOUR:format(math.floor(minutes / 60))
end

local function QualityName(quality)
    return _G["ITEM_QUALITY" .. (quality or 1) .. "_DESC"] or ""
end

--- Compétence de pêche : "110 (+52) / 150" (nil si inconnue).
local function SkillText()
    local rank, bonus, maxRank = ns.Fishing:GetSkill()
    if not rank then return nil end
    local extra = maxRank and ("/ %d"):format(maxRank) or nil
    if bonus and bonus ~= 0 then
        extra = ("(%+d) %s"):format(bonus, extra or "")
    end
    return tostring(rank), extra
end

------------------------------------------------------------------------
-- Ligne "poisson" : icône, nom (couleur de qualité), qualité en italique,
-- quantité et pourcentage à droite, filet fin dessous.
------------------------------------------------------------------------
local function CreateFishRow(list)
    local row = CreateFrame("Frame", nil, list)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(c.gold[1], c.gold[2], c.gold[3], 0.06)
    hover:Hide()

    local rule = W.Line(row, c.lineFaint)
    rule:SetPoint("BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", 0, 0)

    row.icon = W.ItemIcon(row, 30)
    row.icon:SetPoint("LEFT", 0, 0)

    row.count = W.Text(row, Theme.font.numberSmall, "RIGHT")
    row.count:SetPoint("TOPRIGHT", 0, -4)

    row.pct = W.Text(row, Theme.font.tiny, "RIGHT")
    row.pct:SetPoint("BOTTOMRIGHT", 0, 5)

    row.name = W.Text(row, Theme.font.bold)
    row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 12, 2)
    row.name:SetPoint("RIGHT", -50, 0)

    row.sub = W.Text(row, Theme.font.small)
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 12, -2)
    row.sub:SetPoint("RIGHT", -50, 0)

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
    row.sub:SetText(QualityName(quality))
    row.count:SetText(entry.count)
    row.pct:SetText(("%d %%"):format(entry.pct * 100 + 0.5))
end

------------------------------------------------------------------------
-- Une page du carnet : papier sombre, double filet doré, ombre de la
-- reliure du côté intérieur, numéro en bas.
------------------------------------------------------------------------
local function CreatePage(parent, side)
    local page = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    page:SetSize(PAGE_W, BOOK_H - COVER * 2)
    Theme.Backdrop(page, nil, { 0.03, 0.02, 0.01, 1 }, Theme.tex.page)
    W.GiltFrame(page, 9, c.goldDk, "BORDER")

    -- Ombre vers la reliure : la page "plonge" dans le pli.
    local shade = page:CreateTexture(nil, "BORDER", nil, -1)
    shade:SetWidth(46)
    shade:SetPoint("TOP" .. (side == "left" and "RIGHT" or "LEFT"))
    shade:SetPoint("BOTTOM" .. (side == "left" and "RIGHT" or "LEFT"))
    if side == "left" then
        Theme.Shade(shade, "HORIZONTAL", 0, 0.55)
    else
        Theme.Shade(shade, "HORIZONTAL", 0.55, 0)
    end

    -- Zone de contenu (dans les marges)
    page.content = CreateFrame("Frame", nil, page)
    page.content:SetPoint("TOPLEFT", MARGIN, -MARGIN)
    page.content:SetPoint("BOTTOMRIGHT", -MARGIN, MARGIN)

    page.folio = W.Text(page, Theme.font.tiny, "CENTER")
    page.folio:SetPoint("BOTTOM", 0, 14)
    return page
end

--- Crée une double page (gauche + droite) pour un onglet.
local function CreateSpread(book, firstFolio)
    local spread = CreateFrame("Frame", nil, book)
    spread:SetAllPoints()
    spread:Hide()
    spread.left = CreatePage(spread, "left")
    spread.left:SetPoint("TOPLEFT", COVER, -COVER)
    spread.right = CreatePage(spread, "right")
    spread.right:SetPoint("TOPRIGHT", -COVER, -COVER)
    spread.left.folio:SetText(("— %d —"):format(firstFolio))
    spread.right.folio:SetText(("— %d —"):format(firstFolio + 1))
    return spread, spread.left.content, spread.right.content
end

--- En-tête + petit ornement dessous ; renvoie l'en-tête.
local function Header(content, withOrnament)
    local head = W.PageHeader(content)
    head:SetPoint("TOPLEFT", 0, 0)
    head:SetPoint("TOPRIGHT", 0, 0)
    if withOrnament then
        local ornament = W.Ornament(content)
        ornament:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
        ornament:SetPoint("TOPRIGHT", head, "BOTTOMRIGHT", 0, -6)
        head.ornament = ornament
    end
    return head
end

------------------------------------------------------------------------
-- Double page "Session"
------------------------------------------------------------------------
local RECENT_SHOWN = 4

local function BuildSessionSpread(spread, left, right)
    -- Page de gauche : registre du jour ---------------------------------
    spread.head = Header(left, true)

    local labels = { L.STAT_CATCHES_LONG, L.STAT_CASTS_LONG, L.STAT_PER_HOUR_LONG, L.STAT_SUCCESS, L.STAT_SKILL }
    spread.ledger = {}
    local y = -92
    for i, label in ipairs(labels) do
        local row = W.LedgerRow(left, label)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", 0, y)
        spread.ledger[i] = row
        y = y - 26
    end

    local recentHeader = W.SectionHeader(left, L.SESSION_RECENT)
    recentHeader:SetPoint("TOPLEFT", 0, y - 14)
    recentHeader:SetPoint("TOPRIGHT", 0, y - 14)
    y = y - 44

    spread.recent = {}
    for i = 1, RECENT_SHOWN do
        local row = CreateFrame("Frame", nil, left)
        row:SetHeight(30)
        row:SetPoint("TOPLEFT", 0, y)
        row:SetPoint("TOPRIGHT", 0, y)
        row.icon = W.ItemIcon(row, 24)
        row.icon:SetPoint("LEFT", 0, 0)
        row.when = W.Text(row, Theme.font.tiny, "RIGHT")
        row.when:SetPoint("RIGHT", 0, 0)
        row.name = W.Text(row, Theme.font.body)
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
        row.name:SetPoint("RIGHT", row.when, "LEFT", -8, 0)
        spread.recent[i] = row
        y = y - 32
    end
    spread.noRecent = W.Text(left, Theme.font.small)
    spread.noRecent:SetPoint("TOPLEFT", spread.recent[1], "TOPLEFT", 0, -6)
    spread.noRecent:SetPoint("RIGHT", 0, 0)
    spread.noRecent:SetWordWrap(true)
    spread.noRecent:SetText(L.SESSION_EMPTY)

    -- Le mot de Bubulle, écrit à la main en bas de page
    spread.mascot = ns.Mascot:CreateModel(left, 62)
    spread.mascot:SetPoint("BOTTOMLEFT", -4, 6)

    spread.summary = W.Text(left, Theme.font.handSmall)
    spread.summary:SetPoint("LEFT", spread.mascot, "RIGHT", 8, 0)
    spread.summary:SetPoint("RIGHT", 0, 0)
    spread.summary:SetWordWrap(true)
    spread.summary:SetSpacing(1)

    -- Page de droite : ce que tu as pêché -------------------------------
    spread.listHead = Header(right, true)
    spread.listHead:Set(L.KICKER_SESSION, L.SESSION_LIST, "")

    spread.toggle = W.Button(right, "", 176, 28, "primary")
    spread.toggle:SetPoint("BOTTOMLEFT", 0, 14)
    spread.toggle:SetScript("OnClick", function()
        ns.Fishing:Toggle()
    end)

    spread.reset = W.Button(right, L.BTN_NEW_SESSION, 160, 28)
    spread.reset:SetPoint("BOTTOMRIGHT", 0, 14)
    spread.reset:SetScript("OnClick", function()
        ns.Journal:ResetSession()
    end)

    spread.list = W.List(right, 46, CreateFishRow, UpdateFishRow)
    spread.list:SetPoint("TOPLEFT", 0, -88)
    spread.list:SetPoint("BOTTOMRIGHT", spread.reset, "TOPRIGHT", 12, 14)
    spread.list:SetEmptyText(L.HUD_NO_CATCH)
end

local function RefreshSessionSpread(spread)
    local session = ns.session
    local Journal = ns.Journal

    -- En-tête : là où tu pêches
    local _, zoneName, subZone = Journal:GetLocation()
    local since = date("%H:%M", session.started or time())
    if subZone then
        spread.head:Set(L.KICKER_SESSION, subZone, L.SESSION_WHERE:format(zoneName, since))
    else
        spread.head:Set(L.KICKER_SESSION, zoneName, L.SESSION_SINCE:format(since))
    end

    -- Registre
    local rate = Journal:SuccessRate()
    local perHour = Journal:CatchesPerHour()
    spread.ledger[1]:Set(session.catches)
    spread.ledger[2]:Set(session.casts)
    spread.ledger[3]:Set(perHour and ("%d"):format(perHour) or "–", ns.FormatClock(session.seconds))
    spread.ledger[4]:Set(rate and ("%d %%"):format(rate * 100) or "–")
    local rank, extra = SkillText()
    spread.ledger[5]:Set(rank or "–", extra)

    -- Dernières prises
    local recent = session.recent
    for i, row in ipairs(spread.recent) do
        local entry = recent[i]
        if entry then
            local info = Journal:GetItem(entry.id)
            local quality = info and info.q or 1
            row.icon:SetItem(entry.id, info and info.i, quality, entry.qty)
            row.name:SetText(Journal:GetItemName(entry.id))
            row.name:SetTextColor(ns.QualityRGB(quality))
            row.when:SetText(Ago(entry.t))
            row:Show()
        else
            row:Hide()
        end
    end
    spread.noRecent:SetShown(#recent == 0)

    -- Ce que tu as pêché
    local fish = Journal:GetSessionFish()
    spread.list:SetData(fish)
    local items = 0
    for _, entry in ipairs(fish) do items = items + entry.count end
    spread.listHead.sub:SetText(L.SESSION_LIST_SUB:format(#fish, items))

    -- Le mot de Bubulle
    if session.catches == 0 then
        spread.summary:SetText(L.SUMMARY_EMPTY)
    else
        local best = fish[1]
        local bestName = best and Journal:GetItemName(best.id) or "?"
        spread.summary:SetText(L.SUMMARY:format(session.catches, ns.FormatClock(session.seconds), bestName))
    end

    spread.toggle:SetLabel(ns.Fishing.active and L.BTN_STOP or L.BTN_START)
end

------------------------------------------------------------------------
-- Double page "Carnet"
------------------------------------------------------------------------
local function CreateZoneRow(list)
    local row = CreateFrame("Button", nil, list)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetColorTexture(c.gold[1], c.gold[2], c.gold[3], 0.07)
    row.bg:Hide()

    row.mark = row:CreateTexture(nil, "ARTWORK")
    row.mark:SetSize(6, 6)
    row.mark:SetPoint("LEFT", 4, 0)
    row.mark:SetRotation(math.rad(45))
    Theme.Fill(row.mark, c.gold)

    local rule = W.Line(row, c.lineFaint)
    rule:SetPoint("BOTTOMLEFT", 0, 0)
    rule:SetPoint("BOTTOMRIGHT", 0, 0)

    row.name = W.Text(row, Theme.font.body)
    row.name:SetPoint("TOPLEFT", 18, -4)
    row.name:SetPoint("RIGHT", -6, 0)

    row.sub = W.Text(row, Theme.font.tiny)
    row.sub:SetPoint("BOTTOMLEFT", 18, 5)
    row.sub:SetPoint("RIGHT", -6, 0)

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
    row.mark:SetShown(row.selected)
    row.name:SetText(entry.name)
    Theme.Paint(row.name, row.selected and c.gold or c.ink)
    row.sub:SetText(L.ZONE_ROW:format(entry.catches, entry.total))
end

local function BuildJournalSpread(spread, left, right)
    -- Page de gauche : les coins de pêche
    spread.zonesHead = Header(left, true)

    spread.totals = W.Text(left, Theme.font.tiny)
    spread.totals:SetPoint("BOTTOMLEFT", 0, 14)
    spread.totals:SetPoint("BOTTOMRIGHT", 0, 14)
    spread.totals:SetWordWrap(true)
    spread.totals:SetSpacing(2)

    spread.zones = W.List(left, 42, CreateZoneRow, UpdateZoneRow)
    spread.zones:SetPoint("TOPLEFT", 0, -88)
    spread.zones:SetPoint("BOTTOMRIGHT", 12, 50)
    spread.zones:SetEmptyText(L.JOURNAL_NO_ZONE)

    -- Page de droite : ce qu'on pêche dans la zone choisie
    spread.zoneHead = Header(right, true)

    spread.fish = W.List(right, 46, CreateFishRow, UpdateFishRow)
    spread.fish:SetPoint("TOPLEFT", 0, -88)
    spread.fish:SetPoint("BOTTOMRIGHT", 12, 14)
    spread.fish:SetEmptyText(L.JOURNAL_EMPTY)
end

local function RefreshJournalSpread(spread)
    local Journal = ns.Journal
    local zones = Journal:GetZones()

    local allCatches, allTotal = 0, 0
    for _, z in ipairs(zones) do
        allCatches = allCatches + z.catches
        allTotal = allTotal + z.total
    end
    local zoneCount = #zones
    if zoneCount > 0 then
        table.insert(zones, 1, { mapID = false, name = L.JOURNAL_ALL, catches = allCatches, total = allTotal })
    end

    -- La zone choisie n'existe plus (carnet vidé) : retour à "toutes".
    if selectedZone and not ns.db.zones[selectedZone] then
        selectedZone = false
    end
    spread.zonesHead:Set(L.KICKER_JOURNAL, L.JOURNAL_ZONES, L.JOURNAL_ZONES_SUB:format(zoneCount))
    spread.zones:SetData(zones)

    local fish, total
    if selectedZone then
        local zone = ns.db.zones[selectedZone]
        fish, total = Journal:GetZoneFish(selectedZone)
        local last = zone.last and date(L.DATE_FORMAT, zone.last) or "–"
        spread.zoneHead:Set(L.KICKER_JOURNAL, zone.name or UNKNOWN,
            L.ZONE_DETAIL:format(zone.catches or 0, total, #fish, last))
    else
        fish, total = Journal:GetZoneFish(nil)
        spread.zoneHead:Set(L.KICKER_JOURNAL, L.JOURNAL_ALL,
            L.ZONE_DETAIL_ALL:format(allCatches, total, #fish, zoneCount))
    end
    spread.fish:SetData(fish)

    local totals = ns.db.totals
    spread.totals:SetText(L.JOURNAL_TOTALS:format(
        totals.catches, totals.casts, ns.FormatClock(totals.seconds), Journal:CountSpecies()))
end

------------------------------------------------------------------------
-- Double page "Réglages"
------------------------------------------------------------------------
local function BuildOptionsSpread(spread, left, right)
    local s = function() return ns.db.settings end
    spread.controls = {}

    local function Changed()
        ns.Fishing:RefreshSettings()
        ns.HUD:ApplySettings()
        ns:Fire("SETTINGS_CHANGED")
        Window:RefreshOptions()
    end

    local function Check(parent, key, label, tip)
        local box = W.Checkbox(parent, label, tip,
            function() return s()[key] end,
            function(v) s()[key] = v; Changed() end)
        spread.controls[#spread.controls + 1] = box
        return box
    end

    local function Slide(parent, key, label, minV, maxV, step, fmt)
        local slider = W.Slider(parent, label, minV, maxV, step, fmt,
            function() return s()[key] end,
            function(v) s()[key] = v; Changed() end)
        spread.controls[#spread.controls + 1] = slider
        return slider
    end

    local percent = function(v) return ("%d %%"):format(v * 100 + 0.5) end

    -- Place une liste d'éléments les uns sous les autres.
    local function Stack(top, items)
        local y = top
        for i, item in ipairs(items) do
            if item.section and i > 1 then
                y = y + 10 -- un peu d'air avant chaque titre de section
            end
            item.widget:SetPoint("TOPLEFT", 0, -y)
            item.widget:SetWidth(CONTENT_W)
            y = y + (item.space or item.widget:GetHeight() + 2)
        end
    end

    -- Page de gauche : la pêche et Bubulle ------------------------------
    local leftHead = Header(left, false)
    leftHead:SetHeight(44)
    leftHead:Set(L.KICKER_OPTIONS, L.OPT_TITLE_LEFT)

    spread.doubleClick = Check(left, "doubleClick", L.OPT_DOUBLECLICK, L.OPT_DOUBLECLICK_TIP)
    spread.doubleClickAlways = Check(left, "doubleClickAlways", L.OPT_DOUBLECLICK_ALWAYS, L.OPT_DOUBLECLICK_ALWAYS_TIP)
    spread.delay = Slide(left, "doubleClickDelay", L.OPT_DELAY, 0.2, 0.7, 0.05,
        function(v) return ("%.2f s"):format(v) end)

    local keyRow = CreateFrame("Frame", nil, left)
    keyRow:SetHeight(46)
    local keyLabel = W.Text(keyRow, Theme.font.body)
    keyLabel:SetPoint("TOPLEFT", 0, 0)
    keyLabel:SetText(L.OPT_ONEKEY)
    spread.keyButton = W.KeyButton(keyRow,
        function() return s().oneKey end,
        function(v) s().oneKey = v; Changed() end, 140)
    spread.keyButton:SetPoint("TOPLEFT", 0, -20)
    local keyHelp = W.Text(keyRow, Theme.font.tiny)
    keyHelp:SetPoint("LEFT", spread.keyButton, "RIGHT", 10, 0)
    keyHelp:SetPoint("RIGHT", 0, 0)
    keyHelp:SetWordWrap(true)
    keyHelp:SetText(L.OPT_ONEKEY_HELP)
    W.SetTooltip(spread.keyButton, L.OPT_ONEKEY, L.OPT_ONEKEY_TIP)

    spread.oneKeyAlways = Check(left, "oneKeyAlways", L.OPT_ONEKEY_ALWAYS, L.OPT_ONEKEY_ALWAYS_TIP)
    spread.talk = Check(left, "talk", L.OPT_TALK, L.OPT_TALK_TIP)
    spread.newAlert = Check(left, "newSpeciesAlert", L.OPT_ALERT_NEW)
    spread.rareAlert = Check(left, "rareAlert", L.OPT_ALERT_RARE)
    spread.alertSound = Check(left, "alertSound", L.OPT_ALERT_SOUND)
    spread.minimap = Check(left, "minimapButton", L.OPT_MINIMAP, L.OPT_MINIMAP_TIP)

    Stack(56, {
        { widget = W.SectionHeader(left, L.SECTION_CAST), space = 28, section = true },
        { widget = keyRow, space = 54 },
        { widget = spread.oneKeyAlways },
        { widget = spread.doubleClick },
        { widget = spread.doubleClickAlways },
        { widget = spread.delay, space = 52 },
        { widget = W.SectionHeader(left, L.SECTION_BUBULLE), space = 28, section = true },
        { widget = spread.talk },
        { widget = spread.newAlert },
        { widget = spread.rareAlert },
        { widget = spread.alertSound },
        { widget = spread.minimap },
    })

    local footer = W.Text(left, Theme.font.tiny)
    footer:SetPoint("BOTTOMLEFT", 0, 14)
    footer:SetText(L.OPT_FOOTER:format(ns.version))

    -- Page de droite : le son et l'affichage ----------------------------
    local rightHead = Header(right, false)
    rightHead:SetHeight(44)
    rightHead:Set(L.KICKER_OPTIONS, L.OPT_TITLE_RIGHT)

    spread.sound = Check(right, "sound", L.OPT_SOUND, L.OPT_SOUND_TIP)
    spread.sfx = Slide(right, "sfxVolume", L.OPT_SFX, 0.3, 1, 0.05, percent)
    spread.muteMusic = Check(right, "muteMusic", L.OPT_MUTE_MUSIC)
    spread.muteAmbience = Check(right, "muteAmbience", L.OPT_MUTE_AMBIENCE)
    spread.background = Check(right, "soundInBackground", L.OPT_BACKGROUND, L.OPT_BACKGROUND_TIP)
    spread.idle = Slide(right, "idleTimeout", L.OPT_IDLE, 0, 300, 15,
        function(v) return v == 0 and L.NEVER or ("%d s"):format(v) end)
    spread.autoLoot = Check(right, "autoLoot", L.OPT_AUTOLOOT, L.OPT_AUTOLOOT_TIP)
    spread.hudAuto = Check(right, "hudAuto", L.OPT_HUD_AUTO)
    spread.hudAlways = Check(right, "hudAlways", L.OPT_HUD_ALWAYS)
    spread.hudLocked = Check(right, "hudLocked", L.OPT_HUD_LOCK)
    spread.hudScale = Slide(right, "hudScale", L.OPT_HUD_SCALE, 0.7, 1.5, 0.05, percent)

    Stack(56, {
        { widget = W.SectionHeader(right, L.SECTION_SOUND), space = 28, section = true },
        { widget = spread.sound },
        { widget = spread.sfx, space = 46 },
        { widget = spread.muteMusic },
        { widget = spread.muteAmbience },
        { widget = spread.background },
        { widget = W.SectionHeader(right, L.SECTION_BEHAVIOUR), space = 28, section = true },
        { widget = spread.idle, space = 46 },
        { widget = spread.autoLoot },
        { widget = W.SectionHeader(right, L.SECTION_DISPLAY), space = 28, section = true },
        { widget = spread.hudAuto },
        { widget = spread.hudAlways },
        { widget = spread.hudLocked },
        { widget = spread.hudScale, space = 46 },
    })

    local resetPos = W.Button(left, L.BTN_RESET_POSITION, 170, 24)
    resetPos:SetPoint("BOTTOMRIGHT", 0, 8)
    resetPos:SetScript("OnClick", function() ns.HUD:ResetPosition() end)
end

function Window:RefreshOptions()
    local spread = pages.options
    if not spread then return end
    for _, control in ipairs(spread.controls) do
        control:Refresh()
    end
    spread.keyButton:Refresh()

    -- Griser ce qui ne sert à rien avec les réglages actuels
    local s = ns.db.settings
    spread.doubleClickAlways:SetActive(s.doubleClick)
    spread.oneKeyAlways:SetActive(s.oneKey and true or false)
    spread.delay:SetActive(s.doubleClick)
    spread.sfx:SetActive(s.sound)
    spread.muteMusic:SetActive(s.sound)
    spread.muteAmbience:SetActive(s.sound)
    spread.background:SetActive(s.sound)
end

------------------------------------------------------------------------
-- Écran d'accueil (première ouverture) : choisir sa touche de pêche.
-- Une double page à part, posée par-dessus les autres.
------------------------------------------------------------------------
local function BuildWelcome()
    local overlay, left, right = CreateSpread(frame, 0)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 20)
    overlay:EnableMouse(true) -- bloque les clics vers les pages dessous
    overlay.left.folio:SetText("")
    overlay.right.folio:SetText("")

    -- Page de gauche : Bubulle en grand
    overlay.mascot = ns.Mascot:CreateModel(left, 230)
    overlay.mascot:SetPoint("CENTER", 0, 20)

    local hello = W.Text(left, Theme.font.hand, "CENTER")
    hello:SetPoint("TOP", overlay.mascot, "BOTTOM", 0, -8)
    hello:SetText(L.WELCOME_TITLE)

    -- Page de droite : explications et choix de la touche
    local head = Header(right, true)
    head:Set(L.KICKER_WELCOME, L.WELCOME_KEY, "")

    local text = W.Text(right, Theme.font.body)
    text:SetPoint("TOPLEFT", 0, -88)
    text:SetPoint("RIGHT", 0, 0)
    text:SetWordWrap(true)
    text:SetSpacing(3)
    text:SetText(L.WELCOME_TEXT)

    local keyButton = W.KeyButton(right,
        function() return ns.db.settings.oneKey end,
        function(v)
            ns.db.settings.oneKey = v
            ns.Fishing:RefreshSettings()
            ns:Fire("SETTINGS_CHANGED")
        end, 200)
    keyButton:SetHeight(30)
    keyButton:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -20)
    overlay.keyButton = keyButton

    local tip = W.Text(right, Theme.font.small)
    tip:SetPoint("TOPLEFT", keyButton, "BOTTOMLEFT", 0, -12)
    tip:SetPoint("RIGHT", 0, 0)
    tip:SetWordWrap(true)
    tip:SetText(L.WELCOME_TIP)

    local function Close()
        ns.db.welcomed = true
        overlay:Hide()
        Window:Refresh()
    end

    local go = W.Button(right, L.WELCOME_GO, 180, 30, "primary")
    go:SetPoint("BOTTOMLEFT", 0, 14)
    go:SetScript("OnClick", Close)

    local later = W.Button(right, L.WELCOME_LATER, 130, 30)
    later:SetPoint("LEFT", go, "RIGHT", 12, 0)
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
-- La reliure : coins de laiton, signet, bouton de fermeture
------------------------------------------------------------------------
local function DecorateCover(book)
    local deco = CreateFrame("Frame", nil, book)
    deco:SetAllPoints()
    deco:SetFrameLevel(book:GetFrameLevel() + 30)

    -- Reliure entre les pages
    local spine = book:CreateTexture(nil, "ARTWORK")
    spine:SetPoint("TOP", 0, -COVER + 2)
    spine:SetPoint("BOTTOM", 0, COVER - 2)
    spine:SetWidth(SPINE + 4)
    spine:SetColorTexture(0.05, 0.03, 0.02, 0.85)

    -- Signet rouge qui dépasse du bas du carnet
    local ribbon = deco:CreateTexture(nil, "ARTWORK")
    ribbon:SetTexture(Theme.tex.ribbon)
    ribbon:SetSize(18, BOOK_H - 10)
    ribbon:SetPoint("TOP", 10, -10)
    ribbon:SetPoint("BOTTOM", 10, -44)

    -- Coins en laiton (une seule image, retournée pour chaque coin)
    local corners = {
        { "TOPLEFT", 0, 1, 0, 1 }, { "TOPRIGHT", 1, 0, 0, 1 },
        { "BOTTOMLEFT", 0, 1, 1, 0 }, { "BOTTOMRIGHT", 1, 0, 1, 0 },
    }
    for _, corner in ipairs(corners) do
        local t = deco:CreateTexture(nil, "OVERLAY")
        t:SetTexture(Theme.tex.corner)
        t:SetSize(42, 42)
        t:SetPoint(corner[1], 0, 0)
        t:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
    end

    local close = W.BrassClose(deco, 30)
    close:SetPoint("CENTER", book, "TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() book:Hide() end)
    W.SetTooltip(close, CLOSE or "Close")
end

------------------------------------------------------------------------
-- Fenêtre
------------------------------------------------------------------------
local function Build()
    frame = CreateFrame("Frame", "BubulleWindow", UIParent, "BackdropTemplate")
    frame:SetSize(BOOK_W, BOOK_H)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    Theme.Backdrop(frame, nil, { 0.04, 0.02, 0.01, 1 }, Theme.tex.leather)
    frame:Hide()
    tinsert(UISpecialFrames, "BubulleWindow") -- Échap ferme la fenêtre

    -- Ombre portée sous le carnet
    local drop = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    drop:SetPoint("TOPLEFT", -6, 2)
    drop:SetPoint("BOTTOMRIGHT", 8, -10)
    drop:SetColorTexture(0, 0, 0, 0.45)

    -- Filet doré gravé dans le cuir
    local gilt = CreateFrame("Frame", nil, frame)
    gilt:SetPoint("TOPLEFT", 5, -5)
    gilt:SetPoint("BOTTOMRIGHT", -5, 5)
    W.GiltFrame(gilt, nil, { c.goldDk[1], c.goldDk[2], c.goldDk[3], 0.6 })

    W.MakeMovable(frame, "window")

    local builders = {
        { key = "session", build = BuildSessionSpread, refresh = RefreshSessionSpread },
        { key = "journal", build = BuildJournalSpread, refresh = RefreshJournalSpread },
        { key = "options", build = BuildOptionsSpread },
    }
    for i, entry in ipairs(builders) do
        local spread, left, right = CreateSpread(frame, i * 2 - 1)
        entry.build(spread, left, right)
        spread.refresh = entry.refresh
        pages[entry.key] = spread
    end

    DecorateCover(frame)

    -- Marque-pages sur le bord droit
    frame.tabs = W.Tabs(frame, {
        { key = "session", label = L.TAB_SESSION },
        { key = "journal", label = L.TAB_JOURNAL },
        { key = "options", label = L.TAB_OPTIONS },
    }, function(key)
        for pageKey, spread in pairs(pages) do
            spread:SetShown(pageKey == key)
        end
        frame.currentTab = key
        Window:Refresh()
    end)
    frame.tabs:SetPoint("TOPLEFT", frame, "TOPRIGHT", -2, -96)

    frame:SetScript("OnShow", function()
        ns.PlayUISound("IG_MAINMENU_OPEN")
        Window:Refresh()
    end)
    frame:SetScript("OnHide", function()
        ns.PlayUISound("IG_MAINMENU_CLOSE")
    end)

    frame.welcome = BuildWelcome()

    W.RestorePosition(frame, "window", "CENTER", "CENTER", -50, 30)
    frame.tabs:Select("session")
end

function Window:Refresh()
    if not frame or not frame:IsShown() then return end
    local spread = pages[frame.currentTab]
    if frame.currentTab == "options" then
        self:RefreshOptions()
    elseif spread and spread.refresh then
        spread.refresh(spread)
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
