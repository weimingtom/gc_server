local pb = require "protobuf"

local LOG_MONEY_OPT_TYPE_GM = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_GM")
local db_execute = db_execute
require "redis_opt"
local redis_command = redis_command


require "db/msg/net_func"
local send2game_pb = send2game_pb
local send2login_pb = send2login_pb


function gm_change_money(guid,money,log_type)
	print("gm_change_money comming......")
	local db = get_game_db()
	
	-- 基本数据
	--[[
	redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then -- guid in redis
			local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			print(string.format("guid[%d] is in redis.",guid))
			info.money = info.money or 0
			local oldmoney = info.money
			if(money < 0) then
				local tempMoney = oldmoney + money
				if tempMoney < 0 then
					return false
				end
			end
			info.money = oldmoney + money
			info.money = info.money or 0
			db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
			redis_command(string.format("HSET player_base_info %d %s", guid, to_hex(pb.encode("PlayerBaseInfo", info))))
		--[[	local msg = {
				guid = guid,
				old_money = oldmoney,
				new_money = info.money,
				old_bank =  info.bank,
				new_bank = info.bank,
				opt_type = LOG_MONEY_OPT_TYPE_GM
			}--]]
			-- 加钱日志存档
			--[[
			local log_db = get_log_db()
			local sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,oldmoney,info.money,info.bank,info.bank,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(sql)
		else
			print(string.format("guid[%d] is not in redis.",guid))
			local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
			db_execute_query(db, true, sql, function (data)
				if data and #data > 0 then	
					local old_money = data[1].money
					local old_bank = data[1].bank
					if(money < 0) then
						local tempMoney = old_money + money
						if tempMoney < 0 then
							return false
						end
					end
					local new_money = old_money + money
					local sql = string.format("UPDATE t_player SET money=%d WHERE guid=%d;",new_money,guid)
					db:execute(sql)
					-- 加钱日志存档
					local log_db = get_log_db()
					local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,new_money,old_bank,old_bank,log_type or LOG_MONEY_OPT_TYPE_GM)
					log_db:execute(log_sql)
				end
			end)
		end
	end)--]]
	
	local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then	
			local old_money = data[1].money
			local old_bank = data[1].bank
			if(money < 0) then
				local tempMoney = old_money + money
				if tempMoney < 0 then
					return false
				end
			end
			local new_money = old_money + money
			local sql = string.format("UPDATE t_player SET money=%d WHERE guid=%d;",new_money,guid)
			db:execute(sql)
			-- 加钱日志存档
			local log_db = get_log_db()
			local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,new_money,old_bank,old_bank,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(log_sql)
		end
	end)
	return true
  
end

function gm_change_bank_money(guid,bank_money,log_type)
	print("gm_change_bank_money comming......")
    local db = get_game_db()
	--[[
	-- 基本数据
	redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then -- guid in redis
			local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			print(string.format("22guid[%d] is in redis.",guid))
			info.bank = info.bank or 0
			local oldbank = info.bank
			if(bank_money < 0) then
				local tempMoney = oldbank + bank_money
				if tempMoney < 0 then
					return false
				end
			end
			info.bank = oldbank + bank_money
			info.bank = info.bank or 0
			db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
			redis_command(string.format("HSET player_base_info %d %s", guid, to_hex(pb.encode("PlayerBaseInfo", info))))
		--[[	local msg = {
				guid = guid,
				old_money = oldmoney,
				new_money = info.money,
				old_bank =  info.bank,
				new_bank = info.bank,
				opt_type = LOG_MONEY_OPT_TYPE_GM
			}--]]
			-- 加钱日志存档
			--[[
			local log_db = get_log_db()
			local sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,info.money,info.money,oldbank,info.bank,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(sql)
		else
			print(string.format("guid[%d] is not in redis.",guid))
			local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
			db_execute_query(db, true, sql, function (data)
				if data and #data > 0 then	
					local old_money = data[1].money
					local old_bank = data[1].bank
					if(bank_money < 0) then
						local tempMoney = old_bank + bank_money
						if tempMoney < 0 then
							return false
						end
					end
					local new_bank_money = old_bank + bank_money
					local sql = string.format("UPDATE t_player SET bank=%d WHERE guid=%d;",new_bank_money,guid)
					db:execute(sql)
					-- 加钱日志存档
					local log_db = get_log_db()
					local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,old_money,old_bank,new_bank_money,log_type or LOG_MONEY_OPT_TYPE_GM)
					log_db:execute(log_sql)
				end
			end)
		end
	end)--]]
	
	local sql = string.format("SELECT money,bank from t_player WHERE guid = %d;",guid)
	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then	
			local old_money = data[1].money
			local old_bank = data[1].bank
			if(bank_money < 0) then
				local tempMoney = old_bank + bank_money
				if tempMoney < 0 then
					return false
				end
			end
			local new_bank_money = old_bank + bank_money
			local sql = string.format("UPDATE t_player SET bank=%d WHERE guid=%d;",new_bank_money,guid)
			db:execute(sql)
			-- 加钱日志存档
			local log_db = get_log_db()
			local log_sql = string.format("INSERT INTO t_log_money SET guid = %d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,opt_type=%d;",guid,old_money,old_money,old_bank,new_bank_money,log_type or LOG_MONEY_OPT_TYPE_GM)
			log_db:execute(log_sql)
		end
	end)

	return true
end

function gm_change_bank(web_id_, login_id, guid, bank_money, log_type)
    local db = get_game_db()
	local sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", bank_money, guid)

	db_execute_query_update(db, sql, function(ret)
		if ret == 0 then
			send2login_pb(login_id, "DL_LuaCmdPlayerResult", {
				web_id = web_id_,
				result = 0,
				})

			log_warning("gm_change_bank not find guid:" .. guid)
			return;
		end

		send2login_pb(login_id, "DL_LuaCmdPlayerResult", {
			web_id = web_id_,
			result = 1,
			})

		sql = string.format("SELECT money, bank FROM t_player WHERE guid = %d;", guid)
		db_execute_query(db, false, sql, function (data)
			if not data then
				log_warning("gm_change_bank data = null")
				return
			end

			--[[redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
				if reply:is_string() then
					local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
					info.bank = data.bank
					
					redis_command(string.format("HSET player_base_info %d %s", guid, to_hex(pb.encode("PlayerBaseInfo", info))))
				end
			end)--]]
			-- 加钱日志存档
			db = get_log_db()
			local log = {
				guid = guid,
				old_money = data.money,
				new_money = data.money,
				old_bank = data.bank-bank_money,
				new_bank = data.bank,
				opt_type = log_type or LOG_MONEY_OPT_TYPE_GM,
			}
			db_execute(db, "INSERT INTO t_log_money SET $FIELD$;", log)
		end)
	end)
end

--[[maintain_switch = 1
--gm命令维护开关通知
--switch_type:开关类型(1提现开关,2游戏服开关)
--switch_flag:开关(0关,1开)
function gm_query_maintain_switch(switch_type,switch_flag)
	print("gm_query_maintain_switch comming......")
	--test_code
	if maintain_switch == 0 then
		maintain_switch = 1 
	else
		maintain_switch = 0
	end
	print("gm_query_maintain_switch comming......"..maintain_switch)
end--]]