// GateServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include "GateServer.h"
#include "CryptoManager.h"
#include <algorithm>
#include <strstream>
#include "./asynTask/HttpRequest.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

GateServer::GateServer()
	: gate_id_(1)
	, init_config_server_(false)
	, first_network_server_(true)
	, rsa_keys_index_(0)
	, rsa_keys_time_(0)
{
}

GateServer::~GateServer()
{
}

bool GateServer::init()
{
	if (!BaseServer::init())
		return false;

	std::string filename = "../log/%d-%d-%d gate" + boost::lexical_cast<std::string>(get_gate_id()) + ".log";
	GameLog::instance()->init(filename.c_str());

    sesssion_manager_ = std::move(std::unique_ptr<GateSessionManager>(new GateSessionManager));
	ip_manager_ = std::move(std::unique_ptr<IpAreaManager>(new IpAreaManager));
	ip_manager_->parse_file();
	
	// 从网络读取配置
	config_server_ = std::move(std::unique_ptr<GateConfigNetworkServer>(new GateConfigNetworkServer));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());

	config_server_->run();

	asyn_task_manager_ = std::move(std::unique_ptr<AsynTaskMgr>(new AsynTaskMgr));

	//if (!cfg_manager_.load_config())
	//	return false;

    //if (!cfg_manager_.load_gameserver_config())
    {
    //    return false;
    }
	//if (using_db_config_)
	//{
	//	db_manager_ = std::move(std::unique_ptr<GateDBManager>(new GateDBManager));

	//	GateDBManager::instance()->get_db_connection_config().execute_query_vstring([this](std::vector<std::vector<std::string>>* data) {
	//		if (data)
	//		{
	//			cfg_manager_.load_gameserver_config_db(*data);
	//		}
	//		else
	//		{
	//			LOG_ERR("load cfg from db error");
	//		}
	//	}, "SELECT * FROM t_game_server_cfg;");
	//}
	//else if (!cfg_manager_.load_gameserver_config())
	//{
	//	return false;
	//}


	return true;
}

void GateServer::on_loadConfigComplete(const S_ReplyServerConfig& cfg)
{
	if (init_config_server_)
		return;

	gate_config_.CopyFrom(cfg.gate_config());
	gameserver_cfg_.mutable_pb_cfg()->CopyFrom(cfg.client_room_cfg());
	
	//if (!cfg_manager_.load_gameserver_config())
	{
		//return false;
	}

	network_server_ = std::move(std::unique_ptr<NetworkServer>(new NetworkServer(gate_config_.port(), get_core_count(), sesssion_manager_.get())));

	init_config_server_ = true;
}

void GateServer::on_UpdateConfigComplete(const S_ReplyUpdateGameServerConfig& cfg)
{
	gameserver_cfg_.mutable_pb_cfg()->CopyFrom(cfg.client_room_cfg());
	GateSessionManager::instance()->Add_Game_Server_Session(cfg.ip(), cfg.port());
}

bool GateServer::on_NotifyGameServerStart(int game_id)
{
	for (const auto& item : gameserver_cfg_.pb_cfg())
	{
		if (item.game_id() == game_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

void GateServer::on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGate& cfg)
{
	auto addr = gate_config_.add_login_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.login_id());

	GateSessionManager::instance()->Add_Login_Server_Session(cfg.ip(), cfg.port());
}

bool GateServer::on_NotifyLoginServerStart(int login_id)
{
	for (const auto& item : gate_config_.login_addr())
	{
		if (item.server_id() == login_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
int __stdcall seh_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"GateServer_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void GateServer::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
		//if (using_db_config_)
		//	db_manager_->run();

		// 启动网络线程
		//network_server_->run();

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

				//if (using_db_config_)
				//	db_manager_->tick();

				// 消息统计
				print_statistics();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 4 print_statistics:%d", t - t0);
					t0 = t;
				}

				asyn_task_manager_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 5 asyn_task_manager:%d", t - t0);
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

		//if (using_db_config_)
		//	db_manager_->stop();

		if (init_config_server_)
		{
			network_server_->stop();
			network_server_->join();
			sesssion_manager_->release_all_session();
			asyn_task_manager_->stop();
		}

		if (config_server_)
		{
			config_server_->stop();
			config_server_->join();
		}

		//if (using_db_config_)
		//	db_manager_->join();
	}
#ifdef PLATFORM_WINDOWS
	__except (seh_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		printf("seh exception\n");
	}
#endif
}

void GateServer::stop()
{
	if (is_run_ && init_config_server_)
		sesssion_manager_->close_all_session();

	BaseServer::stop();
}

void GateServer::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	//if (using_db_config_)
	//	db_manager_.reset();

	config_server_.reset();

	BaseServer::release();
}

void GateServer::reload_gameserver_config(DL_ServerConfig & cfg)
{
    //cfg_manager_.load_gameserver_config_pb(cfg);
}


void GateServer::reload_gameserver_config_DB(LG_DBGameConfigMgr & cfg)
{
    //cfg_manager_.load_gameserver_config_pb(cfg);
}

void GateServer::get_rsa_key(std::string& public_key, std::string& private_key)
{
	if (rsa_keys_.empty() || GameTimeManager::instance()->get_second_time() - rsa_keys_time_ >= 3600)
	{
		rsa_keys_.clear();
		for (int i = 0; i < 10; i++)
		{
			CryptoManager::rsa_key(public_key, private_key);
			rsa_keys_.push_back(std::make_pair(public_key, private_key));
		}
		rsa_keys_index_ = 0;
		rsa_keys_time_ = GameTimeManager::instance()->get_second_time();
		return;
	}

	++rsa_keys_index_;
	if (rsa_keys_index_ >= rsa_keys_.size())
		rsa_keys_index_ = 0;
	auto& p = rsa_keys_[rsa_keys_index_];
	public_key = p.first;
	private_key = p.second;
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

    //system("pause");
	std::string title = "gate";
	
	GateServer theServer;
	if (argc > 1)
	{
		theServer.set_gate_id(atoi(argv[1]));
		title = str(boost::format("gate%d") % theServer.get_gate_id());
	}

	//for (int i = 1; i < argc; i++)
	{
// 		//if (strcmp(argv[i], "-db") == 0)
// 		//	theServer.set_using_db_config(true);
// 		//else
			//GateServerConfigManager::instance()->set_cfg_file_name(argv[i]);
	}

	//std::string title = GateServerConfigManager::instance()->get_title();
	theServer.set_print_filename(title);

	//if (theServer.get_using_db_config())
	//	title += "-db";

#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA(title.c_str());
#endif

	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}

