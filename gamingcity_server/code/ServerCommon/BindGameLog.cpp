#include "LuaScriptManager.h"
#include "GameLog.h"
#include "GameTimeManager.h"


static std::string format_log(const char* log)
{
	std::stringstream ss;
	
	auto ptm = GameTimeManager::instance()->get_tm();
	char strdate[100] = { 0 };
#ifdef PLATFORM_WINDOWS
	sprintf_s(strdate, "[%d-%02d-%02d %02d:%02d:%02d]", ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
#else
	sprintf(strdate, "[%d-%02d-%02d %02d:%02d:%02d]", ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
#endif

	ss << strdate;

	ss << log;

	auto L = LuaScriptManager::instance()->get_lua_state();
	lua_Debug ar = {};
	lua_getstack(L, 1, &ar);
	lua_getinfo(L, "Sln", &ar);
	std::string name;
	if (ar.name)
		name = ar.name;
	ss << "(" << ar.short_src << ":" << ar.currentline << "[" << name << "])\n";

	return ss.str();
}

static void log_info(const char* log)
{
	GameLog::instance()->log_string(GameLog::LOG_TYPE_INFO, format_log(log).c_str());
}

static void log_error(const char* log)
{
	GameLog::instance()->log_string(GameLog::LOG_TYPE_ERROR, format_log(log).c_str());
}

static void log_warning(const char* log)
{
	GameLog::instance()->log_string(GameLog::LOG_TYPE_WARNING, format_log(log).c_str());
}

static void log_debug(const char* log)
{
	GameLog::instance()->log_string(GameLog::LOG_TYPE_DEBUG, format_log(log).c_str());
}

static void log_assert(const char* log)
{
	GameLog::instance()->log_string(GameLog::LOG_TYPE_ERROR, (std::string(log)+"\n").c_str());
}

void bind_lua_game_log(lua_State* L)
{
	lua_tinker::def(L, "log_info", log_info);
	lua_tinker::def(L, "log_error", log_error);
	lua_tinker::def(L, "log_warning", log_warning);
	lua_tinker::def(L, "log_debug", log_debug);
	lua_tinker::def(L, "log_assert", log_assert);
}
