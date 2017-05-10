#pragma once

#include "NetworkServer.h"
#include "NetworkDispatcher.h"
#include "Singleton.h"

class LoginSession;
class LoginDBSession;
class LOginSmsSession;

/**********************************************************************************************//**
 * \class	LoginSessionManager
 *
 * \brief	Manager for login sessions.
 **************************************************************************************************/

class LoginSessionManager : public NetworkAllocator, public TSingleton < LoginSessionManager >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	LoginSessionManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~LoginSessionManager();

	/**********************************************************************************************//**
	 * \brief	注册服务器连接消息的处理函数.
	 **************************************************************************************************/

	void register_connect_message();

	/**********************************************************************************************//**
	 * \brief	注册GateServer连接到LoginServer的消息的处理函数.
	 **************************************************************************************************/

	void register_gate2login_message();

	/**********************************************************************************************//**
	 * \brief	注册GameServer连接到LoginServer的消息的处理函数.
	 **************************************************************************************************/

	void register_game2login_message();

	/**********************************************************************************************//**
	 * \brief	注册LoginServer连接到DBServer的消息的处理函数.
	 **************************************************************************************************/

	void register_login2db_message();
	
	/**********************************************************************************************//**
	 * \brief	注册GmServer连接到LoginServer的消息的处理函数.
	 **************************************************************************************************/

	void register_web2login_message();

	/**********************************************************************************************//**
	 * \brief	注册LoginServer连接到SmsServer的消息的处理函数.
	 **************************************************************************************************/

	void register_login2sms_message();

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
	 * \brief	得到gate连接login的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager gate.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_gate() { return &dispatcher_manager_gate_; }

	/**********************************************************************************************//**
	 * \brief	得到game连接login的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager gate.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_game() { return &dispatcher_manager_game_; }

	/**********************************************************************************************//**
	 * \brief	得到login连接db的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager database.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_db() { return &dispatcher_manager_db_; }

	/**********************************************************************************************//**
	 * \brief	得到web连接login的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager web.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager_web() { return &dispatcher_manager_web_; }

	/**********************************************************************************************//**
	 * \brief	得到gate连接login的session.
	 *
	 * \param	server_id	Identifier for the server.
	 *
	 * \return	The gate session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_gate_session(int server_id);

	/**********************************************************************************************//**
	 * \brief	添加gate连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_gate_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除gate连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void del_gate_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	得到game连接login的session.
	 *
	 * \param	server_id	Identifier for the server.
	 *
	 * \return	The game session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_game_session(int server_id);

	/**********************************************************************************************//**
	 * \brief	添加game连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_game_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除game连接login的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void del_game_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	得到login连接db的session.
	 *
	 * \return	The database session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_db_session();

	/**********************************************************************************************//**
	 * \brief	向db server发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2db_pb(T* pb)
	{
		auto session = get_db_session();
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("db server disconnect");
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
    /**********************************************************************************************//**
    * \brief	向gate发送消息.
    *
    * \tparam	T	Generic type parameter.
    * \param [in,out]	pb	If non-null, the pb.
    **************************************************************************************************/
    template<typename T> bool sendgate_All( T* pb)
    {
        for (auto item : gate_session_)
        {
            if (item)
            {
                return item->send_pb(pb);
            }
            else
            {
                LOG_WARN("gate server[%d] disconnect", item->get_server_id());
            }
        }
        return false;
    }
	/**********************************************************************************************//**
	 * \brief	向gate发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	gate_id   	玩家在哪个gate server.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> bool send2gate_pb(int gate_id, T* pb)
	{
		auto session = get_gate_session(gate_id);
		if (session)
		{
			return session->send_pb(pb);
		}
		else
		{
			LOG_WARN("gate server[%d] disconnect", gate_id);
		}
		return false;
	}

	/**********************************************************************************************//**
	 * \brief	向gate广播消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> int broadcast2gate_pb(T* pb)
	{
		for (auto session : gate_session_)
		{
			session->send_pb(pb);
		}
		return (int)gate_session_.size();
	}
	
	/**********************************************************************************************//**
	 * \brief	向game发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	guid	  	Unique identifier.
	 * \param	game_id   	玩家在哪个game server.
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

	/**********************************************************************************************//**
	 * \brief	向game广播消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> int broadcast2game_pb(T* pb)
	{
		for (auto session : game_session_)
		{
			session->send_pb(pb);
		}
		return (int)game_session_.size();
	}

	/**********************************************************************************************//**
	 * \brief	向web发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2web_pb(int id, T* pb)
	{
		auto session = find_by_id(id);
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("web server[%d] disconnect", id);
		}
	}

	/**********************************************************************************************//**
	 * \brief	添加一个服务器的信息.
	 **************************************************************************************************/

	void add_game_server_info(int game_id, int first_game_type, int second_game_type, bool default_lobby, int player_limit);

	/**********************************************************************************************//**
	 * \brief	删除一个服务器的信息.
	 **************************************************************************************************/

	void remove_game_server_info(int game_id);

	/**********************************************************************************************//**
	 * \brief	判断是否有一个服务器的信息.
	 **************************************************************************************************/

	bool has_game_server_info(int game_id);

	/**********************************************************************************************//**
	 * \brief	更新服务器的玩家数量信息.
	 **************************************************************************************************/

	void update_game_server_player_count(int game_id, int count);

	/**********************************************************************************************//**
	 * \brief	查找一个默认大厅的game_id.
	 **************************************************************************************************/

	int find_a_default_lobby();
	
	/**********************************************************************************************//**
	 * \brief	打印游戏配置.
	 **************************************************************************************************/

	void print_game_server_info();

	/**********************************************************************************************//**
	 * \brief	查找一个相关房间的game_id.
	 **************************************************************************************************/

	int find_a_game_id(int first_game_type, int second_game_type);

	/**********************************************************************************************//**
	 * \brief	向gate server发送开启列表消息.
	 **************************************************************************************************/

	//void send_open_game_list(std::shared_ptr<NetworkSession> session);
	
	/**********************************************************************************************//**
	 * \brief	向gate server广播开启列表消息.
	 **************************************************************************************************/

	//void broadcast_open_game_list();

	// 设置链接到db
	void set_first_connect_db();

	// 是否连接了db
	bool is_first_connect_db();

	// 第一次连接上db服务器
	virtual void on_first_connect_db();

	void Add_DB_Server_Session(const std::string& ip, int port);
protected:
	NetworkDispatcherManager			dispatcher_manager_;
	NetworkDispatcherManager			dispatcher_manager_gate_;
	NetworkDispatcherManager			dispatcher_manager_game_;
	NetworkDispatcherManager			dispatcher_manager_db_;
	NetworkDispatcherManager			dispatcher_manager_web_;

	std::vector<std::shared_ptr<NetworkSession>> gate_session_;
	std::vector<std::shared_ptr<NetworkSession>> game_session_;
	std::vector<std::shared_ptr<NetworkSession>> db_session_;

	size_t								cur_db_session_;

	// 第一次连接上db
	int									first_connect_db_;

	struct RegGameServerInfo
	{
		int first_game_type;			// 一级菜单
		int second_game_type; 			// 二级菜单，跟据配置文件
		bool default_lobby; 			// 是否是默认大厅
		int player_limit; 				// 玩家人数限制
		int cur_player_count;			// 当前玩家数量
	};
	std::map<int, RegGameServerInfo>	reg_game_server_info_;
	std::recursive_mutex				mutex_reg_game_server_info_;
};
