#include "ConfigDBManager.h"
#include "ConfigServerConfigManager.h"
#include "ConfigServer.h"

ConfigDBManager::ConfigDBManager()
{
}

ConfigDBManager::~ConfigDBManager()
{
}

void ConfigDBManager::run()
{
	{
		auto& cfg = ConfigServerConfigManager::instance()->get_config().config_db();

		db_connection_config_.set_host(cfg.host());
		db_connection_config_.set_user(cfg.user());
		db_connection_config_.set_password(cfg.password());
		db_connection_config_.set_database(cfg.database());
	}

	//auto core_count = ConfigServer::instance()->get_core_count();
	size_t core_count = 1;
	db_connection_config_.run(core_count);
}

void ConfigDBManager::join()
{
	db_connection_config_.join();
}

void ConfigDBManager::stop()
{
	db_connection_config_.stop();
}

void ConfigDBManager::tick()
{
	db_connection_config_.tick();
}
