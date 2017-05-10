#pragma once

#include "perinclude.h"
#include <boost/thread/tss.hpp>
#include <google/protobuf/text_format.h>
#include "DBConnection.h"
#include "DBQueryResult.h"

/**********************************************************************************************//**
 * \class	DBConnectionPool
 *
 * \brief	A database connection pool.
 **************************************************************************************************/

class DBConnectionPool
{
	DBConnectionPool(const DBConnectionPool&) = delete;
	DBConnectionPool& operator =(const DBConnectionPool&) = delete;
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	DBConnectionPool();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBConnectionPool();

	/**********************************************************************************************//**
	 * \brief	运行.
	 *
	 * \param	thread_count	Number of threads.
	 **************************************************************************************************/

	void run(size_t thread_count);

	/**********************************************************************************************//**
	 * \brief	等待线程结束.
	 **************************************************************************************************/

	void join();

	/**********************************************************************************************//**
	 * \brief	请求关闭.
	 **************************************************************************************************/

	void stop();

	/**********************************************************************************************//**
	 * \brief	运行时，每一帧调用.
	 **************************************************************************************************/

	virtual bool tick();

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	fmt	格式化sql语句.
	 * \param	...	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute(const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	message	protobuf消息.
	 * \param	fmt	   	格式化sql语句.
	 * \param	...	   	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute(const google::protobuf::Message& message, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	fmt		格式化sql语句.
	 * \param	...		Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_update(const std::function<void(int)>& func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	message	protobuf消息.
	 * \param	fmt	   	格式化sql语句.
	 * \param	...	   	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_update(const std::function<void(int)>& func, const google::protobuf::Message& message, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句，捕获mysql错误.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	fmt 	格式化sql语句.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_try(const std::function<void(int)>& func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句，捕获mysql错误.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	fmt 	格式化sql语句.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_update_try(const std::function<void(int, int)>& func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql查询语句，返回string.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	fmt 	格式化sql语句.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_query_string(const std::function<void(std::vector<std::string>*)>& func, const char* fmt, ...);
	
	/**********************************************************************************************//**
	 * \brief	执行一条sql查询语句，返回string.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	fmt 	格式化sql语句.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	void execute_query_vstring(const std::function<void(std::vector<std::vector<std::string>>*)>& func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	执行一条sql查询语句，返回protobuf.
	 *
	 * \tparam	T	protobuf类型.
	 * \param	func	逻辑线程处理结果集.
	 * \param	name	多个结果的protobuf变量名.
	 * \param	fmt 	格式化sql语句.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	template<typename T> void execute_query(const std::function<void(T*)>& func, const char* name, const char* fmt, ...)
	{
		char str[4096] = { 0 };

		va_list arg;
		va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
		_vsnprintf_s(str, 4095, fmt, arg);
#else
		vsnprintf(str, 4095, fmt, arg);
#endif
		va_end(arg);

		std::string sql = str;

		std::string strname;
		if (name)
			strname = name;

		io_service_.post([=] {
			DBConnection* con = get_db_connection();
			
			std::string str;
			bool ret = con->execute_query(str, sql, strname);

			auto p = new DBQueryResult<T>(sql, func, ret, str);

			std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
			query_result_.push_back(p);
		});
	}

	/**********************************************************************************************//**
	 * \brief	执行一条有结果集返回的sql语句，返回protobuf.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	func	   	逻辑线程处理结果集.
	 * \param	name	   	多个结果的protobuf变量名.
	 * \param	filter_func	过滤结果集字段保存string样式，不做处理.
	 * \param	fmt		   	格式化sql语句.
	 * \param	...		   	Variable arguments providing additional information.
	 **************************************************************************************************/

	template<typename T> void execute_query_filter(const std::function<void(T*)>& func, const char* name, 
		const std::function<bool(const std::string&)>& filter_func, const char* fmt, ...)
	{
		char str[4096] = { 0 };

		va_list arg;
		va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
		_vsnprintf_s(str, 4095, fmt, arg);
#else
		vsnprintf(str, 4095, fmt, arg);
#endif
		va_end(arg);

		std::string sql = str;

		std::string strname;
		if (name)
			strname = name;

		io_service_.post([=] {
			DBConnection* con = get_db_connection();

			std::string str;
			bool ret = con->execute_query_filter(str, sql, strname, filter_func);

			auto p = new DBQueryResult<T>(func, ret, str);

			std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
			query_result_.push_back(p);
		});
	}

	/**********************************************************************************************//**
	 * \brief	设置数据库ip端口.
	 *
	 * \param	host	数据库ip端口，格式例如：tcp://127.0.0.1:3306.
	 **************************************************************************************************/

	void set_host(const std::string& host)
	{
		host_  = host; 
	}

	/**********************************************************************************************//**
	 * \brief	设置mysql账号.
	 *
	 * \param	user	mysql账号.
	 **************************************************************************************************/

	void set_user(const std::string& user)
	{
		user_ = user;
	}

	/**********************************************************************************************//**
	 * \brief	设置mysql密码.
	 *
	 * \param	password	mysql密码.
	 **************************************************************************************************/

	void set_password(const std::string& password)
	{
		password_ = password;
	}

	/**********************************************************************************************//**
	 * \brief	设置mysql数据库.
	 *
	 * \param	database	mysql数据库.
	 **************************************************************************************************/

	void set_database(const std::string& database)
	{
		database_ = database;
	}

protected:

	/**********************************************************************************************//**
	 * \brief	Gets database connection.
	 *
	 * \return	null if it fails, else the database connection.
	 **************************************************************************************************/

	DBConnection* get_db_connection();

	/**********************************************************************************************//**
	 * \brief	运行一个db线程.
	 **************************************************************************************************/

	void run_thread();

protected:
	std::string										host_;
	std::string										user_;
	std::string										password_;
	std::string										database_;

	boost::asio::io_service							io_service_;
	std::shared_ptr<boost::asio::io_service::work>	work_;
	std::vector<std::shared_ptr<std::thread>>		thread_;
	std::mutex										mutex_;

	volatile bool									is_run_;

	boost::thread_specific_ptr<DBConnection>		con_ptr_;

	std::recursive_mutex							mutex_query_result_;
	std::deque<BaseDBQueryResult*>					query_result_;
};

