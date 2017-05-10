local def 			= require "game/maajan/base/define"
local rule 			= {}

function lastCount(array)
	local sum = 0;
	for i,v in ipairs(array) do
		sum = sum + v;
	end;
	return sum;
end;

local jiang = 0;
g_jiang_tile = 0
g_split_list = {}
function Hu(array)
	if(lastCount(array) == 0) then return 1;end;

	local index = 0;
	for i,v in ipairs(array) do
		if(v ~= 0) then index = i;break;end;
	end;

	if(array[index] == 4) then
		array[index] = 0;
		g_split_list[#g_split_list + 1] = {index,index,index,index}
		if(Hu(array) == 1) then return 1;end;
		array[index] = 4;
		g_split_list[#g_split_list] = nil
	end;
	if(array[index] >= 3) then
		array[index] = array[index] - 3;
		g_split_list[#g_split_list + 1] = {index,index,index}
		if(Hu(array) == 1) then return 1;end;
		array[index] = array[index] + 3;
		g_split_list[#g_split_list] = nil
	end;
	if(jiang == 0 and array[index] >= 2) then
		jiang = 1;
		g_jiang_tile = index;
		array[index] = array[index] - 2;
		g_split_list[#g_split_list + 1] = {index,index}
		if(Hu(array) == 1) then return 1;end;
		array[index] = array[index] + 2;
		g_split_list[#g_split_list] = nil
		jiang = 0;
		g_jiang_tile = 0;
	end;
	if(index > 9) then return 0;end;
	if(index <= 7 and array[index + 1] > 0 and array[index + 2] > 0) then
		array[index] = array[index] - 1;
		array[index + 1] = array[index + 1] - 1;
		array[index + 2] = array[index + 2] - 1;
		g_split_list[#g_split_list + 1] = {index,index + 1,index + 2}
		if(Hu(array) == 1) then return 1;end;
		array[index] = array[index] + 1;
		array[index + 1] = array[index + 1] + 1;
		array[index + 2] = array[index + 2] + 1;
		g_split_list[#g_split_list] = nil
	end;
	return 0;
end;
local function arrayClone(arraySrc)
	local arrayDes = {}
	for k,v in pairs(arraySrc) do
		arrayDes[k] = v
	end
	return arrayDes
end
local HU_INFO = def.CARD_HU_TYPE_INFO
local FAN_UNIQUE_MAP = def.FAN_UNIQUE_MAP
function rule.get_fan_table_res(base_fan_table)
	local res = {describe = "",fan = 0}
	local del_list = {}
	for k,v in ipairs(base_fan_table) do
		local tmp_map = FAN_UNIQUE_MAP[v.name]
		if tmp_map then
			for k1,v1 in ipairs(tmp_map) do
				for k2,v2 in ipairs(base_fan_table) do
					if v1 == v2.name then
						table.insert(del_list,k2)
					end
				end
			end
		end
	end

	for k,v in ipairs(del_list) do
		base_fan_table[v] = nil				
	end
	for k,v in ipairs(base_fan_table) do
		res.describe = res.describe .. v.name .. ","
		res.fan = res.fan + v.fan	
	end

	return res
end
function rule.is_hu(pai,inPai)
	local cache = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
	for k,v in ipairs(pai.shou_pai) do
		cache[v] = cache[v] + 1
	end
	if inPai then cache[inPai] = cache[inPai] + 1 end
	
	--一万到九万， 东-南-西-北  -中-发-白-   春-夏-秋-冬-梅-兰-竹-菊--
	--1-9		    10-13		14-16		20-27
	jiang = 0
	g_jiang_tile = 0
	g_split_list = {}
	local hu = (Hu(cache) == 1 and g_jiang_tile ~= 0)
	if hu then
		local qing_yi_se = true
		local zi_yi_se = true
		local shuang_jian_ke = false  --双箭刻  两个由中、发、白组成的刻子
		local hun_yi_se = false  --牌型中有万、字、风三种牌
		local jian_ke = false --箭刻
		local men_qing = false --门前清
		local ping_hu = false --平胡
		local lao_shao_fu = false --老少副
		local si_an_ke = false --4暗刻
		local san_an_ke = false --3暗刻
		local shuang_an_ke = false --2暗刻
		local lian_liu = false	--连六
		local yao_jiu_ke = 0 --幺九刻
		local ming_gang = 0 --明杠
		local da_san_feng = false	--大三风
		local xiao_san_feng = false	--小三风
		local san_gang = false --三杠
		local quan_dai_yao = true --全带幺

		for k,v in ipairs(pai.ming_pai) do
			g_split_list[#g_split_list + 1] = arrayClone(v)
		end
		local four_tong_list = {}
		local three_tong_list = {}
		local shun_zi_list = {}
		for k,v in ipairs(g_split_list) do
			if #v > 3 then
				four_tong_list[#four_tong_list + 1] = v
			elseif v[1] == v[2] and v[1] == v[3] then
				three_tong_list[#three_tong_list + 1] = v
			elseif #v > 2 then
				shun_zi_list[#shun_zi_list + 1] = v
			end
			for k1,v1 in ipairs(v) do
				if v1 > 9 then qing_yi_se = false end
				if v1 < 10 and k1 > 13 then zi_yi_se = false end
			end
		end
		if g_jiang_tile > 9 then qing_yi_se = false end
		if g_jiang_tile < 10 and g_jiang_tile > 13 then zi_yi_se = false end
		local jian_ke_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 14 and v[1] <= 16 then
				jian_ke_count = jian_ke_count + 1
			end
		end
		if jian_ke_count == 2 then shuang_jian_ke = true end
		if jian_ke_count > 0 then jian_ke = true end

		local has_wan = false--混一色 牌型中有万、字、风三种牌
		local has_zi = false
		local has_feng = false
		for k,v in ipairs(pai.ming_pai) do
			if v[1] <= 9 then
				has_wan = true
			elseif v[1] <= 13 then
				has_zi = true
			elseif v[1] <= 16 then
				has_zi = true
			end
		end
		for k,v in ipairs(pai.shou_pai) do
			if v <= 9 then
				has_wan = true
			elseif v <= 13 then
				has_zi = true
			elseif v <= 16 then
				has_zi = true
			end
		end
		if has_wan and has_zi and has_feng then
			hun_yi_se = true
		end

		if #pai.ming_pai == 0 then
			men_qing = true
		end
		if #shun_zi_list == 4 and #four_tong_list == 0 and #three_tong_list == 0 and g_jiang_tile <= 9 then
			ping_hu = true
		end

		local shao_fu = 0
		local lao_fu = 0
		for k,v in ipairs(shun_zi_list) do
			if v[1] == 1 and v[2] == 2 and v[3] == 3 then
				shao_fu = shao_fu + 1
			end
			if v[1] == 7 and v[2] == 8 and v[3] == 9 then
				lao_fu = lao_fu + 1
			end
		end
		if shao_fu >= 1 and lao_fu >= 1 then
			lao_shao_fu = true
		end
		-- 暗刻 --
		local cache_an_ke = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
		local four_or_three_count = 0
		for k,v in ipairs(pai.shou_pai) do
			cache_an_ke[v] = cache_an_ke[v] + 1
		end
		for k,v in ipairs(cache_an_ke) do
			if v >= 3 then
				four_or_three_count = four_or_three_count + 1
			end
			if four_or_three_count >= 4 then
				si_an_ke = true --4暗刻
			elseif four_or_three_count >= 3 then
				san_an_ke = true --3暗刻
			elseif four_or_three_count >= 2 then
				shuang_an_ke = true --2暗刻
			end
		end
		-- 暗刻 --

		local cache_all_tile = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
		for k,v in ipairs(pai.shou_pai) do
			cache_all_tile[v] = 1
		end
		for k,v in ipairs(pai.ming_pai) do
			for k1,v1 in ipairs(v) do
				if k<5 then
					cache_all_tile[v1] = 1
				end
			end
		end
		cache_all_tile[g_jiang_tile] = 1
		if (cache_all_tile[1] + cache_all_tile[2] + cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] == 6) or
		(cache_all_tile[2] + cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] == 6) or
		(cache_all_tile[3] + cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] + cache_all_tile[8] == 6) or
		(cache_all_tile[4] + cache_all_tile[5] + cache_all_tile[6] + cache_all_tile[7] + cache_all_tile[8] + cache_all_tile[9] == 6) then
			lian_liu = true	--连六
		end

		for k,v in pairs(three_tong_list) do
			if v[1] == 1 and v[1] == 9 and (v[1] <= 16 and v[1] >= 14) then
				yao_jiu_ke = yao_jiu_ke + 1
			end
		end
		for k,v in pairs(four_tong_list) do
			if v[1] == 1 and v[1] == 9 and (v[1] <= 16 and v[1] >= 14) then
				yao_jiu_ke = yao_jiu_ke + 1
			end
			if v[5] == def.GANG_TYPE.MING_GANG and v[5] == def.GANG_TYPE.BA_GANG then
				ming_gang = ming_gang + 1
			end
		end

		-- 大三风 --
		local da_feng_ke_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				da_feng_ke_count = da_feng_ke_count + 1
			end
		end
		for k,v in ipairs(four_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				da_feng_ke_count = da_feng_ke_count + 1
			end
		end
		if da_feng_ke_count >= 3 then
			da_san_feng = true	--大三风
		end
		-- 大三风 --
		-- 小三风 --
		local xiao_feng_ke_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				xiao_feng_ke_count = xiao_feng_ke_count + 1
			end
		end
		for k,v in ipairs(four_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				xiao_feng_ke_count = xiao_feng_ke_count + 1
			end
		end
		if g_jiang_tile >= 10 and g_jiang_tile <= 13 then
			xiao_feng_ke_count = xiao_feng_ke_count + 1
		end
		if xiao_feng_ke_count >= 3 and not da_san_feng then
			xiao_san_feng = true	--小三风
		end
		-- 小三风 --
		-- 三杠 -- 
		if #four_tong_list == 3 then
			san_gang = true
		end
		-- 三杠 --
		-- 全带幺 -- 
		if g_jiang_tile ~= 1 and g_jiang_tile ~= 9 then
			quan_dai_yao = false
		end
		for k,v in ipairs(three_tong_list) do
			if v[1] ~= 1 and v[1] ~= 9 then
				quan_dai_yao = false
			end
		end
		for k,v in ipairs(four_tong_list) do
			if v[1] ~= 1 and v[1] ~= 9 then
				quan_dai_yao = false
			end
		end
		for k,v in ipairs(shun_zi_list) do
			if (v[1] ~= 1 and v[1] ~= 9) and (v[2] ~= 1 and v[2] ~= 9) and (v[3] ~= 1 and v[3] ~= 9) then
				quan_dai_yao = false
			end
		end
		-- 全带幺 --

		local base_fan_table = {}
		if qing_yi_se then table.insert( base_fan_table,HU_INFO.QING_YI_SE) end
		if zi_yi_se then table.insert( base_fan_table,HU_INFO.ZI_YI_SE) end
		if shuang_jian_ke then table.insert( base_fan_table,HU_INFO.SHUANG_JIAN_KE) end
		if hun_yi_se then table.insert( base_fan_table,HU_INFO.HUN_YI_SE) end
		if jian_ke then table.insert( base_fan_table,HU_INFO.JIAN_KE) end
		if men_qing then table.insert( base_fan_table,HU_INFO.MEN_QING) end
		if ping_hu then table.insert( base_fan_table,HU_INFO.PING_HU) end
		if lao_shao_fu then table.insert( base_fan_table,HU_INFO.LAO_SHAO_FU) end
		if si_an_ke then table.insert( base_fan_table,HU_INFO.SI_AN_KE) end
		if san_an_ke then table.insert( base_fan_table,HU_INFO.SAN_AN_KE) end
		if shuang_an_ke then table.insert( base_fan_table,HU_INFO.SHUANG_AN_KE) end
		if lian_liu then table.insert( base_fan_table,HU_INFO.LIAN_LIU) end
		if da_san_feng then table.insert( base_fan_table,HU_INFO.DA_SAN_FENG) end
		if xiao_san_feng then table.insert( base_fan_table,HU_INFO.xiao_san_feng) end
		if san_gang then table.insert( base_fan_table,HU_INFO.SAN_GANG) end
		if quan_dai_yao then table.insert( base_fan_table,HU_INFO.QUAN_DAI_YAO) end
		if ping_hu then table.insert( base_fan_table,HU_INFO.PING_HU) end
		for i=1,yao_jiu_ke do
			table.insert( base_fan_table,HU_INFO.YAO_JIU_KE)
		end
		for i=1,ming_gang do
			table.insert( base_fan_table,HU_INFO.MING_GANG)
		end

		----------特殊牌型---------
		if cache[10] == 2 and cache[11] == 2 and cache[12] == 2 and cache[13] == 2 and cache[14] == 2 
		and cache[15] == 2 and cache[16] == 2
		then
			table.insert(base_fan_table,HU_INFO.DA_QI_XIN)
			return base_fan_table-- 大七星 --
		end

		local normarl_7_dui = true
		local dui_count = 0
		for k,v in ipairs(cache) do
			if v ~= 0 and k < 4
			and cache[k+0] == 2 and cache[k+1] == 2 and cache[k+2] == 2 and cache[k+3] == 2
			and cache[k+4] == 2 and cache[k+5] == 2 and cache[k+6] == 2
			then
				table.insert(base_fan_table,HU_INFO.LIAN_QI_DUI)
				return base_fan_table 
			end

			if v % 2 == 0 then
				dui_count = dui_count + v/2 
			end
			if v ~= 0 and v ~= 2 then
				normarl_7_dui = false
			end
		end
		
		if normarl_7_dui and dui_count == 7 then
			if cache[14] == 2 and cache[15] == 2 and cache[16] == 2 then
				table.insert(base_fan_table,HU_INFO.SAN_YUAN_QI_DUI)
				return base_fan_table-- 三元七对子 --
			end
			if cache[10] == 2 and cache[11] == 2 and cache[12] == 2 and cache[13] == 2 then
				table.insert(base_fan_table,HU_INFO.SI_XI_QI_DUI)
				return base_fan_table-- 四喜七对子 --
			end
			table.insert(base_fan_table,HU_INFO.NORMAL_QI_DUI)
			return base_fan_table-- 七对 --
		end
		---------------------------

	---------------------------------------------------------------------------------------
		-- 大小于五 --
		local da_yu_wu = true;
		local xiao_yu_wu = true;
		for k,v in pairs(cache_all_tile) do
			if v > 0 and k > 4 then
				xiao_yu_wu = false
			end
			if v > 0 and (k < 6 or k > 9) then
				da_yu_wu = false
			end
		end
		if da_yu_wu then
			table.insert(base_fan_table,HU_INFO.DA_YU_WU)
			return base_fan_table
		end
		if xiao_yu_wu then
			table.insert(base_fan_table,HU_INFO.XIAO_YU_WU)
			return base_fan_table
		end
		-- 大小于五 --
		-- 九莲宝灯 --
		if qing_yi_se then
			local cache_bao_deng = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
			for k,v in ipairs(g_split_list) do
				for k1,v1 in ipairs(v) do
					cache_bao_deng[v1] = cache_bao_deng[v1] + 1
				end
			end
			if (cache_bao_deng[1] == 3 or cache_bao_deng[1] == 4) and cache_bao_deng[2] == 1 and cache_bao_deng[3] == 1
			and cache_bao_deng[4] == 1 and cache_bao_deng[5] == 1 and cache_bao_deng[6] == 1 and cache_bao_deng[7] == 1
			and cache_bao_deng[8] == 1 and (cache_bao_deng[9] == 3 or cache_bao_deng[9] == 4) then
				table.insert(base_fan_table,HU_INFO.JIU_LIAN_BAO_DENG)
				return base_fan_table-- 九莲宝灯 --
			end
		end
		-- 九莲宝灯 --
		-- 18罗汉 --
		if #four_tong_list == 4 then
			table.insert(base_fan_table,HU_INFO.LUO_HAN_18)
			return base_fan_table-- 18罗汉 --
		end
		-- 18罗汉 --
		-- 一色双龙会 --
		if qing_yi_se and g_jiang_tile == 5 then
			local shao_fu = 0
			local lao_fu = 0
			for k,v in ipairs(shun_zi_list) do
				if v[1] == 1 and v[2] == 2 and v[3] == 3 then
					shao_fu = shao_fu + 1
				end
				if v[1] == 7 and v[2] == 8 and v[3] == 9 then
					lao_fu = lao_fu + 1
				end
			end
			if shao_fu == 2 and lao_fu == 2 then
				table.insert(base_fan_table,HU_INFO.SHUANG_LONG_HUI)
				return base_fan_table
			end
		end
		-- 一色双龙会 --
		-- 四喜--
		local si_xi_four_count = 0
		for k,v in ipairs(four_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				si_xi_four_count = si_xi_four_count + 1
			end
		end
		local si_xi_three_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 10 and v[1] <= 13 then
				si_xi_three_count = si_xi_three_count + 1
			end
		end
		if (si_xi_three_count + si_xi_four_count) == 4 then
			table.insert(base_fan_table,HU_INFO.DA_SI_XI)
			return base_fan_table
		end
		if si_xi_three_count == 3 and (g_jiang_tile >= 10 and g_jiang_tile <= 13) then
			table.insert(base_fan_table,HU_INFO.XIAO_SI_XI)
			return base_fan_table
		end
		-- 四喜--
		-- 三元 --
		local san_yuan_three_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 14 and v[1] <= 16 then
				san_yuan_three_count = san_yuan_three_count + 1
			end
		end
		if san_yuan_three_count == 3 then
			table.insert(base_fan_table,HU_INFO.DA_SAN_YUAN)
			return base_fan_table
		end
		if san_yuan_three_count == 2 and (g_jiang_tile >= 14 and g_jiang_tile <= 16) then
			table.insert(base_fan_table,HU_INFO.XIAO_SAN_YUAN)
			return base_fan_table
		end
		-- 三元 --
		-- 一色四同顺 --
		if qing_yi_se and #shun_zi_list == 4 then
			local shun_zi_v1 = 0
			local yi_se_si_tong = true
			for k,v in ipairs(shun_zi_list) do
				if shun_zi_v1 == 0 then
					shun_zi_v1 = v[1]
				end
				if shun_zi_v1 ~= v[1] then
					yi_se_si_tong = false break
				end
			end
			if yi_se_si_tong then
				table.insert(base_fan_table,HU_INFO.YI_SE_SI_TONG_SHUN)
				return base_fan_table
			end
		end
		-- 一色四同顺 --
		-- 一色四节高 --
		if qing_yi_se and #three_tong_list == 4 then
			local tong_list = {}
			for k,v in ipairs(three_tong_list) do
				table.insert( tong_list, v[1])
			end
			table.sort(tong_list)
			if (tong_list[1]+1 == tong_list[2]) and (tong_list[1]+2 == tong_list[3]) and (tong_list[1]+3 == tong_list[4]) then
				table.insert(base_fan_table,HU_INFO.YI_SE_SI_JIE_GAO)
				return base_fan_table
			end
		end
		-- 一色四节高 --
		-- 一色四步高 --
		if qing_yi_se and #shun_zi_list == 4 then
			local shun_list = {}
			for k,v in ipairs(shun_zi_list) do
				table.insert( shun_list, v[1])
			end
			table.sort(shun_list)
			if (shun_list[1]+1 == shun_list[2]) and (shun_list[1]+2 == shun_list[3]) and (shun_list[1]+3 == shun_list[4]) then
				table.insert(base_fan_table,HU_INFO.YI_SE_SI_BU_GAO)
				return base_fan_table
			end
		end
		-- 一色四步高 --
		-- 混幺九 --
		if #shun_zi_list == 0 then
			local yao_count = 0
			local jiu_count = 0
			local has_other_wan = false
			if g_jiang_tile == 1 then
				yao_count = yao_count + 1 
			elseif g_jiang_tile == 9 then 
				jiu_count = jiu_count + 1
			elseif g_jiang_tile < 9 and g_jiang_tile > 1 then 
				has_other_wan = true
			end
			for k,v in ipairs(three_tong_list) do
				if v[1] == 1 then
					yao_count = yao_count + 1 
				elseif v[1] == 9 then 
					jiu_count = jiu_count + 1
				elseif v[1] < 9 and v[1] > 1 then 
					has_other_wan = true
				end
			end
			if yao_count == 1 and jiu_count == 1 and not has_other_wan then
				table.insert(base_fan_table,HU_INFO.HUN_YAO_JIU)
				return base_fan_table 
			end
		end
		-- 混幺九 --
		-- 一色三节高 --
		if qing_yi_se and #three_tong_list >= 3 then
			local tong_list = {}
			for k,v in ipairs(three_tong_list) do
				table.insert( tong_list, v[1])
			end
			table.sort(tong_list)
			if ((tong_list[1]+1 == tong_list[2]) and (tong_list[1]+2 == tong_list[3])) or 
			(#three_tong_list > 3 and (tong_list[2]+1 == tong_list[3]) and (tong_list[2]+2 == tong_list[4])) then
				table.insert(base_fan_table,HU_INFO.YI_SE_SAN_JIE_GAO)
				return base_fan_table
			end
		end
		-- 一色三节高 --
		-- 一色三同顺 --
		if qing_yi_se and #shun_zi_list >= 3 then
			local shun_zi_v1_list = {}
			local yi_se_si_tong = true
			for k,v in ipairs(shun_zi_list) do
				shun_zi_v1_list[v[1]] = shun_zi_v1_list[v[1]] or 0
				shun_zi_v1_list[v[1]] = shun_zi_v1_list[v[1]] + 1
			end
			for k,v in ipairs(shun_zi_v1_list) do
				if v == 3 then
					table.insert(base_fan_table,HU_INFO.YI_SE_SAN_TONG_SHUN)
					return base_fan_table
				end
			end
		end
		-- 一色三同顺 --
		-- 清龙 --
		if qing_yi_se then
			local cache_qing_long = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
			for k,v in ipairs(g_split_list) do
				for k1,v1 in ipairs(v) do
					cache_qing_long[v1] = cache_qing_long[v1] + 1
				end
			end
			if cache_qing_long[1] > 0 and cache_qing_long[2] > 0 and cache_qing_long[3] > 0 and cache_qing_long[4] > 0 and 
			cache_qing_long[5] > 0 and cache_qing_long[6] > 0 and cache_qing_long[7] > 0 and cache_qing_long[8] > 0 and cache_qing_long[9] > 0 then
				table.insert(base_fan_table,HU_INFO.QING_LONG)
				return base_fan_table 
			end
		end
		
		-- 清龙 --
		-- 一色三步高 --
		if qing_yi_se and #shun_zi_list >= 3 then
			local cache_san_bu_gao = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
			for k,v in ipairs(shun_zi_list) do
				cache_san_bu_gao[v[1]] = cache_san_bu_gao[v[1]] + 1
			end

			for k,v in ipairs(cache_san_bu_gao) do
				if (v > 0 and cache_san_bu_gao[k+1] > 0 and cache_san_bu_gao[k+2] > 0 ) or 
				(v > 0 and cache_san_bu_gao[k+2] > 0 and cache_san_bu_gao[k+4] > 0) then
					table.insert(base_fan_table,HU_INFO.YI_SE_SAN_BU_GAO)
					return base_fan_table 
				end
			end
		end
		-- 一色三步高 --
		-- 碰碰胡 --
		if (#three_tong_list + #four_tong_list) >= 4 and #shun_zi_list == 0 then
			table.insert(base_fan_table,HU_INFO.PENG_PENG_HU)
			return base_fan_table 
		end
		-- 碰碰胡 --
		-- 四字刻 --
		local zi_ke_count = 0
		for k,v in ipairs(three_tong_list) do
			if v[1] >= 10 and v[1] <= 16 then
				zi_ke_count = zi_ke_count + 1
			end
		end
		for k,v in ipairs(four_tong_list) do
			if v[1] >= 10 and v[1] <= 16 then
				zi_ke_count = zi_ke_count + 1
			end
		end
		if zi_ke_count >= 4 then
			table.insert(base_fan_table,HU_INFO.SI_ZI_KE)
			return base_fan_table 
		end
		-- 四字刻 --
		
		table.insert(base_fan_table,HU_INFO.PING_HU)
		return base_fan_table 
	else
		return {}
	end
end

function rule.is_chi(pai,value)
	local array = {0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,}
	for k,v in ipairs(pai.shou_pai) do
		array[v] = array[v] + 1
	end

	if(value > 9 or value < 1) then return nil;end;
	local s2,s1,s,b1,b2 = array[value - 2],array[value - 1],array[value],array[value + 1],array[value + 2];
	if(value == 8) then b2 = 0;
	elseif(value == 9) then b1 = 0;b2 = 0;
	elseif(value == 2) then s2 = 0;
	elseif(value == 1) then s1 = 0;s2 = 0;
	end;

	local result = {};
	if(s2 > 0 and s1 > 0) then result[#result + 1] = {value-2,value-1};end;
	if(s1 > 0 and b1 > 0) then result[#result + 1] = {value-1,value+1};end;
	if(b1 > 0 and b2 > 0) then result[#result + 1] = {value+1,value+2};end;
	if(#result == 0) then return nil;end;
	return result;
end

return rule