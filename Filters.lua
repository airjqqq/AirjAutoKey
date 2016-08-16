AirjAutoKey.filterTypes = {}
local filterTypes = AirjAutoKey.filterTypes

local function underLine(name)
	if name and strsub(name,1,1) =="_" then
		name = GetSpellInfo(strsub(name,2))
	end
	return name
end

local function toKeyTable(value,default)
	local rst = {}
	if type(value) == "table" then
		for k,v in pairs(value) do
			v = v and tonumber(v) or v
			rst[v] = true
		end
	elseif value and value ~= "" then
		rst[value] = true
	else
		--rst = {}
	end
	local toRet = {}
	for k,v in pairs(rst) do
		toRet[underLine(k)] = v
	end
	return toRet
end

local function copy(table)
	if type(table) == "table" then
		local toRet = {}
		for k,v in pairs(table) do
			toRet[k] = copy(v)
		end
		return toRet
	else
		return table
	end
end

function AirjAutoKey:ToKeyTable(value)
 return toKeyTable(value)
end

function AirjAutoKey:Copy(table)
 return copy(table)
end

local num = 0
local function RegisterFilter(type,data)
	filterTypes[type] = data
	num = num + 1
	data.order = num
	if data.color then
		data.name = "|cff" .. data.color .. data.name .."|r"
	end
end

--GERERATE

RegisterFilter("AUTOON",{
	name = "自动开始",
	color = "00ffff",
	desc = "自动开始已经打开",
	keys = {
	},
}
)
function AirjAutoKey.AUTOON(self,filter,unit)
	local value = self.auto
	if value then
		return true
	end
end

RegisterFilter("BURST",{
	name = "爆发",
	color = "00ffff",
	desc = "自动开始已经打开",
	keys = {
		value = {},
		name = {},
	},
}
)
function AirjAutoKey.BURST(self,filter,unit)
	local name =self[filter.name or "burst"]
	local value = name and (name - GetTime()) or 0
	local pass = value > (filter.value or 0)
	return pass
end


RegisterFilter("TARGETNUM",{
	name = "目标数量",
	color = "00ffff",
	desc = "目标数量",
	keys = {
		value = {},
		greater = {},
	},
}
)
function AirjAutoKey.TARGETNUM(self,filter,unit)
	local value = self.target
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("AOENUM",{
	name = "AOE数量",
	color = "00ffff",
	desc = "AOE数量",
	keys = {
		value = {},
			name = {},
				unit = {},
		greater = {},
	},
}
)
function AirjAutoKey.AOENUM(self,filter,unit)
	local names = toKeyTable(filter.name)
	local tfilter = copy(filter)
	for i,v in pairs(names) do
		tfilter.name = i
		if (self:SPELLHITCNT(tfilter)) then
			return true
		end
	end
	local units = AirjAutoKey:GetUnitListByAirType("help")
	for i,v in pairs(units) do
		local hdfilter = {
			name = "player",
			value = 8,
			unit = v,
		}
		if self:HDRANGE(hdfilter) then
			local tfilter = {
				name = i,
				greater = filter.greater,
				value = filter.value,
				name = filter.unit,
				unit = v,
			}
			if self:BEHITEDCNT(tfilter) then
				return true
			end
		end
	end
	return self:TARGETNUM(filter)
end

RegisterFilter("COMBAT",{
	name = "战斗状态",
	color = "00ffff",
	desc = "进入战斗时此项判定通过",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.COMBAT(self,filter,unit)
	local value = UnitAffectingCombat(filter.unit or "player")
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
end

RegisterFilter("POSSESS",{
	name = "坐骑载具",
	color = "00ffff",
	desc = "包括在载具上,控制其他单位,或在坐骑上",
	keys = {
	},
}
)
function AirjAutoKey.POSSESS(self,filter,unit)
	unit = filter.unit or "player"
	local value = UnitUsingVehicle(unit) or UnitIsPossessed(unit) or IsMounted()
	if not value then
		value = filter.default or false
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end

RegisterFilter("FASTSPELL",{
	name = "快速技能",
	color = "ff00ff",
	desc = "",
	keys = {
		name = {
			name = "技能名称或id"
		},
		value = {
			name = "秒"
		},
		unit = {
		},
	},
	subtypes = {
		UnitCanAttack = {name = "敌对"},
		UnitCanAssist = {name = "友善"},
	},
})

function AirjAutoKey.FASTSPELL(self,filter,unit)
	return self:CD(filter) and self:UNITEXISTS(filter) and self:SRANGE(filter) and self:ISUSABLE(filter)
end


RegisterFilter("FASTAOE",{
	name = "快速AOE",
	color = "ff00ff",
	desc = "",
	keys = {
		name = {
			name = "技能名称或id"
		},
		value = {
			name = "秒"
		},
		unit = {
		},
	},
	subtypes = {
		UnitCanAttack = {name = "敌对"},
		UnitCanAssist = {name = "友善"},
	},
})

function AirjAutoKey.FASTAOE(self,filter,unit)
	return self:CD(filter) and self:UNITEXISTS(filter) and not self:ISDEAD(filter) and self:ISUSABLE(filter)
end

RegisterFilter("FASTDOT",{
	name = "快速DOT",
	color = "ff00ff",
	desc = "",
	keys = {
		name = {
			name = "技能名称或id"
		},
		value = {
			name = "秒"
		},
		unit = {
		},
	},
	subtypes = {
		UnitCanAttack = {name = "敌对"},
		UnitCanAssist = {name = "友善"},
	},
})

function AirjAutoKey.FASTDOT(self,filter,unit)
	local dotfcn = "DEBUFFSELF"
	if filter.subtype == "UnitCanAssist" then
		dotfcn = "BUFFSELF"
	end
	return self[dotfcn](self,filter) and self:UNITEXISTS(filter) and self:SRANGE(filter) and self:ISUSABLE(filter)
end
--Cooldowns
RegisterFilter("CD",{
	name = "技能冷却",
	color = "ff00ff",
	desc = "",
	keys = {
		name = {
			name = "技能名称或id"
		},
		value = {
			name = "秒"
		},
		greater = {},
	},
	subtypes = {
		GCD = {
			name = "公共冷却",
			desc = "",
		},
		NOGCD = {
			name = "忽略公共冷却",
			desc = "",
		},
	}
})
function AirjAutoKey.CD(self,filter,unit)
	local value
	if filter.subtype == "GCD" then
		local start,duration = GetSpellCooldown(AirjAutoKey.GCDSpell)
		--local start,duration = GetItemCooldown(6948)
		if not start then
			value = filter.default or 1
		elseif start ==0 then
			value = 0
		else
			value = (duration - (GetTime() - start))/duration
		end
	else
		assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
		local start,duration
		local name = underLine(filter.name)
		if type(name) == "number" then
			local name = tonumber(name) and GetSpellInfo(tonumber(name)) or name
			start,duration = GetSpellCooldown(name)
		else
			start,duration = GetSpellCooldown(name)
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
			--local gstart,gduration = GetSpellCooldown(self.spellArray.gcd or "")
			local gstart,gduration = GetSpellCooldown(AirjAutoKey.GCDSpell)
			--local gstart,gduration = GetItemCooldown(6948)
			if gstart and gstart ~=0 then
				local gcdRemain = gduration - (GetTime() - gstart)
				if gduration >1.5 then
					gcdRemain = 0.1
				end
				local dvalue = value - gcdRemain
				value = dvalue > 0 and dvalue or 0
			end
		end
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("ICD",{
	name = "物品冷却",
	color = "ff00ff",
	desc = "",
	keys = {
		name = {
			name = "物品名称或id"
		},
		value = {
			name = "秒"
		},
		greater = {},
	},
	subtypes = {
		GCD = {
			name = "公共冷却",
			desc = "",
		},
		NOGCD = {
			name = "忽略公共冷却",
			desc = "",
		},
	}
})
function AirjAutoKey.ICD(self,filter,unit)
	local value
	if filter.subtype == "GCD" then
		local start,duration = GetSpellCooldown(AirjAutoKey.GCDSpell)
		--local start,duration = GetItemCooldown(6948)
		if not start then
			value = filter.default or 1
		elseif start ==0 then
			value = 0
		else
			value = (duration - (GetTime() - start))/duration
		end
	else
		assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
		local start,duration
		local _, itemLink = GetItemInfo(filter.name)
		local count = GetItemCount(filter.name)
		local itemId
		if itemLink and count>0 then
			itemId = tonumber(strmatch(itemLink, ":(%d+)"))
			start,duration = GetItemCooldown(itemId)
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
			--local gstart,gduration = GetSpellCooldown(self.spellArray.gcd or "")
			local gstart,gduration = GetSpellCooldown(AirjAutoKey.GCDSpell)
			--local gstart,gduration = GetItemCooldown(6948)
			if gstart and gstart ~=0 then
				local gvalue = max(min(gduration,1.5) - (GetTime() - gstart),0)
				local dvalue = value - gvalue
				value = dvalue > 0 and dvalue or 0
			end
		end
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("CHARGE",{
	name = "技能充能",
	desc = "",
	color = "ff00ff",
	keys = {
		name = {
			name = "技能名称或id"
		},
		value = {
			name = "数量,可小数"
		},
		greater = {},
	},
}
)
function AirjAutoKey.CHARGE(self,filter,unit)
	local value
		assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
	local charges, maxCharges,start,duration
	if type(filter.name) == "number" then
		local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
		charges, maxCharges,start,duration = GetSpellCharges(name)
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
	local gstart,gduration = GetSpellCooldown(self.spellArray.gcd or "")
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("KNOWS",{
	name = "可知技能",
	desc = "",
	color = "ff00ff",
	keys = {
		name = {
			name = "技能名称或id"
		},
	},
}
)
function AirjAutoKey.KNOWS(self,filter,unit)
	assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
	local _,value = GetSpellBookItemInfo(filter.name)
	if not value then
		if not tonumber(filter.name) then
			value = GetSpellCooldown(filter.name)
		end
	end
	if not value then
		value = IsSpellKnown(filter.name)
	end
	if not value then
		value = IsPlayerSpell(filter.name)
	end

	if not value then
		value = filter.default or false
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end

RegisterFilter("CSPELL",{
	name = "当前法术",
	desc = "",
	color = "ff00ff",
	keys = {
		name = {
			name = "当前使用法术",
			desc = "多用于判定选择位置释放的法术,支持多个,','分割",
		},
	},
}
)
function AirjAutoKey.CSPELL(self,filter,unit)
	local names = filter.name
	local sname
	local value
	assert(filter.name)
	if type(names) == "table" then
		for k, v in pairs(names) do
			if IsCurrentSpell(v) then
				sname = v
				value = true
				do
					break
				end
			end
		end
	else
		if IsCurrentSpell(names) then
			value = true
			sname = names
		end
	end
	if value then
		local filter = {
			name = sname,
			unit = "player",
			greater = true,
		}
		if self:CASTING(filter,"player") then
			value = false
		end
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end

RegisterFilter("HANGLE",{
	name = "面向角度",
	desc = "",
	color = "0000ff",
	keys = {
		unit = {
			name = "测试目标1"
		},
		value = {
			name = "角度"
		},
		greater = {},
	},
}
)

function AirjAutoKey.HANGLE(self,filter,unit)

	local face = GetPlayerFacing()*180/math.pi
	unit = filter.unit or "player"
	local xs,ys = AirjHudMap:GetUnitPosition(unit)
	local xe,ye = AirjHudMap:GetUnitPosition("player")
	local value
	if not xs or xs == 0 or not xe or xe == 0 then
		value = 180
	else
		--print(xs,ys,xe,ye)
		local angle
		if xs-xe == 0 then
			if (ys-ye) > 0 then
				angle = 0
			elseif (ys-ye) > 0 then
				angle = 180
			end
		else
			angle = atan((ys-ye)/(xs-xe)) - 90
			if (xs-xe)<0 then
				angle = angle + 180
			end
		end
		if angle then
			value = abs(angle-face)
			if value > 360 then
				value = value - 360
			end
			if value>180 then
				value = 360-value
			end
		else
			value = 180
		end
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("FRANGE",{
	name = "跟随距离",
	desc = "",
	color = "0000ff",
	keys = {
		value = {
			name = "码"
		},
		greater = {},
	},
}
)

function AirjAutoKey.FRANGE(self,filter,unit)
	local value = 0
	local type,data,minDistance = self.goto.targetType,self.goto.targetData,self.goto.targetMinDistance
	if type then
		local x, y = self:GetXYForType(type,data)
		value = self:GetDistance(x,y)
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("HDRANGE",{
	name = "两者距离",
	desc = "",
	color = "0000ff",
	keys = {
		unit = {
			name = "测试目标1"
		},
		name = {
			name = "测试目标2"
		},
		value = {
			name = "码"
		},
		greater = {},
	},
}
)

function AirjAutoKey.HDRANGE(self,filter,unit)
	unit = filter.unit or "player"
	local unit2 = filter.name
	local airunit = unit2 == "air" and self.raidUnit or unit2 == "airtarget" and (self.raidUnit.."target") or unit2 == "lcu" and (self:FindUnitByGUID(self.lastCastGUID) or self.lastCastUnit)
	airunit = airunit or unit2 == "bgu" and self.groupUnit
	unit2 = airunit or unit2 or "player"
	local xs,ys = AirjHudMap:GetUnitPosition(unit)
	local xe,ye = AirjHudMap:GetUnitPosition(unit2)
	local value
	if not xs or xs == 0 or not xe or xe == 0 then
		value = 120
	else
		--print(xs,ys,xe,ye)
		value = sqrt((xs-xe)^2+(ys-ye)^2)
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
--ranges
RegisterFilter("HRANGE",{
	name = "距离其目标",
	desc = "",
	color = "0000ff",
	keys = {
		unit = {
			name = "测试目标"
		},
		value = {
			name = "码"
		},
		greater = {},
	},
}
)

function AirjAutoKey.HRANGE(self,filter,unit)
	unit = filter.unit or "player"
	local xs,ys = AirjHudMap:GetUnitPosition(unit)
	local xe,ye = AirjHudMap:GetUnitPosition(unit.."target")
	local value
	if not xs or xs == 0 or not xe or xe == 0 then
		value = 0
	else
		--print(xs,ys,xe,ye)
		value = sqrt((xs-xe)^2+(ys-ye)^2)
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
RegisterFilter("SRANGE",{
	name = "技能距离",
	desc = "",
	color = "0000ff",
	keys = {
		name = {
			name = "技能名称或id"
		},
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.SRANGE(self,filter,unit)
	local value
	assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
	unit = filter.unit or "target"
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	value = IsSpellInRange(name,unit)
	if not value or value == 0 then
		value = filter.default or false
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end

RegisterFilter("IRANGE",{
	name = "物品距离",
	desc = "",
	color = "0000ff",
	keys = {
		name = {
			name = "物品名称或id",
			desc = "5:37727\n6:63427\n8:34368\n10:32321\n15:33069\n20:10645",
		},
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.IRANGE(self,filter,unit)
	local value
	assert(type(filter.name)=="number" and filter.name~=0 or type(filter.name)=="string" and filter.name~="")
	unit = filter.unit or "target"
	value = IsItemInRange(filter.name,unit)
	if not value or value == 0 then
		value = filter.default or false
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end

--status


RegisterFilter("UNITEXISTS",{
	name = "存在",
	color = "00ffff",
	desc = "是玩家",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
	subtypes = {
		UnitCanAttack = {name = "敌对"},
		UnitCanAssist = {name = "友善"},
	},
}
)
function AirjAutoKey.UNITEXISTS(self,filter,unit)
	local value
	unit = filter.unit or "player"
	if not filter.subtype then
		if UnitExists(unit) then
			value = true
		end
	else
		if _G[filter.subtype]("player",unit) then
			value = true
		end
	end
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
end
RegisterFilter("ISPLAYER",{
	name = "是玩家",
	color = "00ffff",
	desc = "是玩家",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.ISPLAYER(self,filter,unit)
	unit = filter.unit or "player"
	local value =  UnitIsPlayer(unit)
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
	local name = UnitName(unit)
	if name == "地下城训练假人" or name == "Dungeoneer's Training Dummy" then
		return true
	end
	--debug
	--return true
end


RegisterFilter("ISPLAYERCTRL",{
	name = "是玩家控制",
	color = "00ffff",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.ISPLAYERCTRL(self,filter,unit)
	unit = filter.unit or "player"
	local value =  UnitPlayerControlled(unit)
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
	if UnitName(unit) == "地下城训练假人" then
		return true
	end
	--debug
	--return true
end

RegisterFilter("ISINRAID",{
	name = "在队伍中",
	color = "00ffff",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.ISINRAID(self,filter,unit)
	unit = filter.unit or "player"
	local value =  UnitInRaid(unit) or UnitInParty(unit)
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
	if UnitName(unit) == "地下城训练假人" then
		return true
	end
	--debug
	--return true
end

RegisterFilter("CLASS",{
	name = "职业",
	color = "00ffff",
	desc = "职业",
	keys = {
		unit = {
			name = "测试目标"
		},
		name = {
			name = "职业"
		},
	},
}
)
function AirjAutoKey.CLASS(self,filter,unit)
	unit = filter.unit or "player"
	local _,value =  UnitClass(unit)
	if not value then
		value = filter.default or false
	end
	local names = toKeyTable(filter.name)
	if value and (names[value]) then
		return true
	end
end

RegisterFilter("UNITISTANK",{
	name = "是坦克",
	color = "00ffff",
	desc = "",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.UNITISTANK(self,filter,unit)
	local value
	unit = filter.unit or "player"
	value = UnitGroupRolesAssigned(unit) == "TANK"
	if value then
		return true
	end
end

RegisterFilter("UNITISMELEE",{
	name = "是近战",
	color = "00ffff",
	desc = "",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.UNITISMELEE(self,filter,unit)
	local value
	unit = filter.unit or "player"
	local unitList = {}
	for i = 1,5 do
		tinsert(unitList,"arena"..i)
	end
	local healSpec = {
		[66]=true,
		[70]=true,
		[71]=true,
		[72]=true,
		[73]=true,
		[103]=true,
		[104]=true,
		[250]=true,
		[251]=true,
		[252]=true,
		[259]=true,
		[260]=true,
		[261]=true,
		[263]=true,
		[268]=true,
		[269]=true,
	}
	for i,v in ipairs(unitList) do
		local spec = GetArenaOpponentSpec(i)
		if UnitIsUnit(v,unit)and spec then
			if healSpec[spec] then
				value = true
			else
				value = false
			end
		end
	end
	local _,class = UnitCLASS(unit)
	if value == nil and unit and (UnitInParty(unit) or UnitInRaid(unit)) then
		local classes = {
			["DEATHKNIGHT"] = true,
			["WARRIOR"] = true,
			["ROGUE"] = true,
			["MONK"] = true,
			["PALADIN"] = true,
		}
		if (UnitGroupRolesAssigned(unit) == "DAMAGER" or UnitGroupRolesAssigned(unit) == "TANK") and class and classes[class] then
			value = true
		else
			value = false
		end
	end
	if value == nil and unit then
	print(class)
		if class and (class == "DEATHKNIGHT" or class == "WARRIOR" or class == "ROGUE" )then
			value = true;
		end
	end
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
end

RegisterFilter("UNITISHEALER",{
	name = "是治疗",
	color = "00ffff",
	desc = "",
	keys = {
		unit = {
			name = "测试目标"
		},
	},
}
)
function AirjAutoKey.UNITISHEALER(self,filter,unit)
	local value
	unit = filter.unit or "player"
	local unitList = {}
	for i = 1,5 do
		tinsert(unitList,"arena"..i)
	end
	local healSpec = {
		[65] = true,
		[105] = true,
		[256] = true,
		[257] = true,
		[264] = true,
		[270] = true,
	}
	for i,v in ipairs(unitList) do
		local spec = GetArenaOpponentSpec(i)
		if UnitIsUnit(v,unit)and spec then
			if healSpec[spec] then
				value = true
			else
				value = false
			end
		end
	end
	if value == nil and unit and (UnitInParty(unit) or UnitInRaid(unit)) then
		value = UnitGroupRolesAssigned(unit) == "HEALER"
	end
	if value == nil and unit then
		local guid = UnitGUID(unit)
		if guid then
			value = self.isHealer[guid]
		end
	end
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end

	if UnitName(unit) == "地下城训练假人" then
		return true
	end
end

RegisterFilter("CANLOOT",{
	name = "可以拾取",
	color = "ffbf40",
	desc = "",
	keys = {
		unit = {
		},
	},
}
)
function AirjAutoKey.CANLOOT(self,filter,unit)
	local guid = UnitGUID(filter.unit or "target")
	if guid then
		local can, has = CanLootUnit(guid)
		return can
	end
end

RegisterFilter("FRAMEVISIBLE",{
	name = "框体可见",
	color = "ffbf40",
	desc = "",
	keys = {
		name = {
		},
	},
}
)
function AirjAutoKey.FRAMEVISIBLE(self,filter,unit)
	if filter.name then
		local frame = _G[filter.name]
		if frame then
			if frame:IsVisible() then
				return true
			end
		end
	end
end


RegisterFilter("CANCAST",{
	name = "可以读条",
	color = "00ffff",
	desc = "可以读条",
	keys = {
		unit = {
			name = "测试单位",
		},
	},
}
)
function AirjAutoKey.CANCAST(self,filter,unit)
	local value
	unit = filter.unit or "player"
	if UnitExists(unit) then
		value = GetUnitSpeed(unit)
	else
		value = filter.default or 0
	end

	if value == 0 and unit == "player" then
		value = IsFalling() and 10 or 0
	end

	local tfilter =
	{
		name = {137587,"灵狐守护","浮冰","灵魂行者的恩赐"},
		unit = unit,
		greater = true,
		value = 0,
	}

	if self:BUFF(tfilter) then
		value = 0
	end

	if value <= 0 then
		return true
	end
end

RegisterFilter("SPEED",{
	name = "运动速度",
	color = "00ffff",
	desc = "多用于判定是否在移动状态(包括跳跃[仅自身])",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "速度值",
			desc = "正常奔跑为7",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.SPEED(self,filter,unit)
	local value
	unit = filter.unit or "player"
	if UnitExists(unit) then
		value = GetUnitSpeed(unit)
	else
		value = filter.default or 0
	end

	if value == 0 and unit == "player" then
	--	value = IsFalling() and 10 or 0
	end
	if filter.rv then
		return value
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("STARTMOVETIME",{
	name = "开始移动时间",
	color = "40c000",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.STARTMOVETIME(self,filter,unit)
	local lasttime = GetTime()-120
	local speedList = self.speedList or {}
	for k, v in pairs(speedList) do
		if v == 0 and lasttime<k then
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("SPEEDTIME",{
	name = "停止移动时间",
	color = "40c000",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.SPEEDTIME(self,filter,unit)
	local lasttime = GetTime()-120
	local speedList = self.speedList or {}
	for k, v in pairs(speedList) do
		if v > 0 and lasttime<k then
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("STANCE",{
	name = "姿态",
	color = "00ffff",
	desc = "",
	keys = {
		name = {name = "姿态序号"},
	},
}
)

RegisterFilter("GLYPH",{
	name = "已装雕纹",
	color = "00ffff",
	desc = "",
	keys = {
		name = {
			name = "雕纹名称",
			desc = "多个",
		},
	},
}
)
function AirjAutoKey.GLYPH(self,filter,unit)
	local names = toKeyTable(filter.name)
	assert(filter.name)
	for i = 1, NUM_GLYPH_SLOTS do
		local _, _, _, spellid, _, gid = GetGlyphSocketInfo(i)
		local glyphname = GetSpellInfo(spellid)
		if names[glyphname] or names[spellid]  or names[gid] then
			return true
		end
	end
end

function AirjAutoKey.STANCE(self,filter,unit)
	local value = GetShapeshiftForm()
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end
--	value = value..""
	local values = toKeyTable(filter.name)
	return values[value]
end

RegisterFilter("UNITISUNIT",{
	name = "单位相同",
	color = "00ffff",
	desc = "",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "另一个单位",
		},
	},
}
)
function AirjAutoKey.UNITISUNIT(self,filter,unit)
	unit = filter.unit or "player"
	local targetList = toKeyTable(filter.name)
	for k,v in pairs(targetList) do
		if UnitIsUnit(k,unit) then
			return true
		end
	end
end

RegisterFilter("UNITNAME",{
	name = "单位名字",
	color = "00ffff",
	desc = "",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "单位名字",
		},
	},
}
)
function AirjAutoKey.UNITNAME(self,filter,unit)
	unit = filter.unit or "player"
	local targetList = toKeyTable(filter.name)
	local unitName = UnitName(unit) or ""
	for k,v in pairs(targetList) do
		if strfind(unitName,k) then
			return true
		end
	end
end

RegisterFilter("CHANNELDAMAGE",{
	name = "通道伤害",
	color = "00ffff",
	desc = "施法进程,包括引导,默认为施法剩余时间(秒)",
	keys = {
		name = {
			name = "法术名称",
		},
		value = {
			name = "秒或比例",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.CHANNELDAMAGE(self,filter,unit)
	local names = toKeyTable(filter.name)
	for k,v in pairs(names) do
		local name = tonumber(k) and GetSpellInfo(tonumber(k)) or k
		local lasttime = self.channelTime[name] or (GetTime()-100)
		local value = GetTime() - lasttime
		if filter.greater then
			if value > (filter.value or 0) then
				return true
			end
		else
			if value <= (filter.value or 0) then
				return true
			end
		end
	end
end
RegisterFilter("CASTING",{
	name = "当前读条",
	color = "00ffff",
	desc = "施法进程,包括引导,默认为施法剩余时间(秒)",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "法术名称",
		},
		value = {
			name = "秒或比例",
		},
		greater = {
		},
	},
	subtypes = {
		PERCENT = {name = "剩余比例"},
		START = {name = "已用时间"},
	},
}
)
function AirjAutoKey.CASTING(self,filter,unit)
	local names = toKeyTable(filter.name)
	unit = filter.unit or "player"
	local tnames = {}
	for k,v in pairs(names) do
		k = tonumber(k) and GetSpellInfo(tonumber(k)) or k
		tnames[k] = v
	end
	names = tnames
	local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	end
	local value
	if name and (names[name] or not filter.name) then
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
RegisterFilter("CASTINGCHANNEL",{
	name = "当前通道",
	color = "00ffff",
	desc = "引导进程,默认为施法剩余时间(秒)",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "法术名称",
		},
		value = {
			name = "秒或比例",
		},
		greater = {
		},
	},
	subtypes = {
		PERCENT = {name = "剩余比例"},
		START = {name = "已用时间"},
	},
}
)
function AirjAutoKey.CASTINGCHANNEL(self,filter,unit)
	local names = toKeyTable(filter.name)
	unit = filter.unit or "player"
	local tnames = {}
	for k,v in pairs(names) do
		k = tonumber(k) and GetSpellInfo(tonumber(k)) or k
		tnames[k] = v
	end
	names = tnames
	local name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	local value
	if name and (names[name] or not filter.name) then
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
RegisterFilter("CASTINGINTERRUPT",{
	name = "当前读条可打断",
	color = "00ffff",
	desc = "施法进程,包括引导,默认为施法剩余时间(秒)",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "法术名称",
		},
		value = {
			name = "秒或比例",
		},
		greater = {
		},
	},
	subtypes = {
		PERCENT = {name = "剩余比例"},
		START = {name = "已用时间"},
	},
}
)
function AirjAutoKey.CASTINGINTERRUPT(self,filter,unit)
	local names = toKeyTable(filter.name)
	unit = filter.unit or "player"
	local tnames = {}
	for k,v in pairs(names) do
		k = tonumber(k) and GetSpellInfo(tonumber(k)) or k
		tnames[k] = v
	end
	names = tnames
	local name, subText, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
	if not name then
		name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	end
	local value
	if name and (names[name] or not filter.name) and not notInterruptible then
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
	if value~= 0 then
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end


--aura
local raidbuffs = {
	mas = "IncreasedMastery",
	has = "IncreasedHaste",
	sp = "IncreasedSP",
	ap = "IncreasedAP",
	stats = "IncreasedStats",
	ver = "IncreasedVersatility",
	mul = "IncreasedMultistrike",
	sta = "BonusStamina",
	crit = "IncreasedCrit",
	bh = "BurstHaste",
}

RegisterFilter("RAIDBUFF",{
	name = "无团队BUFF",
	color = "00ff80",
	desc = "",
	keys = {
		name = {
			name = [[
mas = "IncreasedMastery",
has = "IncreasedHaste",
sp = "IncreasedSP",
ap = "IncreasedAP",
stats = "IncreasedStats",
ver = "IncreasedVersatility",
mul = "IncreasedMultistrike",
sta = "BonusStamina",
crit = "IncreasedCrit",
bh = "BurstHaste",
]]
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒或层数",
		},
	},
}
)
function AirjAutoKey.RAIDBUFF(self,filter,unit)
	assert(filter.name)
	local tfilter = copy(filter)
	local toRet = false
	local names = toKeyTable(filter.name)
	for k,v in pairs(names) do
		tfilter.name = self.tmwSpells.buffs[raidbuffs[k]]
		toRet = toRet or self:BUFF(tfilter)
	end
	return toRet
end

RegisterFilter("BUFF",{
	name = "增益(全部)",
	color = "00ff80",
	desc = "",
	keys = {
		name = {
			name = "增益名称或id",
			desc = "多个",
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒或层数",
		},
		greater = {
		},
	},
	subtypes = {
		COUNT = {
			name = "叠加数量",
		},
		START = {
			name = "开始时间",
		},
		OBSERV = {
			name = "吸收值",
		},
	},
}
)
function AirjAutoKey.BUFF(self,filter,unit)
	assert(filter.name)
	unit = filter.unit or "player"
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local names = toKeyTable(filter.name)
	local value
	unit = unit or filter.unit or "player"
	for i=1,100 do
		bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitBuff(unit, i)
		if bname and (names[spellID] or names[bname]) then
			if not bname then
				value = filter.default or 0
			else
				if filter.subtype and filter.subtype == "COUNT" then
					value = count
				elseif filter.subtype and filter.subtype == "START" then

					if duration then
						value = GetTime()-expires+duration
					else
						value = filter.default or 0
					end
					if duration == 0 and expires ==0 then
						value = 10
					end
				elseif filter.subtype and filter.subtype == "OBSERV" then

					if duration then
						value = value2
					else
						value = 0
					end
				else

					if duration then
						value = expires- GetTime()
					else
						value = filter.default or 0
					end
					if duration == 0 and expires ==0 then
						value = 10
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
				if value > (filter.value or 0) then
					return true,spellID
				end
			else
				if value <= (filter.value or 0) then
					return true,spellID
				end
			end
		end
	end
	if not value then
		value = filter.default or 0
		if filter.greater then
			if value > (filter.value or 0) then
				return true
			end
		else
			if value <= (filter.value or 0) then
				return true
			end
		end
	end
end

RegisterFilter("BUFFSELF",{
	name = "增益(自身释放)",
	desc = "",
	color = "00ff80",
	keys = {
		name = {
			name = "增益名称或id",
			desc = "多个",
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒或层数",
		},
		greater = {
		},
	},
	subtypes = {
		COUNT = {
			name = "叠加数量",
		},
	},
}
)
function AirjAutoKey.BUFFSELF(self,filter,unit)
	assert(filter.name)
	unit = filter.unit or "player"
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local names = toKeyTable(filter.name)
	local value
	for i=1,100 do
		bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitBuff(unit, i, "PLAYER")
		if bname and(names[spellID] or names[bname]) then
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
						value = 10
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
				if value > (filter.value or 0) then
					return true
				end
			else
				if value <= (filter.value or 0) then
					return true
				end
			end

		end
	end
	if not value then

		if filter.rv then
			return 0
		end
		value = filter.default or 0
		if filter.greater then
			if value > (filter.value or 0) then
				return true
			end
		else
			if value <= (filter.value or 0) then
				return true
			end
		end
	end
end

RegisterFilter("DEBUFF",{
	name = "负面(全部)",
	color = "00ff80",
	desc = "",
	keys = {
		name = {
			name = "负面名称或id",
			desc = "多个",
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒或层数",
		},
		greater = {
		},
	},
	subtypes = {
		START = {
			name = "开始时间",
		},
		COUNT = {
			name = "叠加数量",
		},
		NUMBER = {
			name = "值",
			desc = "如武僧醉拳",
		},
		NxT = {
			name = "值*持续时间",
		},
		NUMBER2H = {
			name = "值与自身生命比例",
			desc = "如武僧醉拳",
		},
		NxT2H = {
			name = "值*持续时间与自身生命比例",
		},
	},
}
)
function AirjAutoKey.DEBUFF(self,filter,unit)
	assert(filter.name)
	unit = filter.unit or "player"
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local names = toKeyTable(filter.name)
	local rst,rv,hasspellmatched
	for i=1,100 do
		bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, i)
		if not bname and not spellID then
			break
		end
		if names[spellID] or names[bname] then
			hasspellmatched = true
			local value = filter.default or 0
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
			elseif filter.subtype and filter.subtype == "NUMBER2H" then
				value = value2/UnitHealth("player")
			elseif filter.subtype and filter.subtype == "NxT2H" then
				value = (value2 or 0)
				if duration then
					local hm = max(UnitHealth("player"),UnitHealthMax("player")/2)
					value = value*(expires- GetTime())/hm
				else
					value = filter.default or 0
				end
			elseif filter.subtype and filter.subtype == "START" then

				if duration then
					value = GetTime()-expires+duration
				else
					value = filter.default or 0
				end
				if duration == 0 and expires ==0 then
					value = 10
				end
			else
				if duration then
					value = expires- GetTime()
				else
					value = filter.default or 0
				end
				if duration == 0 and expires ==0 then
					value = 10
				end
			end
			if filter.greater then
				if value > (filter.value or 0) then
					rst = true
				end
			else
				if value <= (filter.value or 0) then
					rst = true
				end
			end
			if rst then
				rv = value
				break
			end
		end
	end
	if not hasspellmatched then
		if not filter.greater then
			rst = true
		end
	end
	if filter.rv then
		return rv or filter.default or 0
	end
	return rst
end

RegisterFilter("DEBUFFSELF",{
	name = "负面(自身释放)",
	color = "00ff80",
	desc = "",
	keys = {
		name = {
			name = "负面名称或id",
			desc = "多个",
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒或层数",
		},
		greater = {
		},
	},
	subtypes = {
		START = {
			name = "开始时间",
		},
		COUNT = {
			name = "叠加数量",
		},
		NUMBER = {
			name = "值",
			desc = "如武僧醉拳",
		},
		NxT = {
			name = "值*持续时间",
		},
		NUMBER2H = {
			name = "值与自身生命比例",
			desc = "如武僧醉拳",
		},
		NxT2H = {
			name = "值*持续时间与自身生命比例",
		},
	},
}
)
function AirjAutoKey.DEBUFFSELF(self,filter,unit)
	assert(filter.name)
	unit = filter.unit or "player"
	local bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local names = toKeyTable(filter.name)
	local rst,rv,hasspellmatched
	for i=1,100 do
		bname, _, _, count, _, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, i, "PLAYER")
		if not bname then
			break
		end
		if names[spellID] or names[bname] then
			hasspellmatched = true
			local value = filter.default or 0
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
			elseif filter.subtype and filter.subtype == "NUMBER2H" then
				value = value2/UnitHealth("player")
			elseif filter.subtype and filter.subtype == "NxT2H" then
				value = (value2 or 0)
				if duration then
					local hm = max(UnitHealth("player"),UnitHealthMax("player")/2)
					value = value*(expires- GetTime())/hm
				else
					value = filter.default or 0
				end
			elseif filter.subtype and filter.subtype == "START" then

				if duration then
					value = GetTime()-expires+duration
				else
					value = filter.default or 0
				end
				if duration == 0 and expires ==0 then
					value = 10
				end
			else
				if duration then
					value = expires- GetTime()
				else
					value = filter.default or 0
				end
				if duration == 0 and expires ==0 then
					value = 10
				end
			end
			if filter.greater then
				if value > (filter.value or 0) then
					rst = true
				end
			else
				if value <= (filter.value or 0) then
					rst = true
				end
			end
			rv = value
			if rst then
				break
			end
		end
	end
	if not hasspellmatched then
		if not filter.greater then
			rst = true
		end
	end
	if filter.rv then
		return rv or filter.default or 0
	end
	return rst
end

RegisterFilter("DNUMBER",{
	name = "负面数量",
	desc = "",
	color = "00ff80",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "个",
		},
	},
}
)
function AirjAutoKey.DNUMBER(self,filter,unit)
	local value = 0
	local ignorelist =
	{
		["虚弱灵魂"] = true,
		["心满意足"] = true,
		["筋疲力尽"] = true,
		["时空位移"] = true,
		["虚弱灵魂"] = true,
	}
	unit = filter.unit or "player" or "player"
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("DTYPE",{
	name = "负面类型",
	desc = "",
	color = "00ff80",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
	subtypes = {
		Magic = {
			name = "魔法",
		},
		Curse = {
			name = "诅咒",
		},
		Disease = {
			name = "疾病",
		},
		Poison = {
			name = "毒",
		},
		MINE = {
			name = "可驱散",
		},
	},
}
)
function AirjAutoKey.DTYPE(self,filter,unit)
	unit = filter.unit or "player" or "player"
	assert(filter.subtype)
	local filterstring
	if filter.subtype == "MINE" then
		filterstring = "RAID"
	end
	local bname, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	for i = 1, 100 do
		bname, _, _, count, dispelType, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitDebuff(unit, i,filterstring)
		if not bname then
			break
		elseif (filter.subtype == "MINE" or dispelType == filter.subtype) then
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
			-- debug(value)
		else
			if duration then
				value = expires- GetTime()
			else
				value = filter.default or 0
			end
		end
	end
	-- debug(value, unit, filter.name, UnitAura(unit, filter.name, nil,"HARMFUL"))
	if not value then
		value = filter.default or 0
	end
	if filter.rv then
		return value
	end

	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("CANSTEAL",{
	name = "可以偷取",
	desc = "",
	color = "00ff80",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
	subtypes = {
	},
}
)
function AirjAutoKey.CANSTEAL(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local bname, _, _, count, dtype, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local names = toKeyTable(filter.name)
	for i=1,100 do
		bname, _, _, count, dtype, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitBuff(unit, i)
		if (bname) and (isStealable or dtype == "Magic") then
			local value
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
			if not value then
				value = filter.default or 0
			end
			if filter.rv then
				return value
			end
			if filter.greater then
				if value > (filter.value or 0) then
					return true
				end
			else
				if value <= (filter.value or 0) then
					return true
				end
			end
		end
	end
end
RegisterFilter("CANSTEALNUM",{
	name = "可以偷取数量",
	desc = "",
	color = "00ff80",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "时间",
		},
		value = {
			name = "数量",
		},
		greater = {
		},
	},
	subtypes = {
	},
}
)
function AirjAutoKey.CANSTEALNUM(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local bname, _, _, count, dtype, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3
	local num = 0
	for i=1,100 do
		bname, _, _, count, dtype, duration, expires, caster, isStealable, _, spellID, _, _, value1, value2, value3 = UnitBuff(unit, i)
		if (bname) and (isStealable or dtype == "Magic") then
			local value
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
			if not value then
				value = filter.default or 0
			end
			if value > (filter.name or 0) then
				num = num + 1
			end
		end
	end
	local value = num
	if filter.rv then
		return value
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

--[[
RegisterFilter("ARUANUM",{
	name = "光环数量",
	color = "00ff80",
	desc = "基于战斗记录",
	keys = {
		value = {
			name = "数量",
		},
		name = {
			name = "法术名称",
		},
		greater = {
		},
	},
	subtypes = {
		ignoreAIR = {
			name = "忽略air",
		},
	},
}
)
function AirjAutoKey.ARUANUM(self,filter,unit)
	assert(filter.name)
	local currentTime = GetTime()
	local value = 0
	for k,v in pairs(self.auraList[filter.name] or {}) do
		if filter.subtype ~= "ignoreAIR" or v ~= UnitGUID(self.raidUnit) then
			value = value+1
		end
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
]]

--health
RegisterFilter("HTIME",{
	name = "低生命时间",
	color = "40c000",
	desc = "",
	keys = {
		name = {
			name = "阀值",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.HTIME(self,filter,unit)
	assert(filter.name and type(filter.name) == "number")
	local lasttime = GetTime()-120
	local myHealth = self.healthList or {}
	local maxhealth = UnitHealthMax("player")
	for k, v in pairs(myHealth) do
		if v > (filter.name) and lasttime<k then
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
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
RegisterFilter("ISDEAD",{
	name = "死亡状态",
	desc = "",
	color = "40c000",
	keys = {
		unit = {
			name = "测试单位",
		},
	},
	subtypes = {
	},
}
)
function AirjAutoKey.ISDEAD(self,filter,unit)
	unit = filter.unit or "player"
	if UnitIsDeadOrGhost(unit) then
			return true
	end
end
RegisterFilter("HEALTH",{
	name = "生命值",
	desc = "",
	color = "40c000",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "生命值比例",
		},
		greater = {
		},
	},
	subtypes = {
		CMPSELF = {
			name = "对比自身",
		},
		INCOMING = {
			name = "包括未来",
		},
		ABS = {
			name = "绝对",
		},
		ABSMAX = {
			name = "最大绝对",
		},
	},
}
)
function AirjAutoKey.HEALTH(self,filter,unit)

	unit = filter.unit or "player"
	local health = UnitHealth(unit)
	local maxhealth
	if filter.subtype == "CMPSELF" then
		maxhealth = UnitHealthMax("player")
	elseif filter.subtype == "ABS" then
		maxhealth = 1
	elseif filter.subtype == "ABSMAX" then
		maxhealth = 1
		health = UnitHealthMax(unit)
	elseif filter.subtype == "INCOMING" then
		health = health + (UnitGetIncomingHeals(unit) or 0)
		maxhealth = UnitHealthMax(unit)
	else
		maxhealth = UnitHealthMax(unit)

		local isHalf = select(16,UnitDebuff(unit,"蔑视光环"))
		if isHalf then
			maxhealth = maxhealth*isHalf/100
		end
	end
	local value
	local fvalue = filter.value or 0
	if filter.abs then
		value = health or filter.default or 0
	else
		if health and maxhealth and maxhealth~=0 then
			value = health/maxhealth
			maxhealth = 1
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
	if UnitIsDeadOrGhost(unit) then
		value = 1
	end
	if filter.greater then
		if value > (fvalue or 0) then
			return true
		end
	else
		if value <= (fvalue or 0) then
			return true
		end
	end
end


RegisterFilter("ISUSABLE",{
	name = "技能可用",
	color = "ffff00",
	keys = {
		name = {
			name = "技能名称",
		},
	},
}
)

function AirjAutoKey.ISUSABLE(self,filter,unit)

	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local value = IsUsableSpell(name)
	return value
end
--power
RegisterFilter("POWER",{
	name = "资源值",
	color = "ffff00",
	desc = "如法力值,能量值",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "值或比例",
			desc = "法力值为比例,其他均为实际值",
		},
		greater = {
		},
	},
	subtypes = {
		[SPELL_POWER_MANA] = {name = "法力值"},
		[SPELL_POWER_RAGE] = {name = "怒气"},
		[SPELL_POWER_FOCUS] = {name = "集中值"},
		[SPELL_POWER_ENERGY] = {name = "能量"},
		[SPELL_POWER_RUNIC_POWER] = {name = "符文能量"},
		[SPELL_POWER_SOUL_SHARDS] = {name = "灵魂碎片"},
		--[SPELL_POWER_ECLIPSE] = {name = "月光能量"},
		[SPELL_POWER_HOLY_POWER]  = {name = "神圣能量"},
		[SPELL_POWER_CHI]  = {name = "真气"},
--		[SPELL_POWER_SHADOW_ORBS]  = {name = "暗影宝珠"},
--		[SPELL_POWER_BURNING_EMBERS]  = {name = "余烬"},
	--	[SPELL_POWER_DEMONIC_FURY]  = {name = "恶魔怒气"},
	},
}
)
function AirjAutoKey.POWER(self,filter,unit)
	unit = filter.unit or "player"
	local default = UnitPowerType(unit)
	local power = UnitPower(unit,filter.subtype or default)
	local powermax = UnitPowerMax(unit,tonumber(filter.subtype))

	local tfilter = {
		type = "CASTSTARTALL",
		unit = "player",
	}

	tfilter.name = 56641;
	tfilter.value = 1.9;
	if AirjAutoKey:CASTSTARTALL(tfilter,"player") then
		power = power + 14
	end
	tfilter.name = "专注射击";
	tfilter.value = 2.5;
	if AirjAutoKey:CASTSTARTALL(tfilter,"player") then
		power = power + 50
	end
	tfilter.name = 19434;
	tfilter.value = 2.5;
	if AirjAutoKey:CASTSTARTALL(tfilter,"player") then
		--power = power - 30
	end
	tfilter = {
		type = "BUFF",
		unit = "player",
	}
	local half=1

	tfilter.name = {503340,106951};
	tfilter.value = 0;
	tfilter.greater = true
	if AirjAutoKey:BUFF(tfilter,"player") then
		half = 0.5
	end
	--[[
	tfilter.name = "节能施法";
	tfilter.value = 0;
	tfilter.greater = true
	if AirjAutoKey:BUFF(tfilter,"player") then
		half = 0
	end]]
	local value
	if power and powermax and powermax~=0 then
		if not filter.subtype or filter.subtype=="0" then
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
	elseif half then
		fvalue = fvalue*half
	end
	if filter.greater then
		if value > (fvalue or 0) then
			return true
		end
	else
		if value <= (fvalue or 0) then
			return true
		end
	end
end

RegisterFilter("EMBER",{
	name = "毁灭术士余烬",
	color = "ffff00",
	desc = "",
	keys = {
		value = {
			name = "数量'*'",
			desc = "负数使用最大值作为基准.碎片使用小数点,如'2.3'",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.EMBER(self,filter,unit)
	local power = UnitPower("player",14,true)/MAX_POWER_PER_EMBER
	local powermax = UnitPowerMax("player",14)

	local value
	value = power

	local tf = {
		type = "CASTING",
		name = 116858,
		greater = true,
		value = 0,
	}
	if AirjAutoKey:CheckFilter(tf,"player") then
		value = value-1
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

RegisterFilter("RUNE",{
	name = "可用符文数量",
	color = "ffff00",
	class = {"DEATHKNIGHT"},
	keys = {
		name = {
			name = "未来时间",
		},
		value = {
			name = "符文数量",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.RUNE(self,filter,unit)
	local checkslots = {1,2,3,4,5,6}
	local offset = filter.name
	local value = 0
	for _, slot in pairs(checkslots) do
		local start, duration, runeReady = GetRuneCooldown(slot)
		if runeReady or (GetTime()+offset>start+duration) then
			value = value +1
		end
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

RegisterFilter("DEBUFFENERGY",{
	name = "减益结束时能量",
	color = "ffff00",
	class = {"MONK","ROUGE"},
	desc = "当所指定技能冷却完成时自身的能量值,可能会大于能量上限",
	keys = {
		name = {
			name = "法术名称",
		},
		unit = {
			name = "能量值",
		},
		value = {
			name = "能量值",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.DEBUFFENERGY(self,filter,unit)
	assert(filter.name)
	local speed = GetPowerRegen()
	local power = UnitPower("player") or 0
	local powermax = UnitPowerMax("player") or 1
	local name, remain
	if type(filter.name) == "table" then
		name = filter.name[1]
		remain = tonumber(filter.name[2] or 0)
	else
		name = filter.name
		remain = 0
	end
	local tfilter = {
		name = name,
		rv = true,
		unit = filter.unit,
		greater = true,
	}
	local rv = self:DEBUFFSELF(tfilter) or 0
	if rv<remain then
		rv = 0
	else
		rv =  rv - remain
	end
	local value = (rv)*speed
	--AAK:debug(speed,((start+duration-GetTime())),power,value+power)
	value = power + value
	local start,duration = GetSpellCooldown(5217)
	if start and (duration - (GetTime() - start) < rv) then
		value = value + 60
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
	do
		return true
	end
end
RegisterFilter("BUFFENERGY",{
	name = "增益结束时能量",
	color = "ffff00",
	class = {"MONK","ROUGE"},
	desc = "当所指定技能冷却完成时自身的能量值,可能会大于能量上限",
	keys = {
		name = {
			name = "法术名称",
		},
		unit = {
			name = "能量值",
		},
		value = {
			name = "能量值",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.BUFFENERGY(self,filter,unit)
	assert(filter.name)
	local speed = GetPowerRegen()
	local power = UnitPower("player") or 0
	local powermax = UnitPowerMax("player") or 1
	local name, remain
	if type(filter.name) == "table" then
		name = filter.name[1]
		remain = tonumber(filter.name[2] or 0)
	else
		name = filter.name
		remain = 0
	end
	local tfilter = {
		name = name,
		rv = true,
		unit = filter.unit,
		greater = true,
	}
	local rv = self:BUFF(tfilter) or 0
	if rv<remain then
		rv = 0
	else
		rv =  rv - remain
	end
	local value = (rv)*speed
	--AAK:debug(speed,((start+duration-GetTime())),power,value+power)
	value = power + value
	local start,duration = GetSpellCooldown("猛虎之怒")
	if start and ( duration - (GetTime() - start) < rv )then
		value = value + 60
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
	do
		return true
	end
end

RegisterFilter("NEXTENERGY",{
	name = "冷却时能量",
	color = "ffff00",
	class = {"MONK","ROUGE"},
	desc = "当所指定技能冷却完成时自身的能量值,可能会大于能量上限",
	keys = {
		name = {
			name = "法术名称",
		},
		value = {
			name = "能量值",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.NEXTENERGY(self,filter,unit)
	assert(filter.name)
	local speed = GetPowerRegen()
	local power = UnitPower("player") or 0
	local powermax = UnitPowerMax("player") or 1
	local start,duration = GetSpellCooldown(filter.name)
	local value = ((start+duration-GetTime()))*speed
	if start == 0 then
		value = 0
	end
	--AAK:debug(speed,((start+duration-GetTime())),power,value+power)
	value = power + value
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
	do
		return true
	end
end

RegisterFilter("ENERGYMAXTIME",{
	name = "能量满时间",
	color = "ffff00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.ENERGYMAXTIME(self,filter,unit)
	local speed = GetPowerRegen()
	local power = UnitPower("player") or 0
	local powermax = UnitPowerMax("player") or 100
	local value = (powermax - power)/speed
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

RegisterFilter("TIMEENERGY",{
	name = "未来的能量值",
	desc = "",
	color = "ffff00",
	keys = {
		value = {
			name = "能量值(*)",
			desc = "输入负值将使用(最大能量值)作为基准",
		},
		name = {
			name = "时间",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.TIMEENERGY(self,filter,unit)
	local speed = GetPowerRegen()
	local power = UnitPower("player") or 0
	power = power + speed * (filter.name or 0)
	local powermax = UnitPowerMax("player") or 100
	local value = power
	local fvalue = filter.value
	if fvalue<0 then
		fvalue = fvalue + powermax
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

RegisterFilter("ECLIPSESTATUS",{
	name = "平衡德'蚀'状态",
	desc = "",
	color = "ffff00",
	keys = {
	},
	subtypes = {
		SUN = {
			name = "日蚀",
		},
		MOON = {
			name = "月蚀",
		},
		NEITHER = {
			name = "不在蚀中",
		},
		BOTH = {
			name = "日蚀或月蚀",
		},
	},
}
)
function AirjAutoKey.ECLIPSESTATUS(self,filter,unit)
	assert(filter.subtype)
	local _,class = UnitClass("player")
	if class ~= "DRUID" then
		return
	end
	local castingvalue = 0
	local filtertmp = {type = "CASTING",greater = true}
	filtertmp.name = "星火术",
	locla cxinghuo = self:CheckFilter(filtertmp)
	filtertmp.name = "愤怒",
	locla cfennu = self:CheckFilter(filtertmp)
	filtertmp.name = "星涌术",
	locla cxingyong = self:CheckFilter(filtertmp)
	local direction = GetEclipseDirection()
	local power = UnitPower("player",8)
	local value
	if direction == "sun" or direction == "none" then
		if cxinghuo then
			castingvalue = power>0 and 40 or 20
		elseif cxingyong then
			castingvalue = power>0 and 40 or 20
		end
		if power + castingvalue >= 100 then
			value = 1
		elseif power + castingvalue >=0 then
			value = 0
		else
			value = -1
		end
	else
		if cfennu then
			castingvalue = power<0 and -30 or -15
		elseif cxingyong then
			castingvalue = power<0 and -40 or -20
		end
		if power + castingvalue <= -100 then
			value = -1
		elseif power + castingvalue <=0 then
			value = 0
		else
			value = 1
		end
	end
	local subtype = filter.subtype
	if subtype =="SUN" and value == 1 then
		return true
	elseif subtype =="MOON" and value == -1 then
		return true
	elseif subtype =="BOTH" and (value == -1 or value == 1) then
		return true
	elseif subtype =="NEITHER" and value == 0 then
		return true
	end
	return false
end

RegisterFilter("ECLIPSEDIR",{
	name = "平衡德'蚀'方向",
	desc = "",
	color = "ffff00",
	keys = {
	},
	subtypes = {
		SUN = {
			name = "月蚀->日蚀",
		},
		MOON = {
			name = "日蚀->月蚀",
		},
	},
}
)
function AirjAutoKey.ECLIPSEDIR(self,filter,unit)
	assert(filter.subtype)
	local value
	local direction = GetEclipseDirection()
	if direction == "sun" then
		value = 1
	elseif direction == "none" then
		value = 0
	else
		value = -1
	end
	local subtype = filter.subtype
	if subtype =="SUN" and value == 1 then
		return true
	elseif subtype =="MOON" and value == -1 then
		return true
	end
end

RegisterFilter("COMBOPOINT",{
	name = "连击点数",
	desc = "",
	color = "ffff00",
	keys = {
		value = {
			name = "连击点个数",
		},
		greater = {
		},
		unit = {
		},
	},
	subtypes = {
		INCLUDEPRE = {
			name = "包括预感",
		},
	},
}
)
function AirjAutoKey.COMBOPOINT(self,filter,unit)
	unit = filter.unit or "target"
	local rc = GetComboPoints("player",unit)
	local bc
	if filter.subtype == "INCLUDEPRE" then
		bc = self:BUFF(
		{
			subtype = "COUNT",
			unit = "player",
			name = "预感",
			rv = true,
		})
		if not bc then bc = 0 end
	else
		bc = 0
	end
	local value
	if rc == 5 then
		value = rc + bc
	else
		value = rc
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
RegisterFilter("ZUNYAN",{
	name = "刺客尊严",
	desc = "",
	color = "ffff00",
	keys = {
		greater = {
		},
		value = {
		},
	},
}
)
function AirjAutoKey.ZUNYAN(self,filter,unit)
	local value = GetTime() - (AirjAutoKey.lastZunYan or 0)
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

RegisterFilter("TOTEMTIME",{
	name = "萨满图腾",
	desc = "",
	color = "ffff00",
	keys = {
		name = {
			name = "图腾名称",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
	subtypes = {
		[2] = {
			name = "土图腾",
		},
		[1] = {
			name = "火图腾",
		},
		[3] = {
			name = "水图腾",
		},
		[4] = {
			name = "空气图腾",
		},
	},
}
)
function AirjAutoKey.TOTEMTIME(self,filter,unit)
	assert(filter.subtype)
	local names = toKeyTable(filter.name)
	local value = 0
	if filter.subtype then
		local haveTotem, name, startTime, duration = GetTotemInfo(tonumber(filter.subtype))
		if names[name] or not filter.name then
			value = startTime + duration - GetTime()
		end
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

--combat logs


RegisterFilter("BEHITEDCNT",{
	name = "被近战击中次数",
	color = "00ffff",
	keys = {
		unit = {name="时间"},
		value = {},
		greater = {},
	},
}
)
function AirjAutoKey.BEHITEDCNT(self,filter,unit)
	local value = 0
	local time = tonumber(filter.name) or 5
	local guid = UnitGUID(filter.unit or "player")
	for guid, timestamp in pairs(self.beHitList[guid] or {}) do
		if GetTime() - (timestamp or 0) < time then
			value = value + 1
		end
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end


RegisterFilter("SPELLHITCNT",{
	name = "技能击中数量",
	color = "00ffff",
	keys = {
		value = {},
		unit = {name="时间"},
		name = {},
		greater = {},
	},
}
)
function AirjAutoKey.SPELLHITCNT(self,filter,unit)
	local value = 0
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local time = tonumber(filter.unit or "player") or 5
	local data = self.aoeSpellHit[name] or {}
	if GetTime() - (data.timestamp or 0) < time then
		for k,v in pairs(data.guids or {}) do
			value = value + 1
		end
	end
	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end

RegisterFilter("DAMAGETAKEN",{
	name = "承受伤害",
	desc = "",
	color = "ff7f00",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "持续时间(秒)",
			desc = "默认5秒,最大30秒",
		},
		value = {
			name = "比例",
		},
		greater = {
		},
	},
	subtypes = {
		CMPSELF = {
			name = "对比自身",
		},
	},
}
)
function AirjAutoKey.DAMAGETAKEN(self,filter,unit)
	local currentTime = GetTime()
	local total = 0
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit)
	for k,v in pairs(self.damageList[guid] or {}) do
		if k > currentTime -(tonumber(filter.name) or 5) then
			total = total + v
		end
	end
	local maxhealth
	if filter.subtype == "CMPSELF" then
		maxhealth= UnitHealthMax("player")
	else
		maxhealth= UnitHealthMax(filter.unit or unit)
	end
	if maxhealth == 0 then
		maxhealth = 1
	end
	if (total/maxhealth)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("DAMAGETAKENSWING",{
	name = "承受平砍伤害",
	desc = "",
	color = "ff7f00",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "持续时间(秒)",
			desc = "默认5秒,最大30秒",
		},
		value = {
			name = "比例",
		},
		greater = {
		},
	},
	subtypes = {
		CMPSELF = {
			name = "对比自身",
		},
	},
}
)
function AirjAutoKey.DAMAGETAKENSWING(self,filter,unit)
	local currentTime = GetTime()
	local total = 0
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit)
	for k,v in pairs(self.damageListSwing[guid] or {}) do
		if k > currentTime -(tonumber(filter.name) or 5) then
			total = total + v
		end
	end
	local maxhealth
	if filter.subtype == "CMPSELF" then
		maxhealth= UnitHealthMax("player")
	else
		maxhealth= UnitHealthMax(filter.unit or unit)
	end
	if maxhealth == 0 then
		maxhealth = 1
	end
	if (total/maxhealth)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("DAMAGETAKENMELEE",{
	name = "承受平砍近战",
	desc = "",
	color = "ff7f00",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "持续时间(秒)",
			desc = "默认5秒,最大30秒",
		},
		value = {
			name = "比例",
		},
		greater = {
		},
	},
	subtypes = {
		CMPSELF = {
			name = "对比自身",
		},
	},
}
)
function AirjAutoKey.DAMAGETAKENMELEE(self,filter,unit)
	local currentTime = GetTime()
	local total = 0
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit)
	for k,v in pairs(self.damageListMelee[guid] or {}) do
		if k > currentTime -(tonumber(filter.name) or 5) then
			total = total + v
		end
	end
	local maxhealth
	if filter.subtype == "CMPSELF" then
		maxhealth= UnitHealthMax("player")
	else
		maxhealth= UnitHealthMax(filter.unit or unit)
	end
	if maxhealth == 0 then
		maxhealth = 1
	end
	if (total/maxhealth)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end


RegisterFilter("TIMETODIE",{
	name = "死亡需要时间",
	color = "ff7f00",
	desc = "多用于判定是否需要释放DOT类技能",
	keys = {
		value = {
			name = "秒",
		},
		unit = {
			name = "测试单位",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.TIMETODIE(self,filter,unit)
	local currentTime = GetTime()
	local startTime = currentTime
	local total = 0
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit)
	for k,v in pairs(self.damageList[guid] or {}) do
		if k > currentTime -5 then
			if startTime > k then
				startTime = k
			end
			total = total + v
		end
	end
	local health= UnitHealth(filter.unit or unit)
	local dps = total/max(2,currentTime-startTime+0.5)
	local value = health/dps
	if value<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end
RegisterFilter("SWINGTIME",{
	name = "普通攻击时间",
	color = "ff7f00",
	keys = {
		name = {
			name = "偏移量(秒)",
			desc = "可解决一些延迟问题,负数将使记录的时间向过去偏移",
		},
		unit = {
			name = "测试单位",
		},
		value = {
			name = "经过时间",
		},
		greater = {
		},
	},
	subtypes = {
		JUSTSWING = {
			name = "距离上次攻击",
		},
		NEXTSWING = {
			name = "距离下次攻击",
		},
		ANYSWING = {
			name = "距离任何攻击",
		},
	},
}
)
function AirjAutoKey.SWINGTIME(self,filter,unit)
	assert(filter.subtype)
	local currentTime = GetTime()
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit)
	local swingtime = self.swingTime[guid] or 0
	local nextswing = swingtime + UnitAttackSpeed(filter.unit or unit)
	local offset = tonumber(filter.name) or 0
	local value
	if filter.subtype == JUSTSWING then
		value = abs(currentTime - swingTime - offset)
	elseif filter.subtype == NEXTSWING then
		value = abs(nextswing - swingTime - offset)
	else
		value = min(abs(currentTime - nextswing - offset),abs(currentTime - swingtime - offset))
	end
	if value<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("LASTCASTSEND",{
	name = "技能发送间隔",
	color = "ff7f00",
	desc = "距离上次指定技能发送的时间间隔",
	keys = {
		name = {
			name = "技能名称",
			desc = "",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.LASTCASTSEND(self,filter,unit)
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local castSend = self.castSentList[name] or 0
	local value = GetTime() - castSend
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
RegisterFilter("CASTSTART",{
	name = "曾经开始释放",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		unit = {
			name = "测试单位",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.CASTSTART(self,filter,unit)
	assert(filter.name)
	local ctime = GetTime()

	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit or "player")
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local list = self.castStartList[name] or {}
	local value = list[guid]
	if value then
		value = ctime - value
	else
		value = 30
	end
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end


RegisterFilter("CASTSTARTALL",{
	name = "曾经开始释放任意目标",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.CASTSTARTALL(self,filter,unit)
	assert(filter.name)
	local ctime = GetTime()
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local value = self.allCastStartList[name]
	if value then
		value = ctime - value
	else
		value = 30
	end
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("CASTSUCCESSED",{
	name = "曾经释放法术",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		unit = {
			name = "测试单位",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.CASTSUCCESSED(self,filter,unit)
	assert(filter.name)
	local ctime = GetTime()
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit or "player")
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local list = self.castSuccessList[name] or {}
	local value = list[guid]
	if value then
		value = ctime - value
	else
		value = 30
	end
	--print(value)
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end


RegisterFilter("ALLCASTSUCCESSED",{
	name = "曾经释放任意目标",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.ALLCASTSUCCESSED(self,filter,unit)
	assert(filter.name)
	local ctime = GetTime()
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local value = self.allCastSuccessList[name]
	if value then
		value = ctime - value
	else
		value = 30
	end
	--print(value)
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("AURALOG",{
	name = "战斗记录光环",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		unit = {
			name = "测试单位",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AURALOG(self,filter,unit)
	assert(filter.name)
	local ctime = GetTime()
	unit = filter.unit or "player"
	local guid = UnitGUID(filter.unit or unit or "player")
	local list = self.auraList[filter.name] or {}
	local value
	if list[guid] then
		value = ctime - list[guid]
	else
		value = 0
	end
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end

RegisterFilter("AURANUM",{
	name = "光环数量",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "个数",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AURANUM(self,filter,unit)
	assert(filter.name)
	local time = filter.unit or 60
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local list = self.auraList[name] or {}
	local value = 0
	local currentTime = GetTime()
	for k,v in pairs(list) do
		if v > currentTime - time then
			value = value + 1
		end
	end
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end
RegisterFilter("DOTNUM",{
	name = "DOT数量",
	color = "ff7f00",
	desc = "",
	keys = {
		value = {
			name = "个数",
		},
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.DOTNUM(self,filter,unit)
	assert(filter.name)
	local name = tonumber(filter.name) and GetSpellInfo(tonumber(filter.name)) or filter.name
	local list = self.dotList[name] or {}
	local value = 0
	for k,v in pairs(list) do
		value = value + 1
	end
	if (value)<=(filter.value or 0) then
		return not filter.greater and true or false
	else
		return filter.greater and true or false
	end
end


RegisterFilter("AIRSELF",{
	name = "AIR自身优先",
	color = "ffbf00",
	desc = "",
	keys = {
		value = {
			name = "倍数",
		},
	},
}
)
function AirjAutoKey.AIRSELF(self,filter,unit)
	local value = 1
	unit = self.raidUnit
	if (UnitIsUnit("player",unit)) then
		value = filter.value or 1.5
	end
	self.airCurrent = (value) * (self.airCurrent or 1)
	return true
end
RegisterFilter("AIRRANGE",{
	name = "AIR近距离优先",
	color = "ffbf00",
	desc = "",
	keys = {
		greater = {},
	},
}
)
function AirjAutoKey.AIRRANGE(self,filter,unit)
	local value = 1
	unit = self.raidUnit
	local tfilter = {
		name = "player",
		unit = unit,
		rv = true,
	}
	local value = self:HDRANGE(tfilter)
	if value then
		if filter.greater then
			self.airCurrent = (20 + value) * (self.airCurrent or 1)
		else
			self.airCurrent = (exp(-value)) * (self.airCurrent or 1)
		end
	end
	return true
end
RegisterFilter("AIRLOWHEALTH",{
	name = "AIR低血量优先",
	color = "ffbf00",
	desc = "",
	keys = {
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRLOWHEALTH(self,filter,unit)
	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true
	local value = self:HEALTH(tfilter)
	if value then
		if filter.greater then
			self.airCurrent = value * (self.airCurrent or 1)
		else
			self.airCurrent = (exp(-value)) * (self.airCurrent or 1)
		end
	end
	return true
end

RegisterFilter("AIRHIGHHEALTH",{
	name = "AIR高血量优先",
	color = "ffbf00",
	desc = "",
	keys = {
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRHIGHHEALTH(self,filter,unit)
	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true
	local value = self:HEALTH(tfilter,unit)
	if value then
		if filter.greater then
			self.airCurrent = (exp(-value)) * (self.airCurrent or 1)
		else
			self.airCurrent = value * (self.airCurrent or 1)
		end
	end
	return true
end


RegisterFilter("AIRBUFF",{
	name = "AIR低BUFF优先",
	color = "ffbf00",
	desc = "",
	keys = {
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRBUFF(self,filter,unit)

	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true
	local value = self:BUFFSELF(tfilter,unit) or 0
	if value then
		if filter.greater then
			self.airCurrent = (1+value/30) * (self.airCurrent or 1)
		else
			self.airCurrent = exp(-value/30) * (self.airCurrent or 1)
		end
	end
	return true
end


RegisterFilter("AIRDEBUFF",{
	name = "AIR低DEBUFF优先",
	color = "ffbf00",
	desc = "",
	keys = {
		name = {
			name = "技能名称",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRDEBUFF(self,filter,unit)
	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true
	local value = self:DEBUFFSELF(tfilter) or 0
	if filter.greater then
		self.airCurrent = (1+value/30) * (self.airCurrent or 1)
	else
		self.airCurrent = exp(-value/30) * (self.airCurrent or 1)
	end
	return true
end


local raidDebuffDots = {strsplit(",","邪火炸弹,不稳定的宝珠,献祭,迅猛突袭,血液沸腾,死灵印记,邪能狂怒,180389,命运相连,幻影之伤,暗影之缚,压倒能量,堕落者之赐,暗言术：恶,邪能水晶,魔能喷涌,灵能涌动,点燃,腐蚀序列,枷锁酷刑,暗影之力,裂伤之触,玛诺洛斯凝视")}
local raidDebuffComingDamage = {strsplit(",","啸风战斧,炮击,188929,毁灭之触,毁灭之种,谴责法令,聚焦混乱,精炼混乱,玷污,强化玛诺洛斯凝视")}

RegisterFilter("AIRRAIDDOT",{
	name = "AIR团队DOT优先",
	color = "ffbf00",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRRAIDDOT(self,filter,unit)
	local count = 0;
	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true

	filters.name = raidDebuffDots

	if self:DEBUFF(tfilter) then
		count = count + 1;
	end
	--	for i,dotName in ipairs(raidDebuffDots) do
	--		filters.name = dotName
	--		if AirjAutoKey:CheckFilter(filters,unit) then
	--			count = count + 1;
	--		end
	--	end
	self.airCurrent = (count+2) * (self.airCurrent or 1)
	return true
end

RegisterFilter("AIRRAIDCHD",{
	name = "AIR团队高伤害优先",
	color = "ffbf00",
	desc = "",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.AIRRAIDCHD(self,filter,unit)
	local count = 0;
	if not self.raidUnit then return true end
	local tfilter = copy(filter)
	tfilter.unit = self.raidUnit
	tfilter.rv = true
	filters.name = raidDebuffComingDamage

	if AirjAutoKey:DEBUFF(tfilter) then
		count = count + 1;
	end
	--	for i,dotName in ipairs(raidDebuffComingDamage) do
	--		filters.name = dotName
	--		if AirjAutoKey:CheckFilter(filters,unit) then
	--			dump(filters)
	--			count = count + 1;
	--		end
	--	end
	self.airCurrent = (count+1) * (self.airCurrent or 1)
	return true
end


RegisterFilter("RAIDDOT",{
	name = "团队DOT",
	color = "00ff80",
	desc = "",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.RAIDDOT(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.name = raidDebuffDots
	return AirjAutoKey:DEBUFF(tfilter)
end

RegisterFilter("RAIDCHD",{
	name = "团队高伤害",
	color = "00ff80",
	desc = "",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.RAIDCHD(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.name = raidDebuffComingDamage
end


RegisterFilter("DBMAOETIME",{
	name = "DBMAOE时间",
	color = "ffbf40",
	desc = "",
	keys = {
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)
function AirjAutoKey.DBMAOETIME(self,filter,unit)

	return true
end

--pvp
--[[
local spellIds = {
	-- Death Knight
	[108194] = "CC",		-- Asphyxiate
	[115001] = "CC",		-- Remorseless Winter
	[47476]  = "Silence",		-- Strangulate
	[96294]  = "Root",		-- Chains of Ice (Chilblains)
	[45524]  = "Snare",		-- Chains of Ice
	[50435]  = "Snare",		-- Chilblains
	--[43265]  = "Snare",		-- Death and Decay (Glyph of Death and Decay) - no way to distinguish between glyphed spell and normal. :(
	[115000] = "Snare",		-- Remorseless Winter
	[115018] = "ImmuneControl",		-- Desecrated Ground
	--	[48707]  = "ImmuneSpell",	-- Anti-Magic Shell
	[48707]  = "ImmuneSpellControl",	-- Anti-Magic Shell
	[48792]  = "Other",		-- Icebound Fortitude
	[49039]  = "Other",		-- Lichborne
	--[51271] = "Other",		-- Pillar of Frost
	-- Death Knight Ghoul
	[91800]  = "CC",		-- Gnaw
	[91797]  = "CC",		-- Monstrous Blow (Dark Transformation)
	[91807]  = "Root",		-- Shambling Rush (Dark Transformation)
	-- Druid

	[163505] = "CC",		-- fair
	[113801] = "CC",		-- Bash (Force of Nature - Feral Treants)
	[102795] = "CC",		-- Bear Hug
	[33786]  = "CC",		-- Cyclone
	[99]     = "CC",		-- Disorienting Roar
	[2637]   = "CC",		-- Hibernate
	[22570]  = "CC",		-- Maim
	[5211]   = "CC",		-- Mighty Bash
	[9005]   = "CC",		-- Pounce
	[102546] = "CC",		-- Pounce (Incarnation)
	[114238] = "Silence",		-- Fae Silence (Glyph of Fae Silence)
	[81261]  = "Silence",		-- Solar Beam
	[339]    = "Root",		-- Entangling Roots
	[113770] = "Root",		-- Entangling Roots (Force of Nature - Balance Treants)
	[19975]  = "Root",		-- Entangling Roots (Nature's Grasp)
	[45334]  = "Root",		-- Immobilized (Wild Charge - Bear)
	[102359] = "Root",		-- Mass Entanglement
	[50259]  = "Snare",		-- Dazed (Wild Charge - Cat)
	[58180]  = "Snare",		-- Infected Wounds
	[61391]  = "Snare",		-- Typhoon
	[127797] = "Snare",		-- Ursol's Vortex
	--[???] = "Snare",		-- Wild Mushroom: Detonate
	-- Druid Symbiosis
	[110698] = "CC",		-- Hammer of Justice (Paladin)
	[113004] = "CC",		-- Intimidating Roar [Fleeing in fear] (Warrior)
	[113056] = "CC",		-- Intimidating Roar [Cowering in fear] (Warrior)
	[126458] = "Disarm",		-- Grapple Weapon (Monk)
	[110693] = "Root",		-- Frost Nova (Mage)
	--[110610] = "Snare",		-- Ice Trap (Hunter)

	[110791] = "Other",		-- Evasion (Rogue)
	[110575] = "Other",		-- Icebound Fortitude (Death Knight)
	[122291] = "Other",		-- Unending Resolve (Warlock)
	-- Hunter
	[117526] = "CC",		-- Binding Shot
	[3355]   = "CC",		-- Freezing Trap
	[3355]   = "LC",		-- Freezing Trap
	[1513]   = "CC",		-- Scare Beast
	[19503]  = "CC",		-- Scatter Shot
	[19386]  = "CC",		-- Wyvern Sting
	[19386]  = "LC",		-- Wyvern Sting
	[34490]  = "Silence",		-- Silencing Shot
	[19185]  = "Root",		-- Entrapment
	[64803]  = "Root",		-- Entrapment
	[128405] = "Root",		-- Narrow Escape
	[35101]  = "Snare",		-- Concussive Barrage
	[5116]   = "Snare",		-- Concussive Shot
	[61394]  = "Snare",		-- Frozen Wake (Glyph of Freezing Trap)
	[13810]  = "Snare",		-- Ice Trap
	[19263]  = "Immune",		-- Deterrence
	-- Hunter Pets
	[90337]  = "CC",		-- Bad Manner (Monkey)
	[24394]  = "CC",		-- Intimidation
	[126246] = "CC",		-- Lullaby (Crane)
	[126355] = "CC",		-- Paralyzing Quill (Porcupine)
	[126423] = "CC",		-- Petrifying Gaze (Basilisk)
	[50519]  = "CC",		-- Sonic Blast (Bat)
	[56626]  = "CC",		-- Sting (Wasp)
	[96201]  = "CC",		-- Web Wrap (Shale Spider)
	[50541]  = "Disarm",		-- Clench (Scorpid)
	[91644]  = "Disarm",		-- Snatch (Bird of Prey)
	[90327]  = "Root",		-- Lock Jaw (Dog)
	[50245]  = "Root",		-- Pin (Crab)
	[54706]  = "Root",		-- Venom Web Spray (Silithid)
	[4167]   = "Root",		-- Web (Spider)
	[50433]  = "Snare",		-- Ankle Crack (Crocolisk)
	[54644]  = "Snare",		-- Frost Breath (Chimaera)
	[54216]  = "Other",		-- Master's Call (root and snare immune only)
	-- Mage
	[118271] = "CC",		-- Combustion Impact
	[44572]  = "CC",		-- Deep Freeze
	[44572]  = "CC",		-- Deep Freeze
	[31661]  = "CC",		-- Dragon's Breath
	[118]    = "CC",		-- Polymorph
	[118]    = "LC",		-- Polymorph
	[61305]  = "CC",		-- Polymorph: Black Cat
	[28272]  = "CC",		-- Polymorph: Pig
	[61721]  = "CC",		-- Polymorph: Rabbit
	[61780]  = "CC",		-- Polymorph: Turkey
	[28271]  = "CC",		-- Polymorph: Turtle
	[82691]  = "CC",		-- Ring of Frost
	[82691]  = "LC",		-- Ring of Frost
	[102051] = "Silence",		-- Frostjaw (also a root)
	[102051] = "LC",		-- Frostjaw (also a root)
	[55021]  = "Silence",		-- Silenced - Improved Counterspell
	[122]    = "Root",		-- Frost Nova
	[111340] = "Root",		-- Ice Ward
	[121288] = "Snare",		-- Chilled (Frost Armor)
	[120]    = "Snare",		-- Cone of Cold
	[116]    = "Snare",		-- Frostbolt
	[44614]  = "Snare",		-- Frostfire Bolt
	[113092] = "Snare",		-- Frost Bomb
	[31589]  = "Snare",		-- Slow
	[45438]  = "Immune",		-- Ice Block
	[115760] = "ImmuneSpell",	-- Glyph of Ice Block
	-- Mage Water Elemental
	[33395]  = "Root",		-- Freeze
	-- Monk
	[123393] = "CC",		-- Breath of Fire (Glyph of Breath of Fire)
	[126451] = "CC",		-- Clash
	[122242] = "CC",		-- Clash (not sure which one is right)
	[119392] = "CC",		-- Charging Ox Wave
	[120086] = "CC",		-- Fists of Fury
	[119381] = "CC",		-- Leg Sweep
	[115078] = "CC",		-- Paralysis
	[115078] = "LC",		-- Paralysis
	[117368] = "Disarm",		-- Grapple Weapon
	[140023] = "Disarm",		-- Ring of Peace
	[137461] = "Disarm",		-- Disarmed (Ring of Peace)
	[137460] = "Silence",		-- Silenced (Ring of Peace)
	[116709] = "Silence",		-- Spear Hand Strike
	[116706] = "Root",		-- Disable
	[113275] = "Root",		-- Entangling Roots (Symbiosis)
	[123407] = "Root",		-- Spinning Fire Blossom
	[116095] = "Snare",		-- Disable
	[118585] = "Snare",		-- Leer of the Ox
	[123727] = "Snare",		-- Dizzying Haze
	[123586] = "Snare",		-- Flying Serpent Kick
	--	[131523] = "ImmuneSpell",	-- Zen Meditation
	[122783] = "ImmuneDamage", -- Sanmogong
	-- Paladin
	[105421] = "CC",		-- Blinding Light
	[105421] = "LC",		-- Blinding Light
	[115752] = "CC",		-- Blinding Light (Glyph of Blinding Light)
	[105593] = "CC",		-- Fist of Justice
	[853]    = "CC",		-- Hammer of Justice
	[119072] = "CC",		-- Holy Wrath
	[20066]  = "CC",		-- Repentance
	[20066]  = "LC",		-- Repentance
	[10326]  = "CC",		-- Turn Evil
	--	[10326]  = "LC",		-- Turn Evil
	[145067] = "CC",		-- Turn Evil (Evil is a Point of View)
	--	[145067] = "LC",		-- Turn Evil (Evil is a Point of View)
	[31935]  = "Silence",		-- Avenger's Shield
	[110300] = "Snare",		-- Burden of Guilt
	[63529]  = "Snare",		-- Dazed - Avenger's Shield
	[20170]  = "Snare",		-- Seal of Justice
	[642]    = "Immune",		-- Divine Shield
	[31821]  = "Other",		-- Aura Mastery
	[1022]   = "Other",		-- Hand of Protection
	-- Priest
	[113506] = "CC",		-- Cyclone (Symbiosis)
	[605]    = "CC",		-- Dominate Mind
	[88625]  = "CC",		-- Holy Word: Chastise
	[88625]  = "LC",		-- Holy Word: Chastise
	[64044]  = "CC",		-- Psychic Horror
	--	[64044]  = "LC",		-- Psychic Horror
	[8122]   = "CC",		-- Psychic Scream
	--	[8122]   = "LC",		-- Psychic Scream
	[113792] = "CC",		-- Psychic Terror (Psyfiend)
	[9484]   = "CC",		-- Shackle Undead
	[9484]   = "LC",		-- Shackle Undead
	[87204]  = "CC",		-- Sin and Punishment
	[87204]  = "LC",		-- Sin and Punishment
	[15487]  = "Silence",		-- Silence
	[64058]  = "Disarm",		-- Psychic Horror
	[113275] = "Root",		-- Entangling Roots (Symbiosis)
	[87194]  = "Root",		-- Glyph of Mind Blast
	[114404] = "Root",		-- Void Tendril's Grasp
	[15407]  = "Snare",		-- Mind Flay
	[47585]  = "Immune",		-- Dispersion
	--	[114239] = "ImmuneSpell",	-- Phantasm
	-- Rogue
	[2094]   = "CC",		-- Blind
	[2094]   = "LC",		-- Blind
	[1833]   = "CC",		-- Cheap Shot
	[1776]   = "CC",		-- Gouge
	[1776]   = "LC",		-- Gouge
	[408]    = "CC",		-- Kidney Shot
	[113953] = "CC",		-- Paralysis (Paralytic Poison)
	[6770]   = "CC",		-- Sap
	[6770]   = "LC",		-- Sap
	[1330]   = "Silence",		-- Garrote - Silence
	[51722]  = "Disarm",		-- Dismantle
	[115197] = "Root",		-- Partial Paralysis
	[3409]   = "Snare",		-- Crippling Poison
	["减速药膏"]   = "Snare",		-- Crippling Poison
	["衰弱之毒"]   = "Snare",		-- Crippling Poison
	[26679]  = "Snare",		-- Deadly Throw
	[119696] = "Snare",		-- Debilitation
	[31224]  = "ImmuneSpell",	-- Cloak of Shadows
	[45182]  = "Other",		-- Cheating Death
	[5277]   = "Other",		-- Evasion
	--[76577]  = "Other",		-- Smoke Bomb
	[88611]  = "Other",		-- Smoke Bomb
	-- Shaman
	[76780]  = "CC",		-- Bind Elemental
	[77505]  = "CC",		-- Earthquake
	[51514]  = "CC",		-- Hex
	[51514]  = "LC",		-- Hex
	[118905] = "CC",		-- Static Charge (Capacitor Totem)
	[113287] = "Silence",		-- Solar Beam (Symbiosis)
	[64695]  = "Root",		-- Earthgrab (Earthgrab Totem)
	[63685]  = "Root",		-- Freeze (Frozen Power)
	[3600]   = "Snare",		-- Earthbind (Earthbind Totem)
	[116947] = "Snare",		-- Earthbind (Earthgrab Totem)
	[77478]  = "Snare",		-- Earthquake (Glyph of Unstable Earth)
	[8034]   = "Snare",		-- Frostbrand Attack
	[147732]   = "Snare",		-- Frostbrand Attack
	[8056]   = "Snare",		-- Frost Shock
	[51490]  = "Snare",		-- Thunderstorm
	[8178]   = "ImmuneSpell",	-- Grounding Totem Effect (Grounding Totem)
	-- Shaman Primal Earth Elemental
	[118345] = "CC",		-- Pulverize
	-- Warlock
	[710]    = "CC",		-- Banish
	[137143] = "CC",		-- Blood Horror
	[137143] = "LC",		-- Blood Horror
	[54786]  = "CC",		-- Demonic Leap (Metamorphosis)
	[5782]   = "CC",		-- Fear
	[5782]   = "LC",		-- Fear
	[118699] = "CC",		-- Fear
	[118699] = "LC",		-- Fear
	[130616] = "CC",		-- Fear (Glyph of Fear)
	[130616] = "LC",		-- Fear (Glyph of Fear)
	[5484]   = "CC",		-- Howl of Terror
	--	[5484]   = "LC",		-- Howl of Terror
	[22703]  = "CC",		-- Infernal Awakening
	[6789]   = "CC",		-- Mortal Coil
	[132412] = "CC",		-- Seduction (Grimoire of Sacrifice)
	[30283]  = "CC",		-- Shadowfury
	[104045] = "CC",		-- Sleep (Metamorphosis)
	[132409] = "Silence",		-- Spell Lock (Grimoire of Sacrifice)
	[31117]  = "Silence",		-- Unstable Affliction
	[18223]  = "Snare",		-- Curse of Exhaustion
	[47960]  = "Snare",		-- Shadowflame
	[110913] = "Other",		-- Dark Bargain
	[104773] = "Other",		-- Unending Resolve
	-- Warlock Pets
	[89766]  = "CC",		-- Axe Toss (Felguard/Wrathguard)
	[115268] = "CC",		-- Mesmerize (Shivarra)
	[115268] = "LC",		-- Mesmerize (Shivarra)
	[6358]   = "CC",		-- Seduction (Succubus)
	[6358]   = "LC",		-- Seduction (Succubus)
	[115782] = "Silence",		-- Optical Blast (Observer)
	[24259]  = "Silence",		-- Spell Lock (Felhunter)
	[118093] = "Disarm",		-- Disarm (Voidwalker/Voidlord)
	-- Warrior
	[7922]   = "CC",		-- Charge Stun
	[118895] = "CC",		-- Dragon Roar
	[5246]   = "CC",		-- Intimidating Shout (aoe)
	--	[5246]   = "LC",		-- Intimidating Shout (aoe)
	[20511]  = "CC",		-- Intimidating Shout (targeted)
	[132168] = "CC",		-- Shockwave
	[107570] = "CC",		-- Storm Bolt
	[132169] = "CC",		-- Storm Bolt
	[18498]  = "Silence",		-- Silenced - Gag Order (PvE only)
	[676]    = "Disarm",		-- Disarm
	[107566] = "Root",		-- Staggering Shout
	[105771] = "Root",		-- Warbringer
	[147531] = "Snare",		-- Bloodbath
	[1715]   = "Snare",		-- Hamstring
	[12323]  = "Snare",		-- Piercing Howl
	[129923] = "Snare",		-- Sluggish (Glyph of Hindering Strikes)
	[137637] = "Snare",		-- Warbringer
	[46924]  = "ImmuneControl",		-- Bladestorm
	["剑刃风暴"]  = "ImmuneControl",		-- Bladestorm
	[23920]  = "ImmuneSpell",	-- Spell Reflection
	[114028] = "ImmuneSpell",	-- Mass Spell Reflection
	["群体反射"] = "ImmuneSpell",	-- Mass Spell Reflection
	[18499]  = "Other",		-- Berserker Rage
	-- Other
	[30217]  = "CC",		-- Adamantite Grenade
	[67769]  = "CC",		-- Cobalt Frag Bomb
	[30216]  = "CC",		-- Fel Iron Bomb
	[107079] = "CC",		-- Quaking Palm
	[107079] = "LC",		-- Quaking Palm
	[13327]  = "CC",		-- Reckless Charge
	[20549]  = "CC",		-- War Stomp
	[25046]  = "Silence",		-- Arcane Torrent (Energy)
	[28730]  = "Silence",		-- Arcane Torrent (Mana)
	[50613]  = "Silence",		-- Arcane Torrent (Runic Power)
	[69179]  = "Silence",		-- Arcane Torrent (Rage)
	[80483]  = "Silence",		-- Arcane Torrent (Focus)
	[129597] = "Silence",		-- Arcane Torrent (Chi)
	[39965]  = "Root",		-- Frost Grenade
	[55536]  = "Root",		-- Frostweave Net
	[13099]  = "Root",		-- Net-o-Matic
	[1604]   = "Snare",		-- Dazed
	-- PvE
	--[123456] = "PvE",		-- This is just an example, not a real spell
}

RegisterFilter("PVPDR",{
	name = "PVP递减",
	desc = "依赖DiminishingReturns",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		stun = {
			name = "眩晕",
		},
		disorient = {
			name = "恐惧",
		},
		incapacitate = {
			name = "变形",
		},
		root = {
			name = "定身",
		},
		silence = {
			name = "沉默",
		},
	},
}
)
function AirjAutoKey.PVPDR(self,filter,unit)
	assert(filter.subtype)
	unit = filter.unit or "player" or "player"
	if DiminishingReturns then
		local f,dad = DiminishingReturns:IterateDR(UnitGUID(unit))
		local ad = dad or {}
		local d = ad[filter.subtype]
		--		dump(d)
		local value
		if not d then
			value = 0
		else
			value = d.expireTime - GetTime()
		end
		if filter.subtype == "stun" then
		--			dump(d)
		end
		if filter.greater then
			if value > (filter.value or 0) then
				return true
			end
		else
			if value <= (filter.value or 0) then
				return true
			end
		end
	end
end

RegisterFilter("PVPDRCNT",{
	name = "PVP递减次数",
	desc = "依赖DiminishingReturns",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "次数",
		},
	},
	subtypes = {
		stun = {
			name = "眩晕",
		},
		disorient = {
			name = "恐惧",
		},
		incapacitate = {
			name = "变形",
		},
		root = {
			name = "定身",
		},
		silence = {
			name = "沉默",
		},
	},
}
)
function AirjAutoKey.PVPDRCNT(self,filter,unit)
	assert(filter.subtype)
	unit = filter.unit or "player" or "player"
	if DiminishingReturns then
		local f,d = DiminishingReturns:IterateDR(UnitGUID(unit))
		d = d or {}
		d = d[filter.subtype]
		local value
		if not d then
			value = -1
		else
			value = d.count
		end
		if filter.greater then
			if value > (filter.value or 0) then
				return true
			end
		else
			if value <= (filter.value or 0) then
				return true
			end
		end
	end
end
]]
--[[
RegisterFilter("PVPDRCONTROL",{
	name = "PVP递减类控制",
	desc = "依赖DiminishingReturns",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
	},
	subtypes = {
		stun = {
			name = "眩晕",
		},
		disorient = {
			name = "恐惧",
		},
		incapacitate = {
			name = "变形",
		},
		root = {
			name = "定身",
		},
		silence = {
			name = "沉默",
		},
	},
}
)
function AirjAutoKey.PVPDRCONTROL(self,filter,unit)
	assert(filter.subtype)
	unit = filter.unit or "player" or "player"
	if DiminishingReturns then
		local f,d = DiminishingReturns:IterateDR(UnitGUID(unit))
		d = d or {}
		d = d[filter.subtype]
		local value
		if d and d.count == 0 then
			return true
		end
	end
end
Silenced			= "_47476;_78675;_15487;_1330;114238;_18498;_25046;31935;31117;102051",
ReducedHealing		= "115804",

Silenced
ReducedHealing

Stunned
Incapacitated
Rooted
Shatterable
Disoriented
Slowed
Feared
Bleeding

CrowdControl
]]

local buffs = {
	health = {
		[21562] = 0.1,
	},
	hots = {
		--pal
		[114917] = 1.8,
		[114163] = 0.1,
		--druid
		[774] = 0.17,
		[155777] = 0.17,
		[145518] = 2,
		[33763] = 0.36,
		[48438] = 0.4,
		--monk
		[124682] = 1.65,
		[115151] = 0.07,
		--priest
		[33076] = 0.2,
		[139] = 0.15,
		--Shaman
		[61295] = 0.1,
		[974] = 0.2,
	},
	fastHots = {
		--pal
		[114917] = 1.8,
		--druid
		[145518] = 2,
		--monk
		[124682] = 1.65,
		--priest
		--Shaman
	},
	shield = {
		[17] = 4.59,
		[11426] = 4.95,
		[152118] = 6.6,
	},
	important = {
		[1044] = 1,
		[53271] = 1,
		[12472] = 2,
		[79206] = 2,
		[132158] = 3,
		[1022] = 3,
	},
	damageReduce = {
		[6940] = 0.3,
	}
}

RegisterFilter("PVPSHOULDSTEAL",{
	name = "PVP STEAL",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "level",
		},
	},
}
)

function AirjAutoKey.PVPSHOULDSTEAL(self,filter,unit)
	unit = filter.unit or "player"
	local buff = {
		unit = unit,
		greater = true,
	}
	local health = {
		unit = unit,
	}
	self.airCurrent = (self.airCurrent or 1)
	local level = filter.value and (filter.value >= 2) and 2 or 1
	if UnitIsUnit(unit,"target") then
		buff.name = buffs.health
		health.value = 0.95
		health.greater = true
		if self:BUFF(buff) and self:HEALTH(health) then
			return true
		end
		buff.name = buffs.hots
		buff.value = 10
		health.value = 1-level*0.25
		health.greater = false
		if self:BUFF(buff) and self:HEALTH(health) then
			return true
		end

		buff.name = buffs.fastHots
		buff.value = 2
		health.value = 1.25 - level*0.25
		health.greater = false
		if self:BUFF(buff) and self:HEALTH(health) then
			return true
		end
		buff.name = buffs.damageReduce
		buff.value = 3
		health.value = 0.8
		health.greater = false
		if self:BUFF(buff) and self:HEALTH(health) then
			return true
		end
	end

	buff.name = buffs.important
	buff.value = 3
	local passed, id = self:BUFF(buff)
	if passed then
		local imLevel = buffs.important[id] or 1
		if imLevel > 1 or level < 2 or UnitIsUnit(unit,"target") then
			self.airCurrent = (self.airCurrent or 1) * (1 + imLevel)
			return true
		end
	end

end


RegisterFilter("PVPDEBUFF",{
	name = "PVP DEBUFF",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		name = {
			name = "类型",
			desc = [[root           = L["Roots"],
stun           = L["Stuns"],
disorient      = L["Disorients"],
silence        = L["Silences"],
taunt          = L["Taunts"],
incapacitate   = L["Incapacitates"],
knockback      = L["Knockbacks"],]]
		},
		value = {
			name = "秒",
		},
	},
}
)

function AirjAutoKey.PVPDEBUFF(self,filter,unit)
	unit = filter.unit or "player"
	filter.name = filter.name or {"stun","disorient","incapacitate"}
	local names = filter.name and toKeyTable(filter.name)
	local spells = {}
	for spellId, cat in pairs(self.drSpells) do
		if not filter.name or names[cat] then
			tinsert(spells,spellId)
		end
	end
	tfilter = copy(filter)
	tfilter.name = spells
	return self:DEBUFF(tfilter)
end

RegisterFilter("PVPDOT",{
	name = "PVP DOT",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)

function AirjAutoKey.PVPDOT(self,filter,unit)
	unit = filter.unit or "player"
	tfilter = copy(filter)
	tfilter.name = self.tmwSpells.debuffs.Dot
	return self:DEBUFF(tfilter)
end


RegisterFilter("PVPROOT",{
	name = "PVP ROOT",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)

function AirjAutoKey.PVPROOT(self,filter,unit)
	unit = filter.unit or "player"
	local names = toKeyTable({"root"})
	local spells = {}
	for spellId, cat in pairs(self.drSpells) do
		if names[cat] then
			tinsert(spells,spellId)
		end
	end
	tfilter = copy(filter)
	tfilter.name = spells
	local cc = self:DEBUFF(tfilter)
	tfilter.name = self.tmwSpells.debuffs.Root
	local slow = self:DEBUFF(tfilter)
	if (filter.greater) then
		return cc or slow
	else
		return cc and slow
	end
end

RegisterFilter("PVPSLOW",{
	name = "PVP SLOW",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)

function AirjAutoKey.PVPSLOW(self,filter,unit)
	unit = filter.unit or "player"
	local names = toKeyTable({"stun","disorient","incapacitate","root"})
	local spells = {}
	for spellId, cat in pairs(self.drSpells) do
		if names[cat] then
			tinsert(spells,spellId)
		end
	end
	tfilter = copy(filter)
	tfilter.name = spells
	local cc = self:DEBUFF(tfilter)
	tfilter.name = self.tmwSpells.debuffs.Slowed
	local slow = self:DEBUFF(tfilter)
	if (filter.greater) then
		return cc or slow
	else
		return cc and slow
	end
end

RegisterFilter("PVPDONTHIT",{
	name = "PVP DONTHIT",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		value = {
			name = "秒",
		},
		greater = {
		},
	},
}
)

function AirjAutoKey.PVPDONTHIT(self,filter,unit)
	unit = filter.unit or "player"
	local except = {
		[ 64044] = true, -- Psychic Horror (Horror effect)
		[137143] = 111397, -- Blood Horror
		[  6789] = true, -- Mortal Coil

	}
	local names = toKeyTable({"disorient","incapacitate"})
	local spells = {}
	for spellId, cat in pairs(self.drSpells) do
		if names[cat] and not except[spellId] then
			tinsert(spells,spellId)
		end
	end
	tfilter = copy(filter)
	tfilter.name = spells
	return self:DEBUFF(tfilter)

end

RegisterFilter("PVPDRREMAIN",{
	name = "PVP递减时间",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "类型",
			desc = [[root           = L["Roots"],
stun           = L["Stuns"],
disorient      = L["Disorients"],
silence        = L["Silences"],
taunt          = L["Taunts"],
incapacitate   = L["Incapacitates"],
knockback      = L["Knockbacks"],]]
		},
		value = {
			name = "秒",
		},
	},
}
)
function AirjAutoKey.PVPDRREMAIN(self,filter,unit)
	unit = filter.unit or "player"
	assert(type(filter.name)=="string")
	local guid = UnitGUID(unit)
	local value
	if not guid or not self.drList[guid] or not self.drList[guid][filter.name] then
		value = 0
	else
		local data = self.drList[guid][filter.name]
		if data.timestamp>GetTime() then
			value = data.timestamp - GetTime()
		else
			value = 0
		end
	end
	local passed = value <= (filter.value or 0)
	if filter.greater then passed = not passed end
	return passed
end

RegisterFilter("PVPDRCOUNT",{
	name = "PVP递减次数",
	desc = "",
	color = "20f020",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "类型",
			desc = [[root           = L["Roots"],
stun           = L["Stuns"],
disorient      = L["Disorients"],
silence        = L["Silences"],
taunt          = L["Taunts"],
incapacitate   = L["Incapacitates"],
knockback      = L["Knockbacks"],]]
		},
		value = {
			name = "秒",
		},
	},
}
)
function AirjAutoKey.PVPDRCOUNT(self,filter,unit)
	unit = filter.unit or "player"
	filter.name = filter.name or {
		"stun",
		"incapacitate",
		"disorient",
		"silence",
	}
	assert(type(filter.name)=="string")
	local guid = UnitGUID(unit)
	local value
	if not guid or not self.drList[guid] or not self.drList[guid][filter.name] then
		value = 0
	else
		local data = self.drList[guid][filter.name]
		if data.timestamp>GetTime() then
			value = data.count
		else
			value = 0
		end
	end
	local passed = value <= (filter.value or 0)
	if filter.greater then passed = not passed end
	return passed
end


--[[

RegisterFilter("PVPLC",{
	name = "PVP控制",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		includeSilence = {
			name = "包括沉默",
		},
		onlySilence = {
			name = "只有沉默",
		},
	},
}
)
function AirjAutoKey.PVPLC(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local spells = {}
	local spellType = {}
	if filter.subtype == "includeSilence" then
		spellType["CC"] = true
		spellType["LC"] = true
		spellType["Silence"] = true
	elseif filter.subtype == "onlySilence" then
		spellType["Silence"] = true
	else
		spellType["CC"] = true
		spellType["LC"] = true
	end

	for k,v in pairs(spellIds) do
		if spellType[v] then
			tinsert(spells,k)
		end
	end
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	return self:DEBUFF(tfilter,unit)
end

RegisterFilter("PVPLCCANTATTACK",{
	name = "PVP控制别打",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
	},
}
)
function AirjAutoKey.PVPLCCANTATTACK(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local spells = {}
	local spellType = {}
	spellType["LC"] = true
	for k,v in pairs(spellIds) do
		if spellType[v] then
			tinsert(spells,k)
		end
	end
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	return self:DEBUFF(tfilter,unit)
end

RegisterFilter("PVPLCSLOW",{
	name = "PVP控制减速",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
	},
}
)
function AirjAutoKey.PVPLCSLOW(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local spells = {}
	local spellType = {}
	spellType["Snare"] = true
	spellType["CC"] = true
	spellType["LC"] = true
	spellType["Root"] = true
	for k,v in pairs(spellIds) do
		if spellType[v] then
			tinsert(spells,k)
		end
	end
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	return self:DEBUFF(tfilter,unit)
end
]]
local immunes = {
	silence = "31821,159438,159630,159652,104773,159546",

	meleePhyics = "642,19263,148467,45438,157913,47585,1022,122470",
	meleeMagic = "642,19263,148467,45438,157913,47585,122783,122470",
	spellSingle = "642,19263,148467,45438,157913,47585,122783,115176,31224,115760,114028,23920,8178,89523",
	spellAOE = "642,19263,148467,45438,157913,47585,31224,122783,115176,115760",

	spellSingleDot = "642,19263,148467,45438,157913,31224,115760,114028,23920,8178,89523,48707",
	spellSingleSteal = "642,19263,148467,45438,157913,31224,115760,8178,89523",
	spellSinglePian = "114028,23920,8178,89523",

	controlPhyics = "642,19263,148467,45438,157913,1022,46924,115018",
	controlMagicSingle = "642,19263,148467,45438,157913,46924,115018,31224,115760,48707,114028,23920,8178,89523",
	controlMagicAOE = "642,19263,148467,45438,157913,46924,115018,31224,115760,48707",

	meleePVE = "642,19263,148467,45438,157913,46924,115018,31224,115760,48707",
	slow = "1044,53271,114896",
}

RegisterFilter("PVPIMNEW",{
	name = "PVP免疫新",
	desc = "",
	color = "20F020",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		silence = {
			name = "仅沉默",
		},
		slow = {
			name = "自由",
		},
		meleePhyics = {
			name = "近战伤害-物理",
		},
		meleeMagic = {
			name = "近战伤害-魔法",
		},
		meleePVE = {
			name = "伤害-PVE",
		},
		spellSingle = {
			name = "法术伤害-单体",
		},
		spellAOE = {
			name = "法术伤害-群体",
		},
		spellSingleDot = {
			name = "法术释放-DOT",
		},
		spellSinglePian = {
			name = "法术释放-偏转",
		},
		spellSingleSteal = {
			name = "法术释放-驱散",
		},
		controlPhyics = {
			name = "控制-物理",
		},
		controlMagicSingle = {
			name = "控制-魔法单体",
		},
		controlMagicAOE = {
			name = "控制-魔法群体",
		},
	},
}
)

function AirjAutoKey.PVPIMNEW(self,filter,unit)
	unit = filter.unit or "player" or "player"
	assert(filter.subtype)
	local spells = {strsplit(",",immunes[filter.subtype])}
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	local tfilterDebuff =
	{
		unit = unit,
		name = {33786},
		greater = filter.greater,
		value = filter.value,
	}
	if filter.subtype == "spellSinglePian" then
		return self:BUFF(tfilter)
	end
	if filter.greater then
		return (self:BUFF(tfilter) or self:DEBUFF(tfilterDebuff))
	else
		return (self:BUFF(tfilter) and self:DEBUFF(tfilterDebuff))
	end
end
RegisterFilter("HASHEALER",{
	name = "竞技场有治疗",
	color = "00ffff",
	desc = "",
	keys = {
	},
}
)
function AirjAutoKey.HASHEALER(self,filter,unit)
	local value = false
	unit = filter.unit or "player"
	local unitList = {}
	for i = 1,5 do
		tinsert(unitList,"arena"..i)
	end
	local healSpec = {
		[65] = true,
		[105] = true,
		[256] = true,
		[257] = true,
		[264] = true,
		[270] = true,
	}
	for i,v in ipairs(unitList) do
		local spec = GetArenaOpponentSpec(i)
		if spec then
			if healSpec[spec] then
				value = true
				break
			end
		end
	end
	if not value then
		value = filter.default or false
	end
	if value then
		return true
	end
end

--[[
RegisterFilter("PVPIM",{
	name = "PVP免疫控制",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		includeMagic = {
			name = "包括魔法",
		},
		onlyMagic = {
			name = "只有魔法",
		},
	},
}
)

function AirjAutoKey.PVPIM(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local spells = {}
	local spellType = {}
	if filter.subtype == "includeMagic" then
		spellType["ImmuneSpell"] = true
		spellType["Immune"] = true
		spellType["ImmuneControl"] = true
		spellType["ImmuneSpellControl"] = true
	elseif filter.subtype == "onlyMagic" then
		spellType["ImmuneSpell"] = true
		spellType["ImmuneSpellControl"] = true
	else
		spellType["Immune"] = true
		spellType["ImmuneControl"] = true
	end

	for k,v in pairs(spellIds) do
		if spellType[v] then
			tinsert(spells,k)
		end
	end
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	local tfilterDebuff =
	{
		unit = unit,
		name = {"旋风"},
		greater = filter.greater,
		value = filter.value,
	}
	return (self:BUFF(tfilter,unit) and self:DEBUFF(tfilterDebuff,unit))
end

RegisterFilter("PVPIMDAMAGE",{
	name = "PVP免疫伤害",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		includeMagic = {
			name = "包括魔法",
		},
		onlyMagic = {
			name = "只有魔法",
		},
	},
}
)


function AirjAutoKey.PVPIMDAMAGE(self,filter,unit)
	unit = filter.unit or "player" or "player"
	local spells = {}
	local spellType = {}
	if filter.subtype == "includeMagic" then
		spellType["ImmuneSpell"] = true
		spellType["Immune"] = true
		spellType["ImmuneDamage"] = true
	elseif filter.subtype == "onlyMagic" then
		spellType["ImmuneSpell"] = true
		spellType["ImmuneDamage"] = true
	else
		spellType["Immune"] = true
	end

	for k,v in pairs(spellIds) do
		if spellType[v] then
			tinsert(spells,k)
		end
	end
	local tfilter =
	{
		unit = unit,
		name = spells,
		greater = filter.greater,
		value = filter.value,
	}
	local tfilterDebuff =
	{
		unit = unit,
		name = {"旋风"},
		greater = filter.greater,
		value = filter.value,
	}
	10
	return (self:BUFF(tfilter,unit) and self:DEBUFF(tfilterDebuff,unit))
end
]]

local castName = {strsplit(",","神圣之光,圣光术,永恒之火,荣耀圣令,圣光闪现,忏悔,治疗波,治疗之涌,妖术,愈合,治疗之触,野性增长,旋风,纠缠根须,抚慰之雾,氤氲之雾,升腾之雾,苦修,快速治疗,意志洞悉,愈合祷言,恐惧,变形术,")}
local castNameHeal = {strsplit(",","神圣之光,圣光术,永恒之火,荣耀圣令,圣光闪现,治疗波,治疗之涌,愈合,治疗之触,野性生长,抚慰之雾,氤氲之雾,升腾之雾,苦修,快速治疗,意志洞悉,愈合祷言")}
local castNameControl = {strsplit(",","忏悔,妖术,旋风,恐惧,变形术,冰霜之颌,冰霜之环")}
RegisterFilter("PVPINTERUPTPRE",{
	name = "PVP他人打断",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "法术名称",
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		help = {
			name = "友善",
		},
	},
}
)
function AirjAutoKey.PVPINTERUPTPRE(self,filter,unit)

	unit = filter.unit or "player" or "player"
	local list = filter.subtype == "help" and self.helpCasting or self.harmCasting
	local data = UnitGUID(unit) and list[UnitGUID(unit)] or {}
	local value
	local name = filter.name
	for k,v in pairs(data) do
		if (self.castProperty[name] or 1000)>(self.castProperty[k] or 1000) then
			if GetTime()<v+filter.value then
				return false
			end
		end
	end
	return true
end

local interruptIds = {
	healChannel = {
		740,--[Tranquility]
		47540,--[Penance]
		64843,--[Divine Hymn]
		115175,--[Soothing Mist]
	},
	heal = {
		82327,--[Holy Radiance]
		596,--[Prayer of Healing]
		2060,--[Heal]
		2061,--[Flash Heal]
		5185,--[Healing Touch]
		8004,--[Healing Surge]
		8936,--[Regrowth]
		19750,--[Flash of Light]
		32546,--[Binding Heal]
		33076,--[Prayer of Mending]
		48438,--[Wild Growth]
		73920,--[Healing Rain]
		77472,--[Healing Wave]
		82326,--[Holy Light]
		1064,--[Chain Heal]
		85222,--[Light of Dawn]
		85673,--[Word of Glory]
		114163,--[Eternal Flame]
		116670,--[Uplift]
		116694,--[Surging Mist]
		120517,--[Halo]
		121135,--[Cascade]
		123986,--[Chi Burst]
		124682,--[Enveloping Mist]
		126135,--[Lightwell]
		136494,--[Word of Glory]
		152118,--[Clarity of Will]
		155245,--[Clarity of Purpose]
	},
	cc = {
		118,--[Polymorph]
		5782,--[Fear]
		19386,--[Wyvern Sting]
		20066,--[Repentance]
		28272,--[Polymorph]
		33786,--[Cyclone]
		51514,--[Hex]
		605,--[Dominate Mind]
		61780,--[Polymorph]
		102051,--[Frostjaw]
		113724,--[Ring of Frost]
		161372,--[Polymorph]
		339,
	},
	hd = {
		48181,--[Haunt]
		116858,--[Chaos Bolt]
	},
}

RegisterFilter("PVPINTERUPTNEW",{
	name = "PVP打断新",
	desc = "",
	color = "20F020",
	keys = {
		unit = {
			name = "测试单位",
		},
		name = {
			name = "类型",
			desc = "heal,cc,hd"
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		evenCant = {
			name = "包括无法打断",
		},
	},
}
)
function AirjAutoKey.PVPINTERUPTNEW(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.subtype = nil
	tfilter.greater = true
	tfilter.value = tfilter.value or 0.2
	local spells = {}
	local types = toKeyTable(filter.name)

	for k, v in pairs(interruptIds) do
		if not filter.name or types[k] then
			for _,id in ipairs(v) do
				table.insert(spells,id)
			end
		end
	end
	tfilter.name = spells
	local fcn;
	if filter.subtype == "evenCant" then
		fcn = self.CASTING
	else
		fcn = self.CASTINGINTERRUPT
	end
	local toRet = fcn(self,tfilter)
	local castLastFilter = {
		value = (filter.value or 0)+0.15,
		unit = filter.unit,
	}
	toRet = toRet and fcn(self,castLastFilter)
	if not filter.name or types["heal"] then
		tfilter.subtype = "START"
		tfilter.name = interruptIds.healChannel
		tfilter.value = (tfilter.value or 0) + 0.15
		toRet = toRet or fcn(self,tfilter)
	end
	return toRet
end

--[[
RegisterFilter("PVPINTERUPT",{
	name = "PVP打断",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		evenCant = {
			name = "包括无法打断",
		},
	},
}
)
function AirjAutoKey.PVPINTERUPT(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.name = castName
	if filter.subtype == "evenCant" then
		return self:CASTING(tfilter)
	else
		return self:CASTINGINTERRUPT(tfilter)
	end
end


RegisterFilter("PVPINTERUPTHEAL",{
	name = "PVP打断治疗",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		evenCant = {
			name = "包括无法打断",
		},
	},
}
)
function AirjAutoKey.PVPINTERUPTHEAL(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.name = castNameHeal
	if filter.subtype == "evenCant" then
		return self:CASTING(tfilter)
	else
		return self:CASTINGINTERRUPT(tfilter)
	end
end

RegisterFilter("PVPINTERUPTCC",{
	name = "PVP打断控制",
	desc = "",
	color = "004080",
	keys = {
		unit = {
			name = "测试单位",
		},
		greater = {
		},
		value = {
			name = "秒",
		},
	},
	subtypes = {
		evenCant = {
			name = "包括无法打断",
		},
	},
}
)
function AirjAutoKey.PVPINTERUPTCC(self,filter,unit)
	local tfilter = copy(filter)
	tfilter.name = castNameControl
	if filter.subtype == "evenCant" then
		return self:CASTING(tfilter)
	else
		return self:CASTINGINTERRUPT(tfilter)
	end
end
--useless
RegisterFilter("NOTINBACK",{
	name = "不在背后时间",
	color = "00ffff",
	keys = {
		value = {},
		greater = {},
	},
}
)
]]
function AirjAutoKey.NOTINBACK(self,filter,unit)
	local value = GetTime() - (self.backtime or 0)

	if filter.greater then
		if value > (filter.value or 0) then
			return true
		end
	else
		if value <= (filter.value or 0) then
			return true
		end
	end
end
RegisterFilter("CASSTINGUNITCASTED",{
	name = "释放技能相同",
	color = "00ffff",
	desc = "",
	keys = {
		name = {
			name = "瞬发技能",
		},
		value = {},
		greater = {},
	},
}
)
function AirjAutoKey.CASSTINGUNITCASTED(self,filter,unit)
  --	local castingSpell = filter.unit
	local spellList = toKeyTable(filter.name)
	local castStartGUID = self.castStartGUID
	if castStartGUID then
		local now = GetTime()
		for k,v in pairs(spellList) do
			local timestamp = self.castSuccessList[k] and self.castSuccessList[k][castStartGUID] or (now-100)
			local value = now-timestamp
			--print(value)
			if filter.greater then
				if value > (filter.value or 0) then
					return true
				end
			else
				if value <= (filter.value or 0) then
					return true
				end
			end
		end
	end
end

RegisterFilter("EQUIPPED",{
	name = "装备物品",
	color = "00ffff",
	desc = "",
	keys = {
		name = {},
	},
})
function AirjAutoKey.EQUIPPED(self,filter,unit)
	local names = toKeyTable(filter.name)
	local value = false
	for k,v in pairs(names) do
		if IsEquippedItem(k) then
			value = true
		end
	end
	return value
end
RegisterFilter("ISTWOHAND",{
	name = "使用双手武器",
	color = "00ffff",
	desc = "",
	keys = {
	},
})
function AirjAutoKey.ISTWOHAND(self,filter,unit)
	local twoHandsList =
	{
		"双手斧",
		"双手锤",
		"双手剑",
		"长柄武器",
	}
	local twohand = false
	for k,v in pairs(twoHandsList) do
		if IsEquippedItemType(v) then
			twohand = true
		end
	end
	return twohand
end
RegisterFilter("FRAME",{
	name = "鼠标框体",
	color = "00ffff",
	desc = "",
	keys = {
		name = {
			name = "框体名称",
			desc = "不区分大小写,只要真室框体名包涵即可,可多个,','分割",
		},
	},
}
)
function AirjAutoKey.FRAME(self,filter,unit)
	local frame = GetMouseFocus()
	assert(filter.name)
	local value
	if frame then
		local names = filter.name
		if type(names) == "table" then
			for k, v in pairs(names) do
				if strfind(strlower(frame:GetName() or ""),strlower(v or "")) then
					value = true
					do
						break
					end
				end
			end
		else
			if strfind(strlower(frame:GetName() or ""),strlower(names or "")) then
				value = true
			end
		end
	end
	if filter.greater then
		if not value then
			return true
		end
	else
		if value then
			return true
		end
	end
end
