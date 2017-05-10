
local game_config = {
    bet_score = 10, -- 基础下注数
    shuihu_probability = 0.4, -- 水浒传几率
    lottery_ticket_probability = 0.1, -- 奖券几率
    min_broadcast_multiple = 100, -- 最小广播倍率
}

-- 全屏
game_config.fullscreen = {
    icon_probability = { 1.0, 0.6, 0.5, 0.2, 0.1, 0.05, 0.01, 0.001, 0, 0 } -- 图标:几率
}

-- 比倍
game_config.dice = {
    0.3, 0.2, 0.1, 0.05, 0 -- 次数:胜率
}

-- 派奖
game_config.bonus = {
    max_win_count = 5, -- 最大获奖次数
    max_win_multiple = 200, -- 最大获奖倍数
    icon_probability = { 0.5, 0.3, 0.1, 0.05, 0.04, 0.03, 0.02, 0.01, 0, 0 } -- 图标:几率
}

-- 税率
game_config.tax_rate = {
    player_bet_tax_rate = 0.1, -- 玩家下注税率
    player_win_tax_rate = 0.0, -- 玩家获胜税率
    system_win_tax_rate = 0.0 -- 系统获胜税率
}

-- 库存
game_config.stock = {
    safety_line = 0, -- 安全线
    increase_tax_rate = 0.0 -- 增长税率
}

-- 奖池
game_config.prize_pool = {
    
}

return game_config
