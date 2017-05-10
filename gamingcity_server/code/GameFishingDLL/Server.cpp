#include <stdio.h>
#include <string>
#include<iostream>  
using namespace std;
#include <math.h>
#include<cmath>
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
#define LUA_BUILD_AS_DLL
#include "common.h"
#include "CommonFun.h"

#include "TableframeSink.h"
#include "MyObjectFactory.h"
#include "MyComponentFactory.h"
#include "EffectFactory.h"
#include "EffectManager.h"
#include "BufferFactory.h"
#include "BufferManager.h"
#include "TableManager.h"
#include "GameTimeManager.h"
#include "LuaMsgFun.h"

#include <boost/asio.hpp>    
#include <boost/bind.hpp>  
#include <iostream>  

#include <google/protobuf/text_format.h>

boost::shared_ptr< boost::asio::io_service >  g_IoService;
boost::shared_ptr< boost::asio::io_service::work > g_Work;
boost::mutex global_stream_lock;
lua_State* g_LuaL;
//GameServerConfig				g_pbServerConfig;

GameTimeManager * g_game_time_;
CLock g_LuaLock;
TableManager *g_TableMgr;
std::map<int , CTableFrameSink *> g_mapTable;
bool g_bIsInit;

static int CSTreasureEnd(lua_State *L)
{
    CS_stTreasureEnd  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabTreasireEnd");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.score = GetTableItemInt(L, "score");
    }
    return PostMsgToTabByGuID<CS_stTreasureEnd>(GuID, Temp, enMsgType_TreasureEnd);
}

static int CSChangeCannonSet(lua_State *L)
{
    CS_stChangeCannonSet  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabChangeCannonSet");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.add = GetTableItemInt(L, "add");
    }
    return PostMsgToTabByGuID<CS_stChangeCannonSet>(GuID, Temp, enMsgType_ChangeCannonSet);
}

static int CSNetcast(lua_State *L)
{
    CS_stNetcast  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabNetcast");
        GuID = GetTableItemInt(L, "GuID");
        Temp.bullet_id = GetTableItemInt(L, "bullet_id");
        Temp.data = GetTableItemInt(L, "data");
        Temp.fish_id = GetTableItemInt(L, "fish_id");
    }
    return PostMsgToTabByGuID<CS_stNetcast>(GuID, Temp, enMsgType_Netcast);
}

static int CSLockFish(lua_State *L)
{
    CS_stLockFish  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabLockFish");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.lock = GetTableItemInt(L, "lock");
    }
    return PostMsgToTabByGuID<CS_stLockFish>(GuID, Temp, enMsgType_LockFish);
}

static int CSFire(lua_State *L)
{
    CS_stFire  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabFire");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.direction = GetTableItemInt(L, "direction");
        Temp.fire_time = GetTableItemInt(L, "fire_time");
        Temp.client_id = GetTableItemInt(L, "client_id");
    }
    return PostMsgToTabByGuID<CS_stFire>(GuID, Temp, enMsgType_Fire);
}

static int CSChangeCannon(lua_State *L)
{
    CS_stChangeCannon  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabChangeCannon");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.add = GetTableItemInt(L, "add");
    }
    return PostMsgToTabByGuID<CS_stChangeCannon>(GuID, Temp, enMsgType_ChangeCannon);
}

static int CSTimeSync(lua_State *L)
{
    CS_stTimeSync  Temp;
    //读取
    int GuID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabTimeSync");
        GuID = GetTableItemInt(L, "GuID");
        Temp.chair_id = GetTableItemInt(L, "chair_id");
        Temp.client_tick = GetTableItemInt(L, "client_tick");
    }
    return PostMsgToTabByGuID<CS_stTimeSync>(GuID, Temp, enMsgType_TimeSync);
}

static int RepositionSink(lua_State *L)
{
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabRepositionSink");
        TabID = GetTableItemInt(L, "TableID");
    }
    return PostMsgToTabByTabID(TabID, enMsgType_RepositionSink);
}

static int ActionUserSitDown(lua_State *L)
{
    stLuaMsgType  Temp;
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabActionUserSitDown");
        TabID = GetTableItemInt(L, "TableID");
        Temp.wValue = GetTableItemInt(L, "GuID");
        Temp.bRet = GetTableItemInt(L, "bRet");
        Temp.cbByte = GetTableItemInt(L, "wChairID");
    }
    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_ActionUserSitDown);
}

static int ActionUserStandUp(lua_State *L)
{
    stLuaMsgType  Temp;
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabActionUserStandUp");
        TabID = GetTableItemInt(L, "TableID");
        Temp.wValue = GetTableItemInt(L, "GuID");
        Temp.cbByte = GetTableItemInt(L, "wChairID");
        Temp.bRet = GetTableItemInt(L, "bRet");
    }
    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_ActionUserStandUp);
}

static int EventGameStart(lua_State *L)
{
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabEventGameStart");
        TabID = GetTableItemInt(L, "TableID");
    }
    auto table = TableManager::instance()->find_table_by_tableid(TabID);
    table->OnEventGameStart();
    return 1;
}

static int EventGameConclude(lua_State *L)
{
    stLuaMsgType  Temp;
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabEventGameConclude");
        TabID = GetTableItemInt(L, "TableID");
        Temp.wValue = GetTableItemInt(L, "wChairID");
        Temp.cbByte = GetTableItemInt(L, "cbReason");
    }
    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_EventGameConclude);
}

static int EventSendGameScene(lua_State *L)
{
    stLuaMsgType  Temp;
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabEventSendGameScene");
        TabID = GetTableItemInt(L, "TableID");
        Temp.wValue = GetTableItemInt(L, "wChairID");
        Temp.cbByte = GetTableItemInt(L, "cbReason");
        Temp.bRet = GetTableItemInt(L, "bRet");
    }
    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_EventSendGameScene);
}

static int SetNickNameAndMoney(lua_State *L)
{
    stLuaMsgType  Temp;
    //读取
    int TabID = 0;
    {
        CAutoLock cl(&g_LuaLock);
        GetReadTableName(L, "tabNickName");
        TabID = GetTableItemInt(L, "TableID");
        Temp.wValue = GetTableItemInt(L, "wChairID");
        Temp.lValue = GetTableItemInt64(L, "Money");
        GetTableItemStr(L, "nickname", Temp.strValue);
    }
    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_SetNickNameAndMoney);
}

//static int AddPlayerTable(lua_State *L)
//{
//    stLuaMsgType  Temp;
//    //读取
//    int TabID = 0;
//    {
//        CAutoLock cl(&g_LuaLock);
//        GetReadTableName(L, "tabAddPlayerTable");
//        TabID = GetTableItemInt(L, "TableID");
//        Temp.wValue = GetTableItemInt(L, "Guid");
//    }
//
//    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_AddPlayerTable);
//}
//
//static int RemovePlayerTable(lua_State *L)
//{
//    stLuaMsgType  Temp;
//    //读取
//    int TabID = 0;
//    {
//        CAutoLock cl(&g_LuaLock);
//        GetReadTableName(L, "tabRemovePlayerTable");
//        TabID = GetTableItemInt(L, "TableID");
//        Temp.wValue = GetTableItemInt(L, "Guid");
//    }
//    return PostMsgToTabByGuID<stLuaMsgType>(TabID, Temp, enMsgType_RemovePlayerTable);
//}

HANDLE g_hThreadHandle[100];
int    g_iHandleNum;
int    g_bRun;
int    g_TableNum;

static int StopSever(lua_State *L)
{
    g_bRun = false;
    g_IoService->stop();
    Sleep(10);
    g_Work.reset();
    g_IoService.reset();
    Sleep(10);
    for (int i = 0; i < g_iHandleNum; i++)
    {
        CloseHandle(g_hThreadHandle[i]);
    }
    Sleep(10);
    for (int x = 0; x < g_TableNum; x++)
    {
        delete g_mapTable[x];
    }
    g_mapTable.clear();
    delete g_game_time_;
    delete g_TableMgr;
    return 1;
}
DWORD   WINAPI WorkerThread(LPVOID lpParam)
{
    int i = (int)*(int *)lpParam;
    g_IoService->run();
    printf("线程退出:%d\n", i);
    return 1;
}

bool load_config(const char* cfg, const std::string& db_config = "");
bool load_config(const char* cfg, const std::string& db_config)
{
    /*if (!db_config.empty())
    {
        if (!google::protobuf::TextFormat::ParseFromString(db_config, &g_pbServerConfig))
        {
            printf("parse %s failed", cfg);
            return false;
        }
    }
    else
    {
        std::ifstream ifs(cfg, std::ifstream::in);
        if (!ifs.is_open())
        {
            printf("load %s failed", cfg);
            return false;
        }
        std::string buf = std::string(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
        if (ifs.bad())
        {
            printf("load %s failed", cfg);
            return false;
        }
        if (!google::protobuf::TextFormat::ParseFromString(buf, &g_pbServerConfig))
        {
            printf("parse %s failed", cfg);
            return false;
        }
    }*/

    printf("load_config ok......");
    return true;
}

static int Init(lua_State *L)
{
    CAutoLock cl(&g_LuaLock);
    load_config("../config/GameFishingConfig.pb");
    boost::asio::io_service as;

    if ((g_bIsInit != false) && (g_bRun != false))
    {
        return 0;
    }

    boost::shared_ptr< boost::asio::io_service >  TempIoser(new boost::asio::io_service);
    boost::shared_ptr< boost::asio::io_service::work > TempWork(new boost::asio::io_service::work(*TempIoser));
    g_IoService = TempIoser;
    g_Work = TempWork;

    g_game_time_ = new GameTimeManager();
    g_TableMgr = new TableManager();
    GetReadTableName(L, "ServerInit");
    g_TableNum = GetTableItemInt(L, "TableNum");
    printf("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:%d", g_TableNum);
    g_iHandleNum = g_TableNum / 10 + 1;
    

    for (int x = 0; x < g_iHandleNum; ++x)
    {
        g_hThreadHandle[x] = CreateThread(0, 0, WorkerThread, &x, 0, NULL);
        Sleep(1);
    }
    for (int x = 0; x < g_TableNum; x++)
    {
        g_mapTable[x] = new CTableFrameSink();
    }
    g_bRun = true;
    if (g_bIsInit != false) return 0;
    REGISTER_OBJ_TYPE(EOT_PLAYER, CPlayer);
    REGISTER_OBJ_TYPE(EOT_BULLET, CBullet);
    REGISTER_OBJ_TYPE(EOT_FISH, CFish);

    REGISTER_EFFECT_TYPE(ETP_ADDMONEY, CEffectAddMoney);
    REGISTER_EFFECT_TYPE(ETP_KILL, CEffectKill);
    REGISTER_EFFECT_TYPE(ETP_ADDBUFFER, CEffectAddBuffer);
    REGISTER_EFFECT_TYPE(ETP_PRODUCE, CEffectProduce);
    REGISTER_EFFECT_TYPE(ETP_BLACKWATER, CEffectBlackWater);
    REGISTER_EFFECT_TYPE(ETP_AWARD, CEffectAward);

    REGISTER_BUFFER_TYPE(EBT_CHANGESPEED, CSpeedBuffer);
    REGISTER_BUFFER_TYPE(EBT_DOUBLE_CANNON, CDoubleCannon);
    REGISTER_BUFFER_TYPE(EBT_ION_CANNON, CIonCannon);
    REGISTER_BUFFER_TYPE(EBT_ADDMUL_BYHIT, CAddMulByHit);

    REGISTER_MYCOMPONENT_TYPE(EMCT_PATH, MoveByPath);
    REGISTER_MYCOMPONENT_TYPE(EMCT_DIRECTION, MoveByDirection);

    REGISTER_MYCOMPONENT_TYPE(EECT_MGR, EffectMgr);
    REGISTER_MYCOMPONENT_TYPE(EBCT_BUFFERMGR, BufferMgr);
    g_bIsInit = true;
    return 1;
}
void ServerStart()
{

}
static const luaL_Reg CallFishFun[] =
{
    { "CSTreasureEnd", CSTreasureEnd },
    { "CSChangeCannonSet", CSChangeCannonSet },
    { "CSNetcast", CSNetcast },
    { "CSLockFish", CSLockFish },
    { "CSFire", CSFire },
    { "CSChangeCannon", CSChangeCannon },
    { "CSTimeSync", CSTimeSync },
    { "CFishingInit", Init },    
    { "RepositionSink", RepositionSink },
    { "ActionUserSitDown", ActionUserSitDown },
    { "ActionUserStandUp", ActionUserStandUp },
    { "EventGameStart", EventGameStart },
    { "EventGameConclude", EventGameConclude },
    { "EventSendGameScene", EventSendGameScene },
    { "SetNickNameAndMoney", SetNickNameAndMoney },
    { "Stop", StopSever },    
    { NULL, NULL }
};
//dll通过函数luaI_openlib导出，然后lua使用package.loadlib导入库函数  
extern "C" __declspec(dllexport) int luaopen_GameFishingDLL(lua_State* L)//需要注意的地方,此函数命名与库名一致  
{
    g_bIsInit = false;
    g_bRun = false;
    g_LuaL = L;
    if (L == NULL)
    {
        g_LuaL = NULL;
    }
    lua_getglobal(L, "CallFishFun");
    if (lua_isnil(L, -1)) {
        lua_pop(L, 1);
        lua_newtable(L);
    }
    luaL_setfuncs(L, CallFishFun, 0);
    lua_setglobal(L, "CallFishFun");
    CTableFrameSink::LoadConfig();
    return 1;
}