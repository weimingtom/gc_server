#pragma once

#include "DBConnectionPool.h"
#include "LuaScriptManager.h"


class DBQueryUpdateLuaResult : public BaseDBQueryResult
{
public:

	DBQueryUpdateLuaResult(const std::string& sql, const std::string& query_func, int index, int ret)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, index_(index)
		, ret_(ret)
	{
	}

	virtual ~DBQueryUpdateLuaResult()
	{

	}

	virtual void on_query_result()
	{
		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), query_func_.c_str(), index_, ret_);
	}

private:
	/** \brief	处理查询回调. */
	std::string								query_func_;
	/** \brief	数据库查询结果处理函数Index. */
	int										index_;
	/** \brief	查询结果. */
	int										ret_;
};

class DBQueryLuaResult : public BaseDBQueryResult
{
public:

	DBQueryLuaResult(const std::string& sql, const std::string& query_func, int index, bool success, const std::string& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, index_(index)
		, success_(success)
		, message_(msg)
	{
	}

	virtual ~DBQueryLuaResult()
	{

	}

	virtual void on_query_result()
	{
		if (success_)
		{
			lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), query_func_.c_str(), index_, &message_);
		}
		else
		{
			lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), query_func_.c_str(), index_);
		}
	}

private:
	/** \brief	处理查询回调. */
	std::string								query_func_;
	/** \brief	数据库查询结果处理函数Index. */
	int										index_;
	/** \brief	查询是否成功. */
	bool									success_;
	/** \brief	查询结果集. */
	std::string								message_;
};

class LuaDBConnectionPool : public DBConnectionPool
{
public:
	LuaDBConnectionPool();

	virtual ~LuaDBConnectionPool();

	void execute_lua(const char* sql);

	void execute_update_lua(const char* func, int index, const char* sql);

	void execute_query_lua(const char* func, int index, bool more, const char* sql);
protected:
private:
};
