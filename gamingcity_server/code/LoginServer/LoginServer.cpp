// LoginServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"

#include "LoginServer.h"
#include <google/protobuf/text_format.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

LoginServer::LoginServer()
	: login_id_(1)
	, init_config_server_(false)
	, first_network_server_(true)
{
}

LoginServer::~LoginServer()
{
}

bool LoginServer::init()
{	
	if (!BaseServer::init())
		return false;

	std::string filename = "../log/%d-%d-%d login" + boost::lexical_cast<std::string>(get_login_id()) + ".log";
	GameLog::instance()->init(filename.c_str());

	// 从网络读取配置
	config_server_ = std::move(std::unique_ptr<LoginConfigNetworkServer>(new LoginConfigNetworkServer));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());

	config_server_->run();

	return true;
}

void LoginServer::on_loadConfigComplete(const LoginServerConfigInfo& cfg)
{
	if (init_config_server_)
		return;

	login_config_.CopyFrom(cfg);

	sesssion_manager_ = std::move(std::unique_ptr<LoginSessionManager>(new LoginSessionManager));
	network_server_ = std::move(std::unique_ptr<NetworkServer>(new NetworkServer(login_config_.port(), get_core_count(), sesssion_manager_.get())));

	redis_conn_ = std::move(std::unique_ptr<RedisConnectionThread>(new RedisConnectionThread));
	{
		auto& cfg_sentinel = login_config_.def_sentinel();
		if (cfg_sentinel.size() > 0)
		{
			for (auto& sentinel : cfg_sentinel)
			{
				redis_conn_->add_sentinel(sentinel.ip(), sentinel.port(), sentinel.master_name(), sentinel.dbnum(), sentinel.password());
			}
			redis_conn_->connect_sentinel();
		}
		else
		{
			auto& cfg = login_config_.def_redis();
			if (cfg.has_ip())
			{
				std::string master_name_tmp;
				redis_conn_->set_master_info(cfg.ip(), cfg.port(), master_name_tmp, cfg.dbnum(), cfg.password());
			}
		}
	}
	redis_conn_->start();

	init_config_server_ = true;
}

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
int __stdcall seh_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"LoginServer_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void LoginServer::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
		while (is_run_)
		{
			DWORD t0 = GetTickCount();
			DWORD t;
			bool b_sleep = true;
			if (init_config_server_)
			{
				// 启动网络线程
				if (first_network_server_)
				{
					network_server_->run();
					first_network_server_ = false;
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("tick guard step 1 start net:%d", t - t0);
						t0 = t;
					}
				}

				game_time_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 2 timer:%d", t - t0);
					t0 = t;
				}

				if (!sesssion_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 3 session:%d", t - t0);
					t0 = t;
				}

				if (!redis_conn_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 4 redis:%d", t - t0);
					t0 = t;
				}

				// 消息统计
				print_statistics();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 5 print_statistics:%d", t - t0);
					t0 = t;
				}
			}

			if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("tick guard step 6 config_server:%d", t - t0);
				t0 = t;
			}

#ifdef PLATFORM_WINDOWS
			// linux todo
			if (b_sleep)
				Sleep(1);
#endif
		}

		if (init_config_server_)
		{
			network_server_->stop();
			redis_conn_->stop();

			network_server_->join();
			redis_conn_->join();

			sesssion_manager_->release_all_session();
		}

		if (config_server_)
		{
			config_server_->stop();
			config_server_->join();
		}
	}
#ifdef PLATFORM_WINDOWS
	__except (seh_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		printf("seh exception\n");
	}
#endif
}

void LoginServer::stop()
{
	if (is_run_ && init_config_server_)
		sesssion_manager_->close_all_session();

	BaseServer::stop();
}

void LoginServer::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	redis_conn_.reset();

	config_server_.reset();

	BaseServer::release();
}

bool LoginServer::on_NotifyDBServerStart(int db_id)
{
	for (const auto& item : login_config_.db_addr())
	{
		if (item.server_id() == db_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

void LoginServer::on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByLogin& cfg)
{
	auto addr = login_config_.add_db_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.db_id());

	LoginSessionManager::instance()->Add_DB_Server_Session(cfg.ip(), cfg.port());
}


//////////////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

	std::string title = "login";

	LoginServer theServer;
	if (argc > 1)
	{
		theServer.set_login_id(atoi(argv[1]));
		title = str(boost::format("login%d") % theServer.get_login_id());
	}

	theServer.set_print_filename(title);

#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA(title.c_str());
#endif

	theServer.startup();
	
#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
