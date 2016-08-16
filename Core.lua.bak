
local debugmode = false
local hack = false
local frameleve = 229
local ifsize = 2
local gcdtime = 1
local gcdname = ""
AirjAutoKeyFrame = CreateFrame("frame","AirjAutoKeyFrame")
AirjAutoKeyFrame:SetPoint("TOP", UIParent)
AirjAutoKeyFrame:SetSize(1,1)
AAK = AirjAutoKeyFrame
local function printTable(tab, level, flag)
	local text = ""
	local space = strrep(flag, level)
	for n, v in pairs(tab) do
		if type(v) == "table" then
			if tonumber(n) then
				text = format("%s%s[%s] = {\n%s%s},\n",text,space,n,printTable(v, level + 1, flag),space)
			else
				text = format("%s%s[\"%s\"] = {\n%s%s},\n",text,space,n,printTable(v, level + 1, flag),space)
			end
		else
			if tonumber(n) then
				text = format("%s%s[%s] = %s,\n",text,space,n,type(v) == "string" and "\""..v.."\"" or tostring(v))
			elseif n == "filter" and tonumber(v) then
				text = format("%s%s[\"%s\"] = 0x%.2X,\n",text,space,tostring(n), v)
			else
				text = format("%s%s[\"%s\"] = %s,\n",text,space,tostring(n),type(v) == "string" and "\""..v.."\"" or tostring(v))
			end
		end
	end
	return text
end
local printText = function (...)
	local text = "nil"
	local count = select('#', ...)
	local fmtcount = select(1, ...) and select(2, gsub(tostring(select(1, ...)), "%%", "%%")) or 0
	if fmtcount > 0 and select(fmtcount + 1, ...) then
		for n in pairs(print_params) do
			print_params[n] = nil
		end
		for i = 2, fmtcount + 1 do
			if type(select(i, ...)) == "number" then
				print_params[i-1] = select(i, ...)
			else
				print_params[i-1] = tostring(select(i, ...))
			end
		end
		text = format(select(1, ...), unpack(print_params))
	elseif count > 0 then
		text = ""
		for i = 1, count do
			local v = select(i, ...)
			if type(v) == "table" then
				text = text .. "\ntable = {\n" .. printTable(v, 1, "   ") .. "}\n"
			elseif i == 1 then
				text = text .. tostring(v)
			else
				text = text .. ", " .. tostring(v)
			end
		end
	end
	return text
end
local function debug(...)
	DEFAULT_CHAT_FRAME:AddMessage(format("|cFF00BBFE%s |cff18c818-|r ", "AAK DEBUG")..printText(...), 1, 0.67, 0)
end
local function print(...)
	DEFAULT_CHAT_FRAME:AddMessage(format("|cFF00BBFE%s |cff18c818-|r ", "AAK")..printText(...), 1, 0.67, 0)
end

local function strreplace(str1, str2, str3)
	local s, e = strfind(str1,str2)
	if s then
		local str4 = strsub(str1,1,s-1)..str3
		local str5 = strsub(str1,e+1,-1)
		local str6 = strreplace(str5, str2, str3)
		--print(str4..str6)
		return str4..str6
	else
		--		print(str1)
		return str1
	end
end

function AirjAutoKeyFrame:strreplace(...)
	return strreplace(...)
end

function AirjAutoKeyFrame:debug(...)
	debug(...)
end
function AirjAutoKeyFrame:print(...)
	print(...)
end
local function createOptionPanel()
	local optionPanel = CreateFrame( "Frame", "AirjAutoKeyPanel", UIParent );
	local title = optionPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	local version = "test"
	title:SetText("AirjAutoKey ")
	local subtitle = optionPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	subtitle:SetHeight(135)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetPoint("RIGHT", optionPanel, -32, 0)
	subtitle:SetNonSpaceWrap(true)
	subtitle:SetJustifyH("LEFT")
	subtitle:SetJustifyV("TOP")
	subtitle:SetText("AirjAutoKey帮助:\n  /aak 显示帮助信息\n  /aak status 显示模块状态\n  /aak start 开启模块\n  /aak stop 停止模块\n  /aak pause 暂停/恢复模块\n  /aak target <数字> 设置目标数量")

	optionPanel.name = "AirjAutoKey";
	InterfaceOptions_AddCategory(optionPanel);
end
local function getkeybinds()
	local _, class = UnitClass("player")
	if InCombatLockdown() then return end
	if AAKLoadKeys and AAKLoadKeys[class] then
		AirjAutoKeyFrame:CreateButtons()
		AAKLoadKeys[class]()
	else
		AirjAutoKeyDB.keyBind[class] = {}
	end
end

function AirjAutoKeyFrame:CURSOR_UPDATE()
end

function AirjAutoKeyFrame:PLAYER_SPECIALIZATION_CHANGED()
	if not InCombatLockdown() then
		getkeybinds()
	else
		self.UpdateWhileCombat = true
	end
end
function AirjAutoKeyFrame:PLAYER_TALENT_UPDATE()
	if not InCombatLockdown() then
		getkeybinds()
	else
		self.UpdateWhileCombat = true
	end
end
function AirjAutoKeyFrame:PLAYER_LOGOUT()
	getkeybinds()
end
function AirjAutoKeyFrame:PLAYER_LEAVING_WORLD()
	getkeybinds()
end
function AirjAutoKeyFrame:UPDATE_BINDINGS()
	--debug("UPDATE_BINDINGS")
	getkeybinds()
end

local damagelist = {}
function AirjAutoKeyFrame:CheckDamage(guid)
	local ctime = GetTime()
	local total,firsttime = 0,ctime
	for g, dl in pairs(damagelist) do
		if not guid or g == guid then
			for k,v in pairs(dl) do
				if k > ctime -5 then
					total = total + v
					if k< firsttime then
						firsttime = k
					end
				else
					dl[k] = nil
				end
			end
		end
	end
	return total/max(ctime-firsttime,1)
end

function AirjAutoKeyFrame:TimeToDie(unit)
	local health = UnitHealth(unit)
	return health/(self:CheckDamage(UnitGUID(unit))+0.001)
end
local castingname
local iconlists = {}
local function fifoicon(t)
	local ilt = {}
	local xsize = t:GetWidth()
	for k,v in ipairs(iconlists) do
		ilt[k+1] = iconlists[k]
		v.x = max(k*xsize,v.x or 0)
	end
	iconlists = ilt
	iconlists[1] = t
end
local castedIgnor = 
{
	["战斗姿态"] = 1,
	["狂暴姿态"] = 1,
	["防御姿态"] = 1,
	["玄牛之赐"] = 1,
}
function AirjAutoKeyFrame:COMBAT_LOG_EVENT_UNFILTERED(timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,...)
	if strfind(event, "_DAMAGE") then
		local amount = select(4,...)
		if strfind(event, "SWING") then
			amount = select(1,...)
		end
		timestamp = GetTime()
		if not damagelist[destGUID] then
			damagelist[destGUID] = {}
		end
		damagelist[destGUID][timestamp] = damagelist[destGUID][timestamp] and (damagelist[destGUID][timestamp] + amount) or amount
		self:CheckDamage(destGUID)
	end
	if (event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_START") and UnitGUID("player") == sourceGUID then
		local spellid = select(1,...)
		local name,_,texture = GetSpellInfo(spellid)
		if castedIgnor[name] then
			return
		end
		self.keys = self.keys or {}
		if self.keys[name] or GetSpellCooldown(name) then
			if not(castingname and castingname== name) and event == "SPELL_CAST_SUCCESS" or event == "SPELL_CAST_START" then
				self:CreateCastedIcon(spellid,texture)
			end
			if event == "SPELL_CAST_START" then
				castingname = name
			else
				castingname = nil
			end
		end
	end
end


function AirjAutoKeyFrame:CreateGUI()
	local frame = CreateFrame("frame","AAKGUI")
	self.frame = frame

	if not AAK_GUI_POINT then
		AAK_GUI_POINT = {}
	end
	if AAK_GUI_POINT.point then
		--frame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",AAK_GUI_POINT.x,AAK_GUI_POINT.y)
		local db = AAK_GUI_POINT
		frame:SetPoint(db.point, db.relativeTo or UIParent, db.relativePoint, db.xOffset, db.yOffset);-- = point, relativeTo, relativePoint, xOffset, yOffset
	else
		frame:SetPoint("CENTER",nil,"CENTER",0,-250)
	end
	if AAK_GUI_POINT.a then
		frame:SetAlpha(AAK_GUI_POINT.a)
	else
		frame:SetAlpha(0.1)
	end
	frame:SetSize(220,65)
	frame:SetParent(UIParent)
	frame:SetScale(0.8/UIParent:GetScale())
	frame:SetMovable(true) 
	local ftexture = frame:CreateTexture(nil,"BACKGROUND")
	ftexture:SetAllPoints()
	ftexture:SetTexture(0,0,0,0.2)
	frame.texture = ftexture
	
	local mainbutton = CreateFrame("CheckButton",nil)
	mainbutton:EnableMouse(false) 
	mainbutton:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-2)
	mainbutton:SetSize(50,48)
	mainbutton:SetScale(0.8)
	local mbcooldown = CreateFrame("Cooldown",nil,mainbutton)
	mbcooldown:SetFrameStrata("DIALOG")
	mbcooldown:SetAllPoints()
	mbcooldown:SetAlpha(1)
--	mbcooldown:SetScript("OnUpdate",function(self,elapsed)
--		self.elapsed = (self.elapsed or 0) + elapsed
--		if self.elapsed>2 then
--			self.elapsed = self.elapsed -2
--		end
--		local coord = 0.08+ abs(self.elapsed-1)/80
--		local left,right,top,bottom = coord*(1+1*random()),1-coord*(1+2*random()),coord*(1+1*random()),1-coord*(1+3*random())
--		self.texture:SetTexCoord(coord,1-coord,coord,1-coord)
--	end)
	local ctexture = mbcooldown:CreateTexture(nil,"BACKGROUND")
	ctexture:SetAllPoints()
	ctexture:SetTexture(0,0,0)
--	ctexture:SetTexCoord(0.1,0.9,0.1,0.9)
	ctexture:SetTexCoord(0,1,0,1)
	mbcooldown.texture = ctexture
	mainbutton.cooldown = mbcooldown
	frame.mainbutton = mainbutton
	
	local tarbuttons = {}
	local targettitle = CreateFrame("Frame",nil,frame)
	targettitle:SetSize(85,20)
	targettitle:SetScale(0.75)
	targettitle:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
	local ttfs = targettitle:CreateFontString()
	ttfs:SetAllPoints()
	ttfs:SetFontObject(GameFontNormal) 
	targettitle.fs = ttfs
	targettitle:SetScript("OnUpdate",function(self)
		self.fs:SetText("目标数量: "..AirjAutoKeyFrame.targetnum)
		for k,v in ipairs(tarbuttons) do
			if v.num == AirjAutoKeyFrame.targetnum then
				v:SetScale(0.6/UIParent:GetScale())
				v:SetNormalFontObject(GameFontWhite)
				v:SetParent(UIParent) 
			else
				v:SetNormalFontObject(GameFontNormalSmall) 
				v:SetParent(frame)
				v:SetScale(0.6)
			end
		end
	end)
	local tarbutton, lasttarbutton
	local index = 1
	for i = -1,5 do
		tarbutton = self:CreateTarButton(i)
		tarbuttons[index] = tarbutton
		index = index +1
		if lasttarbutton then
			tarbutton:SetPoint("LEFT",lasttarbutton,"RIGHT")
		else
			tarbutton:SetPoint("LEFT",targettitle,"RIGHT")
		end
		lasttarbutton = tarbutton
	end
	
	local lockbutton = CreateFrame("button",nil,frame,"UIPanelButtonTemplate")
	lockbutton:SetText("移动")
	lockbutton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
	lockbutton:SetSize(50,25)
	lockbutton:SetScale(0.7)
	lockbutton:RegisterForClicks("AnyUp", "AnyDown") 
	lockbutton:RegisterForDrag("LeftButton")
	lockbutton:SetScript("OnDragStart",function(self, button, down)
		frame:SetUserPlaced(true);
		frame:StartMoving()
	end)
	lockbutton:SetScript("OnDragStop",function(self, button, down)
		frame:StopMovingOrSizing()
	end)
	frame.lockbutton = lockbutton
	
	local settingbutton = CreateFrame("button",nil,nil,"UIPanelButtonTemplate")
	settingbutton:SetText("透明")
	settingbutton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,-25)
	settingbutton:SetSize(50,25)
	settingbutton:SetScale(0.6)
	settingbutton:SetScript("OnClick",function(self, button, down)
		if frame:GetAlpha()==1 then
			frame:SetAlpha(0.15)
			self:SetAlpha(0.4)
			AAK_GUI_POINT.a = 0.15
		else
			frame:SetAlpha(1)
			AAK_GUI_POINT.a = 1
			self:SetAlpha(1)
		end
		--InterfaceOptionsFrame_OpenToCategory(AirjAutoKeyPanel)
	end)
	frame.settingbutton = settingbutton
	
	local xoffset = -55
	local startbutton = CreateFrame("button",nil,frame,"UIPanelButtonGrayTemplate")
	startbutton:SetText("开启自动")
	startbutton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",xoffset,0)
	startbutton:SetSize(90,25)
	startbutton:SetScale(0.7)
	startbutton:SetScript("OnClick",function(self, button, down)
		AirjAutoKeyFrame.SlashHandler("start")
		frame.stopbutton:Show()
		self:Hide()
	end)
	startbutton:SetScript("OnEnter",function(self, button, down)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetText("开启AirjAutoKey, \n宏\"/aak start\"具有同样效果")
		GameTooltip:Show()
	end)
	startbutton:SetScript("OnLeave",function(self, button, down)
		GameTooltip:Hide()
	end)
	frame.startbutton = startbutton
	
	local stopbutton = CreateFrame("button",nil,nil,"UIPanelButtonTemplate")
	stopbutton:SetText("关闭自动")
	stopbutton:SetSize(90,25)
	stopbutton:SetScale(0.7*frame:GetScale()*UIParent:GetScale())
	stopbutton:SetPoint("TOPRIGHT",frame,"TOPRIGHT",xoffset,0)
	stopbutton:Hide()
	stopbutton:SetScript("OnClick",function(self, button, down)
		AirjAutoKeyFrame.SlashHandler("stop")
		frame.startbutton:Show()
		self:Hide()
	end)
	stopbutton:SetScript("OnEnter",function(self, button, down)
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetText("关闭AirjAutoKey, \n宏\"/aak stop\"具有同样效果")
		GameTooltip:Show()
	end)
	stopbutton:SetScript("OnLeave",function(self, button, down)
		GameTooltip:Hide()
	end)
	frame.stopbutton = stopbutton
	
	local largecd = CreateFrame("button",nil,frame,"UIPanelButtonGrayTemplate")
	largecd:SetText("开启大招")
	largecd:SetPoint("TOPRIGHT",frame,"TOPRIGHT", xoffset-93,0)
	largecd:SetSize(90,25)
	largecd:SetScale(0.7)
	largecd:SetScript("OnClick",function(self, button, down)
		AirjAutoKeyFrame.SlashHandler("cd 600")
		frame.littlecd:Show()
		self:Hide()
	end)
	frame.largecd = largecd
	local littlecd = CreateFrame("button",nil,nil,"UIPanelButtonTemplate")
	littlecd:SetText("关闭大招")
	littlecd:SetSize(90,25)
	littlecd:SetScale(0.7*frame:GetScale()*UIParent:GetScale())
	littlecd:SetPoint("TOPRIGHT",frame,"TOPRIGHT", xoffset-93,0)
	littlecd:Hide()
	littlecd:SetScript("OnClick",function(self, button, down)
		AirjAutoKeyFrame.SlashHandler("cd 60")
		frame.largecd:Show()
		self:Hide()
	end)
	frame.littlecd = littlecd
	
	return frame
end
function AirjAutoKeyFrame:CreateTarButton(num)
	local frame = self.frame
	local button = CreateFrame("button",nil,frame,"UIPanelButtonTemplate")
	button:SetText(num)
	button.num = num
	button:SetSize(35,23)
	button:SetScale(0.6)
	button:SetScript("OnClick",function(self, button, down)
		AirjAutoKeyFrame.SlashHandler("target "..num)
	end)
	return button
end

local xlenth = 80
function AirjAutoKeyFrame:CreateCastedIcon(spellid,texturename)
	local frame = self.frame
	local button = CreateFrame("CheckButton",nil,nil)
	button:EnableMouse(false) 
	button:SetSize(30,30)
	button:SetScale(1*frame:GetScale()*UIParent:GetScale())
	button.speed = 1
	fifoicon(button)
	button:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",50,0)
	button:SetScript("OnUpdate",function(self,elapsed)
		local xsize = self:GetWidth()
		local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")
		if not name then
			name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
		end
		local speed = 1
		local gstart,gduration = GetSpellCooldown(gcdname)
		if gduration and gduration > 0 then
			speed = 1/gduration
		end
		if name then 
			speed = 1000/(endTime - startTime)
		end
		self.x = (self.x or 0) + elapsed * speed * xsize
		self:ClearAllPoints()
		self:SetPoint("TOPLEFT",frame,"TOPLEFT",self.x + 50 or 0,-20)
		self:SetSize(30,30)
		if self.x>xlenth then
			if (1 - (self.x-xlenth)/18>0) then
				self:SetAlpha(1 - (self.x-xlenth)/18)
			else
				self:Hide()
				self:SetScript("OnUpdate",nil)
				for k,v in ipairs(iconlists) do
					if self == v then
						iconlists[k] = nil
					end
				end
				self=nil
			end
		end
	end)
	local texture = button:CreateTexture(nil,"BACKGROUND")
	texture:SetAllPoints()
	texture:SetTexture(texturename)
--	texture:SetTexCoord(0.1,0.9,0.1,0.9)
	texture:SetTexCoord(0,1,0,1)
	return button
end
function AirjAutoKeyFrame:CreateInterFace()
	local interface = CreateFrame("frame")
	interface:SetFrameStrata("TOOLTIP")
	interface:SetFrameLevel(frameleve)
	interface:SetPoint("TOPLEFT", UIParent)
	interface:SetSize(ifsize,ifsize)
	local texture = interface:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0,0,0)
	return texture
end
	
function AirjAutoKeyFrame:PLAYER_ENTERING_WORLD()
	self.texture = self:CreateInterFace()
	self.frame = self:CreateGUI()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:SetScript("OnUpdate",self.OnUpdate)
	self:CreateButtons()
	self:LoadDefaultBinding()
	getkeybinds()

	hooksecurefunc("EditBox_HighlightText", function(...)
		AirjAutoKeyFrame.editing = true
	end)
	hooksecurefunc("EditBox_ClearHighlight", function(...)
		AirjAutoKeyFrame.editing = false
	end)
	hooksecurefunc("ChatEdit_OnEditFocusGained", function(...)
		AirjAutoKeyFrame.editing = true
	end)
	hooksecurefunc("ChatEdit_OnEditFocusLost", function(...)
		AirjAutoKeyFrame.editing = false
	end)
	hooksecurefunc("UseAction", function(slot, target, button)
		AirjAutoKeyFrame.SlashHandler("onceall -0.5")
	end)
	if not self.pause then
		self.pause = true
	end
	if not self.targetnum then
		self.targetnum = 1
	end
	if not self.cdtime then
		self.cdtime = 90
	end
	createOptionPanel()
	AirjAutoKeyFrame:BugFix()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end
local myHealth = {}
local lastMyHealth = GetTime()
function AirjAutoKeyFrame:OnUpdate(elapsed)
	self.elapsed = (self.elapsed or 0) + elapsed
	--	print(self.elapsed, elapsed, AirjAutoKeyDB.updatetime)
	if self.elapsed<0.1 then
		return
	end
	if GetTime()>lastMyHealth + 0.25 then
		lastMyHealth = GetTime()
		for k,v in pairs(myHealth) do
			if k< lastMyHealth-10 then
				myHealth[k] = nil
			end
		end
		myHealth[lastMyHealth] = UnitHealth("player")
	end
	if self.chat then
		self.chat = self.chat + self.elapsed
		if self.chat>(self.chattime or 100) then
			if self.chatstring then
				SendChatMessage(self.chatstring or "","CHANNEL",nil,self.chatchannel or"5")
				--SendChatMessage(self.chatstring or "","CHANNEL",nil,2)
				--SendChatMessage(self.chatstring or "","CHANNEL",nil,1)
			end
			self.chat = 0;
		end
	end
	if self.UpdateWhileCombat then
		getkeybinds()
	end
	if self.once then
		self.once = self.once - self.elapsed
		if self.once<0 then
			if self.oldpause ~= nil then
				self.pause = self.oldpause
				self.oldpause = nil
			end
			self.once = nil
			--		self.SlashHandler("status")
		end
	end
	local nomod = true
	local defaulticon = "Interface\\Icons\\INV_Misc_QuestionMark"
	local modstring = ""
	local modfunc = {
		"IsLeftAltKeyDown",
		"IsLeftControlKeyDown",
		"IsLeftShiftKeyDown",
		"IsRightAltKeyDown",
		"IsRightControlKeyDown",
		"IsRightShiftKeyDown",
	}
	for k, v in pairs(modfunc) do
		local f = _G[v]
		local str = strsub(v,3,-8)
		if f() then
			nomod = false
			self[str] = (self[str] or 0) + self.elapsed
			if self[str] > 1 then
				if modstring ~= "" then
					modstring = modstring .. " - "
				end
				modstring = modstring .. str
				self[str] = 0
			end
		else
			self[str] = 0
		end
	end
	self.colorr = 0
	self.colorg = 0
	self.colorb = 0
	self.texture:SetTexture(self.colorr, self.colorg,self.colorb)
	self.icon = defaulticon
	self.spellName = ""
	local _, class = UnitClass("player")
	local keys = AirjAutoKeyDB.keyBind[class] and AirjAutoKeyDB.keyBind[class][GetSpecialization()] or {}
	self.keys = keys
	local macrotext = nil
	if not nomod then
		if modstring ~= "" then
			print(modstring)
		end
	else
		
		if not self.once and not self.playmusic then
			self.playmusic = true
		end
		local _, class = UnitClass("player")
		if not AirjAutoKeyDB.spelllist[class] then
			if AAKLoadSpells and AAKLoadSpells[class] then
				AAKLoadSpells[class]()
				print("AAKLoadSpells")
			else
				AirjAutoKeyDB.spelllist[class] = {}
			end
		end
		local spells = AirjAutoKeyDB.spelllist[class] and AirjAutoKeyDB.spelllist[class][GetSpecialization()] or {}
		gcdname = AirjAutoKeyDB.spelllist[class] and AirjAutoKeyDB.spelllist[class].gcd or ""
		if not UnitAffectingCombat("player") then
--			getkeybinds()
		end
		for index, spell in ipairs(spells) do
			local filter = spell.filter
			if (not spell.tarmin or spell.tarmin and spell.tarmin <= self.targetnum) and (not spell.tarmax or spell.tarmax and spell.tarmax >= self.targetnum) then
				local spellName = spell.spellName or spell.spell
				local _, spellId = GetSpellBookItemInfo(strreplace(spellName,"focus",""))
				local spellnameforicon = spellName
				spellnameforicon = strreplace(spellnameforicon,"mouseover","")
				spellnameforicon = strreplace(spellnameforicon,"mouse","")
				spellnameforicon = strreplace(spellnameforicon,"focus","")
				local spellTexture = GetSpellTexture(spell.icon or "") or spell.icon or GetSpellTexture(spellnameforicon)
				local cdtime = spell.cd				
				if not cdtime and spellId then
					cdtime = spell.cd or (GetSpellBaseCooldown(spellId) or 1000)/1000
				end
				cdtime = cdtime or 1
				if not self.cdtime or cdtime <= self.cdtime then
					local	start,duration = known and GetSpellCooldown(spellTexture or "") or nil
					local value
					if not start then
						value = 0
					elseif start ==0 then
						value = 0
					else
						value = duration - (GetTime() - start)
					end
					if self:CheckFilters(filter) then
						local key = keys[spellName] and keys[spellName].key or nil
						macrotext = keys[spellName] and keys[spellName].macrotext or keys[spellName]
						local num
						if key and not self.editing then
							num = self:Key2Num(key)
							self.colorr = num/255
							self.colorg = (num + 10)/255
							self.colorb = (num + 20)/255
							self.icon = spellTexture
							self.spellName = spellName
						end
						if	debugmode then
							debug(index,spell.spell,key,num)
						end
						break
					end
				end
			end
		end
		if not self.pause then
			self.texture:SetTexture(self.colorr, self.colorg,self.colorb)
			if macrotext and hack then
				RunMacroText(macrotext)
			end
		elseif self.editing then
			if not self.once and self.playmusic then
				self.playmusic = false
			end
		else
			if not self.once and self.playmusic then
				self.playmusic = false
			end
		end
	end
	if self.frame then
		local mainbutton = self.frame.mainbutton
		mainbutton.cooldown.texture:SetTexture(self.icon)
		local start,duration = GetSpellCooldown(self.spellName)
		if defaulticon == self.icon then
			start,duration = GetSpellCooldown(gcdname)
		end
		if start and start ~= 0 then
			CooldownFrame_SetTimer(mainbutton.cooldown,start,duration,1000)
		else
			--CooldownFrame_SetTimer(mainbutton.cooldown,GetTime()-10000,200,1000)
			--CooldownFrame_SetTimer(mainbutton.cooldown,0,0)
		end
		--debug(self.icon,start,duration,self.spellName)
	end
	self.elapsed = 0
end

AirjAutoKeyFrame:SetScript("OnEvent", function(self, event, ...)
	if self[event] then
		self[event](self, ...)
	end
end)
AirjAutoKeyFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
AirjAutoKeyFrame:RegisterEvent("CURSOR_UPDATE")
AirjAutoKeyFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
AirjAutoKeyFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
AirjAutoKeyFrame:RegisterEvent("PLAYER_LOGOUT")
AirjAutoKeyFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
AirjAutoKeyFrame:RegisterEvent("UPDATE_BINDINGS")

function AirjAutoKeyFrame:CheckFilters(filters,defaultunit)
	local defaultunit = filters.unit or defaultunit
	if filters.unit == "raid" then
		local cntthd = filters.count or 1
		local cnt = 0
		local tfilter = {}
		for k, v in pairs(filters) do
			tfilter[k] = v
		end
		tfilter.unit = nil
		tfilter.oppo = nil
		if IsInRaid() then
			for i = 1, 40 do
				if UnitCanAssist("player","raid"..i) then
					if self:CheckFilters(tfilter,"raid"..i) then
						cnt = cnt + 1
					end
					if cnt >= cntthd then
						return true
					end
				end
			end
		else
			for i = 1, 4 do
				if UnitCanAssist("player","party"..i) then
					if self:CheckFilters(tfilter,"party"..i) then
						cnt = cnt + 1
					end
					if cnt >= cntthd then
						return true
					end
				end
			end
			if self:CheckFilters(tfilter,"player") then
				cnt = cnt + 1
			end
			if cnt >= cntthd then
				return true
			end
		end
		return false
	end
	for index, filter in ipairs(filters) do
		if filter.group then
			if filter.oppo and self:CheckFilters(filter,defaultunit) then
				return false
			elseif not filter.oppo and self:CheckFilters(filter,defaultunit) == false then
				return false
			end
		else
			if filter.oppo and self:CheckFilter(filter,defaultunit) then
				return false
			elseif not filter.oppo and self:CheckFilter(filter,defaultunit) == false then
				return false
			end
		end
	end
	return true
end

function AirjAutoKeyFrame:CheckFilter(filter,defaultunit)
	local unit = filter.unit or defaultunit or "player"
	if filter.fcn then
		return filter.fcn(filter,defaultunit)
	end
	if self[filter.type] then
		return self[filter.type](self,filter,unit)
	end
	return false
end
function AirjAutoKeyFrame.CD(self,filter,unit)
	local value
	if filter.subtype == "GCD" then
		local _, class = UnitClass("player")
		local start,duration = GetSpellCooldown(AirjAutoKeyDB.spelllist[class].gcd or "")
		if not start then
			value = filter.default or 1
		elseif start ==0 then
			value = 0
		else
			value = (duration - (GetTime() - start))/duration
		end
	else
		local start,duration
		if type(filter.name) == "number" then
			local known = IsSpellKnown(filter.name) or IsSpellKnown(filter.name,true)
			start,duration = known and GetSpellCooldown(filter.name) or nil
		else
			start,duration = GetSpellCooldown(filter.name)
		end
		if not start then
			value = filter.default or 300
		elseif start ==0 then
			value = 0
		else
			value = duration - (GetTime() - start)
		end
		if not value then
			value = filter.default or 0
		end
		if filter.subtype ~= "NOGCD" then
			local _, class = UnitClass("player")
			local gstart,gduration = GetSpellCooldown(AirjAutoKeyDB.spelllist[class].gcd or "")
			if gstart and gstart ~=0 then
				local dvalue = value - (gduration - (GetTime() - gstart))
				value = dvalue > 0 and dvalue or 0
			end
		end
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.CHARGE(self,filter,unit)
	local value
	local charges, maxCharges,start,duration
	if type(filter.name) == "number" then
		local known = IsSpellKnown(filter.name) or IsSpellKnown(filter.name,true)
		charges, maxCharges,start,duration = known and GetSpellCharges(filter.name) or nil
	else
		charges, maxCharges,start,duration = GetSpellCharges(filter.name)
	end
	if not charges then
		value = 0
	elseif charges<maxCharges then
		value = (GetTime() - start)/duration + charges
	else
		value=maxCharges
	end
	if not value then
		value = filter.default or 0
	end
	local _, class = UnitClass("player")
	local gstart,gduration = GetSpellCooldown(AirjAutoKeyDB.spelllist[class].gcd or "")
	if gstart and gstart ~=0 then
		local dvalue = value - (gduration - (GetTime() - gstart))
		if dvalue > -0.05 and dvalue < 0.05 then
			value = dvalue > 0 and dvalue or 0
		end
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end

function AirjAutoKeyFrame.SRANGE(self,filter,unit)
	local value
	value = IsSpellInRange(filter.name, unit)
	if not value or value == 0 then
		value = filter.default or false
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end


function AirjAutoKeyFrame.IRANGE(self,filter,unit)
	local value
	value = IsItemInRange(filter.name, unit)
	if not value or value == 0 then
		value = filter.default or false
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end

function AirjAutoKeyFrame.CSPELL(self,filter,unit)
	local names = filter.name
	local value
	if type(names) == "table" then
		for k, v in pairs(names) do
			if IsCurrentSpell(v) then
				value = true
				break
			end
		end
	else
		if IsCurrentSpell(names) then
			value = true
		end
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.COMBAT(self,filter,unit)
	local value = UnitAffectingCombat(unit)
	if not value then
		value = filter.default or false
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.KNOWS(self,filter,unit)
	local _,value = GetSpellBookItemInfo(filter.name)
	if not value then
		value = GetSpellCooldown(filter.name)
	end
	if not value then
		value = filter.default or false
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.POSSESS(self,filter,unit)
	local value = UnitUsingVehicle(unit) or UnitIsPossessed(unit) or IsMounted()
	if not value then
		value = filter.default or false
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end

function AirjAutoKeyFrame.STANCE(self,filter,unit)
	local value = GetShapeshiftForm()
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.GLYPH(self,filter,unit)
	for i = 1, NUM_GLYPH_SLOTS do
		local _, _, _, spellid, _ = GetGlyphSocketInfo(i)
		local glyphname = GetSpellInfo(spellid)
		if glyphname == filter.name then
			return not filter.greater and true or false
		end
	end
	return filter.greater or false
end
function AirjAutoKeyFrame.FRAME(self,filter,unit)
	local frame = GetMouseFocus()
	local value
	if frame then
		local names = filter.name
		if type(names) == "table" then
			for k, v in pairs(names) do
				if strfind(strlower(frame:GetName() or ""),strlower(v or "")) then
					value = true
					break;
				end
			end
		else
			if strfind(strlower(frame:GetName()),strlower(names)) then
				value = true
			end
		end
	end
	if filter.greater then
		if value then
			return false
		end
	else
		if not value then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.BUFF(self,filter,unit)
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	if type(filter.name)=="number" then
		for i=1,100 do
			bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitAura(unit, i, filter.selfonly and "PLAYER")
			if not bname or filter.name == spellID then
				break
			end
		end
	else
		bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitAura(unit, filter.name, nil, filter.selfonly and "PLAYER")
	end
	local value
	if not bname then
		value = filter.default or 0
	else
		if filter.subtype and filter.subtype == "COUNT" then
			value = count
		else
			if duration then
				value = expires- GetTime()
			else
				value = filter.default or 0
			end
			if duration == 0 and expires ==0 then
				value = 1
			end
		end
	end
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.DEBUFF(self,filter,unit)
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, filter.name, nil, filter.selfonly and "PLAYER")
	local value
	if not bname then
		value = filter.default or 0
	else
		if filter.subtype and filter.subtype == "COUNT" then
			value = count
		elseif filter.subtype and filter.subtype == "NUMBER" then
			value = value2
		elseif filter.subtype and filter.subtype == "NxT" then
			value = (value2 or 0)
			if duration then
				value = value*(expires- GetTime())
			else
				value = filter.default or 0
			end
			--				debug(value)
		else
			if duration then
				value = expires- GetTime()
			else
				value = filter.default or 0
			end
		end
	end
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.DNUMBER(self,filter,unit)
	local value = 0
	local ignorelist =
	{
		["虚弱灵魂"] = true,
		["心满意足"] = true,
		["筋疲力尽"] = true,
		["时空位移"] = true,
	}
	for i = 1,100 do
		local bname, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, i)
		if bname then
			if not ignorelist[bname] then
				value = value + 1
			end
		else
			break
		end
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.DTYPE(self,filter,unit)
	local filterstring
	if not filter.name then
		filterstring = "RAID"
	end
	local bname, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	for i = 1, 100 do
		bname, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, i,filterstring)
		if not bname then
			break
		elseif (not filter.name or  dispelType == filter.name) then
			break
		end
	end
	local value
	if not bname then
		value = filter.default or 0
	else
		if filter.subtype and filter.subtype == "COUNT" then
			value = count
		elseif filter.subtype and filter.subtype == "NUMBER" then
			value = value2
		elseif filter.subtype and filter.subtype == "NxT" then
			value = (value2 or 0)
			if duration then
				value = value*(expires- GetTime())
			else
				value = filter.default or 0
			end
			--				debug(value)
		else
			if duration then
				value = expires- GetTime()
			else
				value = filter.default or 0
			end
		end
	end
	--			debug(value, unit, filter.name, UnitAura(unit, filter.name, nil,"HARMFUL"))
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.HTIME(self,filter,unit)
	local lasttime = GetTime()-10
	local maxhealth = UnitHealthMax("player")
	for k, v in pairs(myHealth) do
		if v > maxhealth*(filter.hp or 0.5) and lasttime<k then
			lasttime = k
		end
	end
	local value = GetTime() - lasttime
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.HEALTH(self,filter,unit)
	if filter.subtype then
		if filter.subtype == "HELP" and not UnitCanAssist("player", unit) then
			return false
		elseif filter.subtype == "HARM" and not UnitCanAttack("player", unit) then
			return false
		end
	end
	local health = UnitHealth(unit)
	local maxhealth
	if filter.cmpself then
		maxhealth = UnitHealthMax("player")
		if debugmode then
			maxhealth = 0.0001
		end
	else
		maxhealth = UnitHealthMax(unit)
	end
	local value
	local fvalue = filter.value or 0
	if filter.abs then
		value = health or filter.default or 0
	else
		if health and maxhealth and maxhealth~=0 then
			value = health/maxhealth
			maxhealth = 1;
		else
			value = filter.default or 0
		end
	end
	if fvalue < 0 then
		fvalue = fvalue + (maxhealth or 1)
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= fvalue then
			return false
		end
	else
		if value > fvalue then
			return false
		end
	end
	--			debug(value,fvalue)
	return true
end
function AirjAutoKeyFrame.POWER(self,filter,unit)
	local power = UnitPower(unit,filter.subtype)
	local powermax = UnitPowerMax(unit,filter.subtype)
	local value
	if power and powermax and powermax~=0 then
		if UnitPowerType(unit) == 0 and not filter.subtype then
			value = power/powermax
			powermax = 1
		else
			value = power
		end
	else
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	local fvalue = filter.value or 0
	if fvalue < 0 then
		fvalue = powermax + fvalue
	end
	if filter.greater then
		if value <= (fvalue or 0) then
			return false
		end
	else
		if value > (fvalue or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.SPEED(self,filter,unit)
	local value
	if UnitExists(unit) then
		value = GetUnitSpeed(unit)
	else
		value = filter.default or 0
	end
	
	if value == 0 then
		value = IsFalling() and 10 or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
function AirjAutoKeyFrame.CASTING(self,filter,unit)
	local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
	if not name or filter.name and name ~= filter.name then
		name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	end
	local value
	if name and (not filter.name or name == filter.name) then
		if filter.subtype == "PERCENT" then
			value = (endTime - GetTime()*1000)/(endTime - startTime)
		elseif filter.subtype == "START" then
			value = (GetTime() - startTime/1000)
		else
			value = (endTime/1000 - GetTime())
		end
	else
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value <= (filter.value or 0) then
			return false
		end
	else
		if value > (filter.value or 0) then
			return false
		end
	end
	return true
end
local function printhelpmsg()
	print("AirjAutoKey帮助:\n  /aak 显示本信息\n  /aak status 显示模块状态\n  /aak start 开启模块\n  /aak stop 停止模块\n  /aak pause 暂停/恢复模块\n  /aak target <数字> 设置目标数量")
end

function AirjAutoKeyFrame.SlashHandler(msg)
	local self = AirjAutoKeyFrame
	msg = strlower(msg)
	if msg == "status" then
		if self.pause then
			print("AirjAutoKey 已经停止")
		else
			print("AirjAutoKey 已经启动")
		end
	elseif msg == "stop" then
		if self.pause ~= true then
			print("AirjAutoKey 已经停止, 使用/aak start 启动")
		end
		self.pause = true
		self.oldpause = nil
		self.once = nil
		if self.frame then
			self.frame.stopbutton:Click("LeftButton")
		end
	elseif msg == "start" then
		if self.pause ~= false then
			print("AirjAutoKey 已经开启, 使用/aak stop 停止")
		end
		self.pause = false
		self.oldpause = nil
		self.once = nil
		if self.frame then
			self.frame.startbutton:Click("LeftButton")
		end
	elseif msg == "pause" then
		self.pause = not self.pause
		self.oldpause = nil
		self.once = nil
		if self.pause then
			print("AirjAutoKey 已经暂停, 使用/aak pause 恢复")
		else
			print("AirjAutoKey 已经恢复工作")
		end
	elseif strfind(msg, "chat") then
		local msg1, msg2 = strsplit(" ",msg,2)
		if msg1 == "chat" then
			if msg2 then
				msg1, msg2 = strsplit(" ",msg2,2)
				self.chatstring = "" and nil or msg1
				self.chattime = msg2 and tonumber(msg2) or 100
				self.chat = self.chattime
			else
				self.chatstring = ""
				self.chattime = 100
				self.chat = nil
			end
		end
	elseif strfind(msg, "channel") then
		local msg1, msg2 = strsplit(" ",msg,2)
		if msg1 == "channel" then
			if msg2 then
				self.chatchannel = msg2
			end
		end
	elseif strfind(msg, "target") then
		local msg1, msg2 = strsplit(" ",msg,2)
		--		debug(msg1, msg2)
		if msg1 == "target" then
			if tonumber(msg2) then
				if self.targetnum ~= tonumber(msg2) then
					print("AirjAutoKey 目标数设置为: "..tonumber(msg2).." 从: "..self.targetnum)
				end
				self.targetnum = tonumber(msg2)
			else
				msg1, msg2 = strsplit(" ",msg2,2)
				if tonumber(msg1) and tonumber(msg2) then
					if self.targetnum == tonumber(msg1) then
						print("AirjAutoKey 目标数设置为: "..tonumber(msg2).." 从: "..self.targetnum)
						self.targetnum = tonumber(msg2)
					end
				end
			end
		else
			printhelpmsg()
		end
	elseif strfind(msg, "cd ") then
		local msg1, msg2 = strsplit(" ",msg,2)
		--		debug(msg1, msg2)
		if msg1 == "cd" then
			if tonumber(msg2) then
				if self.targetnum ~= tonumber(msg2) then
					print("AirjAutoKey 冷却限制变为: "..tonumber(msg2))
				end
				self.cdtime = tonumber(msg2)
				if tonumber(msg2)>120 then
					self.frame.largecd:Hide()
					self.frame.littlecd:Show()
				else
					self.frame.littlecd:Hide()
					self.frame.largecd:Show()
				end
			else
				msg1, msg2 = strsplit(" ",msg2,2)
				if tonumber(msg1) and tonumber(msg2) then
					if self.cdtime == tonumber(msg1) then
						print("AirjAutoKey 冷却限制变为: "..tonumber(msg2))
						self.cdtime = tonumber(msg2)
						if tonumber(msg2)>120 then
							self.frame.largecd:Hide()
							self.frame.littlecd:Show()
						else
							self.frame.littlecd:Hide()
							self.frame.largecd:Show()
						end
					end
				end
			end
		else
			printhelpmsg()
		end
	elseif strfind(msg, "once ") then
		local msg1, msg2 = strsplit(" ",msg,2)
		--		debug(msg1, msg2)
		if msg1 == "once" and tonumber(msg2) then
			local time = tonumber(msg2)
			if time >= 0 then
				if self.pause then
					if self.once == nil and self.oldpause == nil then
						self.oldpause = self.pause
					end
					self.once = time
					self.pause = false
				elseif self.once then
					self.once = time
				end
				--			print("AirjAutoKey 将启动"..time.."秒")
			elseif time <= 0 then
				if not self.pause then
					if self.once == nil and self.oldpause == nil then
						self.oldpause = self.pause
					end
					self.once = -time
					self.pause = true
				elseif self.once then
					self.once = -time
				end
				--			print("AirjAutoKey 将暂停"..(-time).."秒")
			end
		else
			printhelpmsg()
		end
	elseif strfind(msg, "onceall ") then
		local msg1, msg2 = strsplit(" ",msg,2)
		--		debug(msg1, msg2)
		if msg1 == "onceall" and tonumber(msg2) then
			local time = tonumber(msg2)
			if time >= 0 then
				if self.pause then
					if self.once == nil and self.oldpause == nil then
						self.oldpause = self.pause
					end
					if not self.once then
						self.once = time
						self.pause = false
					end
				elseif self.once then
					self.once = time
				end
				--			print("AirjAutoKey 将启动"..time.."秒")
			elseif time <= 0 then
				if not self.pause then
					if self.once == nil and self.oldpause == nil then
						self.oldpause = self.pause
					end
					if not self.once then
						self.once = -time
						self.pause = true
					end
				elseif self.once then
					self.once = -time
				end
				--			print("AirjAutoKey 将暂停"..(-time).."秒")
			end
		else
			printhelpmsg()
		end
	elseif strfind(msg, "bind") then
		local msg1, msg2, msg3 = strsplit(" ",msg,3)
		print("tbd",msg1, msg2, msg3)
	else
		printhelpmsg()
	end
end

-- group api fix

if not GetNumRaidMembers then
	GetNumRaidMembers = function()
		if IsInRaid() then
			return GetNumGroupMembers()
		else
			return 0
		end
	end
end
if not GetNumPartyMembers then
	GetNumPartyMembers = function()
		return GetNumSubgroupMembers()
	end
end
if not IsRaidLeader then
	IsRaidLeader = function()
		return UnitIsGroupLeader("player")
	end
end
if not IsPartyLeader then
	IsPartyLeader = function()
		return UnitIsGroupLeader("player")
	end
end
if not UnitIsPartyLeader then
	UnitIsPartyLeader = function(unit)
		return UnitIsGroupLeader(unit)
	end
end


if not IsRaidOfficer then
	IsRaidOfficer = function()
		return UnitIsGroupAssistant("player")
	end
end
if not UnitIsRaidOfficer then
	UnitIsRaidOfficer = function(unit)
		return UnitIsGroupAssistant(unit)
	end
end


function AirjAutoKeyFrame:BugFix()
	if Grid then
		Grid.options.args.Indicator = Grid.options.args.GridIndicator
	end
end


function AirjAutoKeyFrame:CreateButtons()
	for k = 1, 20 do
		self:CreateButton(k)
	end
end


function AirjAutoKeyFrame:CreateButton(k)
	local button = _G["AirjAutoKeyButton"..k]
	if button then return button end
	AirjAutoKeyButtons = AirjAutoKeyButtons or {}
	button = CreateFrame("Button", "AirjAutoKeyButton"..k, UIParent,"SecureActionButtonTemplate")
	AirjAutoKeyButtons[k] = button
	if k == 1 then
		button:SetPoint("CENTER",UIParent,"TOPLEFT",30,220)
	else
		button:SetPoint("LEFT",_G["AirjAutoKeyButton"..(k-1)],"RIGHT",1,0)
	end
	button:SetSize(20,20)
	button:SetBackdropColor(0,1,0)
	button:SetAttribute("type","macro")
	local texture = button:CreateTexture()
	texture:SetAllPoints()
	texture:SetTexture(0,0,0)
	button.texture = texture
	return button
end


--function AirjAutoKeyFrame:PressButton(index)
--	local button = _G["AirjAutoKeyButton"..index]
--	if not button then return end
--	debug("REAL",button:GetName())
--	--SecureActionButton_OnClick(button, "LeftButton")
--end
function AirjAutoKeyFrame:LoadDefaultBinding()
	local defaultBindings =
	{
		".",
		",",
		"'",
		";",
		"[",
		"]",
		"\\",
		"-",
		"=",
		"BACKSPACE",
		"0",
		"9",
		"8",
		"NUMPADMULTIPLY",
		"NUMPADDIVIDE",
		"F11",
		"F10",
		"F9",
		"F8",
		"F7",
		"F6",
		"F5",
		"7",
		"6",
		"5",
		"INSERT",
		"DELETE",
		"HOME",
		"END",
		"PAGEUP",
		"PAGEDOWN",
		"LEFT",
		"RIGHT",
		"UP",
		"DOWN",
	}
	local bi = 1;
	for i = 1,20 do
		local key = GetBindingKey("AAK_ACTIONBUTTON"..i)
		if not key then
			while not key do
				key = defaultBindings[bi]
				if GetBindingByKey(key) then
					key = nil
				end
				if bi >= #defaultBindings then
					break
				end
				bi = bi + 1
			end
		end
		if key then
			SetBinding(key,"AAK_ACTIONBUTTON"..i)
		end
	end
end


SlashCmdList["AAK"] = AirjAutoKeyFrame.SlashHandler
SLASH_AAK1 = "/aak"
SLASH_AAK2 = "/airjautokey"

BINDING_HEADER_AAK = "Airj自动按键";
BINDING_NAME_AAK_START = "启动Airj自动按键";
BINDING_NAME_AAK_STOP = "停止Airj自动按键";
BINDING_NAME_AAK_PAUSE = "暂停/恢复Airj自动按键";
for i = 1,20 do
	_G["BINDING_NAME_AAK_ACTIONBUTTON"..i] = "Airj占用按键"..i
end

