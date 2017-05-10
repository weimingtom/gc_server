#include "LuaScriptManager.h"
#include "RedisConnectionThread.h"
#include "CryptoManager.h"
#include "GameContrl.h"

void redis_command(const char* cmd)
{
	RedisConnectionThread::instance()->command(cmd);
}

void redis_command_query(const char* func, int index, const char* cmd)
{
	RedisConnectionThread::instance()->command_query_lua(func, index, cmd);
}

// RedisReply * redis_command_do(const char* cmd, bool master_flag){
// 	RedisReply *r;
// 	r = (RedisReply *)new(lua_newuserdata(LuaScriptManager::instance()->get_lua_state(), sizeof(RedisReply))) RedisReply(RedisConnectionThread::instance()->command_do(cmd, master_flag));
// 	return r;
// }

std::string to_hex(std::string src)
{
	return CryptoManager::to_hex(src);
}

std::string from_hex(std::string src)
{
	return CryptoManager::from_hex(src);
}
void Set_GameTimes(const char * GameType, int playGuid, int otherGuid, bool master_flag)
{
	GameContrl::setGameTimes(GameType, playGuid, otherGuid, master_flag);
}
void show(const char * GameType, int playGuid)
{
	GameContrl::show(GameType, playGuid);
}
void IncPlayTimes(const char * GameType, int playGuid, bool master_flag)
{
	GameContrl::IncPlayTimes(GameType, playGuid, master_flag);
}
int  getPlayTimes(const char * GameType, int playGuid, bool master_flag)
{
	return GameContrl::getPlayTimes(GameType, playGuid, master_flag);
}
bool judgePlayTimes(const char * GameType, int playGuid, int otherGuid, int times, bool master_flag)
{
	return GameContrl::judgePlayTimes(GameType, playGuid, otherGuid, times, master_flag);
}

void bind_lua_redis(lua_State* L)
{
	lua_tinker::class_add<RedisReply>(L, "RedisReply");
	lua_tinker::class_def<RedisReply>(L, "is_nil", &RedisReply::is_nil);
	lua_tinker::class_def<RedisReply>(L, "is_error", &RedisReply::is_error);
	lua_tinker::class_def<RedisReply>(L, "is_status", &RedisReply::is_status);
	lua_tinker::class_def<RedisReply>(L, "is_string", &RedisReply::is_string);
	lua_tinker::class_def<RedisReply>(L, "is_integer", &RedisReply::is_integer);
	lua_tinker::class_def<RedisReply>(L, "is_array", &RedisReply::is_array);
	lua_tinker::class_def<RedisReply>(L, "get_integer", &RedisReply::get_integer);
	lua_tinker::class_def<RedisReply>(L, "get_string", &RedisReply::get_string);
	lua_tinker::class_def<RedisReply>(L, "size_element", &RedisReply::size_element);
	lua_tinker::class_def<RedisReply>(L, "get_element", &RedisReply::get_element);

	lua_tinker::def(L, "redis_command", redis_command);
	lua_tinker::def(L, "redis_command_query", redis_command_query);
	//lua_tinker::def(L, "redis_command_do", redis_command_do);
	lua_tinker::def(L, "to_hex", to_hex);
	lua_tinker::def(L, "from_hex", from_hex);
	lua_tinker::def(L, "from_hex", from_hex);
	lua_tinker::def(L, "from_hex", from_hex);
	lua_tinker::def(L, "show", show);
	lua_tinker::def(L, "Set_GameTimes", Set_GameTimes);
	lua_tinker::def(L, "judgePlayTimes", judgePlayTimes);
	lua_tinker::def(L, "getPlayTimes", getPlayTimes);
	lua_tinker::def(L, "IncPlayTimes", IncPlayTimes);
}


