#include "TestPerfLuaScriptManager.h"

TestPerfLuaScriptManager::TestPerfLuaScriptManager()
{
}

TestPerfLuaScriptManager::~TestPerfLuaScriptManager()
{
}

void bind_lua_crypto_message(lua_State* L);
void bind_lua_net_message(lua_State* L);

void TestPerfLuaScriptManager::init()
{
	LuaScriptManager::init();

	bind_lua_crypto_message(L);
	bind_lua_net_message(L);
}
