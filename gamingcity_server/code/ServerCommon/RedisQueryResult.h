#pragma once

#include "perinclude.h"
#include "RedisConnection.h"
#include "LuaScriptManager.h"


/**********************************************************************************************//**
 * \class	BaseRedisQueryResult
 *
 * \brief	Encapsulates the result of a base redis query.
 **************************************************************************************************/

class BaseRedisQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	BaseRedisQueryResult() {}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~BaseRedisQueryResult() {}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_command_result() = 0;
};

/**********************************************************************************************//**
 * \class	RedisQueryResult
 *
 * \brief	Encapsulates the result of a redis query.
 **************************************************************************************************/

class RedisQueryResult : public BaseRedisQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	cmd_func	处理查询回调.
	 * \param	reply   	结果.
	 **************************************************************************************************/

	RedisQueryResult(const std::function<void(RedisReply*)>& cmd_func, const RedisReply& reply)
		: cmd_func_(cmd_func)
		, reply_(reply)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~RedisQueryResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_command_result()
	{
		cmd_func_(&reply_);
	}

private:
	/** \brief	处理查询回调. */
	std::function<void(RedisReply*)>		cmd_func_;
	/** \brief	结果. */
	RedisReply								reply_;
};

class RedisQueryLuaResult : public BaseRedisQueryResult
{
public:
	RedisQueryLuaResult(const std::string& query_func, int index, const RedisReply& reply)
		: cmd_func_(query_func)
		, index_(index)
		, reply_(reply)
	{
	}

	virtual ~RedisQueryLuaResult()
	{

	}

	virtual void on_command_result()
	{
		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), cmd_func_.c_str(), index_, &reply_);
	}

private:
	/** \brief	处理查询回调. */
	std::string								cmd_func_;
	/** \brief	数据库查询结果处理函数Index. */
	int										index_;
	/** \brief	结果. */
	RedisReply								reply_;
};

class RedisQueryNullResult : public BaseRedisQueryResult
{
public:
	RedisQueryNullResult(const std::function<void()>& cmd_func)
		: cmd_func_(cmd_func)
	{
	}

	virtual ~RedisQueryNullResult()
	{

	}

	virtual void on_command_result()
	{
		cmd_func_();
	}

private:
	/** \brief	处理查询回调. */
	std::function<void()>					cmd_func_;
};

template<typename T>
class RedisQueryPbResult : public BaseRedisQueryResult
{
public:
	RedisQueryPbResult(const std::function<void(T*)>& cmd_func, const T& reply)
		: cmd_func_(cmd_func)
		, reply_(reply)
	{
	}

	virtual ~RedisQueryPbResult()
	{

	}

	virtual void on_command_result()
	{
		cmd_func_(&reply_);
	}

private:
	/** \brief	处理查询回调. */
	std::function<void(T*)>					cmd_func_;
	/** \brief	结果. */
	T										reply_;
};
