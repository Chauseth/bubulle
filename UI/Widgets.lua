--[[
    Bubulle - UI/Widgets.lua
    ------------------------------------------------------------------
    Une petite "boîte à outils" d'éléments d'interface réutilisables :
    boutons, cases à cocher, curseurs, onglets, listes défilantes...

    Pourquoi ne pas utiliser les modèles de Blizzard ? Pour avoir un
    style homogène et moderne, entièrement maîtrisé. Chaque fonction
    ci-dessous fabrique un élément et le renvoie, prêt à placer.
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

--- Cadre avec fond et bordure fine.
function W.Panel(parent, bg, border)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme.Backdrop(frame, bg or c.panel, border or c.border)
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

--- Titre de section avec un trait fin dessous.
function W.SectionHeader(parent, text)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(22)
    holder.text = W.Text(holder, Theme.font.heading)
    holder.text:SetPoint("TOPLEFT", 0, 0)
    holder.text:SetText(text)
    local line = holder:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 4)
    line:SetPoint("BOTTOMRIGHT", 0, 4)
    Theme.Fill(line, c.border)
    return holder
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
-- Boutons
------------------------------------------------------------------------
local function ButtonColors(button)
    if button.primary then
        local base = button.hover and c.accentHi or c.accent
        button:SetBackdropColor(base[1], base[2], base[3], 1)
        button:SetBackdropBorderColor(base[1], base[2], base[3], 1)
        button.label:SetTextColor(0.04, 0.09, 0.10)
    else
        local bg = button.hover and c.panelHi or c.panel
        local border = button.hover and c.accent or c.border
        button:SetBackdropColor(bg[1], bg[2], bg[3], 1)
        button:SetBackdropBorderColor(border[1], border[2], border[3], 1)
        Theme.Paint(button.label, button.hover and c.text or { 0.80, 0.85, 0.88, 1 })
    end
end

--- Bouton plat. style = "primary" pour le bouton principal (orange).
function W.Button(parent, text, width, height, style)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(width or 110, height or 24)
    button:SetBackdrop({ bgFile = Theme.WHITE, edgeFile = Theme.WHITE, edgeSize = 1 })
    button.primary = style == "primary"

    button.label = W.Text(button, Theme.font.body, "CENTER")
    button.label:SetPoint("CENTER", 0, 0)
    button.label:SetText(text or "")

    function button:SetLabel(newText)
        self.label:SetText(newText)
    end

    function button:SetPrimary(isPrimary)
        self.primary = isPrimary
        ButtonColors(self)
    end

    button:SetScript("OnEnter", function(self)
        self.hover = true
        ButtonColors(self)
    end)
    button:SetScript("OnLeave", function(self)
        self.hover = false
        ButtonColors(self)
    end)
    button:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() then
            self.label:SetPoint("CENTER", 1, -1)
        end
    end)
    button:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", 0, 0)
    end)
    button:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    button:SetScript("OnDisable", function(self) self:SetAlpha(0.45) end)
    button:HookScript("OnClick", function()
        ns.PlayUISound("IG_MAINMENU_OPTION_CHECKBOX_ON")
    end)

    ButtonColors(button)
    return button
end

--- Petit bouton icône dessiné à la main : "close" (croix) ou "menu" (3 traits).
function W.GlyphButton(parent, kind, size)
    size = size or 18
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)

    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    Theme.Fill(bg, c.panelHi)
    bg:Hide()

    local strokes = {}
    local function Stroke()
        local t = button:CreateTexture(nil, "ARTWORK")
        Theme.Fill(t, c.muted)
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
    button:SetScript("OnEnter", function()
        bg:Show()
        Tint(kind == "close" and c.danger or c.text)
    end)
    button:SetScript("OnLeave", function()
        bg:Hide()
        Tint(c.muted)
    end)
    return button
end

------------------------------------------------------------------------
-- Case à cocher
------------------------------------------------------------------------
function W.Checkbox(parent, label, tooltip, get, set)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(20)

    local box = CreateFrame("Frame", nil, button, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    Theme.Backdrop(box, c.track, c.border)

    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", 3, -3)
    mark:SetPoint("BOTTOMRIGHT", -3, 3)
    Theme.Fill(mark, c.accent)

    button.text = W.Text(button, Theme.font.body)
    button.text:SetPoint("LEFT", box, "RIGHT", 8, 0)
    button.text:SetPoint("RIGHT", 0, 0)
    button.text:SetText(label)

    function button:Refresh()
        local on = get() and true or false
        mark:SetShown(on)
        Theme.Paint(self.text, on and c.text or { 0.75, 0.80, 0.83, 1 })
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
    button:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(c.accent[1], c.accent[2], c.accent[3], 1)
    end)
    button:SetScript("OnLeave", function()
        box:SetBackdropBorderColor(c.border[1], c.border[2], c.border[3], 1)
    end)
    if tooltip then
        W.SetTooltip(button, label, tooltip)
    end

    button:Refresh()
    return button
end

------------------------------------------------------------------------
-- Curseur (slider)
------------------------------------------------------------------------
function W.Slider(parent, label, minValue, maxValue, step, formatter, get, set)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(40)

    holder.label = W.Text(holder, Theme.font.small)
    holder.label:SetPoint("TOPLEFT", 0, 0)
    holder.label:SetText(label)

    holder.value = W.Text(holder, Theme.font.body, "RIGHT")
    holder.value:SetPoint("TOPRIGHT", 0, 0)
    Theme.Paint(holder.value, c.accent)

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(16)
    slider:SetPoint("BOTTOMLEFT", 0, 2)
    slider:SetPoint("BOTTOMRIGHT", 0, 2)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouseWheel(true)
    holder.slider = slider

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(4)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    Theme.Fill(track, c.track)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 14)
    Theme.Fill(thumb, c.text)
    slider:SetThumbTexture(thumb)

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", track, "LEFT")
    fill:SetPoint("RIGHT", thumb, "CENTER")
    Theme.Fill(fill, c.accent)

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
    local button = W.Button(parent, "", width or 140, 24)
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
            self:SetLabel("|cff8b9daa" .. L.KEY_NONE .. "|r")
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
        self:SetLabel("|cff" .. Theme.ACCENT_HEX .. L.KEY_PRESS .. "|r")
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
        set(combo)
        self:Refresh()
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
-- Onglets
------------------------------------------------------------------------
function W.Tabs(parent, items, onSelect)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(30)
    holder.buttons = {}

    local x = 0
    for _, item in ipairs(items) do
        local tab = CreateFrame("Button", nil, holder)
        tab.key = item.key
        tab.text = W.Text(tab, Theme.font.body, "CENTER")
        tab.text:SetPoint("CENTER", 0, 1)
        tab.text:SetText(item.label)
        local width = math.max(80, math.ceil(tab.text:GetStringWidth()) + 28)
        tab:SetSize(width, 30)
        tab:SetPoint("BOTTOMLEFT", x, 0)
        x = x + width

        tab.underline = tab:CreateTexture(nil, "OVERLAY")
        tab.underline:SetHeight(2)
        tab.underline:SetPoint("BOTTOMLEFT", 8, 0)
        tab.underline:SetPoint("BOTTOMRIGHT", -8, 0)
        Theme.Fill(tab.underline, c.accent)

        tab:SetScript("OnClick", function()
            ns.PlayUISound("IG_CHARACTER_INFO_TAB")
            holder:Select(item.key)
        end)
        tab:SetScript("OnEnter", function(self)
            if holder.selected ~= self.key then Theme.Paint(self.text, c.text) end
        end)
        tab:SetScript("OnLeave", function(self)
            if holder.selected ~= self.key then Theme.Paint(self.text, c.muted) end
        end)
        holder.buttons[#holder.buttons + 1] = tab
    end
    holder:SetWidth(x) -- sans largeur, les onglets ne s'affichent pas

    function holder:Select(key)
        self.selected = key
        for _, tab in ipairs(self.buttons) do
            local isSelected = tab.key == key
            tab.underline:SetShown(isSelected)
            Theme.Paint(tab.text, isSelected and c.text or c.muted)
        end
        onSelect(key)
    end

    return holder
end

------------------------------------------------------------------------
-- Tuile de statistique (gros chiffre + libellé)
------------------------------------------------------------------------
function W.StatTile(parent, label)
    local tile = W.Panel(parent)

    tile.value = W.Text(tile, Theme.font.number)
    tile.value:SetPoint("TOPLEFT", 12, -10)
    tile.value:SetText("0")

    tile.label = W.Text(tile, Theme.font.tiny)
    tile.label:SetPoint("BOTTOMLEFT", 12, 9)
    tile.label:SetText(label)

    tile.sub = W.Text(tile, Theme.font.tiny, "RIGHT")
    tile.sub:SetPoint("BOTTOMRIGHT", -10, 9)

    local stripe = tile:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("TOPRIGHT", -1, -1)
    stripe:SetHeight(2)
    Theme.Fill(stripe, c.accentDim)

    function tile:SetValue(value, sub)
        self.value:SetText(value)
        self.sub:SetText(sub or "")
    end

    return tile
end

------------------------------------------------------------------------
-- Barre de progression
------------------------------------------------------------------------
function W.Bar(parent, height)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetHeight(height or 6)
    bar:SetStatusBarTexture(Theme.WHITE)
    local fillColor = c.accent
    bar:SetStatusBarColor(fillColor[1], fillColor[2], fillColor[3], 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    Theme.Fill(bar.bg, c.track)
    return bar
end

------------------------------------------------------------------------
-- Icône d'objet avec bordure de qualité, quantité et info-bulle
------------------------------------------------------------------------
function W.ItemIcon(parent, size)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(size, size)
    Theme.Backdrop(frame, c.track, c.border)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
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
        local r, g, b = ns.QualityRGB(quality)
        if (quality or 1) <= 1 then
            r, g, b = c.border[1], c.border[2], c.border[3]
        end
        self:SetBackdropBorderColor(r, g, b, 1)
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
    bar:SetWidth(4)
    bar:SetPoint("TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", 0, 0)
    bar:SetValueStep(1)
    bar:SetObeyStepOnDrag(true)
    bar:SetMinMaxValues(0, 0)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    Theme.Fill(track, c.track)

    local thumb = bar:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(4, 24)
    Theme.Fill(thumb, c.muted)
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
                row:SetPoint("RIGHT", self, "RIGHT", -10, 0)
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
