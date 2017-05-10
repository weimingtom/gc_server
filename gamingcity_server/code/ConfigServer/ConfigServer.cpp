// ConfigServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"

#include "ConfigServer.h"
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

ConfigServer::ConfigServer()
{
}

ConfigServer::~ConfigServer()
{
}

bool ConfigServer::init()
{
	if (!BaseServer::init())
		return false;

	GameLog::instance()->init("../log/%d-%d-%d config.log");

	if (!cfg_manager_.load_config())
		return false;

	db_manager_ = std::move(std::unique_ptr<ConfigDBManager>(new ConfigDBManager));

	sesssion_manager_ = std::move(std::unique_ptr<ConfigSessionManager>(new ConfigSessionManager));
	network_server_ = std::move(std::unique_ptr<NetworkServer>(new NetworkServer(cfg_manager_.get_config().port(), get_core_count(), sesssion_manager_.get())));
	
    /*if (!LoadSeverConfig())
    {
        return false;
    }*/

	return true;
}

bool  ConfigServer::LoadSeverConfig()
{
    ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([this](std::vector<std::vector<std::string>>* data) {
        if (data)
        {

            DBGameConfigMgr &dbgamer_config = ConfigSessionManager::instance()->GetServerCfg();
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
        }
        else
        {
            LOG_ERR("load cfg from db error");
        }
    }, "SELECT * FROM t_game_server_cfg;");
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
	wsprintf(buf, L"ConfigServer_%d-%02d-%02d_%02d-%02d-%02d.dmp", tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void ConfigServer::run()
{
#ifdef PLATFORM_WINDOWS
	__try
#endif
	{
		// db
		db_manager_->run();

		// 启动网络线程
		network_server_->run();

		while (is_run_)
		{
			bool b_sleep = true;
			game_time_->tick();

			if (!sesssion_manager_->tick())
			{
				b_sleep = false;
			}

			db_manager_->tick();
			tick();

#ifdef _DEBUG
			gm_manager_.exe_gm_command();
#endif

			// 消息统计
			print_statistics();

#ifdef PLATFORM_WINDOWS
			// linux todo
			if (b_sleep)
				Sleep(1);
#endif
		}

		db_manager_->stop();


		network_server_->stop();

		network_server_->join();

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

void ConfigServer::stop()
{
	if (is_run_)
	{
		sesssion_manager_->close_all_session();
	}

	BaseServer::stop();
}

void ConfigServer::release()
{
	network_server_.reset();
	sesssion_manager_.reset();
	db_manager_.reset();

	BaseServer::release();
}

void ConfigServer::on_gm_command(const char* cmd)
{
#ifdef _DEBUG
	std::vector<std::string> vc;
	std::string str = boost::trim_copy(std::string(cmd));
	boost::split(vc, str, boost::is_any_of(" \t"), boost::token_compress_on);

	if (!vc.empty())
		gm_manager_.gm_command(vc);
#endif
}

void ConfigServer::tick()
{
}


//////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

	ConfigServer theServer;
	if (argc > 1)
		ConfigServerConfigManager::instance()->set_cfg_file_name(argv[1]);
	
	theServer.set_print_filename("ConfigServer");

	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
