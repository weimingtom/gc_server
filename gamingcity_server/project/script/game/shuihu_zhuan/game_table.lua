
local game_type = require("game/shuihu_zhuan/game_type")
local game_config = require("game/shuihu_zhuan/game_config")
local game_helper = require("game/shuihu_zhuan/game_helper")
local tablex = require("utils/tablex")
local logger = require("utils/logger")

require "game/net_func"
local send2client_pb = send2client_pb

local game_table = {}

local scene_type = {
    scene_free = 1,
    scene_pattern = 2,
    scene_dice = 3,
    scene_bonus = 4,
}

-- 创建对象
function game_table:new(chair_count)
    if not self.__index then
        self.__index = self
    end
    local object = setmetatable({}, self)
    object.chair_count = chair_count
    object.player = nil
    object:reset()
    return object
end

-- 重置对象
function game_table:reset()
    self.current_scene = scene_type.scene_free
    self.bet_score = 0
    self.pattern_data = {}
    self.pattern_result = {}
    self.pattern_multiple = 0
    self.dice_turns = 0
    self.dice_win_count = 0
    self.dice_multiple = 0
    self.bonus_turns = 0
    self.bonus_win_count = 0
    self.bonus_multiple = 0
end

-- 用户坐下
function game_table:on_sitdown(player)
    logger.trace("game_table:on_sitdown(%d, %d, %d)", player.room_id, player.table_id, player.chair_id)
    self.player = player

    self.win_count = 0
    self.lose_count = 0
    self.tie_count = 0
    self.player_score = 0
end

-- 用户起立
function game_table:on_standup(player)
    logger.trace("game_table:on_standup(%d, %d, %d)", player.room_id, player.table_id, player.chair_id)
    self:over_game()
    self.player = nil

    logger.info("player win count: %d, lose count: %d, tie count: %d", self.win_count, self.lose_count, self.tie_count)
    logger.info("player win score: %d", self.player_score)
    
    self.win_count = 0
    self.lose_count = 0
    self.tie_count = 0
    self.player_score = 0
end

-- 游戏开始
function game_table:start_game(bet_score, line_count)
    line_count = line_count or 9

    self.player_score = self.player_score - bet_score

    self:rotate_pattern(bet_score, line_count)
end

-- 游戏结束
function game_table:over_game()
    -- 场景判断
    if self.current_scene == scene_type.scene_free then
        logger.debug("game_table:over_game(current_scene=%d)", self.current_scene)
        return
    end

    -- 游戏结算
    local result_multiple = self.pattern_multiple + self.dice_multiple + self.bonus_multiple
    local result_score = self.bet_score * result_multiple

    -- 发送结果
    send2client_pb(self.player, "SC_ScoreChanged", {
        lottery_score = result_score,
        player_score = 0
        })

    -- 重置数据
    self:reset()

    if result_multiple > 9 then
        self.win_count = self.win_count + 1
    elseif result_multiple < 9 then
        self.lose_count = self.lose_count + 1
    else
        self.tie_count = self.tie_count + 1
    end
    self.player_score = self.player_score + result_score
end

-- 图案模式
function game_table:rotate_pattern(bet_score, line_count)
    -- 参数校验
    if bet_score <= 0 or line_count <= 0 or line_count > 9 then
        logger.debug("game_table:rotate_pattern(bet_score=%d, line_count=%d)", bet_score, line_count)
        return
    end

    local integer, decimal = math.modf(bet_score / 9 / game_config.bet_score)
    if integer < 1 or integer > 10 or decimal ~= 0 then
        logger.debug("game_table:rotate_pattern(bet_score=%d, line_count=%d)", bet_score, line_count)
        return
    end

    -- 场景判断
    if self.current_scene ~= scene_type.scene_free then
        logger.debug("game_table:rotate_pattern(current_scene=%d)", self.current_scene)
        return
    end

    -- 场景计算
    self.bet_score = bet_score / 9
    self.current_scene = scene_type.scene_pattern

    self.pattern_data = game_helper.generate_random_pattern()
    self.pattern_result = game_helper.analyse_pattern(self.pattern_data)
    self.pattern_multiple = self.pattern_result.multiple_sum

    -- 发送结果
    local pattern_result = {}
    pattern_result.pattern_data = {}
    for i = 1, 3 do
        for j = 1, 5 do
            table.insert(pattern_result.pattern_data, self.pattern_data[i][j])
        end
    end
    pattern_result.pattern_multiple = self.pattern_result.multiple_sum
    pattern_result.bonus_times = self.pattern_result.bonus_times
    pattern_result.lottery_ticket_count = self.pattern_result.lottery_ticket_count
    pattern_result.lottery_items = self.pattern_result.result_items
    pattern_result.lottery_score = self.pattern_result.multiple_sum * self.bet_score
    send2client_pb(self.player, "SC_PatternResult", pattern_result)

    if self.pattern_multiple == 0 then
        self:over_game()
    end
end

-- 比倍模式
function game_table:compare_dice(buy_type)
    -- 参数校验
    if not (buy_type == game_type.dice_type.dice_small or buy_type == game_type.dice_type.dice_tie or buy_type == game_type.dice_type.dice_big) then
        logger.debug("game_table:compare_dice(buy_type=%d)", buy_type)
        return
    end

    -- 场景判断
    if self.current_scene == scene_type.scene_free or self.current_scene == scene_type.scene_bonus then
        logger.debug("game_table:compare_dice(current_scene=%d)", self.current_scene)
        return
    end

    -- 场景计算
    if self.current_scene == scene_type.scene_pattern then
        self.current_scene = scene_type.scene_dice
        self.dice_multiple = self.pattern_multiple
        self.pattern_multiple = 0
    end

    local point1, point2 = game_helper.generate_random_dice()
    local lottery_type, multiple = game_helper.calc_dice_lottery(point1, point2, buy_type)

    self.dice_turns = self.dice_turns + 1

    if multiple ~= 0 then
        self.dice_multiple = self.dice_multiple + multiple
        self.dice_win_count = self.dice_win_count + 1
    else
        self.dice_multiple = 0
    end

    -- 发送结果
    local dice_result = {}
    dice_result.dice_point1 = point1
    dice_result.dice_point2 = point2
    dice_result.lottery_type = lottery_type
    dice_result.lottery_multiple = self.dice_multiple
    dice_result.lottery_score = self.dice_multiple * self.bet_score
    send2client_pb(self.player, "SC_DiceResult", dice_result)

    if self.dice_multiple == 0 then
        self:over_game()
    end
end

-- 派奖模式
function game_table:rotate_bonus()
    -- 场景判断
    if self.current_scene == scene_type.scene_free or self.current_scene == scene_type.scene_dice then
        logger.debug("game_table:rotate_bonus(current_scene=%d)", self.current_scene)
        return
    end
    if self.pattern_result.bonus_times <= 0 then
        logger.debug("game_table:rotate_bonus(bonus_times <= 0)")
        return
    end

    -- 场景计算
    if self.current_scene == scene_type.scene_pattern then
        self.current_scene = scene_type.scene_bonus
    end

    local rolling_icons = game_helper.generate_random_rolling_icons()
    local rotate_icon = game_helper.generate_random_rotate_icon()
    local multiple = game_helper.calc_bonus_lottery(rolling_icons, rotate_icon)

    if multiple ~= 0 then
        self.bonus_multiple = self.bonus_multiple + multiple
        self.bonus_win_count = self.bonus_win_count + 1
    end

    if rotate_icon == game_type.icon_type.shuihu_zhuan then
        self.bonus_turns = self.bonus_turns + 1
    end

    -- 发送结果
    local bonus_result = {}
    bonus_result.rolling_icons = rolling_icons
    bonus_result.rotate_icon = rotate_icon
    bonus_result.lottery_multiple = self.bonus_multiple
    bonus_result.lottery_score = self.bonus_multiple * self.bet_score
    bonus_result.remain_times = self.pattern_result.bonus_times - self.bonus_turns
    send2client_pb(self.player, "SC_BonusResult", bonus_result)

    if self.bonus_turns >= self.pattern_result.bonus_times then
        self:over_game()
    end
end

function game_table:on_cs_rotate_pattern(player, msg)
    logger.trace("game_table:on_cs_rotate_pattern: %d", msg.bet_score)
    self:start_game(msg.bet_score)
end

function game_table:on_cs_compare_dice(player, msg)
    msg = msg or { dice_type = 0 }
    logger.trace("game_table:on_cs_compare_dice: %d", msg.dice_type)
    self:compare_dice(msg.dice_type)
end

function game_table:on_cs_rotate_bonus(player, msg)
    logger.trace("game_table:on_cs_rotate_bonus")
    self:rotate_bonus()
end

function game_table:on_cs_collect_score(player, msg)
    logger.trace("game_table:on_cs_collect_score")
    self:over_game()
end

return game_table
