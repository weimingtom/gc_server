-- 日志消息处理

local pb = require "protobuf"

require "db/msg/net_func"
local send2center_pb = send2center_pb
local send2game_pb = send2game_pb

require "db/db_opt"
local db_execute = db_execute
local db_execute_query = db_execute_query

-- 钱日志
function on_sd_log_money(game_id, msg)

	local db = get_log_db()
	db_execute(db, "INSERT INTO t_log_money SET $FIELD$;", msg)
	
	--print ("...................... on_sd_log_money")
end

function save_error_sql(str_sql)
    local db = get_log_db()
    local sqlT = string.gsub(str_sql,"'","''")
    local sql = string.format("INSERT INTO `log`.`t_erro_sql` (`sql`) VALUES ('%s')",sqlT)
    db_execute(db,sql)
    --print ("...................... save_error_sql")
end

function on_sl_channel_invite_tax(game_id, msg)
    --print("ChannelInviteTaxes step 3--------------------------------")
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_channel_invite_tax` (`guid`, `guid_contribute`, `val`, `time`)
    VALUES (%d, %d, %d, NOW())]],
    msg.guid_invite,msg.guid,msg.val);

    db_execute_query_update(db, sql, function(ret)
        if ret > 0 then
            --print("on_sl_channel_invite_tax t_log_channel_invite_tax success");
        else
            --save_error_sql(sql)
        end
    end)
    --print("ChannelInviteTaxes step 4--------------------------------")
    local game_db = get_game_db()
    sql = string.format([[
    INSERT INTO `game`.`t_channel_invite_tax` (`guid`, `val`)
    VALUES (%d, %d)]],
    msg.guid_invite,msg.val);

    db_execute_query_update(game_db, sql, function(ret)
        if ret > 0 then
            --print("on_sl_channel_invite_tax t_channel_invite_tax success");
        else
            --save_error_sql(sql)
        end
    end)
    --print("ChannelInviteTaxes step 5--------------------------------")

end
function on_sl_log_money(game_id, msg)
    --print ("...................... on_sl_log_money")
    -- body
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_money_tj` (`guid`, `type`, `gameid`, `game_name`,`phone_type`, `old_money`, `new_money`, `tax`, `change_money`, `ip`, `id`, `channel_id`)
    VALUES (%d, %d, %d, '%s', '%s', %d, %d, %d, %d, '%s', '%s', '%s')]],
    msg.guid,msg.type,msg.gameid,msg.game_name,msg.phone_type,msg.old_money,msg.new_money,msg.tax,msg.change_money,msg.ip,msg.id,msg.channel_id);

    db_execute_query_update(db, sql, function(ret)
        --print("on_sl_log_money=============================================1")
        if ret > 0 then
            --print("on_sl_log_money success");
        else
            --save_error_sql(sql)
        end
    end)
end
function on_sl_log_Game(game_id, msg)
    --print ("...................... on_sl_log_Game")
    -- body
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_game_tj` (`id`, `type`, `log`, `start_time`,`end_time`)
    VALUES ('%s', '%s', '%s', FROM_UNIXTIME(%d), FROM_UNIXTIME(%d))]],
    msg.playid,msg.type,msg.log,msg.starttime,msg.endtime);
    db_execute_query_update(db, sql, function(ret)
        --print("on_sl_log_Game=============================================1")
        if ret > 0 then
            --print("on_sl_log_Game success");
        else
            --save_error_sql(sql)
        end
    end)
end

function on_sl_robot_log_money(game_id,msg)
	 --print ("...................... on_sl_robot_log_money")
    -- body
    local db = get_log_db()
    local sql = string.format([[
    INSERT INTO `log`.`t_log_robot_money_tj` (`guid`, `is_banker`, `winorlose`,`gameid`, `game_name`,`old_money`, `new_money`, `tax`, `money_change`, `id`)
    VALUES (%d, %d, %d, %d, '%s', %d, %d, %d, %d, '%s')]],
    msg.guid,msg.isbanker,msg.winorlose,msg.gameid,msg.game_name,msg.old_money,msg.new_money,msg.tax,msg.money_change,msg.id);

    db_execute_query_update(db, sql, function(ret)
        --print("on_sl_robot_log_money=============================================1")
        if ret > 0 then
            --print("on_sl_robot_log_money success");
        else
            --save_error_sql(sql)
        end
    end)
end