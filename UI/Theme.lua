--[[
    Bubulle - UI/Theme.lua
    ------------------------------------------------------------------
    La charte graphique du carnet de pêche, au même endroit :
    couleurs, polices, textures. Changer une valeur ici change tout
    l'addon d'un coup (pratique pour expérimenter !).

    Style : un vieux carnet relié de cuir brun, pages sombres, encre
    crème, filets et coins dorés. Bubulle écrit à la main, en bleu d'eau.
]]

local _, ns = ...

local Theme = {}
ns.Theme = Theme

local MEDIA = "Interface\\AddOns\\Bubulle\\Media\\"

------------------------------------------------------------------------
-- Couleurs { rouge, vert, bleu, opacité } entre 0 et 1
------------------------------------------------------------------------
Theme.color = {
    ink       = { 0.949, 0.894, 0.776, 1 },    -- texte principal (crème)
    inkSoft   = { 0.847, 0.765, 0.608, 1 },    -- texte secondaire
    inkFaint  = { 0.659, 0.576, 0.435, 1 },    -- légendes, aides
    gold      = { 0.902, 0.749, 0.408, 1 },    -- titres, onglet actif, cases cochées
    goldDk    = { 0.690, 0.522, 0.255, 1 },    -- bordures dorées
    line      = { 0.769, 0.604, 0.322, 0.35 }, -- filets fins
    lineFaint = { 0.769, 0.604, 0.322, 0.16 }, -- séparateurs de lignes
    water     = { 0.690, 0.871, 0.910, 1 },    -- ce que dit Bubulle
    fish      = { 0.878, 0.604, 0.243, 1 },    -- orange "poisson rouge"
    danger    = { 0.902, 0.443, 0.384, 1 },
    pageDk    = { 0.090, 0.063, 0.043, 1 },    -- fond des icônes et des champs
    tab       = { 0.231, 0.141, 0.086, 1 },    -- onglets inactifs
    tabHi     = { 0.302, 0.188, 0.110, 1 },
    shadow    = { 0, 0, 0, 0.45 },
}
local c = Theme.color

Theme.ACCENT_HEX = "e6bf68"
Theme.WATER_HEX = "b0dee8"
Theme.FAINT_HEX = "a8936f"
Theme.WHITE = "Interface\\Buttons\\WHITE8x8"
Theme.ICON_FISHING = "Interface\\Icons\\Trade_Fishing"

Theme.tex = {
    page    = MEDIA .. "page",
    leather = MEDIA .. "leather",
    corner  = MEDIA .. "corner",
    ribbon  = MEDIA .. "ribbon",
    bobber  = MEDIA .. "bobber",
    button  = MEDIA .. "button",
    check   = "Interface\\Buttons\\UI-CheckBox-Check",
}

------------------------------------------------------------------------
-- Polices
-- Alegreya (texte et titres) et Caveat (l'écriture de Bubulle) sont des
-- polices libres (licence SIL OFL, voir Media/Fonts). Pour essayer une
-- autre police, il suffit de changer ces chemins, par exemple
-- "Fonts\\MORPHEUS.TTF" ou "Fonts\\FRIZQT__.TTF" (polices du jeu).
------------------------------------------------------------------------
Theme.FONT_TEXT   = MEDIA .. "Fonts\\Alegreya-Regular.ttf"
Theme.FONT_ITALIC = MEDIA .. "Fonts\\Alegreya-Italic.ttf"
Theme.FONT_BOLD   = MEDIA .. "Fonts\\Alegreya-Bold.ttf"
Theme.FONT_TITLE  = MEDIA .. "Fonts\\AlegreyaSC-Bold.ttf"
-- Les chiffres : Alegreya dessine ses chiffres "à l'ancienne" (le 0 ressemble
-- à un o), on prend donc la police du jeu pour les nombres.
Theme.FONT_NUMBER = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

-- La "voix" de Bubulle. L'écriture manuscrite (Caveat) était peu lisible
-- en jeu : il parle donc en italique. Pour revenir à l'écriture à la main,
-- remplacer par MEDIA .. "Fonts\\Caveat-Bold.ttf" et HAND_SIZE par 20.
Theme.FONT_HAND   = MEDIA .. "Fonts\\Alegreya-Italic.ttf"
local HAND_SIZE   = 16

-- Ces polices n'ont que l'alphabet latin : en coréen, chinois ou russe,
-- on garde la police du jeu pour que les noms de zones et d'objets
-- s'affichent correctement.
local LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, itIT = true, ptBR = true }
if not LATIN[GetLocale()] then
    local fallback = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    Theme.FONT_TEXT, Theme.FONT_ITALIC, Theme.FONT_BOLD = fallback, fallback, fallback
    Theme.FONT_TITLE, Theme.FONT_HAND = fallback, fallback
end

local function MakeFont(name, file, size, color, flags)
    local font = CreateFont(name)
    font:SetFont(file, size, flags or "")
    font:SetTextColor(color[1], color[2], color[3], color[4] or 1)
    font:SetShadowColor(0, 0, 0, 0.6)
    font:SetShadowOffset(1, -1)
    return font
end

Theme.font = {
    title       = MakeFont("BubulleFontTitle",   Theme.FONT_TITLE,  22, c.ink),
    kicker      = MakeFont("BubulleFontKicker",  Theme.FONT_TITLE,  12, c.gold),
    heading     = MakeFont("BubulleFontHeading", Theme.FONT_TITLE,  14, c.gold),
    body        = MakeFont("BubulleFontBody",    Theme.FONT_TEXT,   15, c.ink),
    bold        = MakeFont("BubulleFontBold",    Theme.FONT_BOLD,   15, c.ink),
    small       = MakeFont("BubulleFontSmall",   Theme.FONT_ITALIC, 13, c.inkSoft),
    tiny        = MakeFont("BubulleFontTiny",    Theme.FONT_ITALIC, 12, c.inkFaint),
    hand        = MakeFont("BubulleFontHand",    Theme.FONT_HAND,   HAND_SIZE + 3, c.water),
    handSmall   = MakeFont("BubulleFontHandSm",  Theme.FONT_HAND,   HAND_SIZE, c.water),
    number      = MakeFont("BubulleFontNumber",  Theme.FONT_NUMBER, 19, c.ink),
    numberSmall = MakeFont("BubulleFontNumSm",   Theme.FONT_NUMBER, 14, c.ink),
    numberTiny  = MakeFont("BubulleFontNumTiny", Theme.FONT_NUMBER, 11, c.ink, "OUTLINE"),
    button      = MakeFont("BubulleFontButton",  Theme.FONT_TITLE,  13, c.gold),
}

------------------------------------------------------------------------
-- Couleurs de qualité, éclaircies pour rester lisibles sur le papier
-- sombre (le bleu "rare" du jeu y serait presque invisible).
------------------------------------------------------------------------
local QUALITY = {
    [0] = { 0.62, 0.60, 0.56 },
    [1] = { c.ink[1], c.ink[2], c.ink[3] },
    [2] = { 0.53, 0.84, 0.44 },
    [3] = { 0.42, 0.66, 1.00 },
    [4] = { 0.80, 0.55, 1.00 },
    [5] = { 1.00, 0.62, 0.25 },
}

function ns.QualityRGB(quality)
    local q = QUALITY[quality or 1] or QUALITY[1]
    return q[1], q[2], q[3]
end

function ns.QualityHex(quality)
    local r, g, b = ns.QualityRGB(quality)
    return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end

------------------------------------------------------------------------
-- Petits outils de dessin
------------------------------------------------------------------------

--- Applique une couleur du thème à une texture.
function Theme.Fill(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

--- Applique une couleur du thème à un texte.
function Theme.Paint(fontString, color)
    fontString:SetTextColor(color[1], color[2], color[3], color[4] or 1)
end

--- Fond uni + bordure d'un pixel (le cadre doit hériter de "BackdropTemplate").
-- bgFile permet d'utiliser une texture (papier, cuir) au lieu d'une couleur.
function Theme.Backdrop(frame, bg, border, bgFile)
    frame:SetBackdrop({ bgFile = bgFile or Theme.WHITE, edgeFile = Theme.WHITE, edgeSize = 1 })
    bg = bg or (bgFile and { 1, 1, 1, 1 }) or c.pageDk
    border = border or c.goldDk
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

--- Dégradé d'ombre (vers l'intérieur d'une page, sous un onglet...).
-- direction : "HORIZONTAL" ou "VERTICAL" ; from / to : opacités.
function Theme.Shade(texture, direction, from, to)
    texture:SetColorTexture(1, 1, 1, 1)
    if texture.SetGradient and CreateColor then
        texture:SetGradient(direction, CreateColor(0, 0, 0, from), CreateColor(0, 0, 0, to))
    else
        texture:SetColorTexture(0, 0, 0, (from + to) / 2)
    end
end
