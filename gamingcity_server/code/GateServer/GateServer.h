#pragma once

#include "perinclude.h"
#include "BaseServer.h"
#include "GateServerConfigManager.h"
#include "GateSessionManager.h"
#include "IpAreaManager.h"
#include "../ServerCommon/asynTask/AsynTaskMgr.h"
#include "GateConfigNetworkServer.h"

/**********************************************************************************************//**
 * \class	GateServer
 *
 * \brief	A gate server.
 **************************************************************************************************/

class GateServer : public BaseServer
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	GateServer();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~GateServer();

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
	 * \brief	用存储中mysql的配置.
	 **************************************************************************************************/

//	void set_using_db_config(bool b) { using_db_config_ = b; }
	
	/**********************************************************************************************//**
	 * \brief	是否用存储中mysql的配置.
	 **************************************************************************************************/

	//bool get_using_db_config() { return using_db_config_; }
	
	/**********************************************************************************************//**
	 * \brief	重新从mysql中加载的配置.
	 **************************************************************************************************/

    void reload_gameserver_config(DL_ServerConfig & cfg);
    void reload_gameserver_config_DB(LG_DBGameConfigMgr & cfg);

	int get_gate_id() { return gate_id_; }
	void set_gate_id(int gateid) { gate_id_ = gateid; }
	bool get_init_config_server() { return init_config_server_; }
	void on_loadConfigComplete(const S_ReplyServerConfig& cfg);
	void on_UpdateConfigComplete(const S_ReplyUpdateGameServerConfig& cfg);
	bool on_NotifyGameServerStart(int game_id);
	void on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGate& cfg);
	bool on_NotifyLoginServerStart(int login_id);
	GateServerConfigInfo& get_config() { return gate_config_; }
	GC_GameServerCfg& get_gamecfg() { return gameserver_cfg_; }

	void get_rsa_key(std::string& public_key, std::string& private_key);

private:
	int													gate_id_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<GateConfigNetworkServer>			config_server_;
	GateServerConfigInfo								gate_config_;
	GC_GameServerCfg									gameserver_cfg_;
	//GateServerConfigManager								cfg_manager_;


	std::unique_ptr<GateSessionManager>					sesssion_manager_;
	std::unique_ptr<NetworkServer>						network_server_;

	std::unique_ptr<IpAreaManager>						ip_manager_;
	std::unique_ptr<AsynTaskMgr>						asyn_task_manager_;

	bool												using_db_config_;

	std::vector<std::pair<std::string, std::string>>	rsa_keys_;
	size_t												rsa_keys_index_;
	time_t												rsa_keys_time_;
};
