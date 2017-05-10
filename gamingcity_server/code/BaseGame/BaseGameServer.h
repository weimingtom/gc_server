#pragma once

#include "perinclude.h"
#include "BaseServer.h"
#include "GameSessionManager.h"
#include "BaseGameLuaScriptManager.h"
#include "GameGmManager.h"
#include "RedisConnectionThread.h"
#include "GameConfigNetworkServer.h"
#include "msg_server.pb.h"

/**********************************************************************************************//**
 * \class	BaseGameServer
 *
 * \brief	A game server.
 **************************************************************************************************/

class BaseGameServer : public BaseServer
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	BaseGameServer();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~BaseGameServer();

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

	void on_gm_command(const char* cmd);

	/**********************************************************************************************//**
	 * \brief	日志文件名.
	 *
	 * \return	null if it fails, else a pointer to a const char.
	 **************************************************************************************************/

	//virtual const char* log_file_name();

	/**********************************************************************************************//**
	 * \brief	dump文件名.
	 *
	 * \return	null if it fails, else a pointer to a const wchar_t.
	 **************************************************************************************************/

	virtual const wchar_t* dump_file_name();
	
	int get_game_id() { return game_id_; }
	void set_game_id(int gameid) { game_id_ = gameid; }
	const std::string& get_game_name() { return game_name_; }
	void set_game_name(const std::string& name) { game_name_ = name; }
	bool get_init_config_server() { return init_config_server_; }
	void on_loadConfigComplete(const GameServerConfigInfo& cfg);
	GameServerConfigInfo& get_config() { return game_config_; }

	bool on_NotifyLoginServerStart(int login_id);
	void on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGame& cfg);
	bool on_NotifyDBServerStart(int db_id);
	void on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByGame& cfg);

protected:
	virtual void on_tick() {}

	virtual GameSessionManager* new_session_manager();
	virtual BaseGameLuaScriptManager* new_lua_script_manager();

protected:
	int													game_id_;
	std::string											game_name_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<GameConfigNetworkServer>			config_server_;
	GameServerConfigInfo								game_config_;
	//GameServerConfigManager								cfg_manager_;

	std::unique_ptr<GameSessionManager>					sesssion_manager_;
	std::unique_ptr<NetworkServer>						network_server_;
	std::unique_ptr<BaseGameLuaScriptManager>			lua_manager_;
	std::unique_ptr<RedisConnectionThread>				redis_conn_;
	
#ifdef _DEBUG
	GameGmManager										gm_manager_;
#endif

	bool												load_cfg_complete_;
};
