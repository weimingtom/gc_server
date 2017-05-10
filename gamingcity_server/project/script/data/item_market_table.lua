-- 商城表

local pb = require "protobuf"

-- enum ITEM_PRICE_TYPE 
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")


item_market_table = {
	[10010001] = {item_id = 10010001, price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 100000}},
	[10010002] = {item_id = 10010002, price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 500000}},
	[10010003] = {item_id = 10010003, price = {money_type = ITEM_PRICE_TYPE_GOLD, money = 1000000}},
}

