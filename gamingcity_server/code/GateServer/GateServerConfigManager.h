#pragma once

#include "perinclude.h"
#include "Singleton.h"
#include "config_define.pb.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"

/**********************************************************************************************//**
 * \class	GateServerConfigManager
 *
 * \brief	Manager for gate server configurations.
 **************************************************************************************************/
#if 0
class GateServerConfigManager : public TSingleton<GateServerConfigManager>
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	GateServerConfigManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~GateServerConfigManager();

	/**********************************************************************************************//**
	 * \brief	得到配置文件.
	 *
	 * \return	The configuration.
	 **************************************************************************************************/

	GateServerConfig& get_config() { return config_; }

	/**********************************************************************************************//**
	 * \brief	加载配置文件.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool load_config();

	
	/**********************************************************************************************//**
	 * \brief	得到game server配置文件.
	 *
	 * \return	The configuration.
	 **************************************************************************************************/

	GameServerCfg& get_gameserver_config() { return gameserver_cfg_; }

	/**********************************************************************************************//**
	 * \brief	加载game server配置文件.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	bool load_gameserver_config();

	void load_gameserver_config_db(const std::vector<std::vector<std::string>>& data);

    void load_gameserver_config_pb(DL_ServerConfig & cfg);

    void load_gameserver_config_pb(LG_DBGameConfigMgr & cfg);
	/**********************************************************************************************//**
	 * \brief	设置配置文件名.
	 *
	 * \return	null if it fails, else a pointer to a const char.
	 **************************************************************************************************/

	void set_cfg_file_name(const std::string& filename) { cfg_file_name_ = filename; }

	/**********************************************************************************************//**
	 * \brief	得到配置文件名用于控制台标题.
	 *
	 * \return	The title.
	 **************************************************************************************************/

	std::string get_title();

	/**********************************************************************************************//**
	 * \brief	重新设置GamerConfig.
	 *
	 * \return	The title.
	 **************************************************************************************************/
    void db_cfg_to_gamserver();
private:
	bool load_file(const char* file, std::string& buf);

private:
	std::string											cfg_file_name_;
	GateServerConfig									config_;
	GameServerCfg										gameserver_cfg_;
    DBGameConfigMgr                                     dbgamer_config;
};
#endif
