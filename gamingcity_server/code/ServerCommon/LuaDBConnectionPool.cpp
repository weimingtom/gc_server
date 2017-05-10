#include "LuaDBConnectionPool.h"

LuaDBConnectionPool::LuaDBConnectionPool()
{

}

LuaDBConnectionPool::~LuaDBConnectionPool()
{
	
}

void LuaDBConnectionPool::execute_lua(const char* sql)
{
	execute(sql);
}

void LuaDBConnectionPool::execute_update_lua(const char* func, int index, const char* sql)
{
	std::string str_func = func;
	std::string str_sql = sql;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		int ret = con->execute_update(str_sql);

		auto p = new DBQueryUpdateLuaResult(str_sql, str_func, index, ret);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void LuaDBConnectionPool::execute_query_lua(const char* func, int index, bool more, const char* sql)
{
	std::string str_func = func;
	std::string str_sql = sql;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		std::string str;
		bool ret = con->execute_query_lua(str, more, str_sql);

		auto p = new DBQueryLuaResult(str_sql, str_func, index, ret, str);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}
