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

    unsigned short GetRoomID();

    void SetRoomID(unsigned short);

    CTableFrameSink* find_table_by_player(int guid);
    CTableFrameSink* find_table_by_tableid(int tableid);

    int GetTableSize();

private:
	long long									millisecond_time_;
	std::vector<CTableFrameSink*>		        tables_;

	std::unordered_map<int, CTableFrameSink*>	player_tables_; // 玩家对应的桌子
    unsigned short   m_RoomID;      //房间ID
};
