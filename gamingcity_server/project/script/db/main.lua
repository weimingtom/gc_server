collectgarbage("setpause", 100)
collectgarbage("setstepmul", 5000)

print = function (...) end

require "hotfix"
require "db/msg/register"
require "db/msg/gm_cmd"
function _ALERT(str)
	log_assert(str)
end
