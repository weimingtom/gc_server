-- 邮件消息处理

local pb = require "protobuf"

require "data/item_details_table"
require "data/item_market_table"
local item_details_table = item_details_table
local item_market_table = item_market_table

require "game/net_func"
local send2client_pb = send2client_pb
local send2db_pb = send2db_pb

require "game/lobby/base_player"
local base_player = base_player

-- enum MAIL_OPT_RESULT
local MAIL_OPT_RESULT_SUCCESS = pb.enum_id("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_SUCCESS")
local MAIL_OPT_RESULT_FIND_FAILED = pb.enum_id("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_FIND_FAILED")
local MAIL_OPT_RESULT_EXPIRATION = pb.enum_id("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_EXPIRATION")
local MAIL_OPT_RESULT_NO_ATTACHMENT = pb.enum_id("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_NO_ATTACHMENT")
local MAIL_OPT_RESULT_HAS_ATTACHMENT = pb.enum_id("MAIL_OPT_RESULT", "MAIL_OPT_RESULT_HAS_ATTACHMENT")


-- 发送邮件
function on_cs_send_mail(player, msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	mail_.send_guid = player.guid
	mail_.send_name = player.account
	
	send2db_pb("SD_SendMail", {
		pb_mail = mail_,
	})
	
	print ("...................... on_cs_send_mail")
end

function on_des_send_mail(msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	local player = base_player:find(mail_.send_guid)
	if player then
		send2client_pb(player, "SC_SendMail", {
			ret = msg.ret,
			pb_mail = mail_,
		})
	end
	
	print ("...................... on_des_send_mail", msg.ret)
end

function on_des_send_mail_from_center(msg)
	local mail_ = pb.decode(msg.pb_mail[1], msg.pb_mail[2])
	for i, item in ipairs(mail_.pb_attachment) do
		mail_.pb_attachment[i] = pb.decode(item[1], item[2])
	end
	
	local player = base_player:find(mail_.guid)
	if player then
		player.pb_mail_list[mail_.mail_id] = mail_
		
		send2client_pb(player, "SC_RecviceMail", {
			pb_mail = mail_,
		})
	end
	
	print ("...................... on_des_send_mail from center", msg.ret)
end

-- 删除邮件
function on_cs_del_mail(player, msg)
	if player.pb_mail_list and player.pb_mail_list[msg.mail_id] then
		local mail = player.pb_mail_list[msg.mail_id]
		if get_second_time() >= mail.expiration_time then
			player.pb_mail_list[msg.mail_id] = nil
			
			send2client_pb(player, "SC_DelMail", {
				result = MAIL_OPT_RESULT_EXPIRATION,
				mail_id = msg.mail_id,
			})
			return
		end
		
		if mail.attachment and #mail.attachment > 0 then
			send2client_pb(player, "SC_DelMail", {
				result = MAIL_OPT_RESULT_HAS_ATTACHMENT,
				mail_id = msg.mail_id,
			})
			return
		end
		
		player.pb_mail_list[msg.mail_id] = nil
		
		send2client_pb(player, "SC_DelMail", {
			result = MAIL_OPT_RESULT_SUCCESS,
			mail_id = msg.mail_id,
		})
		
		-- 通知db
		send2db_pb("SD_DelMail", {
			guid = player.guid,
			mail_id = msg.mail_id,
		})
	else
		send2client_pb(player, "SC_DelMail", {
			result = MAIL_OPT_RESULT_FIND_FAILED,
			mail_id = msg.mail_id,
		})
	end
	
	print ("...................... on_ce_del_mail")
end

-- 提取附件
function on_cs_receive_mail_attachment(player, msg)
	if player.pb_mail_list and player.pb_mail_list[msg.mail_id] then
		local mail = player.pb_mail_list[msg.mail_id]
		if get_second_time() >= mail.expiration_time then
			player.pb_mail_list[msg.mail_id] = nil
			
			send2client_pb(player, "SC_ReceiveMailAttachment", {
				result = MAIL_OPT_RESULT_EXPIRATION,
				mail_id = msg.mail_id,
			})
			return
		end
		
		if not mail.pb_attachment or #mail.pb_attachment == 0 then
			send2client_pb(player, "SC_ReceiveMailAttachment", {
				result = MAIL_OPT_RESULT_NO_ATTACHMENT,
				mail_id = msg.mail_id,
			})
			return
		end
		
		for i, v in ipairs(mail.pb_attachment) do
			player:add_item(v.item_id, v.item_num)
		end
		
		send2client_pb(player, "SC_ReceiveMailAttachment", {
			result = MAIL_OPT_RESULT_SUCCESS,
			mail_id = msg.mail_id,
			pb_attachment = mail.pb_attachment
		})
		
		mail.pb_attachment = nil
		
		-- 通知db
		send2db_pb("SD_ReceiveMailAttachment", {
			guid = player.guid,
			mail_id = msg.mail_id,
		})
	else
		send2client_pb(player, "SC_ReceiveMailAttachment", {
			result = MAIL_OPT_RESULT_FIND_FAILED,
			mail_id = msg.mail_id,
		})
	end
	
	print ("...................... on_cs_receive_mail_attachment")
end
