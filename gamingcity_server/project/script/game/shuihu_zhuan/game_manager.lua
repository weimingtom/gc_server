
local game_manager = {}

local game_table = require("game/shuihu_zhuan/game_table")

-- 初始化对象
function game_manager.init(room_count, table_count, chair_count)
    assert(room_count and room_count > 0)
    assert(table_count and table_count > 0)
    assert(chair_count and chair_count > 0)

    game_manager.room_count = room_count
    game_manager.table_count = table_count
    game_manager.chair_count = chair_count
    game_manager.rooms = {}
    for i = 1, game_manager.room_count do
        game_manager.rooms[i] = {}
        for j = 1, game_manager.table_count do
            game_manager.rooms[i][j] = game_table:new(chair_count)
        end
    end
end

-- 用户坐下
function game_manager.on_sitdown(player)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])

    game_manager.rooms[player.room_id][player.table_id]:on_sitdown(player)
end

-- 用户起立
function game_manager.on_standup(player)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])

    game_manager.rooms[player.room_id][player.table_id]:on_standup(player)
end

function game_manager.on_cs_rotate_pattern(player, msg)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])

    game_manager.rooms[player.room_id][player.table_id]:on_cs_rotate_pattern(player, msg)
end

function game_manager.on_cs_compare_dice(player, msg)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])

    game_manager.rooms[player.room_id][player.table_id]:on_cs_compare_dice(player, msg)
end

function game_manager.on_cs_rotate_bonus(player, msg)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])

    game_manager.rooms[player.room_id][player.table_id]:on_cs_rotate_bonus(player, msg)
end

function game_manager.on_cs_collect_score(player, msg)
    assert(player and player.room_id and player.table_id)
    assert(game_manager.rooms[player.room_id][player.table_id])
    
    game_manager.rooms[player.room_id][player.table_id]:on_cs_collect_score(player, msg)
end

return game_manager
