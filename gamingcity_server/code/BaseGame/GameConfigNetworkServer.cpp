#include "GameConfigNetworkServer.h"
#include "GameLog.h"
#include "GameConfigSession.h"

#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, GameConfigSession >(&GameConfigSession::Function));

GameConfigNetworkServer::GameConfigNetworkServer()
{
	register_login2config_message();
}

GameConfigNetworkServer::~GameConfigNetworkServer()
{
}

void GameConfigNetworkServer::register_login2config_message()
{
	REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
	REG_CONFIG_DISPATCHER(S_NotifyLoginServerStart, on_S_NotifyLoginServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateLoginServerConfigByGame, on_S_ReplyUpdateLoginServerConfigByGame);
	REG_CONFIG_DISPATCHER(S_NotifyDBServerStart, on_S_NotifyDBServerStart);
	REG_CONFIG_DISPATCHER(S_ReplyUpdateDBServerConfigByGame, on_S_ReplyUpdateDBServerConfigByGame);
}

void GameConfigNetworkServer::create_cfg_session(const std::string& ip, unsigned short port)
{
	auto session = std::make_shared<GameConfigSession>(io_service_);
	session->set_ip_port(ip, port);
	cfg_session_ = std::static_pointer_cast<NetworkConnectSession>(session);
}

void GameConfigNetworkServer::run()
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

void GameConfigNetworkServer::join()
{
	thread_.join();
}

void GameConfigNetworkServer::stop()
{
	if (cfg_session_)
		cfg_session_->close();
	work_ptr_.reset();
	io_service_.stop();
}

void GameConfigNetworkServer::tick()
{
	if (cfg_session_)
		cfg_session_->tick();
}
