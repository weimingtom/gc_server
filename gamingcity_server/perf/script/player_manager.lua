-- 玩家管理器

local pb = require "protobuf"

require "net_func"
local send2server_pb = send2server_pb

require "player"
local player = player

player_manager = {}
-- 创建
function player_manager:new()  
    local o = {}  
    setmetatable(o, {__index = self})
	
	self.player_list = {}
	self.player_id_map = {}
	
    return o 
end

-- 创建玩家
function player_manager:create_player(client_id, account, password)
	local p = player:new()
	p:init(client_id, account, password)
	self.player_list[account] = p
	self.player_id_map[client_id] = p
	return p
end

-- 删除玩家
function player_manager:destroy_player(account)
	self.player_list[account] = nil
end

-- 查找玩家
function player_manager:find_player_by_id(client_id)
	return self.player_id_map[client_id]
end

-- 每帧调用
function player_manager:tick()
	for i, v in pairs(self.player_list) do
		v:tick()
	end
end
