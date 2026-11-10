--[[
    Bubulle - Journal.lua
    ------------------------------------------------------------------
    Le carnet de pêche : enregistre chaque prise (objet, quantité,
    zone) et tient les statistiques de la session en cours.

    Comment sait-on qu'une prise vient de la pêche ?
    Quand la fenêtre de butin s'ouvre, le jeu déclenche l'événement
    LOOT_READY, et la fonction IsFishingLoot() répond "vrai" si ce
    butin vient d'un bouchon. On lit alors chaque emplacement de butin.
]]

local _, ns = ...

local Journal = {}
ns.Journal = Journal

local HISTORY_MAX = 100
local RECENT_MAX  = 6

-- Session : remise à zéro à chaque connexion (ou à la demande).
local session = {
    seconds = 0,   -- temps passé en mode pêche
    casts   = 0,   -- lancers
    catches = 0,   -- prises (une fenêtre de butin = une prise)
    items   = {},  -- [itemID] = quantité
    recent  = {},  -- dernières prises { id, qty } (la plus récente en premier)
}
ns.session = session

function Journal:ResetSession()
    session.seconds = 0
    session.casts = 0
    session.catches = 0
    wipe(session.items)
    wipe(session.recent)
    ns:Fire("SESSION_UPDATED")
end

function Journal:AddCast()
    session.casts = session.casts + 1
    ns.db.totals.casts = ns.db.totals.casts + 1
    ns:Fire("SESSION_UPDATED")
end

function Journal:AddFishingTime(seconds)
    session.seconds = session.seconds + seconds
    ns.db.totals.seconds = ns.db.totals.seconds + seconds
end

--- Prises par heure pendant la session (nil si trop tôt pour être parlant).
function Journal:CatchesPerHour()
    if session.seconds < 60 then return nil end
    return session.catches / (session.seconds / 3600)
end

--- Taux de réussite : prises / lancers (nil si aucun lancer).
function Journal:SuccessRate()
    if session.casts == 0 then return nil end
    return math.min(1, session.catches / session.casts)
end

------------------------------------------------------------------------
-- Lieu actuel
------------------------------------------------------------------------
function Journal:GetLocation()
    local mapID = C_Map.GetBestMapForUnit("player")
    local zoneName
    if mapID then
        local info = C_Map.GetMapInfo(mapID)
        zoneName = info and info.name
    end
    zoneName = zoneName or GetZoneText() or UNKNOWN
    local subZone = GetSubZoneText()
    if subZone == "" or subZone == zoneName then
        subZone = nil
    end
    return mapID or 0, zoneName, subZone
end

------------------------------------------------------------------------
-- Infos d'objet (on garde une copie : le cache du jeu n'a pas toujours
-- le nom d'un objet sous la main)
------------------------------------------------------------------------
function Journal:GetItem(itemID)
    local info = ns.db.items[itemID]
    if info and not info.n then
        info.n = C_Item.GetItemNameByID(itemID)
    end
    return info
end

function Journal:GetItemName(itemID)
    local info = self:GetItem(itemID)
    return (info and info.n) or C_Item.GetItemNameByID(itemID) or ("#" .. itemID)
end

------------------------------------------------------------------------
-- Enregistrement d'une prise
------------------------------------------------------------------------
local function RecordItem(itemID, name, quality, icon, quantity, mapID, zoneName)
    local db = ns.db

    local info = db.items[itemID]
    local isNew = info == nil
    if isNew then
        info = { c = 0 }
        db.items[itemID] = info
    end
    info.n = name or info.n
    info.q = quality or info.q
    info.i = icon or info.i
    info.c = info.c + quantity

    local zone = db.zones[mapID]
    if not zone then
        zone = { name = zoneName, catches = 0, total = 0, fish = {} }
        db.zones[mapID] = zone
    end
    zone.name = zoneName or zone.name
    zone.total = zone.total + quantity
    zone.fish[itemID] = (zone.fish[itemID] or 0) + quantity
    zone.last = time()

    session.items[itemID] = (session.items[itemID] or 0) + quantity
    table.insert(session.recent, 1, { id = itemID, qty = quantity })
    while #session.recent > RECENT_MAX do
        table.remove(session.recent)
    end

    table.insert(db.history, 1, { id = itemID, qty = quantity, t = time(), m = mapID })
    while #db.history > HISTORY_MAX do
        table.remove(db.history)
    end

    return isNew
end

------------------------------------------------------------------------
-- Détection des prises : deux méthodes complémentaires
--
--  1) La fenêtre de butin (LOOT_READY) + IsFishingLoot() : précis, on lit
--     chaque objet du bouchon.
--  2) Filet de sécurité : le message "Vous recevez le butin : ..." dans
--     les secondes qui suivent la fin de la pêche. Utile quand un autre
--     addon (ou le butin automatique) vide la fenêtre avant nous.
--
--  Une même remontée de ligne n'est comptée qu'une fois.
------------------------------------------------------------------------
local FISHING_WINDOW = 4  -- secondes après la fin du bouchon
local lootHandled = false -- fenêtre de butin déjà lue
local castCounted = true  -- la prise de ce lancer est déjà comptée
local expectUntil = 0     -- on attend du butin de pêche jusqu'à ce moment
local slotsReadUntil = 0  -- la méthode 1 a déjà tout lu : ignorer les messages

local function InFishingWindow()
    return ns.Fishing.channeling or GetTime() < expectUntil
end

--- Enregistre une liste d'objets pêchés { id, name, quality, icon, qty }.
local function RecordCatch(items)
    if #items == 0 then return end
    local mapID, zoneName = Journal:GetLocation()
    for _, entry in ipairs(items) do
        entry.isNew = RecordItem(entry.id, entry.name, entry.quality, entry.icon, entry.qty, mapID, zoneName)
    end

    -- Une remontée de ligne = une prise, même avec plusieurs objets.
    if not castCounted then
        castCounted = true
        session.catches = session.catches + 1
        ns.db.totals.catches = ns.db.totals.catches + 1
        local zone = ns.db.zones[mapID]
        if zone then
            zone.catches = (zone.catches or 0) + 1
        end
    end

    ns:Fire("CATCH", items)
    ns:Fire("SESSION_UPDATED")
end

-- Méthode 1 : la fenêtre de butin
local function OnLoot()
    if lootHandled or not ns.db then return end
    if not (IsFishingLoot() or InFishingWindow()) then return end

    local items = {}
    for slot = 1, GetNumLootItems() do
        if GetLootSlotType(slot) == Enum.LootSlotType.Item then
            local link = GetLootSlotLink(slot)
            local icon, name, quantity, _, quality = GetLootSlotInfo(slot)
            local itemID = link and C_Item.GetItemInfoInstant(link)
            if itemID then
                items[#items + 1] = {
                    id = itemID, name = name, quality = quality or 1, icon = icon,
                    qty = (quantity and quantity > 0) and quantity or 1,
                }
            end
        end
    end
    if #items == 0 then return end -- fenêtre déjà vidée : la méthode 2 prendra le relais

    lootHandled = true
    slotsReadUntil = GetTime() + FISHING_WINDOW
    if IsFishingLoot() then
        castCounted = false -- une fenêtre de butin de pêche = une prise
    end
    RecordCatch(items)
end

ns:RegisterEvent("LOOT_READY", OnLoot)
ns:RegisterEvent("LOOT_OPENED", OnLoot)
ns:RegisterEvent("LOOT_CLOSED", function()
    lootHandled = false
end)

-- Méthode 2 : les messages de butin
ns:RegisterEvent("CHAT_MSG_LOOT", function(_, message, _, _, _, _, _, _, _, _, _, _, guid)
    if not ns.db or not InFishingWindow() or GetTime() < slotsReadUntil then return end
    if guid and guid ~= UnitGUID("player") then return end
    if type(message) ~= "string" or (issecretvalue and issecretvalue(message)) then return end

    local link = message:match("|Hitem:[^|]+|h%[[^%]]*%]|h")
    if not link then return end
    local itemID = C_Item.GetItemInfoInstant(link)
    if not itemID then return end

    local name = link:match("%[(.-)%]")
    local quality = C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(itemID) or 1
    local quantity = tonumber(message:match("|r%s*[xX×](%d+)")) or 1
    RecordCatch({ {
        id = itemID, name = name, quality = quality or 1,
        icon = C_Item.GetItemIconByID(itemID), qty = quantity,
    } })
end)

-- Début et fin du bouchon (envoyés par Fishing.lua)
ns:Listen("CHANNEL_START", function()
    castCounted = false
    expectUntil = 0
    slotsReadUntil = 0
end)

ns:Listen("CHANNEL_STOP", function()
    expectUntil = GetTime() + FISHING_WINDOW
end)

------------------------------------------------------------------------
-- Données triées pour l'interface
------------------------------------------------------------------------

--- Liste { id, count, pct } triée par quantité décroissante.
local function SortedFish(fishTable)
    local list, total = {}, 0
    for itemID, count in pairs(fishTable) do
        list[#list + 1] = { id = itemID, count = count }
        total = total + count
    end
    table.sort(list, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.id < b.id
    end)
    for _, entry in ipairs(list) do
        entry.pct = total > 0 and entry.count / total or 0
    end
    return list, total
end

function Journal:GetSessionFish()
    return SortedFish(session.items)
end

--- Toutes les zones, triées par nombre d'objets pêchés.
function Journal:GetZones()
    local list = {}
    for mapID, zone in pairs(ns.db.zones) do
        list[#list + 1] = {
            mapID = mapID, name = zone.name or UNKNOWN,
            total = zone.total or 0, catches = zone.catches or 0, last = zone.last,
        }
    end
    table.sort(list, function(a, b)
        if a.total ~= b.total then return a.total > b.total end
        return a.name < b.name
    end)
    return list
end

--- Poissons d'une zone (mapID) ou de toutes les zones (mapID = nil).
function Journal:GetZoneFish(mapID)
    if mapID then
        local zone = ns.db.zones[mapID]
        return SortedFish(zone and zone.fish or {})
    end
    local merged = {}
    for _, zone in pairs(ns.db.zones) do
        for itemID, count in pairs(zone.fish) do
            merged[itemID] = (merged[itemID] or 0) + count
        end
    end
    return SortedFish(merged)
end

function Journal:CountSpecies()
    local n = 0
    for _ in pairs(ns.db.items) do n = n + 1 end
    return n
end
