#include "GateConfigSession.h"
#include "GameLog.h"
#include "common_enum_define.pb.h"
#include "GateServer.h"
#include "GateConfigNetworkServer.h"

GateConfigSession::GateConfigSession(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, dispatcher_manager_(nullptr)
{
	dispatcher_manager_ = GateConfigNetworkServer::instance()->get_dispatcher_manager();
}

GateConfigSession::~GateConfigSession()
{
}

bool GateConfigSession::on_dispatch(MsgHeader* header)
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

bool GateConfigSession::on_connect()
{
	LOG_INFO("login->config connect success ... [%s:%d]", ip_.c_str(), port_);
    GateSessionManager::instance()->SendOnLine();
	if (!static_cast<GateServer*>(BaseServer::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromGate);
		msg.set_server_id(static_cast<GateServer*>(BaseServer::instance())->get_gate_id());
		send_pb(&msg);
	}

	return NetworkConnectSession::on_connect();
}

void GateConfigSession::on_connect_failed()
{
	LOG_INFO("login->config connect failed ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_connect_failed();
}

void GateConfigSession::on_closed()
{
	LOG_INFO("login->config disconnect ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_closed();
}

void GateConfigSession::on_FS_ChangMoneyDeal(FS_ChangMoneyDeal * msg)
{
    LOG_INFO("on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    FS_ChangMoneyDeal nmsg;
    nmsg.set_web_id(msg->web_id());
    AddMoneyInfo *info = nmsg.mutable_info();
    info->CopyFrom(msg->info());
    int Server_ID = GateSessionManager::instance()->find_gameid_by_guid(msg->info().guid());
    if (Server_ID == -1)
    {
        LOG_INFO("on_FS_ChangMoneyDeal  %d no find", msg->info().guid());
        GateConfigNetworkServer::instance()->send2cfg_pb(&nmsg);
    }
    else
    {
        auto session = GateSessionManager::instance()->get_game_session(Server_ID);
        if (session)
        {
            LOG_INFO("on_FS_ChangMoneyDeal  %d  find session %d", msg->info().guid(), Server_ID);
            session->send_pb(&nmsg);
        }
        else
        {
            LOG_INFO("on_FS_ChangMoneyDeal  %d no find session %d", msg->info().guid(), Server_ID);
            GateConfigNetworkServer::instance()->send2cfg_pb(&nmsg);
        }
    }
}
void GateConfigSession::on_FG_GameServerCfg(FG_GameServerCfg * msg)
{
    //·¢ËÍ
    GC_GameServerCfg notify;
    for (auto& item : static_cast<GateServer*>(BaseServer::instance())->get_gamecfg().pb_cfg())
    {
        if (item.game_id() == msg->pb_cfg().game_id())
        {
            auto dbcfg = const_cast<GameClientRoomListCfg *>(&(item));
            dbcfg->CopyFrom(msg->pb_cfg());
        }
        if (GateSessionManager::instance()->in_open_game_list(item.game_id()))
        {
            notify.add_pb_cfg()->CopyFrom(item);
        }
    }

    GateSessionManager::instance()->broadcast_client(&notify);
}
void GateConfigSession::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<GateServer*>(BaseServer::instance())->on_loadConfigComplete(*msg);

	LOG_INFO("load config complete ltype=%d id=%d\n", msg->type(), msg->server_id());
}

void GateConfigSession::on_S_NotifyGameServerStart(S_NotifyGameServerStart* msg)
{
	if (static_cast<GateServer*>(BaseServer::instance())->on_NotifyGameServerStart(msg->game_id()))
	{
		S_RequestUpdateGameServerConfig request;
		request.set_game_id(msg->game_id());
		send_pb(&request);
	}
}

void GateConfigSession::on_S_ReplyUpdateGameServerConfig(S_ReplyUpdateGameServerConfig* msg)
{
	static_cast<GateServer*>(BaseServer::instance())->on_UpdateConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateGameServerConfig\n");
}

void GateConfigSession::on_S_NotifyLoginServerStart(S_NotifyLoginServerStart* msg)
{
	if (static_cast<GateServer*>(BaseServer::instance())->on_NotifyLoginServerStart(msg->login_id()))
	{
		S_RequestUpdateLoginServerConfigByGate request;
		request.set_login_id(msg->login_id());
		send_pb(&request);
	}
}

void GateConfigSession::on_S_ReplyUpdateLoginServerConfigByGate(S_ReplyUpdateLoginServerConfigByGate* msg)
{
	static_cast<GateServer*>(BaseServer::instance())->on_UpdateLoginConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateLoginServerConfigByGate\n");
}
