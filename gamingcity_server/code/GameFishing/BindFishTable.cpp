#include "LuaScriptManager.h"
#include "TableFrameSink.h"
#include "TableManager.h"


static void add_table(CTableFrameSink* table)
{
	TableManager::instance()->add_table(table);
}

static void remove_table(CTableFrameSink* table)
{
	TableManager::instance()->remove_table(table);
}

static void add_player_table(int chair_id, int guid, int gate_id, CTableFrameSink* table)
{
	TableManager::instance()->add_player_table(chair_id, guid, gate_id, table);
}

static void remove_player_table(int guid)
{
	TableManager::instance()->remove_player_table(guid);
}

static CTableFrameSink* find_table_by_player(int guid)
{
	return TableManager::instance()->find_table_by_player(guid);
}


void bind_lua_fish_table(lua_State* L)
{
	lua_tinker::def(L, "Fishing_LoadConfig", &CTableFrameSink::LoadConfig);
	
	lua_tinker::class_add<CTableFrameSink>(L, "CTableFrameSink");
	lua_tinker::class_con<CTableFrameSink>(L, lua_tinker::constructor<CTableFrameSink>);
	lua_tinker::class_def<CTableFrameSink>(L, "Initialization", &CTableFrameSink::Initialization);
	lua_tinker::class_def<CTableFrameSink>(L, "RepositionSink", &CTableFrameSink::RepositionSink);
	lua_tinker::class_def<CTableFrameSink>(L, "OnActionUserSitDown", &CTableFrameSink::OnActionUserSitDown);
	lua_tinker::class_def<CTableFrameSink>(L, "OnActionUserStandUp", &CTableFrameSink::OnActionUserStandUp);
	lua_tinker::class_def<CTableFrameSink>(L, "OnEventGameStart", &CTableFrameSink::OnEventGameStart);
	lua_tinker::class_def<CTableFrameSink>(L, "OnEventGameConclude", &CTableFrameSink::OnEventGameConclude);
	lua_tinker::class_def<CTableFrameSink>(L, "OnEventSendGameScene", &CTableFrameSink::OnEventSendGameScene);
	lua_tinker::class_def<CTableFrameSink>(L, "set_nickname", &CTableFrameSink::set_nickname);
	lua_tinker::class_def<CTableFrameSink>(L, "set_table_id", &CTableFrameSink::set_table_id);

	lua_tinker::def(L, "add_player_table", add_player_table);
	lua_tinker::def(L, "remove_player_table", remove_player_table);
	lua_tinker::def(L, "find_table_by_player", find_table_by_player);
}
