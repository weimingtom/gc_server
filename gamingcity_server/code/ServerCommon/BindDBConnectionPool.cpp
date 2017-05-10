#include "LuaScriptManager.h"
#include "LuaDBConnectionPool.h"


void bind_lua_db_connection_pool(lua_State* L)
{
	lua_tinker::class_add<LuaDBConnectionPool>(L, "DBConnectionPool");
	lua_tinker::class_def<LuaDBConnectionPool>(L, "execute", &LuaDBConnectionPool::execute_lua);
	lua_tinker::class_def<LuaDBConnectionPool>(L, "execute_update", &LuaDBConnectionPool::execute_update_lua);
	lua_tinker::class_def<LuaDBConnectionPool>(L, "execute_query", &LuaDBConnectionPool::execute_query_lua);
}
