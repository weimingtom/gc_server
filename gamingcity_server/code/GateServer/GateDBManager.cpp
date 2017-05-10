#include "GateDBManager.h"
#include "GateServerConfigManager.h"
#if 0
GateDBManager::GateDBManager()
{
}

GateDBManager::~GateDBManager()
{
}

void GateDBManager::run()
{
	{
		auto& cfg = GateServerConfigManager::instance()->get_config().config_db();

		db_connection_config_.set_host(cfg.host());
		db_connection_config_.set_user(cfg.user());
		db_connection_config_.set_password(cfg.password());
		db_connection_config_.set_database(cfg.database());
	}

	db_connection_config_.run(1);
}

void GateDBManager::join()
{
	db_connection_config_.join();
}

void GateDBManager::stop()
{
	db_connection_config_.stop();
}

void GateDBManager::tick()
{
	db_connection_config_.tick();
}
#endif
