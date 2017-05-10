
local game_type = {}

-- 图标类型
game_type.icon_type = {
    fu_tou = 1,
    ying_qiang = 2,
    da_dao = 3,
    lu_zhi_shen = 4,
    lin_chong = 5,
    song_jiang = 6,
    ti_tian_xing_dao = 7,
    zhong_yi_tang = 8,
    shuihu_zhuan = 9,
    lottery_ticket = 10,
}

-- 连接类型
game_type.link_type = {
    link_three = 1,
    link_four = 2,
    link_five = 3,
    link_wuqi = 4,
    link_renwu = 5,
    link_fullscreen = 6,
}

-- 连接方向
game_type.link_direction = {
    direction_left = -1,
    direction_right = 1,
}

-- 骰子类型
game_type.dice_type = {
    dice_small = -1,
    dice_tie = 0,
    dice_big = 1,
}

return game_type
