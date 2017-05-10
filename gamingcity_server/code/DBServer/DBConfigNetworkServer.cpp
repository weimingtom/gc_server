#include "DBConfigNetworkServer.h"
#include "GameLog.h"
#include "DBConfigSession.h"

#define REG_CONFIG_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, DBConfigSession >(&DBConfigSession::Function));

DBConfigNetworkServer::DBConfigNetworkServer()
{
    register_login2config_message();
}

DBConfigNetworkServer::~DBConfigNetworkServer()
{
}

void DBConfigNetworkServer::register_login2config_message()
{
    REG_CONFIG_DISPATCHER(S_ReplyServerConfig, on_S_ReplyServerConfig);
    REG_CONFIG_DISPATCHER(FD_ChangMoney, on_fd_changemoney);
    REG_CONFIG_DISPATCHER(FD_ChangMoneyDeal, on_fd_changemoneydeal);
    
}

void DBConfigNetworkServer::create_cfg_session(const std::string& ip, unsigned short port)
{
    auto session = std::make_shared<DBConfigSession>(io_service_);
    session->set_ip_port(ip, port);
    cfg_session_ = std::static_pointer_cast<NetworkConnectSession>(session);
}

void DBConfigNetworkServer::run()
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

void DBConfigNetworkServer::join()
{
    thread_.join();
}

void DBConfigNetworkServer::stop()
{
    if (cfg_session_)
        cfg_session_->close();
    work_ptr_.reset();
    io_service_.stop();
}

void DBConfigNetworkServer::tick()
{
    if (cfg_session_)
        cfg_session_->tick();
}
