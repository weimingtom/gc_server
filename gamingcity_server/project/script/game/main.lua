collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

--print = function (...) end

require "hotfix"
math.randomseed(tostring(os.time()):reverse():sub(1, 6))

--if def_game_name == "fishing" then
--	Fishing_LoadConfig()
--end
--维护开关响应(全局变量0正常,1进入维护中,默认正常)
cash_switch = 0  --提现开关全局变量
game_switch = 0  --游戏开关全局变量


require "game/register"


require "game/lobby/base_player"
local base_player = base_player

require "game/lobby/base_android"
local base_passive_android = base_passive_android
require "game/lobby/gm_cmd"
local room_manager = g_room_manager


function _ALERT(str)
	log_assert(str)
end

function on_tick()
	base_player:save_all()
	base_passive_android:on_tick()
	room_manager:tick()
end

function SendStop2Lua()
	if def_game_name == "fishing" then
		StopFishServer()
	end
end