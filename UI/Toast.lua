--[[
    Bubulle - UI/Toast.lua
    ------------------------------------------------------------------
    Petites notifications en haut de l'écran pour les grands moments :
    nouvelle espèce découverte ou prise rare. Elles s'enchaînent si
    plusieurs arrivent en même temps.
]]

local _, ns = ...
local L = ns.L
local Theme = ns.Theme
local W = ns.Widgets
local c = Theme.color

local Toast = {}
ns.Toast = Toast

local HOLD_TIME = 4
local queue = {}
local frame
local busy = false

local function Build()
    frame = CreateFrame("Frame", "BubulleToast", UIParent, "BackdropTemplate")
    frame:SetSize(340, 66)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    frame:SetFrameStrata("HIGH")
    Theme.Backdrop(frame, nil, { c.goldDk[1], c.goldDk[2], c.goldDk[3], 0.8 }, Theme.tex.page)
    frame:Hide()
    W.AttachFader(frame, 0.25)

    -- Liseré orange "poisson rouge" sur le bord gauche
    local stripe = frame:CreateTexture(nil, "ARTWORK")
    stripe:SetPoint("TOPLEFT", 1, -1)
    stripe:SetPoint("BOTTOMLEFT", 1, 1)
    stripe:SetWidth(4)
    Theme.Fill(stripe, c.fish)

    local drop = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    drop:SetPoint("TOPLEFT", -2, 1)
    drop:SetPoint("BOTTOMRIGHT", 4, -5)
    drop:SetColorTexture(0, 0, 0, 0.4)

    -- Bubulle dans sa bulle
    frame.portrait = frame:CreateTexture(nil, "ARTWORK")
    frame.portrait:SetSize(48, 48)
    frame.portrait:SetPoint("LEFT", 12, 0)

    frame.title = W.Text(frame, Theme.font.kicker)
    frame.title:SetPoint("TOPLEFT", 72, -14)
    frame.title:SetPoint("RIGHT", -52, 0)

    frame.text = W.Text(frame, Theme.font.bold)
    frame.text:SetPoint("BOTTOMLEFT", 72, 14)
    frame.text:SetPoint("RIGHT", -52, 0)

    frame.item = W.ItemIcon(frame, 34)
    frame.item:SetPoint("RIGHT", -12, 0)

    -- Clic : ouvre le carnet
    frame:EnableMouse(true)
    frame:SetScript("OnMouseUp", function()
        ns.Window:Open("journal")
    end)
end

local ShowNext

ShowNext = function()
    local data = table.remove(queue, 1)
    if not data then
        busy = false
        return
    end
    busy = true
    if not frame then Build() end

    ns.Mascot:SetPortrait(frame.portrait)
    frame.title:SetText(data.title)
    frame.text:SetText(data.text)
    frame.item:SetItem(data.itemID, data.icon, data.quality, data.qty)
    frame:FadeTo(true)
    if data.sound and ns.db.settings.alertSound then
        ns.PlayUISound(data.sound, "Master")
    end

    C_Timer.After(HOLD_TIME, function()
        frame:FadeTo(false)
        C_Timer.After(0.4, ShowNext)
    end)
end

function Toast:Push(data)
    queue[#queue + 1] = data
    if not busy then
        ShowNext()
    end
end

ns:Listen("CATCH", function(catches)
    local s = ns.db.settings
    for _, entry in ipairs(catches) do
        local name = ns.QualityHex(entry.quality) .. (entry.name or ns.Journal:GetItemName(entry.id)) .. "|r"
        if entry.isNew and s.newSpeciesAlert then
            Toast:Push({
                title = L.TOAST_NEW, text = name, itemID = entry.id, icon = entry.icon,
                quality = entry.quality, qty = entry.qty, sound = "UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST",
            })
        elseif entry.quality >= 3 and s.rareAlert then
            Toast:Push({
                title = L.TOAST_RARE, text = name, itemID = entry.id, icon = entry.icon,
                quality = entry.quality, qty = entry.qty, sound = "UI_EPICLOOT_TOAST",
            })
        end
    end
end)
