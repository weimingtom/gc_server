#include "LoginConfigSession.h"
#include "GameLog.h"
#include "common_enum_define.pb.h"
#include "LoginServer.h"
#include "LoginConfigNetworkServer.h"

LoginConfigSession::LoginConfigSession(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, dispatcher_manager_(nullptr)
{
	dispatcher_manager_ = LoginConfigNetworkServer::instance()->get_dispatcher_manager();
}

LoginConfigSession::~LoginConfigSession()
{
}

bool LoginConfigSession::on_dispatch(MsgHeader* header)
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

bool LoginConfigSession::on_connect()
{
	LOG_INFO("login->config connect success ... [%s:%d]", ip_.c_str(), port_);
	
	if (!static_cast<LoginServer*>(BaseServer::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromLogin);
		msg.set_server_id(static_cast<LoginServer*>(BaseServer::instance())->get_login_id());
		send_pb(&msg);
	}

	return NetworkConnectSession::on_connect();
}

void LoginConfigSession::on_connect_failed()
{
	LOG_INFO("login->config connect failed ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_connect_failed();
}

void LoginConfigSession::on_closed()
{
	LOG_INFO("login->config disconnect ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_closed();
}


void LoginConfigSession::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
	static_cast<LoginServer*>(BaseServer::instance())->on_loadConfigComplete(msg->login_config());

	LOG_INFO("load config complete ltype=%d id=%d\n", msg->type(), msg->server_id());
}

void LoginConfigSession::on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg)
{
	if (static_cast<LoginServer*>(BaseServer::instance())->on_NotifyDBServerStart(msg->db_id()))
	{
		S_RequestUpdateDBServerConfigByLogin request;
		request.set_db_id(msg->db_id());
		send_pb(&request);
	}
}

void LoginConfigSession::on_S_ReplyUpdateDBServerConfigByLogin(S_ReplyUpdateDBServerConfigByLogin* msg)
{
	static_cast<LoginServer*>(BaseServer::instance())->on_UpdateDBConfigComplete(*msg);

	LOG_INFO("load config on_S_ReplyUpdateDBServerConfigByLogin\n");
}


void LoginConfigSession::on_S_Maintain_switch(CS_QueryMaintain* msg)
{
	LOG_INFO("on_S_Maintain_switch  id = [%d],value=[%d]\n", msg->maintaintype(), msg->switchopen());
	int open_switch = msg->switchopen();

	static_cast<LoginServer*>(BaseServer::instance())->set_maintain_switch(open_switch);

}