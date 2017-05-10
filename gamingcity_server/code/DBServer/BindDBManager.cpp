#include "LuaScriptManager.h"
#include "DBManager.h"
#include "DBServerConfigManager.h"
#include "UtilsHelper.h"

static LuaDBConnectionPool* get_account_db()
{
	return &DBManager::instance()->get_db_connection_account();
}

static LuaDBConnectionPool* get_game_db()
{
	return &DBManager::instance()->get_db_connection_game();
}

static LuaDBConnectionPool* get_log_db()
{
	return &DBManager::instance()->get_db_connection_log();
}

static LuaDBConnectionPool* get_recharge_db()
{
    return &DBManager::instance()->get_db_connection_recharge();
}

static const char* get_sd_cash_money_addr()
{
	if (DBServerConfigManager::instance())
		return DBServerConfigManager::instance()->get_config().cash_money_addr().c_str();
	else
		return "";
}

static const char* get_php_interface_addr()
{
    if (DBServerConfigManager::instance())
        return DBServerConfigManager::instance()->get_config().php_interface_addr().c_str();
    else
        return "";
}
static const char* get_php_sign_key()
{
    if (DBServerConfigManager::instance())
        return DBServerConfigManager::instance()->get_config().php_sign_key().c_str();
    else
        return "";
}

static std::string get_to_md5(std::string str)
{
    return UtilsHelper::md5(str);
}

void bind_lua_db_manager(lua_State* L)
{
	lua_tinker::def(L, "get_account_db", get_account_db);
	lua_tinker::def(L, "get_game_db", get_game_db);
    lua_tinker::def(L, "get_log_db", get_log_db);
    lua_tinker::def(L, "get_recharge_db", get_recharge_db);
    lua_tinker::def(L, "get_sd_cash_money_addr", get_sd_cash_money_addr); 
    lua_tinker::def(L, "get_php_interface_addr", get_php_interface_addr);
    lua_tinker::def(L, "get_php_sign_key", get_php_sign_key);
    lua_tinker::def(L, "get_to_md5", get_to_md5);
}
