-- 玩家数据消息处理

local pb = require "protobuf"

require "db/msg/net_func"
local send2game_pb = send2game_pb
local send2center_pb = send2center_pb
local send2login_pb = send2login_pb

require "db/db_opt"
local db_execute = db_execute
local db_execute_query = db_execute_query

require "timer"
local add_timer = add_timer

require "table_func"
local parse_table = parse_table

require "redis_opt"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query

local def_save_db_time = 60 -- 1分钟存次档
local def_offline_cache_time = 600 -- 离线玩家数据缓存10分钟
local LOG_MONEY_OPT_TYPE_RECHARGE_MONEY = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_RECHARGE_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY")
local LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE")


-- 存档到数据库
local function save_player(guid, info)
	local db = get_game_db()
	
	-- 基本数据
	--[[redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			info.money = info.money or 0
			info.bank = info.bank or 0
			db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
		end
	end)--]]

	info.money = info.money or 0
	info.bank = info.bank or 0
	db_execute(db, "UPDATE t_player SET $FIELD$ WHERE guid=" .. guid .. ";", info)
	-- 背包数据
	--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
		if reply:is_string() then
			local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
			for i, item in ipairs(data.pb_items) do
				data.pb_items[i] = pb.decode(item[1], item[2])
			end

			db_execute(db,  "REPLACE INTO t_bag SET guid=" .. guid .. ", $FIELD$;", data)
		end
	end)]]--
	
	print ("........................... save_player")
end

function on_SD_OnlineAccount(game_id, msg)
	local db = get_account_db()
	local sql = string.format("REPLACE INTO t_online_account SET guid=%d, first_game_type=%d, second_game_type=%d, game_id=%d, in_game=%d;", msg.guid, msg.first_game_type, msg.second_game_type, msg.gamer_id, msg.in_game)
	db:execute(sql)
end

-- 玩家退出
function on_s_logout(game_id, msg)
	-- 上次在线时间
	local db = get_account_db()
	local sql
	if msg.phone then
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d, last_login_phone = '%s', last_login_phone_type = '%s', last_login_version = '%s', last_login_channel_id = '%s', last_login_package_name = '%s', last_login_imei = '%s', last_login_ip = '%s' WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.phone, msg.phone_type, msg.version, msg.channel_id, msg.package_name, msg.imei, msg.ip, msg.guid)
	else
		sql = string.format("UPDATE t_account SET login_time = FROM_UNIXTIME(%d), logout_time = FROM_UNIXTIME(%d), online_time = online_time + %d WHERE guid = %d;",
			msg.login_time, msg.logout_time, msg.logout_time-msg.login_time, msg.guid)
	end
	db:execute(sql)

	-- 删除在线
	sql = string.format("DELETE FROM t_online_account WHERE guid=%d;", msg.guid)
	db:execute(sql)
end

function on_sd_delonline_player(game_id, msg)
	print ("on_sd_delonline_player........................... begin")
	-- body
	local db = get_account_db()
	sql = string.format("DELETE FROM t_online_account WHERE guid=%d and game_id=%d;", msg.guid, msg.game_id)
	db:execute(sql)

	print ("on_sd_delonline_player........................... end")
end

--查询提现记录
function on_sd_cash_money_type(game_id, msg)	
	local guid_ = msg.guid
	local db = get_recharge_db()
	local sql = string.format([[
		select money,created_at,status from t_cash where  guid = %d and created_at BETWEEN (curdate() - INTERVAL 6 DAY) and (curdate() - INTERVAL -1 DAY)  order by created_at desc limit 50
]], guid_)
	db_execute_query(db, true, sql, function (data)
		print("---------------------")
		print(data)
		if data and #data > 0 then
			print("-----------------1")
			for _,datainfo in ipairs(data) do
				print(datainfo)
				for i,info in pairs(datainfo) do
					print(i,info)
				end
			end
			local msg = {
			    guid = msg.guid,
				pb_cash_info = data,
			}
			print("-----------------2")
			send2game_pb(game_id,"DS_CashMoneyType",msg)
		end
		print("---------------------end")
	end)
end

--插入提现
function on_sd_cash_money(game_id, msg)	
	local guid_ = msg.guid
	local money_ = msg.money
	local coins_ = msg.coins
	local pay_money_ = msg.pay_money
	local ip_ = msg.ip
	local phone_ = msg.phone
	local phone_type_ = msg.phone_type
	local bag_id_ = msg.bag_id
	local db = get_recharge_db()
	local bef_money_ = msg.bef_money
	local bef_bank_ = msg.bef_bank
	local aft_money_ = msg.aft_money
	local aft_bank_ = msg.aft_bank
	local dbA = get_account_db()
	print ("bag_id", bag_id_)

	local sql = string.format([[
	select channel_id as bag_id_ from t_account where guid = %d;]], 
	guid_)
	db_execute_query(dbA, true, sql, function (data)
		print("---------------------")
		print(data)
		bag_id_ = data[1].bag_id_

			local sql = string.format([[
		INSERT INTO t_cash (`guid`,`money`,`coins`,`pay_money`,`ip`,`phone`,`phone_type`,`bag_id`, `before_money`, `before_bank`, `after_money`, `after_bank`)VALUES ('%d','%d','%d','%d','%s','%s','%s','%s', '%g', '%g', '%g', '%g')
]], guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_, bag_id_, bef_money_, bef_bank_, aft_money_, aft_bank_)

		db_execute_query_update(db, sql, function (ret)
			nmsg = {
			guid = guid_,
			coins = coins_,
			result = 0,
			}
			if ret > 0 then
				nmsg.result = 1
				
				sql = string.format("select max(`order_id`) as `order_id` from t_cash where `guid`=%d and `money`=%d  and `coins`=%d  and `pay_money`=%d  and `ip`='%s' and `phone`='%s' and `phone_type`='%s';",
					guid_, money_, coins_, pay_money_, ip_, phone_, phone_type_)
				db_execute_query(db, false, sql, function (data)
					if data and data.ret ~= 0 and data.order_id then
						smd5 =  string.format("order_id=%s%s",data.order_id, get_php_sign_key())
						print (smd5)
						stemp = get_to_md5(smd5)
						print (stemp)
						http_post_no_reply(get_sd_cash_money_addr(), string.format("{\"order_id\":\"%s\",\"sign\":\"%s\"}",data.order_id, stemp))
					end
				end)
			else
				log_error("on_sd_cash_money:" .. sql)
			end		
			send2game_pb(game_id,"DS_CashMoney",nmsg)
			print("---------------------end")
		end)
	end)
end
-- 查询玩家消息及公告
function  on_sd_query_player_msg(game_id, msg)
	print("on_sd_query_player_msg----------------------------------")
	-- body
	local guid_ = msg.guid
	local db = get_game_db()
	local sql = string.format([[
		select a.id as id,UNIX_TIMESTAMP(a.start_time) as start_time,UNIX_TIMESTAMP(a.end_time) as end_time,'2' as msg_type,
		if(isnull(b.is_read),1,2) as is_read,a.content as content from t_notice a 
		LEFT JOIN t_notice_read b on a.id = b.n_id and b.guid = %d where a.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and a.type = 2
		union all
		select c.id as id,UNIX_TIMESTAMP(c.start_time) as start_time,UNIX_TIMESTAMP(c.end_time) as end_time,'1' as msg_type,
		c.is_read as is_read, c.content as content from t_notice_private as c 
		where c.guid = %d and c.type = 1 and c.end_time > FROM_UNIXTIME(UNIX_TIMESTAMP())]], 
		guid_,guid_)
	db_execute_query(db, true, sql, function (data)
		print("---------------------")
		print(data)
		if data and #data > 0 then
			print("-----------------1")
			for _,datainfo in ipairs(data) do
				print(datainfo)
				for i,info in pairs(datainfo) do
					print(i,info)
				end
			end
			--local msg = {
			--	pb_msg_data_info = data,
			--}
			--print("-----------------2")
			--redis_command(string.format("HSET player_Msg_info %d %s", guid_, to_hex(pb.encode("Msg_Data", msg))))
			print("-----------------3")
			local b = true
			for _, item in ipairs(data) do
				send2game_pb(game_id,"DS_QueryPlayerMsgData",{
						guid = guid_,
						pb_msg_data = { pb_msg_data_info = {item} },
						first = b,
					})

				if b then
					b = false
				end
			end 
		else
			send2game_pb(game_id,"DS_QueryPlayerMsgData",{
				guid = guid_,
			})
		end
		print("---------------------end")
	end)
end

-- 查询玩家跑马灯
function  on_sd_query_player_marquee(game_id, msg)
	print("on_sd_query_player_marquee----------------------------------")
	-- body
	local guid_ = msg.guid
	local db = get_game_db()
	local sql = string.format([[
		select id,UNIX_TIMESTAMP(start_time) as start_time,UNIX_TIMESTAMP(end_time) as end_time,content,number,interval_time from t_notice where end_time > FROM_UNIXTIME(UNIX_TIMESTAMP()) and type = 3;]], 
		guid_,guid_)
	db_execute_query(db, true, sql, function (data)
		print("---------------------")
		print(data)
		if data and #data > 0 then
			print("-----------------1")
			for _,datainfo in ipairs(data) do
				print(datainfo)
				for i,info in pairs(datainfo) do
					print(i,info)
				end
			end
			--local msg = {
			--	pb_msg_data_info = data,
			--}
			--print("-----------------2")
			--redis_command(string.format("HSET player_Msg_info %d %s", guid_, to_hex(pb.encode("Msg_Data", msg))))
			print("-----------------3")
			local b = true
			for _, item in ipairs(data) do
				send2game_pb(game_id,"DS_QueryPlayerMarquee",{
						guid = guid_,
						pb_msg_data = { pb_msg_data_info = {item} },
						first = b,
					})

				if b then
					b = false
				end
			end 
		else
			send2game_pb(game_id,"DS_QueryPlayerMarquee",{
				guid = guid_,
			})
		end
		print("---------------------end")
	end)
end

-- 设置公告消息 查看标志
function on_sd_Set_Msg_Read_Flag( game_id, msg )
	-- body
	local guid_ = msg.guid
	local db = get_game_db()
	if msg.msg_type == 1 then
		-- 消息
		local sql = string.format("update t_notice_private set is_read = 2 where guid = %d and id = %d", 
			msg.guid, msg.id)
		db_execute_query_update(db, sql, function(ret)
			if ret > 0 then
				print("set read flag success :" ..guid_)
			else
				print("set read flag faild :" ..guid_)
			end
		end)
	elseif msg.msg_type == 2 then		
		-- 公告
		local sql = string.format("replace into t_notice_read set guid = %d ,n_id = %d,is_read = 2", 
			msg.guid, msg.id)
		db_execute_query_update(db, sql, function(ret)
			if ret > 0 then
				print("set read flag success :" ..guid_)
			else
				print("set read flag faild :" ..guid_)
			end
		end)
	else
		print(" msg type error")
	end
end

function on_sd_query_channel_invite_cfg(game_id, msg)
	local gameid = game_id
	local db = get_account_db()
	db_execute_query(db, true, string.format("SELECT * FROM t_channel_invite;"), function (data)
		if not data then
			log_error("on_sd_query_channel_invite_cfg not find guid:")
			return
		end
		local ret_msg = {}
		for k,v in pairs(data) do
			local tmp = {}
			tmp.channel_id = v.channel_id
			local channel_lock = v.channel_lock;
			local big_lock = v.big_lock
			if big_lock == 1 and channel_lock == 1 then
				tmp.is_invite_open = 1
			else
				tmp.is_invite_open = 2
			end
			tmp.tax_rate = v.tax_rate
			table.insert( ret_msg, tmp)
		end
		send2game_pb(gameid, "DS_QueryChannelInviteCfg", {cfg = ret_msg})
	end)
end
function on_sd_query_player_invite_reward(game_id, msg)
	local guid_ = msg.guid
	local gameid = game_id

	local db = get_game_db()
	db_execute_query(db, false, string.format("CALL get_player_invite_reward(%d)",guid_), function (data)
		if not data then
			log_error("on_sd_query_player_invite_reward not find guid:" .. guid_)
			return
		end
		send2game_pb(gameid, "DS_QueryPlayerInviteReward", {
			guid = guid_,
			reward = data.total_reward,
		})
	end)
end
-- 查询玩家数据
function on_sd_query_player_data(game_id, msg)
	-- 创建player
	local guid_ = msg.guid
	local account = msg.account
	local nick = msg.nickname

	local gameid = game_id
	
	-- redis
	local db = get_game_db()
	local Rdb = get_recharge_db()
	local ldb = get_log_db()
	-- 查询基本数据
	db_execute_query(db, false, string.format("CALL get_player_data(%d,'%s','%s',%d)",guid_,account,nick,300), function (data)
		if not data then
			log_error("on_sd_query_player_data not find guid:" .. guid_)
			return
		end

	log_info("bank A:"..data.bank)
	data.money = data.money or 0
	data.bank = data.bank or 0
	local sql = string.format([[select id,money,type,order_id from t_re_recharge where  guid = %d and status = 0]], guid_)
	db_execute_query(Rdb, true, sql, function (dataR)
		log_info("---------------------0")
		local num = 0
		local total =  0
		if dataR and #dataR > 0 then
			total =  #dataR
			log_info("-----------------1")
			for _,datainfo in ipairs(dataR) do
				--修改数据库
				--修改插入库		
				local sql_change = 	string.format([[update t_re_recharge set status = 1, updated_at = current_timestamp where  id = %d]], datainfo.id)
				print(sql_change)
				db_execute_query_update(Rdb, sql_change, function(ret)
					num = num + 1
					if ret > 0 then				
						--修改金钱
						local before_bank = data.bank
						log_info("bank C:"..data.bank)
						log_info ("datainfo.money:"..datainfo.money)
						data.bank = before_bank + datainfo.money
						local after_bank = data.bank
						datainfo.type = tonumber(datainfo.type)		
						local typebret = 0
						if datainfo.type == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then 
							typebret = 1
						end
						log_info(string.format("datainfo.type X: %d  %d %d %s %s",  datainfo.type , LOG_MONEY_OPT_TYPE_RECHARGE_MONEY, typebret,  type(datainfo.type), type(LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)))

						if datainfo.type == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY then
							log_info("-------------------------A")
							local sqlR = string.format([[
							update t_recharge_order set server_status = 1, before_bank = %d, after_bank = %d where  serial_order_no = %d]], before_bank, after_bank, datainfo.order_id)
							log_info("sqlR:" ..sqlR)
							Rdb:execute(sqlR)
							--消息通知
							smd5 =  string.format("type=1&sources=1&order_no=%d%s",datainfo.order_id, get_php_sign_key())
							stemp = get_to_md5(smd5)
							log_info("Php addr:" ..get_php_interface_addr())
							local sjson = string.format("{\"type\":1,\"sources\":1,\"order_no\":%d,\"sign\":\"%s\"}",datainfo.order_id, stemp)
							log_info("sjson:"..sjson)
							http_post_no_reply(get_php_interface_addr(), sjson)
						elseif datainfo.type == LOG_MONEY_OPT_TYPE_CASH_MONEY then

						elseif datainfo.type == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE then
							log_info("-------------------------B")
							local sqlR = string.format([[
							update t_cash set status_c = 1 where  order_id = %d]],  datainfo.order_id)
							log_info("sqlR:" ..sqlR)
							Rdb:execute(sqlR)
						end
						--插入金钱记录	
						local log_money_={
							guid = guid_,
							old_money = data.money,
							new_money = data.money,
							old_bank =  before_bank,
							new_bank = after_bank,
							opt_type = datainfo.type,
						}		
						db_execute(ldb, "INSERT INTO t_log_money SET $FIELD$;", log_money_)			
						log_info ("...................... on_sd_log_money")
					end
					log_info("----------num".. num, total)
					if(num ==  total) then
						log_info("bank B:"..data.bank)
						--保存发送
						save_player(guid_, data)
						send2game_pb(gameid, "DS_LoadPlayerData", {
							guid = guid_,
							info_type = 1,
							pb_base_info = data,
						})
					end
				end)
			end
		else
			--发送
			log_info("---------------------  -1")
			send2game_pb(gameid, "DS_LoadPlayerData", {
				guid = guid_,
				info_type = 1,
				pb_base_info = data,
			})
		end
		log_info("---------------------end")
		end)
	end)
	--[[
	db_execute_query(db, false, "SELECT level, money, bank, login_award_day, login_award_receive_day, online_award_time, online_award_num, relief_payment_count, header_icon FROM t_player WHERE guid=" .. guid_, function (data)
		if not data then
			-- 初始化每个用户3元
			local money_ = 300 
			local sql = string.format("REPLACE INTO t_player set guid=%d,account='%s',nickname='%s',money=%d;", guid_, account, nick, money_)
			db:execute(sql)
			
			data = {money=money_}
		end

		redis_command(string.format("HSET player_base_info %d %s", guid_, to_hex(pb.encode("PlayerBaseInfo", data))))

		send2game_pb(gameid, "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 1,
			pb_base_info = data,
		})
	end)
	]]

	-- 查询物品背包
	--[[db_execute_query(db, false, "SELECT pb_items FROM t_bag WHERE guid=" .. guid_, function (data)
		if data then
			data.pb_items = parse_table(data.pb_items)
			redis_command(string.format("HSET player_bag_info %d %s", guid_, to_hex(pb.encode("ItemBagInfo", data))))
		end

		send2game_pb(gameid, "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 2,
			pb_item_bag = data,
		})
	end)]]--
		
	-- 查询邮件
	--[[local sql = string.format("SELECT id AS mail_id, UNIX_TIMESTAMP(expiration_time) AS expiration_time, send_guid, send_name, title, content, pb_attachment FROM t_mail WHERE expiration_time>FROM_UNIXTIME(%d) AND guid=%d ORDER BY id ASC;", 
		get_second_time(), guid_)

	db_execute_query(db, true, sql, function (data)
		local mail_list = nil
		if data then
			for _, mail in ipairs(data) do
				mail.mail_id = tostring(mail.mail_id)
				mail.pb_attachment = parse_table(mail.pb_attachment)
			end
			mail_list = {pb_mails = data}
			
			redis_command(string.format("HSET player_mail_info %d %s", guid_, to_hex(pb.encode("MailListInfo", mail_list))))
		end

		send2game_pb(gameid, "DS_LoadPlayerData", {
			guid = guid_,
			info_type = 3,
			pb_mail_list = mail_list,
		})
	end)]]--
end

-- 保存玩家数据
function on_sd_save_player_data(game_id, msg)
	save_player(msg.guid, msg.pb_base_info)
end

-- 立即保存钱
function on_SD_SavePlayerMoney(game_id, msg)
	local db = get_game_db()
	
	local sql = "UPDATE t_player SET money=" .. (msg.money or 0) .. " WHERE guid=" .. msg.guid ..";"

	db:execute(sql)
end

-- 立即保存银行钱
function on_SD_SavePlayerBank(game_id, msg)
	local db = get_game_db()
	
	local sql = "UPDATE t_player SET bank=" .. (msg.bank or 0) .. " WHERE guid=" .. msg.guid ..";"

	db:execute(sql)
end

-- 请求机器人数据
function on_sd_load_android_data(game_id, msg)
	local opttype = msg.opt_type
	local roomid = msg.room_id
	local sql = string.format("SELECT guid, account, nickname FROM t_player WHERE guid>%d AND is_android=1 ORDER BY guid ASC LIMIT %d;", msg.guid, msg.count)
	local db = get_game_db()

	db_execute_query(db, true, sql, function (data)
		if data and #data > 0 then
			send2game_pb(game_id, "DS_LoadAndroidData", {
				opt_type = opttype,
				room_id = roomid,
				android_list = data,
			})
		end
	end)
end
function on_ld_AlipayEdit(login_id, msg)
	local notify = {
		guid = msg.guid,
		EditNum = 0,
		retid = msg.retid,
	}
	-- body
	print("==============================================on_ld_AlipayEdit=============================================")
	local db = get_account_db()
	local sql = ""
	sql = string.format("update t_account set alipay_name = '%s',alipay_name_y = '%s',alipay_account = '%s',alipay_account_y = '%s' where guid = %d  ",
		msg.alipay_name , msg.alipay_name_y , msg.alipay_account , msg.alipay_account_y,msg.guid  )
	print(sql)
	db_execute_query_update(db, sql, function(ret)
		print("on_ld_AlipayEdit=============================================1")
		notify.EditNum = 1
		send2login_pb(login_id, "DL_AlipayEdit",notify)
	end)
end
function  on_ld_do_sql( login_id, msg)
	-- body
	print("==============================================on_ld_do_sql============================================="..msg.database)
	local db = get_game_db()
	if msg.database == "log" then
		db = get_log_db()
	elseif msg.database == "account" then
		db = get_account_db()
	end

	local sql = msg.sql
	local notify = {
		retCode = 0,
		keyid = msg.keyid,
		retData = "",
		retid = msg.retid,
	}
	print(sql)
	db_execute_query(db, false, sql, function (data)
		if not data then
			notify.retCode = 9999
			notify.retData = "not Data"
			print("on_ld_do_sql faild :"..notify.retCode)
			send2login_pb(login_id, "DL_DO_SQL",notify)
			return
		end
		print("******************ret:"..data.retCode)
		notify.retCode = data.retCode
		notify.retData = data.retData
		send2login_pb(login_id, "DL_DO_SQL",notify)
	end)
end
function on_ld_cc_changemoney(login_id, msg)
	-- body
	print("==============================================on_ld_cc_changemoney=============================================")
	local notify = {
		guid = msg.guid,
		money = msg.money,
		keyid = msg.keyid,
		retid = msg.retid,
		retcode = 0,
		oldmoney = 0,
		newmoney = 0,
	}
	local sql = string.format("CALL change_player_bank_money(%d, %d)",msg.guid, msg.money)
	print(sql)
	local db = get_game_db()
	db_execute_query(db, false, sql, function (data)		
		if not data then
			notify.retcode = 5
			print("on_ld_cc_changemoney faild :" ..notify.retcode)
			send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
			return
		end
		if data.ret ~= 0 then
			notify.retcode = data.ret
			print(string.format("on_ld_cc_changemoney faild ,data.ret[%d] [%d]",data.ret,notify.retcode))
			send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
			return
		end
		notify.retcode = data.ret		
		print("******************ret:"..data.ret)
		if data.ret == 0 then
			notify.oldmoney = data.oldbank
			notify.newmoney = data.newbank
			print(string.format("oldmoney is [%d] newmoney [%d]",notify.oldmoney,notify.newmoney))
		end
		send2login_pb(login_id, "DL_CC_ChangeMoney",notify)
	end)
end
function on_ld_DelMessage(login_id, msg)
	-- body
	print("==============================================on_ld_DelMessage=============================================")
	local sql = ""
	local notify = {
		ret = 1,
		msg_type = msg.msg_type,
		msg_id = msg.msg_id,
		retid = msg.retid,
	}
	local sql = string.format("CALL del_msg(%d, %d)",msg.msg_id, msg.msg_type)
	local db = get_game_db()
	db_execute_query(db, false, sql, function (data)
		if not data then
			print("on_ld_DelMessage faild :" ..notify.msg_type)
			send2login_pb(login_id, "DL_DelMessage",notify)
			return
		end
		
		if data.ret ~= 0 then
			-- 删除失败
			print(string.format("on_ld_DelMessage faild : [%d] [%d]",data.ret,notify.msg_type))
			send2login_pb(login_id, "DL_DelMessage",notify)
			return
		end
		-- 执行成功
		if notify.msg_type == 1 then
			notify.guid = data.guid
		end
		print("on_ld_NewNotice success :" ..notify.msg_type)
		notify.ret = 100
		send2login_pb(login_id, "DL_DelMessage",notify)
	end)	
end

function on_ld_AgentTransfer_finish( login_id, msg)
	-- body
	print("=======================on_ld_AgentTransfer_finish===================================")
	local db = get_log_db()
	sql = string.format([[insert into t_AgentsTransfer_tj (  `agents_guid`,  `player_guid`,  `transfer_id`,  `transfer_type`,  `transfer_money`,  `transfer_status`,
  						`agents_old_bank`,  `agents_new_bank`,  `player_old_bank`,  `player_new_bank`	)
						values(%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)]],
		msg.pb_result.AgentsID,
		msg.pb_result.PlayerID,
		msg.pb_result.transfer_id,
		msg.pb_result.transfer_type,
		msg.pb_result.transfer_money,
		msg.retid,
		msg.a_oldmoney,
		msg.a_newmoney,
		msg.p_oldmoney,
		msg.p_newmoney)
	print("==========================================================")
	print(sql)
	print("==========================================================")
	db:execute(sql)
end
function on_ld_NewNotice(login_id, msg)
	-- body
	print("==============================================on_ld_NewNotice=============================================")
	local sql = ""
	local db = get_game_db()
	local notify = {
		ret = 1,
		guid = msg.guid,
		type = msg.type,
		retID = msg.retID,
		content = msg.content,
		name = msg.name,
		author = msg.author,
		number = msg.number,
		interval_time = msg.interval_time,
	}
	if msg.type == 1 then  --消息
		sql = string.format([[REPLACE INTO t_notice_private set guid=%d,type=1,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s']],
		msg.guid, msg.name, msg.content, msg.author,msg.start_time,msg.end_time)
	elseif msg.type == 2 then --公告
		sql = string.format([[REPLACE INTO t_notice set type=2,name='%s',content='%s',author='%s',
			start_time='%s',end_time = '%s']],
			msg.name, msg.content, msg.author,msg.start_time,msg.end_time)
	elseif msg.type == 3 then --跑马灯
		sql = string.format([[REPLACE INTO t_notice set type=3,number=%d,interval_time=%d,content='%s',
			start_time='%s',end_time = '%s']],msg.number,msg.interval_time,
			msg.content,msg.start_time,msg.end_time)
	else
		log_error("on_ld_NewNotice not find type:"..msg.type)
	end
	print(sql)
	db_execute_query_update(db, sql, function(ret)
		print("on_ld_NewNotice=============================================1")
		if ret > 0 then
			print("on_ld_NewNotice success :" ..notify.type)
			sql = string.format("SELECT LAST_INSERT_ID() as ID, UNIX_TIMESTAMP('%s') as start_time,UNIX_TIMESTAMP('%s') as end_time",msg.start_time,msg.end_time)
			db_execute_query(db, true, sql, function (data)
				print("on_ld_NewNotice=============================================2")
				if data then
					notify.id = data[1].ID
					notify.start_time = data[1].start_time
					notify.end_time = data[1].end_time
				end
				notify.ret = 100
				send2login_pb(login_id, "DL_NewNotice",notify)
			end)
		else
			print("on_ld_NewNotice faild :" ..msg.type)
			send2login_pb(login_id, "DL_NewNotice",notify)
		end
	end)
	print("on_ld_NewNotice=============================================3")
end

-- 保存玩家百人牛牛数据
function on_sd_save_player_Ox_data(game_id, msg)
	--print(string.format("game_id = [%d], guid[%d] is_android[%d] table_id[%d] banker_id[%d] nickname[%s] money[%d] win_money[%d] tax[%d] curtime[%d] save ox data.",
	--game_id,msg.guid,msg.is_android,msg.table_id,msg.banker_id,msg.nickname,msg.money,msg.win_money,msg.tax,msg.curtime))
	local db = get_game_db()
	local sql = string.format("REPLACE INTO t_ox_player_info set guid = %d, is_android = %d, table_id = %d, banker_id = %d, \
	nickname = '%s', money = %d, win_money = %d, bet_money = %d,tax = %d, curtime = %d;",
	msg.guid,msg.is_android,msg.table_id,msg.banker_id,msg.nickname,msg.money,msg.win_money,msg.bet_money,msg.tax,msg.curtime)
	db:execute(sql)
end

-- 请求百人牛牛基础数据
function on_sd_query_Ox_config_data(game_id, msg)
	print(string.format("on_sd_query_Ox_config_data game_id = [%d],curtime = [%d]",game_id,msg.cur_time))
	local db = get_game_db()
	local sql = string.format([[select FreeTime,BetTime,EndTime,MustWinCoeff,BankerMoneyLimit,SystemBankerSwitch,BankerCount,RobotBankerInitUid,RobotBankerInitMoney,BetRobotSwitch,BetRobotInitUid,BetRobotInitMoney,BetRobotNumControl,BetRobotTimesControl,RobotBetMoneyControl,BasicChip from t_many_ox_server_config]])
	db_execute_query(db, true, sql, function (data)
	
		-- 查询数据,返回
		if data and #data > 0 then
			--[[for _,datainfo in ipairs(data) do
				print(datainfo)
				for i,info in pairs(datainfo) do
					print(i,info)
				end
			end--]]
			local msg = {
			   	FreeTime = data[1].FreeTime,
				BetTime = data[1].BetTime,
				EndTime = data[1].EndTime,
				MustWinCoeff = data[1].MustWinCoeff,
				BankerMoneyLimit = data[1].BankerMoneyLimit,
				SystemBankerSwitch = data[1].SystemBankerSwitch,
				BankerCount = data[1].BankerCount,
				RobotBankerInitUid = data[1].RobotBankerInitUid,
				RobotBankerInitMoney = data[1].RobotBankerInitMoney,
				BetRobotSwitch = data[1].BetRobotSwitch,
				BetRobotInitUid = data[1].BetRobotInitUid,
				BetRobotInitMoney = data[1].BetRobotInitMoney,
				BetRobotNumControl = data[1].BetRobotNumControl,
				BetRobotTimesControl = data[1].BetRobotTimesControl,
				RobotBetMoneyControl = data[1].RobotBetMoneyControl,
				BasicChip = data[1].BasicChip
			}
		
			send2game_pb(game_id,"DS_OxConfigData",msg)
		end
		
	end)
	return
end