#include "DBLuaScriptManager.h"

DBLuaScriptManager::DBLuaScriptManager()
{
}

DBLuaScriptManager::~DBLuaScriptManager()
{
}

void bind_lua_redis(lua_State* L);
void bind_lua_db_connection_pool(lua_State* L);

void bind_lua_db_net_message(lua_State* L);
void bind_lua_db_manager(lua_State* L);

void DBLuaScriptManager::init()
{
	LuaScriptManager::init();

	bind_lua_redis(L);
	bind_lua_db_connection_pool(L);
	
	bind_lua_db_net_message(L);
	bind_lua_db_manager(L);
}
