#include "common.h"
#include "TableFrameSink.h"
#include "TableManager.h"

extern int    g_bRun;
typedef struct  stLuaMsg;
bool PostMsgToTabByTabID(int TableID, enMsgType  MsgType)
{
    if (!g_bRun) return false;
    auto table = TableManager::instance()->find_table_by_tableid(TableID);
    if (table != NULL)
    {
        stLuaMsg * Msg = new stLuaMsg();
        Msg->m_pMsg = NULL;
        Msg->m_iMsgID = MsgType;
        Msg->m_TableID = table->get_table_id();

        table->PushMsg(Msg);
        return 1;
    }
    else
    {
        return 0;
    }
}


template<class T>
bool PostMsgToTabByGuID(int GuID, T &theTemp, enMsgType  MsgType)
{
    if (!g_bRun) return false;
    auto table = TableManager::instance()->find_table_by_player(GuID);
    if (table != NULL)
    {
        stLuaMsg * Msg = new stLuaMsg();
        T * Temp = new T();
        (*Temp) = theTemp;
        Msg->m_pMsg = Temp;
        Msg->m_iMsgID = MsgType;
        Msg->m_iGuID = GuID;
        Msg->m_TableID = table->get_table_id();

        table->PushMsg(Msg);
        return 1;
    }
    else
    {
        return 0;
    }
}