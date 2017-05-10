#pragma once
#include "common.h"
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
class CCommonFun
{
public:
    CCommonFun();
    ~CCommonFun();
};



class CLock
{
private:
    CRITICAL_SECTION m_section;
public:
    CLock(void);
    ~CLock(void);
    void lock();
    void unLock();
};
class CAutoLock
{
private:
    CLock * m_pLock;
public:
    CAutoLock(CLock * pLock);
    ~CAutoLock();
};

void InitTableName();
void PushNumToTable(lua_State* L, char * FieldName, int i);
void PushStrToTable(lua_State* L, char * FieldName, char * str);
void PushTabToTable_Begin(lua_State* L, char * TabName);
void PushTabToTable_Begin(lua_State* L);
void PushTabToTable_End(lua_State* L);
void CreatLuaPackage(lua_State* L, char * SendFunName, int GuID, char * PackageName);
void CallLuaFun(lua_State* L);
void GetReadTableName(lua_State* L, char * TabName);
int GetTableItemInt(lua_State* L, char * ItemName);
void GetTableItemStr(lua_State* L, char * ItemName, std::string &strValue);
__int64 GetTableItemInt64(lua_State* L, char * ItemName);
int GetTableIndexInt(lua_State* L, int Index);
__int64 GetTableIndexInt64(lua_State* L, int Index);
void GetTableIndexStr(lua_State* L, int Index, std::string &strValue);