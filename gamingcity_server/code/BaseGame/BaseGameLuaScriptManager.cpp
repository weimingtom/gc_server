#include "BaseGameLuaScriptManager.h"
#include "BaseGameServer.h"

BaseGameLuaScriptManager::BaseGameLuaScriptManager()
{
}

BaseGameLuaScriptManager::~BaseGameLuaScriptManager()
{
}

void bind_lua_redis(lua_State* L);
void bind_lua_net_message(lua_State* L);

void BaseGameLuaScriptManager::init()
{
	LuaScriptManager::init();

	bind_lua_redis(L);
	bind_lua_net_message(L);

	auto& cfg = static_cast<BaseGameServer*>(BaseServer::instance())->get_config();

	int game_id = cfg.game_id();
	lua_tinker::decl(L, "def_game_id", game_id);

	std::string name = static_cast<BaseGameServer*>(BaseServer::instance())->get_game_name();
	lua_tinker::decl(L, "def_game_name", &name);

	int def_first_game_type = cfg.first_game_type();
	lua_tinker::decl(L, "def_first_game_type", def_first_game_type);

	int def_second_game_type = cfg.second_game_type();
	lua_tinker::decl(L, "def_second_game_type", def_second_game_type);

	bool using_login_validatebox = cfg.using_login_validatebox();
	lua_tinker::decl(L, "using_login_validatebox", using_login_validatebox);
}
