-- 玩家

local pb = require "protobuf"

require "net_func"
local send2server_pb = send2server_pb

player = {}
-- 创建
function player:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
    return o 
end

-- 初始化
function player:init(client_id, account, password)
	self.client_id_ = client_id
	self.account_ = account
	self.password_ = password
end

-- 每帧调用
function player:tick()
	--[[if self.is_login and get_second_time() - self.cur_time >= 7 then
		self.cur_time = get_second_time()
		
		send2server_pb(self, "CS_HEARTBEAT")
	end]]
end

-- 返回游戏配置
function on_GC_GameServerCfg(p, msg)
	print "on_GC_GameServerCfg ........................"
	--print_table(msg)
end

-- 得到公钥
function on_C_PublicKey(p, msg)
	print "on_C_PublicKey ........................"
	p.public_key_ = msg.public_key
	
	send2server_pb(p, "CL_Login", {
		account = p.account_,
		password = crypto_encrypt_password(p.public_key_, p.password_),
		phone = "windows",
		phone_type = "windows-test",
		version = "1.0",
		channel_id = "test",
		package_name = "test-package",
		imei = p.account_,
	})
end

-- 登录结果
function on_LC_Login(p, msg)
	print "on_LC_Login ........................"
	print(string.format("ret=%d guid=%d account=%s game_id=%d, nick=%s, guest=%s", msg.result, msg.guid, msg.account, msg.game_id, msg.nickname, (msg.is_guest and 'true' or 'false')))
	
	if msg.result == 0 then
		print "login ok!!!"
		
		player.game_id = msg.game_id
		player.is_login = true
		player.cur_time = get_second_time()
		
		send2server_pb(p, "CS_RequestPlayerInfo")
	end
end

-- 回复玩家数据信息
function on_SC_ReplyPlayerInfo(p, msg)
	print "on_SC_ReplyPlayerInfo ........................"
	--print_table(msg)
end

-- 回复玩家数据信息完成
function on_SC_ReplyPlayerInfoComplete(p, msg)
	print ("on_SC_ReplyPlayerInfoComplete ........................", player.game_id)
end

-- 心跳
function on_SC_HEARTBEAT(p, msg)
	--print "on_SC_HEARTBEAT ........................"
end

-- 跑马灯
function on_SC_QueryPlayerMarquee(p, msg)
	print "on_SC_QueryPlayerMarquee ........................"
end
function on_SC_NewMarquee(p, msg)
	print "on_SC_NewMarquee ........................"
end

-- 返回查询玩家公告及消息
function on_SC_QueryPlayerMsgData(p, msg)
	print "on_SC_QueryPlayerMsgData ........................"
end
function on_SC_NewMsgData(p, msg)
	print "on_SC_NewMsgData ........................"
end
