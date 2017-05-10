#include "GateConfigNetworkServer.h"
#include "GameLog.h"
#include "GateConfigSession.h"

#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, GateConfigSession >(&GateConfigSession::Function));

GateConfigNetworkServer::GateConfigNetworkServer()
{
	register_login2config_message();
}

GateConfigNetworkServer::~GateConfigNetworkServer()
{
}

void GateConfigNetworkServer::register_login2config_message()
{
	REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyGameServerStart, on_S_NotifyGameServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateGameServerConfig, on_S_ReplyUpdateGameServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyLoginServerStart, on_S_NotifyLoginServerStart);
    REG_CONFIG_DISPATCHER(S_ReplyUpdateLoginServerConfigByGate, on_S_ReplyUpdateLoginServerConfigByGate);
    REG_CONFIG_DISPATCHER(FG_GameServerCfg, on_FG_GameServerCfg);
    REG_CONFIG_DISPATCHER(FS_ChangMoneyDeal, on_FS_ChangMoneyDeal);
}

void GateConfigNetworkServer::create_cfg_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GateConfigSession>(io_service_);
	session->set_ip_port(ip, port);
	cfg_session_ = std::static_pointer_cast<NetworkConnectSession>(session);
}

void GateConfigNetworkServer::run()
{
	work_ptr_ = std::move(std::unique_ptr<boost::asio::io_service::work>(new boost::asio::io_service::work(io_service_)));
	
	thread_ = std::thread([this]() {
		try
		{
			io_service_.run();
		}
		catch (const std::exception& e)
		{
			LOG_ERR(e.what());
		}
	});
}

void GateConfigNetworkServer::join()
{
	thread_.join();
}

void GateConfigNetworkServer::stop()
{
	if (cfg_session_)
		cfg_session_->close();
	work_ptr_.reset();
	io_service_.stop();
}

void GateConfigNetworkServer::tick()
{
	if (cfg_session_)
		cfg_session_->tick();
}
