#include "TableManager.h"
#include "GameTimeManager.h"


TableManager::TableManager()
	: millisecond_time_(0)
{
	millisecond_time_ = GameTimeManager::instance()->get_millisecond_time();
    m_RoomID = 0;
}

TableManager::~TableManager()
{
}
//增加桌子
void TableManager::add_table(CTableFrameSink* table)
{
    tables_.push_back(table);
}
//移除桌子
void TableManager::remove_table(CTableFrameSink* table)
{
    vector<CTableFrameSink *>::iterator iter = find(tables_.begin(), tables_.end(), table);
    if (iter != tables_.end()) tables_.erase(iter);
}

unsigned short TableManager::GetRoomID()
{
    return m_RoomID;
}

void TableManager::SetRoomID(unsigned short ID)
{
    m_RoomID = ID;
}
//更新状态
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

//添加玩家到桌子
void TableManager::add_player_table(int chair_id, int guid, int gate_id, CTableFrameSink* table)
{
	player_tables_.insert(std::make_pair(guid, table));
	table->set_guid_gateid(chair_id, guid, gate_id);
}
//移除玩家到桌子
void TableManager::remove_player_table(int guid)
{
	player_tables_.erase(guid);
}
//查找玩家
CTableFrameSink* TableManager::find_table_by_player(int guid)
{
	auto it = player_tables_.find(guid);
	if (it != player_tables_.end())
		return it->second;
	return nullptr;
}
CTableFrameSink* TableManager::find_table_by_tableid(int TablID)
{
    CTableFrameSink* pTemp = NULL;
    if (TablID >= 0 || TablID < tables_.size())
    {
        pTemp = tables_[TablID];
        if (pTemp->get_table_id() == TablID)
        {
            return pTemp;
        }
    }
    vector<CTableFrameSink *>::iterator iter = tables_.begin();
    while (iter != tables_.end())
    {
        if ((*iter)->get_table_id() == TablID)
        {
            return *iter;
        }
        iter++;
    };
    return nullptr;
}
int TableManager::GetTableSize()
{
    return tables_.size();
}

