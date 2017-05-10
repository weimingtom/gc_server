#pragma once

#include "NetworkServer.h"
#include "NetworkDispatcher.h"
#include "Singleton.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"
#include "common_msg_define.pb.h"

class GateClientSession;
class GateLoginSession;
class GateGameSession;

/**********************************************************************************************//**
 * \class	GateSessionManager
 *
 * \brief	Manager for gate sessions.
 **************************************************************************************************/

class GateSessionManager : public NetworkAllocator, public TSingleton < GateSessionManager >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	GateSessionManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GateSessionManager();

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
	 * \brief	创建game server session.
	 *
	 * \param	ip  	The IP.
	 * \param	port	The port.
	 *
	 * \return	The new game session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_game_session(const std::string& ip, unsigned short port);

	/**********************************************************************************************//**
	 * \brief	设置网络服务器.
	 *
	 * \param [in,out]	network_server	If non-null, the network server.
	 **************************************************************************************************/

	virtual void set_network_server(NetworkServer* network_server);

	/**********************************************************************************************//**
	 * \brief	得到客户端连接GateServer的session.
	 *
	 * \param	guid	Unique identifier.
	 *
	 * \return	The client session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_client_session(int guid);

	/**********************************************************************************************//**
	 * \brief	添加一个客户端连接GateServer的session.
	 *
	 * \param	session	The session.
	 **************************************************************************************************/

	void add_client_session(std::shared_ptr<NetworkSession> session);

	/**********************************************************************************************//**
	 * \brief	删除等于guid客户端连接GateServer的session.
	 *
	 * \param	guid	Unique identifier.
	 **************************************************************************************************/

	void remove_client_session(int guid, int session_id);

	/**********************************************************************************************//**
	 * \brief	得到GateServer连接LoginServer的session.
	 *
	 * \return	The login session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_login_session();

	/**********************************************************************************************//**
	 * \brief	得到等于game_id的GateServer连接GameServer的session.
	 *
	 * \param	game_id	Identifier for the game.
	 *
	 * \return	The game session.
	 **************************************************************************************************/

	std::shared_ptr<NetworkSession> get_game_session(int game_id);

	/**********************************************************************************************//**
	 * \brief	向login发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	guid   	玩家guid.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2login_pb(int guid, T* pb)
	{
		auto session = get_login_session();
		if (session)
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("login server disconnect");
		}
	}

	/**********************************************************************************************//**
	 * \brief	向game发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param	guid	  	Unique identifier.
	 * \param	game_id   	玩家在哪个game server.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2game_pb(int guid, int game_id, T* pb)
	{
		auto session = get_game_session(game_id);
		if (session)
		{
			session->send_xc_pb(guid, pb);
		}
		else
		{
			LOG_WARN("game server[%d] disconnect", game_id);
		}
	}

    /**********************************************************************************************//**
    * \brief	向game发送消息.
    *
    * \tparam	T	Generic type parameter.
    * \param	guid	  	Unique identifier.
    * \param	game_id   	玩家在哪个game server.
    * \param [in,out]	pb	If non-null, the pb.
    **************************************************************************************************/

    template<typename T> void broadcast_client(T* pb)
    {
        for (auto& player : client_session_)
        {
			// auto session = static_cast<GateClientSession*>(player.second.get());
			// session->send_pb(pb);
			player.second->send_pb(pb);
        }
    }
    void SendOnLine();

	// 设置链接到db
	void set_first_connect_db();

	// 第一次连接上db服务器
	virtual void on_first_connect_db();

	//void set_open_game_list(LG_OpenGameList* ls);
	bool in_open_game_list(int id);
	void add_game_id(int game_id);
	void remove_game_id(int game_id);
    void Add_Game_Server_Session(std::string ip, int port);
	void Add_Login_Server_Session(const std::string& ip, int port);
    int find_gameid_by_guid(int guid);

	void add_CL_RegAccount(int gate_id, const CL_RegAccount& msg);
	void add_CL_Login(int gate_id, const CL_Login& msg);
	void add_CL_LoginBySms(int gate_id, const CL_LoginBySms& msg);
	void on_login_quque();
	bool check_login_quque_account(const std::string& account);

protected:
	std::unordered_map<int, std::shared_ptr<NetworkSession>>	client_session_;
	std::vector<std::shared_ptr<NetworkSession>>				login_session_;
	std::vector<std::shared_ptr<NetworkSession>>				game_session_;

	size_t														cur_login_session_;

	// 缓存起来
	std::set<int>												open_game_list_;
	// 第一次连接上db
	int															first_connect_db_;

	// 登陆排队
	std::deque<CL_LoginAll>										login_quque_;
	time_t														login_quque_time_;
	std::unordered_set<std::string>								login_quque_account_;
};
