-- 银行消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb

require "game/lobby/base_player"
local base_player = base_player

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

-- enum BANK_STATEMENT_OPT_TYPE
local BANK_STATEMENT_OPT_TYPE_DEPOSIT = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DEPOSIT")
local BANK_STATEMENT_OPT_TYPE_DRAW = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_DRAW")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT")
local BANK_STATEMENT_OPT_TYPE_TRANSFER_IN = pb.enum_id("BANK_STATEMENT_OPT_TYPE", "BANK_STATEMENT_OPT_TYPE_TRANSFER_IN")

local def_game_id = def_game_id


-- 设置银行密码
function on_cs_bank_set_password(player, msg)
	if player.bank_password then
		send2client_pb(player, "SC_BankSetPassword", {
			result = BANK_OPT_RESULT_PASSWORD_HAS_BEEN_SET,
		})
		return
	end
	
	player.bank_password = true

	send2client_pb(player, "SC_BankSetPassword", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	
	send2db_pb("SD_BankSetPassword", {
		guid = player.guid,
		password = msg.password,
	})
	
	print ("...................... on_cs_bank_set_password", player.bank_password)
end

-- 修改银行密码
function on_cs_bank_change_password(player, msg)
	if not player.bank_password then
		send2client_pb(player, "SC_BankChangePassword", {
			result = BANK_OPT_RESULT_PASSWORD_IS_NOT_SET,
		})
		return
	end
	
	send2db_pb("SD_BankChangePassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
	
	print ("...................... on_cs_bank_change_password", player.guid)
end

-- 修改银行密码结果
function on_ds_bank_change_password(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in center", msg.guid))
		return
	end
	
	send2client_pb(player, "SC_BankChangePassword", {
		result = msg.result,
	})
end

-- 登录银行
function on_cs_bank_login(player, msg)
	if player.bank_login then
		send2client_pb(player, "SC_BankLogin", {
			result = BANK_OPT_RESULT_ALREADY_LOGGED,
		})
		return
	end
	
	send2db_pb("SD_BankLogin", {
		guid = player.guid,
		password = msg.password,
	})
	
	print "...................... on_cs_bank_login"
end

-- 登录银行返回
function on_ds_bank_login(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in center", msg.guid))
		return
	end

	if msg.result == BANK_OPT_RESULT_SUCCESS then
		player.bank_login = true
	end

	send2client_pb(player, "SC_BankLogin", {
			result = msg.result,
		})
		
	print ("...................... on_ds_bank_login", msg.guid, msg.result)
end

local room_mgr = g_room_manager
-- 存钱
function on_cs_bank_deposit(player, msg)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了

	--游戏中，限制该操作
	if room_mgr:isPlay(player) then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	local money_ = msg and msg.money or 0
	local money = player.pb_base_info.money
	
	if money_ <= 0 or money < money_ then
		send2client_pb(player, "SC_BankDeposit", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end
	
	player.pb_base_info.money = money - money_
	local bank = player.pb_base_info.bank
	player.pb_base_info.bank = bank + money_
	
	player.flag_base_info = true
	
	send2client_pb(player, "SC_BankDeposit", {
		result = BANK_OPT_RESULT_SUCCESS,
		money = money_,
	})
	
	-- 日志
	send2db_pb("SD_BankLog", {
		time = get_second_time(),
		guid = player.guid,
		nickname = player.nickname,
		phone = player.phone,
		opt_type = 0,
		money = money_,
		old_money = money,
		new_money = player.pb_base_info.money,
		old_bank = bank,
		new_bank = player.pb_base_info.bank,
		ip = player.ip,
	})

	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_DEPOSIT,
			money = money_,
			bank_balance = player.pb_base_info.bank,
		},
	})]]
end

-- 取钱
function on_cs_bank_draw(player, msg)
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了

	--游戏中，限制该操作
	if room_mgr:isPlay(player) then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_FORBID_IN_GAMEING,
		})
		return
	end
	
	local money_ = msg and msg.money or 0
	local bank = player.pb_base_info.bank
	if money_ <= 0 or bank < money_ then
		send2client_pb(player, "SC_BankDraw", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end
	
	local money = player.pb_base_info.money
	player.pb_base_info.money = money + money_
	player.pb_base_info.bank = bank - money_
	
	player.flag_base_info = true
	
	send2client_pb(player, "SC_BankDraw", {
		result = BANK_OPT_RESULT_SUCCESS,
		money = money_,
	})
	
	-- 日志
	send2db_pb("SD_BankLog", {
		time = get_second_time(),
		guid = player.guid,
		nickname = player.nickname,
		phone = player.phone,
		opt_type = 1,
		money = money_,
		old_money = money,
		new_money = player.pb_base_info.money,
		old_bank = bank,
		new_bank = player.pb_base_info.bank,
		ip = player.ip,
	})

	--[[send2db_pb("SD_SaveBankStatement", {
		pb_statement = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_DRAW,
			money = money_,
			bank_balance = player.pb_base_info.bank,
		},
	})]]
end

-- 转账
function on_cs_bank_transfer(player, msg)
	if msg.account == player.account then
		log_error(string.format("on_cs_bank_transfer guid[%d] target = self", player.guid))
		return
	end

	if not player.enable_transfer then
		log_error(string.format("on_cs_bank_transfer enable_transfer=false guid[%d] target = self", player.guid))
		return
	end
	
	--[[if not player.bank_login then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_NOT_LOGIN,
		})
		return
	end]]-- 策划说不需要密码了
	
	local bank = player.pb_base_info.bank
	if msg.money <= 0 or bank < msg.money then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end
	
	player.pb_base_info.bank = bank - msg.money
	player.flag_base_info = true
		
	local target = base_player:find_by_account(msg.account)
	if target then -- 在该服务器情况
		target.pb_base_info.bank = target.pb_base_info.bank + msg.money
		target.flag_base_info = true
		
		-- self
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		--[[local statement_ = {
			guid = player.guid,
			time = get_second_time(),
			opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
			target = msg.account,
			money = msg.money,
			bank_balance = player.pb_base_info.bank,
		}
		send2db_pb("SD_SaveBankStatement", {
			pb_statement = statement_,
		})]]
		
		-- target
		send2client_pb(target, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		--[[statement_.guid = target.guid
		statement_.opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_IN
		statement_.target = player.account
		statement_.bank_balance = target.pb_base_info.bank
		send2db_pb("SD_SaveBankStatement", {
			pb_statement = statement_,
		})]]
	else -- 不在该服务器情况
		send2login_pb("SD_BankTransfer", {
			guid = player.guid,
			time = get_second_time(),
			target = msg.account,
			money = msg.money,
			bank_balance = player.pb_base_info.bank,
			selfname = player.account,
			game_id = def_game_id,
		})
	end

	print "...................................on_cs_bank_transfer"
end

function on_ls_bank_transfer_self(msg)
	send2client_pb(msg.guid, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	--[[local statement_ = {
		guid = msg.guid,
		time = msg.time,
		opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_OUT,
		target = msg.target,
		money = msg.money,
		bank_balance = msg.bank_balance.bank,
	}
	send2db_pb("SD_SaveBankStatement", {
		pb_statement = statement_,
	})]]

	print "...................................on_es_bank_transfer_self"
end

function on_ls_bank_transfer_target(msg)
	local target = base_player:find_by_account(msg.target)
	if not target then 
		log_warning(string.format("on_es_bank_transfer_target account[%s] not find in game", msg.target))
		return
	end

	target.pb_base_info.bank = target.pb_base_info.bank + msg.money
	target.flag_base_info = true

	send2client_pb(target, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
	})
	--[[local statement_ = {
		guid = target.guid,
		time = msg.time,
		opt = BANK_STATEMENT_OPT_TYPE_TRANSFER_IN,
		target = msg.selfname,
		money = msg.money,
		bank_balance = target.pb_base_info.bank,
	}
	send2db_pb("SD_SaveBankStatement", {
		pb_statement = statement_,
	})]]

	print "...................................on_es_bank_transfer_target"
end

-- 转账回复
function on_ds_bank_transfer(msg)
	if msg.result == BANK_OPT_RESULT_SUCCESS then
		local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
		
		send2client_pb(statement_.guid, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
		})
		
		--[[send2client_pb(statement_.guid, "SC_NotifyBankStatement", {
			pb_statement = statement_,
		})]]
	else
		local player = base_player:find(msg.guid)
		if not player then
			log_warning(string.format("on_ds_bank_transfer guid[%d] not find in game", msg.guid))
			return
		end
		
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
	
		player.flag_base_info = true
		
		send2client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end

	print "...................................on_ds_bank_transfer"
end

-- 通过guid转账
function on_cs_bank_transfer_by_guid(player, msg)
	if msg.guid == player.guid then
		log_error(string.format("on_cs_bank_transfer_by_guid guid[%d] target = self", player.guid))
		return
	end

	if not player.enable_transfer then
		log_error(string.format("on_cs_bank_transfer_by_guid enable_transfer=false guid[%d] target = self", player.guid))
		return
	end
	
	-- 银行钱不够
	local bank = player.pb_base_info.bank
	if msg.money <= 0 or bank < msg.money then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_MONEY_ERR,
		})
		return
	end
	
	-- 扣自己钱
	player.pb_base_info.bank = bank - msg.money
	player.flag_base_info = true
		
	local target = base_player:find(msg.guid)
	if target then -- 在该服务器情况
		target.pb_base_info.bank = target.pb_base_info.bank + msg.money
		target.flag_base_info = true
		
		-- self
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			money = -msg.money,
			bank = player.pb_base_info.bank,
		})
		
		-- target
		send2client_pb(target, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			money = msg.money,
			bank = target.pb_base_info.bank,
		})

	else -- 不在该服务器情况
		-- 向login转发
		send2login_pb("S_BankTransferByGuid", {
			guid = player.guid,
			target_guid = msg.guid,
			money = msg.money,
			--bank_balance = player.pb_base_info.bank,
		})
	end

	print "...................................on_cs_bank_transfer_by_guid"
end

function on_ls_bank_transfer_by_guid(msg)
	local player = base_player:find(msg.guid)
	if not player then 
		log_warning(string.format("on_ls_bank_transfer_by_guid guid[%d] not find in game", msg.guid))
		return
	end

	if msg.money > 0 then
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
	end

	send2client_pb(player, "SC_BankTransfer", {
		result = BANK_OPT_RESULT_SUCCESS,
		money = msg.money,
		bank = player.pb_base_info.bank,
	})

	print "...................................on_ls_bank_transfer_by_guid"
end

-- 转账回复
function on_ds_bank_transfer_by_guid(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("on_ds_bank_transfer_by_guid guid[%d] not find in game", msg.guid))
		return
	end

	if msg.result == BANK_OPT_RESULT_SUCCESS then
		send2client_pb(player, "SC_BankTransfer", {
			result = BANK_OPT_RESULT_SUCCESS,
			money = -msg.money,
			bank = player.pb_base_info.bank,
		})
	else
		-- 失败恢复钱
		player.pb_base_info.bank = player.pb_base_info.bank + msg.money
		player.flag_base_info = true
		
		send2client_pb(player, "SC_BankTransfer", {
			result = msg.result,
		})
	end

	print "...................................on_ds_bank_transfer"
end

-- 保存流水
function on_ds_save_bank_statement(msg)
	local statement_ = pb.decode(msg.pb_statement[1], msg.pb_statement[2])
	
	--[[send2client_pb(statement_.guid, "SC_NotifyBankStatement", {
		pb_statement = statement_,
	})]]
end


-- 银行流水记录
function on_cs_bank_statement(player, msg)
	if player.b_bank_statement then
		log_warning(string.format("on_cs_bank_statement guid[%d] repeated", player.guid))
		return
	end
	player.b_bank_statement = true
	
	send2db_pb("SD_BankStatement", {
		guid = player.guid,
		cur_serial = (msg and msg.cur_serial or 0),
	})
end

function on_ds_bank_statement(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("on_ds_bank_statement guid[%d] not find in game", msg.guid))
		return
	end
	
	for i, v in ipairs(msg.pb_statement) do
		msg.pb_statement[i] = pb.decode(v[1], v[2])
	end
	
	send2client_pb(player, "SC_BankStatement", {
		pb_statement = msg.pb_statement,
	})
end
