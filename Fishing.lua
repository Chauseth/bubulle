--[[
    Bubulle - Fishing.lua
    ------------------------------------------------------------------
    Tout ce qui touche à l'action de pêcher :

    1. Le "mode pêche" : s'active tout seul dès que tu lances ta ligne
       (ou avec /bubulle peche). Pendant ce mode, l'addon améliore le son
       et active le double-clic. Il se désactive après un temps
       d'inactivité réglable.

    2. Le double-clic droit pour lancer.
       Un addon n'a PAS le droit de lancer un sort tout seul (Blizzard
       l'interdit pour éviter les bots). L'astuce autorisée : au moment
       du 2e clic, on redirige temporairement le bouton droit de la
       souris vers un bouton "sécurisé" qui lance Pêche. C'est donc
       bien TON clic qui lance le sort.

    3. La touche unique (optionnelle) : une seule touche pour lancer,
       puis pour ferrer (cliquer le bouchon) grâce à la touche
       "Interagir" du jeu.

    4. Le son : pendant la pêche on monte les effets sonores et on
       coupe musique/ambiance pour bien entendre le "plouf", puis on
       remet TES réglages exactement comme avant.
]]

local _, ns = ...
local L = ns.L

local Fishing = {}
ns.Fishing = Fishing

-- Identifiants connus du sort de pêche : version moderne (131474...) et
-- rangs "à l'ancienne" de WoW Forever / Classic (7620 Apprenti, 7731
-- Compagnon, 7732 Expert, 18248 Artisan).
local FISHING_IDS = {
    [131474] = true, [131476] = true, [131490] = true,
    [7620] = true, [7731] = true, [7732] = true, [18248] = true,
}
local FISHING_NAME_SOURCES = { 131474, 7620, 7731, 7732, 18248 }

-- Version du jeu : WoW Forever / Classic ont un numéro < 20000.
local TOC_VERSION = select(4, GetBuildInfo()) or 0
local OLD_SCHOOL = TOC_VERSION < 20000
local CAST_BUTTON_NAME = "BubulleCastButton"

Fishing.active = false      -- mode pêche
Fishing.channeling = false  -- bouchon à l'eau
Fishing.channelStart = 0
Fishing.channelEnd = 0

------------------------------------------------------------------------
-- Outils
------------------------------------------------------------------------

-- Depuis 12.0, certaines valeurs peuvent être "secrètes" pour les addons
-- (surtout en combat). On les ignore simplement.
local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local fishingName
local function GetFishingName()
    if not fishingName then
        for _, id in ipairs(FISHING_NAME_SOURCES) do
            fishingName = C_Spell.GetSpellName(id)
            if fishingName then break end
        end
    end
    return fishingName
end
Fishing.GetFishingName = GetFishingName

local function IsFishingSpell(spellID)
    if spellID == nil or IsSecret(spellID) then return false end
    if FISHING_IDS[spellID] then return true end
    local name = C_Spell.GetSpellName(spellID)
    return name ~= nil and name == GetFishingName()
end

------------------------------------------------------------------------
-- Le bouton sécurisé qui lance Pêche
------------------------------------------------------------------------
local castButton = CreateFrame("Button", CAST_BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
castButton:SetSize(1, 1)
castButton:SetPoint("BOTTOMLEFT", UIParent, "TOPRIGHT", 50, 50) -- hors écran
castButton:RegisterForClicks("AnyUp", "AnyDown")
castButton:SetAttribute("type", "spell")
-- Le sort est donné par son NOM ("Pêche") : le jeu lance alors le meilleur
-- rang connu, que ce soit sur Retail ou sur Forever. (Voir DB_READY.)
castButton:SetAttribute("spell", 7620)
-- Le sort part au RELÂCHEMENT du clic/de la touche : c'est ce qui permet
-- de rediriger le bouton droit pendant l'appui du 2e clic.
castButton:SetAttribute("useOnKeyDown", false)

-- Deux "propriétaires" de raccourcis temporaires, pour pouvoir les
-- retirer séparément.
local doubleClickOwner = CreateFrame("Frame")
local oneKeyOwner = CreateFrame("Frame")

local armedAt

function Fishing:ClearDoubleClick()
    armedAt = nil
    if InCombatLockdown() then return end
    ClearOverrideBindings(doubleClickOwner)
end

castButton:SetScript("PostClick", function(_, _, down)
    if not down then
        Fishing:ClearDoubleClick()
    end
end)

local function ArmDoubleClick()
    if InCombatLockdown() then return end
    SetOverrideBindingClick(doubleClickOwner, true, "BUTTON2", CAST_BUTTON_NAME)
    local token = GetTime()
    armedAt = token
    -- Sécurité : si le clic n'est jamais relâché, on rend le bouton droit.
    C_Timer.After(1.2, function()
        if armedAt == token then
            Fishing:ClearDoubleClick()
        end
    end)
end

------------------------------------------------------------------------
-- Détection du double-clic droit
------------------------------------------------------------------------
local function IsMouseOverWorld()
    if GetMouseFoci then
        local focus = GetMouseFoci()[1]
        return focus == nil or focus == WorldFrame
    end
    return true
end

function Fishing:CanDoubleClick()
    local s = ns.db.settings
    if not s.doubleClick then return false end
    if not (self.active or s.doubleClickAlways) then return false end
    if self.channeling then return false end           -- clic droit = ferrer le bouchon
    if InCombatLockdown() then return false end
    if IsModifierKeyDown() then return false end
    if IsFlying() then return false end
    if UnitExists("mouseover") then return false end    -- survol d'un PNJ / joueur
    if GetCursorInfo() then return false end            -- objet tenu par la souris
    if LootFrame and LootFrame:IsShown() then return false end
    return IsMouseOverWorld()
end

local lastRightDown = 0
local mouseWatcher = CreateFrame("Frame")
mouseWatcher:RegisterEvent("GLOBAL_MOUSE_DOWN")
mouseWatcher:SetScript("OnEvent", function(_, _, button)
    if button ~= "RightButton" or not ns.db then return end
    if not Fishing:CanDoubleClick() then
        lastRightDown = 0
        return
    end
    local now = GetTime()
    if now - lastRightDown <= ns.db.settings.doubleClickDelay then
        lastRightDown = 0
        ArmDoubleClick()
    else
        lastRightDown = now
    end
end)

------------------------------------------------------------------------
-- Touche unique : lancer, puis "Interagir" pour ferrer
------------------------------------------------------------------------
local keyDirty = false

function Fishing:UpdateOneKey()
    if InCombatLockdown() then
        keyDirty = true
        return
    end
    keyDirty = false
    ClearOverrideBindings(oneKeyOwner)

    local s = ns.db and ns.db.settings
    local key = s and s.oneKey
    if not key or not (self.active or s.oneKeyAlways) then return end

    if self.channeling then
        SetOverrideBinding(oneKeyOwner, true, key, "INTERACTTARGET")
    else
        SetOverrideBindingClick(oneKeyOwner, true, key, CAST_BUTTON_NAME)
    end
end

------------------------------------------------------------------------
-- Réglages du jeu modifiés pendant la pêche (son, butin auto...)
-- Les valeurs d'origine sont gardées dans BubulleDB.savedCVars : même
-- après un plantage, elles sont rétablies à la connexion suivante.
------------------------------------------------------------------------
local function WantedCVars()
    local s = ns.db.settings
    local wanted = {}
    if s.sound then
        wanted.Sound_EnableAllSound = "1"
        wanted.Sound_EnableSFX = "1"
        wanted.Sound_SFXVolume = ("%.2f"):format(s.sfxVolume)
        if s.muteMusic then wanted.Sound_MusicVolume = "0" end
        if s.muteAmbience then wanted.Sound_AmbienceVolume = "0" end
        if s.soundInBackground then wanted.Sound_EnableSoundWhenGameIsInBG = "1" end
    end
    if s.autoLoot then
        wanted.autoLootDefault = "1"
    end
    if s.oneKey then
        -- Permet à la touche "Interagir" de viser le bouchon.
        local any = Enum.SoftTargetEnableFlags and Enum.SoftTargetEnableFlags.Any or 3
        wanted.SoftTargetInteract = tostring(any)
        wanted.SoftTargetInteractRange = "30"
    end
    return wanted
end

function Fishing:ApplyCVars()
    local db = ns.db
    db.savedCVars = db.savedCVars or {}
    for cvar, value in pairs(WantedCVars()) do
        local current = C_CVar.GetCVar(cvar)
        if current ~= nil then -- le réglage existe dans cette version
            if db.savedCVars[cvar] == nil then
                db.savedCVars[cvar] = current
            end
            if current ~= value then
                C_CVar.SetCVar(cvar, value)
            end
        end
    end
end

function Fishing:RestoreCVars(keepCopy)
    local db = ns.db
    if not db or not db.savedCVars then return end
    for cvar, value in pairs(db.savedCVars) do
        C_CVar.SetCVar(cvar, value)
    end
    if not keepCopy then
        db.savedCVars = nil
    end
end

--- À appeler quand un réglage change pendant le mode pêche.
function Fishing:RefreshSettings()
    if self.active then
        self:RestoreCVars()
        self:ApplyCVars()
    end
    self:UpdateOneKey()
end

------------------------------------------------------------------------
-- Mode pêche
------------------------------------------------------------------------
local ticker
local lastTick

local function OnTick()
    local now = GetTime()
    ns.Journal:AddFishingTime(now - lastTick)
    lastTick = now

    local timeout = ns.db.settings.idleTimeout
    if timeout > 0 and not Fishing.channeling and now - Fishing.lastActivity > timeout then
        Fishing:SetActive(false)
        ns.Print(L.MODE_AUTO_OFF)
    end
end

function Fishing:SetActive(active)
    active = active and true or false
    if active == self.active then return end
    if active and InCombatLockdown() then
        ns.Print(L.ERR_COMBAT)
        return
    end

    self.active = active
    if active then
        self.lastActivity = GetTime()
        lastTick = GetTime()
        ticker = C_Timer.NewTicker(1, OnTick)
        self:ApplyCVars()
    else
        if ticker then
            ticker:Cancel()
            ticker = nil
        end
        self:RestoreCVars()
        self:ClearDoubleClick()
    end
    self:UpdateOneKey()
    ns:Fire("MODE_CHANGED", active)
end

function Fishing:Toggle()
    self:SetActive(not self.active)
end

--- Temps restant avant que le bouchon ne disparaisse (secondes).
function Fishing:GetChannelProgress()
    if not self.channeling then return nil end
    local now = GetTime()
    local total = self.channelEnd - self.channelStart
    if total <= 0 then return nil end
    return math.max(0, self.channelEnd - now), total
end

--- Texte d'aide : comment lancer avec les réglages actuels.
function Fishing:GetCastHint()
    local s = ns.db.settings
    if s.oneKey then
        return L.HINT_KEY:format(GetBindingText(s.oneKey))
    elseif s.doubleClick then
        return L.HINT_DOUBLECLICK
    end
    return L.HINT_MANUAL
end

------------------------------------------------------------------------
-- Équipement (WoW Forever / Classic : canne en main, appâts, compétence)
------------------------------------------------------------------------
Fishing.OLD_SCHOOL = OLD_SCHOOL

--- Faut-il une canne à pêche en main pour pêcher ? (Forever / Classic)
function Fishing:NeedsPole()
    return OLD_SCHOOL
end

local FISHING_POLE_SUBCLASS = (Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole) or 20

function Fishing:HasPole()
    local itemID = GetInventoryItemID("player", 16) -- main droite
    if not itemID then return false end
    local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    return classID == 2 and subclassID == FISHING_POLE_SUBCLASS
end

--- Minutes d'appât restantes sur la canne (nil = pas d'appât / sans objet).
function Fishing:GetLureMinutes()
    if not OLD_SCHOOL or not GetWeaponEnchantInfo then return nil end
    local hasEnchant, expirationMs = GetWeaponEnchantInfo()
    if hasEnchant and expirationMs then
        return math.ceil(expirationMs / 60000)
    end
    return nil
end

--- Compétence de pêche : niveau réel, bonus (appât, objets...), maximum.
-- Renvoie nil si inconnue.
function Fishing:GetSkill()
    local name = GetFishingName()
    if GetNumSkillLines and GetSkillLineInfo and name then
        for i = 1, GetNumSkillLines() do
            local skillName, isHeader, _, rank, _, modifier, maxRank = GetSkillLineInfo(i)
            if not isHeader and skillName == name then
                return rank, modifier or 0, maxRank
            end
        end
    end
    if GetProfessions and GetProfessionInfo then
        local _, _, _, fishing = GetProfessions()
        if fishing then
            local _, _, rank, maxRank, _, _, _, modifier = GetProfessionInfo(fishing)
            if rank then
                return rank, modifier or 0, maxRank
            end
        end
    end
    return nil
end

------------------------------------------------------------------------
-- Suivi de la canalisation (le bouchon est à l'eau)
------------------------------------------------------------------------
local castWatcher = CreateFrame("Frame")
castWatcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
castWatcher:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
castWatcher:SetScript("OnEvent", function(_, event, _, _, spellID)
    if not ns.db then return end

    if event == "UNIT_SPELLCAST_CHANNEL_START" then
        if not IsFishingSpell(spellID) then return end

        local _, _, _, startMs, endMs = UnitChannelInfo("player")
        if startMs and endMs and not IsSecret(startMs) and not IsSecret(endMs) then
            Fishing.channelStart = startMs / 1000
            Fishing.channelEnd = endMs / 1000
        else
            Fishing.channelStart = GetTime()
            Fishing.channelEnd = GetTime() + 20
        end

        Fishing.channeling = true
        Fishing.lastActivity = GetTime()
        if not Fishing.active then
            Fishing:SetActive(true) -- 1er lancer manuel : on passe en mode pêche
        end
        ns.Journal:AddCast()
        Fishing:UpdateOneKey()
        ns:Fire("CHANNEL_START")

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if not Fishing.channeling then return end
        Fishing.channeling = false
        Fishing.lastActivity = GetTime()
        ns:Fire("CHANNEL_STOP")
        -- Petit délai : évite que le relâchement de la touche unique
        -- (qui vient de ferrer) ne relance aussitôt la ligne.
        C_Timer.After(0.5, function()
            if not Fishing.channeling then
                Fishing:UpdateOneKey()
            end
        end)
    end
end)

------------------------------------------------------------------------
-- Combat, connexion, déconnexion
------------------------------------------------------------------------
ns:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    -- Dernier instant où l'on peut encore modifier les raccourcis.
    ClearOverrideBindings(doubleClickOwner)
    ClearOverrideBindings(oneKeyOwner)
    armedAt = nil
end)

ns:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    if keyDirty or Fishing.active then
        Fishing:UpdateOneKey()
    end
end)

ns:Listen("DB_READY", function()
    local name = GetFishingName()
    if name then
        castButton:SetAttribute("spell", name)
    end

    -- Des réglages sont restés modifiés (plantage, /reload en pêchant) :
    -- on les rétablit.
    if ns.db.savedCVars then
        Fishing:RestoreCVars()
    end
end)

ns:Listen("LOGIN", function()
    -- La touche de pêche peut être active dès la connexion.
    Fishing:UpdateOneKey()
end)

ns:RegisterEvent("PLAYER_LOGOUT", function()
    -- On rend au joueur ses réglages de son avant de quitter / recharger.
    -- On garde une copie : elle sera réappliquée à la prochaine connexion,
    -- par sécurité.
    if Fishing.active then
        Fishing:RestoreCVars(true)
    end
end)
