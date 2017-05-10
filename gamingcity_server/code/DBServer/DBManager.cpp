#include "DBManager.h"
#include "DBServerConfigManager.h"
#include "DBServer.h"

DBManager::DBManager()
{
}

DBManager::~DBManager()
{
}

void DBManager::run()
{
	{
		auto& cfg = DBServerConfigManager::instance()->get_config().login_db();

		db_connection_account_.set_host(cfg.host());
		db_connection_account_.set_user(cfg.user());
		db_connection_account_.set_password(cfg.password());
		db_connection_account_.set_database(cfg.database());
	}

	{
		auto& cfg = DBServerConfigManager::instance()->get_config().game_db();

		db_connection_game_.set_host(cfg.host());
		db_connection_game_.set_user(cfg.user());
		db_connection_game_.set_password(cfg.password());
		db_connection_game_.set_database(cfg.database());
	}

	{
		auto& cfg = DBServerConfigManager::instance()->get_config().log_db();

		db_connection_log_.set_host(cfg.host());
		db_connection_log_.set_user(cfg.user());
		db_connection_log_.set_password(cfg.password());
		db_connection_log_.set_database(cfg.database());
	}

    {
        auto& cfg = DBServerConfigManager::instance()->get_config().recharge_db();

        db_connection_recharge_.set_host(cfg.host());
        db_connection_recharge_.set_user(cfg.user());
        db_connection_recharge_.set_password(cfg.password());
        db_connection_recharge_.set_database(cfg.database());
    }
    
	auto core_count = DBServer::instance()->get_core_count();
	//core_count = 1;
	db_connection_account_.run(core_count);
	db_connection_game_.run(core_count);
	db_connection_log_.run(core_count);
	db_connection_recharge_.run(core_count);
}

void DBManager::join()
{
	db_connection_account_.join();
	db_connection_game_.join();
	db_connection_log_.join();
	db_connection_recharge_.join();
}

void DBManager::stop()
{
	db_connection_account_.stop();
	db_connection_game_.stop();
	db_connection_log_.stop();
	db_connection_recharge_.stop();
}

bool DBManager::tick()
{
	bool ret = true;
	if (!db_connection_account_.tick())
	{
		ret = false;
	}
	if (!db_connection_game_.tick())
	{
		ret = false;
	}
	if (!db_connection_log_.tick())
	{
		ret = false;
	}
	if (!db_connection_recharge_.tick())
	{
		ret = false;
	}

	return ret;
}
