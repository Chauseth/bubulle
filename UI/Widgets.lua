--[[
    Bubulle - UI/Widgets.lua
    ------------------------------------------------------------------
    La "boîte à outils" du carnet : textes, filets dorés, boutons,
    cases à cocher, curseurs, onglets en marque-page, listes...

    Chaque fonction fabrique un élément et le renvoie, prêt à placer.
    Toutes les couleurs et polices viennent de UI/Theme.lua.
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local c = Theme.color

local W = {}
ns.Widgets = W

------------------------------------------------------------------------
-- Bases
------------------------------------------------------------------------

--- Cadre avec fond et bordure fine (fond sombre et filet doré par défaut).
function W.Panel(parent, bg, border, bgFile)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme.Backdrop(frame, bg, border, bgFile)
    return frame
end

--- Texte avec une police du thème.
function W.Text(parent, font, justify, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFontObject(font or Theme.font.body)
    text:SetJustifyH(justify or "LEFT")
    text:SetWordWrap(false)
    return text
end

--- Info-bulle simple au survol.
function W.SetTooltip(frame, title, body)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        if body then
            GameTooltip:AddLine(body, nil, nil, nil, true)
        end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

--- Trait fin (horizontal par défaut).
function W.Line(parent, color, thickness, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    Theme.Fill(t, color or c.line)
    t:SetHeight(thickness or 1)
    return t
end

--- Cadre de filets dorés autour d'un cadre : un filet au bord, un autre
-- en retrait (inset), comme les pages d'un livre relié.
function W.GiltFrame(frame, inset, color, layer)
    local function Edge(offset, alpha)
        local col = { color[1], color[2], color[3], (color[4] or 1) * alpha }
        local top, bottom = W.Line(frame, col, 1, layer), W.Line(frame, col, 1, layer)
        top:SetPoint("TOPLEFT", offset, -offset)
        top:SetPoint("TOPRIGHT", -offset, -offset)
        bottom:SetPoint("BOTTOMLEFT", offset, offset)
        bottom:SetPoint("BOTTOMRIGHT", -offset, offset)
        local left, right = W.Line(frame, col, 1, layer), W.Line(frame, col, 1, layer)
        left:SetWidth(1)
        right:SetWidth(1)
        left:SetPoint("TOPLEFT", offset, -offset)
        left:SetPoint("BOTTOMLEFT", offset, offset)
        right:SetPoint("TOPRIGHT", -offset, -offset)
        right:SetPoint("BOTTOMRIGHT", -offset, offset)
    end
    if not Theme.deco.gilt then return end -- styles sans filets dorés
    color = color or c.goldDk
    Edge(0, 0.75)
    if inset then
        Edge(inset, 0.4)
    end
end

--- Filet d'ornement : un trait, un petit losange doré, un trait.
function W.Ornament(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(9)
    local diamond = holder:CreateTexture(nil, "ARTWORK")
    diamond:SetSize(6, 6)
    diamond:SetPoint("CENTER")
    diamond:SetRotation(math.rad(45))
    Theme.Fill(diamond, c.gold)
    local left = W.Line(holder, c.line)
    left:SetPoint("LEFT", 0, 0)
    left:SetPoint("RIGHT", diamond, "LEFT", -8, 0)
    local right = W.Line(holder, c.line)
    right:SetPoint("LEFT", diamond, "RIGHT", 8, 0)
    right:SetPoint("RIGHT", 0, 0)
    return holder
end

--- En-tête de page : petit sur-titre doré, grand titre, sous-titre en italique.
function W.PageHeader(parent)
    local head = CreateFrame("Frame", nil, parent)
    head:SetHeight(62)
    head.kicker = W.Text(head, Theme.font.kicker)
    head.kicker:SetPoint("TOPLEFT", 0, 0)
    head.kicker:SetPoint("RIGHT", 0, 0)
    head.title = W.Text(head, Theme.font.title)
    head.title:SetPoint("TOPLEFT", head.kicker, "BOTTOMLEFT", 0, -3)
    head.title:SetPoint("RIGHT", 0, 0)
    head.sub = W.Text(head, Theme.font.small)
    head.sub:SetPoint("TOPLEFT", head.title, "BOTTOMLEFT", 0, -3)
    head.sub:SetPoint("RIGHT", 0, 0)

    function head:Set(kicker, title, sub)
        self.kicker:SetText(kicker or "")
        self.title:SetText(title or "")
        self.sub:SetText(sub or "")
    end
    return head
end

--- Titre de section avec un filet doré dessous.
function W.SectionHeader(parent, text)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(22)
    holder.text = W.Text(holder, Theme.font.heading)
    holder.text:SetPoint("TOPLEFT", 0, 0)
    holder.text:SetText(text)
    local line = W.Line(holder, c.line)
    line:SetPoint("BOTTOMLEFT", 0, 3)
    line:SetPoint("BOTTOMRIGHT", 0, 3)
    return holder
end

--- Ligne de registre : "Prises ........ 24" (les points s'adaptent seuls).
function W.LedgerRow(parent, label)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(24)
    row.label = W.Text(row, Theme.font.body)
    row.label:SetPoint("LEFT", 0, 0)
    row.label:SetText(label)
    row.extra = W.Text(row, Theme.font.small, "RIGHT")
    row.extra:SetPoint("RIGHT", 0, 0)
    row.value = W.Text(row, Theme.font.numberSmall, "RIGHT")
    row.value:SetPoint("RIGHT", row.extra, "LEFT", 0, 0)
    -- Les points de conduite : un texte très long, coupé à la bonne
    -- largeur par le jeu (qui ajoute lui-même "..." : encore des points !).
    row.leader = W.Text(row, Theme.font.small)
    row.leader:SetPoint("LEFT", row.label, "RIGHT", 4, -2)
    row.leader:SetPoint("RIGHT", row.value, "LEFT", -4, -2)
    row.leader:SetText(string.rep(". ", 80))
    Theme.Paint(row.leader, { c.inkFaint[1], c.inkFaint[2], c.inkFaint[3], 0.55 })

    function row:Set(value, extra)
        self.value:SetText(value)
        self.extra:SetText(extra and ("  " .. extra) or "")
    end
    return row
end

------------------------------------------------------------------------
-- Apparition / disparition en fondu
------------------------------------------------------------------------
function W.AttachFader(frame, duration)
    local group = frame:CreateAnimationGroup()
    group:SetToFinalAlpha(true)
    local anim = group:CreateAnimation("Alpha")
    anim:SetDuration(duration or 0.18)
    anim:SetSmoothing("OUT")

    group:SetScript("OnFinished", function()
        frame:SetAlpha(group.target)
        if group.target == 0 then
            frame:Hide()
        end
    end)

    function frame:FadeTo(show)
        group:Stop()
        if show then
            if not self:IsShown() then
                self:SetAlpha(0)
                self:Show()
            end
            anim:SetFromAlpha(self:GetAlpha())
            anim:SetToAlpha(1)
            group.target = 1
        else
            if not self:IsShown() then return end
            anim:SetFromAlpha(self:GetAlpha())
            anim:SetToAlpha(0)
            group.target = 0
        end
        group:Play()
    end
end

------------------------------------------------------------------------
-- Déplacement à la souris + mémorisation de la position
------------------------------------------------------------------------
function W.MakeMovable(frame, key, handle, isLocked)
    handle = handle or frame
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        if isLocked and isLocked() then return end
        frame:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)
        local point, _, relativePoint, x, y = frame:GetPoint(1)
        ns.db.positions[key] = { point, relativePoint, x, y }
    end)
end

function W.RestorePosition(frame, key, point, relativePoint, x, y)
    local saved = ns.db.positions[key]
    frame:ClearAllPoints()
    if saved then
        frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
    else
        frame:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

------------------------------------------------------------------------
-- Boutons : couleurs du style (cuir et lettres dorées pour le carnet),
-- ou le bouton rouge du jeu pour le style « wow »
------------------------------------------------------------------------
local function ButtonColors(button)
    local hover = button.hover
    if button.blizzard then
        Theme.Paint(button.label, hover and c.btnTextHi or c.btnText)
        return
    end
    if button.primary then
        local bg = hover and c.primaryHi or c.primary
        button:SetBackdropColor(bg[1], bg[2], bg[3], 1)
        button:SetBackdropBorderColor(c.gold[1], c.gold[2], c.gold[3], 1)
        Theme.Paint(button.label, hover and c.primaryTextHi or c.primaryText)
    else
        local bg = hover and c.tabHi or c.tab
        button:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
        local border = hover and c.gold or c.goldDk
        button:SetBackdropBorderColor(border[1], border[2], border[3], hover and 1 or 0.7)
        Theme.Paint(button.label, hover and c.btnTextHi or c.btnText)
    end
end

--- Bouton. style = "primary" pour le bouton principal.
function W.Button(parent, text, width, height, style)
    local blizzard = Theme.deco.widgets == "blizzard"
    local button = CreateFrame("Button", nil, parent, blizzard and "UIPanelButtonTemplate" or "BackdropTemplate")
    button:SetSize(width or 110, height or 26)
    button.blizzard = blizzard
    if not blizzard then
        button:SetBackdrop({ bgFile = Theme.WHITE, edgeFile = Theme.WHITE, edgeSize = 1 })
    end
    button.primary = style == "primary"

    button.label = W.Text(button, Theme.font.button, "CENTER")
    button.label:SetPoint("CENTER", 0, 0)
    button.label:SetText(text or "")

    function button:SetLabel(newText)
        self.label:SetText(newText)
    end

    function button:SetPrimary(isPrimary)
        self.primary = isPrimary
        ButtonColors(self)
    end

    -- HookScript (et non SetScript) : le bouton du jeu garde ses effets.
    button:HookScript("OnEnter", function(self)
        self.hover = true
        ButtonColors(self)
    end)
    button:HookScript("OnLeave", function(self)
        self.hover = false
        ButtonColors(self)
    end)
    button:HookScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self.label:SetPoint("CENTER", 1, -1)
        end
    end)
    button:HookScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", 0, 0)
    end)
    button:HookScript("OnEnable", function(self) self:SetAlpha(1) end)
    button:HookScript("OnDisable", function(self) self:SetAlpha(0.45) end)
    button:HookScript("OnClick", function()
        ns.PlayUISound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    end)

    ButtonColors(button)
    return button
end

--- Petit bouton tracé à l'encre : "close" (croix) ou "menu" (3 traits).
function W.GlyphButton(parent, kind, size)
    size = size or 18
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)

    local strokes = {}
    local function Stroke()
        local t = button:CreateTexture(nil, "ARTWORK")
        Theme.Fill(t, c.inkFaint)
        strokes[#strokes + 1] = t
        return t
    end

    local inner = size * 0.55
    if kind == "close" then
        for _, angle in ipairs({ 45, -45 }) do
            local t = Stroke()
            t:SetSize(inner * 1.25, 1.5)
            t:SetPoint("CENTER")
            t:SetRotation(math.rad(angle))
        end
    else -- "menu"
        for i = -1, 1 do
            local t = Stroke()
            t:SetSize(inner, 1.5)
            t:SetPoint("CENTER", 0, i * (inner / 3))
        end
    end

    local function Tint(color)
        for _, t in ipairs(strokes) do Theme.Fill(t, color) end
    end
    button:SetScript("OnEnter", function() Tint(kind == "close" and c.danger or c.gold) end)
    button:SetScript("OnLeave", function() Tint(c.inkFaint) end)
    return button
end

--- Bouton rond en laiton avec une croix (fermer la fenêtre du carnet).
function W.BrassClose(parent, size)
    size = size or 28
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    local disc = button:CreateTexture(nil, "ARTWORK")
    disc:SetAllPoints()
    disc:SetTexture(Theme.tex.button)
    for _, angle in ipairs({ 45, -45 }) do
        local t = button:CreateTexture(nil, "OVERLAY")
        t:SetSize(size * 0.42, 2)
        t:SetPoint("CENTER")
        t:SetRotation(math.rad(angle))
        Theme.Fill(t, c.closeX)
    end
    button:SetScript("OnEnter", function() disc:SetVertexColor(1.15, 1.1, 1, 1) end)
    button:SetScript("OnLeave", function() disc:SetVertexColor(1, 1, 1, 1) end)
    return button
end

------------------------------------------------------------------------
-- Case à cocher : petite case sombre, coche dorée
------------------------------------------------------------------------
function W.Checkbox(parent, label, tooltip, get, set)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(22)

    -- La case est faite de deux carrés pleins (un doré, un sombre posé
    -- dessus) plutôt que d'un contour d'un pixel : selon l'échelle de
    -- l'interface, le jeu "arrondit" les traits fins et en efface parfois un.
    local box = CreateFrame("Frame", nil, button)
    box:SetSize(14, 14)
    box:SetPoint("LEFT", 0, 0)
    local edge = box:CreateTexture(nil, "BACKGROUND")
    edge:SetAllPoints()
    local inside = box:CreateTexture(nil, "BORDER")
    inside:SetPoint("TOPLEFT", 1.5, -1.5)
    inside:SetPoint("BOTTOMRIGHT", -1.5, 1.5)
    Theme.Fill(inside, c.pageDk)
    for _, t in ipairs({ edge, inside }) do
        if t.SetSnapToPixelGrid then
            t:SetSnapToPixelGrid(false)
            t:SetTexelSnappingBias(0)
        end
    end
    local function Edge(color) Theme.Fill(edge, color) end
    Edge(c.goldDk)

    -- Style « wow » : la case à cocher du jeu
    local hilite
    if Theme.deco.widgets == "blizzard" then
        edge:SetTexture(Theme.BLIZZ.checkUp)
        edge:ClearAllPoints()
        edge:SetPoint("CENTER")
        edge:SetSize(24, 24)
        inside:Hide()
        hilite = box:CreateTexture(nil, "OVERLAY", nil, -1)
        hilite:SetTexture(Theme.BLIZZ.checkHi)
        hilite:SetBlendMode("ADD")
        hilite:SetAllPoints(edge)
        hilite:Hide()
        Edge = function(color) hilite:SetShown(color == c.gold) end
    end

    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetSize(22, 22)
    mark:SetPoint("CENTER", 1, 1)
    mark:SetTexture(Theme.tex.check)

    button.text = W.Text(button, Theme.font.body)
    button.text:SetPoint("LEFT", box, "RIGHT", 9, 0)
    button.text:SetPoint("RIGHT", 0, 0)
    button.text:SetText(label)

    function button:Refresh()
        local on = get() and true or false
        mark:SetShown(on)
        Theme.Paint(self.text, on and c.ink or c.inkSoft)
    end

    function button:SetActive(enabled)
        self:SetEnabled(enabled)
        self:SetAlpha(enabled and 1 or 0.4)
    end

    button:SetScript("OnClick", function(self)
        local value = not get()
        set(value)
        ns.PlayUISound(value and "IG_MAINMENU_OPTION_CHECKBOX_ON" or "IG_MAINMENU_OPTION_CHECKBOX_OFF")
        self:Refresh()
    end)
    button:SetScript("OnEnter", function() Edge(c.gold) end)
    button:SetScript("OnLeave", function() Edge(c.goldDk) end)
    if tooltip then
        W.SetTooltip(button, label, tooltip)
    end

    button:Refresh()
    return button
end

------------------------------------------------------------------------
-- Curseur : un filet doré et un petit losange qu'on fait glisser
------------------------------------------------------------------------
function W.Slider(parent, label, minValue, maxValue, step, formatter, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(42)

    holder.label = W.Text(holder, Theme.font.body)
    holder.label:SetPoint("TOPLEFT", 0, 0)
    holder.label:SetText(label)

    holder.value = W.Text(holder, Theme.font.numberSmall, "RIGHT")
    holder.value:SetPoint("TOPRIGHT", 0, 0)
    Theme.Paint(holder.value, c.gold)

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(16)
    slider:SetPoint("BOTTOMLEFT", 0, 0)
    slider:SetPoint("BOTTOMRIGHT", 0, 0)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    holder.slider = slider

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(1)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    Theme.Fill(track, c.line)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(14, 14)
    thumb:SetColorTexture(0, 0, 0, 0) -- zone de prise, invisible
    slider:SetThumbTexture(thumb)

    local diamond = slider:CreateTexture(nil, "OVERLAY", nil, 2)
    diamond:SetSize(9, 9)
    diamond:SetPoint("CENTER", thumb, "CENTER")
    diamond:SetRotation(math.rad(45))
    Theme.Fill(diamond, c.gold)

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(2)
    fill:SetPoint("LEFT", track, "LEFT")
    fill:SetPoint("RIGHT", thumb, "CENTER")
    Theme.Fill(fill, c.goldDk)

    local function Round(value)
        return math.floor(value / step + 0.5) * step
    end

    slider:SetScript("OnValueChanged", function(_, value, userInput)
        value = Round(value)
        holder.value:SetText(formatter(value))
        if userInput then
            set(value)
        end
    end)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local value = Round(math.min(maxValue, math.max(minValue, self:GetValue() + delta * step)))
        self:SetValue(value)
        set(value)
    end)

    function holder:Refresh()
        local value = get()
        slider:SetValue(value)
        self.value:SetText(formatter(value))
    end

    function holder:SetActive(enabled)
        slider:SetEnabled(enabled)
        self:SetAlpha(enabled and 1 or 0.4)
    end

    holder:Refresh()
    return holder
end

------------------------------------------------------------------------
-- Bouton de choix de touche (clic gauche : choisir, clic droit : effacer)
------------------------------------------------------------------------
local MODIFIER_KEYS = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true,
}

function W.KeyButton(parent, get, set, width)
    local button = W.Button(parent, "", width or 140, 26)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local function Stop(self)
        self.listening = false
        self:EnableKeyboard(false)
    end

    function button:Refresh()
        local key = get()
        if key then
            self:SetLabel(GetBindingText(key))
        else
            self:SetLabel("|cff" .. Theme.FAINT_HEX .. L.KEY_NONE .. "|r")
        end
    end

    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "RightButton" then
            Stop(self)
            set(false)
            self:Refresh()
            return
        end
        if InCombatLockdown() then
            ns.Print(L.ERR_COMBAT)
            return
        end
        self.listening = true
        self:SetLabel("|cff" .. Theme.WATER_HEX .. L.KEY_PRESS .. "|r")
        self:EnableKeyboard(true)
    end)

    button:SetScript("OnKeyDown", function(self, key)
        if not self.listening then return end
        if key == "ESCAPE" then
            Stop(self)
            self:Refresh()
            return
        end
        if MODIFIER_KEYS[key] then return end
        local combo = (IsAltKeyDown() and "ALT-" or "")
            .. (IsControlKeyDown() and "CTRL-" or "")
            .. (IsShiftKeyDown() and "SHIFT-" or "")
            .. key
        Stop(self)
        -- Même si l'enregistrement échoue, le bouton ne doit pas rester
        -- bloqué sur « Appuie sur une touche... » : on rafraîchit quoi qu'il
        -- arrive, et on affiche l'erreur dans le chat pour la comprendre.
        local ok, err = pcall(set, combo)
        self:Refresh()
        if not ok then ns.Print("|cffff6060" .. tostring(err) .. "|r") end
    end)

    -- Important : définir OnKeyDown active le clavier sur ce bouton, ce qui
    -- empêcherait le personnage de bouger. On ne l'active que pendant le choix.
    button:EnableKeyboard(false)

    button:SetScript("OnHide", function(self)
        if self.listening then
            Stop(self)
            self:Refresh()
        end
    end)

    button:Refresh()
    return button
end

------------------------------------------------------------------------
-- Onglets : des marque-pages en ruban qui dépassent du bord du livre.
-- Chaque onglet a sa couleur (Theme.marks) ; l'onglet ouvert sort plus
-- loin et prend sa couleur vive, les autres restent un peu sombres.
------------------------------------------------------------------------
local TAB_W, TAB_H, TAB_GAP = 100, 30, 10
local TAB_OUT, TAB_HOVER = 18, 6 -- dépassement de l'onglet ouvert / survolé

function W.Tabs(parent, items, onSelect)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(TAB_W + TAB_OUT, #items * (TAB_H + TAB_GAP))
    holder.buttons = {}

    -- Longueur et teinte du ruban selon son état
    local function Paint(tab)
        local on = holder.selected == tab.key
        local length = TAB_W + (on and TAB_OUT or tab.hover and TAB_HOVER or 0)
        local light = on and 1 or tab.hover and 0.88 or 0.70
        local col = tab.color
        tab:SetWidth(length)
        tab.ribbon:SetVertexColor(col[1] * light, col[2] * light, col[3] * light)
        Theme.Paint(tab.text, (on or tab.hover) and c.tabTextOn or c.tabText)
        tab:SetFrameLevel(holder:GetFrameLevel() + (on and 2 or 1))
    end

    for i, item in ipairs(items) do
        local tab = CreateFrame("Button", nil, holder)
        tab.key = item.key
        tab.color = Theme.marks[(i - 1) % #Theme.marks + 1]
        tab:SetSize(TAB_W, TAB_H)
        tab:SetPoint("TOPLEFT", 0, -(i - 1) * (TAB_H + TAB_GAP))

        tab.ribbon = tab:CreateTexture(nil, "BACKGROUND")
        tab.ribbon:SetAllPoints()
        tab.ribbon:SetTexture(Theme.tex.bookmark)
        -- Ombre à la racine : le ruban semble sortir de sous la couverture
        local root = tab:CreateTexture(nil, "BORDER")
        root:SetPoint("TOPLEFT")
        root:SetPoint("BOTTOMLEFT")
        root:SetWidth(14)
        Theme.Shade(root, "HORIZONTAL", 0.6, 0)

        tab.text = W.Text(tab, Theme.font.button, "LEFT")
        tab.text:SetPoint("LEFT", 16, 0)
        tab.text:SetText(item.label)
        tab.text:SetShadowColor(0, 0, 0, 0.8)
        tab.text:SetShadowOffset(1, -1)

        tab:SetScript("OnClick", function()
            ns.PlayUISound("IG_CHARACTER_INFO_TAB")
            holder:Select(item.key)
        end)
        tab:SetScript("OnEnter", function(self)
            self.hover = true
            Paint(self)
        end)
        tab:SetScript("OnLeave", function(self)
            self.hover = false
            Paint(self)
        end)
        holder.buttons[i] = tab
    end

    function holder:Select(key)
        self.selected = key
        for _, tab in ipairs(self.buttons) do Paint(tab) end
        onSelect(key)
    end

    return holder
end

------------------------------------------------------------------------
-- Barre de progression (fine, dorée)
------------------------------------------------------------------------
function W.Bar(parent, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(height or 3)
    bar:SetStatusBarTexture(Theme.WHITE)
    bar:SetStatusBarColor(c.goldDk[1], c.goldDk[2], c.goldDk[3], 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    Theme.Fill(bar.bg, c.lineFaint)
    return bar
end

------------------------------------------------------------------------
-- Icône d'objet : cadre doré (couleur de qualité si l'objet est au moins
-- peu commun), quantité et info-bulle
------------------------------------------------------------------------
function W.ItemIcon(parent, size)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(size, size)
    Theme.Surface(frame, "field")
    local br, bg, bb, ba = frame:GetBackdropBorderColor()
    local baseBorder = br and { br, bg, bb, ba } or c.goldDk

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 2, -2)
    frame.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    frame.count = W.Text(frame, Theme.font.numberTiny, "RIGHT")
    frame.count:SetPoint("BOTTOMRIGHT", -1, 2)

    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    function frame:SetItem(itemID, texture, quality, count)
        self.itemID = itemID
        self.icon:SetTexture(texture or C_Item.GetItemIconByID(itemID) or 134400)
        if (quality or 1) >= 2 then
            local r, g, b = ns.QualityRGB(quality)
            self:SetBackdropBorderColor(r, g, b, 0.9)
        else
            self:SetBackdropBorderColor(baseBorder[1], baseBorder[2], baseBorder[3], (baseBorder[4] or 1) * 0.8)
        end
        self.count:SetText((count and count > 1) and count or "")
    end

    return frame
end

------------------------------------------------------------------------
-- Liste défilante légère (seules les lignes visibles existent)
--   createRow(list)            -> fabrique une ligne
--   updateRow(row, entry, i)   -> remplit une ligne avec une donnée
------------------------------------------------------------------------
function W.List(parent, rowHeight, createRow, updateRow)
    local list = CreateFrame("Frame", nil, parent)
    list.rows = {}
    list.data = {}
    list.offset = 0
    list.visible = 0

    local bar = CreateFrame("Slider", nil, list)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(5)
    bar:SetPoint("TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetValueStep(1)
    bar:SetObeyStepOnDrag(true)
    bar:SetMinMaxValues(0, 0)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetWidth(1)
    track:SetPoint("TOP")
    track:SetPoint("BOTTOM")
    Theme.Fill(track, c.line)

    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(5, 24)
    Theme.Fill(thumb, c.goldDk)
    bar:SetThumbTexture(thumb)

    list.empty = W.Text(list, Theme.font.small, "CENTER")
    list.empty:SetPoint("TOPLEFT", 12, -24)
    list.empty:SetPoint("TOPRIGHT", -12, -24)
    list.empty:SetWordWrap(true)
    list.empty:Hide()

    bar:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        if value ~= list.offset then
            list.offset = value
            list:Refresh()
        end
    end)

    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(self, delta)
        local _, maxOffset = bar:GetMinMaxValues()
        local value = math.min(maxOffset, math.max(0, self.offset - delta * 2))
        bar:SetValue(value)
    end)

    function list:SetEmptyText(text)
        self.empty:SetText(text)
    end

    function list:Layout()
        local count = math.floor((self:GetHeight() or 0) / rowHeight)
        self.visible = math.max(0, count)
        for i = 1, self.visible do
            local row = self.rows[i]
            if not row then
                row = createRow(self)
                row:SetHeight(rowHeight)
                row:SetPoint("TOPLEFT", 0, -(i - 1) * rowHeight)
                row:SetPoint("RIGHT", self, "RIGHT", -12, 0)
                self.rows[i] = row
            end
        end
        self:Refresh()
    end

    function list:SetData(data)
        self.data = data or {}
        self:Refresh()
    end

    function list:Refresh()
        local total = #self.data
        local maxOffset = math.max(0, total - self.visible)
        if self.offset > maxOffset then
            self.offset = maxOffset
        end
        bar:SetMinMaxValues(0, maxOffset)
        bar:SetValue(self.offset)
        bar:SetShown(maxOffset > 0)
        if total > 0 and self.visible > 0 then
            thumb:SetHeight(math.max(16, self:GetHeight() * self.visible / total))
        end

        for i, row in ipairs(self.rows) do
            local index = self.offset + i
            local entry = self.data[index]
            if i <= self.visible and entry then
                updateRow(row, entry, index)
                row:Show()
            else
                row:Hide()
            end
        end
        self.empty:SetShown(total == 0)
    end

    list:SetScript("OnSizeChanged", function(self)
        self:Layout()
    end)

    return list
end
