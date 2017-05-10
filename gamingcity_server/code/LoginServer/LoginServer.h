#pragma once

#include "perinclude.h"
#include "BaseServer.h"
#include "LoginSessionManager.h"
#include "RedisConnectionThread.h"
#include "LoginConfigNetworkServer.h"
#include "msg_server.pb.h"

/**********************************************************************************************//**
 * \class	LoginServer
 *
 * \brief	A login server.
 **************************************************************************************************/

class LoginServer : public BaseServer
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	LoginServer();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~LoginServer();

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

	int get_login_id() { return login_id_; }
	void set_login_id(int loginid) { login_id_ = loginid; }
	bool get_init_config_server() { return init_config_server_; }
	void on_loadConfigComplete(const LoginServerConfigInfo& cfg);
	LoginServerConfigInfo& get_config() { return login_config_; }

	bool on_NotifyDBServerStart(int db_id);
	void on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByLogin& cfg);
	void set_maintain_switch(int open_switch) { maintain_switch = open_switch; };
	int get_maintain_switch() { return maintain_switch; };
private:
	int													login_id_;
	bool												init_config_server_;
	bool												first_network_server_;
	std::unique_ptr<LoginConfigNetworkServer>			config_server_;
	LoginServerConfigInfo								login_config_;

	std::unique_ptr<LoginSessionManager>				sesssion_manager_;
	std::unique_ptr<NetworkServer>						network_server_;
	std::unique_ptr<RedisConnectionThread>				redis_conn_;
	int													maintain_switch;//1维护中,0正常
};