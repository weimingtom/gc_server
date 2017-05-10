-- 斗地主出牌规则

local pb = require "protobuf"

-- enum LAND_CARD_TYPE
local LAND_CARD_TYPE_SINGLE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE")
local LAND_CARD_TYPE_DOUBLE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE")
local LAND_CARD_TYPE_THREE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE")
local LAND_CARD_TYPE_SINGLE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_SINGLE_LINE")
local LAND_CARD_TYPE_DOUBLE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_DOUBLE_LINE")
local LAND_CARD_TYPE_THREE_LINE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_LINE")
local LAND_CARD_TYPE_THREE_TAKE_ONE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_ONE")
local LAND_CARD_TYPE_THREE_TAKE_TWO = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_THREE_TAKE_TWO")
local LAND_CARD_TYPE_FOUR_TAKE_ONE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_ONE")
local LAND_CARD_TYPE_FOUR_TAKE_TWO = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_FOUR_TAKE_TWO")
local LAND_CARD_TYPE_BOMB = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_BOMB")
local LAND_CARD_TYPE_MISSILE = pb.enum_id("LAND_CARD_TYPE", "LAND_CARD_TYPE_MISSILE")


-- 得到牌大小
local function get_value(card)
	return math.floor(card / 4)
end

-- 是大小王
local function is_king(card)
	return card == 52 or card == 53
end
-- 0：方块3，1：梅花3，2：红桃3，3：黑桃3 …… 48：方块2，49：梅花2，50：红桃2，51：黑桃2，52：小王，53：大王

land_cards = {}

-- 创建
function land_cards:new()
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function land_cards:init(cards)
    self.cards_ = cards
    self.bomb_count_ = 0
end

-- 添加牌
function land_cards:add_cards(cards)
	for i,v in ipairs(cards) do
    	table.insert(self.cards_, v)
    end
end

-- 加炸弹
function land_cards:add_bomb_count()
	self.bomb_count_ = self.bomb_count_ + 1
end

-- 得到炸弹
function land_cards:get_bomb_count()
	return self.bomb_count_
end

-- 查找是否有拥有
function land_cards:find_card(card)
	for i,v in ipairs(self.cards_) do
		if v == card then
			return true
		end
	end
	return false
end

-- 删除牌
function land_cards:remove_card(card)
for i,v in ipairs(self.cards_) do
		if v == card then
			table.remove(self.cards_, i)
			return true
		end
	end
	return false
end

-- 检查牌是否合法
function land_cards:check_cards(cards)
	if not cards or #cards == 0 then
		return false
	end

	local set = {} -- 检查重复牌
	for i,v in ipairs(cards) do
		if v < 0 or v > 53 or set[v] then
			return false
		end

		if not self:find_card(v) then
			return false
		end

		set[v] = true
	end

	return true
end

-- 分析牌
function land_cards:analyseb_cards(cards)
	local ret = {{}, {}, {}, {}} -- 依次单，双，三，炸的数组
	local last_val = nil
	local i = 0

	for _, card in ipairs(cards) do
		if is_king(card) then
			table.insert(ret[1], card) -- 王默认是单牌
		else
			local val = get_value(card)
			if last_val == val then
				i = i + 1
			else
				if i > 0 and i <= 4 then
					table.insert(ret[i], last_val)
				end
				last_val = val
				i = 1
			end
		end
	end
	if i > 0 and i <= 4 then
		table.insert(ret[i], last_val)
	end
	return ret
end

-- 得到牌类型
function land_cards:get_cards_type(cards)
	local count = #cards
	if count == 1 then
		return LAND_CARD_TYPE_SINGLE, get_value(cards[1]) -- 单牌
	elseif count == 2 then
		if is_king(cards[1]) and is_king(cards[2]) then
			return LAND_CARD_TYPE_MISSILE -- 火箭
		elseif get_value(cards[1]) == get_value(cards[2]) then
			return LAND_CARD_TYPE_DOUBLE, get_value(cards[1]) -- 对牌
		end
		return nil
	end

	local ret = self:analyseb_cards(cards)

	if #ret[4] == 1 then
		if count == 4 then
			return LAND_CARD_TYPE_BOMB, ret[4][1] -- 炸弹
		elseif count == 6 then
			return LAND_CARD_TYPE_FOUR_TAKE_ONE, ret[4][1] -- 四带两单
		elseif count == 8 and #ret[2] == 2 then
			return LAND_CARD_TYPE_FOUR_TAKE_TWO, ret[4][1] -- 四带两对
		elseif count >= 8 then
			table.insert(ret[3], ret[4][1])
			table.insert(ret[1], ret[4][1])
			table.sort(ret[3], function(a, b) return a < b end)
			table.sort(ret[1], function(a, b) return a < b end)
		else
			return nil
		end
	end
	local three_count = #ret[3] 
	if three_count > 0 then
		if three_count > 1 then
			if ret[3][1] >= 12 then
				return nil
			end
			local cur_val = nil
			for _, card in ipairs(ret[3]) do
				if not cur_val then
					cur_val = card + 1
				elseif cur_val == card then
					cur_val = cur_val + 1
				else
					return nil
				end
			end
		elseif count == 3 then
			return LAND_CARD_TYPE_THREE, ret[3][1]	-- 三条
		end

		if count == three_count * 3 then
			return LAND_CARD_TYPE_THREE_LINE, ret[3][1] -- 三连
		elseif count == three_count * 4 then
			return LAND_CARD_TYPE_THREE_TAKE_ONE, ret[3][1] -- 三带一单
		elseif count == three_count * 5 and #ret[2] == three_count then
			return LAND_CARD_TYPE_THREE_TAKE_TWO, ret[3][1] -- 三带一对
		end
		return nil
	end

	local two_count = #ret[2]
	if two_count >= 3 then
		if ret[2][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[2]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end

		if count == two_count * 2 then
			return LAND_CARD_TYPE_DOUBLE_LINE, ret[2][1] -- 对连
		end
		return nil
	end

	local one_count = #ret[1]
	if one_count >= 5 and count == one_count then
		if ret[1][1] >= 12 then
			return nil
		end
		local cur_val = nil
		for _, card in ipairs(ret[1]) do
			if not cur_val then
				cur_val = card + 1
			elseif cur_val == card then
				cur_val = cur_val + 1
			else
				return nil
			end
		end

		return LAND_CARD_TYPE_SINGLE_LINE, ret[1][1] -- 单连
	end

	return nil
end

-- 比较牌
function land_cards:compare_cards(cur, last)
	print("land_cards  compare_cards")
	if cur.cards_val ~= nil then
		print(string.format("cur [%d,%d,%d]", cur.cards_type , cur.cards_count, cur.cards_val))
	else
		print(string.format("cur [%d,%d]", cur.cards_type , cur.cards_count))
	end
	if last ~= nil then
		print(string.format("last [%d,%d,%d]", last.cards_type , last.cards_count, last.cards_val))
	end
	if not last then
		return true
	end

	-- 比较火箭
	if cur.cards_type == LAND_CARD_TYPE_MISSILE then
		return true
	end

	-- 比较炸弹
	if last.cards_type == LAND_CARD_TYPE_BOMB then
		return cur.cards_type == LAND_CARD_TYPE_BOMB and cur.cards_val > last.cards_val
	elseif cur.cards_type == LAND_CARD_TYPE_BOMB then
		return true
	end

	return cur.cards_type == last.cards_type and cur.cards_count == last.cards_count and cur.cards_val > last.cards_val
end

-- 出牌
function land_cards:out_cards(cards)
	print("remove_card: "..table.concat( cards, ", "))
	for i,v in ipairs(cards) do
		self:remove_card(v)
	end
	print(string.format("card_count[%d],cards[%s]",#self.cards_ , table.concat( self.cards_, ", ")))
	return #self.cards_ > 0
end
