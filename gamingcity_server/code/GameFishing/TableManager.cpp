#include "TableManager.h"
#include "GameTimeManager.h"


TableManager::TableManager()
	: millisecond_time_(0)
{
	millisecond_time_ = GameTimeManager::instance()->get_millisecond_time();
}

TableManager::~TableManager()
{
}

void TableManager::add_table(CTableFrameSink* table)
{
	tables_.insert(table);
}

void TableManager::remove_table(CTableFrameSink* table)
{
	tables_.erase(table);
}

void TableManager::update()
{
	auto cur = GameTimeManager::instance()->get_millisecond_time();
	int elapsed = static_cast<int>(cur - millisecond_time_);
	if (elapsed < 1000 / GAME_FPS)
		return;

	millisecond_time_ = cur;

	for (auto& item : tables_)
	{
		item->OnGameUpdate();
	}
}

void TableManager::add_player_table(int chair_id, int guid, int gate_id, CTableFrameSink* table)
{
	player_tables_.insert(std::make_pair(guid, table));
	table->set_guid_gateid(chair_id, guid, gate_id);
}

void TableManager::remove_player_table(int guid)
{
	player_tables_.erase(guid);
}

CTableFrameSink* TableManager::find_table_by_player(int guid)
{
	auto it = player_tables_.find(guid);
	if (it != player_tables_.end())
		return it->second;
	return nullptr;
}


