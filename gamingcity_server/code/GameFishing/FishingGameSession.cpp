#include "FishingGameSession.h"
#include "TableManager.h"
#include "GameLog.h"

FishingGameSession::FishingGameSession(boost::asio::ip::tcp::socket& sock)
	: GameSession(sock)
{
}

FishingGameSession::~FishingGameSession()
{
}

void FishingGameSession::on_cs_time_sync(int guid, CS_TimeSync* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnTimeSync(msg);
}

void FishingGameSession::on_cs_change_score(int guid, CS_ChangeScore* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}
}

void FishingGameSession::on_cs_change_cannon_set(int guid, CS_ChangeCannonSet* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnChangeCannonSet(msg);
}

void FishingGameSession::on_cs_netcast(int guid, CS_Netcast* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnNetCast(msg);
}

void FishingGameSession::on_cs_lock_fish(int guid, CS_LockFish* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnLockFish(msg);
}

void FishingGameSession::on_cs_fire(int guid, CS_Fire* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnFire(msg);
}

void FishingGameSession::on_cs_change_cannon(int guid, CS_ChangeCannon* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnChangeCannon(msg);
}

void FishingGameSession::on_cs_treasure_end(int guid, CS_TreasureEnd* msg)
{
	auto table = TableManager::instance()->find_table_by_player(guid);
	if (nullptr == table)
	{
		LOG_ERR("guid[%d] find not fishing table", guid);
		return;
	}

	table->OnTreasureEND(msg);
}
