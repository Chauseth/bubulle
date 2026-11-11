--[[
    Bubulle - UI/Mascot.lua
    ------------------------------------------------------------------
    Affiche Bubulle, le poisson rouge mascotte de l'addon.

    Son image est Media/Bubulle.tga : une image 256 x 256 avec
    transparence (format TGA, que WoW sait lire). Tu peux la remplacer
    par la tienne, du moment qu'elle garde le même nom et la même taille.
    Attention : après avoir changé une image, il faut relancer le jeu
    (un simple /reload ne suffit pas pour les images).
]]

local _, ns = ...

local Mascot = {}
ns.Mascot = Mascot

local ILLUSTRATION = "Interface\\AddOns\\Bubulle\\Media\\Bubulle"
Mascot.ILLUSTRATION = ILLUSTRATION

--- Met l'image de Bubulle sur une texture (petits portraits, minicarte).
--- Pas de SetTexCoord ici : le jeu le refuse sur une texture découpée en
--- rond par un masque (minicarte, page d'options), et l'image entière est
--- déjà affichée par défaut.
function Mascot:SetPortrait(texture)
    texture:SetTexture(ILLUSTRATION)
end

--- Fabrique un cadre qui affiche Bubulle en train de "nager" sur place.
function Mascot:CreateModel(parent, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)

    -- "body" porte l'image ; on le déplace nous-mêmes à chaque image
    -- (nage + petit saut), en partant toujours de la position de repos :
    -- aucun risque qu'il dérive hors de son cadre.
    local body = CreateFrame("Frame", nil, holder)
    body:SetSize(size, size)
    body:SetPoint("CENTER", holder, "CENTER", 0, 0)

    local picture = body:CreateTexture(nil, "ARTWORK")
    picture:SetPoint("CENTER")
    picture:SetSize(size * 0.92, size * 0.92)
    picture:SetTexture(ILLUSTRATION)
    holder.picture = picture

    local SWIM_HEIGHT, SWIM_SPEED = 3, 2.2  -- pixels, vitesse de la nage
    local HOP_HEIGHT, HOP_TIME = 10, 0.4    -- pixels, durée du saut
    local clock, hopStart = 0, nil

    holder:SetScript("OnUpdate", function(_, elapsed)
        clock = clock + elapsed
        local y = math.sin(clock * SWIM_SPEED) * SWIM_HEIGHT
        if hopStart then
            local t = (clock - hopStart) / HOP_TIME
            if t >= 1 then
                hopStart = nil
            else
                y = y + math.sin(t * math.pi) * HOP_HEIGHT
            end
        end
        body:SetPoint("CENTER", holder, "CENTER", 0, y)
    end)

    -- Petit saut de joie (prise, nouvelle espèce...).
    function holder:Hop()
        if not hopStart then
            hopStart = clock
        end
    end

    return holder
end
