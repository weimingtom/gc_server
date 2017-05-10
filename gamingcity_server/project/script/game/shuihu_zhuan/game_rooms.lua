
require("game/lobby/base_rooms")

local init_rooms_ = g_init_rooms_
local player_rooms_ = g_player_rooms_
local game_rooms = base_rooms:new()
local game_manager = require("game/shuihu_zhuan/game_manager")

function game_rooms:on_sit_down(player)
    game_manager.on_sitdown(player)
end

-- 快速坐下
function game_rooms:auto_sit_down(player)
    if not base_rooms.auto_sit_down(self, player) then
        return false
    end
    
    self:on_sit_down(player)
    return true
end

-- 坐下
function game_rooms:sit_down(player, table_id_, chair_id_)
    if not base_rooms.sit_down(self, player, table_id_, chair_id_) then
        return false
    end
    
    self:on_sit_down(player)
    return true
end

function game_rooms:on_stand_up(player)
    game_manager.on_standup(player)
end

-- 站起
function game_rooms:stand_up(player)
    self:on_stand_up(player)

    if not base_rooms.stand_up(self, player) then
        return false
    end
    return true
end

return game_rooms
