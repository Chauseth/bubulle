--[[
    Bubulle - UI/Theme.lua
    ------------------------------------------------------------------
    Les styles de Bubulle : couleurs, polices, fonds et décorations.
    Chaque style (« thème ») est une simple table de réglages ci-dessous ;
    le reste de l'addon ne lit que Theme.color, Theme.font, Theme.Surface
    et Theme.deco, sans savoir quel style est choisi.

    Le style est appliqué au chargement (avant que la moindre fenêtre soit
    construite). En changer demande donc de recharger l'interface.

      carnet : vieux carnet relié de cuir, pages sombres, filets dorés
      clair  : le même carnet, papier crème et encre brune
      sombre : moderne et épuré, gris anthracite, sans décor
      wow    : les cadres et la police des fenêtres du jeu
]]

local _, ns = ...

local Theme = {}
ns.Theme = Theme

local MEDIA = "Interface\\AddOns\\Bubulle\\Media\\"
local FONTS = MEDIA .. "Fonts\\"
local GAME_FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

Theme.WHITE = "Interface\\Buttons\\WHITE8x8"
Theme.ICON_FISHING = "Interface\\Icons\\Trade_Fishing"

-- Nos propres images (Media/*.tga, dessinées par tools/draw_textures.py)
Theme.tex = {
    page      = MEDIA .. "page",
    pageLight = MEDIA .. "page_light",
    leather   = MEDIA .. "leather",
    corner    = MEDIA .. "corner",
    ribbon    = MEDIA .. "ribbon",
    bobber    = MEDIA .. "bobber",
    button    = MEDIA .. "button",
    check     = "Interface\\Buttons\\UI-CheckBox-Check",
}
local tex = Theme.tex

-- Images du jeu lui-même, pour le style « wow »
local BLIZZ = {
    dialogBg     = "Interface\\DialogFrame\\UI-DialogBox-Background",
    dialogBorder = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tipBg        = "Interface\\Tooltips\\UI-Tooltip-Background",
    tipBorder    = "Interface\\Tooltips\\UI-Tooltip-Border",
    checkUp      = "Interface\\Buttons\\UI-CheckBox-Up",
    checkHi      = "Interface\\Buttons\\UI-CheckBox-Highlight",
    rock         = "Interface\\FrameGeneral\\UI-Background-Rock",
}
Theme.BLIZZ = BLIZZ

------------------------------------------------------------------------
-- Les polices : quel fichier pour quel rôle, et à quelle taille
------------------------------------------------------------------------
local ALEGREYA = {
    text   = FONTS .. "Alegreya-Regular.ttf",
    italic = FONTS .. "Alegreya-Italic.ttf",
    bold   = FONTS .. "Alegreya-Bold.ttf",
    title  = FONTS .. "AlegreyaSC-Bold.ttf",
    -- La voix de Bubulle : l'écriture à la main (Caveat-Bold.ttf) était
    -- peu lisible en jeu, il parle donc en italique.
    hand   = FONTS .. "Alegreya-Italic.ttf",
    -- Alegreya dessine ses chiffres "à l'ancienne" (le 0 ressemble à un o) :
    -- on prend la police du jeu pour les nombres.
    number = GAME_FONT,
}
local FIRA = {
    text   = FONTS .. "FiraSans-Regular.ttf",
    italic = FONTS .. "FiraSans-Italic.ttf",
    bold   = FONTS .. "FiraSans-SemiBold.ttf",
    title  = FONTS .. "FiraSans-SemiBold.ttf",
    hand   = FONTS .. "FiraSans-Italic.ttf",
    number = FONTS .. "FiraSans-Regular.ttf",
}
local GAME = {
    text = GAME_FONT, italic = GAME_FONT, bold = GAME_FONT,
    title = GAME_FONT, hand = GAME_FONT, number = GAME_FONT,
}

-- Rôle de chaque police de l'addon : famille, couleur (nom dans la palette)
local FONT_ROLES = {
    title       = { "title",  "ink" },
    kicker      = { "title",  "gold" },
    heading     = { "title",  "gold" },
    body        = { "text",   "ink" },
    bold        = { "bold",   "ink" },
    small       = { "italic", "inkSoft" },
    tiny        = { "italic", "inkFaint" },
    hand        = { "hand",   "water" },
    handSmall   = { "hand",   "water" },
    number      = { "number", "ink" },
    numberSmall = { "number", "ink" },
    numberTiny  = { "number", "count", "OUTLINE" },
    button      = { "title",  "gold" },
}

-- Tailles : Alegreya est petite à taille égale, les autres plus grandes.
local SIZES_SERIF = {
    title = 22, kicker = 12, heading = 14, body = 15, bold = 15, small = 13, tiny = 12,
    hand = 19, handSmall = 16, number = 19, numberSmall = 14, numberTiny = 11, button = 13,
}
local SIZES_SANS = {
    title = 19, kicker = 11, heading = 13, body = 13, bold = 13, small = 12, tiny = 11,
    hand = 15, handSmall = 13, number = 17, numberSmall = 13, numberTiny = 11, button = 12,
}

------------------------------------------------------------------------
-- Les styles
--   color   : la palette { rouge, vert, bleu, opacité } entre 0 et 1
--   hex     : les mêmes couleurs pour colorer un bout de texte (|cff...)
--   quality : couleurs des qualités d'objet, lisibles sur ce fond
--   surface : le fond et la bordure de chaque type de cadre
--   deco    : les décorations (ruban, coins, scotch...) et les widgets
------------------------------------------------------------------------
local THEMES = {}
Theme.ORDER = { "carnet", "clair", "sombre", "wow" }

-- Couleurs de qualité éclaircies pour les fonds sombres (le bleu "rare"
-- du jeu y serait presque invisible).
local QUALITY_BRIGHT = {
    [0] = { 0.62, 0.60, 0.56 }, [2] = { 0.53, 0.84, 0.44 }, [3] = { 0.42, 0.66, 1.00 },
    [4] = { 0.80, 0.55, 1.00 }, [5] = { 1.00, 0.62, 0.25 },
}

THEMES.carnet = {
    color = {
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
        tab       = { 0.231, 0.141, 0.086, 1 },    -- onglets inactifs, boutons
        tabHi     = { 0.302, 0.188, 0.110, 1 },
        count     = { 0.949, 0.894, 0.776, 1 },    -- quantité sur une icône
        shadow    = { 0, 0, 0, 0.45 },
        -- Boutons
        btnText   = { 0.847, 0.765, 0.608, 1 },
        btnTextHi = { 0.902, 0.749, 0.408, 1 },
        primary   = { 0.34, 0.21, 0.08, 1 },
        primaryHi = { 0.42, 0.27, 0.11, 1 },
        primaryText   = { 0.902, 0.749, 0.408, 1 },
        primaryTextHi = { 0.949, 0.894, 0.776, 1 },
        -- Décor
        spine     = { 0.05, 0.03, 0.02, 0.85 },
        tape      = { 0.80, 0.72, 0.55, 0.38 },
        closeX    = { 0.29, 0.20, 0.07, 1 },
    },
    hex = { accent = "e6bf68", water = "b0dee8", faint = "a8936f" },
    quality = QUALITY_BRIGHT,
    fonts = ALEGREYA, sizes = SIZES_SERIF,
    fontShadow = { 0, 0, 0, 0.6 },
    surface = {
        window = { bgFile = tex.leather, border = { 0.04, 0.02, 0.01, 1 } },
        page   = { bgFile = tex.page, border = { 0.03, 0.02, 0.01, 1 } },
        card   = { bgFile = tex.page, border = { 0.03, 0.02, 0.01, 1 } },
        toast  = { bgFile = tex.page, border = { 0.690, 0.522, 0.255, 0.8 } },
        tabOn  = { bgFile = tex.page, border = "goldDk" },
        tabOff = { bg = "tab", border = { 0.690, 0.522, 0.255, 0.5 } },
        field  = { bg = "pageDk", border = "goldDk" },
    },
    deco = {
        gilt = true, ribbon = true, corners = true, spine = true, tape = true,
        pageShade = 0.55, drop = true, folio = true, close = "brass", widgets = "custom",
    },
}

THEMES.clair = {
    color = {
        ink       = { 0.200, 0.140, 0.090, 1 },
        inkSoft   = { 0.360, 0.270, 0.180, 1 },
        inkFaint  = { 0.500, 0.420, 0.320, 1 },
        gold      = { 0.600, 0.380, 0.090, 1 },
        goldDk    = { 0.580, 0.430, 0.220, 1 },
        line      = { 0.550, 0.400, 0.200, 0.40 },
        lineFaint = { 0.550, 0.400, 0.200, 0.18 },
        water     = { 0.100, 0.360, 0.520, 1 },
        fish      = { 0.820, 0.430, 0.100, 1 },
        danger    = { 0.720, 0.200, 0.150, 1 },
        pageDk    = { 0.965, 0.940, 0.870, 1 },
        tab       = { 0.760, 0.660, 0.500, 1 },
        tabHi     = { 0.820, 0.730, 0.580, 1 },
        count     = { 1, 1, 1, 1 },
        shadow    = { 0, 0, 0, 0.30 },
        btnText   = { 0.200, 0.140, 0.090, 1 },
        btnTextHi = { 0.200, 0.140, 0.090, 1 },
        primary   = { 0.440, 0.290, 0.130, 1 },
        primaryHi = { 0.520, 0.350, 0.160, 1 },
        primaryText   = { 0.970, 0.930, 0.840, 1 },
        primaryTextHi = { 1, 1, 1, 1 },
        spine     = { 0.05, 0.03, 0.02, 0.85 },
        tape      = { 0.70, 0.62, 0.45, 0.45 },
        closeX    = { 0.29, 0.20, 0.07, 1 },
    },
    hex = { accent = "9a6117", water = "1a5c85", faint = "806b52" },
    quality = {
        [0] = { 0.45, 0.43, 0.40 }, [2] = { 0.10, 0.48, 0.05 }, [3] = { 0.00, 0.34, 0.78 },
        [4] = { 0.48, 0.16, 0.72 }, [5] = { 0.78, 0.38, 0.00 },
    },
    fonts = ALEGREYA, sizes = SIZES_SERIF,
    fontShadow = { 0, 0, 0, 0 },
    surface = {
        window = { bgFile = tex.leather, border = { 0.04, 0.02, 0.01, 1 } },
        page   = { bgFile = tex.pageLight, border = { 0.40, 0.30, 0.18, 1 } },
        card   = { bgFile = tex.pageLight, border = { 0.40, 0.30, 0.18, 1 } },
        toast  = { bgFile = tex.pageLight, border = "goldDk" },
        tabOn  = { bgFile = tex.pageLight, border = "goldDk" },
        tabOff = { bg = "tab", border = { 0.40, 0.30, 0.18, 0.8 } },
        field  = { bg = "pageDk", border = "goldDk" },
    },
    deco = {
        gilt = true, ribbon = true, corners = true, spine = true, tape = true,
        pageShade = 0.22, drop = true, folio = true, close = "brass", widgets = "custom",
    },
}

THEMES.sombre = {
    color = {
        ink       = { 0.930, 0.940, 0.960, 1 },
        inkSoft   = { 0.740, 0.770, 0.810, 1 },
        inkFaint  = { 0.530, 0.570, 0.620, 1 },
        gold      = { 0.450, 0.740, 0.960, 1 },    -- couleur d'accent : bleu
        goldDk    = { 0.300, 0.360, 0.430, 1 },
        line      = { 0.550, 0.620, 0.700, 0.25 },
        lineFaint = { 0.550, 0.620, 0.700, 0.10 },
        water     = { 0.550, 0.850, 0.900, 1 },
        fish      = { 0.960, 0.600, 0.260, 1 },
        danger    = { 0.940, 0.420, 0.400, 1 },
        pageDk    = { 0.090, 0.100, 0.110, 1 },
        tab       = { 0.130, 0.140, 0.160, 1 },
        tabHi     = { 0.180, 0.200, 0.230, 1 },
        count     = { 1, 1, 1, 1 },
        shadow    = { 0, 0, 0, 0.5 },
        btnText   = { 0.740, 0.770, 0.810, 1 },
        btnTextHi = { 0.930, 0.940, 0.960, 1 },
        primary   = { 0.200, 0.400, 0.580, 1 },
        primaryHi = { 0.240, 0.470, 0.670, 1 },
        primaryText   = { 1, 1, 1, 1 },
        primaryTextHi = { 1, 1, 1, 1 },
        spine     = { 0, 0, 0, 0 },
        tape      = { 0, 0, 0, 0 },
        closeX    = { 0.930, 0.940, 0.960, 1 },
    },
    hex = { accent = "73bdf5", water = "8cd9e6", faint = "878f9e" },
    quality = QUALITY_BRIGHT,
    fonts = FIRA, sizes = SIZES_SANS,
    fontShadow = { 0, 0, 0, 0.35 },
    surface = {
        window = { bg = { 0.075, 0.080, 0.090, 0.97 }, border = { 0.20, 0.22, 0.25, 1 } },
        page   = { bg = { 0.110, 0.120, 0.135, 1 }, border = { 0.19, 0.21, 0.24, 1 } },
        card   = { bg = { 0.090, 0.100, 0.110, 0.95 }, border = { 0.22, 0.24, 0.28, 1 } },
        toast  = { bg = { 0.090, 0.100, 0.110, 0.95 }, border = { 0.22, 0.24, 0.28, 1 } },
        tabOn  = { bg = { 0.110, 0.120, 0.135, 1 }, border = "gold" },
        tabOff = { bg = "tab", border = { 0.19, 0.21, 0.24, 1 } },
        field  = { bg = "pageDk", border = { 0.24, 0.27, 0.31, 1 } },
    },
    deco = {
        gilt = false, ribbon = false, corners = false, spine = false, tape = false,
        pageShade = false, drop = true, folio = false, close = "glyph", widgets = "custom",
    },
}

-- Style « wow » : comme le grimoire du jeu. Cadre de métal sur fond de
-- roche, pages de parchemin, encre brune et police du jeu.
local function Tip(bg, border) -- cadre façon info-bulle du jeu
    return { bgFile = BLIZZ.tipBg, edgeFile = BLIZZ.tipBorder, edgeSize = 16,
             tile = true, inset = 4, bg = bg, border = border }
end

THEMES.wow = {
    color = {
        ink       = { 0.200, 0.120, 0.050, 1 },    -- encre brune du grimoire
        inkSoft   = { 0.320, 0.220, 0.120, 1 },
        inkFaint  = { 0.450, 0.350, 0.240, 1 },
        gold      = { 0.420, 0.220, 0.040, 1 },    -- titres : brun-roux
        goldDk    = { 0.500, 0.370, 0.200, 1 },
        line      = { 0.400, 0.260, 0.110, 0.45 },
        lineFaint = { 0.400, 0.260, 0.110, 0.18 },
        water     = { 0.080, 0.300, 0.480, 1 },
        fish      = { 0.800, 0.400, 0.080, 1 },
        danger    = { 0.700, 0.150, 0.100, 1 },
        pageDk    = { 0, 0, 0, 0.55 },
        tab       = { 0.05, 0.05, 0.05, 0.9 },
        tabHi     = { 0.12, 0.12, 0.12, 0.9 },
        count     = { 1, 1, 1, 1 },
        shadow    = { 0, 0, 0, 0.5 },
        btnText   = { 1, 0.82, 0, 1 },
        btnTextHi = { 1, 1, 1, 1 },
        primary   = { 1, 1, 1, 1 },
        primaryHi = { 1, 1, 1, 1 },
        primaryText   = { 1, 0.82, 0, 1 },
        primaryTextHi = { 1, 1, 1, 1 },
        tabText   = { 1, 0.82, 0, 1 },             -- onglets sur fond sombre
        tabTextOn = { 1, 1, 1, 1 },
        spine     = { 0, 0, 0, 0 },
        tape      = { 0, 0, 0, 0 },
        closeX    = { 1, 1, 1, 1 },
    },
    hex = { accent = "6b380a", water = "144d7a", faint = "73593d" },
    quality = {
        [0] = { 0.40, 0.38, 0.35 }, [2] = { 0.08, 0.42, 0.04 }, [3] = { 0.00, 0.30, 0.70 },
        [4] = { 0.45, 0.12, 0.65 }, [5] = { 0.72, 0.34, 0.00 },
    },
    fonts = GAME, sizes = SIZES_SANS,
    fontShadow = { 0, 0, 0, 0 },
    surface = {
        -- Cadre de métal des fenêtres du jeu, fond de roche
        window   = { panel = "ButtonFrameTemplateNoPortrait", bgFile = BLIZZ.rock },
        -- Les deux pages du grimoire
        pageLeft = { atlas = "spellbook-Page-Left-C60" },
        page     = { atlas = "spellbook-Page-Right-C60" },
        card     = { atlas = "spellbook-Page-Right-C60" },
        toast    = Tip({ 0.84, 0.74, 0.56, 0.97 }, { 0.55, 0.42, 0.25, 1 }),
        tabOn    = Tip({ 0.10, 0.10, 0.10, 0.95 }, { 1, 0.82, 0, 1 }),
        tabOff   = Tip({ 0.05, 0.05, 0.05, 0.9 }, { 0.5, 0.5, 0.5, 1 }),
        field    = { bg = { 0, 0, 0, 0.55 }, border = { 0.35, 0.25, 0.15, 1 } },
    },
    deco = {
        gilt = false, ribbon = false, corners = false, spine = false, tape = false,
        pageShade = false, drop = false, folio = false, close = "blizzard", widgets = "blizzard",
        title = true, headerSpace = 10,
    },
}

Theme.THEMES = THEMES

------------------------------------------------------------------------
-- État courant (rempli par Theme.Apply)
------------------------------------------------------------------------
Theme.color = {}
Theme.deco = {}
Theme.font = {}
local c = Theme.color
local current

-- Ces polices n'ont que l'alphabet latin : en coréen, chinois ou russe,
-- on garde la police du jeu pour que les noms de zones et d'objets
-- s'affichent correctement.
local LATIN = { enUS = true, enGB = true, frFR = true, deDE = true, esES = true, esMX = true, itIT = true, ptBR = true }
local latin = LATIN[GetLocale()]

for role in pairs(FONT_ROLES) do
    Theme.font[role] = CreateFont("BubulleFont_" .. role)
end

local function Copy(target, source)
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

--- Applique un style (avant de construire les fenêtres).
function Theme.Apply(key)
    local theme = THEMES[key] or THEMES.carnet
    current = theme
    Theme.key = THEMES[key] and key or "carnet"

    for name, value in pairs(theme.color) do
        c[name] = { value[1], value[2], value[3], value[4] or 1 }
    end
    -- Texte des onglets : comme les boutons, sauf avis contraire du style
    c.tabText = c.tabText or c.inkSoft
    c.tabTextOn = c.tabTextOn or c.gold
    Copy(Theme.deco, theme.deco)
    Theme.ACCENT_HEX = theme.hex.accent
    Theme.WATER_HEX = theme.hex.water
    Theme.FAINT_HEX = theme.hex.faint

    local shadow = theme.fontShadow
    for role, spec in pairs(FONT_ROLES) do
        local file = theme.fonts[spec[1]]
        if not latin and file ~= GAME_FONT then file = GAME_FONT end
        local font = Theme.font[role]
        font:SetFont(file, theme.sizes[role], spec[3] or "")
        local col = c[spec[2]]
        font:SetTextColor(col[1], col[2], col[3], col[4] or 1)
        font:SetShadowColor(shadow[1], shadow[2], shadow[3], shadow[4])
        font:SetShadowOffset(1, -1)
    end
end

--- Le style choisi dans les réglages (appliqué une fois pour toutes).
ns:Listen("DB_READY", function()
    Theme.Apply(ns.db.settings.theme)
end)
Theme.Apply("carnet") -- valeurs par défaut, le temps de lire les réglages

------------------------------------------------------------------------
-- Couleurs de qualité d'objet, adaptées au fond du style
------------------------------------------------------------------------
function ns.QualityRGB(quality)
    quality = quality or 1
    if quality == 1 then return c.ink[1], c.ink[2], c.ink[3] end
    local q = current.quality[quality] or current.quality[0]
    if quality > 5 then q = current.quality[5] end
    return q[1], q[2], q[3]
end

function ns.QualityHex(quality)
    local r, g, b = ns.QualityRGB(quality)
    return ("|cff%02x%02x%02x"):format(r * 255, g * 255, b * 255)
end

------------------------------------------------------------------------
-- Petits outils de dessin
------------------------------------------------------------------------

--- Une couleur du thème en code hexadécimal ("rrggbb"), pour |cff...|r.
function Theme.Hex(color)
    return ("%02x%02x%02x"):format(color[1] * 255, color[2] * 255, color[3] * 255)
end

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

--- Habille un cadre selon son rôle ("window", "page", "card", "toast",
--- "tabOn", "tabOff", "field") et le style choisi. themeKey permet
--- d'utiliser un autre style (aperçus de l'onglet Style).
function Theme.Surface(frame, kind, themeKey)
    local theme = themeKey and THEMES[themeKey] or current
    local palette = themeKey and theme.color or c
    local s = theme.surface[kind] or theme.surface.page

    -- Image du jeu étirée sur tout le cadre (pages du grimoire)
    if s.atlas then
        frame:SetBackdrop(nil)
        if not frame.surfaceArt then
            frame.surfaceArt = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
            frame.surfaceArt:SetAllPoints()
        end
        frame.surfaceArt:SetAtlas(s.atlas)
        return
    end
    -- Cadre de métal du jeu (bordure en 9 morceaux) sur fond de roche
    if s.panel then
        frame:SetBackdrop(nil)
        if not frame.surfaceArt then
            frame.surfaceArt = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
            frame.surfaceArt:SetPoint("TOPLEFT", 2, -2)
            frame.surfaceArt:SetPoint("BOTTOMRIGHT", -2, 2)
            frame.surfaceArt:SetTexture(s.bgFile, "REPEAT", "REPEAT")
            frame.surfaceArt:SetHorizTile(true)
            frame.surfaceArt:SetVertTile(true)
            if NineSliceUtil then
                local border = CreateFrame("Frame", nil, frame, "NineSlicePanelTemplate")
                border:SetAllPoints()
                -- Juste au-dessus du fond : le titre et la croix restent visibles
                border:SetFrameLevel(frame:GetFrameLevel() + 1)
                NineSliceUtil.ApplyLayoutByName(border, s.panel)
                frame.surfaceBorder = border
            end
        end
        return
    end

    local inset = s.inset or 0
    frame:SetBackdrop({
        bgFile = s.bgFile or Theme.WHITE,
        edgeFile = s.edgeFile or Theme.WHITE,
        edgeSize = s.edgeSize or 1,
        tile = s.tile, tileSize = s.tile and (s.edgeSize or 16) or nil,
        insets = { left = inset, right = inset, top = inset, bottom = inset },
    })
    local function Resolve(color, fallback)
        if type(color) == "string" then color = palette[color] end
        return color or fallback
    end
    local bg = Resolve(s.bg, s.bgFile and { 1, 1, 1, 1 } or palette.pageDk)
    local border = Resolve(s.border, palette.goldDk)
    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
end

--- Police d'un style, pour écrire un aperçu ("title", "text"...).
function Theme.FontFile(themeKey, family)
    local file = THEMES[themeKey].fonts[family]
    if not latin then file = GAME_FONT end
    return file, THEMES[themeKey].sizes
end

--- Épaisseur de la bordure d'un rôle (pour placer un liseré à l'intérieur).
function Theme.Inset(kind)
    local s = current.surface[kind] or current.surface.page
    return math.max(1, s.inset or 0)
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
