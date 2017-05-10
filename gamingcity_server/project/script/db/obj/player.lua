-- db player

if not g_init_player_ then
	g_init_player_ = {}
end
local init_player_ = g_init_player_

function add_player(guid_)
	local obj = {guid = guid_}
	init_player_[guid_] = obj
	return obj
end

function remove_player(guid)
	init_player_[guid] = nil
end

function find_player(guid)
	return init_player_[guid]
end

function for_in_player(func)
	for _, player in pairs(init_player_) do
		func(player)
	end
end
