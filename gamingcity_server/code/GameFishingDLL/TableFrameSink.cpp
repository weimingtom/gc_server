//
#include "common.h"
#include "TableFrameSink.h"
#include "GameConfig.h"
#include "MathAide.h"
#include "GameConfig.h"
#include "CommonLogic.h"
#include "PathManager.h"
#include "EventMgr.h"
#include <math.h>
#include <MMSystem.h>
//#include "ServerControl.h"
#include "IDGenerator.h"
#include "BufferManager.h"
#include "MyComponentFactory.h"

#include "GameLog.h"
#include "TableManager.h"
#include <codecvt>

#define IDI_GAMELOOP	1

#define TIME_GAMELOOP	1000/GAME_FPS

#define MAX_LIFE_TIME	30000
extern "C" {
#include"lua.hpp"
#include "lauxlib.h"
#include "lualib.h"
}
extern lua_State* g_LuaL;
extern CLock g_LuaLock;
extern boost::shared_ptr< boost::asio::io_service >  g_IoService;
//extern GameServerConfig				g_pbServerConfig;
//构造函数
CTableFrameSink::CTableFrameSink()
    : m_Timer(*g_IoService)
{
	m_nFishCount = 0;
	m_bRun = false;

	m_table_id = 0;
    Initialization();
	TableManager::instance()->add_table(this);
}

//析构函数
CTableFrameSink::~CTableFrameSink(void)
{
    //m_Timer.cancel();
	TableManager::instance()->remove_table(this);
}

VOID  CTableFrameSink::Release()
{
	/*for (uint16_t chair_id = 0; chair_id < MAX_TABLE_CHAIR; ++chair_id) {
		auto pUser = m_pITableFrame->GetTableUserItem(chair_id);
		if (pUser) {
		m_pITableFrame->DecUserRebateAndSaveToDB(pUser, 0);
		}
		}
		if(m_pITableFrame->IsGameStarted())
		m_pITableFrame->DismissGame();

		m_player.clear();
		m_SystemTimeStart.clear();
		m_NearFishPos.clear();*/
}

//初始化
bool  CTableFrameSink::Initialization()
{
	Bind_Event_Handler("ProduceFish", CTableFrameSink, OnProduceFish);
	Bind_Event_Handler("CannonSetChanaged", CTableFrameSink, OnCannonSetChange);
	Bind_Event_Handler("AddBuffer", CTableFrameSink, OnAddBuffer);
	Bind_Event_Handler("CatchFishBroadCast", CTableFrameSink, OnCatchFishBroadCast);
	Bind_Event_Handler("FirstFire", CTableFrameSink, OnFirstFire);
	Bind_Event_Handler("AdwardEvent", CTableFrameSink, OnAdwardEvent);
	Bind_Event_Handler("FishMulChange", CTableFrameSink, OnMulChange);

	m_player.resize(GAME_PLAYER);
	m_SystemTimeStart.resize(GAME_PLAYER);
	m_NearFishPos.resize(GAME_PLAYER);

	memset(user_win_scores_, 0, sizeof(user_win_scores_));
	memset(user_revenues_, 0, sizeof(user_revenues_));
	memset(user_score_pools_, 0, sizeof(user_score_pools_));

	return true;
}

void CTableFrameSink::LoadConfig()
{
	std::string path = "../data/fishing/";// g_pbServerConfig.data_path();
    printf("开始加载配置...\n");
	//LOG_DEBUG("开始加载配置...");
	DWORD dwStartTick = ::GetTickCount();

	CGameConfig::GetInstance()->LoadSystemConfig(path + "System.xml");

	CGameConfig::GetInstance()->LoadBoundBox(path + "BoundingBox.xml");

	CGameConfig::GetInstance()->LoadFish(path + "Fish.xml");


	PathManager::GetInstance()->LoadNormalPath(path + "path.xml");

	PathManager::GetInstance()->LoadTroop(path + "TroopSet.xml");

	CGameConfig::GetInstance()->LoadCannonSet(path + "CannonSet.xml");
	CGameConfig::GetInstance()->LoadBulletSet(path + "BulletSet.xml");

	CGameConfig::GetInstance()->LoadScenes(path + "Scene.xml");

	CGameConfig::GetInstance()->LoadSpecialFish(path + "Special.xml");

    dwStartTick = ::GetTickCount() - dwStartTick;
    printf("加载完成 总计耗时%g秒\n", dwStartTick / 1000.f);
	//LOG_DEBUG("加载完成 总计耗时%g秒", dwStartTick / 1000.f);
}
//重置桌子
void CTableFrameSink::ResetTable()
{

	m_FishManager.Clear();

	m_BulletManager.Clear();

	m_fPauseTime = 0.0f;

	m_nSpecialCount = 0;

	m_nFishCount = 0;

	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		m_player[i].ClearSet(i);
	}
}
//复位桌子
void  CTableFrameSink::RepositionSink()
{
	ResetTable();
}

//用户坐下
bool CTableFrameSink::OnActionUserSitDown(WORD wChairID, int GuID, bool bLookonUser)
{
	if (!bLookonUser)
	{
		if (wChairID >= GAME_PLAYER)
		{
			return false;
		}
		m_player[wChairID].ClearSet(wChairID);

		user_revenues_[wChairID] = 0;
		user_win_scores_[wChairID] = 0;
        
		//获取BUFF管理器
		BufferMgr* pBMgr = (BufferMgr*)m_player[wChairID].GetComponent(ECF_BUFFERMGR);
		if (pBMgr == NULL)
		{
			pBMgr = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
			if (pBMgr != NULL)
				m_player[wChairID].SetComponent(pBMgr);
		}

		if (pBMgr != NULL)
		{
			pBMgr->Clear();
		}
		else
		{
			return false;
        }
        TableManager::instance()->add_player_table(wChairID, GuID, 0, this);

	}
	return true;

}

//用户起立
bool  CTableFrameSink::OnActionUserStandUp(WORD wChairID, int GuID, bool bLookonUser)
{
	if (!bLookonUser)
	{
		if (wChairID >= GAME_PLAYER)
		{
			return false;
		}

		user_revenues_[wChairID] = 0;
		user_win_scores_[wChairID] = 0;
		// 将我们吃掉的分数退还给用户，下次可以尝试把吃掉的分数退还到用户返利里
		if (user_score_pools_[wChairID] > 0) {
			user_win_scores_[wChairID] -= user_score_pools_[wChairID];
			user_score_pools_[wChairID] = 0;
		}
		// 更新用户信息到数据库
		ReturnBulletScore(wChairID);

		WORD playerCount = 0;
		for (WORD i = 0; i < GAME_PLAYER; ++i)
		{
			if (m_player[i].get_guid() != 0)
				++playerCount;
		}

		if (playerCount == 0)
		{
			ResetTable();
		}
        m_player[wChairID].ClearSet(wChairID);
        TableManager::instance()->remove_player_table(GuID);
	}
	return true;
}


//游戏状态
bool  CTableFrameSink::IsUserPlaying(WORD wChairID)
{
	return true;
}

//游戏开始
bool  CTableFrameSink::OnEventGameStart()
{
	if (m_bRun)
		return false;

	ResetTable();

	m_dwLastTick = timeGetTime();

	m_nCurScene = CGameConfig::GetInstance()->SceneSets.begin()->first;
	m_fSceneTime = 0.0f;
	m_fPauseTime = 0.0f;
	m_bAllowFire = false;

	ResetSceneDistrub();

	//初始化随机种子
	RandSeed(timeGetTime());
	srand(timeGetTime());

	m_bRun = true;

    m_Timer.expires_from_now(boost::posix_time::millisec(1000 / 30));
    m_Timer.async_wait(boost::bind(&CTableFrameSink::OnGameUpdate, this));
	return true;
}
//重置场景
void CTableFrameSink::ResetSceneDistrub()
{
	//重置干扰鱼群刷新时间
	int sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.size();
	m_vDistrubFishTime.resize(sn);
	for (int i = 0; i < sn; ++i)
	{
		m_vDistrubFishTime[i] = 0;
	}

	//重置鱼群
	//获取场景刷新鱼时间组数
	sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.size();
	m_vDistrubTroop.resize(sn);//设置刷新鱼信息大小
	//初始化刷新信息
	for (int i = 0; i < sn; ++i)
	{
		m_vDistrubTroop[i].bSendDes = false;
		m_vDistrubTroop[i].bSendTroop = false;
		m_vDistrubTroop[i].fBeginTime = 0.0f;
	}
}

//结束原因
#define GER_NORMAL					0x00								//常规结束
#define GER_DISMISS					0x01								//游戏解散
#define GER_USER_LEAVE				0x02								//用户离开
#define GER_NETWORK_ERROR			0x03								//网络错误

//游戏结束
bool  CTableFrameSink::OnEventGameConclude(WORD wChairID, BYTE cbReason)
{
	switch (cbReason)
	{
	case GER_NORMAL:
	case GER_USER_LEAVE:
	case GER_NETWORK_ERROR:
	{
		//单个玩家，网络退出
		//ASSERT(wChairID < m_pITableFrame->GetChairCount());
		ReturnBulletScore(wChairID);
		m_player[wChairID].ClearSet(wChairID);

		m_player[wChairID].set_guid_gateid(0, 0);

		return true;
	}
	case GER_DISMISS:
	{   //所有玩家退出 清除所有信息
		for (WORD i = 0; i < GAME_PLAYER; ++i)
		{
			ReturnBulletScore(i);
			m_player[i].ClearSet(i);

			m_player[i].set_guid_gateid(0, 0);
		}
        m_bRun = false;
		return true;
	}
	}
	return false;
}

//发送场景
bool  CTableFrameSink::OnEventSendGameScene(WORD wChairID, BYTE cbGameStatus, bool bSendSecret)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        return false;
    }
	switch (cbGameStatus)
	{
	case GAME_STATUS_FREE:
	case GAME_STATUS_PLAY:
	{
		SendGameConfig(wChairID);
		SendAllowFire(wChairID);
		SendPlayerInfo(wChairID);

		/*TCHAR szInfo[256];
		_sntprintf_s(szInfo, _TRUNCATE, TEXT("当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币"),
		CGameConfig::GetInstance()->nChangeRatioUserScore, CGameConfig::GetInstance()->nChangeRatioFishScore);
		m_pITableFrame->SendGameMessage(pIServerUserItem, szInfo, SMT_CHAT);*/

		// 可优 1将字符串转为数值  2上边SendGameConfig 已经发送了nChangeRatioUserScore nChangeRatioFishScore 为何要重复发送 需要修改协议
		char szInfo[256];
		std::wstring str = TEXT("当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币");
		std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
		std::string narrowStr = conv.to_bytes(str);
		sprintf_s(szInfo, narrowStr.c_str(), CGameConfig::GetInstance()->nChangeRatioUserScore, CGameConfig::GetInstance()->nChangeRatioFishScore);

        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_SystemMessage");
        PushNumToTable(g_LuaL, "wtype", SMT_CHAT);
        PushStrToTable(g_LuaL, "szstring", szInfo);
        CallLuaFun(g_LuaL);
		return true;
	}
	}
	return false;
}
//发送游戏系统配置
void CTableFrameSink::SendGameConfig(WORD wChairID)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        return;
    }
    {
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_GameConfig");
        PushNumToTable(g_LuaL, "server_id", 1);
        PushNumToTable(g_LuaL, "change_ratio_fish_score", CGameConfig::GetInstance()->nChangeRatioFishScore);
        PushNumToTable(g_LuaL, "change_ratio_user_score", CGameConfig::GetInstance()->nChangeRatioUserScore);
        PushNumToTable(g_LuaL, "exchange_once", CGameConfig::GetInstance()->nExchangeOnce);
        PushNumToTable(g_LuaL, "fire_interval", CGameConfig::GetInstance()->nFireInterval);
        PushNumToTable(g_LuaL, "max_interval", CGameConfig::GetInstance()->nMaxInterval);
        PushNumToTable(g_LuaL, "min_interval", CGameConfig::GetInstance()->nMinInterval);
        PushNumToTable(g_LuaL, "show_gold_min_mul", CGameConfig::GetInstance()->nShowGoldMinMul);
        PushNumToTable(g_LuaL, "max_bullet_count", CGameConfig::GetInstance()->nMaxBullet);
        PushNumToTable(g_LuaL, "max_cannon", CGameConfig::GetInstance()->m_MaxCannon);
        CallLuaFun(g_LuaL);
    }
	// 可优 子弹配置？ 配置数据不需要发送
	int nb = CGameConfig::GetInstance()->BulletVector.size();
	for (int i = 0; i < nb; ++i)
	{
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_BulletSet");
        PushNumToTable(g_LuaL, "first", i == 0 ? 1 : 0);
        PushNumToTable(g_LuaL, "bullet_size", CGameConfig::GetInstance()->BulletVector[i].nBulletSize);
        PushNumToTable(g_LuaL, "cannon_type", CGameConfig::GetInstance()->BulletVector[i].nCannonType);
        PushNumToTable(g_LuaL, "catch_radio", CGameConfig::GetInstance()->BulletVector[i].nCatchRadio);
        PushNumToTable(g_LuaL, "max_catch", CGameConfig::GetInstance()->BulletVector[i].nMaxCatch);
        PushNumToTable(g_LuaL, "mulriple", CGameConfig::GetInstance()->BulletVector[i].nMulriple);
        PushNumToTable(g_LuaL, "speed", CGameConfig::GetInstance()->BulletVector[i].nSpeed);
        CallLuaFun(g_LuaL);

		//send2client_pb(wChairID, &cbs);
	}
}
//发送玩家信息
void CTableFrameSink::SendPlayerInfo(WORD wChairID)
{
	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		if (m_player[i].get_guid() != 0)
		{

            CAutoLock cl(&g_LuaLock);
            CreatLuaPackage(g_LuaL, "on_Send2_pb", m_player[i].get_guid(), "SC_UserInfo");
            PushNumToTable(g_LuaL, "chair_id", i);
            PushNumToTable(g_LuaL, "score", m_player[i].GetScore());
            PushNumToTable(g_LuaL, "cannon_mul", m_player[i].GetMultiply());
            PushNumToTable(g_LuaL, "cannon_type", m_player[i].GetCannonType());
            PushNumToTable(g_LuaL, "wastage", m_player[i].GetWastage());
            CallLuaFun(g_LuaL);

		}
	}
}

int   CTableFrameSink::GetPlayerGuID(WORD wChairID)
{
    if (INVALID_CHAIR == wChairID)
    {
        return 0;
    }

    if (wChairID >= m_player.size())
    {
        LOG_WARN("wChairID %d out of range[0,%d)", wChairID, m_player.size());
        return 0;
    }

    return m_player[wChairID].get_guid();
}
bool    CTableFrameSink::GetOnePlayerGuID(int &GuID)
{
    for (WORD i = 0; i < GAME_PLAYER; ++i)
    {
        if (m_player[i].get_guid() != 0)
        {
            GuID = m_player[i].get_guid();
        }
        return true;
    }
    return false;
}
//发送场景信息
void CTableFrameSink::SendSceneInfo(WORD wChairID)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        return;
    }
    {
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_SwitchScene");
        PushNumToTable(g_LuaL, "switching", 0);
        PushNumToTable(g_LuaL, "nst", m_nCurScene);

        CallLuaFun(g_LuaL);
    }

	//send2client_pb(wChairID, &css);


	m_BulletManager.Lock();
	obj_table_iter ibu = m_BulletManager.Begin();
	while (ibu != m_BulletManager.End())
	{
		CBullet* pBullet = (CBullet*)ibu->second;
		//发送子弹
		SendBullet(pBullet, wChairID);
		++ibu;
	}
	m_BulletManager.Unlock();

	m_FishManager.Lock();
	obj_table_iter ifs = m_FishManager.Begin();
	while (ifs != m_FishManager.End())
	{
		CFish* pFish = (CFish*)ifs->second;
		SendFish(pFish, wChairID);
		++ifs;
	}
	m_FishManager.Unlock();
}
//发送是否允许开火
void CTableFrameSink::SendAllowFire(WORD wChairID)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        return;
    }
    CAutoLock cl(&g_LuaLock);
    CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_AllowFire");
    PushNumToTable(g_LuaL, "allow_fire", m_bAllowFire ? 1 : 0);
    CallLuaFun(g_LuaL);
}

//定时器事件
bool CTableFrameSink::OnTimerMessage(DWORD wTimerID, WPARAM wBindParam)
{
	switch (wTimerID)
	{
	case IDI_GAMELOOP:
	{
		OnGameUpdate();
	}
	break;
	}
	return true;
}

stLuaMsg * CTableFrameSink::GetMsg()
{
    stLuaMsg * pTemp = NULL;
    CAutoLock cl(&m_LockLuaMsg);
    if (!m_lsLuaMsg.empty())
    {
        pTemp = m_lsLuaMsg.front();
        m_lsLuaMsg.pop_front();
    }
    return pTemp;
}
void    CTableFrameSink::PushMsg(stLuaMsg *Msg)
{
    CAutoLock cl(&m_LockLuaMsg);
    m_lsLuaMsg.push_back(Msg);
}
void CTableFrameSink::OnDealLuaMsg()
{
    stLuaMsg * pTemp = NULL;
    while (NULL != (pTemp = GetMsg()))
    {
        switch (pTemp->m_iMsgID)
        {
        case enMsgType_TreasureEnd:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnTreasureEND((CS_stTreasureEnd *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_ChangeCannonSet:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnChangeCannonSet((CS_stChangeCannonSet *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_Netcast:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnNetCast((CS_stNetcast *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_LockFish:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnLockFish((CS_stLockFish *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_Fire:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnFire((CS_stFire *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_ChangeCannon:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnChangeCannon((CS_stChangeCannon *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_TimeSync:
        {
            if (pTemp->m_pMsg != NULL)
            {
                OnTimeSync((CS_stTimeSync *)pTemp->m_pMsg);
            }
        }
        break;
        case enMsgType_RepositionSink:
        {
            RepositionSink();
        }
        break;
        case enMsgType_ActionUserSitDown:
        {
            if (pTemp->m_pMsg != NULL)
            {
                stLuaMsgType * pstTemp = (stLuaMsgType *)pTemp->m_pMsg;
                OnActionUserSitDown(pstTemp->cbByte, pstTemp->wValue, pstTemp->bRet);
            }
        }
        break;
        case enMsgType_ActionUserStandUp:
        {
            if (pTemp->m_pMsg != NULL)
            {
                stLuaMsgType * pstTemp = (stLuaMsgType *)pTemp->m_pMsg;
                OnActionUserStandUp(pstTemp->cbByte, pstTemp->wValue, pstTemp->bRet);
            }
        }
        break;
        case enMsgType_EventGameStart:
        {
            OnEventGameStart();
        }
        break;
        case enMsgType_EventGameConclude:
        {
            if (pTemp->m_pMsg != NULL)
            {
                stLuaMsgType * pstTemp = (stLuaMsgType *)pTemp->m_pMsg;
                OnEventGameConclude(pstTemp->wValue, pstTemp->cbByte);
            }
        }
        break;
        case enMsgType_EventSendGameScene:
        {
            if (pTemp->m_pMsg != NULL)
            {
                stLuaMsgType * pstTemp = (stLuaMsgType *)pTemp->m_pMsg;
                OnEventSendGameScene(pstTemp->wValue, pstTemp->cbByte, pstTemp->bRet);
            }
        }
        break;
        case enMsgType_SetNickNameAndMoney:
        {
            if (pTemp->m_pMsg != NULL)
            {
                stLuaMsgType * pstTemp = (stLuaMsgType *)pTemp->m_pMsg;
                set_nickname(pstTemp->wValue, pstTemp->strValue.c_str());
                set_money(pstTemp->wValue, pstTemp->lValue);
            }
        }
        break;
        case enMsgType_AddPlayerTable:
        {
        }
        break;
        case enMsgType_RemovePlayerTable:
        {
        }
        break;
        }
    }
}
//游戏状态更新
void CTableFrameSink::OnGameUpdate()
{
	if (!m_bRun)
		return;

	DWORD NowTime = timeGetTime();
	int ndt = NowTime - m_dwLastTick;
	float fdt = ndt / 1000.0f;

	bool hasR = HasRealPlayer();

	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		if (m_player[i].get_guid() == 0)
			continue;
		//处理玩家事件
		m_player[i].OnUpdate(ndt);
		//有玩家存在且玩家锁定了鱼
		if (m_player[i].bLocking())
		{
			//当玩家锁定鱼时判断鱼ID，是否存在
			if (m_player[i].GetLockFishID() == 0)
			{
				//ID= 0 重新锁定
				LockFish(i);
				if (m_player[i].GetLockFishID() == 0)
					m_player[i].SetLocking(false);
			}
			else
			{
				CFish* pFish = (CFish*)m_FishManager.Find(m_player[i].GetLockFishID());
				if (pFish == NULL || !pFish->InSideScreen())
				{//当鱼不存在或鱼已经出屏幕，重新锁定
					LockFish(i);
					if (m_player[i].GetLockFishID() == 0)
						m_player[i].SetLocking(false);
				}
			}
		}
	}
	//清理可锁定列表
	m_CanLockList.clear();
	//清理鱼数量
	m_nFishCount = 0;

	//移除队列
	std::list<DWORD> rmList;
	//特殊鱼清0
	m_nSpecialCount = 0;

	m_FishManager.Lock();
	obj_table_iter ifs = m_FishManager.Begin();
	while (ifs != m_FishManager.End())
	{
		CFish* pFish = (CFish*)ifs->second;
		//处理鱼事件
		pFish->OnUpdate(ndt);
		MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
		if (pMove == NULL || pMove->IsEndPath())
		{//移动组件为空或 已经移动到结束
			if (pMove != NULL && pFish->InSideScreen())
			{//移动组件存且移动结束，但还在屏幕内 改为按指定方向移动
				MoveCompent* pMove2 = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
				if (pMove2 != NULL)
				{
					pMove2->SetSpeed(pMove->GetSpeed());
					pMove2->SetDirection(pMove->GetDirection());
					pMove2->SetPosition(pMove->GetPostion());
					pMove2->InitMove();
					//SetComponent有清除旧组件功能
					pFish->SetComponent(pMove2);
				}
			}
			else
			{//否则添加到移除列表
				rmList.push_back(pFish->GetId());
			}
		}
		else if (pFish->GetFishType() != ESFT_NORMAL)
		{//钱类型不等于普通鱼 特殊鱼+1
			++m_nSpecialCount;
		}

		if (hasR && pFish->InSideScreen())
		{//还在屏幕内
			if (pFish->GetLockLevel() > 0)
			{//锁定等级大于0 加入可锁定列表
				m_CanLockList.push_back(pFish->GetId());
			}
			//鱼数量+1
			++m_nFishCount;
		}
		++ifs;
	}
	m_FishManager.Unlock();
	//清除鱼
	std::list<DWORD>::iterator it = rmList.begin();
	while (it != rmList.end())
	{
		m_FishManager.Remove(*it);
		++it;
	}
	rmList.clear();
	//子弹
	m_BulletManager.Lock();
	obj_table_iter ibu = m_BulletManager.Begin();
	while (ibu != m_BulletManager.End())
	{
		CBullet* pBullet = (CBullet*)ibu->second;
		//处理子弹事件
		pBullet->OnUpdate(ndt);
		//获取移动组件
		MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
		if (pMove == NULL || pMove->IsEndPath())
		{//当没有移动组件或已经移动到终点 加入到清除列表
			rmList.push_back(pBullet->GetId());
		}
		//不需要直接判断？
		else if (CGameConfig::GetInstance()->bImitationRealPlayer && !hasR)
		{//如果开起模拟 且 无玩家？
			{
				ifs = m_FishManager.Begin();
                int GuID = 0;
                GetOnePlayerGuID(GuID);
				while (ifs != m_FishManager.End())
				{
					CFish* pFish = (CFish*)ifs->second;
					//只要鱼没死 判断 是否击中鱼
					if (pFish->GetState() < EOS_DEAD && pBullet->HitTest(pFish))
					{
						//发送清除子弹
                        if (GuID != 0)
                        {
                            CAutoLock cl(&g_LuaLock);
                            CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_KillBullet");
                            PushNumToTable(g_LuaL, "chair_id", pBullet->GetChairID());
                            PushNumToTable(g_LuaL, "bullet_id", pBullet->GetId());
                            CallLuaFun(g_LuaL);
                        }
						//抓捕鱼   //抓住后 Remove 不会破坏ifs？
						CatchFish(pBullet, pFish, 1, 0);
						//子弹加入清除列表
						rmList.push_back(pBullet->GetId());
						break;
					}
					++ifs;
				}
			}
		}

		++ibu;
	}

	m_BulletManager.Unlock();

	it = rmList.begin();
	while (it != rmList.end())
	{
		m_BulletManager.Remove(*it);
		++it;
	}
	rmList.clear();

	DWORD tEvent = timeGetTime();
	CEventMgr::GetInstance()->Update(ndt);
	tEvent = timeGetTime() - tEvent;

	//场景处理包换刷新鱼
	DistrubFish(fdt);

	m_dwLastTick = NowTime;

    m_Timer.expires_from_now(boost::posix_time::millisec(1000/30));
    m_Timer.async_wait(boost::bind(&CTableFrameSink::OnGameUpdate, this));
}
//判断是否有玩家在
bool CTableFrameSink::HasRealPlayer()
{
	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		if (m_player[i].get_guid() != 0)
			return true;
	}

	return false;
}
//抓捕鱼
void CTableFrameSink::CatchFish(CBullet* pBullet, CFish* pFish, int nCatch, int* nCatched)
{
	//获取子弹 对鱼类型的概率值
	float pbb = pBullet->GetProbilitySet(pFish->GetTypeID()) / MAX_PROBABILITY;
	//获取鱼被抓捕概率值
	float pbf = pFish->GetProbability() / nCatch;
	//设置倍率
	float fPB = 1.0f;

	//获取安卓增加值
	fPB = CGameConfig::GetInstance()->fAndroidProbMul;

	std::list<MyObject*> list;      //存放被捕捉鱼 解除其它玩家锁定用

	bool bCatch = false;        //是否抓到
	SCORE lScore = 0;           //价值积分
	auto chair_id = pBullet->GetChairID();  //获取子弹所属玩家
//	ASSERT(chair_id < MAX_TABLE_CHAIR);


	//判断是否抓到（子弹抓这类鱼的概率*这类鱼被抓的概率*倍率）
	bCatch = RandFloat(0, MAX_PROBABILITY) < pbb * pbf * fPB;
	if (bCatch)
	{
		//抓到，执行鱼被抓效果
		lScore = CommonLogic::GetFishEffect(pBullet, pFish, list, false);
	}

	auto score_pool = user_score_pools_[chair_id];
	if (!bCatch && score_pool > 0)
	{// 如果当前没有成功捕获 并且玩家有被吃的子弹
		bCatch = score_pool > lScore;// 如果吃掉玩家的分数大于鱼的分数，优先给玩家退还吃掉的分数
		if (bCatch)
		{// 吃的分数被退还了
			user_score_pools_[chair_id] -= lScore;
		}
	}


	// del lee for test
	//pFish->SetState(EOS_HIT, pBullet);

	if (bCatch)
	{
		//{
		//	// 在上边执行了一次？ 又执行一次？ 可优？
		//	std::list<MyObject*> ll;
		//	LONGLONG lst = CommonLogic::GetFishEffect(pBullet, pFish, ll, false);
		//	ll.clear();
		//}


		m_player[pBullet->GetChairID()].AddScore(lScore);

		user_win_scores_[chair_id] += lScore;

		//能量炮 当鱼的值/炮弹值 大于 能量炮机率 且 随机值 小于能量炮率 为玩家获取双倍炮BUFF
		if (lScore / pBullet->GetScore() > CGameConfig::GetInstance()->nIonMultiply && RandInt(0, MAX_PROBABILITY) < CGameConfig::GetInstance()->nIonProbability)
		{
			BufferMgr* pBMgr = (BufferMgr*)m_player[pBullet->GetChairID()].GetComponent(ECF_BUFFERMGR);
			if (pBMgr != NULL && !pBMgr->HasBuffer(EBT_DOUBLE_CANNON))
			{
				pBMgr->Add(EBT_DOUBLE_CANNON, 0, CGameConfig::GetInstance()->fDoubleTime);
				//可优，直接是发送 SendCannonSet
				//RaiseEvent("CannonSetChanaged", &(m_player[pBullet->GetChairID()]));
				SendCannonSet(pBullet->GetChairID());
			}
		}

		//发送抓捕
		SendCatchFish(pBullet, pFish, lScore);

		//解除其它玩家锁定
		std::list<MyObject*>::iterator im = list.begin();
		while (im != list.end())
		{
			CFish* pf = (CFish*)*im;
			for (WORD i = 0; i < GAME_PLAYER; ++i)
			{
				if (m_player[i].GetLockFishID() == pf->GetId())
				{
					m_player[i].SetLockFishID(0);
				}
			}
			if (pf != pFish)
			{
				m_FishManager.Remove(pf);
			}
			++im;
		}
		//移除鱼
		m_FishManager.Remove(pFish);

		//用处不明 调用全为空 可优
		if (nCatched != NULL)
			*nCatched = *nCatched + 1;
	}
}
//发送鱼被抓
void CTableFrameSink::SendCatchFish(CBullet* pBullet, CFish*pFish, LONGLONG score)
{
    int GuID = 0;
    if (!GetOnePlayerGuID(GuID))
    {
        return;
    }
	if (pBullet != NULL && pFish != NULL)
	{
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_KillFish");
        PushNumToTable(g_LuaL, "chair_id", pBullet->GetChairID());
        PushNumToTable(g_LuaL, "fish_id", pFish->GetId());
        PushNumToTable(g_LuaL, "score", score);
        PushNumToTable(g_LuaL, "bscoe", pBullet->GetScore());
        CallLuaFun(g_LuaL);
	}
}
//给所有鱼添加BUFF
void CTableFrameSink::AddBuffer(int btp, float parm, float ft)
{
    int GuID = 0;
    if(GetOnePlayerGuID(GuID))
    {
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_AddBuffer");
        PushNumToTable(g_LuaL, "buffer_type", btp);
        PushNumToTable(g_LuaL, "buffer_param", parm);
        PushNumToTable(g_LuaL, "buffer_time", ft);
        CallLuaFun(g_LuaL);
    }

	m_FishManager.Lock();
	obj_table_iter ifs = m_FishManager.Begin();
	while (ifs != m_FishManager.End())
	{
		MyObject* pObj = ifs->second;
		BufferMgr* pBM = (BufferMgr*)pObj->GetComponent(ECF_BUFFERMGR);
		if (pBM != NULL)
		{
			pBM->Add(btp, parm, ft);
		}
		++ifs;
	}
	m_FishManager.Unlock();
}
//场景处理 包括场景更换 鱼刷新
void CTableFrameSink::DistrubFish(float fdt)
{
	if (m_fPauseTime > 0.0f)
	{
		m_fPauseTime -= fdt;
		return;
	}
	//场景时间增加
	m_fSceneTime += fdt;
	//时间大于场景准备时间，且不可开火 INVALID_CHAIR群发可开火命令 可优，是否应该出现在此处改为时间回调
	if (m_fSceneTime > SWITCH_SCENE_END && !m_bAllowFire)
	{
		m_bAllowFire = true;
		SendAllowFire(INVALID_CHAIR);
	}
	//判断当前场景是否存在
	if (CGameConfig::GetInstance()->SceneSets.find(m_nCurScene) == CGameConfig::GetInstance()->SceneSets.end())
	{
		return;
	}
	//场景时间是否小于场景持续时间
	if (m_fSceneTime < CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime)
	{
		int npos = 0;
		//获取当前场景的刷鱼时间列表
		std::list<TroopSet>::iterator is = CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.begin();
		while (is != CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.end())
		{
			TroopSet &ts = *is;
			//是否无玩家存在
			if (!HasRealPlayer())
			{
				//当场景时间　是否为刷鱼时间　
				if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime))
				{
					//是则置为刷鱼结束时间
					m_fSceneTime = ts.fEndTime + fdt;
				}
			}
			//当场景时间　是否为刷鱼时间　
			if ((m_fSceneTime >= ts.fBeginTime) && (m_fSceneTime <= ts.fEndTime))
			{
				//当循环小于刷新鱼信息数量
				if (npos < m_vDistrubTroop.size())
				{
					int tid = ts.nTroopID;
					//是否发送描述 可优 描述无需发送吧
					if (!m_vDistrubTroop[npos].bSendDes)
					{
						//给所有鱼加速度BUFF
						AddBuffer(EBT_CHANGESPEED, 5, 60);
						//获取刷新鱼群描述信息
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp != NULL)
						{
							//获取总描述数量
							size_t nCount = ptp->Describe.size();
							//大于4条则只发送4条
							if (nCount > 4) nCount = 4;
							//配置刷新时间开始时间 为 2秒
							m_vDistrubTroop[npos].fBeginTime = nCount * 2.0f;//每条文字分配2秒的显示时间
                            //发送描述  可优 改为发送ID
                            int Guid;
                            if (GetOnePlayerGuID(Guid))
                            {
                                CAutoLock cl(&g_LuaLock);
                                CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", Guid, "SC_SendDes");
                                for (int i = 0; i < nCount; ++i)
                                {
                                    PushStrToTable(g_LuaL, "des", (char *)ptp->Describe[i].c_str());
                                }
                                CallLuaFun(g_LuaL);
                            }
						}
						//设置为已发送
						m_vDistrubTroop[npos].bSendDes = true;
					}
					else if (!m_vDistrubTroop[npos].bSendTroop && m_fSceneTime > (m_vDistrubTroop[npos].fBeginTime + ts.fBeginTime))
					{//如果没有发送过鱼群且 场景时间 大于 刷新时间加描述滚动时间
						m_vDistrubTroop[npos].bSendTroop = true;
						//获取刷新鱼群描述信息
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp == NULL)
						{
							//如果为空，则换下一场景
							m_fSceneTime += CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime;
						}
						else
						{
							int n = 0;
							int ns = ptp->nStep.size();    //获取步数 意义不明
							for (int i = 0; i < ns; ++i)
							{
								//刷鱼的ID
								int Fid = -1;
								//获取总步数
								int ncount = ptp->nStep[i];
								for (int j = 0; j < ncount; ++j)
								{
									//n大于 总形状点时 退出循环
									if (n >= ptp->Shape.size()) break;
									//获取形状点
									ShapePoint& tp = ptp->Shape[n++];
									//总权重
									int WeightCount = 0;
									//获取鱼类型列表和权重列表最小值
									int nsz = min(tp.m_lTypeList.size(), tp.m_lWeight.size());
									//如果为0就跳过本次
									if (nsz == 0) continue;
									//获取总权重
									for (int iw = 0; iw < nsz; ++iw)
										WeightCount += tp.m_lWeight[iw];

									for (int ni = 0; ni < tp.m_nCount; ++ni)
									{
										if (Fid == -1 || !tp.m_bSame)
										{
											//第几个鱼目标
											int wpos = 0;
											//随机权重
											int nf = RandInt(0, WeightCount);
											//运算匹配的权重
											while (nf > tp.m_lWeight[wpos])
											{
												//大于或等于权重最大值就跳出
												if (wpos >= tp.m_lWeight.size()) break;
												//随机值减去当前权重
												nf -= tp.m_lWeight[wpos];
												//目标加1
												++wpos;
												//如果大于鱼类型列表 
												if (wpos >= nsz)
													wpos = 0;
											}
											//随机位置小于鱼列表 获取 鱼ID
											if (wpos < tp.m_lTypeList.size())
												Fid = tp.m_lTypeList[wpos];
										}
										//查找鱼
										std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
										if (ift != CGameConfig::GetInstance()->FishMap.end())
										{
											Fish &finf = ift->second;
											CFish* pFish = CommonLogic::CreateFish(finf, tp.x, tp.y, 0.0f, ni*tp.m_fInterval, tp.m_fSpeed, tp.m_nPathID, true);
											if (pFish != NULL)
											{
												m_FishManager.Add(pFish);
												SendFish(pFish);
											}
										}
									}
								}
							}
						}
					}
				}
				return;
			}

			++is;
			++npos;
		}
		//如果场景时间大于 场景开始选择时间
		if (m_fSceneTime > SWITCH_SCENE_END)
		{
			int nfpos = 0;
			//获取干扰鱼列表
			std::list<DistrubFishSet>::iterator it = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.begin();
			while (it != CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.end())
			{
				//当前场景 干扰鱼群集
				DistrubFishSet &dis = *it;

				if (nfpos >= m_vDistrubFishTime.size())
				{
					break;
				}
				m_vDistrubFishTime[nfpos] += fdt;
				//[nfpos]干扰鱼刷新时间 加上 当前时间跳动时间 大于刷新时间
				if (m_vDistrubFishTime[nfpos] > dis.ftime)
				{
					//清除一个刷新时间
					m_vDistrubFishTime[nfpos] -= dis.ftime;
					//是否当前有玩家在
					if (HasRealPlayer())
					{
						//获取权重和鱼列表最小值
						int nsz = min(dis.Weight.size(), dis.FishID.size());
						//总权重
						int WeightCount = 0;
						//刷新鱼数量    随机一个刷新最小值到最大值
						int nct = RandInt(dis.nMinCount, dis.nMaxCount);
						//总刷新数量
						int nCount = nct;
						//蛇类型？
						int SnakeType = 0;
						//类型是否等于大蛇 刷新数量加2
						if (dis.nRefershType == ERT_SNAK)
						{
							nCount += 2;
							nct += 2;
						}

						//获取一个刷新ID
						DWORD nRefershID = IDGenerator::GetInstance()->GetID64();

						//获取总权重
						for (int wi = 0; wi < nsz; ++wi)
							WeightCount += dis.Weight[wi];

						//鱼与权重必须大于1
						if (nsz > 0)
						{
							//鱼ID
							int ftid = -1;
							//获取一个普通路径ID
							int pid = PathManager::GetInstance()->GetRandNormalPathID();
							while (nct > 0)
							{
								//普通鱼
								if (ftid == -1 || dis.nRefershType == ERT_NORMAL)
								{
									if (WeightCount == 0)
									{//权重为0 
										ftid = dis.FishID[0];
									}
									else
									{
										//权重随机
										int wpos = 0, nw = RandInt(0, WeightCount);
										while (nw > dis.Weight[wpos])
										{
											if (wpos < 0 || wpos >= dis.Weight.size()) break;
											nw -= dis.Weight[wpos];
											++wpos;
											if (wpos >= nsz)
												wpos = 0;
										}
										if (wpos >= 0 || wpos < dis.FishID.size())
											ftid = dis.FishID[wpos];
									}

									SnakeType = ftid;
								}
								//如果是刷大蛇，获取头和尾
								if (dis.nRefershType == ERT_SNAK)
								{
									if (nct == nCount)
										ftid = CGameConfig::GetInstance()->nSnakeHeadType;
									else if (nct == 1)
										ftid = CGameConfig::GetInstance()->nSnakeTailType;
								}
								//查找鱼
								std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(ftid);
								if (ift != CGameConfig::GetInstance()->FishMap.end())
								{
									Fish &finf = ift->second;
									//类型普通
									int FishType = ESFT_NORMAL;
									//随机偏移值
									float xOffest = RandFloat(-dis.OffestX, dis.OffestX);
									float yOffest = RandFloat(-dis.OffestY, dis.OffestY);
									//随机延时时间
									float fDelay = RandFloat(0.0f, dis.OffestTime);
									//如果是线或大蛇 则不随机
									if (dis.nRefershType == ERT_LINE || dis.nRefershType == ERT_SNAK)
									{
										xOffest = dis.OffestX;
										yOffest = dis.OffestY;
										fDelay = dis.OffestTime * (nCount - nct);
									}
									else if (dis.nRefershType == ERT_NORMAL && m_nSpecialCount < CGameConfig::GetInstance()->nMaxSpecailCount)
									{
										std::map<int, SpecialSet>* pMap = NULL;
										//试着随机到谋一种特殊鱼
										int nrand = rand() % 100;
										int fft = ESFT_NORMAL;

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_KING])
										{
											pMap = &(CGameConfig::GetInstance()->KingFishMap);
											fft = ESFT_KING;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_KING];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_KINGANDQUAN])
										{
											pMap = &(CGameConfig::GetInstance()->KingFishMap);
											fft = ESFT_KINGANDQUAN;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_KINGANDQUAN];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_SANYUAN])
										{
											pMap = &(CGameConfig::GetInstance()->SanYuanFishMap);
											fft = ESFT_SANYUAN;
										}
										else
										{
											nrand -= CGameConfig::GetInstance()->nSpecialProb[ESFT_SANYUAN];
										}

										if (nrand < CGameConfig::GetInstance()->nSpecialProb[ESFT_SIXI])
										{
											pMap = &(CGameConfig::GetInstance()->SiXiFishMap);
											fft = ESFT_SIXI;
										}
										//判断是否随机到特殊鱼
										if (pMap != NULL)
										{
											std::map<int, SpecialSet>::iterator ist = pMap->find(ftid);
											if (ist != pMap->end())
											{
												SpecialSet& kks = ist->second;
												//对特殊鱼进行随机判断是否生成
												if (RandFloat(0, MAX_PROBABILITY) < kks.fProbability)
													FishType = fft;
											}
										}
									}
									//生成鱼
									CFish* pFish = CommonLogic::CreateFish(finf, xOffest, yOffest, 0.0f, fDelay, finf.nSpeed, pid, false, FishType);
									if (pFish != NULL)
									{
										//设置鱼ID
										pFish->SetRefershID(nRefershID);
										m_FishManager.Add(pFish);
										SendFish(pFish);
									}
								}

								if (ftid == CGameConfig::GetInstance()->nSnakeHeadType)
									ftid = SnakeType;

								--nct;
							}
						}
					}
				}
				++it;
				++nfpos;
			}
		}
	}
	else
	{//当场景时间大于场景持续时间 切换场景
		//获取下一场景ID 并判断是否存在
		int nex = CGameConfig::GetInstance()->SceneSets[m_nCurScene].nNextID;
		if (CGameConfig::GetInstance()->SceneSets.find(nex) != CGameConfig::GetInstance()->SceneSets.end())
		{
			m_nCurScene = nex;
		}
		//重置场景
		ResetSceneDistrub();
		//清除玩家 锁定鱼 及锁定状态 子弹
        int GuID = 0;
		for (WORD wc = 0; wc < GAME_PLAYER; ++wc)
		{
			m_player[wc].SetLocking(false);
			m_player[wc].SetLockFishID(0);
			m_player[wc].ClearBulletCount();
            if (m_player[wc].get_guid() == 0)
            {
                continue;
            }
            GuID = m_player[wc].get_guid();
            //发送 锁定信息
            CAutoLock cl(&g_LuaLock);
            CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", m_player[wc].get_guid(), "SC_LockFish");
            PushNumToTable(g_LuaL, "chair_id", wc);
            CallLuaFun(g_LuaL);
		}

		//设定不可开火 并发送
		m_bAllowFire = false;
        SendAllowFire(INVALID_CHAIR);

        //发送场景替换
        if (GuID != 0)
        {
            CAutoLock cl(&g_LuaLock);
            CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_SwitchScene");
            PushNumToTable(g_LuaL, "nst", m_nCurScene);
            PushNumToTable(g_LuaL, "switching", 1);
            CallLuaFun(g_LuaL);
        }

		//清除鱼
		m_FishManager.Clear();
		//m_BulletManager.Clear();

		m_fSceneTime = 0.0f;
	}
}
//获取总玩家数 可优，每次循环获取？
int	CTableFrameSink::CountPlayer()
{
	int n = 0;

	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		if (m_player[i].get_guid() != 0)
			++n;
	}

	return n;
}
//发送鱼数据
void CTableFrameSink::SendFish(CFish* pFish, WORD wChairID)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        return;
    }
	std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(pFish->GetTypeID());
	if (ift != CGameConfig::GetInstance()->FishMap.end())
	{
		Fish finf = ift->second;

        MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
        BufferMgr* pBM = (BufferMgr*)pFish->GetComponent(ECF_BUFFERMGR);

        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", GuID, "SC_SendFish");

        PushNumToTable(g_LuaL, "fish_id", pFish->GetId());
        PushNumToTable(g_LuaL, "type_id", pFish->GetTypeID());
        PushNumToTable(g_LuaL, "create_tick", pFish->GetCreateTick());
        PushNumToTable(g_LuaL, "fis_type", pFish->GetFishType());
        PushNumToTable(g_LuaL, "refersh_id", pFish->GetRefershID());

		if (pMove != NULL)
        {
            PushNumToTable(g_LuaL, "path_id", pMove->GetPathID());
			if (pMove->GetID() == EMCT_DIRECTION)
            {
                PushNumToTable(g_LuaL, "offest_x", pMove->GetPostion().x_);
                PushNumToTable(g_LuaL, "offest_y", pMove->GetPostion().y_);
			}
            else
            {
                PushNumToTable(g_LuaL, "offest_x", pMove->GetOffest().x_);
                PushNumToTable(g_LuaL, "offest_y", pMove->GetOffest().y_);
            }
            PushNumToTable(g_LuaL, "dir", pMove->GetDirection());
            PushNumToTable(g_LuaL, "delay", pMove->GetDelay());
            PushNumToTable(g_LuaL, "fish_speed", pMove->GetSpeed());
            PushNumToTable(g_LuaL, "troop", pMove->bTroop() ? 1 : 0);
		}

		if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT))
		{
			PostEvent("FishMulChange", pFish);
		}
        PushNumToTable(g_LuaL, "server_tick", timeGetTime());

        CallLuaFun(g_LuaL);
		// 		css.bSpecial = pFish->bSpecial();
	}
}

//游戏消息处理
/*bool  CTableFrameSink::OnGameMessage(WORD wSubCmdID,  void * pDataBuffer, WORD wDataSize, IServerUserItem * pIServerUserItem)
{
switch(wSubCmdID)
{
case SUB_C_TIME_SYNC:
{
return OnTimeSync(pDataBuffer, wDataSize);
}
case SUB_C_CHANGE_SCORE:
{
return OnChangeScore(pDataBuffer, wDataSize, pIServerUserItem);
}
case SUB_C_CHANAGE_CANNON:
{
return OnChangeCannon(pDataBuffer, wDataSize);
}
case SUB_C_FIRE:
{
return OnFire(pDataBuffer, wDataSize, pIServerUserItem);
}
case SUB_C_ENDGAME:
{
//m_pITableFrame->PerformStandUpAction(pIServerUserItem);
// 			if (m_pITableFrame->PerformStandUpAction(pIServerUserItem) == false)
// 				CTraceService::TraceStringEx(TraceLevel_Debug, TEXT("站起失败221  %d %d=%s"), pIServerUserItem->GetTableID(), pIServerUserItem->GetChairID(), pIServerUserItem->GetNickName());
return true;
}
case SUB_C_LOCK_FISH:
{
return OnLockFish(pDataBuffer, wDataSize);
}
case SUB_C_BREADY:
{
SendSceneInfo(pIServerUserItem->GetChairID());
return true;
}
case SUB_C_NETCAST:
{
return OnNetCast(pDataBuffer, wDataSize);
}
case SUB_C_CHANGE_CANNONSET:
{
return OnChangeCannonSet(pDataBuffer, wDataSize);
}
case SUB_C_TREASURE_END:
{
return OnTreasureEND(pDataBuffer, wDataSize);
}
case SUB_C_RELOAD_CONFIG:
{
if(CUserRight::IsGameCheatUser(pIServerUserItem->GetUserRight()))
{
LoadConfig();
}
return true;
}
case SUB_C_TURN_ON_CONTROL:
{
if(CUserRight::IsGameCheatUser(pIServerUserItem->GetUserRight()))
{
ServerManager::InitControl();

if(ServerManager::m_pControl != NULL && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
ServerManager::m_pControl->Initialization(m_pITableFrame, m_pGameServiceOption, (float)CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore);
}
return true;
}
case SUB_C_TURN_OFF_CONTROL:
{
if(CUserRight::IsGameCheatUser(pIServerUserItem->GetUserRight()))
{
if(ServerManager::m_pControl != NULL && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
ServerManager::FreeControl();
}
return true;
}
default:
{
if(CUserRight::IsGameCheatUser(pIServerUserItem->GetUserRight()))
{
if(ServerManager::m_pControl != NULL && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
{
return ServerManager::m_pControl->RecvControlReq(m_pITableFrame, wSubCmdID, pDataBuffer, wDataSize, pIServerUserItem->GetChairID());
}

return true;
}
}
}

return false;
}*/
//改变大炮集
bool CTableFrameSink::OnChangeCannonSet(CS_stChangeCannonSet* msg)
{
	if (msg->chair_id >= GAME_PLAYER) return false;

	BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id].GetComponent(ECF_BUFFERMGR);
	if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON)))
	{
		return true;//离子炮或能量炮时禁止换炮
	}
	//获取大炮集类型
	int n = m_player[msg->chair_id].GetCannonSetType();

	do
	{
		if (msg->add)
		{
			if (n < CGameConfig::GetInstance()->CannonSetArray.size() - 1)
			{
				++n;
			}
			else
			{
				n = 0;
			}
		}
		else
		{
			if (n >= 1)
			{
				--n;
			}
			else
			{
				n = CGameConfig::GetInstance()->CannonSetArray.size() - 1;
			}
		}//等于离子炮ID 或双倍ID是退出循环
	} while (n == CGameConfig::GetInstance()->CannonSetArray[n].nIonID || n == CGameConfig::GetInstance()->CannonSetArray[n].nDoubleID);

	if (n < 0) n = 0;
	if (n >= CGameConfig::GetInstance()->CannonSetArray.size())
		n = CGameConfig::GetInstance()->CannonSetArray.size() - 1;

	//设置大炮集类型 ？CacluteCannonPos 获取的是大炮类型 m_nCannonType
	m_player[msg->chair_id].SetCannonSetType(n);
	//运算大炮坐标
	m_player[msg->chair_id].CacluteCannonPos(msg->chair_id);
	//发送大炮信息
	SendCannonSet(msg->chair_id);

	return true;
}
//开火
bool CTableFrameSink::OnFire(CS_stFire* msg)
{
	if (msg->chair_id >= GAME_PLAYER) return false;
	auto chair_id = msg->chair_id;

	// lee test
	// 	m_player[pf->wChairID].SetLastFireTick(timeGetTime());
	// 	return true;
	// lee test end.
	//获取子弹类型
	int mul = m_player[msg->chair_id].GetMultiply();
	if (mul < 0 || mul >= CGameConfig::GetInstance()->BulletVector.size()) return false;

	//场景及玩家可以开火
	if (m_bAllowFire && (HasRealPlayer() || CGameConfig::GetInstance()->bImitationRealPlayer) && m_player[msg->chair_id].CanFire())
	{
		//获取子弹
		Bullet &binf = CGameConfig::GetInstance()->BulletVector[mul];
		//玩家金钱大于子弹值， 且 玩家总子弹数 小于最大子弹数
		if ((m_player[msg->chair_id].GetScore() >= binf.nMulriple) && (m_player[msg->chair_id].GetBulletCount() <= CGameConfig::GetInstance()->nMaxBullet))
		{
			m_player[msg->chair_id].AddScore(-binf.nMulriple);
			m_player[msg->chair_id].SetFired();

			LONGLONG lRevenue = 0;
			//if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pIServerUserItem) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			//	ServerManager::m_pControl->OnFire(m_pITableFrame, pIServerUserItem->GetChairID(), pIServerUserItem, binf.nMulriple, lRevenue);

			// 整理税收和玩家输赢分数
			user_revenues_[chair_id] += lRevenue;
			user_win_scores_[chair_id] -= binf.nMulriple;
			//创建子弹
			CBullet* pBullet = CommonLogic::CreateBullet(binf, m_player[msg->chair_id].GetCannonPos(), msg->direction,
				m_player[msg->chair_id].GetCannonType(), m_player[msg->chair_id].GetMultiply(), false);

			if (pBullet != NULL)
			{
				if (msg->client_id != 0)
					pBullet->SetId(msg->client_id);

				pBullet->SetChairID(msg->chair_id);       //设置椅子
				pBullet->SetCreateTick(msg->fire_time);   //设置开火时间 此时间无效校验

				//查找玩家BUFF是否有双倍炮BUFF
				BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id].GetComponent(ECF_BUFFERMGR);
				if (pBMgr != NULL && pBMgr->HasBuffer(EBT_DOUBLE_CANNON))
					pBullet->setDouble(true);

				//是否有锁定鱼
				if (m_player[msg->chair_id].GetLockFishID() != 0)
				{
					//获取子弹移动控件
					MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
					if (pMove != NULL)
					{
						pMove->SetTarget(&m_FishManager, m_player[msg->chair_id].GetLockFishID());
					}
				}

				DWORD now = timeGetTime();
				if (msg->fire_time > now)
				{
					//m_pITableFrame->SendTableData(pf->wChairID, SUB_S_FORCE_TIME_SYNC);
				}
				else
				{
					//如果子弹生成时间大于2秒执行更新事件处理操作
					now = now - msg->fire_time;
					if (now > 2000) now = 2000;
					pBullet->OnUpdate(now);
				}
				//增加子弹
				m_player[msg->chair_id].ADDBulletCount(1);
				m_BulletManager.Add(pBullet);
				//发送子弹
				SendBullet(pBullet, INVALID_CHAIR, true);
			}
			//设置最后开火时间
			m_player[msg->chair_id].SetLastFireTick(timeGetTime());
		}
	}

	return true;
}
//发送子弹
void CTableFrameSink::SendBullet(CBullet* pBullet, WORD wChairID, bool bNew)
{
	if (pBullet == NULL) return;


    CAutoLock cl(&g_LuaLock);
    CreatLuaPackage(g_LuaL, "on_Send2_pb", m_player[pBullet->GetChairID()].get_guid(), "SC_SendBullet");
    PushNumToTable(g_LuaL, "chair_id", pBullet->GetChairID());              //椅子ID
    PushNumToTable(g_LuaL, "id", pBullet->GetId());
    PushNumToTable(g_LuaL, "cannon_type", pBullet->GetCannonType());
    PushNumToTable(g_LuaL, "multiply", pBullet->GetTypeID());
    PushNumToTable(g_LuaL, "direction", pBullet->GetDirection());
    PushNumToTable(g_LuaL, "x_pos", pBullet->GetPosition().x_);
    PushNumToTable(g_LuaL, "y_pos", pBullet->GetPosition().y_);
    PushNumToTable(g_LuaL, "score", m_player[pBullet->GetChairID()].GetScore());
    PushNumToTable(g_LuaL, "is_new", bNew ? 1 : 0);
    PushNumToTable(g_LuaL, "is_double", pBullet->bDouble() ? 1 : 0);
    PushNumToTable(g_LuaL, "server_tick", timeGetTime());
    if (bNew)
    {
        PushNumToTable(g_LuaL, "create_tick", pBullet->GetCreateTick());
    }
    else
    {
        PushNumToTable(g_LuaL, "create_tick", timeGetTime());
    }
    CallLuaFun(g_LuaL);
}

//发送系统时间
bool CTableFrameSink::OnTimeSync(CS_stTimeSync* msg)
{
    if (GetPlayerGuID(msg->chair_id) != 0)
    {
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2_pb", m_player[msg->chair_id].get_guid(), "SC_TimeSync");
        PushNumToTable(g_LuaL, "chair_id", msg->chair_id);              //椅子ID
        PushNumToTable(g_LuaL, "client_tick", msg->client_tick);        //玩家时间
        PushNumToTable(g_LuaL, "server_tick", timeGetTime());           //系统时间
        CallLuaFun(g_LuaL);
        return true;
    }
    else
    {
        return false;
    }
}

/*bool CTableFrameSink::OnChangeScore(void* pData, WORD wDataSize, IServerUserItem * pIServerUserItem)
{
if(sizeof(CMD_C_CHANGE_SCORE) != wDataSize) return false;
CMD_C_CHANGE_SCORE* pcs = (CMD_C_CHANGE_SCORE*)pData;

try
{
IServerUserItem *pUser = pIServerUserItem;
if(pUser == NULL) return false;
auto chair_id = pUser->GetChairID();

SCORE lUserScore = pUser->GetUserScore() - m_player[chair_id].GetWastage();
SCORE lFishScore = 0;
SCORE lBuyOnceScoe = CGameConfig::GetInstance()->nExchangeOnce * CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore;

if(pcs->bAdd)
{
if(pcs->bAddAll || lUserScore < lBuyOnceScoe)
{
lFishScore = lUserScore * CGameConfig::GetInstance()->nChangeRatioFishScore / CGameConfig::GetInstance()->nChangeRatioUserScore;
}
else
{
lFishScore = CGameConfig::GetInstance()->nExchangeOnce;
}
}
else
{
lFishScore = -m_player[chair_id].GetScore();
}

if(lFishScore != 0)
{
lUserScore = lFishScore * CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore;
m_player[chair_id].AddScore(lFishScore);
m_player[chair_id].AddWastage(lUserScore);

CMD_S_CHANGE_SCORE css;
css.wChairID = chair_id;
css.lWastageScore = m_player[chair_id].GetWastage();
css.lFishScore = lFishScore;

m_pITableFrame->SendTableData(INVALID_CHAIR, SUB_S_CHANGE_SCORE, &css, sizeof(CMD_S_CHANGE_SCORE));
m_pITableFrame->SendLookonData(INVALID_CHAIR, SUB_S_CHANGE_SCORE, &css, sizeof(CMD_S_CHANGE_SCORE));

m_player[chair_id].SetLastFireTick(timeGetTime());

if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pUser) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
ServerManager::m_pControl->OnChangeScore(m_pITableFrame, chair_id, pUser, -lUserScore, lFishScore);
}

return true;
}
catch (...)
{
CTraceService::TraceString(TEXT("OnChangeScore错误"),TraceLevel_Exception);
DebugString(TEXT("[Fish]OnChangeScore错误"));
return false;
}
}*/
//变换大炮
bool CTableFrameSink::OnChangeCannon(CS_stChangeCannon* msg)
{
	if (msg->chair_id >= GAME_PLAYER)
	{
		return false;
	}


	//获取Buff管理器
	BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id].GetComponent(ECF_BUFFERMGR);
	//查看当前大炮是否为双倍或离子炮
	if (pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON)))
	{
		return true;//离子炮或能量炮时禁止换炮
	}

	//获取当前子弹类型
	int mul = m_player[msg->chair_id].GetMultiply();

	if (msg->add)
	{
		++mul;
	}
	else
	{
		--mul;
	}
	//循环类型
	if (mul < 0) mul = CGameConfig::GetInstance()->BulletVector.size() - 1;
	if (mul >= CGameConfig::GetInstance()->BulletVector.size()) mul = 0;
	//设置类型
	m_player[msg->chair_id].SetMultiply(mul);
	//获取子弹对应的炮类形
	int CannonType = CGameConfig::GetInstance()->BulletVector[mul].nCannonType;
	//设置炮
	m_player[msg->chair_id].SetCannonType(CannonType);
	//发送炮设置
	SendCannonSet(msg->chair_id);
	//设置
	m_player[msg->chair_id].SetLastFireTick(timeGetTime());

	return true;
}
//发送大炮属性
void CTableFrameSink::SendCannonSet(WORD wChairID)
{
    int GuID = GetPlayerGuID(wChairID);
    if (GuID == 0)
    {
        if (!GetOnePlayerGuID(GuID))
        {
            return;
        }
    }
    CAutoLock cl(&g_LuaLock);
    CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_CannonSet");
    PushNumToTable(g_LuaL, "chair_id", wChairID);              //椅子ID
    PushNumToTable(g_LuaL, "cannon_mul", m_player[wChairID].GetMultiply());
    PushNumToTable(g_LuaL, "cannon_type", m_player[wChairID].GetCannonType());
    PushNumToTable(g_LuaL, "cannon_set", m_player[wChairID].GetCannonSetType());
    CallLuaFun(g_LuaL);
}
//打开宝箱
bool CTableFrameSink::OnTreasureEND(CS_stTreasureEnd* msg)
{
	if (msg->chair_id >= 0 && msg->chair_id < m_player.size() && m_player[msg->chair_id].get_guid() != 0)
	{

		char szInfo[512];
		std::wstring str = TEXT("恭喜%s第%d桌的玩家『%s』打中宝箱,　并从中获得%I64d金币!!!");
		std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
		std::string narrowStr = conv.to_bytes(str);
		sprintf_s(szInfo, narrowStr.c_str(), "fishing",//GameServerConfigManager::instance()->get_config().game_name(),
			get_table_id(), m_player[msg->chair_id].get_nickname().c_str(), msg->score);
		//查找CatchFishBroadCast 处理事件 Bind_Event_Handler
		RaiseEvent("CatchFishBroadCast", szInfo, &m_player[msg->chair_id]);
	}

	return true;
}
//
void CTableFrameSink::ReturnBulletScore(WORD wChairID)
{
    {
        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_Send2luaback_pb", m_player[wChairID].get_guid(), "on_Send2luaback_pb");
        PushNumToTable(g_LuaL, "money", m_player[wChairID].GetScore());
        PushNumToTable(g_LuaL, "bout", true);
        CallLuaFun(g_LuaL);
    }

#if 0
	if (wChairID >= GAME_PLAYER)
	{
		DebugString(TEXT("[Fish]ReturnBulletScore Err: wTableID %d wChairID %d"), m_pITableFrame->GetTableID(), wChairID);
		return;
	}
	try
	{
		IServerUserItem* pIServerUserItem = m_pITableFrame->GetTableUserItem(wChairID);
		if (pIServerUserItem != NULL)
		{
			// 			SCORE score = m_player[wChairID].GetScore();
			// 			if(score != 0)
			// 			{
			// 				LONGLONG ls = score * CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore;
			// 				m_player[wChairID].AddWastage(-ls);
			// 			}
			// 
			// 			tagScoreInfo ScoreInfo;
			// 			ZeroMemory(&ScoreInfo, sizeof(tagScoreInfo));
			// 			score = -m_player[wChairID].GetWastage();
			// 			LONGLONG lReve=0,cbRevenue=m_pGameServiceOption->wRevenueRatio;	
			// 			if (score > 0)
			// 			{	
			// 				float fRevenuePer = float(cbRevenue/1000);
			// 				lReve  = LONGLONG(score*fRevenuePer);
			// 				ScoreInfo.cbType = SCORE_TYPE_WIN;
			// 			}
			// 			else if (score < 0)
			// 				ScoreInfo.cbType = SCORE_TYPE_LOSE;
			// 			else
			// 				ScoreInfo.cbType = SCORE_TYPE_DRAW;
			// 			ScoreInfo.lScore = score;
			// 			ScoreInfo.lRevenue = lReve;
			// 
			// 			m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);

			if (user_win_scores_[wChairID] != 0 || user_revenues_[wChairID] != 0) {// 有发炮过
				tagScoreInfo ScoreInfo = { 0 };
				ScoreInfo.cbType = (user_win_scores_[wChairID] > 0L) ? SCORE_TYPE_WIN : SCORE_TYPE_LOSE;
				ScoreInfo.lRevenue = user_revenues_[wChairID];
				ScoreInfo.lScore = user_win_scores_[wChairID];
				user_revenues_[wChairID] = 0;
				user_win_scores_[wChairID] = 0;
				m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);
			}

			m_player[wChairID].ClearSet(wChairID);
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误1"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误1"));
	}

	std::list<DWORD> rmList;
	m_BulletManager.Lock();
	try
	{
		obj_table_iter ibu = m_BulletManager.Begin();
		while (ibu != m_BulletManager.End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			if (pBullet->GetChairID() == wChairID)
				rmList.push_back(pBullet->GetId());

			++ibu;
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误2"), TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误2"));
	}
	m_BulletManager.Unlock();

	std::list<DWORD>::iterator it = rmList.begin();
	while (it != rmList.end())
	{
		m_BulletManager.Remove(*it);
		++it;
	}

	rmList.clear();
#endif
}
//奖励事件
void CTableFrameSink::OnAdwardEvent(CMyEvent* pEvent)
{
	//判断事件是否为本事件
	if (pEvent == NULL || pEvent->GetName() != "AdwardEvent") return;
	//奖励事件
	CEffectAward* pe = (CEffectAward*)pEvent->GetParam();
	//鱼
	CFish* pFish = (CFish*)pEvent->GetSource();
	//子弹
	CBullet* pBullet = (CBullet*)pEvent->GetTarget();

	if (pe == NULL || pFish == NULL || pBullet == NULL) return;
	//设置玩家不可开火
	m_player[pBullet->GetChairID()].SetCanFire(false);

	LONGLONG lScore = 0;
	//GetParam(1) 参数２表示实际效果 ０加金币　　１加ＢＵＦＦＥＲ
	if (pe->GetParam(1) == 0)
	{
		if (pe->GetParam(2) == 0)
			lScore = pe->GetParam(3);
		else
			lScore = pBullet->GetScore() * pe->GetParam(3);
	}
	else
	{
		//纵使子弹加BUFF
		BufferMgr* pBMgr = (BufferMgr*)m_player[pBullet->GetChairID()].GetComponent(ECF_BUFFERMGR);
		if (pBMgr != NULL && !pBMgr->HasBuffer(pe->GetParam(2)))
		{
			//GetParam(2)类型 GetParam(3)持续时间
			pBMgr->Add(pe->GetParam(2), 0, pe->GetParam(3));
		}
	}
	//玩家加钱
	m_player[pBullet->GetChairID()].AddScore(lScore);
}
//增加鱼BUFF
void CTableFrameSink::OnAddBuffer(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "AddBuffer") return;
	CEffectAddBuffer* pe = (CEffectAddBuffer*)pEvent->GetParam();

	CFish* pFish = (CFish*)pEvent->GetSource();
	if (pFish == NULL) return;

	if (pFish->GetMgr() != &m_FishManager) return;

	//当目标是全部鱼且类型为改变速度 改变值为0时 定屏 时间为pe->GetParam(4)
	if (pe->GetParam(0) == 0 && pe->GetParam(2) == EBT_CHANGESPEED && pe->GetParam(3) == 0)//定屏
	{//？只停止了刷新?
		m_fPauseTime = pe->GetParam(4);
	}
}
//执行鱼死亡效果
void CTableFrameSink::OnMulChange(CMyEvent* pEvent)
{
    int GuID;
    if (!GetOnePlayerGuID(GuID))
    {
        return;
    }
	if (pEvent == NULL || pEvent->GetName() != "FishMulChange") return;

	CFish* pFish = (CFish*)pEvent->GetParam();
	if (pFish != NULL)
	{
		m_FishManager.Lock();
		obj_table_iter ifs = m_FishManager.Begin();
		while (ifs != m_FishManager.End())
		{

			CFish* pf = (CFish*)ifs->second;
			//找到一个同类的鱼，然后执行死亡效果
			if (pf != NULL && pf->GetTypeID() == pFish->GetTypeID())
			{
				CBullet bt;
				bt.SetScore(1);
				std::list<MyObject*> llt;
				llt.clear();
				//如果找到鱼死亡管理器 
				EffectMgr* pEM = (EffectMgr*)pf->GetComponent(ECF_EFFECTMGR);
                int multemp = 0;
				if (pEM != NULL)
				{//执行死亡效果
                    multemp = pEM->Execute(&bt, llt, true);
				}

                CAutoLock cl(&g_LuaLock);
                CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_FishMul");
                PushNumToTable(g_LuaL, "fish_id", pf->GetId());
                PushNumToTable(g_LuaL, "mul", multemp);
                CallLuaFun(g_LuaL);
			}

			++ifs;

		}
		m_FishManager.Unlock();
	}
}
//第一次开火？ 为啥是生成鱼的 第一波鱼生成吗？
void CTableFrameSink::OnFirstFire(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "FirstFire") return;

	CPlayer* pPlayer = (CPlayer*)pEvent->GetParam();

	for (WORD i = 0; i < GAME_PLAYER; ++i)
	{
		//本桌玩家 可优 结束后 
		if (&m_player[i] == pPlayer)
		{
			//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
			//if(pUser == NULL) break;

			int npos = 0;
			npos = CGameConfig::GetInstance()->FirstFireList.size() - 1;
			FirstFire& ff = CGameConfig::GetInstance()->FirstFireList[npos];
			//在鱼类型与权重中取最低值
			int nsz = min(ff.FishTypeVector.size(), ff.WeightVector.size());

			if (nsz <= 0) continue;
			//总权重
			int WeightCount = 0;
			for (int iw = 0; iw < nsz; ++iw)
			{
				WeightCount += ff.WeightVector[iw];
			}
			//获取大炮位置
			MyPoint pt = m_player[i].GetCannonPos();
			//获取大炮方向
			float dir = CGameConfig::GetInstance()->CannonPos[i].m_Direction;
			//数量？
			for (int nc = 0; nc < ff.nCount; ++nc)
			{
				//价格计数？
				for (int ni = 0; ni < ff.nPriceCount; ++ni)
				{
					//获取 一种鱼
					int Fid = ff.FishTypeVector[RandInt(0, nsz)];
					//随机一个权重
					int nf = RandInt(0, WeightCount);
					int wpos = 0;
					//匹配一个权重
					for (; wpos < nsz; ++wpos)
					{
						if (nf > ff.WeightVector[wpos])
						{
							nf -= ff.WeightVector[wpos];
						}
						else
						{
							Fid = ff.FishTypeVector[wpos];
							break;;
						}
					}
					//如果没有匹配到则匹配第一个
					if (wpos >= nsz)
					{
						Fid = ff.FishTypeVector[0];
					}

					//运算最终角度？
					dir = CGameConfig::GetInstance()->CannonPos[i].m_Direction - M_PI_2 + M_PI / ff.nPriceCount * ni;

					//查找匹配到的鱼
					std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
					if (ift != CGameConfig::GetInstance()->FishMap.end())
					{
						Fish& finf = ift->second;

						//生成鱼
						CFish* pFish = CommonLogic::CreateFish(finf, pt.x_, pt.y_, dir, RandFloat(0.0f, 1.0f) + nc, finf.nSpeed, -2);
						if (pFish != NULL)
						{
							m_FishManager.Add(pFish);
							SendFish(pFish);
						}
					}
				}
			}
			break;
		}
	}
}
//生成鱼
void CTableFrameSink::OnProduceFish(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "ProduceFish") return;

	CEffectProduce* pe = (CEffectProduce*)pEvent->GetParam();
	//Source为鱼
	CFish* pFish = (CFish*)pEvent->GetSource();
	if (pFish == NULL) return;

	if (pFish->GetMgr() != &m_FishManager) return;
	//获取坐标
	MyPoint& pt = pFish->GetPosition();
    list<SC_stSendFish> msg;
	//通过ID查找鱼
	std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(pe->GetParam(0));
	if (ift != CGameConfig::GetInstance()->FishMap.end())
	{
		Fish finf = ift->second;
		float fdt = M_PI * 2.0f / (float)pe->GetParam(2);
		//类型为普通
		int fishtype = ESFT_NORMAL;
		int ndif = -1;
		//批次循环
		for (int i = 0; i < pe->GetParam(1); ++i)
		{
			//当最后一批，且总批次大于2 刷新数量大于10只时 随机一条鱼刷新为鱼王
			if ((i == pe->GetParam(1) - 1) && (pe->GetParam(1) > 2) && (pe->GetParam(2) > 10))
			{
				ndif = RandInt(0, pe->GetParam(2));
			}

			//刷新数量
			for (int j = 0; j < pe->GetParam(2); ++j)
			{
				if (j == ndif)
				{
					fishtype = ESFT_KING;
				}
				else
				{
					fishtype = ESFT_NORMAL;
				}
				//创建鱼
				CFish* pf = CommonLogic::CreateFish(finf, pt.x_, pt.y_, fdt*j, 1.0f + pe->GetParam(3)*i, finf.nSpeed, -2, false, fishtype);
				if (pf != NULL)
				{
					m_FishManager.Add(pf);
					//SendFish(pf);
					// 换成只处理数据
					//ASSERT(fishs->dwFishCount < 300);
					//if (fishs->dwFishCount >= 300) {
					//CTraceService::TraceString(_T("SUB_S_SEND_FISHS > 300"), TraceLevel_Warning);
					//	break;
					//}
					//if (msg.fishes_size() >= 300)
					//	break;
                    if (msg.size() >= 300)
                    {
                        break;
                    }
                    SC_stSendFish fish;
					fish.fish_id = pf->GetId();
                    fish.type_id = pf->GetTypeID();
                    fish.create_tick = pf->GetCreateTick();
                    fish.fis_type = pf->GetFishType();
                    fish.refersh_id = pf->GetRefershID();
					//添加移动组件
					MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
					if (pMove != NULL)
					{
						fish.path_id = pMove->GetPathID();
						fish.offest_x = pMove->GetOffest().x_;
						fish.offest_y = pMove->GetOffest().y_;
						if (pMove->GetID() == EMCT_DIRECTION)
						{
							fish.offest_x = pMove->GetPostion().x_;
							fish.offest_y = pMove->GetPostion().y_;
						}
						fish.dir = pMove->GetDirection();
						fish.delay = pMove->GetDelay();
						fish.fish_speed = pMove->GetSpeed();
						fish.troop = pMove->bTroop() ? 1 : 0;
					}

					BufferMgr* pBM = (BufferMgr*)pf->GetComponent(ECF_BUFFERMGR);
					if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT))
					{//找到BUFF管理器，且有BUFF 被击 吃子弹 添加事件
						PostEvent("FishMulChange", pf);
					}

					fish.server_tick = timeGetTime();
                    msg.push_back(fish);
				}
			}
		}
	}
    int GuID;
    if (!GetOnePlayerGuID(GuID))
    {
        return;
    }
    list<SC_stSendFish>::iterator it = msg.begin();
    CAutoLock cl(&g_LuaLock);
    CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", GuID, "SC_SendFishList");
    InitTableName();
    while (it != msg.end())
    {
        PushTabToTable_Begin(g_LuaL);
        SC_stSendFish &temp = *it++;
        PushNumToTable(g_LuaL, "fish_id",	   temp.fish_id); //鱼ID
        PushNumToTable(g_LuaL, "type_id",      temp.type_id);  //类型？
        PushNumToTable(g_LuaL, "path_id",      temp.path_id);  //路径ID
        PushNumToTable(g_LuaL, "create_tick",  temp.create_tick);  //创建时间
        PushNumToTable(g_LuaL, "offest_x",     temp.offest_x);  //X坐标
        PushNumToTable(g_LuaL, "offest_y",     temp.offest_y);  //Y坐标
        PushNumToTable(g_LuaL, "dir",          temp.dir);  //方向
        PushNumToTable(g_LuaL, "delay",        temp.delay);  //延时
        PushNumToTable(g_LuaL, "server_tick",  temp.server_tick);  //系统时间
        PushNumToTable(g_LuaL, "fish_speed",   temp.fish_speed);  //鱼速度
        PushNumToTable(g_LuaL, "fis_type",     temp.fis_type);  //鱼类型？
        PushNumToTable(g_LuaL, "troop",        temp.troop);      //是否鱼群
        PushNumToTable(g_LuaL, "refersh_id",   temp.refersh_id);  //获取刷新ID？
        PushTabToTable_End(g_LuaL);
    }
    CallLuaFun(g_LuaL);
    //发送broadcast2client_pb(&msg);
}
//锁定鱼
void CTableFrameSink::LockFish(WORD wChairID)
{
	DWORD dwFishID = 0;

	CFish* pf = NULL;
	//获取当前锁定ID
	dwFishID = m_player[wChairID].GetLockFishID();
	if (dwFishID != 0)
		pf = (CFish*)m_FishManager.Find(dwFishID);
	//判断是否有锁定目标
	if (pf != NULL)
	{
		//判断当前锁定鱼 是否已经不可锁定了
		MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
		if (pf->GetState() >= EOS_DEAD || pMove == NULL || pMove->IsEndPath())
		{
			pf = NULL;
		}
	}

	dwFishID = 0;

	CFish* pLock = NULL;

	//轮询可锁定列表
	std::list<DWORD>::iterator iw = m_CanLockList.begin();
	while (iw != m_CanLockList.end())
	{
		//查找鱼
		CFish* pFish = (CFish*)m_FishManager.Find(*iw);
		//当前鱼有效 且 没死亡 且 锁定等级大于0 且 没有游出屏幕
		if ((pFish != NULL) && (pFish->GetState() < EOS_DEAD) && (pFish->GetLockLevel()) > 0 && (pFish->InSideScreen()))
		{
			//获取能锁定的最大等级的鱼
			if ((pf == NULL) || ((pf != pFish) && !m_player[wChairID].HasLocked(pFish->GetId())))
			{
				pf = pFish;

				if (pLock == NULL)
				{
					pLock = pf;
				}
				else if (pf->GetLockLevel() > pLock->GetLockLevel())
				{
					pLock = pf;
				}
			}
		}

		++iw;

	}

	if (pLock != NULL)
		dwFishID = pLock->GetId();
	//设置锁定ID 
	m_player[wChairID].SetLockFishID(dwFishID);

	if (m_player[wChairID].GetLockFishID() != 0)
	{

        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", m_player[wChairID].get_guid(), "SC_LockFish");
        PushNumToTable(g_LuaL, "chair_id", wChairID);
        PushNumToTable(g_LuaL, "lock_id", dwFishID);
        CallLuaFun(g_LuaL);
	}
}
//锁定鱼
bool CTableFrameSink::OnLockFish(CS_stLockFish* msg)
{
	//椅子子位置是否合理
	if (msg->chair_id >= GAME_PLAYER)
	{
		return false;
	}
	//如果没有玩家退出
	if (!HasRealPlayer()) return true;

	if (msg->lock)
	{
		//设置玩家锁定
		m_player[msg->chair_id].SetLocking(true);
		//锁定鱼
		LockFish(msg->chair_id);
	}
	else
	{
		m_player[msg->chair_id].SetLocking(false);
		m_player[msg->chair_id].SetLockFishID(0);

        CAutoLock cl(&g_LuaLock);
        CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", m_player[msg->chair_id].get_guid(), "SC_LockFish");
        PushNumToTable(g_LuaL, "chair_id", msg->chair_id);
        PushNumToTable(g_LuaL, "lock_id", 0);
        CallLuaFun(g_LuaL);
	}
	//设置最后一次开火时间
	m_player[msg->chair_id].SetLastFireTick(timeGetTime());

	return true;

}
//发送 玩家大炮属性    并不是改变大炮？
void CTableFrameSink::OnCannonSetChange(CMyEvent* pEvent)
{
	if (pEvent == NULL || pEvent->GetName() != "CannonSetChanaged")
		return;

	CPlayer* pp = (CPlayer*)pEvent->GetParam();
	if (pp != NULL)
	{
		auto sz = m_player.size();
		for (size_t i = 0; i < sz; ++i)
		{
			if (&m_player[i] == pp)
			{
				SendCannonSet(i);
			}
		}
	}
}
//网鱼
bool CTableFrameSink::OnNetCast(CS_stNetcast* msg)
{
	auto bullet_id = msg->bullet_id;      //子弹ID
	auto fish_id = msg->fish_id;          //鱼ID

	m_BulletManager.Lock();
	//获取子弹
	CBullet* pBullet = (CBullet*)m_BulletManager.Find(bullet_id);
	if (pBullet != NULL)
	{
		//获取子弹所属玩家座位
		auto chair_id = pBullet->GetChairID();
		m_FishManager.Lock();
		CFish* pFish = (CFish*)m_FishManager.Find(fish_id);
		if (pFish != NULL)
		{
			CatchFish(pBullet, pFish, 1, 0);
		}
		else
		{
			// 这里因为鱼不存在，所以我们吃掉了玩家一个子弹，给玩家加到玩家分数池里以便后面退给玩家
			user_score_pools_[chair_id] += pBullet->GetScore();
		}
		m_FishManager.Unlock();

		//发送子弹消失
        {
            CAutoLock cl(&g_LuaLock);
            CreatLuaPackage(g_LuaL, "on_broadcast2client_pb", m_player[chair_id].get_guid(), "SC_KillBullet");
            PushNumToTable(g_LuaL, "chair_id", chair_id);              //椅子ID
            PushNumToTable(g_LuaL, "bullet_id", bullet_id);
            CallLuaFun(g_LuaL);
        }
		//玩家子弹-1
		m_player[chair_id].ADDBulletCount(-1);
		//移除子弹
		m_BulletManager.Remove(bullet_id);
	}
	else
	{

		// TODO: 如果子弹不存在，也可能导致一些问题：玩家碰撞子弹的包比子弹出现的包被先一步处理了，这里后续完善 
	}
	m_BulletManager.Unlock();

	return true;
}
//打开宝箱 无处理，只发送？ 可优
void CTableFrameSink::OnCatchFishBroadCast(CMyEvent* pEvent)
{
	if (pEvent != NULL && pEvent->GetName() == "CatchFishBroadCast")
	{
		//IServerUserItem* pp = (IServerUserItem*)pEvent->GetSource();
		//获取玩家
		CPlayer* pp = (CPlayer*)pEvent->GetSource();
		if (pp != NULL)
		{
			//for(WORD i = 0; i < GAME_PLAYER; ++i)
			{
				//if(m_pITableFrame->GetTableUserItem(i) == pp)
				{
					//m_pITableFrame->SendGameMessage(pp, (LPCTSTR)pEvent->GetParam(), SMT_TABLE_ROLL);

                    CAutoLock cl(&g_LuaLock);
                    CreatLuaPackage(g_LuaL, "on_Send2_pb", pp->get_guid(), "SC_SystemMessage");
                    PushNumToTable(g_LuaL, "wtype", SMT_TABLE_ROLL);
                    PushStrToTable(g_LuaL, "szstring", (char*)pEvent->GetParam());
                    CallLuaFun(g_LuaL);

					//break;
					//m_pITableFrame->SendRoomMessage((IServerUserItem*)pEvent->GetSource(), (LPCTSTR)pEvent->GetParam(), SMT_TABLE_ROLL);					
				}
			}
		}
	}
}
// 设置网关 可优 不再关心网关层
void CTableFrameSink::set_guid_gateid(int chair_id, int guid, int gate_id)
{
	if (chair_id >= 0 && chair_id < (int)m_player.size())
	{
		m_player[chair_id].set_guid_gateid(guid, gate_id);
		m_player[chair_id].set_chair_id(chair_id);
	}
	else
	{
		//LOG_WARN("chair_id %d error", chair_id);
	}
}
//设置昵称
void CTableFrameSink::set_nickname(int chair_id, const char* nickname)
{
	if (chair_id >= 0 && chair_id < (int)m_player.size())
	{
		m_player[chair_id].set_nickname(nickname);
	}
}

void CTableFrameSink::set_money(int chair_id, LONGLONG lvalue)
{
    if (chair_id >= 0 && chair_id < (int)m_player.size())
    {
        m_player[chair_id].SetScore(lvalue);
    }
}