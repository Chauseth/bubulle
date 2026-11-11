-- Minimal WoW API mock to smoke-test Bubulle
local ADDON_DIR = arg[1] or "."
local LOCALE = arg[2] or "frFR"
local TOCV = tonumber(arg[3] or "16001")
local events = {}       -- event -> list of frames
local unitEvents = {}
local now = 1000
local timers = {}
local bindings = {}
local cvars = { Sound_EnableAllSound="1", Sound_EnableSFX="1", Sound_SFXVolume="0.5", Sound_MusicVolume="0.7",
  Sound_AmbienceVolume="0.6", Sound_EnableSoundWhenGameIsInBG="0", autoLootDefault="0", SoftTargetInteract="1", SoftTargetInteractRange="10" }
local calls = {}
local function log(s) calls[#calls+1] = s end

local Obj = {}
local function new(kind, name)
  local o = { _kind = kind, _shown = (kind ~= "Frame" and kind ~= "Button") or true, _scripts = {}, _h = 0, _w = 0, _min=0, _max=1, _val=0, _alpha=1, _enabled=true, _name=name, _attrs={} }
  return setmetatable(o, Obj)
end
local methods = {}
Obj.__index = function(t, k)
  if methods[k] then return methods[k] end
  if type(k)=="string" and k:match("^%u") then return function() return nil end end
  return nil
end
function methods:SetScript(s, f) self._scripts[s] = f end
function methods:HookScript(s, f) local old = self._scripts[s]; self._scripts[s] = function(...) if old then old(...) end f(...) end end
function methods:GetScript(s) return self._scripts[s] end
function methods:Fire(s, ...) local f = self._scripts[s]; if f then return f(self, ...) end end
function methods:RegisterEvent(e) events[e] = events[e] or {}; table.insert(events[e], self) end
function methods:RegisterUnitEvent(e) events[e] = events[e] or {}; table.insert(events[e], self) end
function methods:CreateTexture() return new("Texture") end
function methods:CreateFontString() local f = new("FontString"); f._text=""; return f end
function methods:CreateAnimationGroup() return new("AnimationGroup") end
function methods:CreateAnimation() return new("Animation") end
function methods:SetText(t) self._text = t end
function methods:GetText() return self._text end
function methods:GetStringWidth() return #(tostring(self._text or "")) * 6 end
function methods:SetHeight(h) self._h = h; self:Fire("OnSizeChanged") end
function methods:SetWidth(w) self._w = w end
function methods:SetSize(w, h) self._w = w; self._h = h; self:Fire("OnSizeChanged") end
function methods:GetHeight() return self._h end
function methods:GetWidth() return self._w end
function methods:SetPoint(...) self._points = (self._points or 0) + 1 end
function methods:GetPoint() return "CENTER", nil, "CENTER", 10, 20 end
function methods:SetAllPoints() if self._h == 0 then self._h = 300 end end
function methods:Show() if not self._shown then self._shown = true; self:Fire("OnShow") end end
function methods:Hide() if self._shown then self._shown = false; self:Fire("OnHide") end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self._shown end
function methods:IsVisible() return self._shown end
function methods:SetMinMaxValues(a,b) assert(type(a)=="number" and type(b)=="number","minmax"); self._min=a; self._max=b end
function methods:GetMinMaxValues() return self._min, self._max end
function methods:SetValue(v) assert(type(v)=="number","SetValue needs number"); local old=self._val; self._val=v; if self._kind=="Slider" and old~=v then self:Fire("OnValueChanged", v, false) end end
function methods:GetValue() return self._val end
function methods:SetAlpha(a) self._alpha = a end
function methods:GetAlpha() return self._alpha end
function methods:IsEnabled() return self._enabled end
function methods:SetEnabled(v) self._enabled = v end
function methods:GetFrameLevel() return 1 end
function methods:IsPlaying() return false end
function methods:Play() if self._kind=="AnimationGroup" then self:Fire("OnFinished") end end
function methods:SetAttribute(k,v) self._attrs[k]=v end
function methods:GetAttribute(k) return self._attrs[k] end
function methods:SetFont(file, size, flags) assert(file and size and flags, "SetFont args") end
function methods:SetTextColor(r,g,b) assert(type(r)=="number" and type(g)=="number" and type(b)=="number", "SetTextColor") end
function methods:SetColorTexture(r,g,b) assert(type(r)=="number" and type(g)=="number" and type(b)=="number", "SetColorTexture") end
function methods:SetBackdropColor(r,g,b) assert(type(r)=="number" and type(g)=="number" and type(b)=="number", "BackdropColor") end
function methods:SetBackdropBorderColor(r,g,b) assert(type(r)=="number" and type(g)=="number" and type(b)=="number", "BorderColor") end
function methods:SetStatusBarColor(r,g,b) assert(type(r)=="number","statusbarcolor") end
function methods:SetFontObject(f) assert(f, "SetFontObject nil") end
function methods:SetTexture(t) self._tex = t end
function methods:Click(button, down) self:Fire("OnClick", button or "LeftButton", down) ; self:Fire("PostClick", button or "LeftButton", down) end
function methods:SetDisplayInfo(id) log("SetDisplayInfo "..tostring(id)) end
function methods:SetCreature(id) log("SetCreature "..tostring(id)) end

_G.CreateFrame = function(kind, name, parent, template)
  local o = new(kind, name)
  o._shown = true
  if name then _G[name] = o end
  return o
end
_G.CreateFont = function(name) local f = new("Font"); _G[name]=f; return f end
_G.UIParent = new("Frame"); _G.WorldFrame = new("Frame")
_G.Minimap = new("Frame"); Minimap._w = 140
function methods:GetCenter() return 500, 400 end
function methods:GetEffectiveScale() return 1 end
_G.GetCursorPosition = function() return 500, 600 end
_G.GameTooltip = new("GameTooltip"); _G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) print("[chat] "..m) end }
_G.GetTime = function() return now end
_G.time = os.time; _G.date = os.date
_G.wipe = function(t) for k in pairs(t) do t[k]=nil end return t end
_G.tinsert = table.insert; _G.strtrim = function(s) return (s:gsub("^%s+",""):gsub("%s+$","")) end
_G.UISpecialFrames = {}
_G.GetLocale = function() return LOCALE end
-- Forever : nom composé « Chau Seth » (UnitName renvoie prénom, nom)
_G.UnitName = function() return "Chau", "Seth" end
_G.GetRealmName = function() return "Forever" end
-- Ancien carnet commun au compte (avant 1.1) : doit revenir à ce personnage
_G.BubulleDB = { zones = { [1] = { name = "Vieux lac", catches = 2, total = 3, fish = { [6303] = 3 } } },
  totals = { catches = 2, casts = 4, seconds = 60 }, history = {}, items = { [6303] = { n = "Lutjan", q = 1, c = 3 } } }
_G.C_AddOns = { GetAddOnMetadata = function() return "1.0.0" end }
_G.C_Timer = { After = function(d, f) table.insert(timers, {t=now+d, f=f}) end,
  NewTicker = function(d, f) local tk = {d=d,f=f,next=now+d,cancel=false}; tk.Cancel = function(s) s.cancel=true end; table.insert(timers, tk); return tk end }
_G.InCombatLockdown = function() return false end
_G.SetOverrideBindingClick = function(owner, prio, key, btn) bindings[key] = "CLICK "..btn; log("bind "..key.." -> "..btn) end
_G.SetOverrideBinding = function(owner, prio, key, cmd) bindings[key] = cmd; log("bind "..key.." -> "..cmd) end
_G.ClearOverrideBindings = function(owner) log("clear bindings") end
local gameBindings = {}
_G.SetBinding = function(key, cmd) gameBindings[key] = cmd; return true end
_G.GetBindingAction = function(key) return gameBindings[key] or "" end
_G.GetBindingKey = function(cmd) local out = {}; for k, c in pairs(gameBindings) do if c == cmd then out[#out+1] = k end end; table.sort(out); return unpack(out) end
_G.SaveBindings = function() end
_G.GetCurrentBindingSet = function() return 2 end
_G.GetMouseFoci = function() return { WorldFrame } end
_G.IsModifierKeyDown = function() return false end
_G.IsFlying = function() return false end
_G.UnitExists = function() return false end
_G.GetCursorInfo = function() return nil end
_G.IsAltKeyDown = function() return false end; _G.IsControlKeyDown = function() return false end; _G.IsShiftKeyDown = function() return false end
_G.GetBindingText = function(k) return k end
_G.C_Spell = { GetSpellName = function(id) if id==131474 or id==131476 then return "Pêche" end return "Autre" end }
_G.C_CVar = { GetCVar = function(k) return cvars[k] end, SetCVar = function(k, v) cvars[k] = tostring(v); log("cvar "..k.."="..tostring(v)) end }
_G.UnitChannelInfo = function() return "Pêche", "Pêche", 1, now*1000, (now+21)*1000, true, false, 131476 end
_G.C_Map = { GetBestMapForUnit = function() return 2248 end, GetMapInfo = function() return { name = "Île de Dorn" } end }
_G.GetZoneText = function() return "Île de Dorn" end; _G.GetSubZoneText = function() return "Lac" end
_G.C_Item = { GetItemInfoInstant = function(link) return tonumber(link:match("item:(%d+)")) end, GetItemNameByID = function(id) return "Item"..id end, GetItemIconByID = function() return 1 end }
_G.Enum = { LootSlotType = { Item = 1, Money = 2 } }
local loot = {}
_G.IsFishingLoot = function() return true end
_G.GetNumLootItems = function() return #loot end
_G.GetLootSlotType = function(i) return loot[i].type end
_G.GetLootSlotLink = function(i) return loot[i].link end
_G.GetLootSlotInfo = function(i) local l = loot[i]; return l.icon, l.name, l.qty, nil, l.q end
_G.ITEM_QUALITY_COLORS = {}
for q=0,7 do ITEM_QUALITY_COLORS[q] = { r=1, g=1, b=1, hex="|cffffffff" } end
_G.SOUNDKIT = { IG_MAINMENU_OPTION_CHECKBOX_ON = 1, UI_EPICLOOT_TOAST = 2, UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST = 3 }
_G.PlaySound = function(id, ch) log("sound "..tostring(id)) end
_G.STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
_G.UNKNOWN = "Inconnu"
_G.SetPortraitTextureFromCreatureDisplayID = function(t, id) log("portrait "..id) end
_G.Settings = { RegisterCanvasLayoutCategory = function() return {} end, RegisterAddOnCategory = function() end }
_G.SlashCmdList = {}
_G.LootFrame = new("Frame"); LootFrame._shown = false
_G.HideUIPanel = function() end
_G.print = print
_G.issecretvalue = nil
_G.UnitGUID = function() return "Player-1" end
_G.GetBuildInfo = function() return "1.60.1", "70888", "Nov 2026", TOCV end
local poleEquipped = true
_G.GetInventoryItemID = function(u, slot) if slot == 16 and poleEquipped then return 6256 end end
_G.GetWeaponEnchantInfo = function() return false end
_G.GetNumSkillLines = function() return 2 end
_G.GetSkillLineInfo = function(i) if i == 1 then return "Métiers", true end return "Pêche", false, nil, 150, 0, 5, 225 end
_G.CreateColor = function(r,g,b,a) return {r=r,g=g,b=b,a=a} end
local _gii = C_Item.GetItemInfoInstant
C_Item.GetItemInfoInstant = function(x) if x == 6256 then return 6256, "Arme", "Canne", "INVTYPE_2HWEAPON", 1, 2, 20 end return _gii(x) end

local function fire(e, ...)
  for _, f in ipairs(events[e] or {}) do f:Fire("OnEvent", e, ...) end
end
local function advance(sec)
  local target = now + sec
  while true do
    table.sort(timers, function(a,b) return (a.t or a.next) < (b.t or b.next) end)
    local tm = timers[1]
    if not tm or (tm.t or tm.next) > target then break end
    now = tm.t or tm.next
    if tm.d then -- ticker
      if tm.cancel then table.remove(timers,1) else tm.next = now + tm.d; tm.f() end
    else table.remove(timers,1); tm.f() end
  end
  now = target
end

-- Load TOC
local ns = {}
local toc = io.open(ADDON_DIR.."/Bubulle.toc"):read("*a")
for line in toc:gmatch("[^\r\n]+") do
  if not line:match("^##") and line:match("%.lua$") then
    local path = ADDON_DIR.."/"..line:gsub("\\","/")
    local chunk = assert(loadfile(path))
    chunk("Bubulle", ns)
  end
end

local function step(name, f) local ok, err = pcall(f); print((ok and "OK   " or "FAIL ")..name..(ok and "" or (": "..tostring(err)))) if not ok then os.exit(1) end end

step("ADDON_LOADED", function() fire("ADDON_LOADED", "Bubulle") end)
step("PLAYER_LOGIN", function() fire("PLAYER_LOGIN") end)
step("welcome on first open", function() advance(5); assert(not BubulleWindow, "window should not auto-open"); SlashCmdList.BUBULLE(""); assert(BubulleWindow.welcome:IsShown(), "welcome not shown")
  assert(BubulleWindow.tabs:GetWidth() > 0, "tabs width")
  BubulleWindow.welcome.keyButton:Fire("OnClick","LeftButton"); BubulleWindow.welcome.keyButton:Fire("OnKeyDown","F")
  assert(ns.db.settings.oneKey=="F"); assert(bindings.F=="CLICK BubulleCastButton", "always-on key not bound") ; ns.db.settings.oneKey=false; ns.Fishing:RefreshSettings(); bindings.F=nil; ns.db.welcomed=true; BubulleWindow.welcome:Hide() end)
step("game key binding sync", function()
  -- choisir F dans Bubulle la range dans le menu Raccourcis du jeu
  ns.Fishing:SetKey("F"); assert(gameBindings.F == "BUBULLE_FISH", "game binding not saved")
  -- changer la touche dans le menu du jeu met Bubulle à jour
  gameBindings.F = nil; gameBindings.H = "BUBULLE_FISH"; fire("UPDATE_BINDINGS")
  assert(ns.db.settings.oneKey == "H", "oneKey "..tostring(ns.db.settings.oneKey))
  -- l'effacer dans Bubulle la retire du menu du jeu
  ns.Fishing:SetKey(false); assert(gameBindings.H == nil); assert(ns.db.settings.oneKey == false)
  Bubulle_OnFishKey(); assert(ns.Fishing.active, "key should start fishing mode"); ns.Fishing:SetActive(false)
end)
step("open window session", function() SlashCmdList.BUBULLE("") end)
step("journal tab empty", function() ns.Window:Open("journal") end)
step("options tab", function() ns.Window:Open("options") end)
step("double-click inactive", function() fire("GLOBAL_MOUSE_DOWN","RightButton"); advance(0.1); fire("GLOBAL_MOUSE_DOWN","RightButton"); assert(not bindings.BUTTON2, "should not arm outside mode") end)
step("fishing mode via slash", function() SlashCmdList.BUBULLE("peche"); assert(ns.Fishing.active); assert(cvars.Sound_MusicVolume=="0"); assert(cvars.autoLootDefault=="1") end)
step("double-click arms", function() advance(1); fire("GLOBAL_MOUSE_DOWN","RightButton"); advance(0.2); fire("GLOBAL_MOUSE_DOWN","RightButton"); assert(bindings.BUTTON2 == "CLICK BubulleCastButton") end)
step("cast button click", function() BubulleCastButton:Click("LeftButton", true); BubulleCastButton:Click("LeftButton", false); assert(BubulleCastButton:GetAttribute("spell")=="Pêche", tostring(BubulleCastButton:GetAttribute("spell"))) end)
step("channel start", function() fire("UNIT_SPELLCAST_CHANNEL_START","player","guid",131476); assert(ns.Fishing.channeling); assert(ns.session.casts==1) end)
step("hud gear", function() ns.HUD:Refresh(); print("   gear: "..tostring(BubulleHUD.gear:GetText())) end)
step("hud tick", function() local hud = BubulleHUD; for i=1,5 do hud:Fire("OnUpdate", 0.1) end; advance(3); hud:Fire("OnUpdate", 0.1) end)
step("loot fish", function()
  loot = { {type=1, link="|Hitem:194966:|h", name="Poisson du Rivage", qty=1, q=1, icon=5},
           {type=1, link="|Hitem:200000:|h", name="Perle", qty=2, q=3, icon=6}, {type=2} }
  fire("LOOT_READY", true); fire("LOOT_OPENED", true, false); fire("CHANNEL_STOP_dummy")
  fire("UNIT_SPELLCAST_CHANNEL_STOP","player","guid",131476); fire("LOOT_CLOSED")
  assert(ns.session.catches==1, "catches "..ns.session.catches); assert(ns.Journal:GetZone(2248).fish[200000]==2)
end)
step("toasts + speech", function() advance(10); BubulleHUD:Fire("OnUpdate", 0.1) end)
step("second cast + miss", function() fire("UNIT_SPELLCAST_CHANNEL_START","player","g2",131476); advance(5); fire("UNIT_SPELLCAST_CHANNEL_STOP","player","g2",131476); advance(2); BubulleHUD:Fire("OnUpdate", 0.1); print("   say: "..tostring(BubulleHUD.shownLine)) end)
step("fast-loot fallback via chat", function()
  local before = ns.session.catches
  fire("UNIT_SPELLCAST_CHANNEL_START","player","g9",131476); advance(3)
  loot = {}; fire("LOOT_READY", true); fire("UNIT_SPELLCAST_CHANNEL_STOP","player","g9",131476)
  fire("CHAT_MSG_LOOT", "Vous recevez le butin : |cffffffff|Hitem:6303::::::::|h[Lutjan à longue mâchoire cru]|h|r.", "", "", "", "", "", 0, 0, "", 0, 1, "Player-1")
  fire("CHAT_MSG_LOOT", "Vous recevez le butin : |cffffffff|Hitem:6303::::::::|h[Lutjan à longue mâchoire cru]|h|rx2.", "", "", "", "", "", 0, 0, "", 0, 2, "Player-1")
  fire("LOOT_CLOSED")
  assert(ns.session.catches == before + 1, "catches "..ns.session.catches.." vs "..before)
  assert(ns.session.items[6303] == 3, "qty "..tostring(ns.session.items[6303]))
  advance(10); fire("CHAT_MSG_LOOT", "Vous recevez le butin : |cffffffff|Hitem:2589::::::::|h[Tissu]|h|r.", "", "", "", "", "", 0, 0, "", 0, 3, "Player-1")
  assert(ns.session.items[2589] == nil, "non-fishing loot counted")
end)
step("third loot same fish", function() local b = ns.session.catches; loot = { {type=1, link="|Hitem:194966:|h", name="Poisson du Rivage", qty=1, q=1, icon=5} }; fire("LOOT_READY", true); fire("LOOT_CLOSED"); assert(ns.session.catches==b+1) end)
step("window session refresh", function() ns.Window:Open("session"); print("   summary set") end)
step("journal tab with data", function() ns.Window:Open("journal") end)
step("options toggles", function()
  ns.Window:Open("options")
  -- click every checkbox twice and wheel every slider
  local page = ns.Window.pages.options
  for _, ctl in ipairs(page.controls) do
    if ctl.slider then ctl.slider:Fire("OnMouseWheel", 1); ctl.slider:Fire("OnValueChanged", 0.5, true) else ctl:Fire("OnClick"); ctl:Fire("OnClick") end
  end
  page.keyButton:Fire("OnClick", "LeftButton"); page.keyButton:Fire("OnKeyDown", "LSHIFT"); page.keyButton:Fire("OnKeyDown", "G")
  assert(ns.db.settings.oneKey == "G", "key "..tostring(ns.db.settings.oneKey))
  page.keyButton:Fire("OnClick", "RightButton"); assert(ns.db.settings.oneKey == false)
  print("   settings after:", ns.db.settings.hudScale, ns.db.settings.idleTimeout, ns.db.settings.sfxVolume)
  ns.db.settings.hudScale = 1; ns.db.settings.idleTimeout = 90; ns.db.settings.sfxVolume = 1; ns.db.settings.doubleClickDelay = 0.4
  -- zone row click
  local zrow = ns.Window.pages.journal.zones.rows[2]; ns.Window:Open("journal"); if zrow then zrow:Fire("OnClick") end; ns.Window:Open("journal")
end)
step("one key set", function() ns.db.settings.oneKey = "F"; ns.Fishing:RefreshSettings(); assert(bindings.F == "CLICK BubulleCastButton"); assert(cvars.SoftTargetInteract=="3")
  fire("UNIT_SPELLCAST_CHANNEL_START","player","g3",131476); assert(bindings.F=="INTERACTTARGET"); fire("UNIT_SPELLCAST_CHANNEL_STOP","player","g3",131476); advance(1); assert(bindings.F == "CLICK BubulleCastButton") end)
step("idle timeout restores cvars", function() ns.db.settings.idleTimeout = 90; advance(200); assert(not ns.Fishing.active, "should auto stop"); assert(cvars.Sound_MusicVolume=="0.7", "music "..cvars.Sound_MusicVolume); assert(cvars.autoLootDefault=="0"); assert(cvars.SoftTargetInteract=="1"); assert(ns.db.savedCVars==nil) end)
step("zone change", function() SlashCmdList.BUBULLE("peche"); fire("ZONE_CHANGED_NEW_AREA"); BubulleHUD:Fire("OnUpdate", 0.1); print("   say: "..tostring(BubulleHUD.shownLine)) end)
step("logout keeps copy", function() fire("PLAYER_LOGOUT"); assert(cvars.Sound_MusicVolume=="0.7"); assert(ns.db.savedCVars) end)
step("hud toggle + reset session + help", function() SlashCmdList.BUBULLE("hud"); SlashCmdList.BUBULLE("session"); SlashCmdList.BUBULLE("aide") end)
step("compartment", function() Bubulle_OnCompartmentClick("Bubulle","LeftButton"); Bubulle_OnCompartmentClick("Bubulle","RightButton"); Bubulle_OnCompartmentEnter("Bubulle", UIParent); Bubulle_OnCompartmentLeave() end)
step("mascot picture", function() assert(BubulleHUD.mascot.picture:IsShown()); BubulleHUD.mascot:Hop(); BubulleHUD.mascot:Fire("OnUpdate", 0.1) end)
step("minimap button", function()
  local b = assert(BubulleMinimapButton, "button")
  assert(b:IsShown())
  b:Fire("OnEnter"); b:Fire("OnLeave")
  b:Fire("OnDragStart"); b:Fire("OnUpdate", 0.01); b:Fire("OnDragStop")
  assert(math.abs(ns.db.settings.minimapAngle - 90) < 0.01, ns.db.settings.minimapAngle)
  b:Fire("OnClick", "LeftButton"); b:Fire("OnClick", "RightButton")
  SlashCmdList.BUBULLE("minimap"); assert(not b:IsShown()); SlashCmdList.BUBULLE("minimap"); assert(b:IsShown())
end)
step("journal per character", function()
  local char = ns.Journal:Char(); assert(ns.db.chars["Player-1"] == char, "journal not keyed by GUID")
  assert(char.name == "Chau Seth", "full name: " .. tostring(char.name)); assert(ns.Journal:CharName() == "Chau Seth")
  assert(ns.db.zones == nil and ns.db.totals == nil, "legacy journal not migrated")
  assert(char.zones[1] and char.species[6303] and ns.db.items[6303].c == nil, "legacy data lost")
  ns.db.chars["Jaina-Forever"] = { zones = { [1] = { name = "Vieux lac", catches = 5, total = 5, fish = { [999] = 5 } } },
    totals = { catches = 5, casts = 5, seconds = 10 }, history = {}, species = { [999] = 5 } }
  local mine = ns.Journal:GetTotals().catches
  ns.db.settings.journalAllChars = true
  assert(ns.Journal:GetTotals().catches == mine + 5, "all chars totals"); assert(ns.Journal:GetZone(1).catches == 7)
  ns.Window:Open("journal"); local page = ns.Window.pages.journal; page.allChars:Fire("OnClick")
  assert(ns.db.settings.journalAllChars == false); assert(ns.Journal:GetTotals().catches == mine)
  -- Carnet rangé sous l'ancienne clé par nom : repris sous le GUID du perso
  local oldGUID = UnitGUID
  local named = { zones = {}, totals = { catches = 9, casts = 9, seconds = 1 }, history = {}, species = {} }
  ns.db.chars["Chau-Forever"] = named
  _G.UnitGUID = function() return "Player-2" end; ns:Fire("LOGIN")
  assert(ns.db.chars["Player-2"] == named and ns.db.chars["Chau-Forever"] == nil, "name key not moved to GUID")
  assert(ns.Journal:Char() == named and named.name == "Chau Seth")
  ns.db.chars["Player-2"] = nil; _G.UnitGUID = oldGUID; ns:Fire("LOGIN")
  assert(ns.Journal:Char() == char, "back to own journal")
end)
step("reset settings + clear journal", function()
  ns.db.settings.hudScale = 1.3; ns.Fishing:SetKey("F"); ns.db.welcomed = true
  local page = ns.Window.pages.options
  page.resetSettings:Fire("OnClick")
  assert(ns.db.settings.hudScale == 1, "scale not reset"); assert(ns.db.settings.oneKey == false); assert(gameBindings.F == nil, "game binding kept")
  assert(ns.db.welcomed == false); assert(BubulleWindow.welcome:IsShown(), "welcome not shown after reset")
  BubulleWindow.welcome:Hide(); ns.db.welcomed = true
  local before = ns.Journal:GetTotals().catches; assert(before > 0)
  page.clearJournal:Fire("OnClick")
  local char = ns.Journal:Char()
  assert(char.totals.catches == 0 and next(char.zones) == nil and next(char.species) == nil, "journal not cleared")
  assert(ns.db.chars["Jaina-Forever"].totals.catches == 5, "other character touched")
  assert(ns.session.catches == 0)
  ns.Window:Open("journal"); ns.Window:Open("session")
end)
