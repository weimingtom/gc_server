#pragma once

#include "perinclude.h"
#include "Singleton.h"
#include "TableFrameSink.h"

class TableManager : public TSingleton<TableManager>
{
public:
	TableManager();

	~TableManager();

	void add_table(CTableFrameSink* table);

	void remove_table(CTableFrameSink* table);

	void update();

	void add_player_table(int chair_id, int guid, int gate_id, CTableFrameSink* table);

	void remove_player_table(int guid);

	CTableFrameSink* find_table_by_player(int guid);

private:
	long long									millisecond_time_;
	std::unordered_set<CTableFrameSink*>		tables_;

	std::unordered_map<int, CTableFrameSink*>	player_tables_; // 玩家对应的桌子
};
