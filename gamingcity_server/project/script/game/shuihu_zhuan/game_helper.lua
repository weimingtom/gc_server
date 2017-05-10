
local game_type = require("game/shuihu_zhuan/game_type")
local random = require("utils/random")
local tablex = require("utils/tablex")

local icon_type = game_type.icon_type
local link_type = game_type.link_type
local link_direction = game_type.link_direction
local dice_type = game_type.dice_type

local game_helper = {}

-- 线条坐标
local line_table = {
    { { x = 2, y = 1 }, { x = 2, y = 2 }, { x = 2, y = 3 }, { x = 2, y = 4 }, { x = 2, y = 5 } },
    { { x = 1, y = 1 }, { x = 1, y = 2 }, { x = 1, y = 3 }, { x = 1, y = 4 }, { x = 1, y = 5 } },
    { { x = 3, y = 1 }, { x = 3, y = 2 }, { x = 3, y = 3 }, { x = 3, y = 4 }, { x = 3, y = 5 } },
    { { x = 1, y = 1 }, { x = 2, y = 2 }, { x = 3, y = 3 }, { x = 2, y = 4 }, { x = 1, y = 5 } },
    { { x = 3, y = 1 }, { x = 2, y = 2 }, { x = 1, y = 3 }, { x = 2, y = 4 }, { x = 3, y = 5 } },
    { { x = 1, y = 1 }, { x = 1, y = 2 }, { x = 2, y = 3 }, { x = 1, y = 4 }, { x = 1, y = 5 } },
    { { x = 3, y = 1 }, { x = 3, y = 2 }, { x = 2, y = 3 }, { x = 3, y = 4 }, { x = 3, y = 5 } },
    { { x = 2, y = 1 }, { x = 3, y = 2 }, { x = 3, y = 3 }, { x = 3, y = 4 }, { x = 2, y = 5 } },
    { { x = 2, y = 1 }, { x = 1, y = 2 }, { x = 1, y = 3 }, { x = 1, y = 4 }, { x = 2, y = 5 } }
}

-- 图案倍率表，图标值:倍数
local pattern_multiple_table = {
    [3] = { 2, 3, 5, 7, 10, 15, 20, 50, 0, 0 },
    [4] = { 5, 10, 15, 20, 30, 40, 80, 20, 0, 0 },
    [5] = { 20, 40, 60, 100, 160, 200, 400, 1000, 0, 0 },
    [15] = { 50, 100, 150, 250, 400, 500, 1000, 2500, 5000, 200 },
    wuqi = 15,
    renwu = 50
}
    
-- 除全屏图标倍率外的所有倍率
local all_pattern_multiple_table = {
    2, 3, 5, 7, 10, 15, 20, 30, 40, 50, 60, 80, 100, 160, 200, 400, 1000
}

-- 骰子倍率表
local dice_multiple_table = {
    small = 2,
    small_pair = 4,
    tie = 6,
    big = 2,
    big_pair = 4
}

-- 小玛丽倍率表，图标值:倍数
local bonus_multiple_table = {
    2, 5, 10, 20, 50, 70, 100, 200, 0, 0,
    rolling_four = 500,
    rolling_three = 20
}

-- 游戏配置
local game_config = nil

-- 设置配置
function game_helper.set_config(config)
    game_config = config
end

-- 生成随机图案
function game_helper.generate_random_pattern()
    local pattern = {}
    for x = 1, 3 do
        pattern[x] = {}
        for y = 1, 5 do
            local icon = random.integer(icon_type.fu_tou, icon_type.lottery_ticket)
            if not game_config then
                pattern[x][y] = icon
            else
                if icon == icon_type.shuihu_zhuan then
                    local rand_odds = random.float()
                    if rand_odds < game_config.shuihu_probability then
                        pattern[x][y] = icon
                    else
                        pattern[x][y] = random.integer(icon_type.fu_tou, icon_type.zhong_yi_tang)
                    end
                elseif icon == icon_type.lottery_ticket then
                    local rand_odds = random.float()
                    if rand_odds < game_config.lottery_ticket_probability then
                        pattern[x][y] = icon
                    else
                        pattern[x][y] = random.integer(icon_type.fu_tou, icon_type.zhong_yi_tang)
                    end
                else
                    pattern[x][y] = icon
                end
            end
        end
    end
    return pattern
end

-- 生成全屏图标
function game_helper.generate_fullscreen_pattern(icon)
    local pattern = {}
    for x = 1, 3 do
        pattern[x] = {}
        for y = 1, 5 do
            pattern[x][y] = icon
        end
    end
    return pattern
end

-- 生成全屏武器
function game_helper.generate_fullscreen_wuqi()
    local pattern = {}
    for x = 1, 3 do
        pattern[x] = {}
        for y = 1, 5 do
            pattern[x][y] = random.integer(icon_type.fu_tou, icon_type.da_dao)
        end
    end
    return pattern
end

-- 生成全屏人物
function game_helper.generate_fullscreen_renwu()
    local pattern = {}
    for x = 1, 3 do
        pattern[x] = {}
        for y = 1, 5 do
            pattern[x][y] = random.integer(icon_type.lu_zhi_shen, icon_type.song_jiang)
        end
    end
    return pattern
end

-- 统计每个图标的个数
local function game_helper_statis_icon_count(pattern)
    local icon_count = {}
    for i = icon_type.fu_tou, icon_type.lottery_ticket do
        icon_count[i] = 0
    end
    
    for x = 1,3 do
        for y = 1,5 do
            local v = pattern[x][y]
            icon_count[v] = icon_count[v] + 1
        end
    end
    return icon_count
end

-- 是否中奖图案：当每个图标和水浒传的总个数小于三个时，一定不会中奖
local function game_helper_is_lottery_pattern(icon_count)
  for i = icon_type.fu_tou, icon_type.lottery_ticket do
    if i ~= icon_type.shuihu_zhuan and (icon_count[i] + icon_count[icon_type.shuihu_zhuan]) >= 3 then
      return true
    end
  end
  return false
end

-- 是否全屏武器
local function game_helper_is_fullscreen_wuqi(icon_count)
    return ((icon_count[icon_type.fu_tou] + icon_count[icon_type.ying_qiang] + icon_count[icon_type.da_dao]) == 15)
end

-- 是否全屏人物
local function game_helper_is_fullscreen_renwu(icon_count)
    return ((icon_count[icon_type.lu_zhi_shen] + icon_count[icon_type.lin_chong] + icon_count[icon_type.song_jiang]) == 15)
end

-- 分析图案
function game_helper.analyse_pattern(pattern, line_count)
    line_count = line_count or 9
    if line_count < 1 or line_count > 9 then
        line_count = 9
    end
    -- 统计结果
    local analyse_result = { multiple_sum = 0, bonus_times = 0, lottery_ticket_count = 0, result_items = {} }
    
    -- 统计图标个数
    local icon_count = game_helper_statis_icon_count(pattern)
    
    -- 全屏图案判断
    for i = icon_type.fu_tou, icon_type.lottery_ticket do
        if icon_count[i] == 15 then
            analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table[15][i]
            -- 全屏水浒传
            if i == icon_type.shuihu_zhuan then
                analyse_result.bonus_times = 27
            -- 全屏奖券
            elseif i == icon_type.lottery_ticket then
                analyse_result.lottery_ticket_count = 27
            end

            local result_item = {
                line = -1,
                icon = i,
                type = link_type.link_fullscreen,
                direction=link_direction.direction_left,
                multiple = pattern_multiple_table[15][i]
            }
            table.insert(analyse_result.result_items, result_item)
        end
    end
    if analyse_result.multiple_sum > 0 or analyse_result.bonus_times > 0 or analyse_result.lottery_ticket_count > 0 then
        return analyse_result
    end
  
    -- 是否中奖判断
    if not game_helper_is_lottery_pattern(icon_count) then
        return analyse_result
    end

    -- 小玛丽判断
    if icon_count[icon_type.shuihu_zhuan] > 3 then
        for line = 1, line_count do
            -- 从左向右，1 ~ 5
            local result_item = {
                line = line,
                icon = icon_type.shuihu_zhuan,
                type = -1,
                direction = link_direction.direction_left,
                multiple = 0
            }
            local shuihu_count = 0
            for point = 1, 5 do
                local current_pos = line_table[line][point]
                local current_icon = pattern[current_pos.x][current_pos.y]
                if current_icon == icon_type.shuihu_zhuan then
                    shuihu_count = shuihu_count + 1
                else
                    break
                end
            end
            if shuihu_count < 3 then
                -- 从右向左，5 ~ 2
                result_item.direction = link_direction.direction_right
                shuihu_count = 0
                for point = 5, 2, -1 do
                    local current_pos = line_table[line][point]
                    local current_icon = pattern[current_pos.x][current_pos.y]
                    if current_icon == icon_type.shuihu_zhuan then
                        shuihu_count = shuihu_count + 1
                    else
                        break
                    end
                end
            end

            if shuihu_count == 5 then
                analyse_result.bonus_times = analyse_result.bonus_times + 3
                result_item.type = link_type.link_five
                result_item.multiple = pattern_multiple_table[5][result_item.icon]
            elseif shuihu_count == 4 then
                analyse_result.bonus_times = analyse_result.bonus_times + 2
                result_item.type = link_type.link_four
                result_item.multiple = pattern_multiple_table[4][result_item.icon]
            elseif shuihu_count == 3 then
                analyse_result.bonus_times = analyse_result.bonus_times + 1
                result_item.type = link_type.link_three
                result_item.multiple = pattern_multiple_table[3][result_item.icon]
            end
            if shuihu_count >= 3 then
                table.insert(analyse_result.result_items, result_item)
            end
        end
    end
  
    -- 常规判断：普通图标与水浒传百搭
    for icon = icon_type.fu_tou, icon_type.lottery_ticket do
        for line = 1, line_count do
            -- 当前图案必须靠左或靠右才算中奖
            local pos1, pos5 = line_table[line][1], line_table[line][5]
            local icon1, icon5 = pattern[pos1.x][pos1.y], pattern[pos5.x][pos5.y]
            -- 排除水浒传
            local condition1 = (icon ~= icon_type.shuihu_zhuan)
            -- 排除左侧
            local condition2 = (icon1 == icon or icon1 == icon_type.shuihu_zhuan)
            -- 排除右侧
            local condition3 = (icon5 == icon or icon5 == icon_type.shuihu_zhuan)
            
            if condition1 and (condition2 or condition3) then
                -- 从左向右，1 ~ 5
                local result_item = {
                    line = line,
                    icon = icon,
                    type = -1,
                    direction = link_direction.direction_left,
                    multiple = 0
                }
                local link_count, all_shuihu = 0, true
                for point = 1, 5 do
                    local current_pos = line_table[line][point]
                    local current_icon = pattern[current_pos.x][current_pos.y]

                    if current_icon == icon or current_icon == icon_type.shuihu_zhuan then
                        link_count = link_count + 1
                        if all_shuihu and current_icon ~= icon_type.shuihu_zhuan then
                            all_shuihu = false
                        end
                    else
                        break
                    end
                end
                if all_shuihu or link_count < 3 then
                    -- 从右向左，5 ~ 2
                    result_item.direction = link_direction.direction_right
                    link_count, all_shuihu = 0, true
                    for point = 5, 2, -1 do
                        local current_pos = line_table[line][point]
                        local current_icon = pattern[current_pos.x][current_pos.y]

                        if current_icon == icon or current_icon == icon_type.shuihu_zhuan then
                            link_count = link_count + 1
                            if all_shuihu and current_icon ~= icon_type.shuihu_zhuan then
                                all_shuihu = false
                            end
                        else
                            break
                        end
                    end
                end
                if not all_shuihu and link_count >= 3 then
                    if link_count == 5 then
                        analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table[5][icon]
                        if icon == icon_type.lottery_ticket then
                            analyse_result.lottery_ticket_count = analyse_result.lottery_ticket_count + 3
                        end
                        result_item.type = link_type.link_five
                        result_item.multiple = pattern_multiple_table[5][icon]
                    elseif link_count == 4 then
                        analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table[4][icon]
                        if icon == icon_type.lottery_ticket then
                            analyse_result.lottery_ticket_count = analyse_result.lottery_ticket_count + 2
                        end
                        result_item.type = link_type.link_four
                        result_item.multiple = pattern_multiple_table[4][icon]
                    else
                        analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table[3][icon]
                        if icon == icon_type.lottery_ticket then
                            analyse_result.lottery_ticket_count = analyse_result.lottery_ticket_count + 1
                        end
                        result_item.type = link_type.link_three
                        result_item.multiple = pattern_multiple_table[3][icon]
                    end
                    table.insert(analyse_result.result_items, result_item)
                end
            end
        end
    end

    -- 全屏武器判断
    if game_helper_is_fullscreen_wuqi(icon_count) then
        analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table.wuqi
        local result_item = { type = link_type.link_wuqi, line = -1, icon = -1, multiple = pattern_multiple_table.wuqi }
        table.insert(analyse_result.result_items, result_item)
    -- 全屏人物判断
    elseif game_helper_is_fullscreen_renwu(icon_count) then
        analyse_result.multiple_sum = analyse_result.multiple_sum + pattern_multiple_table.renwu
        local result_item = { type = link_type.link_renwu, line = -1, icon = -1, multiple = pattern_multiple_table.renwu }
        table.insert(analyse_result.result_items, result_item)
    end

    -- 返回结果
    return analyse_result
end

-- 生成随机骰子
function game_helper.generate_random_dice()
    return random.integer(1, 6), random.integer(1, 6)
end

-- 计算骰子中奖
function game_helper.calc_dice_lottery(point1, point2, buy_type)
    local lottery_type, multiple, point_sum = 0, 0, point1 + point2
    if point_sum < 7 then
        lottery_type = dice_type.dice_small
        if buy_type == dice_type.dice_small then
            if point1 ~= point2 then
                multiple = dice_multiple_table.small
            else
                multiple = dice_multiple_table.small_pair
            end
        end
    elseif point_sum > 7 then
        lottery_type = dice_type.dice_big
        if buy_type == dice_type.dice_big then
            if point1 ~= point2 then
                multiple = dice_multiple_table.big
            else
                multiple = dice_multiple_table.big_pair
            end
        end
    else
        lottery_type = dice_type.dice_tie
        if buy_type == dice_type.dice_tie then
            multiple = dice_multiple_table.tie
        end
    end
    return lottery_type, multiple
end

-- 生成小玛丽滚动图案
function game_helper.generate_random_rolling_icons()
    local rolling_icons = {}
    for i = 1, 4 do
        rolling_icons[i] = random.integer(icon_type.fu_tou, icon_type.zhong_yi_tang)
    end
    return rolling_icons
end

-- 生成随机转动图标
function game_helper.generate_random_rotate_icon()
    return random.integer(icon_type.fu_tou, icon_type.shuihu_zhuan)
end

-- 计算小玛丽中奖
function game_helper.calc_bonus_lottery(rolling_icons, rotate_icon)
    local icon_count = {}
    for i = icon_type.fu_tou, icon_type.lottery_ticket do
        icon_count[i] = 0
    end

    for i = 1, 4 do
        local icon = rolling_icons[i]
        icon_count[icon] = icon_count[icon] + 1
    end

    local multiple = 0
    for i = 1, 4 do
        if rotate_icon == rolling_icons[i] then
            multiple = bonus_multiple_table[rotate_icon]
            break
        end
    end

    for i = icon_type.fu_tou, icon_type.lottery_ticket do
        if icon_count[i] == 4 then
            multiple = multiple + bonus_multiple_table.rolling_four
        elseif icon_count[i] == 3 and rolling_icons[2] ~= rolling_icons[3] then
            multiple = multiple + bonus_multiple_table.rolling_three
        end
    end
    return multiple
end

-- 打印线条
function game_helper.print_line(line)
    local pattern_table = {}
    for x = 1,3 do
        for y = 1,5 do
            if line_table[line][y].x == x and line_table[line][y].y == y then
                table.insert(pattern_table, "* ")
            else
                table.insert(pattern_table, "- ")
            end
        end
        table.insert(pattern_table, "\n")
    end
    print(table.concat(pattern_table))
end

-- 打印所有线条
function game_helper.print_all_lines()
    for i = 1, 9 do
        game_helper.print_line(i)
    end
end

-- 打印图案
function game_helper.print_pattern(pattern)
    local pattern_table = {}
    for x = 1,3 do
        for y = 1,5 do
            table.insert(pattern_table, string.format("%X ", pattern[x][y]))
        end
        table.insert(pattern_table, "\n")
    end
    print(table.concat(pattern_table))
end

return game_helper
