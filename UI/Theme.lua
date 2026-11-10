--[[
    Bubulle - UI/Theme.lua
    ------------------------------------------------------------------
    La charte graphique de l'addon, au même endroit :
    couleurs, polices, textures. Changer une valeur ici change tout
    l'addon d'un coup (pratique pour expérimenter !).

    Style : bleu nuit des profondeurs, accent "poisson rouge" (la
    couleur de Bubulle) et eau turquoise pour le bouchon.
]]

local _, ns = ...

local Theme = {}
ns.Theme = Theme

-- Couleurs { rouge, vert, bleu, opacité } entre 0 et 1
Theme.color = {
    bg        = { 0.051, 0.067, 0.082, 0.96 }, -- fond des fenêtres
    header    = { 0.071, 0.090, 0.110, 1.00 }, -- bandeau du haut
    panel     = { 0.086, 0.110, 0.133, 1.00 }, -- cartes
    panelHi   = { 0.118, 0.149, 0.176, 1.00 }, -- survol
    border    = { 0.165, 0.212, 0.247, 1.00 }, -- bordures fines
    track     = { 0.137, 0.173, 0.204, 1.00 }, -- fond des barres
    accent    = { 0.957, 0.639, 0.227, 1.00 }, -- orange "poisson rouge"
    accentHi  = { 1.000, 0.737, 0.380, 1.00 },
    accentDim = { 0.957, 0.639, 0.227, 0.18 },
    water     = { 0.290, 0.745, 0.859, 1.00 }, -- turquoise (barre du bouchon)
    bubble    = { 0.133, 0.176, 0.212, 1.00 }, -- bulle de dialogue
    gold      = { 1.000, 0.800, 0.360, 1.00 },
    text      = { 0.910, 0.933, 0.949, 1.00 },
    muted     = { 0.545, 0.616, 0.667, 1.00 },
    faint     = { 0.345, 0.404, 0.447, 1.00 },
    danger    = { 0.902, 0.384, 0.384, 1.00 },
}

Theme.ACCENT_HEX = "f4a33a"
Theme.WHITE = "Interface\\Buttons\\WHITE8x8"
Theme.ICON_FISHING = "Interface\\Icons\\Trade_Fishing"

-- Police principale : celle du jeu (gère les accents et toutes les langues).
Theme.FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
-- Police des chiffres : plus étroite, très lisible.
Theme.FONT_NUMBER = "Fonts\\ARIALN.TTF"

local function MakeFont(name, file, size, color, flags)
    local font = CreateFont(name)
    font:SetFont(file, size, flags or "")
    font:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    font:SetShadowColor(0, 0, 0, 0.75)
    font:SetShadowOffset(1, -1)
    return font
end

local c = Theme.color
Theme.font = {
    title       = MakeFont("BubulleFontTitle",       Theme.FONT,        15, c.text),
    heading     = MakeFont("BubulleFontHeading",     Theme.FONT,        12, c.accent),
    body        = MakeFont("BubulleFontBody",        Theme.FONT,        12, c.text),
    small       = MakeFont("BubulleFontSmall",       Theme.FONT,        11, c.muted),
    tiny        = MakeFont("BubulleFontTiny",        Theme.FONT,        10, c.muted),
    number      = MakeFont("BubulleFontNumber",      Theme.FONT_NUMBER, 24, c.text),
    numberSmall = MakeFont("BubulleFontNumberSmall", Theme.FONT_NUMBER, 16, c.text),
    numberTiny  = MakeFont("BubulleFontNumberTiny",  Theme.FONT_NUMBER, 12, c.text, "OUTLINE"),
}

--- Applique une couleur du thème à une texture.
function Theme.Fill(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

--- Applique une couleur du thème à un texte.
function Theme.Paint(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

--- Fond uni + bordure d'un pixel (le cadre doit hériter de "BackdropTemplate").
function Theme.Backdrop(frame, bg, border)
    frame:SetBackdrop({ bgFile = Theme.WHITE, edgeFile = Theme.WHITE, edgeSize = 1 })
    bg = bg or c.panel
    border = border or c.border
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end
