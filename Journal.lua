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
    recent  = {},  -- dernières prises { id, qty, t } (la plus récente en premier)
    started = time(), -- heure de début de la session
}
ns.session = session

function Journal:ResetSession()
    session.seconds = 0
    session.casts = 0
    session.catches = 0
    session.started = time()
    wipe(session.items)
    wipe(session.recent)
    ns:Fire("SESSION_UPDATED")
end

------------------------------------------------------------------------
-- Un carnet par personnage
--   BubulleDB.chars["Nom-Royaume"] = {
--       zones   = { [mapID] = { name, catches, total, fish = { [itemID] = n }, last } },
--       totals  = { catches, casts, seconds },
--       history = { { id, qty, t, m }, ... }  (dernières prises)
--       species = { [itemID] = quantité totale },
--   }
-- Avec l'option "tous mes personnages", l'affichage additionne les carnets.
------------------------------------------------------------------------
local function NewCharData()
    return { zones = {}, totals = { catches = 0, casts = 0, seconds = 0 }, history = {}, species = {} }
end

local function Fill(data)
    local blank = NewCharData()
    for key, value in pairs(blank) do
        if type(data[key]) ~= "table" then data[key] = value end
    end
    for key, value in pairs(blank.totals) do
        data.totals[key] = data.totals[key] or value
    end
end

local char -- le carnet du personnage connecté

function Journal:CharKey()
    return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

--- Le carnet du personnage connecté.
function Journal:Char()
    return char
end

--- Les carnets à afficher (ce personnage, ou tous).
local function Sources()
    if ns.db.settings.journalAllChars then
        local list = {}
        for _, data in pairs(ns.db.chars) do list[#list + 1] = data end
        return list
    end
    return { char }
end

ns:Listen("DB_READY", function()
    local db = ns.db
    local key = Journal:CharKey()
    db.chars[key] = db.chars[key] or NewCharData()
    char = db.chars[key]
    Fill(char)

    -- Avant la 1.1, le carnet était commun à tout le compte : il revient
    -- au premier personnage qui se connecte avec la nouvelle version.
    if db.zones or db.totals or db.history then
        char.zones = db.zones or char.zones
        char.totals = db.totals or char.totals
        char.history = db.history or char.history
        for itemID, info in pairs(db.items) do
            if info.c then
                char.species[itemID] = (char.species[itemID] or 0) + info.c
                info.c = nil
            end
        end
        Fill(char)
        db.zones, db.totals, db.history = nil, nil, nil
    end
end)

--- Efface le carnet de ce personnage (ou de tous).
function Journal:Clear(all)
    local db = ns.db
    if all then
        wipe(db.chars)
        wipe(db.items)
        db.chars[self:CharKey()] = char
    end
    wipe(char)
    Fill(char)
end

function Journal:AddCast()
    session.casts = session.casts + 1
    char.totals.casts = char.totals.casts + 1
    ns:Fire("SESSION_UPDATED")
end

function Journal:AddFishingTime(seconds)
    session.seconds = session.seconds + seconds
    char.totals.seconds = char.totals.seconds + seconds
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

    -- Mémoire de l'objet (nom, icône), commune à tous les personnages
    local info = db.items[itemID]
    if not info then
        info = {}
        db.items[itemID] = info
    end
    info.n = name or info.n
    info.q = quality or info.q
    info.i = icon or info.i

    -- Nouvelle espèce pour ce personnage ?
    local isNew = char.species[itemID] == nil
    char.species[itemID] = (char.species[itemID] or 0) + quantity

    local zone = char.zones[mapID]
    if not zone then
        zone = { name = zoneName, catches = 0, total = 0, fish = {} }
        char.zones[mapID] = zone
    end
    zone.name = zoneName or zone.name
    zone.total = zone.total + quantity
    zone.fish[itemID] = (zone.fish[itemID] or 0) + quantity
    zone.last = time()

    session.items[itemID] = (session.items[itemID] or 0) + quantity
    table.insert(session.recent, 1, { id = itemID, qty = quantity, t = time() })
    while #session.recent > RECENT_MAX do
        table.remove(session.recent)
    end

    table.insert(char.history, 1, { id = itemID, qty = quantity, t = time(), m = mapID })
    while #char.history > HISTORY_MAX do
        table.remove(char.history)
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
        char.totals.catches = char.totals.catches + 1
        local zone = char.zones[mapID]
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

--- Une zone, additionnée sur les carnets affichés (nil si jamais pêché là).
function Journal:GetZone(mapID)
    local merged
    for _, data in ipairs(Sources()) do
        local zone = data.zones[mapID]
        if zone then
            merged = merged or { name = zone.name, catches = 0, total = 0, fish = {} }
            merged.name = merged.name or zone.name
            merged.catches = merged.catches + (zone.catches or 0)
            merged.total = merged.total + (zone.total or 0)
            if zone.last and (not merged.last or zone.last > merged.last) then
                merged.last = zone.last
            end
            for itemID, count in pairs(zone.fish or {}) do
                merged.fish[itemID] = (merged.fish[itemID] or 0) + count
            end
        end
    end
    return merged
end

--- Toutes les zones, triées par nombre d'objets pêchés.
function Journal:GetZones()
    local seen, list = {}, {}
    for _, data in ipairs(Sources()) do
        for mapID in pairs(data.zones) do
            if not seen[mapID] then
                seen[mapID] = true
                local zone = self:GetZone(mapID)
                list[#list + 1] = {
                    mapID = mapID, name = zone.name or UNKNOWN,
                    total = zone.total, catches = zone.catches, last = zone.last,
                }
            end
        end
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
        local zone = self:GetZone(mapID)
        return SortedFish(zone and zone.fish or {})
    end
    local merged = {}
    for _, data in ipairs(Sources()) do
        for _, zone in pairs(data.zones) do
            for itemID, count in pairs(zone.fish or {}) do
                merged[itemID] = (merged[itemID] or 0) + count
            end
        end
    end
    return SortedFish(merged)
end

--- Totaux (prises, lancers, temps) des carnets affichés.
function Journal:GetTotals()
    local sum = { catches = 0, casts = 0, seconds = 0 }
    for _, data in ipairs(Sources()) do
        for key in pairs(sum) do
            sum[key] = sum[key] + (data.totals[key] or 0)
        end
    end
    return sum
end

function Journal:CountSpecies()
    local seen, n = {}, 0
    for _, data in ipairs(Sources()) do
        for itemID in pairs(data.species) do
            if not seen[itemID] then
                seen[itemID] = true
                n = n + 1
            end
        end
    end
    return n
end
