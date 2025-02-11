local _, br = ...
function br:AcceptQueues()
	if br.getOptionCheck("Accept Queues") then
		-- Accept Queues
		br.randomReady = math.random(8, 15)
		-- add some randomness
		if br.readyToAccept and br.readyToAccept <= br._G.GetTime() - 5 then
			br._G.AcceptProposal()
			br.readyToAccept = nil
			br.randomReady = nil
		end
	end
end
------------------------------------------------------------------------------------------------------------------------
-- idTip by Silverwind
local hooksecurefunc, select, UnitBuff, UnitDebuff, UnitAura, UnitGUID, _, tonumber, strfind =
	br._G.hooksecurefunc,
	br._G.select,
	br._G.UnitBuff,
	br._G.UnitDebuff,
	br._G.UnitAura,
	br._G.UnitGUID,
	br._G.GetGlyphSocketInfo,
	br._G.tonumber,
	br._G.strfind
local types = {
	spell = "SpellID:",
	item = "ItemID:",
	glyph = "GlyphID:",
	unit = "NPC ID:",
	quest = "QuestID:",
	talent = "TalentID:",
	achievement = "AchievementID:"
}
local function addLine(tooltip, id, type, noEmptyLine)
	local found = false
	-- Check if we already added to this tooltip. Happens on the talent frame
	for i = 1, 15 do
		local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
		local text
		if frame then
			text = frame:GetText()
		end
		if text and text == type then
			found = true
			break
		end
	end
	if not found then
		if not noEmptyLine then
			tooltip:AddLine(" ")
		end
		tooltip:AddDoubleLine(type, "|cffffffff" .. id)
		tooltip:Show()
	end
end
-- All types, primarily for linked tooltips
local function onSetHyperlink(self, link)
	local type, id = string.match(link, "^(%a+):(%d+)")
	if not type or not id then
		return
	end
	if type == "spell" or type == "enchant" or type == "trade" then
		addLine(self, id, types.spell)
	elseif type == "glyph" then
		addLine(self, id, types.glyph)
	elseif type == "talent" then
		addLine(self, id, types.talent)
	elseif type == "quest" then
		addLine(self, id, types.quest)
	elseif type == "achievement" then
		addLine(self, id, types.achievement)
	elseif type == "item" then
		addLine(self, id, types.item)
	end
end
hooksecurefunc(br._G.ItemRefTooltip, "SetHyperlink", onSetHyperlink)
hooksecurefunc(br._G.GameTooltip, "SetHyperlink", onSetHyperlink)
-- Spells
hooksecurefunc(
	br._G.GameTooltip,
	"SetUnitBuff",
	function(self, ...)
		local id = select(10, UnitBuff(...))
		if id then
			addLine(self, id, types.spell)
		end
	end
)
hooksecurefunc(
	br._G.GameTooltip,
	"SetUnitDebuff",
	function(self, ...)
		local id = select(10, UnitDebuff(...))
		if id then
			addLine(self, id, types.spell)
		end
	end
)
hooksecurefunc(
	br._G.GameTooltip,
	"SetUnitAura",
	function(self, ...)
		local id = select(10, UnitAura(...))
		if id then
			addLine(self, id, types.spell)
		end
	end
)
hooksecurefunc(
	"SetItemRef",
	function(link, ...)
		local id = tonumber(link:match("spell:(%d+)"))
		if id then
			addLine(br._G.ItemRefTooltip, id, types.spell)
		end
	end
)
br._G.GameTooltip:HookScript(
	"OnTooltipSetSpell",
	function(self)
		local id = select(3, self:GetSpell())
		if id then
			addLine(self, id, types.spell)
		end
	end
)
-- NPCs
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit,
	function(self)
		if br._G.C_PetBattles.IsInBattle() then
			return
		end
		local unit = select(2, self:GetUnit())
		if br.isChecked("Unit ID In Tooltip") and unit then
			local guid = UnitGUID(unit) or ""
			local id = tonumber(guid:match("-(%d+)-%x+$"), 10)
			local type = guid:match("%a+")
			-- ID 970 seems to be used for players
			if id and type ~= "Player" then
				addLine(br._G.GameTooltip, id, types.unit)
			end
		end
	end
)
-- Items
local function attachItemTooltip(self)
	local link = select(2, self:GetItem())
	if link then
		local id = select(3, strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+).*"))
		if id then
			addLine(self, id, types.item)
		end
	end
end
br._G.GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
br._G.ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
br._G.ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
br._G.ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
br._G.ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
br._G.ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
-- Glyphs -- Commented out due to Legion
-- hooksecurefunc(GameTooltip, "SetGlyph", function(self, ...)
-- 	local id = select(4, GetGlyphSocketInfo(...))
-- 	if id then addLine(self, id, types.glyph) end
-- end)
-- hooksecurefunc(GameTooltip, "SetGlyphByID", function(self, id)
-- 	if id then addLine(self, id, types.glyph) end
-- end)
-- Achievement Frame Tooltips
local f = br._G.CreateFrame("frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript(
	"OnEvent",
	function(_, _, what)
		if what == "Blizzard_AchievementUI" then
			for _, button in ipairs(br._G.AchievementFrameAchievementsContainer.buttons) do
				button:HookScript(
					"OnEnter",
					function()
						br._G.GameTooltip:SetOwner(button, "ANCHOR_NONE")
						br._G.GameTooltip:SetPoint("TOPLEFT", button, "TOPRIGHT", 0, 0)
						addLine(br._G.GameTooltip, button.id, types.achievement, true)
						br._G.GameTooltip:Show()
					end
				)
				button:HookScript(
					"OnLeave",
					function()
						br._G.GameTooltip:Hide()
					end
				)
			end
		end
	end
)
-- local petAbilityTooltipID = false
-- local orig_SharedPetBattleAbilityTooltip_SetAbility = br._G.SharedPetBattleAbilityTooltip_SetAbility
-- function br.SharedPetBattleAbilityTooltip_SetAbility(self, abilityInfo, additionalText)
-- 	orig_SharedPetBattleAbilityTooltip_SetAbility(self, abilityInfo, additionalText)
-- 	petAbilityTooltipID = abilityInfo:GetAbilityID()
-- end
-- br._G.PetBattlePrimaryAbilityTooltip:HookScript(
-- 	"OnShow",
-- 	function(self)
-- 		local name = self.Name:GetText()
-- 		self.Name:SetText(name .. " (ID: " .. petAbilityTooltipID .. ")")
-- 	end
-- )
------------------------------------------------------------------------------------------------------------------------
-- LibStub
-- $Id: LibStub.lua 76 2007-09-03 01:50:17Z mikk $
-- LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/wiki/LibStub for more info
-- LibStub is hereby placed in the Public Domain
-- Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2 -- NEVER MAKE THIS AN SVN REVISION! IT NEEDS TO BE USABLE IN ALL REPOS!
local LibStub = _G[LIBSTUB_MAJOR]
-- Check to see is this version of the stub is obsolete
if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or {libs = {}, minors = {}}
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR
	-- LibStub:NewLibrary(major, minor)
	-- major (string) - the major version of the library
	-- minor (string or number ) - the minor version of the library
	--
	-- returns nil if a newer or same version of the lib is already present
	-- returns empty library object or old library object if upgrade is needed
	function LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		minor = assert(tonumber(br._G.strmatch(minor, "%d+")), "Minor version must either be a number or contain a number.")
		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then
			return nil
		end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end
	-- LibStub:GetLibrary(major, [silent])
	-- major (string) - the major version of the library
	-- silent (boolean) - if true, library is optional, silently return nil if its not found
	--
	-- throws an error if the library can not be found (except silent is set)
	-- returns the library object if found
	function LibStub:GetLibrary(major, silent)
		if not self.libs[major] and not silent then
			error(("Cannot find a library instance of %q."):format(tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end
	-- LibStub:IterateLibraries()
	--
	-- Returns an iterator for the currently registered libraries
	function LibStub:IterateLibraries()
		return pairs(self.libs)
	end
	setmetatable(LibStub, {__call = LibStub.GetLibrary})
end

function br.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[br.deepcopy(orig_key)] = br.deepcopy(orig_value)
		end
		setmetatable(copy, br.deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end
