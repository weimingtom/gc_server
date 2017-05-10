#include "CommonFun.h"


CCommonFun::CCommonFun()
{
}


CCommonFun::~CCommonFun()
{
}



CLock::CLock(void)
{
    //InitializeCriticalSection(&m_section);
}
CLock::~CLock(void)
{
    //DeleteCriticalSection(&m_section);
}
void CLock::lock()
{
    //EnterCriticalSection(&m_section);
}
void CLock::unLock()
{
    //LeaveCriticalSection(&m_section);
}
CAutoLock::CAutoLock(CLock * pLock)
{
    m_pLock = pLock;
    pLock->lock();
}
CAutoLock::~CAutoLock()
{
    m_pLock->unLock();
}
char g_TableName[16];
int g_TableNameIn;
void InitTableName()
{
    memset(g_TableName, 0, 16);
    g_TableNameIn = 0;
}
void PushNumToTable(lua_State* L, char * FieldName, int i)
{
    lua_pushstring(L, FieldName);
    lua_pushnumber(L, i);
    lua_settable(L, -3);
}
void PushStrToTable(lua_State* L, char * FieldName, char * str)
{
    lua_pushstring(L, FieldName);
    lua_pushstring(L, str);
    lua_settable(L, -3);
}
void PushTabToTable_Begin(lua_State* L, char * TabName)
{
    lua_pushstring(L, TabName);
    lua_newtable(L);
}
void PushTabToTable_Begin(lua_State* L)
{
    sprintf(g_TableName, "%d", g_TableNameIn + '1');
    lua_pushstring(L, g_TableName);
    lua_newtable(L);
    g_TableNameIn++;
}
void PushTabToTable_End(lua_State* L)
{
    lua_settable(L, -3);
}
void CallLuaFun(lua_State* L)
{
    int iRet = lua_pcall(L, 3, 1, 0);
}

void CreatLuaPackage(lua_State* L, char * SendFunName, int GuID, char * PackageName)
{
    lua_getglobal(L, SendFunName);
    lua_pushnumber(L, GuID);
    lua_pushstring(L, PackageName);
    lua_newtable(L);
}
void GetReadTableName(lua_State* L, char * TabName)
{
    lua_getglobal(L, TabName);
}
int GetTableItemInt(lua_State* L, char * ItemName)
{
    int Temp = 0;
    lua_pushstring(L, ItemName);
    lua_gettable(L, -2);
    Temp = (int)lua_tonumber(L, -1);
    lua_pop(L, 2);
    return Temp;
}
__int64 GetTableItemInt64(lua_State* L, char * ItemName)
{
    __int64 Temp = 0;
    lua_pushstring(L, ItemName);
    lua_gettable(L, -2);
    Temp = (__int64)lua_tonumber(L, -1);
    lua_pop(L, 2);
    return Temp;
}
void GetTableItemStr(lua_State* L, char * ItemName, std::string &strValue)
{
    lua_pushstring(L, ItemName);
    lua_gettable(L, -2);
    strValue = lua_tostring(L, -1);
    lua_pop(L, 2);
}
int GetTableIndexInt(lua_State* L, int Index)
{
    int Temp = 0;
    lua_rawgeti(L, -1, Index);
    Temp = (int)lua_tonumber(L, -1);
    lua_pop(L, 2);
    return Temp;
}
__int64 GetTableIndexInt64(lua_State* L, int Index)
{
    __int64 Temp = 0;
    lua_rawgeti(L, -1, Index);
    Temp = (__int64)lua_tonumber(L, -1);
    lua_pop(L, 2);
    return Temp;
}
void GetTableIndexStr(lua_State* L, int Index, std::string &strValue)
{
    lua_rawgeti(L, -1, Index);
    strValue =  lua_tostring(L, -1);
    lua_pop(L, 2);
}
