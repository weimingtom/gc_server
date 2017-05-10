
local game_type = require("game_type")
local game_helper = require("game_helper")

local icon_type = game_type.icon_type
local link_type = game_type.link_type
local link_direction = game_type.link_direction
local dice_type = game_type.dice_type

-- 测试比倍
local function test_compare_dice()
    local buy_type = math.random(dice_type.dice_small, dice_type.dice_big)
    local point1, point2 = game_helper.generate_random_dice()
    local lottery_type, multiple = game_helper.calc_dice_lottery(point1, point2, buy_type)

    print(string.format("buy type: %d", buy_type))
    print(string.format("random dice: %d, %d", point1, point2))
    print(string.format("compare dice: %d, %d", lottery_type, multiple))
end

for i = 1, 10 do
    test_compare_dice()
    print()
end
