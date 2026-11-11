--[[
    Bubulle - Core.lua
    ------------------------------------------------------------------
    Le "cœur" de l'addon :
      * crée l'espace de noms partagé entre tous les fichiers (ns) ;
      * charge / initialise les données sauvegardées (BubulleDB) ;
      * fournit un petit système d'événements (WoW -> addon) et de
        messages internes (addon -> addon) ;
      * déclare les commandes /bubulle et l'entrée du menu des addons
        (le petit bouton sous la minicarte).

    Astuce débutant : chaque fichier listé dans le .toc reçoit deux
    valeurs grâce à "..." : le nom de l'addon et une table partagée.
    C'est la façon propre de partager du code sans polluer les
    variables globales du jeu.
]]

local ADDON_NAME, ns = ...
local L = ns.L

ns.name = ADDON_NAME
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1.0.0"

------------------------------------------------------------------------
-- Valeurs par défaut des réglages et des données
------------------------------------------------------------------------
ns.defaults = {
    settings = {
        -- Lancer
        doubleClick       = true,   -- double-clic droit pour lancer
        doubleClickAlways = false,  -- actif même hors "mode pêche"
        doubleClickDelay  = 0.40,   -- secondes entre les deux clics
        oneKey            = false,  -- touche de pêche (ex. "F"), false = aucune
        oneKeyAlways      = true,   -- la touche marche aussi hors du mode pêche
        -- Son
        sound             = true,   -- mettre en avant le bruit du bouchon
        sfxVolume         = 1.0,
        muteMusic         = true,
        muteAmbience      = true,
        soundInBackground = true,
        -- Comportement
        autoLoot          = true,
        idleTimeout       = 0,      -- secondes avant de quitter le mode pêche (0 = jamais)
        -- Affichage
        hudAuto           = true,
        hudAlways         = false,
        hudLocked         = false,
        hudScale          = 1.0,
        minimapButton     = true,   -- bouton rond au bord de la minicarte
        minimapAngle      = 215,    -- sa position (en degrés)
        -- Bubulle
        talk              = true,   -- Bubulle commente ta pêche
        -- Alertes
        newSpeciesAlert   = true,
        rareAlert         = true,
        alertSound        = true,
        -- Carnet
        journalAllChars   = false,  -- afficher les prises de tous les personnages
    },
    chars     = {},   -- le carnet de chaque personnage ["Nom-Royaume"] (voir Journal.lua)
    items     = {},   -- mémoire des objets [itemID] = { n = nom, q = qualité, i = icône }
    welcomed  = false, -- l'écran d'accueil a déjà été vu
    positions = {},   -- positions des fenêtres déplaçables
    savedCVars = nil, -- réglages du jeu modifiés pendant la pêche (pour les rétablir)
}

-- Copie les valeurs par défaut manquantes dans "target" (récursif).
local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            ApplyDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

------------------------------------------------------------------------
-- Événements du jeu
------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local eventHandlers = {}

--- Abonne une fonction à un événement WoW (ex. "LOOT_READY").
function ns:RegisterEvent(event, handler)
    local list = eventHandlers[event]
    if not list then
        list = {}
        eventHandlers[event] = list
        eventFrame:RegisterEvent(event)
    end
    list[#list + 1] = handler
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = eventHandlers[event]
    if not list then return end
    for i = 1, #list do
        list[i](event, ...)
    end
end)

------------------------------------------------------------------------
-- Messages internes (ex. "CATCH", "MODE_CHANGED")
------------------------------------------------------------------------
local listeners = {}

function ns:Listen(message, handler)
    listeners[message] = listeners[message] or {}
    table.insert(listeners[message], handler)
end

function ns:Fire(message, ...)
    local list = listeners[message]
    if not list then return end
    -- Si un abonné plante, les suivants sont quand même prévenus (sinon une
    -- seule erreur empêchait par exemple la fenêtre de se mettre à jour).
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then
            local handler = geterrorhandler and geterrorhandler()
            if handler then handler(err) else print(err) end
        end
    end
end

------------------------------------------------------------------------
-- Petits outils
------------------------------------------------------------------------
local PREFIX = "|cfff4a33aBubulle|r "

function ns.Print(text, ...)
    if select("#", ...) > 0 then
        text = text:format(...)
    end
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. text)
end

--- 75 -> "1:15", 3725 -> "1:02:05"
function ns.FormatClock(seconds)
    seconds = math.floor(seconds or 0)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return ("%d:%02d:%02d"):format(h, m, s)
    end
    return ("%d:%02d"):format(m, s)
end

--- Joue un son de l'interface s'il existe dans cette version du jeu.
function ns.PlayUISound(kitName, channel)
    local id = SOUNDKIT and SOUNDKIT[kitName]
    if id then
        PlaySound(id, channel or "SFX")
    end
end

--- Couleur hexadécimale d'une qualité d'objet (gris, blanc, vert, bleu...).
function ns.QualityHex(quality)
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    if color and color.hex then
        return color.hex
    end
    return "|cffffffff"
end

function ns.QualityRGB(quality)
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

------------------------------------------------------------------------
-- Chargement
------------------------------------------------------------------------
ns:RegisterEvent("ADDON_LOADED", function(_, loadedName)
    if loadedName ~= ADDON_NAME then return end

    BubulleDB = BubulleDB or {}
    ApplyDefaults(BubulleDB, ns.defaults)
    ns.db = BubulleDB

    -- Mises à jour des réglages d'anciennes versions
    if (BubulleDB.schema or 1) < 2 then
        BubulleDB.settings.idleTimeout = 0 -- plus d'arrêt automatique par défaut
    end
    BubulleDB.mascot = nil -- ancien réglage de l'apparence, retiré
    BubulleDB.schema = 2

    ns:Fire("DB_READY")
end)

ns:RegisterEvent("PLAYER_LOGIN", function()
    ns:Fire("LOGIN")
end)

------------------------------------------------------------------------
-- Remise à zéro (boutons de l'onglet Réglages)
------------------------------------------------------------------------

--- Remet tous les réglages par défaut. La touche de pêche est effacée
-- (aussi dans le menu Raccourcis du jeu) et l'écran d'accueil revient.
-- Le carnet de pêche, lui, est conservé.
function ns:ResetSettings()
    if InCombatLockdown() then
        ns.Print(L.ERR_COMBAT)
        return
    end
    -- Quitter le mode pêche d'abord : les réglages de son sont rétablis.
    if ns.Fishing.active then
        ns.Fishing:SetActive(false)
    end
    local db = ns.db
    wipe(db.settings)
    ApplyDefaults(db.settings, ns.defaults.settings)
    wipe(db.positions)
    db.welcomed = false
    ns.Fishing:SetKey(false)
    ns.HUD:ApplySettings()
    ns:Fire("SETTINGS_CHANGED")
    ns.Print(L.RESET_SETTINGS_DONE)
    ns.Window:ShowWelcome()
end

--- Efface tout le carnet : prises, zones, statistiques et la mémoire des
-- objets (noms, icônes). Les réglages ne changent pas.
function ns:ClearJournal()
    -- On efface ce qui est affiché : ce personnage, ou tous si l'option
    -- "tous mes personnages" est cochée.
    local all = ns.db.settings.journalAllChars
    ns.Journal:Clear(all)
    ns.Journal:ResetSession()
    ns.Print(all and L.JOURNAL_CLEARED_ALL or L.JOURNAL_CLEARED)
end

-- Fenêtres de confirmation (le jeu les affiche au milieu de l'écran).
local function Confirm(key, text, onAccept)
    if not StaticPopupDialogs or not StaticPopup_Show then
        onAccept()
        return
    end
    StaticPopupDialogs[key] = {
        text = text,
        button1 = YES or "Yes",
        button2 = CANCEL or "Cancel",
        OnAccept = onAccept,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
        preferredIndex = 3,
    }
    StaticPopup_Show(key)
end

function ns:AskResetSettings()
    Confirm("BUBULLE_RESET_SETTINGS", L.CONFIRM_RESET_SETTINGS, function() ns:ResetSettings() end)
end

function ns:AskClearJournal()
    local text = ns.db.settings.journalAllChars and L.CONFIRM_CLEAR_JOURNAL_ALL or L.CONFIRM_CLEAR_JOURNAL
    Confirm("BUBULLE_CLEAR_JOURNAL", text, function() ns:ClearJournal() end)
end

------------------------------------------------------------------------
-- Commandes : /bubulle
------------------------------------------------------------------------
SLASH_BUBULLE1 = "/bubulle"
SLASH_BUBULLE2 = "/bub"

local function ShowHelp()
    ns.Print(L.HELP_HEADER)
    print("  |cfff4a33a/bubulle|r - " .. L.HELP_TOGGLE)
    print("  |cfff4a33a/bubulle peche|r - " .. L.HELP_FISH)
    print("  |cfff4a33a/bubulle hud|r - " .. L.HELP_HUD)
    print("  |cfff4a33a/bubulle options|r - " .. L.HELP_OPTIONS)
    print("  |cfff4a33a/bubulle session|r - " .. L.HELP_SESSION)
    print("  |cfff4a33a/bubulle minimap|r - " .. L.HELP_MINIMAP)
end

SlashCmdList.BUBULLE = function(input)
    local cmd = strtrim((input or ""):lower())
    if cmd == "" then
        ns.Window:Toggle()
    elseif cmd == "peche" or cmd == "pêche" or cmd == "fish" then
        ns.Fishing:Toggle()
    elseif cmd == "hud" then
        ns.HUD:ToggleManual()
    elseif cmd == "options" or cmd == "config" then
        ns.Window:Open("options")
    elseif cmd == "minimap" or cmd == "minicarte" then
        ns.MinimapButton:Toggle()
    elseif cmd == "session" or cmd == "reset" then
        ns.Journal:ResetSession()
        ns.Print(L.SESSION_RESET_DONE)
    else
        ShowHelp()
    end
end

------------------------------------------------------------------------
-- Menu des addons (bouton sous la minicarte)
-- Ces trois fonctions sont nommées dans le .toc, elles doivent donc
-- être globales.
------------------------------------------------------------------------
function Bubulle_OnCompartmentClick(_, mouseButton)
    if mouseButton == "RightButton" then
        ns.Fishing:Toggle()
    else
        ns.Window:Toggle()
    end
end

function Bubulle_OnCompartmentEnter(_, menuButton)
    GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cfff4a33aBubulle|r")
    GameTooltip:AddLine(L.COMPARTMENT_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.COMPARTMENT_RIGHT, 1, 1, 1)
    GameTooltip:Show()
end

function Bubulle_OnCompartmentLeave()
    GameTooltip:Hide()
end
