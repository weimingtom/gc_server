-- 登陆，退出，切换服务器消息处理

local pb = require "protobuf"

require "data/login_award_table"
local login_award_table = login_award_table

require "game/net_func"
local send2db_pb = send2db_pb
local send2client_pb = send2client_pb
local send2client_login = send2client_login

require "game/lobby/base_player"
local base_player = base_player

require "game/lobby/base_android"
local base_active_android = base_active_android
local base_passive_android = base_passive_android

require "game/lobby/android_manager"
local android_manager = android_manager

require "redis_opt"
local redis_command = redis_command
local redis_cmd_query = redis_cmd_query

require "timer"
local add_timer = add_timer
local def_save_db_time = 60 -- 1分钟存次档

-- enum LAND_CARD_TYPE
local ITEM_PRICE_TYPE_GOLD = pb.enum_id("ITEM_PRICE_TYPE", "ITEM_PRICE_TYPE_GOLD")
-- enum LOG_MONEY_OPT_TYPE
local LOG_MONEY_OPT_TYPE_RESET_ACCOUNT = pb.enum_id("LOG_MONEY_OPT_TYPE","LOG_MONEY_OPT_TYPE_RESET_ACCOUNT")

local LOG_MONEY_OPT_TYPE_INVITE = pb.enum_id("LOG_MONEY_OPT_TYPE", "LOG_MONEY_OPT_TYPE_INVITE")


--require "game/lobby/base_room_manager"
local room_manager = g_room_manager

local g_get_game_cfg = g_get_game_cfg

-- enum LOGIN_RESULT
local LOGIN_RESULT_SUCCESS = pb.enum_id("LOGIN_RESULT", "LOGIN_RESULT_SUCCESS")
local LOGIN_RESULT_SMS_REPEATED = pb.enum_id("LOGIN_RESULT", "LOGIN_RESULT_SMS_REPEATED")
local LOGIN_RESULT_RESET_ACCOUNT_FAILED = pb.enum_id("LOGIN_RESULT", "LOGIN_RESULT_RESET_ACCOUNT_FAILED")
local LOGIN_RESULT_SMS_FAILED = pb.enum_id("LOGIN_RESULT", "LOGIN_RESULT_SMS_FAILED")
local LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL = pb.enum_id("LOGIN_RESULT", "LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL")
local ChangMoney_NotEnoughMoney = pb.enum_id("ChangeMoneyRecode", "ChangMoney_NotEnoughMoney")

-- enum GAME_SERVER_RESULT
local GAME_SERVER_RESULT_SUCCESS = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_SUCCESS")
local GAME_SERVER_RESULT_NO_GAME_SERVER = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_NO_GAME_SERVER")
local GAME_SERVER_RESULT_MAINTAIN = pb.enum_id("GAME_SERVER_RESULT", "GAME_SERVER_RESULT_MAINTAIN")
-- enum GM_ANDROID_OPT
local GM_ANDROID_ADD_ACTIVE = pb.enum_id("GM_ANDROID_OPT", "GM_ANDROID_ADD_ACTIVE")
local GM_ANDROID_SUB_ACTIVE = pb.enum_id("GM_ANDROID_OPT", "GM_ANDROID_SUB_ACTIVE")
local GM_ANDROID_ADD_PASSIVE = pb.enum_id("GM_ANDROID_OPT", "GM_ANDROID_ADD_PASSIVE")
local GM_ANDROID_SUB_PASSIVE = pb.enum_id("GM_ANDROID_OPT", "GM_ANDROID_SUB_PASSIVE")
local GM_ANDROID_CLEAR = pb.enum_id("GM_ANDROID_OPT", "GM_ANDROID_CLEAR")

local GAME_BAND_ALIPAY_SUCCESS = pb.enum_id("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_SUCCESS")
local GAME_BAND_ALIPAY_CHECK_ERROR = pb.enum_id("GAME_BAND_ALIPAY", "GAME_BAND_ALIPAY_CHECK_ERROR")

local def_game_id = def_game_id
local def_first_game_type = def_first_game_type
local def_second_game_type = def_second_game_type
local def_game_name = def_game_name
local using_login_validatebox = using_login_validatebox

require "table_func"


-- 登陆验证框相关
local validatebox_ch = {}
for i=243,432 do
	table.insert(validatebox_ch, i)
end 
local function get_validatebox_ch()
	local ch ={}
	local count = #validatebox_ch
	for i=1,4 do
		local r = math.random(count)
		table.insert(ch, validatebox_ch[r])
		if r ~= count then
			validatebox_ch[r], validatebox_ch[count] = validatebox_ch[count], validatebox_ch[r]
		end
		count = count-1
	end
	return ch
end
function on_ls_AlipayEdit(msg)
	-- body
	local  notify = {
		guid = msg.guid,
		alipay_name = msg.alipay_name,
		alipay_name_y = msg.alipay_name_y,
		alipay_account = msg.alipay_account,
		alipay_account_y = msg.alipay_account_y,
	}
	local player = base_player:find(msg.guid)
	if player  then
		player.alipay_account = msg.alipay_account
		player.alipay_name = msg.alipay_name		
	end
	send2client_pb(player,  "SC_AlipayEdit" , notify)
end
function on_new_nitice(msg)
	-- body
	if msg then
		base_player:updateNoticeEverone(msg)
	end
end
function  on_ls_DelMessage(msg)
	-- body
	if msg then
		base_player:deleteNoticeEverone(msg)
	end
end
--function on_UpdateMsg(msg)
--	-- body
--	if msg then		
--		local player = base_player:find(msg.guid)
--		player:UpdateMsg()
--	end
--end
-- 玩家登录通知 验证账号成功后会收到
function on_ls_login_notify(msg)
	local info = msg.player_login_info
	print ("on_ls_login_notify game_id =", def_game_id)
	if info.is_reconnect then
		-- 重连

		local player = base_player:find(info.guid)
		if player then
			print("set player.online = true")
			player.online = true
			player.session_id = info.session_id
			player.gate_id = info.gate_id
			player.phone = info.phone
			player.phone_type = info.phone_type
			player.version = info.version
			player.channel_id = info.channel_id
			player.package_name = info.package_name
			player.imei = info.imei
			player.ip = info.ip
			player.risk = info.risk or 0
			player.ip_area = info.ip_area
			player.create_channel_id = info.create_channel_id
			player.enable_transfer = info.enable_transfer
			player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
			player.invite_code = info.invite_code or player.invite_code or "0"
			log_info(string.format("ip_area =%s", info.ip_area))

			send2client_login(info.session_id, info.gate_id, "LC_Login", {
				guid = info.guid,
				account = info.account,
				game_id = def_game_id,
				nickname = info.nickname,
				is_guest = info.is_guest,
				password = msg.password,
				alipay_account = info.alipay_account,
				alipay_name = info.alipay_name,
				change_alipay_num = info.change_alipay_num,
				ip_area = info.ip_area,
				enable_transfer = info.enable_transfer,
			})
			
			log_info(string.format("login step reconnect game->LC_Login,account=%s", info.account))

			-- 更新在线信息
			send2db_pb("SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				})
			return
		end

	end

	local player = base_player:new()
	player:init(info.guid, info.account, info.nickname)

	player.session_id = info.session_id
	player.gate_id = info.gate_id
	player.vip = info.vip
	player.login_time = info.login_time
	player.logout_time = info.logout_time
	player.bank_password = info.has_bank_password
	player.is_guest = info.is_guest
	player.bank_login = false
	player.online_award_start_time = 0
	print("info.alipay_account~~~~AAAA:",info.alipay_account)
	player.alipay_account = info.alipay_account
	player.alipay_name = info.alipay_name
	player.change_alipay_num = info.change_alipay_num
	player.phone = info.phone
	player.phone_type = info.phone_type
	player.version = info.version
	player.channel_id = info.channel_id
	player.package_name = info.package_name
	player.imei = info.imei
	player.ip = info.ip
	player.risk = info.risk or 0
	player.ip_area = info.ip_area
	player.create_channel_id = info.create_channel_id
	player.enable_transfer = info.enable_transfer
	player.inviter_guid = info.inviter_guid or player.inviter_guid or 0
	player.invite_code = info.invite_code or player.invite_code or "0"
	log_info(string.format("ip_area =%s", info.ip_area))
	--log_error(string.format("invite_code =%s inviter_guid = %d", player.invite_code, player.inviter_guid))
	--log_error(tostring(player))

	local notify = {
		guid = info.guid,
		account = info.account,
		game_id = def_game_id,
		nickname = info.nickname,
		is_guest = info.is_guest,
		password = msg.password,
		alipay_account = info.alipay_account,
		alipay_name = info.alipay_name,
		change_alipay_num = info.change_alipay_num,
		ip_area = info.ip_area,
		enable_transfer = info.enable_transfer,
		is_first = info.is_first,
	}
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
	-- 是否需要弹出验证框
	if using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days() then
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		notify.is_validatebox = true
		notify.pb_validatebox = {
			question = ch,
			answer = player.login_validate_answer,
		}
	end
	send2client_login(info.session_id, info.gate_id, "LC_Login", notify)
	
	log_info(string.format("login step game->LC_Login,account=%s", info.account))

	-- 定时存档
	local guid = player.guid
	local function save_db_timer()
		local p = base_player:find(guid)
		if not p then
			return
		end

		if p ~= player then
			return
		end

		p:save()

		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	-- 更新在线信息
	send2db_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		})

	print ("test .................. on_les_login_notify", info.has_bank_password)
end

function on_ls_login_notify_again(msg)
	local player = base_player:find(msg.guid)
	if player then
		local notify = {
			guid = player.guid,
			account = player.account,
			game_id = def_game_id,
			nickname = player.nickname,
			is_guest = player.is_guest,
			password = msg.password,
			alipay_account = player.alipay_account,
			alipay_name = player.alipay_name,
			change_alipay_num = player.change_alipay_num,
		}
		math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		-- 是否需要弹出验证框
		if using_login_validatebox and player.is_guest and player.login_time ~= 0 and to_days(player.login_time) ~= cur_to_days() then
			local ch = get_validatebox_ch()
			local r1 = math.random(4)
			local r2 = math.random(4)
			if r1 == r2 then
				r2 = r2%4+1
			end
			player.login_validate_answer = {ch[r1], ch[r2]}
			notify.is_validatebox = true
			notify.pb_validatebox = {
				question = ch,
				answer = player.login_validate_answer,
			}
		end
		send2client_login(player.session_id, player.gate_id, "LC_Login", notify)

		log_info(string.format("login step again game->LC_Login,account=%s", player.account))
	else
		log_error(string.format("login step again game,guid=%d", msg.guid))
	end
	print ("test .................. on_ls_login_notify_again")
end

-- 登录验证框
function on_cs_login_validatebox(player, msg)
	if msg and msg.answer and #msg.answer == 2 and player.login_validate_answer and #player.login_validate_answer == 2  and 
		((msg.answer[1] == player.login_validate_answer[1] and msg.answer[2] == player.login_validate_answer[2]) or
		(msg.answer[1] == player.login_validate_answer[2] and msg.answer[2] == player.login_validate_answer[1])) then

		send2client_pb(player,  "SC_LoginValidatebox", {
			result = LOGIN_RESULT_SUCCESS,
			})
		return
	end

	-- 验证失败
	math.randomseed(tostring(os.time()):reverse():sub(1, 6))
		local ch = get_validatebox_ch()
		local r1 = math.random(4)
		local r2 = math.random(4)
		if r1 == r2 then
			r2 = r2%4+1
		end
		player.login_validate_answer = {ch[r1], ch[r2]}
		local notify = {
			question = ch,
			answer = player.login_validate_answer,
		}
		
		local msg = {result = LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL,pb_validatebox = notify}
		send2client_pb(player,  "SC_LoginValidatebox",msg)
	--[[send2client_pb(player,  "SC_LoginValidatebox", {
		result = LOGIN_RESULT_LOGIN_VALIDATEBOX_FAIL,
		})--]]
		
end

-- 玩家退出 
function logout(guid_, bfishing)
	print("===========logout")
	local player = base_player:find(guid_)
	if not player then
		log_warning(string.format("guid[%d] not find in game= %d", guid_, def_game_id))
		return
	end

	if(bfishing ~= true) and (def_game_name == "fishing") then
		return
	end

	redis_command(string.format("HDEL player_login_info %s", player.account))
	redis_command(string.format("HDEL player_login_info_guid %d", guid_))

	if player.pb_base_info then
		if room_manager:exit_server(player) then
			return true -- 掉线处理
		end

		player.logout_time = get_second_time()
	
		local old_online_award_time = player.pb_base_info.online_award_time
		player.pb_base_info.online_award_time = player.pb_base_info.online_award_time + player.logout_time - player.online_award_start_time

		if old_online_award_time ~= player.pb_base_info.online_award_time then
			--player.flag_base_info = true
		end
		
		print("set player.online = false")
		player.online = false

		--player:save2redis()
		player:save()

	end
	
	--- 把下面这段提出来，有还没有请求base_info客户端就退出，导致现在玩家数据没有清理
		-- 给db退出消息
		send2db_pb("S_Logout", {
			account = player.account,
			guid = guid_,
			login_time = player.login_time,
			logout_time = player.logout_time,
			phone = player.phone,
			phone_type = player.phone_type,
			version = player.version,
			channel_id = player.channel_id,
			package_name = player.package_name,
			imei = player.imei,
			ip = player.ip,
		})
	--- end

	redis_command(string.format("HDEL player_online_gameid %d", player.guid))
	redis_command(string.format("HDEL player_session_gate %d@%d", player.session_id, player.gate_id))
	
	-- 删除玩家
	player:del()

	return false
end

--login发送过来
function on_s_logout(msg)
	print ("test .................. on_s_logout")
	logout(msg.guid)

	if msg.user_data > 0 then
		send2login_pb("L_KickClient", {
			reply_account = player.account,
			user_data = msg.user_data,
		})
	end
end

-- 跨天了
local function next_day(player)
	local next_login_award_day = player.pb_base_info.login_award_day + 1
	if login_award_table[next_login_award_day] then
		player.pb_base_info.login_award_day = next_login_award_day
	end
	
	player.pb_base_info.online_award_time = 0
	player.pb_base_info.online_award_num = 0
	player.pb_base_info.relief_payment_count = 0

	player.flag_base_info = true

	player.online_award_start_time = get_second_time()
end

-- 加载玩家数据
local function load_player_data_complete(player)
	if to_days(player.logout_time) ~= cur_to_days() then
		next_day(player)
	end

	player.login_time = get_second_time()
	player.online_award_start_time = player.login_time
	
	if player.is_offline then
		print("-------------------------1")
	end
	if room_manager:isPlay(player) then
		print("-------------------------2")
	end
	if player.is_offline and room_manager:isPlay(player) then
		print("=====================================send SC_ReplyPlayerInfoComplete")
		local notify = {
			pb_gmMessage = {
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				room_id = player.room_id,
				table_id = player.table_id,
				chair_id = player.chair_id,
			}
		}
		send2client_pb(player,  "SC_ReplyPlayerInfoComplete", notify)
		room_manager:player_online(player)
		return
	end
	
	send2client_pb(player,  "SC_ReplyPlayerInfoComplete", nil)

	--邀请码的奖励
	send2db_pb("SD_QueryPlayerInviteReward", {
				guid = player.guid,
			})
end

local channel_cfg = {}
function channel_invite_cfg(channel_id)
	if channel_cfg then
		for k,v in pairs(channel_cfg) do
			if v.channel_id == channel_id then
				return v
			end
		end
	end
	return nil
end
function on_ds_load_channel_invite_cfg(msg)
	channel_cfg = msg.cfg or {}	
	--[[for k,v in pairs(channel_cfg) do
		for k1,v1 in pairs(v) do
			log_error(tostring(k1))
			log_error(tostring(v1))
		end
		end
	]]
end
function on_ds_load_player_invite_reward(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("on_ds_load_player_invite_reward guid[%d] not find in game", msg.guid))
		return
	end
	if msg.reward and msg.reward > 0 then player:change_money(msg.reward,LOG_MONEY_OPT_TYPE_INVITE) end
end

-- 检查是否从Redis中加载完成
local function check_load_complete(player)
	--if player.flag_load_base_info and player.flag_load_item_bag and player.flag_load_mail_list then
	--	player.flag_load_base_info = nil
	--	player.flag_load_item_bag = nil
	--	player.flag_load_mail_list = nil
		
		load_player_data_complete(player)
		
		player.flag__request_player_info = nil
	--end
end

-- 请求玩家信息
function on_cs_request_player_info(player, msg)
	local guid = player.guid
	if player.flag__request_player_info then
		log_warning(string.format("guid[%d] request_player_info repeated", guid))
		return
	end
	player.flag__request_player_info = true

	--[[redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local player = base_player:find(guid)
			if not player then
				log_warning(string.format("guid[%d] not find in game", guid))
				return
			end
			-- 基本数据
			player.pb_base_info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_base_info = player.pb_base_info,
			})

			--player.flag_load_base_info = true
			check_load_complete(player)
			
			-- 背包数据
			--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
				local player = base_player:find(guid)
				if not player then
					log_warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_items) do
						data.pb_items[i] = pb.decode(item[1], item[2])
					end

					player.pb_item_bag = data

					send2client_pb(player, "SC_ReplyPlayerInfo", {
						pb_item_bag = data,
					})
				end

				player.flag_load_item_bag = true -- flag
				check_load_complete(player)
			end)]]

			-- 邮件数据
			--[[redis_cmd_query(string.format("HGET player_mail_info %d", guid), function (reply)
				local player = base_player:find(guid)
				if not player then
					log_warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("MailListInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_mails) do
						data.pb_mails[i] = pb.decode(item[1], item[2])
						for j, item in ipairs(data.mails[i].pb_attachment) do
							data.mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
						end
					end

					player.pb_mail_list = data

					send2client_pb(player, "SC_ReplyPlayerInfo", {
						pb_mail_list = data,
					})
				end
				
				player.flag_load_mail_list = true -- flag
				check_load_complete(player)
			end)]]

			---- 公告及消息
			--redis_cmd_query(string.format("HGET player_Msg_info %d",guid),function (reply)
			--	-- body
			--	local player = base_player:find(guid)
			--	if not player then
			--		log_warning(string.format("guid[%d] not find in game", guid))
			--		return
			--	end
			--	if reply:is_string() then
			--		local data = pb.decode("Msg_Data", from_hex(reply:get_string()))
			--		player.msg_data_info = data.pb_msg_data_info
			--		send2client_pb(player,"SC_QueryPlayerMsgData",{
			--			pb_msg_data = data.pb_msg_data_info
			--		})
			--	end
			--end)
		--[[else
			send2db_pb("SD_QueryPlayerData", {
				guid = player.guid,
				account = player.account,
				nickname = player.nickname,
			})
		end
		send2db_pb("SD_QueryPlayerMsgData", {
			guid = player.guid,
		})
		send2db_pb("SD_QueryPlayerMarquee", {
			guid = player.guid,
		})
	end)--]]

		send2db_pb("SD_QueryPlayerData", {
			guid = player.guid,
			account = player.account,
			nickname = player.nickname,
		})
		send2db_pb("SD_QueryPlayerMsgData", {
			guid = player.guid,
		})
		send2db_pb("SD_QueryPlayerMarquee", {
			guid = player.guid,
		})
	print ("test .................. on_ce_request_player_info")
end


-- 加载玩家数据
function on_ds_load_player_data(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	if msg.info_type == 1 then
		if #msg.pb_base_info > 0 then
			local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])

			data.money = data.money or 0
			data.bank = data.bank or 0
			data.slotma_addition = data.slotma_addition or 0

			player.pb_base_info = data
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_base_info = data,
			})
		else
			player.pb_base_info = {}
		end

		--player.flag_load_base_info = true -- flag
		check_load_complete(player)
	--[[elseif msg.info_type == 2 then
		if #msg.pb_item_bag > 0 then
			local data = pb.decode(msg.item_bag[1], msg.item_bag[2])
			for i, item in ipairs(data.items) do
				data.items[i] = pb.decode(item[1], item[2])
			end
			
			player.pb_item_bag = data
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_item_bag = data,
			})
		end

		player.flag_load_item_bag = true -- flag
		check_load_complete(player)
	elseif msg.info_type == 3 then
		if #msg.pb_mail_list > 0 then
			local data = pb.decode(msg.pb_mail_list[1], msg.pb_mail_list[2])
			for i, item in ipairs(data.pb_mails) do
				data.pb_mails[i] = pb.decode(item[1], item[2])
				for j, item in ipairs(data.pb_mails[i].pb_attachment) do
					data.pb_mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
				end
			end
			
			player.pb_mail_list = player.pb_mail_list or {}
			for i, v in ipairs(data.pb_mails) do
				player.pb_mail_list[v.mail_id] = v
			end
			
			send2client_pb(player, "SC_ReplyPlayerInfo", {
				pb_mail_list = data,
			})
		end

		player.flag_load_mail_list = true -- flag
		check_load_complete(player)]]--
	end
	
	print ("test .................. on_ds_load_player_data")
end

-- 切换游戏服务器
function on_cs_change_game(player, msg)
	if player.disable == 1 then		
		-- 踢用户下线 封停所有功能
		print("on_cs_change_game =======================disable == 1")
		if not room_manager:isPlay(player) then
			print("on_cs_change_game.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
		return
	end
	if  game_switch == 1 then --游戏进入维护阶段
		if player.vip ~= 100 then	
			send2client_pb(player, "SC_GameMaintain", {
					result = GAME_SERVER_RESULT_MAINTAIN,
					})
			player:forced_exit()
			log_warning(string.format("GameServer will maintain,exit"))	
			return
		end	
	
	end
	if msg.first_game_type == def_first_game_type and msg.second_game_type == def_second_game_type then
		-- 已经在这个服务器中了
		--[[send2client_pb(player,  "SC_EnterRoomAndSitDown", {
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			result = GAME_SERVER_RESULT_SUCCESS,
		})]]

		local result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
		if result_ == GAME_SERVER_RESULT_SUCCESS then
			local notify = {
				room_id = room_id_,
				table_id = table_id_,
				chair_id = chair_id_,
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
			}
			tb:foreach_except(chair_id_, function (p)
				local v = {
					chair_id = p.chair_id,
					guid = p.guid,
					account = p.account,
					nickname = p.nickname,
					level = p:get_level(),
					money = p:get_money(),
					header_icon = p:get_header_icon(),
					ip_area = p.ip_area,
				}
				notify.pb_visual_info = notify.pb_visual_info or {}
				table.insert(notify.pb_visual_info, v)
			end)
			
			send2client_pb(player, "SC_EnterRoomAndSitDown", notify)
			player.noready = nil 
			tb:send_playerinfo(player)
			-- 更新在线信息
			send2db_pb("SD_OnlineAccount", {
				guid = player.guid,
				first_game_type = def_first_game_type,
				second_game_type = def_second_game_type,
				gamer_id = def_game_id,
				in_game = 1,
				})

			log_info(string.format("change step this ok,account=%s", player.account))
		else
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				})

			log_info(string.format("change step this err,account=%s,result [%s]", player.account,result_))
		end
	else
		--room_manager:exit_server(player)
		--player:save2redis()
		
		send2login_pb("SS_ChangeGame", {
			guid = player.guid,
			session_id = player.session_id,
			gate_id = player.gate_id,
			account = player.account,
			nickname = player.nickname,
			vip = player.vip,
			login_time = player.login_time,
			logout_time = player.logout_time,
			bank_password = player.bank_password,
			bank_login = player.bank_login,
			is_guest = player.is_guest,
			online_award_start_time = player.online_award_start_time,
			game_id = def_game_id,
			first_game_type = msg.first_game_type,
			second_game_type = msg.second_game_type,
			phone = player.phone,
			phone_type = player.phone_type,
			version = player.version,
			channel_id = player.channel_id,
			package_name = player.package_name,
			imei = player.imei,
			ip = player.ip,
			ip_area = player.ip_area,
			risk = player.risk,
			create_channel_id = player.create_channel_id,
			enable_transfer = player.enable_transfer,
			inviter_guid = player.inviter_guid,
			invite_code = player.invite_code,
			pb_base_info = player.pb_base_info,
		})
		--send2db_pb("SD_Delonline_player", {
		--guid = player.guid,
		--game_id = def_game_id,
		--})
		
		--player:del()

		log_info(string.format("change step ask login,account=%s", player.account))
	end
end

function on_LS_ChangeGameResult(msg)
	if msg.success then
		local player = base_player:find(msg.guid)
		if not player then
			log_warning(string.format("==guid[%d] not find in game=%d", msg.guid, def_game_id))
			return
		end

		room_manager:exit_server(player)
		player:save()
		--player:save2redis()

		send2db_pb("SD_Delonline_player", {
		guid = player.guid,
		game_id = def_game_id,
		})
		
		player:del()
		
		send2login_pb("SL_ChangeGameResult", msg)
		
		log_info(string.format("change step complete,account=%s", player.account))
	end

	print ("on_LS_ChangeGameResult................................", msg.success)
end

-- 检查是否从Redis中加载完成
local function check_change_complete(player, msg)
	--if player.flag_load_base_info and player.flag_load_item_bag and player.flag_load_mail_list then
	--	player.flag_load_base_info = nil
	--	player.flag_load_item_bag = nil
	--	player.flag_load_mail_list = nil
		
		local result_, room_id_, table_id_, chair_id_, tb = room_manager:enter_room_and_sit_down(player)
		if result_ == GAME_SERVER_RESULT_SUCCESS then
			local notify = {
				room_id = room_id_,
				table_id = table_id_,
				chair_id = chair_id_,
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
			}
			tb:foreach_except(chair_id_, function (p)
				local v = {
					chair_id = p.chair_id,
					guid = p.guid,
					account = p.account,
					nickname = p.nickname,
					level = p:get_level(),
					money = p:get_money(),
					header_icon = p:get_header_icon(),
					ip_area = p.ip_area,
				}
				notify.pb_visual_info = notify.pb_visual_info or {}
				table.insert(notify.pb_visual_info, v)
			end)
			
			send2client_pb(player, "SC_EnterRoomAndSitDown", notify)


			log_info(string.format("change step other ok,account=%s", player.account))
		else
			send2client_pb(player, "SC_EnterRoomAndSitDown", {
				result = result_,
				game_id = def_game_id,
				first_game_type = msg.first_game_type,
				second_game_type = msg.second_game_type,
				ip_area = player.ip_area,
				})

			log_info(string.format("change step other ok,account=%s", player.account))
		end
	--end
end

function on_ss_change_game(msg)
	local player = base_player:find(msg.guid)
	if player then
		room_manager:exit_server(player)
		player:del()
		log_warning(string.format("guid[%d] find in game=%d", msg.guid, def_game_id))		
	end
	
	local player = base_player:new()
	player:init(msg.guid, msg.account, msg.nickname)
	
	player.session_id = msg.session_id
	player.gate_id = msg.gate_id
	player.vip = msg.vip
	player.login_time = msg.login_time
	player.logout_time = msg.logout_time
	player.bank_password = msg.bank_password ~= 0
	player.bank_login = msg.bank_login ~= 0
	player.is_guest = msg.is_guest
	player.online_award_start_time = msg.online_award_start_time

	player.phone = msg.phone
	player.phone_type = msg.phone_type
	player.version = msg.version
	player.channel_id = msg.channel_id
	player.package_name = msg.package_name
	player.imei = msg.imei
	player.ip = msg.ip
	player.ip_area = msg.ip_area
	player.risk = msg.risk
	player.create_channel_id = msg.create_channel_id
	player.enable_transfer = msg.enable_transfer
	player.inviter_guid = msg.inviter_guid
	player.invite_code = msg.invite_code
	
	player.flag_load_base_info = nil
	player.flag_load_item_bag = nil
	player.flag_load_mail_list = nil

	-- 更新在线信息
	send2db_pb("SD_OnlineAccount", {
		guid = player.guid,
		first_game_type = def_first_game_type,
		second_game_type = def_second_game_type,
		gamer_id = def_game_id,
		in_game = 1,
		})

	redis_command(string.format("HSET player_online_gameid %d %d", player.guid, def_game_id))

	if #msg.pb_base_info > 0 then
		local data = pb.decode(msg.pb_base_info[1], msg.pb_base_info[2])

		data.money = data.money or 0
		data.bank = data.bank or 0
		player.pb_base_info = data
		
		check_change_complete(player, msg)
	end

	-- 定时存档
	local guid = player.guid
	local function save_db_timer()
		local p = base_player:find(guid)
		if not p then
			return
		end

		if p ~= player then
			return
		end

		p:save()

		add_timer(def_save_db_time, save_db_timer)
	end
	save_db_timer()

	log_info(string.format("change step login notify,account=%s", player.account))

	--[[local guid = player.guid
	redis_cmd_query(string.format("HGET player_base_info %d", guid), function (reply)
		if reply:is_string() then
			local player = base_player:find(guid)
			if not player then
				log_warning(string.format("guid[%d] not find in game", guid))
				return
			end]]--

			-- 基本数据
	---		player.pb_base_info = pb.decode("PlayerBaseInfo", from_hex(reply:get_string()))
			
			--player.flag_load_base_info = true
	---		check_change_complete(player, msg)
			
			-- 背包数据
			--[[redis_cmd_query(string.format("HGET player_bag_info %d", guid), function (reply)
				local player = base_player:find(guid)
				if not player then
					log_warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("ItemBagInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_items) do
						data.pb_items[i] = pb.decode(item[1], item[2])
					end

					player.pb_item_bag = data
				end

				player.flag_load_item_bag = true -- flag
				check_change_complete(player, msg)
			end)]]--

			-- 邮件数据
			--[[redis_cmd_query(string.format("HGET player_mail_info %d", guid), function (reply)
				local player = base_player:find(guid)
				if not player then
					log_warning(string.format("guid[%d] not find in game", guid))
					return
				end

				if reply:is_string() then
					local data = pb.decode("MailListInfo", from_hex(reply:get_string()))
					for i, item in ipairs(data.pb_mails) do
						data.pb_mails[i] = pb.decode(item[1], item[2])
						for j, item in ipairs(data.mails[i].pb_attachment) do
							data.mails[i].pb_attachment[j] = pb.decode(item[1], item[2])
						end
					end

					player.pb_mail_list = data
				end
				
				player.flag_load_mail_list = true -- flag
				check_change_complete(player, msg)
			end)]]--
	---	end
	---end)

	--[[send2db_pb("SD_QueryPlayerData", {
		guid = player.guid,
		account = player.account,
		nickname = player.nickname,
	})
	
	send2client_pb(player,  "SC_EnterRoomAndSitDown", {
		game_id = def_game_id,
		first_game_type = msg.first_game_type,
		second_game_type = msg.second_game_type,
		result = GAME_SERVER_RESULT_SUCCESS,
	})]]
end

-- 完善账号
function on_cs_reset_account(player, msg)
	if (not player.is_guest) and (not player.flag_wait_reset_account) then
		send2client_pb(player,  "SC_ResetAccount", {
			result = LOGIN_RESULT_RESET_ACCOUNT_FAILED,
			account = msg.account,
			nickname = msg.nickname,
		})

		log_warning(string.format("reset account error isguest[%d], %d", (player.is_guest and 1 or 0), (player.flag_wait_reset_account and 1 or 0)))
		return
	end

	player.flag_wait_reset_account = true

	send2db_pb("SD_ResetAccount", {
		guid = player.guid,
		account = msg.account,
		password = msg.password,
		nickname = msg.nickname,
	})

	print "on_cs_reset_account ..........................."
end

function on_ds_reset_account(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		player.is_guest = false
		player:add_money({{money_type = ITEM_PRICE_TYPE_GOLD, money = 300}}, LOG_MONEY_OPT_TYPE_RESET_ACCOUNT)

		-- redis数据修改
		redis_cmd_query(string.format("HGET player_login_info %s", player.account), function (reply)
			if reply:is_string() then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply:get_string()))
				info.account = msg.account
				info.nickname = msg.nickname
				redis_command(string.format("HDEL player_login_info %s", player.account))
				redis_command(string.format("HDEL player_login_info_guid %d", player.guid))
				redis_command(string.format("HSET player_login_info %d %s", player.account, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player_login_info_guid %d %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)

		-- 修改lua数据
		player:reset_account(msg.account, msg.nickname)
	--else
	--	log_warning(string.format("guid[%d] reset account sql error", msg.guid))
	end
	player.flag_wait_reset_account = nil

	send2client_pb(player,  "SC_ResetAccount", {
		result = msg.ret,
		account = msg.account,
		nickname = msg.nickname,
	})

	print "on_ds_reset_account ..........................."
end

-- 绑定支付宝
function on_cs_bandalipay(player, msg)
	print ("on_cs_bandalipay ........................... start:", player.change_alipay_num, alipay_account, alipay_name, player.is_guest)
	print (player.change_alipay_num > 0, player.alipay_account == "", player.alipay_name == "", player.is_guest == false)
	if player.change_alipay_num > 0 and (player.alipay_account == "" and player.alipay_name == "")  and player.is_guest == false then		
		print "on_cs_bandalipay ........................... to db"
		send2db_pb("SD_BandAlipay", {
			guid = player.guid,
			alipay_account = msg.alipay_account,
			alipay_name = msg.alipay_name,
		})
	else
		print "on_cs_bandalipay ........................... false"
		send2client_pb(player, "SC_BandAlipay", {
			result = GAME_BAND_ALIPAY_CHECK_ERROR,
			alipay_account = "",
			alipay_name = "",
			})
	end
end

function on_ds_bandalipay(msg)	
	print ("on_ds_bandalipay ........................... ", msg.result )
	local player = base_player:find(msg.guid)
	if player then		
		if msg.result == GAME_BAND_ALIPAY_SUCCESS then
     		player.alipay_account = msg.alipay_account
     		player.alipay_name = msg.alipay_name
			send2client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = msg.alipay_account,
				alipay_name = msg.alipay_name,
				})
		else
			send2client_pb(player, "SC_BandAlipay", {
				result = msg.result,
				alipay_account = "",
				alipay_name = "",
				})
		end
	end
end

function on_ds_bandalipaynum(msg)	
	print "on_ds_bandalipaynum ........................... "
	local player = base_player:find(msg.guid)
	if player then	
		player.change_alipay_num = msg.band_num
	end
end

-- 修改密码
function on_cs_set_password(player, msg)
	if player.is_guest then
		send2client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})

		log_warning("set password error");
	end

	send2db_pb("SD_SetPassword", {
		guid = player.guid,
		old_password = msg.old_password,
		password = msg.password,
	})
end

function on_ds_set_password(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	send2client_pb(player, "SC_SetPassword", {
		result = msg.ret,
	})
end

function on_cs_set_password_by_sms(player, msg)
	if player.is_guest then
		send2client_pb(player,  "SC_SetPassword", {
			result = LOGIN_RESULT_SET_PASSWORD_GUEST,
		})

		log_warning("set password error");
	end

	send2db_pb("SD_SetPasswordBySms", {
		guid = player.guid,
		password = msg.password,
	})
end

-- 设置昵称
function on_cs_set_nickname(player, msg)
	send2db_pb("SD_SetNickname", {
		guid = player.guid,
		nickname = msg.nickname,
	})
end

function on_ds_set_nickname(msg)
	local player = base_player:find(msg.guid)
	if not player then
		log_warning(string.format("guid[%d] not find in game", msg.guid))
		return
	end

	if msg.ret == LOGIN_RESULT_SUCCESS then
		-- redis数据修改
		redis_cmd_query(string.format("HGET player_login_info %s", player.account), function (reply)
			if reply:is_string() then
				local info = pb.decode("PlayerLoginInfo", from_hex(reply:get_string()))
				info.nickname = msg.nickname
				redis_command(string.format("HSET player_login_info %d %s", player.account, to_hex(pb.encode("PlayerLoginInfo", info))))
				redis_command(string.format("HSET player_login_info_guid %d %s", player.guid, to_hex(pb.encode("PlayerLoginInfo", info))))
			end
		end)

		player.nickname = msg.nickname
	end

	send2client_pb(player,  "SC_SetNickname", {
		nickname = msg.nickname,
		result = msg.ret,
	})
end

-- 修改头像
function on_cs_change_header_icon(player, msg)
	local header_icon = player.pb_base_info.header_icon or 0
	if msg.header_icon ~= header_icon then
		player.pb_base_info.header_icon = msg.header_icon
		player.flag_base_info = true
	end

	send2client_pb(player,  "SC_ChangeHeaderIcon", {
		header_icon = msg.header_icon,
	})
end

-- 添加机器人
local function add_android(opt_type, room_id, android_list)
	if opt_type == GM_ANDROID_ADD_ACTIVE then
		for _, v in ipairs(android_list) do
			local a = base_active_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	elseif opt_type == GM_ANDROID_ADD_PASSIVE then
		for _, v in ipairs(android_list) do
			local a = base_passive_android:new()
			a:init(room_id, v.guid, v.account, v.nickname)
		end
	end
end

-- gm命令操作回调
function on_gm_android_opt(opt_type_, roomid_, num_)
	print "on_gm_android_opt .........................."

	if not room_manager:find_room(roomid_) then
		log_error("on_gm_android_opt room not find")
		return
	end

	if opt_type_ == GM_ANDROID_ADD_ACTIVE or opt_type_ == GM_ANDROID_ADD_PASSIVE then
		local a = android_manager:create_android(def_game_id, num_)
		local n = #a
		if n > 0 then
			add_android(opt_type_, roomid_, a)
		end

		if n ~= num_ then
			send2db_pb("SD_LoadAndroidData", {
				opt_type = opt_type_,
				room_id = roomid_,
				guid = android_manager:get_max_guid(),
				count = num_ - n,
				})
		end
	elseif opt_type_ == GM_ANDROID_SUB_ACTIVE then
		base_active_android:sub_android(roomid_, num_)
	elseif opt_type_ == GM_ANDROID_SUB_PASSIVE then
		base_passive_android:sub_android(roomid_, num_)
	end
end

-- 返回机器人数据
function on_ds_load_android_data(msg)
	print "on_ds_load_android_data .........................."

	if not msg then
		log_error("on_ds_load_android_data error")
		return
	end

	android_manager:load_from_db(msg.android_list)

	local a = android_manager:create_android(def_game_id, #msg.android_list)

	if #a <= 0 then
		return
	end
	
	add_android(msg.opt_type, msg.room_id, a)
end

function  on_ds_QueryPlayerMsgData(msg)
	-- body
	print ("on_ds_QueryPlayerMsgData .........................."..msg.guid)

	--for _,datainfo in ipairs(msg.pb_msg_data.pb_msg_data_info) do
	--	print(datainfo)
	--	for i,info in pairs(datainfo) do
	--		print(i,info)
	--	end
	--end
	--local notify = {
	--	id = 21,
	--	is_read = 1,
	--	msg_type = 1,
	--	content = "********************",
	--	start_time = 8888888,
	--	end_time = 999999,
	--}
	--table.insert(msg.pb_msg_data.pb_msg_data_info,notify)
	--print("-----------------------------------------------------------------------")
	--print("=======================================================================")
	--for _,datainfo in ipairs(msg.pb_msg_data.pb_msg_data_info) do
	--	print(datainfo)
	--	for i,info in pairs(datainfo) do
	--		print(i,info)
	--	end
	--end
	local player = base_player:find(msg.guid)
	if player then
		if msg.pb_msg_data then
			--player.msg_data_info = msg.pb_msg_data.pb_msg_data_info
			if msg.first then
				send2client_pb(player,"SC_QueryPlayerMsgData",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			else
				send2client_pb(player,"SC_NewMsgData",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			end
		else
			send2client_pb(player,"SC_QueryPlayerMsgData")
		end
	else
		print("on_ds_QueryPlayerMsgData not find player , guid : " ..msg.guid)
	end
end

function on_cs_QueryPlayerMsgData( player, msg )
	-- body
	print ("on_ds_QueryPlayerMsgData .........................."..player.guid)
	send2db_pb("SD_QueryPlayerMsgData", {
		guid = player.guid,
	})
end

function on_ds_QueryPlayerMarquee(msg)
	-- body
	print ("on_ds_QueryPlayerMarquee .........................."..msg.guid)

	local player = base_player:find(msg.guid)
	if player then
		if msg.pb_msg_data then
			--player.msg_data_info = msg.pb_msg_data.pb_msg_data_info
			if msg.first then
				send2client_pb(player,"SC_QueryPlayerMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			else
				send2client_pb(player,"SC_NewMarquee",{
					pb_msg_data = msg.pb_msg_data.pb_msg_data_info
				})
			end
		else
			send2client_pb(player,"SC_QueryPlayerMarquee")
		end
	else
		print("on_ds_QueryPlayerMarquee not find player , guid : " ..msg.guid)
	end
end

function on_cs_QueryPlayerMarquee( player, msg )
	print ("on_cs_QueryPlayerMarquee .........................."..player.guid)
	send2db_pb("SD_QueryPlayerMarquee", {
		guid = player.guid,
	})
end

function on_cs_SetMsgReadFlag( player, msg )
	-- body
	print ("on_cs_SetMsgReadFlag .........................."..player.guid)
	send2db_pb("SD_SetMsgReadFlag", {
		guid = player.guid,
		id = msg.id,
		msg_type = msg.msg_type,
	})
end

function  on_ds_LoadOxConfigData(msg)
	--print("on_ds_LoadOxConfigData...................................test ")
	--ox_table:reload_many_ox_DB_config(msg)
end

-- 修改税率
function on_ls_set_tax(msg)
	print("on_ls_SetTax...................................on_ls_set_tax")
	print(msg.tax, msg.is_show, msg.is_enable)
	room_manager:change_tax(msg.tax, msg.is_show, msg.is_enable)
	local nmsg = {
	webid = msg.webid,
	result = 1,
	}
	send2login_pb("SL_ChangeTax",nmsg)
end
function on_ls_FreezeAccount( msg )
	print("on_ls_FreezeAccount...................................start")
	-- body
	local player = base_player:find(msg.guid)
	local notify = {
		guid = msg.guid,
		status = msg.status,
		retid = msg.retid,
		ret = 0,
	}
	if not player then
		notify.ret = 1
		print(" not find player :",notify.ret)
		send2loginid_pb(msg.login_id,"SL_FreezeAccount",notify)
		return
	end	
	local notifyT = {
		guid = msg.guid,
		status = msg.status,
	}
	-- 通知客户端
	send2client_pb(player,  "SC_FreezeAccount", notifyT)
	-- 修改玩家数据
	player.disable = msg.status;
	if player.disable == 1 then
		-- 踢用户下线 封停所有功能
		print("=======================disable == 1")
		if not room_manager:isPlay(player) then
			print("on_ls_FreezeAccount.....................player not in play forced_exit")
			-- 强行T下线
			player:forced_exit();
		end
	end
	send2loginid_pb(msg.login_id,"SL_FreezeAccount",notify)
end
--修改玩家 bank 金币 retcode 0 成功 1 玩家未找到 2 扣减时玩家金币不够
function on_ls_cc_changemoney(msg)
	print("on_ls_cc_changemoney...................................start")
	-- body
	local player = base_player:find(msg.guid)	
	local notify = {
		guid = msg.guid,
		money = msg.money,
		keyid = msg.keyid,
		retid = msg.retid,
		oldmoney = 0,
		newmoney = 0,
		retcode = ChangMoney_NotEnoughMoney,
	}
	if player and  player.pb_base_info then		
		notify.retcode,notify.oldmoney,notify.newmoney = player:changeBankMoney(msg.money)
	end
	send2loginid_pb(msg.login_id,"SL_AgentsTransfer_ChangeMoney",notify)
	print("on_ls_cc_changemoney...................................end:"..notify.retcode)
end

--修改游戏cfg
function on_fs_chang_config(msg)
	print("on_ds_chang_config...................................on_ds_chang_config")

	local nmsg = {
	webid = msg.webid,
	result = 1,
	pb_cfg = {
		game_id = def_game_id,
		second_game_type = def_second_game_type,
		first_game_type = def_first_game_type,
		game_name = def_game_name,
		table_count = 0,
		money_limit = 0,
		cell_money = 0,
		tax = 0,
		},	
	}
	local tb_l
	if msg.room_list ~= "" then	
		local tb = load_json_buffer(msg.room_list )
		g_room_manager:gm_update_cfg(tb, msg.room_lua_cfg)
		tb_l = tb
	else			
		log_error("on_ds_chang_config error")
		nmsg.result = 0
	end

	local table_count_l = 0
	local money_limit_l = 0
	local cell_money_l = 0
	local tax_l = 0
	for i,v in ipairs(tb_l) do
		 table_count_l = v.table_count
		 money_limit_l = v.money_limit
		 cell_money_l = v.cell_money
		 tax_l = v.tax * 0.01
	end

	nmsg.pb_cfg.table_count = table_count_l
	nmsg.pb_cfg.money_limit = money_limit_l
	nmsg.pb_cfg.cell_money = cell_money_l
	nmsg.pb_cfg.tax = tax_l
	send2cfg_pb("SF_ChangeGameCfg",nmsg)
	
end

--修改游戏cfg
function on_ds_server_config(msg)
	print("on_ds_server_config...................................on_ds_server_config")
	if msg.cfg.room_list ~= "" then	
		print(msg.cfg.room_list)
		local tb = load_json_buffer(msg.cfg.room_list)
		g_room_manager:gm_update_cfg(tb, msg.cfg.room_lua_cfg)
	else			
		log_error("on_ds_server_config error")
	end
end



function on_cs_change_maintain(msg)
	print("on_cs_change_maintain...................................on_cs_change_maintain")
	--msg.maintaintype  // 维护类型(1提现维护,2游戏维护,登录开关3)
	--msg.switchopen	// 开关(1维护中,0正常))	
	print("-----------id value",msg.maintaintype,msg.switchopen)
	if msg.maintaintype == 1 then --提现
		cash_switch = msg.switchopen
	elseif msg.maintaintype == 2 then --游戏
		game_switch = msg.switchopen
		if game_switch == 1 then
			--[[room_manager:broadcast2client_by_player("SC_GameMaintain", {
			result = GAME_SERVER_RESULT_MAINTAIN,
			}) --广播游戏维护状态--]]
			room_manager:foreach_by_player(function (player) 
				if player and player.vip ~= 100 then --非系统玩家广播维护
					send2client_pb(player, "SC_GameMaintain", {
					result = 0,
					})
				end
			end)
		end

	else
		log_error("unknown msg maintaintype:",msg.maintaintype,msg.switchopen)
	end
end