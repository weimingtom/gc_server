#include "LoginConfigNetworkServer.h"
#include "GameLog.h"
#include "LoginConfigSession.h"

#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, LoginConfigSession >(&LoginConfigSession::Function));

LoginConfigNetworkServer::LoginConfigNetworkServer()
{
	register_login2config_message();
}

LoginConfigNetworkServer::~LoginConfigNetworkServer()
{
}

void LoginConfigNetworkServer::register_login2config_message()
{
	REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyDBServerStart, on_S_NotifyDBServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateDBServerConfigByLogin, on_S_ReplyUpdateDBServerConfigByLogin);
	REG_CONFIG_DISPATCHER(CS_QueryMaintain, on_S_Maintain_switch);
}

void LoginConfigNetworkServer::create_cfg_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<LoginConfigSession>(io_service_);
	session->set_ip_port(ip, port);
	cfg_session_ = std::static_pointer_cast<NetworkConnectSession>(session);
}

void LoginConfigNetworkServer::run()
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

void LoginConfigNetworkServer::join()
{
	thread_.join();
}

void LoginConfigNetworkServer::stop()
{
	if (cfg_session_)
		cfg_session_->close();
	work_ptr_.reset();
	io_service_.stop();
}

void LoginConfigNetworkServer::tick()
{
	if (cfg_session_)
		cfg_session_->tick();
}
