#pragma once

#include "perinclude.h"
#include "Singleton.h"
#include "WindowsConsole.h"
#include "GameTimeManager.h"
#include "GameLog.h"
#include "ClientSession.h"
#include "TestPerfLuaScriptManager.h"


class TestPerfManager : public TSingleton < TestPerfManager >
{
public:
	TestPerfManager();

	virtual ~TestPerfManager();

	virtual void startup();

	virtual bool init();
	virtual void run();
	virtual void stop();
	virtual void release();

	std::shared_ptr<NetworkSession> get_session(int client_id);
	NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }

protected:
	std::shared_ptr<NetworkSession> create_client_session(int client_id, const std::string& ip, unsigned short port);

protected:
#ifdef _DEBUG
	WindowsConsole									windows_console_;
#endif // _DEBUG
	std::unique_ptr<GameTimeManager>				game_time_;
	std::unique_ptr<GameLog>						game_log_;

	std::thread										thread_;
	volatile bool									is_run_;

	boost::asio::io_service							ioservice_;
	std::shared_ptr<boost::asio::io_service::work>	work_;
	std::thread										thread_net_;
	std::vector<std::shared_ptr<NetworkSession>>	session_;
	NetworkDispatcherManager						dispatcher_manager_;

	std::unique_ptr<TestPerfLuaScriptManager>		lua_manager_;
};
