#include "GameFishingLuaScriptManager.h"

GameFishingLuaScriptManager::GameFishingLuaScriptManager()
{
}

GameFishingLuaScriptManager::~GameFishingLuaScriptManager()
{
}

void bind_lua_fish_table(lua_State* L);

void GameFishingLuaScriptManager::init()
{
	BaseGameLuaScriptManager::init();
	
	bind_lua_fish_table(L);
}
