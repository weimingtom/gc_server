-- 物品表

local pb = require "protobuf"

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")

-- enum ITEM_TYPE 
local ITEM_TYPE_MONEY = pb.enum_id("ITEM_TYPE", "ITEM_TYPE_MONEY")
local ITEM_TYPE_BOX  = pb.enum_id("ITEM_TYPE", "ITEM_TYPE_BOX")

item_details_table = {
	[10010000] = {item_id = 10010000, item_type = ITEM_TYPE_MONEY, name = "金币"},
	[10010001] = {item_id = 10010001, item_type = ITEM_TYPE_BOX, name = "小宝箱", price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 100000}, sub_item = {{item_id = 10010000, item_num = 100000}}},
	[10010002] = {item_id = 10010002, item_type = ITEM_TYPE_BOX, name = "中宝箱", price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 500000}, sub_item = {{item_id = 10010000, item_num = 500000}}},
	[10010003] = {item_id = 10010003, item_type = ITEM_TYPE_BOX, name = "大宝箱", price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 1000000}, sub_item = {{item_id = 10010000, item_num = 1000000}}},
}
