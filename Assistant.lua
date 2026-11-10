--[[
    Bubulle - Assistant.lua
    ------------------------------------------------------------------
    La "personnalité" de Bubulle : ce qu'il dit, et quand.

    Chaque événement de pêche (début, lancer, prise, raté, nouvelle
    zone...) choisit une réplique au hasard dans une liste (voir
    Locales.lua). Une réplique importante (nouvelle espèce) n'est pas
    écrasée par une réplique banale ("je surveille le bouchon").
    Quand rien de spécial ne se passe, Bubulle rappelle comment lancer.
]]

local _, ns = ...
local L = ns.L

local Assistant = {}
ns.Assistant = Assistant

local PRIORITY_LOW, PRIORITY_NORMAL, PRIORITY_HIGH = 1, 2, 3
local MILESTONE_EVERY = 25

local current = { text = nil, untilTime = 0, priority = 0 }
local lastCatchTime = 0

local function Pick(list)
    if type(list) ~= "table" then return list end
    return list[math.random(#list)]
end

--- Fait parler Bubulle.
-- duration : secondes d'affichage ; hop : petit saut de joie
function Assistant:Say(text, duration, hop, priority)
    if not ns.db.settings.talk or not text then return end
    priority = priority or PRIORITY_NORMAL
    local now = GetTime()
    if current.text and now < current.untilTime and priority < current.priority then
        return -- une réplique plus importante est en cours
    end
    current.text = text
    current.untilTime = now + (duration or 7)
    current.priority = priority
    ns:Fire("ASSISTANT_SAY", text, hop)
end

--- Réplique à afficher maintenant.
function Assistant:GetLine()
    if current.text and GetTime() < current.untilTime then
        return current.text
    end
    current.text = nil
    return self:GetDefaultLine()
end

function Assistant:GetDefaultLine()
    local Fishing = ns.Fishing
    if not Fishing.active then
        return L.SAY_DEFAULT_OFF
    elseif Fishing.channeling then
        return L.SAY_DEFAULT_WATCHING
    end
    return Fishing:GetCastHint()
end

local function ColoredName(entry)
    return ns.QualityHex(entry.quality) .. (entry.name or ns.Journal:GetItemName(entry.id)) .. "|r"
end

------------------------------------------------------------------------
-- Réactions aux événements
------------------------------------------------------------------------
local lastLureWarning = 0

ns:Listen("MODE_CHANGED", function(active)
    if active then
        if ns.Fishing:NeedsPole() and not ns.Fishing:HasPole() then
            Assistant:Say(L.SAY_NO_POLE, 10, false, PRIORITY_HIGH)
        else
            Assistant:Say(Pick(L.SAY_HELLO), 6, true)
        end
    else
        Assistant:Say(Pick(L.SAY_BYE), 5, false, PRIORITY_HIGH)
    end
end)

ns:Listen("CHANNEL_START", function()
    -- Sur Forever / Classic, un petit rappel quand la canne n'a plus d'appât
    -- (au plus toutes les 10 minutes).
    local now = GetTime()
    if ns.Fishing.OLD_SCHOOL and not ns.Fishing:GetLureMinutes() and now - lastLureWarning > 600 then
        lastLureWarning = now
        Assistant:Say(L.SAY_NO_LURE, 6)
        return
    end
    Assistant:Say(Pick(L.SAY_WAIT), 4, false, PRIORITY_LOW)
end)

ns:Listen("CHANNEL_STOP", function()
    local stopTime = GetTime()
    C_Timer.After(1.5, function()
        -- Aucune prise juste avant/après l'arrêt : c'est raté.
        if math.abs(lastCatchTime - stopTime) > 2 and not ns.Fishing.channeling then
            Assistant:Say(Pick(L.SAY_MISS), 4, false, PRIORITY_LOW)
        end
    end)
end)

ns:Listen("CATCH", function(catches)
    lastCatchTime = GetTime()

    -- On commente l'objet le plus remarquable de la prise.
    local best
    for _, entry in ipairs(catches) do
        if not best
            or (entry.isNew and not best.isNew)
            or (entry.isNew == best.isNew and entry.quality > best.quality) then
            best = entry
        end
    end

    local total = ns.session.catches
    if best and best.isNew then
        Assistant:Say(L.SAY_NEW:format(ColoredName(best)), 8, true, PRIORITY_HIGH)
    elseif best and best.quality >= 3 then
        Assistant:Say(L.SAY_RARE:format(ColoredName(best)), 8, true, PRIORITY_HIGH)
    elseif total > 0 and total % MILESTONE_EVERY == 0 then
        Assistant:Say(L.SAY_MILESTONE:format(total), 7, true, PRIORITY_HIGH)
    elseif best then
        Assistant:Say(Pick(L.SAY_CATCH):format(ColoredName(best)), 5, true)
    end
end)

ns:RegisterEvent("ZONE_CHANGED_NEW_AREA", function()
    if not ns.Fishing.active then return end
    local mapID, zoneName = ns.Journal:GetLocation()
    local zone = ns.db.zones[mapID]
    if zone and (zone.catches or 0) > 0 then
        Assistant:Say(L.SAY_ZONE_KNOWN:format(zoneName, zone.catches), 7)
    else
        Assistant:Say(L.SAY_ZONE_NEW:format(zoneName), 7)
    end
end)
