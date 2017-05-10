#pragma once

#include "perinclude.h"
#include "NetworkConnectSession.h"
#include "NetworkDispatcher.h"

class DBConfigNetworkServer : public TSingleton < DBConfigNetworkServer >
{
public:
    DBConfigNetworkServer();

    ~DBConfigNetworkServer();

    void register_login2config_message();

    void create_cfg_session(const std::string& ip, unsigned short port);
    NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }

    void run();
    void join();
    void stop();

    void tick();

    template<typename T> void send2db_pb(T* pb)
    {
        auto session = get_db_session();
        if (session)
        {
            session->send_pb(pb);
        }
        else
        {
            LOG_WARN("db server disconnect");
        }
    }

    template<typename T> void send2cfg_pb(T* pb)
    {
        if (cfg_session_)
        {
            cfg_session_->send_pb(pb);
        }
        else
        {
            LOG_WARN("db server disconnect");
        }
    }

protected:
private:
    boost::asio::io_service					io_service_;
    std::unique_ptr<boost::asio::io_service::work> work_ptr_;
    std::thread								thread_;

    std::shared_ptr<NetworkSession>			cfg_session_;

    NetworkDispatcherManager				dispatcher_manager_;
};
