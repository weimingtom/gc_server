-- 银行消息处理

local pb = require "protobuf"

require "game/net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb
local send2login_pb = send2login_pb

require "game/lobby/base_player"
local base_player = base_player

local def_game_id = def_game_id

local LOG_MONEY_OPT_TYPE_CASH_MONEY = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")
local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")

--处理充值
function on_changmoney_deal(msg)
	local info = msg.info
	log_info(string.format("on_changmoney_deal  begin----------------- player  guid[%d]  money[%g] type[%d] order_id[%d]", info.guid, info.gold, info.type_id, info.order_id))
	local player = base_player:find(info.guid)	
	local nmsg = {
		web_id = msg.web_id,
		result = 1,	
		info = msg.info,
		befor_bank = 0,
		after_bank = 0,
	}
	if player and player.pb_base_info then
		bank_ = player.pb_base_info.bank
		local bRet = player:change_bank(info.gold, info.type_id, true)
		if bRet == true then
			nmsg.befor_bank = bank_
			nmsg.after_bank =  player.pb_base_info.bank
			send2db_pb("SD_ChangMoneyReply",nmsg)
			log_info "end...................................on_changmoney_deal   A"
			return
		end
		log_info("on_changmoney_deal bRet is" .. bRet);
	else
		log_error(string.format("on_changmoney_deal no find player  guid[%d]", info.guid))
		fmsg = {
		web_id =  msg.web_id,
		info = msg.info,
		}
		send2db_pb("FD_ChangMoneyDeal",nmsg)
		log_info ("end...................................on_changmoney_deal   B")		
	end
end

--处理提现回退
function on_cash_false_deal(msg)
	local info = msg.info
	log_info(string.format("on_changmoney_deal  begin----------------- player  guid[%d]  money[%g]  order_id[%d]", info.guid, info.coins, info.order_id))
	local player = base_player:find(info.guid)	
	local nmsg = {
		web_id = msg.web_id,
		result = 1,	
		server_id = msg.server_id,
		order_id = info.order_id,
		info = msg.info,
	}
	if player and  player.pb_base_info then
		local bRet = player:change_bank(info.coins, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
		if bRet == false then
			nmsg.result = 6
			log_warning(string.format("on_cash_false_deal..............................%d add money false player", info.guid))
		end
	else		
		nmsg.result = 5
		log_warning(string.format("on_cash_false_deal..............................%d no find player", info.guid))
	end
	send2loginid_pb(msg.login_id, "SL_CashReply",nmsg)
	log_info "end...................................on_cash_false_deal"
end

--用户申请提现
function on_cs_cash_money(player, msg)
	log_info("...................................on_cs_cash_money" ..player.guid)
	log_info(string.format("on_cs_cash_money  begin----------------- player  guid[%d]  money[%d] ", player.guid, msg.money ))
	local nmsg = {
		result = 1,
		bank = player.pb_base_info.bank ,
		money = player.pb_base_info.money,
	}
	--2017-04-20 by rocky add 添加提现开关
	if cash_switch == 1 then --提现维护中
		log_info("=======cash maintain ===============cash_switch:"..cash_switch)
		if player.vip ~= 100 then --非内部账号不能进入
			local msg = {
			result = GAME_SERVER_RESULT_MAINTAIN,
			}
			send2client_pb(player,"SC_CashMaintain", msg)		
			return
		end
		
	end

	--封号禁提现
	if player.disable == 1 then
		log_info ("------------- is disable：".. player.guid)
		send2client_pb(player,"SC_CashMoneyResult", nmsg)		
		return
	end
	if (player.alipay_account == nil or player.alipay_account == "") and (player.alipay_name == nil or player.alipay_name == "") then
		log_error ("alipay is empty")
		nmsg.result = 9
		send2client_pb(player,"SC_CashMoneyResult", nmsg)		
		return
	end
	local nmoney = msg.money / 100
	if nmoney < 50 or  nmoney % 50 ~= 0 then
		log_error ("msg.money < 50 or  msg.money % 50 ~= 0     ----------:".. msg.money )
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	--	6 元保底
	if player.pb_base_info.bank + player.pb_base_info.money < msg.money + 600 then
		local all_money_t_ = player.pb_base_info.bank + player.pb_base_info.money
		log_error ("msg.money----------:".. msg.money .. "all money -----------:" ..all_money_t_)
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
		return
	end
	local bRet = false
	local bef_money_ = player.pb_base_info.money 
	local bef_bank_ = player.pb_base_info.bank
	if player.pb_base_info.bank < msg.money then
		local money = msg.money - player.pb_base_info.bank
		bRet = player:change_money(-money, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
		if bRet == false then
			log_error("on_cs_cash_money player:change_money false")
			return
		end
		if player.pb_base_info.bank > 0 then
			bRet = player:change_bank(-player.pb_base_info.bank, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
			if bRet == false then
				log_error("on_cs_cash_money player:change_bank false")
				return
			end
		end
	else
		bRet = player:change_bank(-msg.money, LOG_MONEY_OPT_TYPE_CASH_MONEY, true)
		if bRet == false then
			log_error("on_cs_cash_money player:change_bank false")
			return
		end
	end
	local pay_money_ =  0
	if nmoney  < 150 then
		pay_money_ = nmoney - 2
	else
		pay_money_ = nmoney - nmoney * 0.02
	end
	local aft_money_ = player.pb_base_info.money 
	local aft_bank_ = player.pb_base_info.bank

	local fmsg = {
	guid = player.guid,
	money = nmoney,
	coins = msg.money,
	pay_money = pay_money_,
	phone = player.phone,
	phone_type = player.phone_type,
	ip = player.ip,
	bag_id = player.channel_id,
	bef_money = bef_money_,
	bef_bank = bef_bank_,
	aft_money = aft_money_,
	aft_bank = aft_bank_,
	}
	print ("bag_id", fmsg.bag_id)
	send2db_pb("SD_CashMoney", fmsg)
	log_info "end...................................on_cs_cash_money"
end
--用户查询提现记录
function on_cs_cash_money_type( player, msg )
	print "...................................on_cs_cash_money_type"	
	send2db_pb("SD_CashMoneyType", {guid = player.guid,})
	print "end...................................on_cs_cash_money_type"
end

--处理服务器返回提现记录
function on_ds_cash_money_type( msg )
	print "...................................on_ds_cash_money_type"	
	local player = base_player:find(msg.guid)	
	if player then
		local nmsg = {
		pb_cash_info = msg.pb_cash_info
		}
		send2client_pb(player,"SC_CashMoneyType",nmsg)
	else		
		log_warning(string.format("on_ds_cash_money_type..............................%d no find player", msg.guid))
	end
	print "...................................on_ds_cash_money_type end"	
end

--处理服务器返回提现记录
function on_ds_cash_money( msg )
	log_info (string.format("on_ds_cash_money begin  guid[%d]  money[%d]", msg.guid, msg.coins))
	local player = base_player:find(msg.guid)	
	local bRet = false
	if player and  player.pb_base_info  then
		bRet = true
		local nmsg = {
			result = 0,
			bank = player.pb_base_info.bank ,
			money = player.pb_base_info.money,
		}
		if msg.result ~= 1 then				
			nmsg.result = 2
			bRet = player:change_bank(msg.coins, LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
		end
		send2client_pb(player,"SC_CashMoneyResult", nmsg)
	else		
		log_warning(string.format("on_ds_cash_money..............................%d no find player", msg.guid))
	end
	if bRet == false then		
		log_error(string.format("on_ds_cash_money no find player  guid[%d]", msg.guid))
		fmsg = {
		web_id =  -1,
		info = {
			guid = msg.guid,
			type_id = LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE,
			gold = msg.coins,
			order_id = -1,
			},
		}
		send2db_pb("FD_ChangMoneyDeal",fmsg)
	end
	log_info "end...................................on_ds_cash_money"
end

function on_ls_addmoney( msg )
	print "start...................................on_ls_addmoney"
	local player = base_player:find(msg.guid)	
	local bRet = false
	if player and  player.pb_base_info  then
		bRet = player:change_bank(msg.money, LOG_MONEY_OPT_TYPE_CASH_MONEY)
	end
	if bRet == false then
		print "on_ls_addmoney----------------------false"

		local fmsg = 
		{
			guid = msg.guid,
			money = msg.money,
			add_type = msg.add_type,
		}
		send2login_pb("SL_AddMoney",fmsg)
	end
	print "end...................................on_ls_addmoney"

end
