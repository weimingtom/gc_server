-- 银行消息处理

local pb = require "protobuf"

require "db/msg/net_func"
local send2game_pb = send2game_pb

require "db/db_opt"
local db_execute_query_update = db_execute_query_update
local db_execute_query = db_execute_query

require "redis_opt"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query


-- enum BANK_OPT_RESULT
local BANK_OPT_RESULT_SUCCESS = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_SUCCESS")
local BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET")
local BANK_OPT_RESULT_PASSWORD_IS_NOT_SET = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_PASSWORD_IS_NOT_SET")
local BANK_OPT_RESULT_OLD_PASSWORD_ERR = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_OLD_PASSWORD_ERR")
local BANK_OPT_RESULT_ALREADY_LOGGED = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_ALREADY_LOGGED")
local BANK_OPT_RESULT_LOGIN_FAILED = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_LOGIN_FAILED")
local BANK_OPT_RESULT_NOT_LOGIN = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_NOT_LOGIN")
local BANK_OPT_RESULT_MONEY_ERR = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_MONEY_ERR")
local BANK_OPT_RESULT_TRANSFER_ACCOUNT = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_TRANSFER_ACCOUNT")
local BANK_OPT_RESULT_FORBID_IN_GAMEING = pb.enum_id("BANK_OPT_RESULT", "BANK_OPT_RESULT_FORBID_IN_GAMEING")

-- enum BANK_STATEMENT_OPT_TYPE
local BANK_STATEMENT_OPT_TYPE_DEPOSIT = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DEPOSIT")
local BANK_STATEMENT_OPT_TYPE_DRAW = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DRAW")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_IN = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_IN")



-- 设置银行密码
function on_sd_bank_set_password(game_id, msg)
	local db = get_account_db()
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d;", msg.password, msg.guid)
	db:execute(sql)
	
	print "......................... on_sd_bank_set_password"
end

-- 修改银行密码
function on_sd_bank_change_password(game_id, msg)
	local guid_ = msg.guid
	
	local db = get_account_db()
	local sql = string.format("UPDATE t_account SET bank_password = '%s' WHERE guid = %d AND bank_password = '%s';", 
		msg.password, guid_, msg.old_password)
	local gameid = game_id
		
	db_execute_query_update(db, sql, function(ret)
		send2game_pb(gameid, "DS_BankChangePassword", {
			guid = guid_,
			result = (ret > 0 and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_OLD_PASSWORD_ERR),
		})
	end)
end

-- 登录银行
function on_sd_bank_login(game_id, msg)
	local guid_ = msg.guid
	
	local db = get_account_db()
	local sql = string.format("SELECT guid FROM t_account WHERE guid = %d AND bank_password = '%s';", guid_, msg.password)
	local gameid = game_id
	
	db_execute_query(db, false, sql, function (data)
		send2game_pb(gameid, "DS_BankLogin", {
			guid = guid_,
			result = (data ~= nil and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_LOGIN_FAILED)
		})
	end)
	
	print "......................... on_sd_bank_login"
end

-- 银行转账
function on_sd_bank_transfer(game_id, msg)
	local db = get_game_db()
	local sql = string.format("CALL bank_transfer(%d, %d, '%s', %d, %d);", 
		msg.guid, msg.time, msg.target, msg.money, msg.bank_balance)
	local gameid = msg.game_id
	
	db_execute_query(db, false, sql, function (data)
		if not data then
			log_warning("on_sd_bank_transfer data = null")
			return
		end
		
		if data.ret ~= 0 then
			-- 没有找到收款的人
			log_warning("bank transfer data.ret != 0, guid:"..msg.guid .. ",target:" .. msg.target)
			send2game_pb(gameid, "DS_BankTransfer", {
				result = BANK_OPT_RESULT_TRANSFER_ACCOUNT,
				guid = msg.guid,
				money = msg.money,
			})
			return
		end
		
		send2game_pb(gameid, "DS_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			pb_statement = {
				serial = tostring(data.id),
				guid = msg.guid,
				time = msg.time,
				opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
				target = msg.target,
				money = msg.money,
				bank_balance = msg.bank_balance,
			},
		})
	end)
end

function on_s_bank_transfer_by_guid(login_id, msg)
	local db = get_game_db()
	local sql = string.format("UPDATE t_player SET bank = bank + %d WHERE guid = %d;", 
		msg.money, msg.target_guid)

	db_execute_query_update(db, sql, function(ret)
		--[[
		redis_cmd_query(string.format("HGET player_base_info %d", msg.target_guid), function (reply)
			if reply:is_string() then
				local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
				info.bank = info.bank + msg.money
				
				redis_command(string.format("HSET player_base_info %d %s", msg.target_guid, to_hex(pb.encode("PlayerBaseInfo", info))))
			end
		end--)]]

		send2game_pb(msg.game_id, "DS_BankTransferByGuid", {
			result = (ret > 0 and BANK_OPT_RESULT_SUCCESS or BANK_OPT_RESULT_TRANSFER_ACCOUNT),
			guid = msg.guid,
			money = msg.money,
		})
	end)
end

-- 记录银行流水
function on_sd_save_bank_statement(game_id, msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
	
	local db = get_game_db()
	local sql = string.format("CALL save_bank_statement(%d,%d,%d,'%s',%d,%d);", 
		statement_.guid, statement_.time, statement_.opt, statement_.target, statement_.money, statement_.bank_balance)
	local gameid = game_id
	
	db_execute_query(db, false, sql, function (data)
		if not data then
			log_warning("on_sd_save_bank_statement data = null")
			return
		end
		
		statement_.serial = data.id
		send2game_pb(gameid, "DS_SaveBankStatement", {
			pb_statement = statement_,
		})
	end)
end

-- 查询银行流水记录
local function get_bank_statement(guid_, serial, gameid)
	local db = get_game_db()
	local sql = string.format("SELECT id AS serial,guid,UNIX_TIMESTAMP(time) AS time,opt,target,money,bank_balance FROM t_bank_statement WHERE id>%d AND guid=%d ORDER BY id ASC LIMIT 20;", serial, guid_)
	
	db_execute_query(db, true, sql, function (data)
		if not data then
			log_warning("get_bank_statement data = null")
			return
		end
		
		for _, item in ipairs(data) do
			item.serial = item.serial
		end
		
		send2game_pb(gameid, "DS_BankStatement", {
			guid = guid_,
			pb_statement = data,
		})
		
		if #data ~= 20 then
			return
		end
		
		get_bank_statement(guid_, data[20].serial, gameid)
	end)
end
function on_sd_bank_statement(game_id, msg)
	get_bank_statement(msg.guid, msg.cur_serial, game_id)
end


function on_SD_BankLog(game_id, msg)
	local db = get_log_db()
	local sql = string.format("INSERT INTO t_log_bank SET time=FROM_UNIXTIME(%d),guid=%d,nickname='%s',phone='%s',opt_type=%d,money=%d,old_money=%d,new_money=%d,old_bank=%d,new_bank=%d,ip='%s'", 
		msg.time, msg.guid, msg.nickname, msg.phone, msg.opt_type, msg.money, msg.old_money, msg.new_money, msg.old_bank, msg.new_bank, msg.ip)

	db:execute(sql)
end