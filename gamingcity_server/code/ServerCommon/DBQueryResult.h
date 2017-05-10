#pragma once

#include "perinclude.h"
#include <google/protobuf/text_format.h>
#include "GameLog.h"


/**********************************************************************************************//**
 * \class	BaseDBQueryResult
 *
 * \brief	Encapsulates the result of a base database query.
 **************************************************************************************************/

class BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	BaseDBQueryResult(const std::string& sql) : sql_(sql) {}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~BaseDBQueryResult() {}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result() = 0;

	const char* get_sql() { return sql_.c_str(); }
private:
	std::string							sql_;
};

/**********************************************************************************************//**
 * \class	DBQueryResult
 *
 * \brief	Encapsulates the result of a database query.
 **************************************************************************************************/

template<typename T>
class DBQueryResult : public BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	query_func	处理查询回调.
	 * \param	success   	查询是否成功.
	 * \param	msg		  	查询结果集.
	 **************************************************************************************************/

	DBQueryResult(const std::string& sql, const std::function<void(T*)>& query_func, bool success, const std::string& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
		, message_(msg)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBQueryResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result()
	{
		if (success_)
		{
			T msg;
			if (google::protobuf::TextFormat::ParseFromString(message_, &msg))
			{
				query_func_(&msg);
			}
			else
			{
				LOG_ERR("query error:%s", message_.c_str());
			}
		}
		else
		{
			query_func_(nullptr);
		}
	}

private:
	/** \brief	处理查询回调. */
	std::function<void(T*)>					query_func_;
	/** \brief	查询是否成功. */
	bool									success_;
	/** \brief	查询结果集. */
	std::string								message_;
};

/**********************************************************************************************//**
 * \class	DBQueryUpdateResult
 *
 * \brief	Encapsulates the result of a database query update.
 **************************************************************************************************/

class DBQueryUpdateResult : public BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	query_func	处理查询回调.
	 * \param	int   		查询结果.
	 **************************************************************************************************/

	DBQueryUpdateResult(const std::string& sql, const std::function<void(int)>& query_func, int ret)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, ret_(ret)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBQueryUpdateResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result()
	{
		query_func_(ret_);
	}

private:
	std::function<void(int)>				query_func_;
	int										ret_;
};

/**********************************************************************************************//**
 * \class	DBQueryUpdateTryResult
 *
 * \brief	Encapsulates the result of a database query update.
 **************************************************************************************************/

class DBQueryUpdateTryResult : public BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	query_func	处理查询回调.
	 * \param	int   		查询结果.
	 **************************************************************************************************/

	DBQueryUpdateTryResult(const std::string& sql, const std::function<void(int, int)>& query_func, int ret, int err)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, ret_(ret)
		, err_(err)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBQueryUpdateTryResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result()
	{
		query_func_(ret_, err_);
	}

private:
	std::function<void(int, int)>			query_func_;
	int										ret_;
	int										err_;
};

/**********************************************************************************************//**
 * \class	DBQueryStringResult
 *
 * \brief	Encapsulates the result of a database query string.
 **************************************************************************************************/

class DBQueryStringResult : public BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	query_func	处理查询回调.
	 * \param	success   	查询是否成功.
	 * \param	msg		  	查询结果集.
	 **************************************************************************************************/

	DBQueryStringResult(const std::string& sql, const std::function<void(std::vector<std::string>*)>& query_func, bool success, const std::vector<std::string>& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
		, message_(msg)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBQueryStringResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result()
	{
		if (success_)
		{
			query_func_(&message_);
		}
		else
		{
			query_func_(nullptr);
		}
	}

private:
	/** \brief	处理查询回调. */
	std::function<void(std::vector<std::string>*)> query_func_;
	/** \brief	查询是否成功. */
	bool									success_;
	/** \brief	查询结果集. */
	std::vector<std::string>				message_;
};


/**********************************************************************************************//**
 * \class	DBQueryStringResult
 *
 * \brief	Encapsulates the result of a database query string.
 **************************************************************************************************/

class DBQueryVStringResult : public BaseDBQueryResult
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	query_func	处理查询回调.
	 * \param	success   	查询是否成功.
	 * \param	msg		  	查询结果集.
	 **************************************************************************************************/

	DBQueryVStringResult(const std::string& sql, const std::function<void(std::vector<std::vector<std::string>>*)>& query_func, bool success, const std::vector<std::vector<std::string>>& msg)
		: BaseDBQueryResult(sql)
		, query_func_(query_func)
		, success_(success)
		, message_(msg)
	{
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBQueryVStringResult()
	{

	}

	/**********************************************************************************************//**
	 * \brief	在逻辑线程处理查询结果.
	 **************************************************************************************************/

	virtual void on_query_result()
	{
		if (success_)
		{
			query_func_(&message_);
		}
		else
		{
			query_func_(nullptr);
		}
	}

private:
	/** \brief	处理查询回调. */
	std::function<void(std::vector<std::vector<std::string>>*)> query_func_;
	/** \brief	查询是否成功. */
	bool									success_;
	/** \brief	查询结果集. */
	std::vector<std::vector<std::string>>	message_;
};
