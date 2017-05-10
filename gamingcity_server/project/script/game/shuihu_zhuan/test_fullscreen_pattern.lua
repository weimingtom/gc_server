
local game_type = require("game_type")
local game_helper = require("game_helper")
local tablex = require("utils/tablex")

local icon_type = game_type.icon_type
local link_type = game_type.link_type
local link_direction = game_type.link_direction
local dice_type = game_type.dice_type

-- 测试全屏图案
local function test_fullscreen_pattern()
    for i = icon_type.fu_tou, icon_type.lottery_ticket do
        local pattern = game_helper.generate_fullscreen_pattern(i)
        local analyse_result = game_helper.analyse_pattern(pattern)
        game_helper.print_pattern(pattern)
        tablex.print(analyse_result)
        print()
    end
end

test_fullscreen_pattern()
