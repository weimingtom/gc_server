#include "BaseGameServer.h"
#include <google/protobuf/text_format.h>
#include <boost/algorithm/string.hpp>
#include "CryptoManager.h"
#include "redis_define.pb.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

BaseGameServer::BaseGameServer()
	: game_id_(1)
	, init_config_server_(false)
	, first_network_server_(true)
	, load_cfg_complete_(false)
{
	
}

BaseGameServer::~BaseGameServer()
{
}

bool BaseGameServer::init()
{
	if (!BaseServer::init())
		return false;

	//if (!cfg_manager_.load_config())
	//	return false;

	std::string filename = "../log/%d-%d-%d" + get_game_name() + boost::lexical_cast<std::string>(get_game_id()) + ".log";
	GameLog::instance()->init(filename.c_str());

	// 从网络读取配置
	config_server_ = std::move(std::unique_ptr<GameConfigNetworkServer>(new GameConfigNetworkServer));
	config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());

	config_server_->run();

	return true;
}

void BaseGameServer::on_loadConfigComplete(const GameServerConfigInfo& cfg)
{
	if (init_config_server_)
		return;

	game_config_.CopyFrom(cfg);

	sesssion_manager_ = std::move(std::unique_ptr<GameSessionManager>(new_session_manager()));
	network_server_ = std::move(std::unique_ptr<NetworkServer>(new NetworkServer(game_config_.port(), get_core_count(), sesssion_manager_.get())));

	redis_conn_ = std::move(std::unique_ptr<RedisConnectionThread>(new RedisConnectionThread));
	{
		auto& cfg_sentinel = game_config_.def_sentinel();
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
			auto& cfg = game_config_.def_redis();
			if (cfg.has_ip())
			{
				std::string master_name_tmp;
				redis_conn_->set_master_info(cfg.ip(), cfg.port(), master_name_tmp, cfg.dbnum(), cfg.password());
			}
		}
	}
	redis_conn_->start();

	// 初始化在线人数
	//redis_conn_->command(str(boost::format("HSET game_server_online_count %1% 0") % game_config_.game_id()));

	lua_manager_ = std::move(std::unique_ptr<BaseGameLuaScriptManager>(new_lua_script_manager()));
	lua_manager_->init();
	lua_manager_->dofile(main_lua_file());
	load_cfg_complete_ = true;

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
	wsprintf(buf, static_cast<BaseGameServer*>(BaseServer::instance())->dump_file_name(), tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void BaseGameServer::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
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

				on_tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 5 on_tick:%d", t - t0);
					t0 = t;
				}

				if (load_cfg_complete_)
					lua_tinker::call<void>(lua_manager_->get_lua_state(), "on_tick");
				t = GetTickCount(); 
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 6 lua on_tick:%d", t - t0);
					t0 = t;
				}

#ifdef _DEBUG
				gm_manager_.exe_gm_command();
#endif

				// 消息统计
				print_statistics();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 7 print_statistics:%d", t - t0);
					t0 = t;
				}
			}

			if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("tick guard step 8 config_server:%d", t - t0);
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

			if (load_cfg_complete_)
				lua_tinker::call<void>(lua_manager_->get_lua_state(), "SendStop2Lua");
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

void BaseGameServer::stop()
{
	if (is_run_ && init_config_server_)
		sesssion_manager_->close_all_session();

	BaseServer::stop();
}

void BaseGameServer::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	lua_manager_.reset();
	redis_conn_.reset();

	config_server_.reset();

	BaseServer::release();
}

void BaseGameServer::on_gm_command(const char* cmd)
{
#ifdef _DEBUG
	std::vector<std::string> vc;
	std::string str = boost::trim_copy(std::string(cmd));
	boost::split(vc, str, boost::is_any_of(" \t"), boost::token_compress_on);

	if (!vc.empty())
		gm_manager_.gm_command(vc);
#endif
}
/*
const char* BaseGameServer::log_file_name()
{
	assert(false);
	return "";
}*/

const wchar_t* BaseGameServer::dump_file_name()
{
	assert(false);
	return L"";
}

GameSessionManager* BaseGameServer::new_session_manager()
{
	return new GameSessionManager;
}

BaseGameLuaScriptManager* BaseGameServer::new_lua_script_manager()
{
	return new BaseGameLuaScriptManager;
}

bool BaseGameServer::on_NotifyLoginServerStart(int login_id)
{
	for (const auto& item : game_config_.login_addr())
	{
		if (item.server_id() == login_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

void BaseGameServer::on_UpdateLoginConfigComplete(const S_ReplyUpdateLoginServerConfigByGame& cfg)
{
	auto addr = game_config_.add_login_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.login_id());

	GameSessionManager::instance()->Add_Login_Server_Session(cfg.ip(), cfg.port());
}

bool BaseGameServer::on_NotifyDBServerStart(int db_id)
{
	for (const auto& item : game_config_.db_addr())
	{
		if (item.server_id() == db_id)
		{
			return false;
		}
	}

	// 没有找到，说明新加了服务器
	return true;
}

void BaseGameServer::on_UpdateDBConfigComplete(const S_ReplyUpdateDBServerConfigByGame& cfg)
{
	auto addr = game_config_.add_db_addr();
	addr->set_ip(cfg.ip());
	addr->set_port(cfg.port());
	addr->set_server_id(cfg.db_id());

	GameSessionManager::instance()->Add_DB_Server_Session(cfg.ip(), cfg.port());
}
