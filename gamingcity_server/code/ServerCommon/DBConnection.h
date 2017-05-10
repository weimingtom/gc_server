#pragma once

#include "perinclude.h"
#include <mysqld_error.h>
#include <mysql_driver.h>
#include <mysql_connection.h>
#include <cppconn/driver.h>
#include <cppconn/statement.h>
#include <cppconn/prepared_statement.h>
#include <cppconn/metadata.h>
#include <cppconn/exception.h>

/**********************************************************************************************//**
 * \class	DBConnection
 *
 * \brief	A database connection.
 **************************************************************************************************/

class DBConnection
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	DBConnection();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~DBConnection();

	/**********************************************************************************************//**
	 * \brief	连接数据库.
	 *
	 * \param	host		数据库ip端口，格式例如：tcp://127.0.0.1:3306.
	 * \param	user		mysql账号.
	 * \param	password	mysql密码.
	 * \param	database	mysql数据库.
	 **************************************************************************************************/

	void connect(const std::string& host, const std::string& user, const std::string& password, const std::string& database);

	/**********************************************************************************************//**
	 * \brief	关闭数据库连接.
	 **************************************************************************************************/

	void close();

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	sql	The SQL.
	 **************************************************************************************************/

	void execute(const std::string& sql);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句.
	 *
	 * \param	sql	The SQL.
	 **************************************************************************************************/

	int execute_update(const std::string& sql);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句，捕获mysql错误.
	 *
	 * \param	sql	The SQL.
	 *
	 * \return	An int.
	 **************************************************************************************************/

	int execute_try(const std::string& sql);

	/**********************************************************************************************//**
	 * \brief	执行一条sql语句，捕获mysql错误.
	 *
	 * \param	sql	The SQL.
	 * \param	ret	更新结果.
	 *
	 * \return	An int.
	 **************************************************************************************************/
	int execute_update_try(const std::string& sql, int& ret);

	/**********************************************************************************************//**
	 * \brief	执行一条有结果集返回的sql语句，结果集是字符串数组.
	 *
	 * \param [in,out]	output	结果集.
	 * \param	sql			  	The SQL.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool execute_query_string(std::vector<std::string>& output, const std::string& sql);

	/**********************************************************************************************//**
	 * \brief	执行一条有结果集返回的sql语句，结果集是字符串数组.
	 *
	 * \param [in,out]	output	结果集.
	 * \param	sql			  	The SQL.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool execute_query_vstring(std::vector<std::vector<std::string>>& output, const std::string& sql);

	/**********************************************************************************************//**
	 * \brief	执行一条有结果集返回的sql语句，结果集是protobuf.
	 *
	 * \param [out]	output		结果集.
	 * \param	sql			  	The SQL.
	 * \param	name		  	多个结果的protobuf变量名.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool execute_query(std::string& output, const std::string& sql, const std::string& name);

	/**********************************************************************************************//**
	 * \brief	执行一条有结果集返回的sql语句，结果集是protobuf.
	 *
	 * \param [in,out]	output	结果集.
	 * \param	sql			  	The SQL.
	 * \param	name		  	多个结果的protobuf变量名.
	 * \param	filter_func   	过滤结果集字段保存string样式，不做处理.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool execute_query_filter(std::string& output, const std::string& sql, const std::string& name, 
		const std::function<bool(const std::string&)>& filter_func);

	bool execute_query_lua(std::string& output, bool b_more, const std::string& sql);

private:
	sql::Connection*							con_;
	sql::Statement*								stmt_;
};
