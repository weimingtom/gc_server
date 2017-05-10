#pragma once

#include "LuaDBConnectionPool.h"
#include "Singleton.h"
#include "common_msg_define.pb.h"

/**********************************************************************************************//**
 * \class	DBManager
 *
 * \brief	Manager for databases.
 **************************************************************************************************/

class DBManager : public TSingleton<DBManager>
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	DBManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBManager();

	/**********************************************************************************************//**
	 * \brief	开启数据库线程并运行.
	 **************************************************************************************************/

	void run();

	/**********************************************************************************************//**
	 * \brief	等待线程结束.
	 **************************************************************************************************/

	void join();

	/**********************************************************************************************//**
	 * \brief	请求关闭.
	 **************************************************************************************************/

	void stop();

	/**********************************************************************************************//**
	 * \brief	每一帧调用.
	 **************************************************************************************************/

	virtual bool tick();

	/**********************************************************************************************//**
	 * \brief	得到account数据库.
	 *
	 * \return	The database connection account.
	 **************************************************************************************************/

	LuaDBConnectionPool& get_db_connection_account() { return db_connection_account_; }

	/**********************************************************************************************//**
	 * \brief	得到game数据库.
	 *
	 * \return	The database connection game.
	 **************************************************************************************************/

	LuaDBConnectionPool& get_db_connection_game() { return db_connection_game_; }

	/**********************************************************************************************//**
	 * \brief	得到game数据库.
	 *
	 * \return	The database connection game.
	 **************************************************************************************************/

    LuaDBConnectionPool& get_db_connection_recharge() { return db_connection_recharge_; }
	

	/**********************************************************************************************//**
	 * \brief	得到log数据库.
	 *
	 * \return	The database connection game.
	 **************************************************************************************************/

	LuaDBConnectionPool& get_db_connection_log() { return db_connection_log_; }


protected:
	LuaDBConnectionPool							db_connection_account_;
	LuaDBConnectionPool							db_connection_game_;
    LuaDBConnectionPool							db_connection_log_;
    LuaDBConnectionPool							db_connection_recharge_;
};
