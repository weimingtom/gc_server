#include "GameLoginSession.h"
#include "GameSession.h"
#include "GameLog.h"
#include "platform_windows.h"
#include "BaseServer.h"
#include "BaseGameServer.h"

GameLoginSession::GameLoginSession(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, dispatcher_manager_(nullptr)
{
}

GameLoginSession::~GameLoginSession()
{
}

bool GameLoginSession::on_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool GameLoginSession::on_connect()
{
	LOG_INFO("game->login accept ... [%s:%d]", ip_.c_str(), port_);

	dispatcher_manager_ = GameSessionManager::instance()->get_dispatcher_manager_login();

	auto& cfg = static_cast<BaseGameServer*>(BaseServer::instance())->get_config();

	S_Connect msg;
	msg.set_type(ServerSessionFromGame);
	msg.set_server_id(cfg.game_id());
	msg.set_first_game_type(cfg.first_game_type());
	msg.set_second_game_type(cfg.second_game_type());
	if (cfg.default_lobby())
		msg.set_default_lobby(true);
	msg.set_player_limit(cfg.player_limit());

	send_pb(&msg);

	return NetworkConnectSession::on_connect();
}

void GameLoginSession::on_connect_failed()
{
	LOG_INFO("game->login connect failed ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_connect_failed();
}

void GameLoginSession::on_closed()
{
	LOG_INFO("game->login disconnect ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_closed();
}

void GameLoginSession::on_wl_request_game_server_info(WL_RequestGameServerInfo* msg)
{
#ifdef PLATFORM_WINDOWS
	// linux todo
	auto& cfg = static_cast<BaseGameServer*>(BaseServer::instance())->get_config();

	SL_WebGameServerInfo notify;
	notify.set_id(msg->id());
	auto p = notify.mutable_info();
	int pid = _getpid();
	p->set_cpu(get_cpu_usage(pid));
	int workingSetSize = 0;
	int peakWorkingSetSize = 0;
	int pagefileUsage = 0;
	int peakPagefileUsage = 0;
	get_memory_info(workingSetSize, peakWorkingSetSize, pagefileUsage, peakPagefileUsage);
	p->set_memory(workingSetSize + pagefileUsage);
	p->set_status(1);
	p->set_ip("127.0.0.1");
	p->set_port(cfg.port());
	p->set_first_game_type(cfg.first_game_type());
	p->set_second_game_type(cfg.second_game_type());

	send_pb(&notify);
#endif
}

void GameLoginSession::on_wl_request_php_gm_cmd_change_money(LS_ChangeMoney * msg)
{
	int webid = msg->webid();
	int playerid = msg->guid();
	//printf("webid = [%d],playerid=[%d]",webid,playerid);
	std::string content = msg->gmcommand();
	auto L = LuaScriptManager::instance()->get_lua_state();
	lua_tinker::dostring(L, content.c_str());
}

void GameLoginSession::on_wl_broadcast_gameserver_gmcommand(WL_BroadcastClientUpdate * msg)
{
	std::string content = msg->gmcommand();
	auto L = LuaScriptManager::instance()->get_lua_state();
	lua_tinker::dostring(L, content.c_str());
}

void GameLoginSession::on_wl_request_LS_LuaCmdPlayerResult(LS_LuaCmdPlayerResult* msg)
{
	auto L = LuaScriptManager::instance()->get_lua_state();
	std::string strtemp = msg->cmd();
	auto pos = strtemp.find("(");
	if (pos == std::string::npos)
	{
		SL_LuaCmdPlayerResult notify;
		notify.set_web_id(msg->web_id());
		notify.set_result(0);
		send_pb(&notify);
		return;
	}

	int login_id = get_server_id();
	std::string cmd = str(boost::format("%d,%d,") % msg->web_id() % login_id);
	cmd = strtemp.substr(0, pos + 1) + cmd + strtemp.substr(pos + 1, -1);

	lua_tinker::dostring(L, cmd.c_str());
}
