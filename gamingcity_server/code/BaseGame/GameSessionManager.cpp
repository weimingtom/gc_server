#include "GameSessionManager.h"
#include "GameSession.h"
#include "GameLoginSession.h"
#include "GameDBSession.h"
#include "LuaScriptManager.h"
#include "BaseGameServer.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#define REG_GATE_DISPATCHER(Msg, Function) dispatcher_manager_gate_.register_dispatcher(new GateMsgDispatcher< Msg, GameSession >(&GameSession::Function));
#define REG_LOGIN_DISPATCHER(Msg, Function) dispatcher_manager_login_.register_dispatcher(new MsgDispatcher< Msg, GameLoginSession >(&GameLoginSession::Function));
#define REG_GAME_DISPATCHER(Msg, Function) dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher<Msg,GameSession>(&GameSession::Function));
GameSessionManager::GameSessionManager()
	: cur_login_session_(0)
	, cur_db_session_(0)
	, first_connect_db_(0)
{
	register_connect_message();
	register_game2login_message();
	register_gate2game_message();
	register_game2db_message();
}

GameSessionManager::~GameSessionManager()
{
}

void GameSessionManager::register_connect_message()
{
	dispatcher_manager_.register_dispatcher(new MsgDispatcher<S_Connect, GameSession>(&GameSession::on_s_connect));
}

void GameSessionManager::register_game2login_message()
{
	REG_LOGIN_DISPATCHER(WL_RequestGameServerInfo, on_wl_request_game_server_info);
	REG_LOGIN_DISPATCHER(LS_ChangeMoney, on_wl_request_php_gm_cmd_change_money);
	REG_LOGIN_DISPATCHER(WL_BroadcastClientUpdate, on_wl_broadcast_gameserver_gmcommand);
	REG_LOGIN_DISPATCHER(LS_LuaCmdPlayerResult, on_wl_request_LS_LuaCmdPlayerResult);
}

void GameSessionManager::register_gate2game_message()
{
	dispatcher_manager_gate_.register_dispatcher(new MsgDispatcher< S_Logout, GameSession >(&GameSession::on_s_logout));
}

void GameSessionManager::register_game2db_message()
{
}

void GameSessionManager::close_all_session()
{
	NetworkAllocator::close_all_session();
	
	for (auto item : login_session_)
		item->close();

	for (auto item : db_session_)
		item->close();
}

void GameSessionManager::release_all_session()
{
	NetworkAllocator::release_all_session();

	for (auto item : login_session_)
	{
		item->on_closed();
	}
	login_session_.clear();

	for (auto item : db_session_)
	{
		item->on_closed();
	}
	db_session_.clear();
}

bool GameSessionManager::tick()
{
	bool ret = NetworkAllocator::tick();

	for (auto item : login_session_)
	{
		if (!item->tick())
			ret = false;
	}

	for (auto item : db_session_)
	{
		if (!item->tick())
			ret = false;
	}

	if (first_connect_db_ == 1)
	{
		on_first_connect_db();
		first_connect_db_ = 2;
	}

	return ret;
}

std::shared_ptr<NetworkSession> GameSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<GameSession>(socket));
}

std::shared_ptr<NetworkSession> GameSessionManager::create_login_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GameLoginSession>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<NetworkSession>(session);
}

std::shared_ptr<NetworkSession> GameSessionManager::create_db_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GameDBSession>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<NetworkSession>(session);
}

void GameSessionManager::set_network_server(NetworkServer* network_server)
{
	NetworkAllocator::set_network_server(network_server);

	auto& cfg = static_cast<BaseGameServer*>(BaseServer::instance())->get_config();

	for (auto& attr : cfg.login_addr())
	{
		login_session_.push_back(create_login_session(attr.ip(), attr.port()));
	}

	for (auto& attr : cfg.db_addr())
	{
		db_session_.push_back(create_db_session(attr.ip(), attr.port()));
	}
}

std::shared_ptr<NetworkSession> GameSessionManager::get_db_session()
{
	if (db_session_.empty())
		return std::shared_ptr<NetworkSession>();

	if (cur_db_session_ >= db_session_.size())
		cur_db_session_ = 0;

	return db_session_[cur_db_session_++];
}

std::shared_ptr<NetworkSession> GameSessionManager::get_login_session(int login_id)
{
    for (auto item : login_session_)
    {
        if (item->get_server_id() == login_id)
            return item;
    }
    return std::shared_ptr<NetworkSession>();
}

std::shared_ptr<NetworkSession> GameSessionManager::get_login_session()
{
	if (login_session_.empty())
		return std::shared_ptr<NetworkSession>();

	if (cur_login_session_ >= login_session_.size())
		cur_login_session_ = 0;

	return login_session_[cur_login_session_++];
}

void GameSessionManager::add_login_session(std::shared_ptr<NetworkSession> session)
{
	login_session_.push_back(session);
}

void GameSessionManager::del_login_session(std::shared_ptr<NetworkSession> session)
{
	for (auto it = login_session_.begin(); it != login_session_.end(); ++it)
	{
		if (*it == session)
		{
			login_session_.erase(it);
			break;
		}
	}
}

std::shared_ptr<NetworkSession> GameSessionManager::get_gate_session(int server_id)
{
	for (auto item : gate_session_)
	{
		if (item->get_server_id() == server_id)
			return item;
	}
	return std::shared_ptr<NetworkSession>();
}

void GameSessionManager::add_gate_session(std::shared_ptr<NetworkSession> session)
{
	gate_session_.push_back(session);
}

void GameSessionManager::del_gate_session(std::shared_ptr<NetworkSession> session)
{
	for (auto it = gate_session_.begin(); it != gate_session_.end(); ++it)
	{
		if (*it == session)
		{
			gate_session_.erase(it);
			break;
		}
	}
}

void GameSessionManager::broadcast_player_count(int count)
{
	S_UpdateGamePlayerCount msg;
	msg.set_cur_player_count(count);

	for (auto session : login_session_)
	{
		session->send_pb(&msg);
	}
}

void GameSessionManager::set_first_connect_db()
{
	if (first_connect_db_ == 0)
	{
		first_connect_db_ = 1;
	}
}

void GameSessionManager::on_first_connect_db()
{
	lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), "on_first_connect_db");

    printf(">>>>>>>>>>>>>>>>>>> on_first_connect_db\n");
    /*int game_id = static_cast<BaseGameServer*>(BaseServer::instance())->get_config().game_id();
    SD_ServerConfig msg;
    msg.set_gamer_id(game_id);
    auto session = get_db_session();
    session->send_pb(&msg);*/
}

void GameSessionManager::Add_Login_Server_Session(const std::string& ip, int port)
{
	login_session_.push_back(create_login_session(ip, port));
}

void GameSessionManager::Add_DB_Server_Session(const std::string& ip, int port)
{
	db_session_.push_back(create_db_session(ip, port));
}
