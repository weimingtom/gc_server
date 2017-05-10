#pragma once

#include "NetworkServer.h"
#include "NetworkDispatcher.h"
#include "Singleton.h"

class GameSession;
class GameDBSession;

/**********************************************************************************************//**
 * \class	GameSessionManager
 *
 * \brief	Manager for game sessions.
 **************************************************************************************************/

class GameSessionManager : public NetworkAllocator, public TSingleton < GameSessionManager >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	GameSessionManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GameSessionManager();

	/**********************************************************************************************//**
	 * \brief	注册服务器连接消息的处理函数.
	 **************************************************************************************************/

	void register_connect_message();
	
	/**********************************************************************************************//**
	 * \brief	注册GameServer连接到LoginServer的消息的处理函数.
	 **************************************************************************************************/

	void register_game2login_message();

	/**********************************************************************************************//**
	 * \brief	注册GateServer连接到GameServer的消息的处理函数.
	 **************************************************************************************************/

	void register_gate2game_message();

	/**********************************************************************************************//**
	 * \brief	注册GameServer连接到DBServer的消息的处理函数.
	 **************************************************************************************************/

	void register_game2db_message();

	/**********************************************************************************************//**
	 * \brief	关闭所有session.
	 **************************************************************************************************/

	virtual void close_all_session();

	/**********************************************************************************************//**
	 * \brief	释放所有session资源.
	 **************************************************************************************************/

	virtual void release_all_session();

	/**********************************************************************************************//**
	 * \brief	每一帧调用.
	 **************************************************************************************************/

	virtual bool tick();

	/**********************************************************************************************//**
	 * \brief	创建sesssion.
	 *
	 * \param [in,out]	socket	The socket.
	 *
	 * \return	The new session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_session(boost::asio::ip::tcp::socket& socket);
	
	/**********************************************************************************************//**
	 * \brief	创建login server session.
	 *
	 * \param	ip  	The IP.
	 * \param	port	The port.
	 *
	 * \return	The new login session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_login_session(const std::string& ip, unsigned short port);

	/**********************************************************************************************//**
	 * \brief	创建database server session.
	 *
	 * \param	ip  	The IP.
	 * \param	port	The port.
	 *
	 * \return	The new database session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_db_session(const std::string& ip, unsigned short port);

	/**********************************************************************************************//**
	 * \brief	设置网络服务器.
	 *
	 * \param [in,out]	network_server	If non-null, the network server.
	 **************************************************************************************************/

	virtual void set_network_server(NetworkServer* network_server);

	/**********************************************************************************************//**
	 * \brief	得到处理S_Connect的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }
	
	/**********************************************************************************************//**
	 * \brief	得到game连接login的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager gate.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_login() { return &dispatcher_manager_login_; }

	/**********************************************************************************************//**
	 * \brief	得到gate连接game的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager gate.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_gate() { return &dispatcher_manager_gate_; }

	/**********************************************************************************************//**
	 * \brief	得到game连接db的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager database.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_db() { return &dispatcher_manager_db_; }

	/**********************************************************************************************//**
	 * \brief	得到game连接db的session.
	 *
	 * \return	The database session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_db_session();

	/**********************************************************************************************//**
	 * \brief	得到game连接login的session.
	 *
	 * \return	The login session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_login_session();

    std::shared_ptr<NetworkSession> get_login_session(int login_id);
	/**********************************************************************************************//**
	 * \brief	添加game连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_login_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除game连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void del_login_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	得到gate连接game的session.
	 *
	 * \param	server_id	Identifier for the server.
	 *
	 * \return	The gate session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_gate_session(int server_id);

	/**********************************************************************************************//**
	 * \brief	添加gate连接game的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_gate_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除gate连接game的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void del_gate_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	向db server发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	/*template<typename T> void send2db_pb(T* pb)
	{
		if (db_session_)
		{
			db_session_->send_pb(pb);
		}
		else
		{
			LOG_WARN("db server disconnect");
		}
	}*/

	/**********************************************************************************************//**
	 * \brief	向login发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2login_pb(T* pb)
	{
		auto session = get_login_session();
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}
	
	/**********************************************************************************************//**
	 * \brief	向client发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	guid	  	Unique identifier.
	 * \param	gate_id   	玩家在哪个gate server.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2client_pb(int guid, int gate_id, T* pb)
	{
		auto session = get_gate_session(gate_id);
		if (session)
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("gate server[%d] disconnect", gate_id);
		}
	}

	// 向login广播当前玩家数量
	void broadcast_player_count(int count);

	// 设置链接到db
	void set_first_connect_db();

	// 第一次连接上db服务器
	virtual void on_first_connect_db();

	void Add_Login_Server_Session(const std::string& ip, int port);
	void Add_DB_Server_Session(const std::string& ip, int port);
protected:
	NetworkDispatcherManager			dispatcher_manager_;
	NetworkDispatcherManager			dispatcher_manager_login_;
	NetworkDispatcherManager			dispatcher_manager_gate_;
	NetworkDispatcherManager			dispatcher_manager_db_;

	std::vector<std::shared_ptr<NetworkSession>> login_session_;
	std::vector<std::shared_ptr<NetworkSession>> db_session_;
	std::vector<std::shared_ptr<NetworkSession>> gate_session_;

	size_t								cur_login_session_;
	size_t								cur_db_session_;

	// 第一次连接上db
	int									first_connect_db_;
};
