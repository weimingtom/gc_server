#include "GameConfigSession.h"
#include "GameLog.h"
#include "common_enum_define.pb.h"
#include "BaseGameServer.h"
#include "GameConfigNetworkServer.h"

GameConfigSession::GameConfigSession(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, dispatcher_manager_(nullptr)
{
	dispatcher_manager_ = GameConfigNetworkServer::instance()->get_dispatcher_manager();
}

GameConfigSession::~GameConfigSession()
{
}

bool GameConfigSession::on_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool GameConfigSession::on_connect()
{
	LOG_INFO("login->config connect success ... [%s:%d]", ip_.c_str(), port_);
	
	if (!static_cast<BaseGameServer*>(BaseServer::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromGame);
		msg.set_server_id(static_cast<BaseGameServer*>(BaseServer::instance())->get_game_id());
		send_pb(&msg);
	}

	return NetworkConnectSession::on_connect();
}

void GameConfigSession::on_connect_failed()
{
	LOG_INFO("login->config connect failed ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_connect_failed();
}

void GameConfigSession::on_closed()
{
	LOG_INFO("login->config disconnect ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_closed();
}


void GameConfigSession::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<BaseGameServer*>(BaseServer::instance())->on_loadConfigComplete(msg->game_config());

	LOG_INFO("load config complete ltype=%d id=%d\n", msg->type(), msg->server_id());
}

void GameConfigSession::on_S_NotifyLoginServerStart(S_NotifyLoginServerStart* msg)
{
	if (static_cast<BaseGameServer*>(BaseServer::instance())->on_NotifyLoginServerStart(msg->login_id()))
	{
		S_RequestUpdateLoginServerConfigByGame request;
		request.set_login_id(msg->login_id());
		send_pb(&request);
	}
}

void GameConfigSession::on_S_ReplyUpdateLoginServerConfigByGame(S_ReplyUpdateLoginServerConfigByGame* msg)
{
	static_cast<BaseGameServer*>(BaseServer::instance())->on_UpdateLoginConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateLoginServerConfigByGame\n");
}

void GameConfigSession::on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg)
{
	if (static_cast<BaseGameServer*>(BaseServer::instance())->on_NotifyDBServerStart(msg->db_id()))
	{
		S_RequestUpdateDBServerConfigByGame request;
		request.set_db_id(msg->db_id());
		send_pb(&request);
	}
}

void GameConfigSession::on_S_ReplyUpdateDBServerConfigByGame(S_ReplyUpdateDBServerConfigByGame* msg)
{
	static_cast<BaseGameServer*>(BaseServer::instance())->on_UpdateDBConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateDBServerConfigByGame\n");
}
