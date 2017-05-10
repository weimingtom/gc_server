
local game_type = require("game_type")
local game_helper = require("game_helper")
local tablex = require("utils/tablex")

-- 测试随机图案
local function test_random_pattern(valid_count)
    valid_count = valid_count or 1
    if valid_count < 1 then
        valid_count = 1
    end

    local count = 0
    while true do
        if count >= valid_count then
            break
        end

        local pattern = game_helper.generate_random_pattern()
        local analyse_result = game_helper.analyse_pattern(pattern)
        if analyse_result.multiple_sum > 0 or analyse_result.bonus_times > 0 or analyse_result.lottery_ticket_count > 0 then
            game_helper.print_pattern(pattern)
            tablex.print(analyse_result)
            print()
            count = count + 1
        end
    end
end

test_random_pattern(10)
