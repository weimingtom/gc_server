#pragma once

#include "perinclude.h"
#include "BaseServer.h"
#include "DBServerConfigManager.h"
#include "DBSessionManager.h"
#include "DBManager.h"
#include "DBLuaScriptManager.h"
#include "GmManager.h"
#include "RedisConnectionThread.h"
#include "DBConfigNetworkServer.h"

/**********************************************************************************************//**
 * \class	DBServer
 *
 * \brief	A db server.
 **************************************************************************************************/

class DBServer : public BaseServer
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	DBServer();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~DBServer();

	/**********************************************************************************************//**
	 * \brief	初始化.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool init();

	/**********************************************************************************************//**
	 * \brief	运行.
	 **************************************************************************************************/

	virtual void run();

	/**********************************************************************************************//**
	 * \brief	停止运行.
	 **************************************************************************************************/

	virtual void stop();

	/**********************************************************************************************//**
	 * \brief	释放.
	 **************************************************************************************************/

	virtual void release();

	/**********************************************************************************************//**
	 * \brief	处理gm命令.
	 *
	 * \param	cmd	The command.
	 **************************************************************************************************/

	virtual void on_gm_command(const char* cmd);

	/**********************************************************************************************//**
	 * \brief	调用的脚本文件.
	 *
	 * \return	null if it fails, else a pointer to a const char.
	 **************************************************************************************************/

	virtual const char* main_lua_file();

	void update_rank_to_center();
	
	virtual bool LoadSeverConfig();

	/**********************************************************************************************//**
	 * \brief	读取所有服务器配置.
	 **************************************************************************************************/

	bool get_init_config_server() { return init_config_server_; }
    void on_loadConfigComplete(const DBServerConfig& cfg);

    int get_db_id() { return db_id_; }
    void set_db_id(int dbid) { db_id_ = dbid; }

private:
	void tick();

    std::unique_ptr<DBConfigNetworkServer>			    config_server_;
	DBServerConfigManager								cfg_manager_;


    int													db_id_;
    bool												init_config_server_;
    bool												first_network_server_;

	std::unique_ptr<DBSessionManager>					sesssion_manager_;
	std::unique_ptr<NetworkServer>						network_server_;
	std::unique_ptr<DBManager>							db_manager_;
	std::unique_ptr<DBLuaScriptManager>					lua_manager_;
	std::unique_ptr<RedisConnectionThread>				redis_conn_;

#ifdef _DEBUG
	GmManager											gm_manager_;
#endif

	time_t												fortune_rank_time_;
	time_t												daily_earnings_time_;
	time_t												weekly_earnings_time_;
	int													monthly_earnings_year_mon_;
};