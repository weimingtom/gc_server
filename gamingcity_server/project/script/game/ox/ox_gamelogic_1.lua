local pb = require "protobuf"
--高倍场牛牛(1赔10)游戏逻辑
-- enum OX_CARD_TYPE
local OX_CARD_TYPE_OX_NONE = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_OX_NONE")
local OX_CARD_TYPE_OX_ONE = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_OX_ONE")
local OX_CARD_TYPE_OX_TWO = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_OX_TWO")
local OX_CARD_TYPE_FOUR_KING = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_KING")
local OX_CARD_TYPE_FIVE_KING = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FIVE_KING")
local OX_CARD_TYPE_FOUR_SAMES = pb.enum_id("OX_CARD_TYPE", "OX_CARD_TYPE_FOUR_SAMES")
local OX_CARD_TYPE_FIVE_SAMLL = pb.enum_id("OX_CARD_TYPE","OX_CARD_TYPE_FIVE_SAMLL")
-- enum OX_SCORE_AREA
local OX_AREA_ONE = pb.enum_id("OX_SCORE_AREA","OX_AREA_ONE")
local OX_AREA_TWO = pb.enum_id("OX_SCORE_AREA","OX_AREA_TWO")
local OX_AREA_THREE = pb.enum_id("OX_SCORE_AREA","OX_AREA_THREE")
local OX_AREA_FOUR = pb.enum_id("OX_SCORE_AREA","OX_AREA_FOUR")

-- 0：方块A，1：梅花A，2：红桃A，3：黑桃A …… 48：方块K，49：梅花K，50：红桃K，51：黑桃K，52:小王 ，53大王

--[[-- 最大赔率倍数10倍
local OX_MAX_TIMES = 10

-- 是否有大小王
local CLOWN_EXSITS = false

-- 上庄条件金币限制
local OX_BANKER_LIMIT = 500
--]]
-- 得到牌大小
function get_value(card)
	return math.floor(card / 4)
end

-- 得到牛牛计算值
function get_value_ox(val)
	if val >= 9 then
		return 10
	end
	return val + 1
end

-- 得到牌花色
function get_color(card)
	return card % 4
end

-- 得到倍数
function get_type_times(cards_type,max_value)
	-- 1. 无牛：1倍。
	-- 2. 牛一：1倍，牛二：2倍……牛八：8倍，牛九：9倍。
	-- 3. 牛牛及以上：10倍。
	-- 牛牛及以上10倍
	if cards_type >= OX_CARD_TYPE_OX_TWO then
		return 10
	-- 牛N 返回最大数值的倍率
	elseif cards_type == OX_CARD_TYPE_OX_ONE then
		return max_value
	end
	-- 其它均为1倍
	return 1
end



-- 得到牌类型
function get_cards_type(cards)
	--[[
		params: cards
		return ox,val_list,max_color,max_value
	]]
	local list = {}
	for i=1,5 do
		list[i] = cards[i]
	end
	table.sort(list, function (a, b)
		return a > b
	end)


	local king_ox = 0
	local is_ten = false
	local repeat_times =0
	local last_value = nil
	local val_list = {}
	local four_same = false
	local same_value = nil
	local sum_value =0

	for i =1,5 do
		local  val = math.floor(list[i]/4)
		sum_value = sum_value + val +1
		val_list[i] = val
		if val > 9 then
			-- 花色
			king_ox = king_ox + 1
		elseif val == 9 then
			-- 10点
			is_ten = true
		end

		if not last_value then
			last_value = val
			repeat_times = 1
		elseif last_value ~= val then
			if repeat_times ==4 then
				-- 4个相同
				four_same = true
				same_value = list[i]
			end
			last_value = val
			repeat_times = 1
		else
			repeat_times = repeat_times +1
			same_value = list[i]
		end
	end
	if sum_value <= 10 then
		return OX_CARD_TYPE_FIVE_SAMLL,val_list,get_color(list[1])
	end

	if repeat_times == 4 or four_same then
		return OX_CARD_TYPE_FOUR_SAMES,same_value,get_color(list[1])
	end

	-- 五花牛
	if king_ox == 5 then
		return OX_CARD_TYPE_FIVE_KING,val_list,get_color(list[1])
	end
	-- 四花牛
	if king_ox == 4 and is_ten then
		return OX_CARD_TYPE_FOUR_KING,val_list,get_color(list[1])
	end

	-- 其它类型判断
	local val_ox = {}
	for i=1,5 do
		val_ox[i] = get_value_ox(val_list[i])
	end

	local is_three_eq_ten =false -- 是否有三个数的和为10的倍数
	local is_ox_two = false -- 是否是牛牛
	local ox_num = 0 -- 牛1的牛数
	for i=1,3 do
		for j =i+1,4 do
			for k=j+1,5 do
				if (val_ox[i] + val_ox[j] + val_ox[k]) %10 ==0 then
					is_three_eq_ten = true
					local other_sum =0
					for m=1,5 do
						if m ~=i and m ~=j and m~=k then
							other_sum = other_sum + val_ox[m]
						end
					end
					if(other_sum)%10 ==0 then
						--牛牛
						is_ox_two = true
					else
						ox_num = other_sum %10
					end
				end
			end
		end
	end

	if is_ox_two then
		return OX_CARD_TYPE_OX_TWO,val_list,get_color(list[1])
	end
	if is_three_eq_ten then
		return OX_CARD_TYPE_OX_ONE,val_list,get_color(list[1]),ox_num
	end
	return OX_CARD_TYPE_OX_NONE, val_list, get_color(list[1])
end

-- 比较牌
function compare_cards(first, second)
	-- ox_type= ox_type_,val_list = value_list_,color = color_,extro_num = extro_num_
	if first.ox_type ~= second.ox_type then
		return first.ox_type > second.ox_type
	end

	--有牛判断,判断倍数
	if first.ox_type == OX_CARD_TYPE_OX_ONE then
		if first.cards_times ~= second.cards_times then
			return first.cards_times > second.cards_times
		end
	end
	

	if first.ox_type == OX_CARD_TYPE_FOUR_SAMES then
		return first.val_list > second.val_list
	end

	for i=1,5 do
		local v1 = first.val_list[i]
		local v2 = second.val_list[i]
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		else -- v1 = v2 倍数相等比单张牌大小也相等,再比花色
			return first.color > second.color
		end
	end
	return first.color > second.color
end


-- 分离字符串
function lua_string_split(str, split_char)      
	local sub_str_tab = {}
   
	while (true) do
		local pos = string.find(str, split_char)  
		if (not pos) then
			local number = tonumber(str)            
			table.insert(sub_str_tab,number)  
			break
		end  
	   
		local sub_str = string.sub(str, 1, pos - 1)
		local number = tonumber(sub_str)
		table.insert(sub_str_tab,number)
		local t = string.len(str)
		str = string.sub(str, pos + 1, t)    
	end      
	return sub_str_tab
end 