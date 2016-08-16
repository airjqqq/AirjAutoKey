AirjAutoKey = LibStub("AceAddon-3.0"):NewAddon("AirjAutoKey", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0","AceSerializer-3.0","AceComm-3.0")
AirjAutoKey.rotationDataBaseArray = {}
local setfcn = {};
local getfcn = {};
local interval = 0.02

local debugmode --= 1
local hack = false
local frameleve = 229
local ifsize = 2
local gcdtime = 1
local gcdname = ""
local optionCallback = {}

local _, pclass = UnitClass("Player")
AirjAutoKey.GCDSpells = {
	ROGUE		= 1752,		-- sinister strike
	PRIEST		= 585,		-- smite
	DRUID		= 5176,		-- wrath
	WARRIOR		= 5308,		-- execute
	MAGE		= 44614,	-- frostfire bolt
	WARLOCK		= 686,		-- shadow bolt
	PALADIN		= 7328,	-- seal of command
	SHAMAN		= 403,		-- lightning bolt
	HUNTER		= 3044,		-- arcane shot
	DEATHKNIGHT = 47541,	-- death coil
	MONK		= 100780,	-- jab
}
AirjAutoKey.spellStrings = {
	--NOTE: any id prefixed with "_" will have its localized name substituted in instead of being forced to match as an ID
	debuffs = {
		Silenced			= "_47476;_78675;_15487;1330;114238;_18498;_25046;31935;31117;102051",
		ReducedHealing		= "115804",

		Stunned				= "_1833;_408;_91800;_113801;5211;22570;19577;24394;44572;_853;_20549;46968;132168;_30283;_7922;64044;91797;_25;_89766;105593;120086;117418;157997;115001;_131402;108194;117526;118905;119392;119381;118345;132169;163505",
		Incapacitated		= "99;3355;_19386;20066;_118;1776;_6770;115078;115268;107079;31661;82691;123393;_137460;88625;_51514",
		Rooted				= "339;122;64695;19387;33395;16979;45334;87194;63685;102359;128405;116706;107566;96294;105771;53148;114404;170996",
		Shatterable			= "122;33395;_44572;_82691;63685;102051", -- by algus2
		Disoriented			= "31661;_2094;_51514;99;123393",
		Slowed				= "_116;_120;_13810;_5116;_8056;_3600;_1715;_12323;116095;_20170;_31589;115000;_115180;45524;50435;51490;_15407;_3409;26679;_58180;61391;44614;_7302;_63529;_15571;_7321;_7992;123586;47960;129923;6343;147531", -- by algus2
		Feared				= "_5782;5246;_8122;10326;_137143;_5484;_6789;_87204",
		Bleeding			= "_1822;_1079;33745;1943;_703;_115767;_11977;106830;77758;155722;16511",

		CrowdControl		= "_118;33786;_1499;_19386;20066;10326;_9484;_6770;_2094;_51514;_710;_5782;_6358;_605;_82691;115078;115268;107079", -- originally by calico0 of Curse

		Dot = "_164812,55078,55095,33745,1079,152221,77758,106830,164815,3674,53301,2120,114923,44457,11366,117952,14914,15407,155361,34914,129250,589,16511,1943,703,8050,103103,1949,980,27243,30108,689,772,115767,_152281,1822,_100784,122470,_31804,",

		Root = "105771,170996,45334,102051",
	},
	buffs = {
		IncreasedMastery	= "155522;24907;19740;116956;93435;160039;128997;160073;160198",
		IncreasedHaste  	= "55610;49868;116956;113742;160003;135678;160074;128432;160203",
		IncreasedSP			= "1459;61316;109773;126309;90364;160205",
		IncreasedAP			= "57330;19506;6673",
		IncreasedStats		= "1126;20217;90363;115921;116781;159988;160017;160077;72586;160206",
		IncreasedVersatility= "55610;1126;167187;167188;159735;35290;160045;50518;57386;160077;172967",
		IncreasedMultistrike= "166916;49868;113742;109773;58604;34889;57386;24844;172968",
		BonusStamina		= "21562;166928;469;90364;160003;160014;111922;160199",
		IncreasedCrit		= "24932;1459;61316;116781;97229;24604;90309;126373;126309;160052;160200",
		BurstHaste			= "2825;32182;80353;90355;146555;160452",

		-- From l337g0g0 of Curse:
		DamageShield		= "_17;_11426;116849;115295;114908;110913;108416;112048;86273;114214;47753;65148;108008;1463;108366;115635;77535;145441;152118;173260;169373",

		ImmuneToStun		= "642;45438;48792;1022;33786;710;46924;_19263;6615",
		ImmuneToMagicCC		= "642;45438;48707;33786;710;46924;_19263;31224;8178;23920;49039;114028",
		DefensiveBuffs		= "48707;30823;33206;47585;871;48792;498;22812;61336;5277;74001;47788;_19263;6940;31850;31224;42650;86657;118038;115176;115308;120954;115295;51271;12975;97463;102342;114039",
		MiscHelpfulBuffs	= "10060;23920;68992;2983;1850;53271;1044;31821;45182;114028",
		SpeedBoosts			= "54861;121557;_2983;_61684;68992;108843;65081;118922;137573;2379;58875;133278;85499;96268;137452;111400;116841;119085;7840;5118;13159;2645;_77761",
		DamageBuffs			= "1719;12292;50334;5217;3045;77801;31884;51713;12472;57933;51271;_107574;114050;114051;113858;113861;113860;112071",
	},
	casts = {
		--prefixing with _ doesnt really matter here since casts only match by name,
		-- but it may prevent confusion if people try and use these as buff/debuff equivs
		Heals				= "5185;8936;740;2060;2061;32546;596;64843;82326;19750;77472;8004;1064;73920;124682;115175;116694;33076;120517;121135;48438;116670;114163;85222;85673",
		PvPSpells			= "33786;339;20484;982;_605;5782;5484;10326;51514;118;12051;20066",
		Tier11Interrupts	= "_83703;_82752;_82636;_83070;_79710;_77896;_77569;_80734;_82411",
		Tier12Interrupts	= "_97202;_100094",
	},
}

function AirjAutoKey:RemapSpells()
	self.tmwSpells = {}
	local spells = self.tmwSpells
	for group, v in pairs(self.spellStrings) do
		spells[group] = {}
		for type, str in pairs(v) do
			spells[group][type] = {}
			local list = {strsplit(";",str)}
			for i, id in ipairs(list) do
				local key
				if string.sub(id,1,1) == "_" then
					id = string.sub(id,2)
					key = GetSpellInfo(id) or id
				else
					key = tonumber(id)
				end
				tinsert(spells[group][type],key)
			end
		end
	end
end

AirjAutoKey.GCDSpell = AirjAutoKey.GCDSpells[pclass]

function optionCallback:SetValue(info, value, ...)
	local key = info[#info];
	AirjAutoKey:SetConfigValue(key,value);
end
function optionCallback:GetValue(info, ...)
	local key = info[#info];
	return AirjAutoKey:GetConfigValue(key);
end


local options = {
	type = "group",
	args = {
		auto = {
			name = "Enable auto",
			descStyle =  "inline",
			order  = 1,
			desc = "Cast the spell automatic without key pressing. NEED OUTGAME SOFTWARE",
			type = "toggle",
			set = "SetValue",
			get = "GetValue",
			handler  = optionCallback,
			width = "full",
		},
		cd = {
			name = "Cooldown limit",
			order  = 2,
			desc = "Cooldown time limit. The spells those has longer cd will be ignored.",
			type = "range",
			set = "SetValue",
			get = "GetValue",
			min = 15,
			max = 600,
			step = 15,
			bigStep  = 15,
			handler  = optionCallback,
			width = "full",
		},
		once = {
			name = "once",
			order  = 3,
			desc = "enable auto for a while, giving the postive value will disable auto for a while",
			type = "range",
			set = "SetValue",
			get = "GetValue",
			min = -100,
			max = 100,
			step = 0.2,
			bigStep  = 1,
			handler  = optionCallback,
			dialogHidden = true,
			width = "full",
		},
		target = {
			name = "Target number",
			order  = 4,
			desc = "The number of target. 1 for single target, while 3 for multi target.",
			type = "range",
			set = "SetValue",
			get = "GetValue",
			min = -1,
			max = 10,
			step = 1,
			bigStep  = 1,
			handler  = optionCallback,
			width = "full",
		},
		interval = {
			name = "Interval(in second)",
			order  = 5,
			desc = "The interval between each time addon update",
			type = "range",
			set = "SetValue",
			get = "GetValue",
			min = 0.0,
			max = 2,
			step = interval,
			bigStep  = interval,
			handler  = optionCallback,
			width = "full",
		},
	}
}

local default = {
	profile = {
		auto = true,
		interval = 0.1,
		target = 1,
		cd = 60,
	}
}

function AirjAutoKey:OnInitialize()
	-- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("AirjAutoKeyDB",default,true)
	-- Print a message to the chat frame
	self:Print("Loaded")
	self.fcnData = {}
	self.timerId = {}
	self.beHitList = {}
	self.aoeSpellHit = {}
	self.damageList = {}
	self.damageListSwing = {}
	self.damageListMelee = {}
	self.swingTime = {}
	self.channelTime = {}
	self.castSentList = {}
	self.castSuccessList = {}
	self.allCastSuccessList = {}
	self.castStartList = {}
	self.allCastStartList = {}
	self.drList = {}
	self.auraList = {}
	self.dotList = {}
	self.powerList = {}
	self.lastSentList = {}
	self.lastSentUnitList = {}
	self.notinsight = {}
	self.isHealer = {}
	self.helpCasting = {}
	self.harmCasting = {}
	self.kickSpells = {}

	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	local AceConfig = LibStub("AceConfig-3.0")
	AceConfig:RegisterOptionsTable("AirjAutoKey", options, {"aak", "AirjAutoKey"});
	local AceConfigDialog =  LibStub("AceConfigDialog-3.0")
	AceConfigDialog:AddToBlizOptions("AirjAutoKey","AirjAutoKey")

--	self:CreateCommunicateFrame()
	AirjAutoKey.getDefaultDataBaseFcn = {};
--	self:CreateButtons()
--	self:LoadDefaultBinding()
	self:SecureHook("UseAction", function(slot, target, button)
		local value = -0.5;
		if self.auto then
			if self.once == nil and self.oldauto == nil then
				self.oldauto = self.auto
			end
			if not self.once then
				self.once = -value
				self.auto = false
			end
		elseif self.once then
			self.once = -value
		end
	end)

	for i = 1,20 do
--		_G["BINDING_NAME_AAK_ACTIONBUTTON"..i] = "AirjAutoKeyNeeded"..i
	end

	self.timer1sec = self:ScheduleRepeatingTimer(function()
		self:TimerCallback()
	end,0.2)

	self.goto = {}
	self.moveTimer = self:ScheduleRepeatingTimer(function()
		self:MoveTimer()
	end,0.01)

	local selectedRotationIndex = self.db.profile.selectedRotationIndex
	local newIndex = #self.rotationDataBaseArray or 0
	local customRotation
	for k,v in ipairs(self.db.profile.rotationDataBaseArray or {}) do
		if not v.isDefault then
			local index = self:RegisterRotationDB(v)
			if k == selectedRotationIndex then
				newIndex = index
				customRotation = true
			end
		end
	end
	self.db.profile.rotationDataBaseArray = self.rotationDataBaseArray
	if customRotation then
		self:SelectRotationDB(newIndex)
	else
		self:SelecDefaultRotationDB()
	end
	if not self.selectedIndex then
		self:SelectRotationDB(1)
	end

	self.DRData = LibStub("DRData-1.0")
end
function AirjAutoKey:RestartTimer()
	self:CancelTimer(self.mainTimer,true)
	self.mainTimer = self:ScheduleRepeatingTimer(function()
		pcall(self.OnUpdate,self,interval)
	end,interval)
end

function AirjAutoKey:OnEnable()
	-- Called when the addon is enabled

	-- Print a message to the chat frame
	self:Print("Enable")

	self:SetConfigValue("auto",self.db.profile.auto)
	self:SetConfigValue("interval",self.db.profile.interval)
	self:SetConfigValue("target",self.db.profile.target)
	self:SetConfigValue("cd",self.db.profile.cd)
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")

	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	self:RegisterEvent("UI_ERROR_MESSAGE")


	self:RegisterMessage("HHTD_HEALER_BORN");

	self.mainTimer = self:ScheduleRepeatingTimer(function()
		pcall(self.OnUpdate,self,interval)
	end,interval)
--	self.communicateFrame:Show();
--	self.communicateFrame:SetScript("OnUpdate",function(self,elapsed)
--		AirjAutoKey:OnUpdate(elapsed)
--	end)
	self:LoadAutoRotation()
	self.lastUpdate = GetTime()
	-- self:RegisterEvent("UPDATE_BINDINGS")
--	self:AIRJAUTOKEY_NEW_DATABASE()

	self:RegisterComm("AAK_CASTING")
	self:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
	self:RegisterChatCommand("aakm", function(str,...)
		local args = {strsplit(" ",str)}
		if args[1] and UnitExists(args[1]) then
			self:KeepFollowUnit(args[1])
			if args[2] then
				self:KeepFacingUnit(args[2])
			end
		else
			self:KeepGoToStop()
		end
	end)
	self:RegisterChatCommand("aakf", function(str,...)
		local frame = GetMouseFocus()
		local text = frame:GetName() or ""
		print(text)
		ChatFrame1EditBox:Show()
		ChatFrame1EditBox:SetText(text)
	--	ChatFrame1EditBox:SetFocus()
		ChatFrame1EditBox:HighlightText()
	end)

	self:RemapSpells()
	self.drSpells = self.DRData.GetSpells()
end

function AirjAutoKey:OnDisable()
	-- Called when the addon is disabled
	self:Print("Disabled")

	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("UNIT_SPELLCAST_SENT")
	self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	-- self:RegisterEvent("UPDATE_BINDINGS")
--	self.communicateFrame:Hide();
--	self.communicateFrame:SetScript("OnUpdate",nil)
	self:CancelTimer(self.timer1sec)
end

local bgNames0 = {
}
local bgNames1 = {
}

function AirjAutoKey:UPDATE_BATTLEFIELD_SCORE()
	local numScore = GetNumBattlefieldScores()

	wipe(bgNames0)
	wipe(bgNames1)

	for i = 1, numScore do
		local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange, preMatchMMR, mmrChange, talentSpec = GetBattlefieldScore(i)
		if faction == 0 then
			tinsert(bgNames0,name)
		else
			tinsert(bgNames1,name)
		end
	end
end

local bgTargetIndex

function AirjAutoKey:FocusNextBGtarget()
	local faction = GetBattlefieldArenaFaction()
	local tab
	if faction == 1 then
		tab = bgNames0
	else
		tab = bgNames1
	end
	bgTargetIndex = bgTargetIndex or 1
	if tab[bgTargetIndex] then
		self:FocusByName(tab[bgTargetIndex])
--		print(tab[bgTargetIndex])
	end
	bgTargetIndex = bgTargetIndex + 1
	if bgTargetIndex > #tab then
		bgTargetIndex = 1
	end
end

function AirjAutoKey:FocusByName(name)
	local guid = UnitGUID("target")
	RunMacroText("/targetexact "..name.."\n".."/focus")
	if guid ~= UnitGUID("target") then
		RunMacroText("/targetlasttarget")
	end
end


function AirjAutoKey:OnCommReceived(prefix,data,channel,sender)
	local match, tab = self:Deserialize(data)
	if not match then return end
	local guid = tab.guid
	local list = tab.type=="harm" and self.harmCasting or self.helpCasting
	list[guid] = list[guid] or {}
	list[guid][tab.spell] = GetTime()
end
AirjAutoKey.kickCooldown = {
	["脚踢"] = 15,
	["拳击"] = 15,
	["责难"] = 15,
	["心灵冰冻"] = 15,
	["锁喉手"] = 15,
	["迎头痛击"] = 15,
	["法术反制"] = 24,
	["法术封锁"] = 24,
	["眼棱爆炸"] = 24,
	["反制射击"] = 24,
	["风剪"] = 12,
}

AirjAutoKey.castProperty = {
	["脚踢"] = 10,
	["拳击"] = 20,
	["责难"] = 30,
	["心灵冰冻"] = 40,
	["锁喉手"] = 50,
	["迎头痛击"] = 60,
	["法术反制"] = 70,
	["法术封锁"] = 80,
	["风剪"] = 90,
	["反制射击"] = 100,
	["群体反射"] = 110,
	["根基图腾"] = 120,
	["法术反射"] = 130,
	["奥术洪流"] = 140,
	["深度冻结"] = 150,
}
function AirjAutoKey:SendCasting(unit,spell,isHelp)
	local type = isHelp and "help" or "harm"
	local tab = {
		type = type,
		guid = UnitGUID(unit) or "",
		spell = spell,
	}
	self:SendCommMessage("AAK_CASTING",self:Serialize(tab),"PARTY",nil,"ALERT")
	self:OnCommReceived("AAK_CASTING",self:Serialize(tab))
end


function AirjAutoKey:HHTD_HEALER_BORN(event,isFriend, record)
	--dump(record)
	self.isHealer[record.guid] = record.isTrueHeal or nil
end


--function AirjAutoKey:Getkeybinds()
--	if InCombatLockdown() then UpdateWhileCombat = true return end
--	if self.macroArray then
--		self.keyArray = self:SyncButtonAttribute(self.macroArray); -- test GetSpecialization()]);
--	else
--		self.keyArray = {};
--	end
--end

function AirjAutoKey:UI_ERROR_MESSAGE(event,msg)
	if msg == "你必须位于目标背后。" then
		self.backtime = GetTime()
	end
end
local guids = {}
local units = {}
local subUnit = {"","target","pet","pettarget"}
local function getUnitCheckList()
	local unitCheckList = {"player","target","targettarget","pet","pettarget","focus","focustarget","mouseover","mouseovertarget"}
	for i = 1,5 do
		tinsert(unitCheckList,"arena"..i)
	end
	if IsInRaid() then
		for i = 1,GetNumGroupMembers() do
			for _,sub in pairs(subUnit) do
				tinsert(unitCheckList,"raid"..i..sub)
			end
		end
	else
		for _,sub in pairs(subUnit) do
			--tinsert(unitCheckList,"player"..sub)
			for i = 1,GetNumGroupMembers() do
				tinsert(unitCheckList,"party"..i..sub)
			end
		end
	end
	return unitCheckList
end

local name2unit = {}
local function findUnitByName(name)
	local unit = name2unit[name]
	if unit and UnitName(unit)==name then
		return unit
	end
	for _,u in ipairs(getUnitCheckList()) do
		local n = UnitName(u)
		if n then
			name2unit[n] = u
			if n == name then
				return u
			end
		end
	end
end

local guid2unit = {}
local function findUnitByGUID(guid)
	local unit = guid2unit[guid]
	if unit and UnitGUID(unit)==guid then
		return unit
	end
	for _,u in pairs(getUnitCheckList()) do
		local g = UnitGUID(u)
		if g then
			guid2unit[g] = u
			if g == guid then
				return u
			end
		end
	end
end

function AirjAutoKey:FindUnitByGUID(guid)
	return findUnitByGUID(guid)
end


local sendLineID
local sendUnit

function AirjAutoKey:UNIT_SPELLCAST_SENT(event,unitID, spell, rank, target, lineID)
	if unitID == "player" then
		local spellName = spell
		local lslunit
		self.castSentList[spellName] = GetTime()
		self.lastCastUnitName = target
--		local unitList = {}
--
--		for i = 1,5 do
--			tinsert(unitList,"arena"..i)
--		end
--		for i = 1,4 do
--			tinsert(unitList,"party"..i)
--		end
--		for i = 1,40 do
--			tinsert(unitList,"raid"..i)
--		end
--		tinsert(unitList,"focus")
--		tinsert(unitList,"targettarget")
--		tinsert(unitList,"mouseover")
--		tinsert(unitList,"target")
--		tinsert(unitList,"party")
		local eName = strsplit("-",target)
		local unit = findUnitByName(eName)
		if unit then
			self.lastCastSendUnit = unit
			self.lastCastSendTime = GetTime()
			self.lastCastSendName = UnitName(unit)
			sendLineID  = lineID
			sendUnit = unit
			lslunit = unit
			self.lastCastSendGUID = UnitGUID(unit)
		end
		self.lastSentList[spellName] = UnitGUID(lslunit or target or "player") or UnitGUID("player")
		self.lastSentUnitList[spellName] = lslunit
	end
end

function AirjAutoKey:UNIT_SPELLCAST_FAILED(event,unitID, spell, rank, lineID, spellID)
	if unitID == "player" then
		local spellName = spell
		self.castStartList[spellName] = self.castStartList[spellName] or {}
--		self.castStartList[spellName][self.castStartGUID] = nil
		if sendLineID == lineID then
			if sendUnit then
				local guid = UnitGUID(sendUnit)
				if guid then
					self.notinsight[guid] = GetTime();
				end
			end
		end
	end
end

function AirjAutoKey:IsMeleeSpell(spell)
	local meleeList = {
		--武器
		["致死打击"] = true,
		["巨人打击"] = true,
		["旋风斩"] = true,
		["剑刃风暴"] = true,
		["斩杀"] = true,
		--狂暴
		["狂风打击"] = true,
		["嗜血"] = true,
		--冰
		["冰霜打击"] = true,
		["湮灭"] = true,
		--邪
		["天谴打击"] = true,
		--血
		["灵界打击"] = true,
		--惩戒
		["十字军打击"] = true,
		["圣殿骑士的裁决"] = true,
		["最终审判"] = true,
		["神圣风暴"] = true,
		--增强
		["风暴打击"] = true,
		["熔岩猛击"] = true,
		--刺杀
		["毒伤"] = true,
		["斩击"] = true,
		["毁伤"] = true,
		--敏锐
		["伏击"] = true,
		["背刺"] = true,
		["刺骨"] = true,
		--战斗
		["影袭"] = true,
		["要害打击"] = true,
		--野
		["撕碎"] = true,
		["斜掠"] = true,
		["凶猛撕咬"] = true,
		["割碎"] = true,
	}
	return meleeList[spell]
end


function AirjAutoKey:GetCooldown(spell)
	local spellList = {
		["深度冻结"] = true,
		["冰冻陷阱"] = true,
	}
end

function AirjAutoKey:COMBAT_LOG_EVENT_UNFILTERED(realEvent,timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,...)
	timestamp = GetTime()



	if (strfind(event, "SWING_DAMAGE") or strfind(event, "SWING_MISSED")) then
		self.beHitList[destGUID] = self.beHitList[destGUID] or {}

		self.beHitList[destGUID][sourceGUID] = timestamp
	end

	if (strfind(event, "SPELL_DAMAGE") or strfind(event, "SPELL_MISSED")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID)  then
		local spellName = select(2,...)
		if spellName then
			if spellName == "刀扇" or spellName == "剑刃乱舞" then
				if GetTime() -( self.daoshanTimestamp or 0 ) <0.9 then
					self.daoshanCnt =  self.daoshanCnt + 1
				else
					self.daoshanCnt = 1
				end
				self.daoshanTimestamp = GetTime()
			end
			self.aoeSpellHit[spellName] = self.aoeSpellHit[spellName] or {}
			self.aoeSpellHit[spellName].guids  =  self.aoeSpellHit[spellName].guids or {}
			if GetTime() -( self.aoeSpellHit[spellName].timestamp or 0 ) < 0.9 then
			else
				wipe(self.aoeSpellHit[spellName].guids)
				self.aoeSpellHit[spellName].timestamp = GetTime()
			end
			self.aoeSpellHit[spellName].guids[destGUID] = GetTime()
		end
	end


	-- damage stuff
	if strfind(event, "_DAMAGE") and destGUID then
		local amount
		local offset
		if strfind(event, "SWING") then
			offset = 0
		else
			offset = 3
		end
		local arg1 = select(1+offset,...)
		amount = (type(arg1)=="number" and arg1 or 0) + (select(4+offset,...) or 0) + (select(5+offset,...) or 0) + (select(6+offset,...) or 0)
		self.damageList[destGUID] = self.damageList[destGUID] or {}
		self.damageList[destGUID][timestamp] = (self.damageList[destGUID][timestamp] or 0) + amount

		local spellName = select(2,...)
		if self:IsMeleeSpell(spellName) then
			self.damageListMelee[destGUID] = self.damageListMelee[destGUID] or {}
			self.damageListMelee[destGUID][timestamp] = (self.damageListMelee[destGUID][timestamp] or 0) + amount
		end
	end
	if strfind(event, "SWING_DAMAGE") and destGUID then
		local amount
		local offset
		if strfind(event, "SWING") then
			offset = 0
		else
			offset = 3
		end
		local arg1 = select(1+offset,...)
		amount = (type(arg1)=="number" and arg1 or 0) + (select(4+offset,...) or 0) + (select(5+offset,...) or 0) + (select(6+offset,...) or 0)
		self.damageListSwing[destGUID] = self.damageListSwing[destGUID] or {}
		self.damageListSwing[destGUID][timestamp] = (self.damageListSwing[destGUID][timestamp] or 0) + amount
		self.damageListMelee[destGUID] = self.damageListMelee[destGUID] or {}
		self.damageListMelee[destGUID][timestamp] = (self.damageListMelee[destGUID][timestamp] or 0) + amount
	end
	if (strfind(event, "_MISSED") and (select(1,...)=="ABSORB")) and destGUID then
		local amount
		local offset
		if strfind(event, "SWING") then
			offset = 0
		else
			offset = 3
		end
		amount = (select(3 + offset,...) or 0)
		self.damageList[destGUID] = self.damageList[destGUID] or {}
		if type(amount) ~= "number" then
			amount = 0;
		end

		self.damageList[destGUID][timestamp] = (self.damageList[destGUID][timestamp] or 0) + amount
	end

	--swing stuff
	if strfind(event, "SWING") and sourceGUID then
		self.swingTime[sourceGUID] = timestamp
	end

	-- channel stuff
	if strfind(event, "_DAMAGE") and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID)  then
		local spellName = select(2,...)
		local spellId = select(1,...)
		if spellName then
			local channelName = UnitChannelInfo("player")
			if spellName == channelName then
				self.channelTime[spellName] = timestamp
			--	print("吸取灵魂",GetTime())
			end
			if spellId == 15407 then
				self.channelTime[spellName] = timestamp
			--	print("吸取灵魂",GetTime())
			end
		end
	end
	--cast success stuff
	if (strfind(event, "_CAST_SUCCESS")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID) then
		local spellName = select(2,...)
		if spellName then
			if not destGUID or destGUID == "" then
				destGUID = self.lastSentList[spellName]
			end
			if not destGUID then destGUID = UnitGUID("player") end
			if destGUID then
				self.castSuccessList[spellName] = self.castSuccessList[spellName] or {}
				self.castSuccessList[spellName][destGUID] = timestamp
--				print("castSuccessList",spellName)
			end
			self.allCastSuccessList[spellName] = timestamp
		end

		if self.debugmode then
			if self.lastSpellIndex ~= spellIndex then
				self:Print(GetTime(),"Casted --------- ",spellName)
				self.lastSpellIndex = spellIndex
			end
		end
	end

	--cast start stuff
	if (strfind(event, "_CAST_START")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID) then
		local spellName = select(2,...)
		if not destGUID or destGUID == "" then
			destGUID = self.lastSentList[spellName]
		end
--		print(spellName,destGUID,UnitGUID("target"))
		if destGUID and spellName then
			self.castStartList[spellName] = self.castStartList[spellName] or {}
			self.castStartList[spellName][destGUID] = timestamp
		end
		self.allCastStartList[spellName] = timestamp
		self.castStartGUID = destGUID
		self.lastCastUnit=self.lastCastSendUnit
		self.lastCastGUID=self.lastCastSendGUID
--		print(spellName,self.lastCastUnit,self.lastCastGUID)
	end

	-- aura stuff
	if (strfind(event, "_AURA_APPLIED") or strfind(event, "_AURA_REFRESH")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID) then
		local spellName = select(2,...)
		self.auraList[spellName] = self.auraList[spellName] or {}
		self.auraList[spellName][destGUID] = timestamp

		self.dotList[spellName] = self.dotList[spellName] or {}
		self.dotList[spellName][destGUID] = timestamp
	end
	if (strfind(event, "_AURA_BROKEN") or strfind(event, "_AURA_REMOVED")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID) then
		local spellName = select(2,...)
		if destGUID and spellName then
			self.auraList[spellName] = self.auraList[spellName] or {}
			self.auraList[spellName][destGUID] = nil
			self.dotList[spellName] = self.dotList[spellName] or {}
			self.dotList[spellName][destGUID] = nil
		end
	end
	--dot stuf

	if (strfind(event, "SPELL_PERIODIC_DAMAGE")) and (UnitGUID("player") == sourceGUID or UnitGUID("pet") == sourceGUID) then
		local spellName = select(2,...)
		self.dotList[spellName] = self.dotList[spellName] or {}
		self.dotList[spellName][destGUID] = timestamp
	end

	-- dotPower stuff
--	if (strfind(event, "_CAST_SUCCESS") or strfind(event, "_AURA_APPLIED") and not strfind(event, "_AURA_APPLIED_DOSE") or strfind(event, "_AURA_REFRESH")) and UnitGUID("player") == sourceGUID then
--		local spellName = select(2,...)
--		local spellid = select(1,...)
--		if spellid == 119678 or spellid == 86213 then
--			spellName = "痛楚"
--		end
--		if destGUID and spellName then
--			self.powerList[spellName] = self.powerList[spellName] or {}
--			self.powerList[spellName][destGUID] = {timestamp = timestamp, power = self.CurrentPower()}
--		end
--	end
--	if (strfind(event, "_AURA_BROKEN") or strfind(event, "_AURA_REMOVED")) and UnitGUID("player") == sourceGUID then
--		local spellName = select(2,...)
--		if destGUID and spellName then
--			self.powerList[spellName] = self.powerList[spellName] or {}
--			self.powerList[spellName][destGUID] = nil
--		end
--	end

	if (strfind(event, "_ENERGIZE") and sourceGUID == UnitGUID("player")) then
		local spellName = select(2,...)
		if spellName == "刺客的尊严" then
			self.lastZunYan = GetTime()
		end
	end
	if (strfind(event, "_AURA_BROKEN_SPELL")) then
		local spellList = {
			["变形术"] = true,
			["致盲"] = true,
			["凿击"] = true,
			["闷棍"] = true,
		}
		local spellName = select(2,...)
		if spellList[spellName] then
			local brokeName = select(5,...)
			local type = select(7,...)
			local pre = ""
			if sourceGUID == UnitGUID("player") then
				pre = "YOU_______"
			end
			if type == "DEBUFF" then
				print(pre.."BROKEN:"..spellName.." of "..destName.." by "..sourceName.."'s "..brokeName)
			end
		end
	end


	--cas


	-- dr
	if (strfind(event, "_AURA_APPLIED") or strfind(event, "_AURA_REFRESH")) then
		local spellId = select(1,...)
		local type = select(4,...)
		local cat = self.drSpells[spellId]
		if type == "DEBUFF" and cat then
			self.drList[destGUID] = self.drList[destGUID] or {}
			local data = self.drList[destGUID][cat]
			local count
			if data and data.timestamp > timestamp then
				count = data.count + 1
			else
				count = 1
			end
			self.drList[destGUID][cat] = {timestamp = timestamp+18.5, count = count}
		end
	end
	if (strfind(event, "_AURA_BROKEN") or strfind(event, "_AURA_REMOVED"))then
		local spellId = select(1,...)
		local type = select(4,...)
		local cat = self.drSpells[spellId]
		if type == "DEBUFF" and cat then
			self.drList[destGUID] = self.drList[destGUID] or {}
			local data = self.drList[destGUID][cat]
			local count
			if data and data.timestamp > timestamp then
				count = data.count
			else
				count = 1
			end
			self.drList[destGUID][cat] = {timestamp = timestamp+18.5, count = count}
		end
	end
end

function AirjAutoKey:RecoverDamageList()
	local currentTime = GetTime()
	for guid,dls in pairs(self.damageList) do
		local hasElement
		for timestamp,damage in pairs(dls)do
			if currentTime - timestamp > 120 then
				dls[timestamp] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.damageList[guid] = nil
		end
	end
end
function AirjAutoKey:RecoverDamageListSwing()
	local currentTime = GetTime()
	for guid,dls in pairs(self.damageListSwing) do
		local hasElement
		for timestamp,damage in pairs(dls)do
			if currentTime - timestamp > 120 then
				dls[timestamp] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.damageListSwing[guid] = nil
		end
	end
end

function AirjAutoKey:RecoverDamageListMelee()
	local currentTime = GetTime()
	for guid,dls in pairs(self.damageListMelee) do
		local hasElement
		for timestamp,damage in pairs(dls)do
			if currentTime - timestamp > 120 then
				dls[timestamp] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.damageListMelee[guid] = nil
		end
	end
end
function AirjAutoKey:RecoverSwtingTime()
	local currentTime = GetTime()
	for guid,timestamp in pairs(self.swingTime) do
		if currentTime - timestamp > 120 then
			self.swingTime[guid] = nil
		end
	end
	for desc,data in pairs(self.beHitList) do
		local hasElement
		for source,timestamp in pairs(data) do
			if currentTime - timestamp > 30 then
				data[source] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.beHitList[desc] = nil
		end
	end
end

function AirjAutoKey:RecoverCastSend()
	local currentTime = GetTime()
	for spellName,timestamp in pairs(self.castSentList) do
		if currentTime - timestamp > 120 then
			self.castSentList[spellName] = nil
		end
	end
end
function AirjAutoKey:RecoverCastSuccess()
	local currentTime = GetTime()
	for spellName,data in pairs(self.castSuccessList) do
		local hasElement
		for guid, timestamp in pairs(data) do
			if currentTime - timestamp > 120 then
				data[guid] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.castSuccessList[spellName] = nil
		end
	end
end
function AirjAutoKey:RecoverCastStart()
	local currentTime = GetTime()
	for spellName,data in pairs(self.castStartList) do
		local hasElement
		for guid, timestamp in pairs(data) do
			if currentTime - timestamp > 120 then
				data[guid] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.castStartList[spellName] = nil
		end
	end
end
function AirjAutoKey:RecoverAura()
	local currentTime = GetTime()
	for spellName,data in pairs(self.auraList) do
		local hasElement
		for guid, timestamp in pairs(data) do
			if currentTime - timestamp > 60 then
				data[guid] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.auraList[spellName] = nil
		end
	end
end
function AirjAutoKey:RecoverDOT()
	local currentTime = GetTime()
	for spellName,data in pairs(self.dotList) do
		local hasElement
		for guid, timestamp in pairs(data) do
			if currentTime - timestamp > 3 then
				data[guid] = nil
			else
				hasElement = true
			end
		end
		if not hasElement then
			self.dotList[spellName] = nil
		end
	end
end
--function AirjAutoKey:RecoverPower()
--	local currentTime = GetTime()
--	for spellName,data in pairs(self.powerList) do
--		local hasElement
--		for guid, v in pairs(data) do
--			local timestamp = v.timestamp or 0
--			if currentTime - timestamp > 120 then
--				data[guid] = nil
--			else
--				hasElement = true
--			end
--		end
--		if not hasElement then
--			self.powerList[spellName] = nil
--		end
--	end
--end

--function AirjAutoKey:CurrentPower()
--	local crit = GetCritChance(6)
--	local minDamage, maxDamage = UnitDamage("player")
--	local spellCrit = GetSpellCritChance(6)
--	local spellPower = GetSpellBonusDamage(6)
--	local maste = GetMastery()
--	local spellHaste = UnitSpellHaste("player")
--	return 0
--end
--
--function AirjAutoKey:UpdatePower()
--	local currentPower = self:CurrentPower()
--	if not self.averagePower then
--		self.averagePower = currentPower
--	else
--		self.averagePower = self.averagePower + (currentPower - self.averagePower) * 0.01
--	end
--end

function AirjAutoKey:TimerCallback()
	self:RecoverDamageList()
	self:RecoverDamageListSwing()
	self:RecoverDamageListMelee()
	self:RecoverSwtingTime()
	self:RecoverCastSend()
	self:RecoverCastSuccess()
	self:RecoverCastStart()
	self:RecoverAura()
	self:RecoverDOT()
--	self:RecoverPower()
--	self:UpdatePower()
	self:UpdateHealth()
	if GetTime() - self.lastUpdate > 0.5 then
		self:RestartTimer()
	end
end

function AirjAutoKey:LoadAutoRotation()
	local selfspec = GetSpecializationInfo(GetSpecialization() or 0) or 0
	for k,rotation in pairs(self.rotationDataBaseArray) do
		if rotation.autoSwap then
			if  floor(selfspec - rotation.spec+0.5) == 0 then
				self:SelectRotationDB(k)
				break;
			end
		end
	end
--	self:Getkeybinds()
end

function AirjAutoKey:PLAYER_SPECIALIZATION_CHANGED()
	self:LoadAutoRotation()
end

function AirjAutoKey:IsModKeyPressed()
	local modstring = ""
	local modFcn = {
		"IsLeftAltKeyDown",
		"IsLeftControlKeyDown",
		"IsLeftShiftKeyDown",
		"IsRightAltKeyDown",
		"IsRightControlKeyDown",
		"IsRightShiftKeyDown",
	}
	local pressed = false
	for k, v in pairs(modFcn) do
		local fcn = _G[v]
		local str = strsub(v,3,-8)
		if fcn() then
			self[str] = (self[str] or 0) + self.elapsed
			if self[str] > 1 then
				if modstring ~= "" then
					modstring = modstring .. " - "
				end
				modstring = modstring .. str
				self[str] = 0
			end
			pressed = true
		else
			self[str] = 0
		end
	end
	if modstring == "" then
		return pressed,nil
	else
		return pressed,modstring.." Pressed."
	end
end

function AirjAutoKey:UpdateHealth()
	--TBD
	self.healthList = self.healthList or {}
	local myHealth = self.healthList
	local currentTime = GetTime()
	for k,v in pairs(myHealth) do
		if k< currentTime-120 then
			myHealth[k] = nil
		end
	end
	local maxhealth = UnitHealthMax("player")
	myHealth[currentTime] = maxhealth >0 and UnitHealth("player")/maxhealth or 1

	self.speedList = self.speedList or {}
	local speedList = self.speedList
	local currentTime = GetTime()
	for k,v in pairs(speedList) do
		if k< currentTime-120 then
			speedList[k] = nil
		end
	end
	local speed = GetUnitSpeed("player")
	speedList[currentTime] = speed
end

function AirjAutoKey:OnceTimeCalculate()
	if self.once then
		self.once = self.once - self.elapsed
		if self.once<0 then
			if self.oldauto ~= nil then
				self.auto = self.oldauto
				self.oldauto = nil
			end
			self.once = nil
		end
	end
end

function AirjAutoKey:IsMeetTargetNum(spell)
	return (not spell.tarmin or spell.tarmin and spell.tarmin <= self.target) and (not spell.tarmax or spell.tarmax and spell.tarmax >= self.target)
end

function AirjAutoKey:IsMeetCooldown(spell,spellId)
end

--function AirjAutoKey:Key2Num(string)
--	local keylist = self.keylist
--	local num = keylist[string]
--	if not num then
--		if strlen(string) > 1 then
--			num = 0
--		else
--			num = strbyte(strupper(string))
--		end
--	end
--	do
--		return num or 0
--	end
--end

local function copyNoAirFilter(filter)
	local newFilter = {}
	for i,v in ipairs (filter) do
		if v.group or v.type and (v.type == "GROUP") then
--			tinsert(newFilter,copyNoAirFilter(v))
--			newFilter[#newFilter].type = "GROUP"
--			newFilter[#newFilter].value = v.value
--			newFilter[#newFilter].oppo = v.oppo
		else
			if v.unit ~= "air" and v.unit ~= "airtarget" then
				tinsert(newFilter,v)
			end
		end
	end
	return newFilter
end

function AirjAutoKey:GetUnitListByAirType(anyinraid)
	unitList = {"target","mouseover","player","targettarget","focus","pet","pettarget"};
	if anyinraid == "help" then
		if not IsInRaid() then
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i)
			end
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i.."pet")
			end
		else
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"raid"..i)
			end
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"raid"..i.."pet")
			end
		end
	elseif anyinraid == "pveharm" then
		for i = 1,5 do
			tinsert(unitList,"boss"..i)
		end
	elseif anyinraid == "pvpharm" then
		for i = 1,5 do
			tinsert(unitList,"arena"..i)
		end
		for i = 1,5 do
			tinsert(unitList,"arena".."pet"..i)
		end
		if not IsInRaid() then
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i.."target")
			end
		else
			for i = 1,15 do
				tinsert(unitList,"raid"..i.."target")
			end
		end
	elseif anyinraid == "arena" then
		for i = 1,5 do
			tinsert(unitList,"arena"..i)
		end
		for i = 1,5 do
			tinsert(unitList,"arena".."pet"..i)
		end
	else
		if not IsInRaid() then
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i)
			end
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i.."pet")
			end
		else
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"raid"..i)
			end
		end
		for i = 1,5 do
			tinsert(unitList,"boss"..i)
		end
		for i = 1,5 do
			tinsert(unitList,"arena"..i)
		end
		for i = 1,5 do
			tinsert(unitList,"arena"..i.."pet")
		end
		if not IsInRaid() then
			for i = 1,GetNumGroupMembers() do
				tinsert(unitList,"party"..i.."target")
			end
		else
			for i = 1,15 do
				tinsert(unitList,"raid"..i.."target")
			end
		end
	end
	return unitList
end

function AirjAutoKey:GetCurrentSpellInfo(spellArray)
	for spellIndex, spell in ipairs(spellArray) do
		if not spell.disable then
			if self:IsMeetTargetNum(spell) then
				local spellKey = spell.spell
				local spellId = spell.spellId
				if not spellId then
					_, spellId = spellKey and GetSpellBookItemInfo(spellKey)
					spellId = spellId or spellKey
					spell.spellId = spellId
				end
				local spellName = spell.spellName
				if not spellName then
					spellName = GetSpellInfo(spellKey) or spellKey
					spell.spellName = spellName
				end
				local spellCD = spell.cd
				if not spellCD and spellId then
					spellCD = GetSpellBaseCooldown(spellId) or 0
					spell.cd = spellCD/1000
				end
				if not spellCD or spellCD < self.cd then
					local filterArray = spell.filter
					if spell.anyinraid and not self.raidUnit then
						self.preFilter = self.preFilter or {}
						wipe(self.preFilter)
						self.preFilter = copyNoAirFilter(filterArray)
						if self:CheckFilters(self.preFilter) then
							local unitList = self:GetUnitListByAirType(spell.anyinraid)
							local maxUnit
							local maxValue = -1000000000
							local checked = {}
							for i,unit in ipairs(unitList) do
								if self:PassPreCheck(unit) then
									local guid = UnitGUID(unit)
									if not checked[guid] then
										checked[guid] = true
										self.raidUnit = unit
										self.airCurrent = nil
										if self:CheckFilters(filterArray) then
											if not self.airCurrent then
												self.maxUnit = unit
												self:PassFilters(spellIndex,spell,spellId,spellName,unit)
												if self.found then
													return
												end
												if not spell.group then
													break
												end
											elseif self.airCurrent > maxValue then
												maxValue = self.airCurrent
												maxUnit = unit
											end
										end
										self.raidUnit = nil
									end
								end
							end
							if maxUnit then
								self.maxUnit = maxUnit
								self:PassFilters(spellIndex,spell,spellId,spellName,maxUnit)
								if self.found then
									return
								end
							end
						end
					else
						if self:CheckFilters(filterArray) then
							self:PassFilters(spellIndex,spell,spellId,spellName,self.raidUnit)
							if self.found then
								return
							end
						end
					end
				end
			end
		end
	end
end

function AirjAutoKey:PassPreCheck(unit)
	local needF,needT = UnitInRange(unit)
	return UnitExists(unit) and not (needF == false and needT==true) and ((GetTime() - (self.notinsight[UnitGUID(unit)] or 0))>1)
end

function AirjAutoKey:PassFilters(spellIndex,spell,spellId,spellName,unit)
	self.passedSpell[tostring(spell)] = unit or true
	if spell.group then
		self.raidUnit = unit
		self:GetCurrentSpellInfo(spell)
		self.raidUnit = nil
		if spell.continue then
			self.found = nil
		end
		return
	end
	self.raidUnit = nil
	if (not spell.continue) then
		self.found = true
	end
	local keyIndex = spell.spell;
	local macrotext = self:GetSpellMacroText(self.macroArray,keyIndex)
	if unit and macrotext then
		macrotext = string.gsub(macrotext,"/cast ","/cast [@"..unit.."]")
		macrotext = string.gsub(macrotext,"_air_",unit)
		macrotext = string.gsub(macrotext,"air",unit)
	end
	if self.debugmode then
		if self.lastSpellIndex ~= spellIndex and not spell.continue then
			self:Print(GetTime(),spellIndex,spell.spell,macrotext)
			self.lastSpellIndex = spellIndex
		end
	end
--		local spellTexture = GetSpellTexture(spell.icon or "") or spell.icon or GetSpellTexture(spellName) or "Interface\\Icons\\INV_Misc_QuestionMark"
--		return spell.spell,num, macrotext, spellId, spellTexture
	self.currentMacrotext = macrotext
	self.currentSpellID = spellId
	self.currentSpellUnit = unit
	if macrotext then
		if _G["GetGu".."ildInfo"]("player") == "\232\165\191\231\147\156\229\149\134\229\159\142" or true then
			local success,msg = pcall(RunMacroText,macrotext)
			if not success then
--				print(msg)
			end
		end
	end
end

function AirjAutoKey:CheckSpellTextureChanged(spellTexture,spellId)
	local start, duration
	if spellId then
		start, duration = GetSpellCooldown(spellId)
	end
	start = start or 0;
	duration = duration or 0;
	spellTexture = spellTexture or ""
	if self.lastSpellTexture and self.lastSpellTexture == spellTexture and self.lastRefreshTime and self.lastRefreshTime == start + duration then
		return
	end
	self.lastSpellTexture = spellTexture;
	self.lastRefreshTime = start + duration;
	self:SendMessage("AIRJAUTOKEY_SPELL_TEXTURE_CHANGED",spellId)
end

--function AirjAutoKey:RegisterKey(key,delay)
--	local keynum = self:Key2Num(key)
--	if keynum ~= 0 then
--		if self.priorityTimer then
--			self:CancelTimer(self.priorityTimer);
--		end
--		self.priorityTimer = self:ScheduleTimer("UnregisterKey", delay)
--		self.priorityKey = keynum
--	end
--end
--function AirjAutoKey:UnregisterKey(key)
--	if not key or self:Key2Num(key) ~= 0 and self.priorityKey and self.priorityKey == self:Key2Num(key) then
--		if self.priorityTimer then
--			self:CancelTimer(self.priorityTimer);
--		end
--		self.priorityTimer = nil;
--		self.priorityKey = nil;
--	end
--end
function AirjAutoKey:OnUpdate(elapsed)
	self.passedSpell = self.passedSpell or {}
	wipe(self.passedSpell)
	local unit = "target"
	if UnitExists(unit) then
--		print("........",UnitGUID(unit),(GetTime() - (self.notinsight[UnitGUID(unit)] or 0)))
	end
--	self.elapsed = (self.elapsed or 0) + elapsed
--	-- print(self.elapsed, elapsed, AirjAutoKeyDB.updatetime)
--	if self.elapsed<self.interval then
--		return
--	end
--	if self.UpdateWhileCombat then
--		self:Getkeybinds()
--	end
	self.elapsed = (GetTime() - (self.lastUpdate or 0))
	self.lastUpdate = GetTime()
	self:OnceTimeCalculate()
	local modPressed, modString = self:IsModKeyPressed()
	if modString then
		self:Print(modString);
	end
--	self.elapsed = 0

	local spellArray = self.spellArray or {}
	self.currentMacrotext = nil
	self.currentSpellID = nil

		self.found = nil
		self.maxUnit = nil
		self.raidUnit = nil

	pcall(AirjAutoKey.GetCurrentSpellInfo,self,spellArray)
	--AirjAutoKey:GetCurrentSpellInfo(spellArray)
	local macrotext = self.currentMacrotext
	modPressed = nil
	self:SendMessage("AIRJAUTOKEY_SPELL_TEXTURE_CHANGED",self.currentSpellID)
--	if macrotext and macrotext~="" and not modPressed then
--		if _G["GetGu".."ildInfo"]("player") == "\232\165\191\231\147\156\229\149\134\229\159\142" or true then
--			local success,msg = pcall(RunMacroText,macrotext)
--			if not success then
--				print(msg)
--			end
--		end
--	end
--	self:CheckSpellTextureChanged(spellTexture,spellId)
end

function AirjAutoKey:CheckFilters(filters)
	local countToPass = filters.value or 0
	if countToPass <= 0 then
		countToPass = countToPass + #filters
	end
	local passedCount = 0
	local failedCount = 0
	for index, filter in ipairs(filters) do
		local toRet = true
		if filter.group or filter.type and (filter.type == "GROUP") then
			local passed
			local unitlist = filter.unit and self:GetUnitListByAirType(filter.unit)
			if unitlist then
				local tfilter = self:Copy(filter)
				tfilter.oppo = nil
				tfilter.unit = nil
				tfilter.value = nil
				tfilter.greater = nil
				tfilter.note = nil
				local count = 0
				local dones = {}
				for i,unit in ipairs(unitlist) do
					self.groupUnit = unit
					local key = unit and UnitGUID(unit)
					if key and not dones[key] then
						dones[key] = true
						if self:CheckFilters(tfilter) then
							count = count + 1
						end
					end
				end
				self.groupUnit = nil
				passed = count <= (filter.value or 0)
				if filter.greater then passed = not passed end
				if (filter.note == "debug") then
					dump({
						filter=filter,
						toRet=passed,
						raidUnit=self.raidUnit or "nil",
						groupUnit=self.groupUnit or "nil",
						count = count
					})
				end
			else
				passed = self:CheckFilters(filter)
			end
			if filter.oppo then passed = not passed end
			if not passed then
				toRet = false
			end
		else
			local status, filterRtn = pcall(self.CheckFilter,self,filter)
			if not status then
				toRet = false
			end
			local passed = filterRtn and true or false
			if filter.oppo then passed = not passed end
			if not passed then toRet = false end
		end
		if toRet then
			passedCount = passedCount + 1
		else
			failedCount = failedCount + 1
		end
		if passedCount >= countToPass then
			return true
		end
		if failedCount > #filters - countToPass then
			return false
		end
	end
	if passedCount >= countToPass then
		return true
	end
end

function AirjAutoKey:CheckFilter(filter)
	local toRet
	if filter.type == "GROUP" then
		toRet = self:CheckFilters(filter)
	else
		local airunit = filter.unit == "air" and self.raidUnit or filter.unit == "airtarget" and (self.raidUnit.."target") or filter.unit == "lcu" and (findUnitByGUID(self.lastCastGUID) or self.lastCastUnit)
		airunit = airunit or filter.unit == "bgu" and self.groupUnit
		local tfilter
		if airunit then
			tfilter= self:Copy(filter)
			tfilter.unit = airunit
		else
			tfilter = filter
		end
		toRet = self:CheckFilterOld(tfilter)
	end
	toRet = toRet and true or false
	if filter.note == "debug" then
		dump({
			filter=filter,
			toRet=toRet,
			raidUnit=self.raidUnit or "nil",
			groupUnit=self.groupUnit or "nil",
		})
	end
	return toRet
end

function AirjAutoKey:CheckFilterOld(filter)
	if self[filter.type] then
		return self[filter.type](self,filter)
	end
end


AirjAutoKey.filterTypes = {}
local filterTypes = AirjAutoKey.filterTypes

--function AirjAutoKey:CreateButtons()
--	for k = 1, 20 do
--		self:CreateButton(k)
--	end
--end

--function AirjAutoKey:CreateButton(k)
--	local button = _G["AirjAutoKeyButton"..k]
--	if button then return button end
--	AirjAutoKeyButtons = AirjAutoKeyButtons or {}
--	button = CreateFrame("Button", "AirjAutoKeyButton"..k, UIParent,"SecureActionButtonTemplate")
--	AirjAutoKeyButtons[k] = button
--	if k == 1 then
--		button:SetPoint("CENTER",UIParent,"TOPLEFT",30,220)
--	else
--		button:SetPoint("LEFT",_G["AirjAutoKeyButton"..(k-1)],"RIGHT",1,0)
--	end
--	button:SetSize(20,20)
--	button:SetBackdropColor(0,1,0)
--	button:SetAttribute("type","macro")
--	local texture = button:CreateTexture()
--	texture:SetAllPoints()
--	texture:SetTexture(0,0,0)
--	button.texture = texture
--	do
--		return button
--	end
--end

--function AirjAutoKey:LoadDefaultBinding()
--	local defaultBindings =
--		{
--			".",
--			",",
--			"'",
--			"",
--			"[",
--			"]",
--			"\\",
--			"-",
--			"=",
--			"BACKSPACE",
--			"0",
--			"9",
--			"8",
--			"NUMPADMULTIPLY",
--			"NUMPADDIVIDE",
--			"F11",
--			"F10",
--			"F9",
--			"F8",
--			"F7",
--			"F6",
--			"F5",
--			"7",
--			"6",
--			"5",
--			"INSERT",
--			"DELETE",
--			"HOME",
--			"END",
--			"PAGEUP",
--			"PAGEDOWN",
--			"LEFT",
--			"RIGHT",
--			"UP",
--			"DOWN",
--		}
--	local bi = 1
--	for i = 1,20 do
--		local key = GetBindingKey("AAK_ACTIONBUTTON"..i)
--		if not key then
--			while not key do
--				key = defaultBindings[bi]
--				if GetBindingByKey(key) then
--					key = nil
--				end
--				if bi >= #defaultBindings then
--					break
--				end
--				bi = bi + 1
--			end
--		end
--		if key then
--			SetBinding(key,"AAK_ACTIONBUTTON"..i)
--		end
--	end
--end
--
setfcn.once = function(self,value)
	if value >= 0 then
		if not self.auto then
			if self.once == nil and self.oldauto == nil then
				self.oldauto = self.auto
			end
			self.once = value
			self.auto = true
		elseif self.once then
			self.once = value
		end
		--			print("AirjAutoKey 将启动"..time.."秒")
	elseif value <= 0 then
		if self.auto then
			if self.once == nil and self.oldauto == nil then
				self.oldauto = self.auto
			end
			self.once = -value
			self.auto = false
		elseif self.once then
			self.once = -value
		end
		--			print("AirjAutoKey 将暂停"..(-time).."秒")
	end
end

setfcn.auto = function(self,value)
	if value then
		self.auto = true
	else
		self.auto = false
	end
	self.oldauto = nil
	self.once = nil
end

setfcn.burst = function(self,value,...)
	dump(value,...)
end


function AirjAutoKey:SetConfigValue(key, value, starter)
	if setfcn[key] then
		setfcn[key](self,value);
	else
		self[key] = value;
	end
	self.db.profile[key] = value;
	self:SendMessage("AIRJAUTOKEY_CONFIG_CHANGED",key,value, starter);
end

function AirjAutoKey:GetConfigValue(key)
	if getfcn[key] then
		return getfcn[key](self);
	else
		return self[key];
		end
end

function AirjAutoKey:GetSpellMacroText(macroArray,spell)
	if not spell or spell =="" then
		return
	end
	local v = macroArray[spell]
	if v and v~= "" then
		return v
	end
	if string.sub(spell,1,1) == "/" then
		return spell
	end
	local spellName = strsplit("_",spell or "")
	if type(tonumber(spellName)) == "number" then
		spellName = GetSpellInfo(spellName)
	end
	local castMacroText =  "/cast ".. spellName
	return castMacroText
end
--
--function AirjAutoKey:SyncButtonAttribute(macroArray)
--	self.UpdateWhileCombat = nil
--
--	local kb = {};
--	local index = 0
--	for k,v in pairs(macroArray) do
--		local key = nil
----		while not key do
----			if index >= 20 then
----				break
----			end
----			key=  ("AAK_ACTIONBUTTON"..(index+1))
----			index = index + 1
----		end
--		--key = string.lower(key)
----		local spellName = strsplit("_",k)
----		local macrotext = v ~= "" and v or "/cast ".. spellName
----		macrotext = string.gsub(macrotext,"spell",spellName)
--
--		local macrotext = self:GetSpellMacroText(macroArray,k)
----		if key then
----			local button = _G["AirjAutoKeyButton"..index] or self:CreateButton(index)
----			if button then
----				ClearOverrideBindings(button)
--	--			SetOverrideBindingClick(button,true,key,"AirjAutoKeyButton"..index)
--	--			button:SetAttribute("macrotext",macrotext)
--	--		end
----		end
--		kb[k] =
--		{
--			macrotext =  macrotext,
--			key = key,
--		}
--	end
--	return kb
--end

function AirjAutoKey:GetCheckFilterFcn(str)
	if not str then return end
	local fcn = loadstring("local fcn = "..str.." return fcn")
	if not fcn then return end
	return fcn()
end


function AirjAutoKey:RegisterRotationDB(db)
	tinsert(self.rotationDataBaseArray,db)
	return #self.rotationDataBaseArray
end

function AirjAutoKey:SelectRotationDB(index)
	local rdb = self.rotationDataBaseArray[index]
	if not rdb then return end
	self.rotationDB = rdb
	self.spellArray = rdb.spellArray;
	self.macroArray = rdb.macroArray;
	self.fcnArray = rdb.fcnArray
	self.eventArray = rdb.eventArray
	self.timerArray = rdb.timerArray
	local data = {}
	self:Unhook(self, "COMBAT_LOG_EVENT_UNFILTERED")
	if self.eventArray then
		if self.eventArray.OnInitialize then
			local fcn = self:GetCheckFilterFcn(self.eventArray.OnInitialize)
			data = fcn(data)
		end
		if self.eventArray.COMBAT_LOG_EVENT_UNFILTERED then
			local fcn = self:GetCheckFilterFcn(self.eventArray.COMBAT_LOG_EVENT_UNFILTERED)
			if fcn then
				self:Hook(self, "COMBAT_LOG_EVENT_UNFILTERED", function(obj,...)
					fcn(self.fcnData,...)
				end)
			end
		end
	end
	self.fcnData = data
	for k,v in pairs(self.timerId) do
		self:CancelTimer(v)
		self.timerId[k] = nil
	end
	if self.timerArray then
		for k,v in pairs(self.timerArray) do
			local fcn = self:GetCheckFilterFcn(v)
			local id = self:ScheduleRepeatingTimer(function()
				--fcn(self.fcnData)
			end,tonumber(k))
			tinsert(self.timerId,id)
		end
	end
	self.selectedIndex = index
	self.db.profile.selectedRotationIndex = index
--	self:Getkeybinds()
end

function AirjAutoKey:SelecDefaultRotationDB()
	for i,v in pairs(self.rotationDataBaseArray) do
		local rClass, rSpec, rIsDefault = v.class, v.spec, v.isDefault
		local _, class = UnitClass("player")
		local spec = GetSpecializationInfo(GetSpecialization() or 0)
		if rClass == class and rSpec == spec and rIsDefault then
			self:SelectRotationDB(i)
		end
	end
end

function AirjAutoKey:AIRJAUTOKEY_NEW_DATABASE()
	local _, currentclass = UnitClass("player")
	if self.getDefaultDataBaseFcn[currentclass] or true then --test
		self.spellArray = self.getDefaultDataBaseFcn[currentclass]();
		self.macroArray = self.spellArray.macroArray;
		self:UnregisterMessage("AIRJAUTOKEY_NEW_DATABASE");
		self:Getkeybinds()
		return true
	else
		self:RegisterMessage("AIRJAUTOKEY_NEW_DATABASE");
		return false
	end
end

function AirjAutoKey:GetDMBTimer(modName,spellId,timerType)
	if not DBM then return end
	local mod = DBM:GetModByName(modName)
	if not mod then
		return
	end
	local timer
	for k, v in pairs(mod.timers) do
		if v.spellId == spellId and (v.type == timerType or (not timerType and (v.type:match("cd")))) then
			timer = v;
			break;
		end
	end
	if not timer then
		return
	end
	return timer
end

local start = {MoveForwardStart,MoveBackwardStart,StrafeLeftStart,StrafeRightStart,TurnLeftStart,TurnRightStart}
local stop  = {MoveForwardStop ,MoveBackwardStop ,StrafeLeftStop ,StrafeRightStop ,TurnLeftStop ,TurnRightStop }

local stopAllMoves = {0,0,0,0,0,0}

function AirjAutoKey:MoveTimer()
	local moves = {}
	local targetAngle
	local targetDistance
	do
		local type,data,minDistance = self.goto.targetType,self.goto.targetData,self.goto.targetMinDistance
		if type then
			local x, y = self:GetXYForType(type,data)
			if x then
				minDistance = minDistance or 0.2
				local distance = self:GetDistance(x,y)
				targetDistance = distance
				targetAngle = self:GetAngle(x,y)
				if (distance>minDistance) then
					moves = self:GetGoToMoves(x,y)
				else
					moves = {0,0,0,0,0,0}
					if not self.goto.targetFollow then
						self:ClearGoToTarget()
					end
				end
			else
				moves = {0,0,0,0,0,0}
			end
		end
	end

	do
		local type,data,minAngle = self.goto.facingType,self.goto.facingData,self.goto.facingMinAngle
		if type then
			local x,y = self:GetXYForType(type,data)
			if x then
				minAngle = minAngle or 90
				local distance = self:GetDistance(x,y)
				local angle = self:GetAngle(x,y)
				if (GetUnitSpeed("player")==0) then
					if distance<1 then
						moves[5] = moves[5] or 0
						moves[6] = moves[6] or 0
					elseif abs(angle)<45 then
						moves[5] = 0
						moves[6] = 0
					elseif angle>0 then
						moves[5] = 1
						moves[6] = 0
					else
						moves[5] = 0
						moves[6] = 1
					end
				else
					local turnFacing
					if targetAngle then
						if abs(targetAngle-angle) > 185 then
							if targetDistance >5 then
								turnFacing = true
								if (abs(targetAngle)<120) then
									if GetUnitSpeed("player")>=3 then
										JumpOrAscendStart()
									end
								end
							end
						end
						if abs(targetAngle-angle) < 90+45/2 then

						end
					end
					if not turnFacing and (abs(angle)<minAngle-4 or distance<1) then
						moves[5] = moves[5] or 0
						moves[6] = moves[6] or 0
					elseif not turnFacing and abs(angle)<minAngle then
						if angle>0 then
							moves[6] = 0
						else
							moves[5] = 0
						end
					elseif angle>0 then
						moves[5] = 1
						moves[6] = 0
					else
						moves[5] = 0
						moves[6] = 1
					end
				end
			end
		end
	end
	self:DoMove(moves)
end

function AirjAutoKey:DoMove (moves)
	for i=1,6 do
		local n = moves[i]
		if n then
			if n ==1 then
				start[i]()
			else
				stop[i]()
			end
		end
	end
end

function AirjAutoKey:GetXYForType(type,data)
	if (type == "point") then
		return unpack(data)
	elseif (type == "unit") then
		return UnitPosition(data)
	elseif (type == "guid") then
		local unit = self:FindUnitByGUID(data)
		if unit then
			return UnitPosition(unit)
		end
	end
end

function AirjAutoKey:SetMoveTarget (type,data,follow,minDistance)
	self.goto.targetType = type
	self.goto.targetData = data
	self.goto.targetFollow= follow
	if (minDistance and minDistance<0.1) then minDistance = 0.1 end
	self.goto.targetMinDistance = minDistance
end
function AirjAutoKey:ClearGoToTarget ()
	self:SetMoveTarget()
end

function AirjAutoKey:SetMoveFacing (type,data,follow,minAngle)
	self.goto.facingType = type
	self.goto.facingData = data
	self.goto.facingFollow= follow
	if (minAngle and minAngle<0.1) then minAngle = 0.1 end
	self.goto.facingMinAngle = minAngle
end

function AirjAutoKey:ClearMoveFacing ()
	self:SetMoveFacing()
end



function AirjAutoKey:KeepGoToUnit(unit,...)
	local x, y = UnitPosition(unit)
	if x then
		self:SetMoveTarget("point",{x,y},nil,...)
	end
end

function AirjAutoKey:KeepFollowUnit(unit,...)
	self:SetMoveTarget("unit",unit,true,...)
end

function AirjAutoKey:KeepFollowGUID(guid,...)
	--local guid = UnitGUID(unit)
	if guid and guid~=UnitGUID("player") then
		self:SetMoveTarget("guid",guid,true,...)
	end
end
function AirjAutoKey:KeepFacingUnit(unit,...)
	self:SetMoveFacing("unit",unit,true,...)
end
function AirjAutoKey:KeepFacingGUID(guid,...)
	--local guid = UnitGUID(unit)
	if guid and guid~=UnitGUID("player") then
		self:SetMoveFacing("guid",guid,true,...)
	end
end


function AirjAutoKey:KeepGoToStop()
	self:ClearGoToTarget()
	self:ClearMoveFacing()
	self:StopMoving()
end

function AirjAutoKey:StopMoving()
	self:DoMove({0,0,0,0,0,0})
end

function AirjAutoKey:GoToUnit (unit, ...)
	local x, y = UnitPosition(unit)
	if x then
		local moves = self:GetGoToMoves(x,y)
		self.DoMove(moves)
	end
end

function AirjAutoKey:GetPlayPosition()
	local x, y = UnitPosition("player")
	return x, y
end

function AirjAutoKey:GetDistance (x,y)
	local px, py = self:GetPlayPosition()
	local distance = sqrt((x-px)*(x-px) + (y-py)*(y-py))
	return distance
end

function AirjAutoKey:GetAngle(x,y)
	local px, py = self:GetPlayPosition()
	local facing = GetPlayerFacing()*180/math.pi
	local angle = atan2(y-py, x-px)
	angle = angle - facing + 360
	if (angle > 180) then angle = angle - 360 end
	return angle
end

function AirjAutoKey:GetGoToMoves (x, y)
	local distance = self:GetDistance(x,y)
	local angle = self:GetAngle(x,y)
	local dir
	local absAngle = abs(angle)
	if absAngle>157.5 then
		dir = {0,1,0,0}
	elseif absAngle>135 then
		dir = {0,1,1,0}
	elseif absAngle>112.5 then
		dir = {0,0,1,0}
	elseif absAngle>67.5 then
		dir = {0,0,1,0}
	elseif absAngle>22.5 then
		dir = {1,0,1,0}
	else
		dir = {1,0,0,0}
	end
	if angle <0 then
		dir[4] = dir[3]
		dir[3] = 0
	end

	local minAngle = 1
	if distance<40 then
		minAngle = minAngle + (40-distance)/20
	end
	local noTurnAngle= {-90,-45,0,45,90}
	local noTurn = false
	local min = 90
	local to = 0
	for i,v in ipairs(noTurnAngle) do
		if abs(angle-v)<minAngle then
			noTurn = true
		end
		if abs(angle-v) < min then
			min = abs(angle-v)
			to = v
		end
	end
	if noTurn then
		dir[5] = 0
		dir[6] = 0
	elseif (angle>to) then
		dir[5] = 1
		dir[6] = 0
	else
		dir[5] = 0
		dir[6] = 1
	end

	return dir
end


local events = CreateFrame("Frame")
events:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function events:UPDATE_SHAPESHIFT_FORM()
  -- http://wowprogramming.com/docs/api/GetShapeshiftFormID
  local form = GetShapeshiftFormID()
  if form == 1 then -- cat form
  	if not UnitBuff("player",102543) then
	    SetDisplayID("player", 892)
	    UpdateModel("player")
	  end
  elseif form == 5 then -- bear form
    --SetDisplayID("player", 1338)
    UpdateModel("player")
  end
end

function AirjAutoKey:GetAreaTriggerBySpellName(spellNames,objects)
	objects = objects or self:GetObjects()
	local toRet = {}
	for guid,oType in pairs(objects) do
		if bit.band(oType,0x100)~=0 then --bit.band(oType,0x100)~=0
			local spellId = AirjGetObjectDataInt(guid,0x88)
			local name = GetSpellInfo(spellId)
			if not spellNames or spellNames[name] then
				toRet[guid] = {
					name = name,
					spellId = spellId,
				}
			end
		end
	end
	return toRet
end

function AirjAutoKey:GetObjects()
	local objNumber = AirjUpdateObjects()
	local toRet = {}
	for i = 0,objNumber do
		local guid, type = AirjGetObjectGUID(i)
		if guid and type then
			toRet[guid] = type
		end
	end
	return toRet
end


events:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
--[[
LoadAddOn("Blizzard_CompactRaidFrames") CRFSort_Group=function(t1, t2) if UnitIsUnit(t1,"player") then return true elseif UnitIsUnit(t2,"player") then return false elseif UnitIsUnit(t1,"party1") then return true elseif UnitIsUnit(t2,"party1") then return false else return t1 < t2 end end CompactRaidFrameContainer.flowSortFunc=CRFSort_Group
]]
