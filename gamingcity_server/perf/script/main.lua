collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

require "config"
require "register"

function _ALERT(str)
	log_error(str)
end

local player_manager_ = g_player_manager
function on_tick()
	player_manager_:tick()
end

function on_session_closed(client_id)
	local p = player_manager_:find_player_by_id(client_id)
	if p then
		p.is_login = nil
	end
end

print "test finish ..."
