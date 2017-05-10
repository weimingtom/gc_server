// DBServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"

#include "DBServer.h"
#include <google/protobuf/text_format.h>
#include <boost/algorithm/string.hpp>

#include "DBConnection.h"
#include "DBConnectionPool.h"
#include "common_enum_define.pb.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

DBServer::DBServer()
	: fortune_rank_time_(0)
	, daily_earnings_time_(0)
	, weekly_earnings_time_(0)
	, monthly_earnings_year_mon_(0)
    , db_id_(1)
    , init_config_server_(false)
    , first_network_server_(true)
{
}

DBServer::~DBServer()
{
}

bool DBServer::init()
{
	if (!BaseServer::init())
		return false;

	GameLog::instance()->init("../log/%d-%d-%d db.log");

    config_server_ = std::move(std::unique_ptr<DBConfigNetworkServer>(new DBConfigNetworkServer));
    config_server_->create_cfg_session(common_config_.config_addr().ip(), common_config_.config_addr().port());
    config_server_->run();

	return true;
}
void DBServer::on_loadConfigComplete(const DBServerConfig& ncfg)
{
	if (init_config_server_)
		return;

    auto & mycfg = cfg_manager_.get_config();
    mycfg.CopyFrom(ncfg);

	db_manager_ = std::move(std::unique_ptr<DBManager>(new DBManager));

	sesssion_manager_ = std::move(std::unique_ptr<DBSessionManager>(new DBSessionManager));
	network_server_ = std::move(std::unique_ptr<NetworkServer>(new NetworkServer(cfg_manager_.get_config().port(), get_core_count(), sesssion_manager_.get())));
	
	lua_manager_ = std::move(std::unique_ptr<DBLuaScriptManager>(new DBLuaScriptManager));
	lua_manager_->init();
	lua_manager_->dofile("../script/db/main.lua");

	redis_conn_ = std::move(std::unique_ptr<RedisConnectionThread>(new RedisConnectionThread));
	{
		auto& cfg_sentinel = cfg_manager_.get_config().def_sentinel();
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
			auto& cfg = cfg_manager_.get_config().def_redis();
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

bool  DBServer::LoadSeverConfig()
{
    /*  DBManager::instance()->get_db_connection_config().execute_query_vstring([this](std::vector<std::vector<std::string>>* data) {
          if (data)
          {

          DBGameConfigMgr &dbgamer_config = DBSessionManager::instance()->GetServerCfg();
          dbgamer_config.clear_pb_cfg();
          for (auto& item : *data)
          {
          auto dbcfg = dbgamer_config.add_pb_cfg();
          dbcfg->set_cfg_name(item[0]);
          dbcfg->set_is_open(boost::lexical_cast<int>(item[1]));
          dbcfg->set_using_login_validatebox(boost::lexical_cast<int>(item[2]));
          dbcfg->set_ip(item[3]);
          dbcfg->set_port(boost::lexical_cast<int>(item[4]));
          dbcfg->set_game_id(boost::lexical_cast<int>(item[5]));
          dbcfg->set_first_game_type(boost::lexical_cast<int>(item[6]));
          dbcfg->set_second_game_type(boost::lexical_cast<int>(item[7]));
          dbcfg->set_game_name(item[8]);
          dbcfg->set_game_log(item[9]);
          dbcfg->set_default_lobby(boost::lexical_cast<int>(item[10]));
          dbcfg->set_player_limit(boost::lexical_cast<int>(item[11]));
          dbcfg->set_data_path(item[12]);
          dbcfg->set_room_list(item[13]);
          dbcfg->set_room_lua_cfg(item[14]);
          }

			DBManager::instance()->get_db_connection_account().execute_query_vstring([](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					DBGameConfigMgr &dbgamer_config = DBSessionManager::instance()->GetServerCfg();
					dbgamer_config.clear_channel_cfg();
					for (auto& item : *data)
					{
						auto dbcfg = dbgamer_config.add_channel_cfg();
						dbcfg->set_channel_id(item[1]);
						int channel_lock = boost::lexical_cast<int>(item[2]);
						int big_lock = boost::lexical_cast<int>(item[3]);
						dbcfg->set_is_invite_open((big_lock == 1 && channel_lock == 1) ? 1 : 0);
						dbcfg->set_tax_rate(boost::lexical_cast<int>(item[4]));
					}
				}
				else
				{
					LOG_ERR("load cfg from db error");
				}
			}, "SELECT * FROM t_channel_invite;");
          }
          else
          {
          LOG_ERR("load cfg from db error");
          }
          }, "SELECT * FROM t_game_server_cfg;");*/
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
	wsprintf(buf, L"DBServer_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void DBServer::run()
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
                if (first_network_server_)
                {
                    // 启动网络线程
                    network_server_->run();
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("tick guard step 1 start net:%d", t - t0);
						t0 = t;
					}

                    // db
                    db_manager_->run();
					t = GetTickCount();
					if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
					{
						LOG_WARN("tick guard step 2 start db:%d", t - t0);
						t0 = t;
					}
                    first_network_server_ = false;
                }
                game_time_->tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 3 timer:%d", t - t0);
					t0 = t;
				}

				if (!sesssion_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 4 session:%d", t - t0);
					t0 = t;
				}

				if (!db_manager_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 5 db:%d", t - t0);
					t0 = t;
				}

				if (!redis_conn_->tick())
				{
					b_sleep = false;
				}
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 6 redis:%d", t - t0);
					t0 = t;
				}

                tick();
				t = GetTickCount();
				if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
				{
					LOG_WARN("tick guard step 7 tick:%d", t - t0);
					t0 = t;
				}

#ifdef _DEBUG
                gm_manager_.exe_gm_command();
#endif
            }
            if (config_server_)
				config_server_->tick();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("tick guard step 8 config_server:%d", t - t0);
				t0 = t;
			}

			// 消息统计
			print_statistics();
			t = GetTickCount();
			if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
			{
				LOG_WARN("tick guard step 9 print_statistics:%d", t - t0);
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
            db_manager_->stop();


            network_server_->stop();
            redis_conn_->stop();

            network_server_->join();
            redis_conn_->join();
        }
        if (config_server_)
        {
            config_server_->stop();
            config_server_->join();
        }

		sesssion_manager_->release_all_session();

		db_manager_->join();
	}
#ifdef PLATFORM_WINDOWS
	__except (seh_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		printf("seh exception\n");
	}
#endif
}

void DBServer::stop()
{
	if (is_run_)
	{
        if (init_config_server_)
        {
            sesssion_manager_->close_all_session();
        }
	}

	BaseServer::stop();
}

void DBServer::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	db_manager_.reset();
	lua_manager_.reset();
    redis_conn_.reset();
    config_server_.reset();

	BaseServer::release();
}

void DBServer::on_gm_command(const char* cmd)
{
#ifdef _DEBUG
	std::vector<std::string> vc;
	std::string str = boost::trim_copy(std::string(cmd));
	boost::split(vc, str, boost::is_any_of(" \t"), boost::token_compress_on);

	if (!vc.empty())
		gm_manager_.gm_command(vc);
#endif
}

const char* DBServer::main_lua_file()
{
	return "../script/db/main.lua";
}

static void update_fortune_rank()
{
	/*DBManager::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_FORTUNE);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		DBSessionManager::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_fortune_rank();");*/
}

static void update_daily_earnings_rank()
{
	/*DBManager::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_DAILY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		DBSessionManager::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_daily_earnings_rank();");*/
}

static void update_weekly_earnings_rank()
{
	/*DBManager::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_WEEKLY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		DBSessionManager::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_weekly_earnings_rank();");*/
}

static void update_monthly_earnings_rank()
{
	/*DBManager::instance()->get_db_connection_game().execute_query<RankList>([](RankList* data) {
		DE_UpdateRank reply;
		reply.set_rank_type(RANK_TYPE_MONTHLY_EARNINGS);
		if (data)
		{
			reply.mutable_pb_rank()->CopyFrom(data->pb_rank_list());
		}

		DBSessionManager::instance()->send2center_pb(&reply);

	}, "pb_rank_list", "CALL get_monthly_earnings_rank();");*/
}

void DBServer::update_rank_to_center()
{
	update_fortune_rank();
	update_daily_earnings_rank();
	update_weekly_earnings_rank();
	update_monthly_earnings_rank();
}

void DBServer::tick()
{
	if (fortune_rank_time_ != 0)
	{
		if (GameTimeManager::instance()->to_days() != GameTimeManager::instance()->to_days(fortune_rank_time_))
		{
			update_fortune_rank();
			fortune_rank_time_ = GameTimeManager::instance()->get_second_time();
		}
	}
	else
	{
		fortune_rank_time_ = GameTimeManager::instance()->get_second_time();
	}

	if (daily_earnings_time_ != 0 )
	{
		if (GameTimeManager::instance()->to_days() != GameTimeManager::instance()->to_days(daily_earnings_time_))
		{
			update_daily_earnings_rank();
			daily_earnings_time_ = GameTimeManager::instance()->get_second_time();
		}
	}
	else
	{
		daily_earnings_time_ = GameTimeManager::instance()->get_second_time();
	}

	if (weekly_earnings_time_ != 0)
	{
		if (GameTimeManager::instance()->to_weeks() != GameTimeManager::instance()->to_weeks(weekly_earnings_time_))
		{
			update_weekly_earnings_rank();
			weekly_earnings_time_ = GameTimeManager::instance()->get_second_time();
		}
	}
	else
	{
		weekly_earnings_time_ = GameTimeManager::instance()->get_second_time();
	}

	auto tm = GameTimeManager::instance()->get_tm();
	int year_mon = tm->tm_year * 100 + tm->tm_mon;
	if (monthly_earnings_year_mon_ != 0)
	{
		if (monthly_earnings_year_mon_ != year_mon)
		{
			update_monthly_earnings_rank();
			monthly_earnings_year_mon_ = year_mon;
		}
	}
	else
	{
		monthly_earnings_year_mon_ = year_mon;
	}
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

    std::string title = "db";

	DBServer theServer;
    if (argc > 1)
    {
        theServer.set_db_id(atoi(argv[1]));
        title = str(boost::format("db%d") % theServer.get_db_id());
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
