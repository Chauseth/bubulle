--[[
    Bubulle - UI/Settings.lua
    ------------------------------------------------------------------
    Ajoute une page "Bubulle" dans Options > AddOns du jeu, avec un
    bouton qui ouvre la fenêtre de l'addon. Comme ça, on retrouve
    Bubulle au même endroit que les autres addons.
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets

ns:Listen("LOGIN", function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end

    local panel = CreateFrame("Frame")

    local portrait = panel:CreateTexture(nil, "ARTWORK")
    portrait:SetSize(64, 64)
    portrait:SetPoint("TOPLEFT", 16, -16)
    portrait:SetMask("Interface\\CharacterFrame\\TempPortraitAlphaMask")

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
    title:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 14, -8)
    title:SetText("|cff" .. Theme.ACCENT_HEX .. "Bubulle|r")

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
    desc:SetJustifyH("LEFT")
    desc:SetText(L.SETTINGS_DESC)

    local open = W.Button(panel, L.SETTINGS_OPEN, 220, 30, "primary")
    open:SetPoint("TOPLEFT", portrait, "BOTTOMLEFT", 0, -20)
    open:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        ns.Window:Open("options")
    end)

    panel:SetScript("OnShow", function()
        ns.Mascot:SetPortrait(portrait)
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "Bubulle")
    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end)
