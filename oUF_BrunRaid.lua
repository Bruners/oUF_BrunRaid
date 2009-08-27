local NameHoover = false
local total = 0
local pairs = pairs
local texture = "Interface\\AddOns\\oUF_BrunRaid\\textures\\statusbar"
local FONT, FONT_SIZE, SMALL_FONT_SIZE = ("Interface\\Addons\\oUF_BrunRaid\\textures\\Font.ttf"), 9, 8
local function menu(self)
	if(self.unit:match("party")) then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor")
	else
		FriendsDropDown.unit = self.unit
		FriendsDropDown.id = self.id
		FriendsDropDown.initialize = RaidFrameDropDown_Initialize
		ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor")
	end
end

local function ReadyCheckFinish(self, elapsed)
	total = total + elapsed
	if(total >= 10) then
		if(total >= 15) then
			for k,v in pairs(oUF.objects) do
				if(type(v) == "table" and v.ReadyCheck) then
					v.ReadyCheck:Hide()
				end
			end
			total = 0
			self:SetScript("OnUpdate", nil)
		else
			local alpha = (5 - total) / 5
			for k,v in pairs(oUF.objects) do
				if(type(v) == "table" and v.ReadyCheck) then
					v.ReadyCheck:SetAlpha(alpha)
				end
			end
		end
	end
end

local function ReadyCheckConfirm(self, event, index, status)
	if(self.id ~= tostring(index)) then return end

	if(status and status == 1) then
		self.ReadyCheck:SetTexture([=[Interface\RAIDFRAME\ReadyCheck-Ready]=])
	else
		self.ReadyCheck:SetTexture([=[Interface\RAIDFRAME\ReadyCheck-NotReady]=])
	end
end

local function ReadyCheck(self, event, name)
	if(not IsRaidLeader() and not IsRaidOfficer() and not IsPartyLeader()) then return end

	if(UnitName(self.unit) == name) then
		self.ReadyCheck:SetTexture([=[Interface\RAIDFRAME\ReadyCheck-Ready]=])
	else
		self.ReadyCheck:SetTexture([=[Interface\RAIDFRAME\ReadyCheck-Waiting]=])
	end

	self.ReadyCheck:SetAlpha(1)
	self.ReadyCheck:Show()
end
local utf8sub = function(string, i, dots)
	local bytes = string:len()
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and '...' or '')
		else
			return string
		end
	end
end

oUF.Tags["[brunraid_name]"] = function(unit)
	if(not unit) then return end
	local name = UnitName(unit)
	return utf8sub(name, 4, false)
end
oUF.Tags["[brunraid_afk]"] = function(unit)
	if(not UnitExists(unit)) then return end
	return UnitIsAFK(unit) and " |cffffff00<A>|r" or ""
end

oUF.Tags["[brunraid_health]"] = function(unit)
	if(not unit) then return end
	local m = UnitHealthMax(unit)
	local n = UnitHealth(unit)
	return m == 0 and 0 .."%" or n > m and m .. "%" or math.floor(n/m*100) .. "%"
end

oUF.Tags["[brunraid_status]"] = function(unit)
	return not unit and "" or UnitIsDead(unit) and "Dead" or UnitIsGhost(unit) and "Ghst" or not UnitIsConnected(unit) and "Offl" or oUF.Tags["[brunraid_health]"](unit)
end
	
oUF.TagEvents["[brunraid_name]"] = "UNIT_NAME_UPDATE"
oUF.TagEvents["[brunraid_afk]"] = "PLAYER_FLAGS_CHANGED"
oUF.TagEvents["[brunraid_health]"] = "UNIT_HEALTH UNIT_MAXHEALTH"
oUF.TagEvents["[brunraid_status]"] = "UNIT_HEALTH PLAYER_UPDATE_RESTING"

local function CreateStyle(self, unit)
	self.menu = menu

	self:RegisterForClicks("AnyUp")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:SetAttribute("*type2", "menu")

	self:SetAttribute("initial-height", 21)
	self:SetAttribute("initial-width", 85)

	local hp = CreateFrame"StatusBar"
	hp:SetHeight(20)
	hp:SetStatusBarTexture(texture)
	hp:SetStatusBarColor(.25, .25, .35)
	hp:SetAlpha(0.8)
	hp:SetParent(self)
	hp:SetPoint"TOP"
	hp:SetPoint"LEFT"
	hp:SetPoint"RIGHT"

	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(0, 0, 0, .5)

	local hpp = hp:CreateFontString(nil, 'OVERLAY')
	hpp:SetFont(FONT, FONT_SIZE , "OUTLINE")
	hpp:SetPoint("RIGHT", -2, 0)
	hpp:SetShadowOffset(1, -1)
	hpp:SetTextColor(1, 1, 1)
	self:Tag(hpp, "[brunraid_status]")
	
	hp.bg = hpbg

	self.Health = hp
	self.Health.colorDisconnected = true
	self.Health.colorClass = true

	local leader = hp:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("CENTER", hp, "CENTER", -5, 10)
	leader:SetTexture"Interface\\GroupFrame\\UI-Group-LeaderIcon"
	self.Leader = leader

	local ricon = hp:CreateTexture(nil, "OVERLAY")
	ricon:SetHeight(16)
	ricon:SetWidth(16)
	ricon:SetPoint("LEFT", hp, "LEFT", -10, 10)
	ricon:SetTexture"Interface\\TargetingFrame\\UI-RaidTargetingIcons"
	self.RaidIcon = ricon

	local name = hp:CreateFontString(nil, 'OVERLAY')
	name:SetFont(FONT, FONT_SIZE , "OUTLINE")
	name:SetPoint("LEFT", 2, 0)
	name:SetJustifyH"LEFT"
	name:SetShadowOffset(1, -1)
	name:SetTextColor(1, 1, 1)
	
	self:Tag(name, "[brunraid_name][brunraid_afk]")
	self.Name = name
	
	if NameHoover then
		name:SetAlpha(0)
		self:SetScript('OnEnter', function() name:SetAlpha(1) end)
		self:SetScript('OnLeave', function() name:SetAlpha(0) end)
	end
	local masterloot = hp:CreateTexture(nil, "OVERLAY")
	masterloot:SetHeight(16)
	masterloot:SetWidth(16)
	masterloot:SetPoint("LEFT", leader, "RIGHT")
	masterloot:SetTexture"Interface\\GroupFrame\\UI-Group-MasterLooter"
	self.MasterLooter = masterloot
	
	local hili = self:CreateTexture(nil, "HIGHLIGHT")
	hili:SetAllPoints(self.Health)
	hili:SetBlendMode("ADD")
	hili:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	self.Highlight = hili
	
	self.ReadyCheck = self.Health:CreateTexture(nil, "OVERLAY")
	self.ReadyCheck:SetPoint("CENTER")
	self.ReadyCheck:SetHeight(20)
	self.ReadyCheck:SetWidth(20)
	
	self:RegisterEvent("READY_CHECK", ReadyCheck)
	self:RegisterEvent("READY_CHECK_CONFIRM", ReadyCheckConfirm)
	self:RegisterEvent("READY_CHECK_FINISHED", function()
	CreateFrame("Frame"):SetScript("OnUpdate", ReadyCheckFinish)
	end)
	
	if(not unit) then
		self.Range = true 
		self.inRangeAlpha = 1.0
		self.outsideRangeAlpha = 0.5
	end

	return self
end

oUF:RegisterStyle("oUF_BrunRaid", CreateStyle)

local raid = {}
local partyToggle = CreateFrame("Frame")
partyToggle:RegisterEvent("PLAYER_LOGIN")
partyToggle:RegisterEvent("RAID_ROSTER_UPDATE")
partyToggle:RegisterEvent("PARTY_LEADER_CHANGED")
partyToggle:RegisterEvent("PARTY_MEMBERS_CHANGED")
partyToggle:SetScript("OnEvent", function(self)
	oUF:SetActiveStyle("oUF_BrunRaid")
	if(InCombatLockdown()) then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		for i = 1, 8 do
			table.insert(raid, oUF:Spawn("header", "oUF_Raid"..i))
			if i == 1 then
				raid[i]:SetPoint("LEFT", UIParent, "LEFT", 20, 100)
			elseif i == 6 then
				raid[i]:SetPoint("LEFT", UIParent, "LEFT", 20, -20)
			else
				raid[i]:SetPoint("LEFT", raid[i-1], "RIGHT", 5, 0)		
			end
			raid[i]:SetManyAttributes("showRaid", true, "yOffset", 0, "groupFilter", i)
			raid[i]:Show()
		end
	end
end)

