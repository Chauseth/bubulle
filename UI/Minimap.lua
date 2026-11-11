--[[
    Bubulle - UI/Minimap.lua
    ------------------------------------------------------------------
    Le petit bouton rond de Bubulle au bord de la minicarte.
      - clic gauche : ouvrir ou fermer la fenêtre
      - clic droit  : commencer ou arrêter le mode pêche
      - glisser     : le faire tourner autour de la minicarte

    Comment on le place ? On garde seulement un ANGLE (en degrés) dans
    les réglages. Avec un peu de trigonométrie (cosinus pour x, sinus
    pour y), on le pose sur le cercle qui entoure la minicarte.
]]

local _, ns = ...
local L = ns.L

local Minimap = _G.Minimap
local MinimapButton = {}
ns.MinimapButton = MinimapButton

local button

local function Settings()
    return ns.db.settings
end

--- Pose le bouton sur le bord de la minicarte, selon l'angle mémorisé.
local function UpdatePosition()
    local angle = math.rad(Settings().minimapAngle or 215)
    local radius = Minimap:GetWidth() / 2 + 5
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

--- Pendant qu'on glisse : l'angle suit la souris autour du centre.
local function FollowCursor()
    local centerX, centerY = Minimap:GetCenter()
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    Settings().minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX)) % 360
    UpdatePosition()
end

local function ShowTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff" .. ns.Theme.ACCENT_HEX .. "Bubulle|r")
    GameTooltip:AddLine(L.COMPARTMENT_LEFT, 1, 1, 1)
    GameTooltip:AddLine(L.COMPARTMENT_RIGHT, 1, 1, 1)
    GameTooltip:AddLine(L.MINIMAP_DRAG, 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function Create()
    button = CreateFrame("Button", "BubulleMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Les trois couches habituelles d'un bouton de minicarte :
    -- un fond sombre, l'image, et l'anneau doré par-dessus.
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 6, -5)
    button.icon = icon

    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetSize(53, 53)
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetPoint("TOPLEFT")

    button:SetScript("OnClick", function(_, mouseButton)
        GameTooltip:Hide()
        if mouseButton == "RightButton" then
            ns.Fishing:Toggle()
        else
            ns.Window:Toggle()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", FollowCursor)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnShow", function() MinimapButton:RefreshIcon() end)
end

--- L'image de Bubulle, découpée en rond.
function MinimapButton:RefreshIcon()
    if not button then return end
    ns.Mascot:SetPortrait(button.icon)
    if button.icon.SetMask and not button.iconMasked then
        button.icon:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        button.iconMasked = true
    end
end

--- Affiche ou cache le bouton selon les réglages.
function MinimapButton:Apply()
    if not Minimap then return end
    if Settings().minimapButton then
        if not button then Create() end
        UpdatePosition()
        button:Show()
        self:RefreshIcon()
    elseif button then
        button:Hide()
    end
end

function MinimapButton:Toggle()
    Settings().minimapButton = not Settings().minimapButton
    self:Apply()
    ns:Fire("SETTINGS_CHANGED")
end

ns:Listen("DB_READY", function() MinimapButton:Apply() end)
ns:Listen("SETTINGS_CHANGED", function() MinimapButton:Apply() end)
