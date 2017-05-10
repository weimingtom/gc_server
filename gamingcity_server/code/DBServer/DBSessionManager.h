#pragma once

#include "NetworkServer.h"
#include "NetworkDispatcher.h"
#include "Singleton.h"
#include "msg_server.pb.h"

class DBSession;

/**********************************************************************************************//**
 * \class	DBSessionManager
 *
 * \brief	Manager for db sessions.
 **************************************************************************************************/

class DBSessionManager : public NetworkAllocator, public TSingleton < DBSessionManager >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	DBSessionManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~DBSessionManager();

	/**********************************************************************************************//**
	 * \brief	注册服务器连接消息的处理函数.
	 **************************************************************************************************/

	void register_connect_message();

	/**********************************************************************************************//**
	 * \brief	注册LoginServer连接到DBServer的消息的处理函数.
	 **************************************************************************************************/

	void register_login2db_message();

	/**********************************************************************************************//**
	 * \brief	注册GameServer连接到DBServer的消息的处理函数.
	 **************************************************************************************************/

	void register_game2db_message();

	/**********************************************************************************************//**
	 * \brief	创建sesssion.
	 *
	 * \param [in,out]	socket	The socket.
	 *
	 * \return	The new session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_session(boost::asio::ip::tcp::socket& socket);

	/**********************************************************************************************//**
	 * \brief	得到处理S_Connect的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }

	/**********************************************************************************************//**
	 * \brief	得到login连接db的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager login.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_login() { return &dispatcher_manager_login_; }

	/**********************************************************************************************//**
	 * \brief	得到game连接db的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager game.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_game() { return &dispatcher_manager_game_; }

	/**********************************************************************************************//**
	 * \brief	得到login连接db的session.
	 *
	 * \return	The login session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_login_session(int login_id);

	/**********************************************************************************************//**
	 * \brief	添加login连接db的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_login_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除login连接db的session.
	 **************************************************************************************************/

	void del_login_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	得到game连接db的session.
	 *
	 * \param	server_id	Identifier for the server.
	 *
	 * \return	The game session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_game_session(int server_id);

	/**********************************************************************************************//**
	 * \brief	添加game连接db的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_game_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除game连接db的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void del_game_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	向login server发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2login_pb(int login_id, T* pb)
	{
		auto session = get_login_session(login_id);
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server[%d] disconnect", login_id);
		}
	}
    
	/**********************************************************************************************//**
	 * \brief	向login广播消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> int broadcast2login_pb(T* pb)
	{
        for (auto session : login_session_)
		{
			session->send_pb(pb);
		}
        return (int)login_session_.size();
	}
	
	/**********************************************************************************************//**
	 * \brief	向game server发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	game_id   	Identifier for the game.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2game_pb(int game_id, T* pb)
	{
		auto session = get_game_session(game_id);
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_id);
		}
	}
    DBGameConfigMgr  &GetServerCfg(){        return dbgamer_config; }

	void add_verify_account(const std::string& account);
	void remove_verify_account(const std::string& account);
	bool find_verify_account(const std::string& account);

protected:
	NetworkDispatcherManager			dispatcher_manager_;
	NetworkDispatcherManager			dispatcher_manager_login_;
    NetworkDispatcherManager			dispatcher_manager_game_;
    DBGameConfigMgr                     dbgamer_config;

	std::vector<std::shared_ptr<NetworkSession>> login_session_;
	std::vector<std::shared_ptr<NetworkSession>> game_session_;

	std::unordered_map<std::string, time_t> verify_account_list_;
};