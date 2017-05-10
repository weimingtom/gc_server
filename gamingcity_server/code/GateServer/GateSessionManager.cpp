#include "GateSessionManager.h"
#include "GateClientSession.h"
#include "GateLoginSession.h"
#include "GateGameSession.h"
#include "GateServerConfigManager.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include "GateServer.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

GateSessionManager::GateSessionManager()
	: cur_login_session_(0)
	, first_connect_db_(0)
{
}

GateSessionManager::~GateSessionManager()
{
	assert(game_session_.empty());
}

void GateSessionManager::close_all_session()
{
	NetworkAllocator::close_all_session();

	for (auto item : login_session_)
		item->close();

	for (auto item : game_session_)
		item->close();
}

void GateSessionManager::release_all_session()
{
	NetworkAllocator::release_all_session();

	for (auto item : login_session_)
	{
		item->on_closed();
	}
	login_session_.clear();

	for (auto item : game_session_)
	{
		item->on_closed();
	}
	game_session_.clear();
}

bool GateSessionManager::tick()
{
	bool ret = NetworkAllocator::tick();

	for (auto item : login_session_)
	{
		if (!item->tick())
			ret = false;
	}

	for (auto item : game_session_)
	{
		if (!item->tick())
			ret = false;
	}
	if (first_connect_db_ == 1)
	{
		on_first_connect_db();
		first_connect_db_ = 2;
	}
	on_login_quque();
	return ret;
}

std::shared_ptr<NetworkSession> GateSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<GateClientSession>(socket));
}


std::shared_ptr<NetworkSession> GateSessionManager::create_login_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GateLoginSession>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<NetworkSession>(session);
}

std::shared_ptr<NetworkSession> GateSessionManager::create_game_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GateGameSession>(network_server_->get_io_server_pool().get_io_service());
	session->set_ip_port(ip, port);
	return std::static_pointer_cast<NetworkSession>(session);
}

void GateSessionManager::set_network_server(NetworkServer* network_server)
{
	NetworkAllocator::set_network_server(network_server);

	auto& cfg = static_cast<GateServer*>(BaseServer::instance())->get_config();

	for (auto& attr : cfg.login_addr())
	{
		login_session_.push_back(create_login_session(attr.ip(), attr.port()));
	}

	for (auto& attr : cfg.game_addr())
	{
        Add_Game_Server_Session(attr.ip(), attr.port());
	}
}
void GateSessionManager::Add_Game_Server_Session(std::string ip, int port){
    game_session_.push_back(create_game_session(ip, port));
}

void GateSessionManager::Add_Login_Server_Session(const std::string& ip, int port)
{
	login_session_.push_back(create_login_session(ip, port));
}
std::shared_ptr<NetworkSession> GateSessionManager::get_client_session(int guid)
{
	auto it = client_session_.find(guid);
	if (it != client_session_.end())
		return it->second;

	return std::shared_ptr<NetworkSession>();
}
void GateSessionManager::add_client_session(std::shared_ptr<NetworkSession> session)
{
	//client_session_.insert(std::make_pair(static_cast<GateClientSession*>(session.get())->get_guid(), session));
	client_session_[static_cast<GateClientSession*>(session.get())->get_guid()] = session;
}

void GateSessionManager::remove_client_session(int guid, int session_id)
{
	auto it = client_session_.find(guid);
	if (it != client_session_.end() && static_cast<GateClientSession*>(it->second.get())->get_id() == session_id)
	{
		client_session_.erase(guid);
	}
}

int GateSessionManager::find_gameid_by_guid(int guid)
{
    auto it = client_session_.find(guid);
    if (it != client_session_.end())
    {
        auto session = static_cast<GateClientSession*>(it->second.get());
        return session->get_game_server_id();
    }
    else
    {
        return -1;
    }
}

void GateSessionManager::SendOnLine()
{
    for (auto& player : client_session_)
    {
        GF_PlayerIn nmsg;
        nmsg.set_guid(player.first);
        GateConfigNetworkServer::instance()->send2cfg_pb(&nmsg);
    }
}
std::shared_ptr<NetworkSession> GateSessionManager::get_login_session()
{
	if (login_session_.empty())
		return std::shared_ptr<NetworkSession>();

	if (cur_login_session_ >= login_session_.size())
		cur_login_session_ = 0;

	return login_session_[cur_login_session_++];
}

std::shared_ptr<NetworkSession> GateSessionManager::get_game_session(int game_id)
{
	for (auto item : game_session_)
	{
		if (item->get_server_id() == game_id)
			return item;
	}

	return std::shared_ptr<NetworkSession>();
}

/*void GateSessionManager::set_open_game_list(LG_OpenGameList* ls)
{
	open_game_list_.clear();
	for (auto id : ls->game_id_list())
	{
		open_game_list_.insert(id);
	}
}*/

bool GateSessionManager::in_open_game_list(int id)
{
	return open_game_list_.find(id) != open_game_list_.end();
}

void GateSessionManager::add_game_id(int game_id)
{
	open_game_list_.insert(game_id);
}

void GateSessionManager::remove_game_id(int game_id)
{
	open_game_list_.erase(game_id);
}

void GateSessionManager::set_first_connect_db()
{
	if (first_connect_db_ == 0)
	{
		first_connect_db_ = 1;
	}
}

void GateSessionManager::on_first_connect_db()
{
    printf(">>>>>>>>>>>>>>>>>>> on_first_connect_db\n");
    GL_GetServerCfg msg;

    // 登录时，没有guid，做过特殊处理
    auto session = GateSessionManager::instance()->get_login_session();
    if (session)
    {
        GateSessionManager::instance()->send2login_pb(1, &msg);
    }
    else
    {
        LOG_WARN("login server disconnect");
    }
}

void GateSessionManager::add_CL_RegAccount(int gate_id, const CL_RegAccount& msg)
{
	CL_LoginAll a;
	a.set_type(1);
	a.set_gate_id(gate_id);
	a.mutable_reg()->CopyFrom(msg);
	login_quque_.push_back(a);
}
void GateSessionManager::add_CL_Login(int gate_id, const CL_Login& msg)
{
	CL_LoginAll a;
	a.set_type(2);
	a.set_gate_id(gate_id);
	a.mutable_login()->CopyFrom(msg);
	login_quque_.push_back(a);

	login_quque_account_.insert(msg.account());
}
void GateSessionManager::add_CL_LoginBySms(int gate_id, const CL_LoginBySms& msg)
{
	CL_LoginAll a;
	a.set_type(3);
	a.set_gate_id(gate_id);
	a.mutable_sms()->CopyFrom(msg);
	login_quque_.push_back(a);

	login_quque_account_.insert(msg.account());
}
void GateSessionManager::on_login_quque()
{
	if (login_quque_time_ == 0 || GameTimeManager::instance()->get_second_time() - login_quque_time_ >= 1)
	{
		login_quque_time_ = GameTimeManager::instance()->get_second_time();

		for (int i = 0; i < 25; i++)
		{
			if (login_quque_.empty())
			{
				break;
			}
			auto& item = login_quque_.front();
			switch (item.type())
			{
			case 1:
				if (item.has_reg())
				{
					auto s = GateSessionManager::instance()->find_by_id(item.gate_id());
					if (s)
					{
						GateSessionManager::instance()->send2login_pb(item.gate_id(), item.mutable_reg());
					}
				}
				break;
			case 2:
				if (item.has_login())
				{
					auto s = GateSessionManager::instance()->find_by_id(item.gate_id());
					if (s)
					{
						GateSessionManager::instance()->send2login_pb(item.gate_id(), item.mutable_login());
					}
					login_quque_account_.erase(item.mutable_login()->account());
				}
			case 3:
				if (item.has_sms())
				{
					auto s = GateSessionManager::instance()->find_by_id(item.gate_id());
					if (s)
					{
						GateSessionManager::instance()->send2login_pb(item.gate_id(), item.mutable_sms());
					}
					login_quque_account_.erase(item.mutable_sms()->account());
				}
			default:
				break;
			}
			login_quque_.pop_front();
		}
	}
}

bool GateSessionManager::check_login_quque_account(const std::string& account)
{
	return login_quque_account_.find(account) != login_quque_account_.end();
}
