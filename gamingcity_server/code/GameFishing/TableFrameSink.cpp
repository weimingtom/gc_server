//
#include "Stdafx.h"
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

//构造函数
CTableFrameSink::CTableFrameSink()
{
	//m_pITableFrame=NULL;
	//m_pGameServiceOption=NULL;
	//m_pGameServiceAttrib=NULL;
	m_nFishCount = 0;
	m_bRun = false;

	m_table_id = 0;

	TableManager::instance()->add_table(this);
}

//析构函数
CTableFrameSink::~CTableFrameSink(void)
{
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
//接口查询
/*void *  CTableFrameSink::QueryInterface(const IID & Guid, DWORD dwQueryVer)
{
	QUERYINTERFACE(ITableFrameSink,Guid,dwQueryVer);
	QUERYINTERFACE(ITableUserAction,Guid,dwQueryVer);
	QUERYINTERFACE_IUNKNOWNEX(ITableFrameSink,Guid,dwQueryVer);
	return NULL;
}

//初始化
*/bool  CTableFrameSink::Initialization()
{
	//查询接口
	/*ASSERT(pIUnknownEx!=NULL);
	m_pITableFrame=QUERY_OBJECT_PTR_INTERFACE(pIUnknownEx,ITableFrame);
	if (m_pITableFrame==NULL) return false;

	//获取参数
	m_pGameServiceOption=m_pITableFrame->GetGameServiceOption();
	ASSERT(m_pGameServiceOption!=NULL);

	static bool coni = false;
	if(!coni)
	{
		IDGenerator::GetInstance()->SetSeed(GAME_PLAYER*10000);

		LoadConfig();

		if(ServerManager::m_pControl != NULL && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			ServerManager::m_pControl->Initialization(m_pITableFrame, m_pGameServiceOption, (float)CGameConfig::GetInstance()->nChangeRatioUserScore / CGameConfig::GetInstance()->nChangeRatioFishScore);			
	
		coni = true;
	}*/

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
	std::string path = "../data/fishing/";// GameServerConfigManager::instance()->get_config().data_path();

	LOG_DEBUG("开始加载配置...");
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
	LOG_DEBUG("加载完成 总计耗时%g秒", dwStartTick / 1000.f);
}

void CTableFrameSink::ResetTable()
{
		//m_pITableFrame->KillGameTimer(IDI_GAMELOOP);

		m_FishManager.Clear();

		m_BulletManager.Clear();

		m_fPauseTime = 0.0f;

		m_nSpecialCount = 0;

		m_nFishCount = 0;

		for(WORD i = 0; i < GAME_PLAYER; ++i)
		{
			m_player[i].ClearSet(i);
		}
}
//复位桌子
void  CTableFrameSink::RepositionSink()
{
	ResetTable();
}

/*bool CTableFrameSink::ImitationRealPlayer(IServerUserItem* pUser)
{
	if(pUser == NULL) return false;
	if (pUser->GetMemberOrder() == 5) return false;			//特殊机器人不用处理 yanwg 2015-08-22
 	if(pUser->IsAndroidUser())
 		return CGameConfig::GetInstance()->bImitationRealPlayer;	
	return true;
}
//用户断线
bool  CTableFrameSink::OnActionUserOffLine(WORD wChairID, IServerUserItem * pIServerUserItem) 
{

//	CTraceService::TraceStringEx(TraceLevel_Exception, TEXT("玩家断线:%ld, %d, %d"), pIServerUserItem->GetUserID(), pIServerUserItem->GetTableID(), pIServerUserItem->GetChairID());

	if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pIServerUserItem) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
		ServerManager::m_pControl->OnEventUserLeave(m_pITableFrame, wChairID, pIServerUserItem);

	
	//return OnActionUserStandUp(wChairID, pIServerUserItem, false);

	// 向客户端发送用户起立的消息
	//return m_pITableFrame->PerformStandUpAction(pIServerUserItem);
	return true;
}

void CTableFrameSink::SaveTableData()
{
	tagScoreInfo ScoreInfo[MAX_TABLE_CHAIR] = { 0 };
	for (uint16_t wChairID = 0; wChairID < MAX_TABLE_CHAIR; ++wChairID) {
		IServerUserItem *pIServerUserItem = m_pITableFrame->GetTableUserItem(wChairID);
		if (pIServerUserItem == NULL) {
			continue;
		}

		if (user_win_scores_[wChairID] == 0 && user_revenues_[wChairID] == 0) {// 没有发炮
			continue;
		}
		tagScoreInfo ScoreInfo = { 0 };
		ScoreInfo.cbType = (user_win_scores_[wChairID]>0L) ? SCORE_TYPE_WIN : SCORE_TYPE_LOSE;
		ScoreInfo.lRevenue = user_revenues_[wChairID];
		ScoreInfo.lScore = user_win_scores_[wChairID];
		user_revenues_[wChairID] = 0;
		user_win_scores_[wChairID] = 0;
		m_pITableFrame->WriteUserScore(wChairID, ScoreInfo);
	}
}
*/
//用户坐下
bool CTableFrameSink::OnActionUserSitDown(WORD wChairID, bool bLookonUser)
{
	try
	{
		if(!bLookonUser)
		{
#ifdef _DEBUG
			//CTraceService::TraceStringEx(TraceLevel_Debug, _T("OnActionUserSitDown ChairID:%d UserID:%d"), wChairID, pIServerUserItem->GetUserID());
#endif // _DEBUG
			if(wChairID>=GAME_PLAYER)
			{
				//DebugString(TEXT("[Fish]OnActionUserSitDown Err: wTableID %d wChairID %d"),m_pITableFrame->GetTableID() ,wChairID);
				return false;
			}
			m_player[wChairID].ClearSet(wChairID);

			user_revenues_[wChairID] = 0;
			user_win_scores_[wChairID] = 0;

			GetLocalTime(&m_SystemTimeStart[wChairID]);

			/*if(m_pITableFrame->GetGameStatus() == GAME_STATUS_FREE)
			{
				m_pITableFrame->StartGame();
				m_pITableFrame->SetGameStatus(GAME_STATUS_PLAY);
			}*/

			//m_pITableFrame->SendTableData(wChairID, SUB_S_FORCE_TIME_SYNC);

			BufferMgr* pBMgr = (BufferMgr*)m_player[wChairID].GetComponent(ECF_BUFFERMGR);
			if(pBMgr == NULL)
			{
				pBMgr = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
				if(pBMgr != NULL)
					m_player[wChairID].SetComponent(pBMgr);
			}

			if(pBMgr != NULL)
				pBMgr->Clear();

			//if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pIServerUserItem) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			//	ServerManager::m_pControl->OnEventUserEnter(m_pITableFrame, wChairID, pIServerUserItem);
		}
		return true;
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnActionUserSitDown错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnActionUserSitDown错误"));
		return false;
	}
	return false;
}

//用户起立
bool  CTableFrameSink::OnActionUserStandUp(WORD wChairID, bool bLookonUser)
{
	try
	{
		if(!bLookonUser)
		{
#ifdef _DEBUG
			//CTraceService::TraceStringEx(TraceLevel_Debug, _T("OnActionUserStandUp ChairID:%d UserID:%d"), wChairID, pIServerUserItem->GetUserID());
#endif // _DEBUG
			if(wChairID>=GAME_PLAYER)
			{
				//DebugString(TEXT("[Fish]OnActionUserStandUp Err: wTableID %d wChairID %d"),m_pITableFrame->GetTableID() ,wChairID);
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

			//if (ServerManager::m_pControl != NULL && ImitationRealPlayer(pIServerUserItem) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			//	ServerManager::m_pControl->OnEventUserLeave(m_pITableFrame, wChairID, pIServerUserItem);

			// 更新用户返利
			//m_pITableFrame->DecUserRebateAndSaveToDB(pIServerUserItem, 0);

			WORD playerCount = 0;
			for(WORD i = 0; i < GAME_PLAYER; ++i)
			{
				//if(m_pITableFrame->GetTableUserItem(i) != NULL)
				if (m_player[i].get_guid() != 0)
					++playerCount;
			}

			if(playerCount == 0)
			{
				ResetTable();
				//m_pITableFrame->ConcludeGame(GAME_STATUS_FREE);
			}
			m_player[wChairID].ClearSet(wChairID);
		}
		return true;
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnActionUserStandUp错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnActionUserStandUp错误"));
		return false;
	}
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

	RandSeed(timeGetTime());
	srand(timeGetTime());

	m_bRun = true;

	return true;
}

void CTableFrameSink::ResetSceneDistrub()
{
	int sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.size();
	m_vDistrubFishTime.resize(sn);
	for(int i=0; i<sn; ++i)	
		m_vDistrubFishTime[i] = 0;

	sn = CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.size();
	m_vDistrubTroop.resize(sn);
	for(int i=0; i<sn; ++i)
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
bool  CTableFrameSink::OnEventGameConclude( WORD wChairID, BYTE cbReason )
{
	//if(ServerManager::m_pControl != NULL)
	//	ServerManager::m_pControl->SaveStorage(m_pITableFrame);


	switch(cbReason)
	{
	case GER_NORMAL:
	case GER_USER_LEAVE:
	case GER_NETWORK_ERROR:
		{
			//ASSERT(wChairID < m_pITableFrame->GetChairCount());
			ReturnBulletScore(wChairID);
			m_player[wChairID].ClearSet(wChairID);

			m_player[wChairID].set_guid_gateid(0, 0);

			return true;
		}
	case GER_DISMISS:
		{
			for(WORD i = 0; i < GAME_PLAYER; ++i)
			{
				ReturnBulletScore(i);
				m_player[i].ClearSet(i);

				m_player[i].set_guid_gateid(0, 0);
			}
			return true;
		}
	}
	return false;
}

//发送场景
bool  CTableFrameSink::OnEventSendGameScene(WORD wChairID, BYTE cbGameStatus, bool bSendSecret)
{
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
			
			char szInfo[256];
			std::wstring str = TEXT("当前房间的游戏币与渔币的兑换比例为%d游戏币兑换%d渔币");
			std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
			std::string narrowStr = conv.to_bytes(str);
			sprintf_s(szInfo, narrowStr.c_str(), CGameConfig::GetInstance()->nChangeRatioUserScore, CGameConfig::GetInstance()->nChangeRatioFishScore);

			SC_SystemMessage msg;
			msg.set_wtype(SMT_CHAT);
			msg.set_szstring(szInfo);
			send2client_pb(wChairID, &msg);

			return true;
		}
	}
	return false;
}

void CTableFrameSink::SendGameConfig(WORD wChairID)
{
	SC_GameConfig css;
	css.set_server_id(1);
	css.set_change_ratio_fish_score(CGameConfig::GetInstance()->nChangeRatioFishScore);
	css.set_change_ratio_user_score(CGameConfig::GetInstance()->nChangeRatioUserScore);
	css.set_exchange_once(CGameConfig::GetInstance()->nExchangeOnce);
	css.set_fire_interval(CGameConfig::GetInstance()->nFireInterval);
	css.set_max_interval(CGameConfig::GetInstance()->nMaxInterval);
	css.set_min_interval(CGameConfig::GetInstance()->nMinInterval);
	css.set_show_gold_min_mul(CGameConfig::GetInstance()->nShowGoldMinMul);
	css.set_max_bullet_count(CGameConfig::GetInstance()->nMaxBullet);
	css.set_max_cannon(CGameConfig::GetInstance()->m_MaxCannon);

	send2client_pb(wChairID, &css);

	int nb = CGameConfig::GetInstance()->BulletVector.size();
	for(int i = 0; i < nb; ++i)
	{
		SC_BulletSet cbs;
		cbs.set_first(i == 0 ? 1 : 0);
		cbs.set_bullet_size(CGameConfig::GetInstance()->BulletVector[i].nBulletSize);
		cbs.set_cannon_type(CGameConfig::GetInstance()->BulletVector[i].nCannonType);
		cbs.set_catch_radio(CGameConfig::GetInstance()->BulletVector[i].nCatchRadio);
		cbs.set_max_catch(CGameConfig::GetInstance()->BulletVector[i].nMaxCatch);
		cbs.set_mulriple(CGameConfig::GetInstance()->BulletVector[i].nMulriple);
		cbs.set_speed(CGameConfig::GetInstance()->BulletVector[i].nSpeed);

		send2client_pb(wChairID, &cbs);
	}
}

void CTableFrameSink::SendPlayerInfo(WORD wChairID)
{
	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
		//if(pUser == NULL) continue;
		if (m_player[i].get_guid() != 0)
		{
			SC_UserInfo cui;

			cui.set_chair_id(i);
			cui.set_score(m_player[i].GetScore());
			cui.set_cannon_mul(m_player[i].GetMultiply());
			cui.set_cannon_type(m_player[i].GetCannonType());
			cui.set_wastage(m_player[i].GetWastage());
	
			send2client_pb(wChairID, &cui);
		}
	}
}


void CTableFrameSink::SendSceneInfo(WORD wChairID)
{
	SC_SwitchScene css;
	css.set_switching(0);
	css.set_nst(m_nCurScene);
	send2client_pb(wChairID, &css);


	m_BulletManager.Lock();
	try
	{
		obj_table_iter ibu = m_BulletManager.Begin();
		while(ibu != m_BulletManager.End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			SendBullet(pBullet, wChairID);
			++ibu;
		}
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("SendSceneInfo错误1"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]SendSceneInfo错误1"));
	}
	m_BulletManager.Unlock();

	m_FishManager.Lock();
	try
	{
		obj_table_iter ifs = m_FishManager.Begin();
		while(ifs != m_FishManager.End())
		{
			CFish* pFish = (CFish*)ifs->second;
			SendFish(pFish, wChairID);
			++ifs;
		}
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("SendSceneInfo错误2"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]SendSceneInfo错误2"));
	}
	m_FishManager.Unlock();
}

void CTableFrameSink::SendAllowFire(WORD wChairID)
{
	SC_AllowFire cf;
	cf.set_allow_fire(m_bAllowFire ? 1 : 0);

	send2client_pb(wChairID, &cf);
}

//定时器事件
bool CTableFrameSink::OnTimerMessage(DWORD wTimerID, WPARAM wBindParam)
{
	switch(wTimerID)
	{
	case IDI_GAMELOOP:
		{
			OnGameUpdate();
		}
		break;
	}
	return true;
}

void CTableFrameSink::OnGameUpdate()
{
	if (!m_bRun)
		return;

	DWORD NowTime = timeGetTime();
	int ndt = NowTime - m_dwLastTick;
	float fdt = ndt / 1000.0f;

	//if(ServerManager::m_pControl != NULL && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
	//	ServerManager::m_pControl->OnUpdate(m_pITableFrame, fdt);

	bool hasR = HasRealPlayer();

	DWORD tPlayer = timeGetTime();
	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
		//if (pUser == NULL || pUser->GetUserID() == 0)// 对已经清理的用户不再判断 add lee 2016.04.09
		//	continue;
		
		if (m_player[i].get_guid() == 0)
			continue;

		m_player[i].OnUpdate(ndt);

		if(hasR && m_player[i].bLocking())
		{
			if(m_player[i].GetLockFishID() == 0)
			{
				LockFish(i);
				if(m_player[i].GetLockFishID() == 0)
					m_player[i].SetLocking(false);
			}
			else
			{
				try
				{
					CFish* pFish = (CFish*)m_FishManager.Find(m_player[i].GetLockFishID());
					if(pFish == NULL || !pFish->InSideScreen())
					{
						LockFish(i);
						if(m_player[i].GetLockFishID() == 0)
							m_player[i].SetLocking(false);
					}
				}
				catch (...)
				{
					//CTraceService::TraceString(TEXT("OnGameUpdate错误1"),TraceLevel_Exception);
					DebugString(TEXT("[Fish]OnGameUpdate错误1"));
				}
			}
		}

		/*if(pUser->IsAndroidUser())
		{
			if(hasR || ImitationRealPlayer(pUser))
			{
				AndroidUpdata au;
				au.FishCount = m_nFishCount;
				au.dir = CMathAide::CalcAngle(m_NearFishPos[i].x_, m_NearFishPos[i].y_, m_player[i].GetCannonPos().x_, m_player[i].GetCannonPos().y_);
				m_pITableFrame->SendTableData(i, SUB_S_ANDROID_UPD, &au, sizeof(AndroidUpdata));
			}
		}
		else if (NowTime - CGameConfig::GetInstance()->nMaxInterval + 1000 > m_player[i].GetLastFireTick()
			&&!CUserRight::IsGameCheatUser(pUser->GetUserRight()))
		{
			m_pITableFrame->PerformStandUpAction(pUser);
// 			if (m_pITableFrame->PerformStandUpAction(pUser) == false)
// 				CTraceService::TraceStringEx(TraceLevel_Debug, TEXT("站起失败220  %d %d=%s"), pUser->GetTableID(), pUser->GetChairID(), pUser->GetNickName());
		}*/
	}
	tPlayer = timeGetTime() - tPlayer;

	DWORD tFish = timeGetTime();

	m_CanLockList.clear();
	m_nFishCount = 0;

	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		m_NearFishPos[i].x_ = CGameConfig::GetInstance()->nDefaultWidth / 2;
		m_NearFishPos[i].y_ = CGameConfig::GetInstance()->nDefaultHeight / 2;
	}

	std::list<DWORD> rmList;
	m_nSpecialCount = 0;
	
	m_FishManager.Lock();
	obj_table_iter ifs = m_FishManager.Begin();
// 	try
// 	{
		while(ifs != m_FishManager.End())
		{
			CFish* pFish = (CFish*)ifs->second;
			pFish->OnUpdate(ndt);
			MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
			if(/*NowTime - pFish->GetCreateTick() >= MAX_LIFE_TIME|| */ pMove == NULL || pMove->IsEndPath())
			{
				if(pMove != NULL && pFish->InSideScreen())
				{
					MoveCompent* pMove2 = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
					if(pMove2 != NULL)
					{
						pMove2->SetSpeed(pMove->GetSpeed());
						pMove2->SetDirection(pMove->GetDirection());
						pMove2->SetPosition(pMove->GetPostion());
						pMove2->InitMove();
						pFish->SetComponent(pMove2);
					}
				}
				else
				{
					rmList.push_back(pFish->GetId());
				}
			}
			else if(pFish->GetFishType() != ESFT_NORMAL)
			{
				++m_nSpecialCount;
			}

			if(hasR && pFish->InSideScreen())
			{
				//  			if(pFish->GetPosition().y_ > 50 && pFish->GetPosition().y_ < CGameConfig::GetInstance()->nDefaultHeight - 50
				//  				&&pFish->GetPosition().x_ > 50 && pFish->GetPosition().x_ < CGameConfig::GetInstance()->nDefaultWidth - 50)
				//  			{
				//  				for(WORD i = 0; i < GAME_PLAYER; ++i)
				//  				{
				// 					IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
				// 					if(pUser == NULL || !pUser->IsAndroidUser())
				// 						continue;
				// 
				//  					float dis1 = CMathAide::CalcDistance(m_player[i].GetCannonPos().x_, m_player[i].GetCannonPos().y_, m_NearFishPos[i].x_, m_NearFishPos[i].y_);
				//  					float dis2 = CMathAide::CalcDistance(m_player[i].GetCannonPos().x_, m_player[i].GetCannonPos().y_, pFish->GetPosition().x_, pFish->GetPosition().y_);
				//  					if(dis2 < dis1)
				//  					{
				//  						m_NearFishPos[i].x_ = pFish->GetPosition().x_;
				//  						m_NearFishPos[i].y_ = pFish->GetPosition().y_;
				//  					}
				//  				}
				//  			}
				if(pFish->GetLockLevel() > 0)
				{
					m_CanLockList.push_back(pFish->GetId());
				}
				++m_nFishCount;
			}
			++ifs;
		}

// 	}
// 	catch (...)
// 	{
// 		CTraceService::TraceString(TEXT("OnGameUpdate错误2"),TraceLevel_Exception);
// 		DebugString(TEXT("[Fish]OnGameUpdate错误2"));
// 	}
	m_FishManager.Unlock();

	std::list<DWORD>::iterator it = rmList.begin();
	while(it != rmList.end())
	{
		m_FishManager.Remove(*it);
		++it;
	}

	rmList.clear();
	tFish = timeGetTime() - tFish;

	DWORD tBullet = timeGetTime();
	m_BulletManager.Lock();
	obj_table_iter ibu = m_BulletManager.Begin();
	try
	{
		while(ibu != m_BulletManager.End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			pBullet->OnUpdate(ndt);
			MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
			if(pMove == NULL || pMove->IsEndPath())
			{
				rmList.push_back(pBullet->GetId());
			}
			else if(CGameConfig::GetInstance()->bImitationRealPlayer && !hasR)
			{
				//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(pBullet->GetChairID());
				//if(ImitationRealPlayer(pUser))
				{
					ifs = m_FishManager.Begin();
					while(ifs != m_FishManager.End())
					{
						CFish* pFish = (CFish*)ifs->second;
						if(pFish->GetState() < EOS_DEAD && pBullet->HitTest(pFish))
						{
							SC_KillBullet csb;
							csb.set_chair_id(pBullet->GetChairID());
							csb.set_bullet_id(pBullet->GetId());
							broadcast2client_pb(&csb);  

							CatchFish(pBullet, pFish, 1, 0);
							rmList.push_back(pBullet->GetId());
							break;
						}
						++ifs;
					}
				}
			}	

			++ibu;
		}

	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnGameUpdate错误3"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnGameUpdate错误3"));
	}
	m_BulletManager.Unlock();

	it = rmList.begin();
	while(it != rmList.end())
	{
		m_BulletManager.Remove(*it);
		++it;
	}

	rmList.clear();
	tBullet = timeGetTime() - tBullet;

	

	DWORD tEvent = timeGetTime();
	CEventMgr::GetInstance()->Update(ndt);
	tEvent = timeGetTime() - tEvent;

	DWORD tDistrub = timeGetTime();
	try
	{
		DistrubFish(fdt);
	}
	catch (...)
	{
// 		CTraceService::TraceStringEx(TraceLevel_Exception, TEXT("刷鱼失败！"));
	}
	tDistrub = timeGetTime() - tDistrub;

	// 	if(timeGetTime() - NowTime > 100)
	// 	{
	// 		DebugString(TEXT("-------------------------------------------------------------------------------------"));
	// 		DebugString(TEXT("当前桌号%d,定时器工作时间达到%ld，各个阶段工作耗时如下：更新控制器用时:%ld,更新玩家的信息用时%ld\n更新鱼的位置信息用时%ld,更新子弹的位置信息用时%ld,事件处理用时%ld,刷新鱼用时%ld"), 
	// 			m_pITableFrame->GetTableID()+1, timeGetTime()-NowTime, tControl, tPlayer, tFish,tBullet,tEvent,tDistrub);
	// 	}

	m_dwLastTick = NowTime;
}

bool CTableFrameSink::HasRealPlayer()
{
	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		/*IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
		if(pUser != NULL && !pUser->IsAndroidUser())
			return true;

		pUser = m_pITableFrame->EnumLookonUserItem(i);
		if(pUser != NULL && !pUser->IsAndroidUser())
			return true;*/

		if (m_player[i].get_guid() != 0)
			return true;
	}

	return false;
}

void CTableFrameSink::CatchFish(CBullet* pBullet, CFish* pFish, int nCatch, int* nCatched)
{
 	float pbb = pBullet->GetProbilitySet(pFish->GetTypeID()) / MAX_PROBABILITY;
 	float pbf = pFish->GetProbability() / nCatch;

 	float fPB = 1.0f;
	//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(pBullet->GetChairID());
  	//if(pUser == NULL) return;
 	
	//if(!ImitationRealPlayer(pUser))
 		fPB = CGameConfig::GetInstance()->fAndroidProbMul;
 	
	std::list<MyObject*> list;

	bool bCatch = false;
	SCORE lScore = 0;
	auto chair_id = pBullet->GetChairID();
	ASSERT(chair_id < MAX_TABLE_CHAIR);
	bool is_catch_by_rebate = false;// 是否是因为用户有返利导致的捕获命中

	try
	{
		//if(ServerManager::m_pControl == NULL || !ImitationRealPlayer(pUser) || m_pGameServiceOption->wServerType != GAME_GENRE_GOLD)
		{
//#ifdef _DEBUG
			//bCatch = true;
//#else
			bCatch = RandFloat(0, MAX_PROBABILITY) < pbb * pbf * fPB;
//#endif // _DEBUG
			if (bCatch) {
				lScore = CommonLogic::GetFishEffect(pBullet, pFish, list, false);
			}
		}
		//else {
		//	bCatch = ServerManager::m_pControl->CanCatchFish(m_pITableFrame, pUser, pBullet, pFish, CGameConfig::GetInstance()->m_MaxCannon, lScore, list, is_catch_by_rebate);
		//}

		auto score_pool = user_score_pools_[chair_id];
		if (!bCatch && score_pool > 0) {// 如果当前没有成功捕获 并且玩家有被吃的子弹
			bCatch = score_pool > lScore;// 如果吃掉玩家的分数大于鱼的分数，优先给玩家退还吃掉的分数
			if (bCatch) {// 吃的分数被退还了
				user_score_pools_[chair_id] -= lScore;
#ifdef _DEBUG
				/*CString str;
				str.Format(_T("退还分数[%d] 玩家ID[%d]"), lScore, pUser->GetUserID());
				CTraceService::TraceString(str, TraceLevel_Debug);*/
#endif // _DEBUG
			}
		}
	}
	catch(...)
	{
		//CTraceService::TraceString(_T("计算命中失败"), TraceLevel_Debug);
	}

	// del lee for test
	//pFish->SetState(EOS_HIT, pBullet);

	if(bCatch)
	{
  		//if(ImitationRealPlayer(pUser))
 		{
 			std::list<MyObject*> ll;
 			LONGLONG lst = CommonLogic::GetFishEffect(pBullet, pFish, ll, false);
 			ll.clear();
 		}

		try
		{
			m_player[pBullet->GetChairID()].AddScore(lScore);

			//if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pUser) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			//	ServerManager::m_pControl->CatchFish(m_pITableFrame, pBullet, pUser, lScore, is_catch_by_rebate);
			user_win_scores_[chair_id] += lScore;
			//if (is_catch_by_rebate && pUser->IsRebateUser()) {// 只有在本次用户的返利参与了加成计算时，才扣除用户返利
			///	pUser->DecUserRebate(lScore);
			//}
			if(pFish->BroadCast() && lScore/pBullet->GetScore() >= CGameConfig::GetInstance()->nMinNotice)
			{
				//TCHAR szInfo[512];
				//_sntprintf_s(szInfo, _TRUNCATE, TEXT("恭喜%s第%d桌的玩家『%s』打中%s,获得%I64d倍的奖励!!!"), m_pGameServiceOption->szServerName, m_pITableFrame->GetTableID()+1, pUser->GetNickName(), pFish->GetName(), lScore/pBullet->GetScore());
				//RaiseEvent("CatchFishBroadCast", szInfo, pUser);
			}

			//能量炮
			if(lScore/pBullet->GetScore() > CGameConfig::GetInstance()->nIonMultiply && RandInt(0, MAX_PROBABILITY) < CGameConfig::GetInstance()->nIonProbability)
			{
				BufferMgr* pBMgr = (BufferMgr*)m_player[pBullet->GetChairID()].GetComponent(ECF_BUFFERMGR);
				if(pBMgr != NULL && !pBMgr->HasBuffer(EBT_DOUBLE_CANNON))
				{
					pBMgr->Add(EBT_DOUBLE_CANNON, 0, CGameConfig::GetInstance()->fDoubleTime);
					RaiseEvent("CannonSetChanaged", &(m_player[pBullet->GetChairID()]));
				}
			}
		}
		catch (...)
		{
			//CTraceService::TraceString(TEXT("CatchFish错误"),TraceLevel_Exception);
			DebugString(TEXT("[Fish]CatchFish错误"));
		}

		SendCatchFish(pBullet, pFish, lScore);

		std::list<MyObject*>::iterator im = list.begin();
		while(im != list.end())
		{
			CFish* pf = (CFish*)*im;
			for(WORD i = 0; i < GAME_PLAYER; ++i)
			{
				if(m_player[i].GetLockFishID() == pf->GetId())
				{
					m_player[i].SetLockFishID(0);
				}
			}
 			if(pf != pFish) 
 			{
 				m_FishManager.Remove(pf);
 			}
			++im;
		}

		m_FishManager.Remove(pFish);

		if(nCatched != NULL)
			*nCatched = *nCatched + 1;
	}
}

void CTableFrameSink::SendCatchFish(CBullet* pBullet, CFish*pFish, LONGLONG score)
{
	if(pBullet != NULL && pFish != NULL)
	{
		SC_KillFish ck;

		ck.set_chair_id(pBullet->GetChairID());
		ck.set_fish_id(pFish->GetId());
		ck.set_score(score);
		ck.set_bscoe(pBullet->GetScore());

		broadcast2client_pb(&ck);
	}
}

void CTableFrameSink::AddBuffer(int btp, float parm, float ft)
{
	SC_AddBuffer cab;
	cab.set_buffer_type(btp);
	cab.set_buffer_param(parm);
	cab.set_buffer_time(ft);
	broadcast2client_pb(&cab);

	try
	{
		m_FishManager.Lock();
		obj_table_iter ifs = m_FishManager.Begin();
		while(ifs != m_FishManager.End())
		{
			MyObject* pObj = ifs->second;
			BufferMgr* pBM = (BufferMgr*)pObj->GetComponent(ECF_BUFFERMGR);
			if(pBM != NULL)
			{
				pBM->Add(btp, parm, ft);
			}
			++ifs;
		}
		m_FishManager.Unlock();
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("AddBuffer错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]AddBuffer错误"));
	}
}

void CTableFrameSink::DistrubFish(float fdt)
{
	if (m_fPauseTime > 0.0f)
	{
		m_fPauseTime -= fdt;
		return;
	}

	m_fSceneTime += fdt;

	if (m_fSceneTime > SWITCH_SCENE_END && !m_bAllowFire)
	{
		m_bAllowFire = true;
		SendAllowFire(INVALID_CHAIR);
	}

	if (CGameConfig::GetInstance()->SceneSets.find(m_nCurScene) == CGameConfig::GetInstance()->SceneSets.end())
	{
		return;
	}

	if (m_fSceneTime < CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime)
	{
		int npos = 0;
		std::list<TroopSet>::iterator is = CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.begin();
		while (is != CGameConfig::GetInstance()->SceneSets[m_nCurScene].TroopList.end())
		{
			TroopSet ts = *is;
			if (!HasRealPlayer())
			{
				if (m_fSceneTime >= ts.fBeginTime && m_fSceneTime <= ts.fEndTime)
					m_fSceneTime = ts.fEndTime + fdt;
			}

			if (m_fSceneTime >= ts.fBeginTime && m_fSceneTime <= ts.fEndTime)
			{
				int tid = ts.nTroopID;

				if (npos < m_vDistrubTroop.size())
				{
					if (!m_vDistrubTroop[npos].bSendDes)
					{
						AddBuffer(EBT_CHANGESPEED, 5, 60);
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp != NULL)
						{
							SC_SendDes ccd;

							size_t nCount = ptp->Describe.size();
							if (nCount > 4) nCount = 4;

							m_vDistrubTroop[npos].fBeginTime = nCount * 2.0f;//每条文字分配2秒的显示时间
							for (int i = 0; i<nCount; ++i)
							{
								ccd.add_des(ptp->Describe[i]);
							}

							broadcast2client_pb(&ccd);
						}
						m_vDistrubTroop[npos].bSendDes = true;
					}
					else if (!m_vDistrubTroop[npos].bSendTroop && m_fSceneTime>(m_vDistrubTroop[npos].fBeginTime + ts.fBeginTime))
					{
						m_vDistrubTroop[npos].bSendTroop = true;
						Troop* ptp = PathManager::GetInstance()->GetTroop(tid);
						if (ptp == NULL)
						{
							m_fSceneTime += CGameConfig::GetInstance()->SceneSets[m_nCurScene].fSceneTime;
						}
						else
						{
							int n = 0, ns = ptp->nStep.size();
							for (int i = 0; i < ns; ++i)
							{
								int Fid = -1, ncount = ptp->nStep[i];
								for (int j = 0; j < ncount; ++j)
								{
									if (n >= ptp->Shape.size()) break;
									ShapePoint& tp = ptp->Shape[n++];

									int WeightCount = 0, nsz = min(tp.m_lTypeList.size(), tp.m_lWeight.size());
									if (nsz == 0) continue;

									for (int iw = 0; iw < nsz; ++iw)
										WeightCount += tp.m_lWeight[iw];
									for (int ni = 0; ni < tp.m_nCount; ++ni)
									{
										if (Fid == -1 || !tp.m_bSame)
										{
											int wpos = 0, nf = RandInt(0, WeightCount);
											while (nf > tp.m_lWeight[wpos])
											{
												if (wpos >= tp.m_lWeight.size()) break;
												nf -= tp.m_lWeight[wpos];
												++wpos;
												if (wpos >= nsz)
													wpos = 0;
											}
											if (wpos < tp.m_lTypeList.size())
												Fid = tp.m_lTypeList[wpos];
										}
										std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
										if (ift != CGameConfig::GetInstance()->FishMap.end())
										{
											Fish finf = ift->second;
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

		if (m_fSceneTime > SWITCH_SCENE_END)
		{
			int nfpos = 0;
			std::list<DistrubFishSet>::iterator it = CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.begin();
			while (it != CGameConfig::GetInstance()->SceneSets[m_nCurScene].DistrubList.end())
			{
				DistrubFishSet dis = *it;

				if (nfpos >= m_vDistrubFishTime.size())
				{
					break;
				}
				m_vDistrubFishTime[nfpos] += fdt;
				if (m_vDistrubFishTime[nfpos] > dis.ftime)
				{
					m_vDistrubFishTime[nfpos] -= dis.ftime;

					if (HasRealPlayer())
					{
						int nsz = min(dis.Weight.size(), dis.FishID.size());
						int WeightCount = 0;
						int nct = RandInt(dis.nMinCount, dis.nMaxCount);
						int nCount = nct;
						int SnakeType = 0;

						if (dis.nRefershType == ERT_SNAK)
						{
							nCount += 2;
							nct += 2;
						}

						DWORD nRefershID = IDGenerator::GetInstance()->GetID64();

						for (int wi = 0; wi < nsz; ++wi)
							WeightCount += dis.Weight[wi];

						if (nsz > 0)
						{
							int ftid = -1;
							int pid = PathManager::GetInstance()->GetRandNormalPathID();
							while (nct > 0)
							{
								if (ftid == -1 || dis.nRefershType == ERT_NORMAL)
								{
									pid = PathManager::GetInstance()->GetRandNormalPathID();
									if (WeightCount == 0)
										ftid = dis.FishID[0];
									else
									{
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

								if (dis.nRefershType == ERT_SNAK)
								{
									if (nct == nCount)
										ftid = CGameConfig::GetInstance()->nSnakeHeadType;
									else if (nct == 1)
										ftid = CGameConfig::GetInstance()->nSnakeTailType;
								}

								std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(ftid);
								if (ift != CGameConfig::GetInstance()->FishMap.end())
								{
									Fish finf = ift->second;

									int FishType = ESFT_NORMAL;

									float xOffest = RandFloat(-dis.OffestX, dis.OffestX);
									float yOffest = RandFloat(-dis.OffestY, dis.OffestY);
									float fDelay = RandFloat(0.0f, dis.OffestTime);

									if (dis.nRefershType == ERT_LINE || dis.nRefershType == ERT_SNAK)
									{
										xOffest = dis.OffestX;
										yOffest = dis.OffestY;
										fDelay = dis.OffestTime * (nCount - nct);
									}
									else if (dis.nRefershType == ERT_NORMAL && m_nSpecialCount < CGameConfig::GetInstance()->nMaxSpecailCount)
									{
										std::map<int, SpecialSet>* pMap = NULL;

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

										if (pMap != NULL)
										{
											std::map<int, SpecialSet>::iterator ist = pMap->find(ftid);
											if (ist != pMap->end())
											{
												SpecialSet& kks = ist->second;
												if (RandFloat(0, MAX_PROBABILITY) < kks.fProbability)
													FishType = fft;
											}
										}
									}

									CFish* pFish = CommonLogic::CreateFish(finf, xOffest, yOffest, 0.0f, fDelay, finf.nSpeed, pid, false, FishType);
									if (pFish != NULL)
									{
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
	{
		int nex = CGameConfig::GetInstance()->SceneSets[m_nCurScene].nNextID;
		if (CGameConfig::GetInstance()->SceneSets.find(nex) != CGameConfig::GetInstance()->SceneSets.end())
		{
			m_nCurScene = nex;
		}

		ResetSceneDistrub();

		for (WORD wc = 0; wc < GAME_PLAYER; ++wc)
		{
			m_player[wc].SetLocking(false);
			m_player[wc].SetLockFishID(0);
			m_player[wc].ClearBulletCount();

			SC_LockFish cl;
			cl.set_chair_id(wc);
			broadcast2client_pb(&cl);
		}

		m_bAllowFire = false;
		SendAllowFire(INVALID_CHAIR);

		SC_SwitchScene css;
		css.set_nst(m_nCurScene);
		css.set_switching(1);
		broadcast2client_pb(&css);

		m_FishManager.Clear();
		//m_BulletManager.Clear();

		m_fSceneTime = 0.0f;
	}
}

int	CTableFrameSink::CountPlayer()
{
	int n = 0;

	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		//if(m_pITableFrame->GetTableUserItem(i) != NULL)
		//	++n;
		if (m_player[i].get_guid() != 0)
			++n;
	}

	return n;
}

void CTableFrameSink::SendFish(CFish* pFish, WORD wChairID)
{
	DWORD tt = timeGetTime();	
	std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(pFish->GetTypeID());
	if(ift != CGameConfig::GetInstance()->FishMap.end())
	{
		Fish finf = ift->second;

		SC_SendFish css;

		css.set_fish_id(pFish->GetId());
		css.set_type_id(pFish->GetTypeID());
		css.set_create_tick(pFish->GetCreateTick());
		css.set_fis_type(pFish->GetFishType());
		css.set_refersh_id(pFish->GetRefershID());

		MoveCompent* pMove = (MoveCompent*)pFish->GetComponent(ECF_MOVE);
		if(pMove != NULL)
		{
			css.set_path_id(pMove->GetPathID());
			css.set_offest_x(pMove->GetOffest().x_);
			css.set_offest_y(pMove->GetOffest().y_);
			if(pMove->GetID() == EMCT_DIRECTION) 
			{
				css.set_offest_x(pMove->GetPostion().x_);
				css.set_offest_y(pMove->GetPostion().y_);
			}
			css.set_dir(pMove->GetDirection());
			css.set_delay(pMove->GetDelay());
			css.set_fish_speed(pMove->GetSpeed());
			css.set_troop(pMove->bTroop() ? 1 : 0);
		}

		BufferMgr* pBM = (BufferMgr*)pFish->GetComponent(ECF_BUFFERMGR);
		if(pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT))
		{
			PostEvent("FishMulChange", pFish);
		}

		css.set_server_tick(timeGetTime());
// 		css.bSpecial = pFish->bSpecial();
		
		send2client_pb(wChairID, &css);
	}

	tt = timeGetTime() - tt;
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

bool CTableFrameSink::OnChangeCannonSet(CS_ChangeCannonSet* msg)
{
	if(msg->chair_id() >= GAME_PLAYER) return false;

	try
	{
		BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id()].GetComponent(ECF_BUFFERMGR);
		if(pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON)))
		{
			return true;//离子炮或能量炮时禁止换炮
		}

		int n = m_player[msg->chair_id()].GetCannonSetType();

		do 
		{
			if(msg->add())
			{
				if(n < CGameConfig::GetInstance()->CannonSetArray.size()-1)
					++n;
				else
					n = 0;
			}
			else
			{
				if(n >= 1)
					--n;
				else
					n = CGameConfig::GetInstance()->CannonSetArray.size()-1;
			}
		} while (n == CGameConfig::GetInstance()->CannonSetArray[n].nIonID || n == CGameConfig::GetInstance()->CannonSetArray[n].nDoubleID);

		if(n < 0) n = 0;
		if(n >= CGameConfig::GetInstance()->CannonSetArray.size())
			n = CGameConfig::GetInstance()->CannonSetArray.size() - 1;

		m_player[msg->chair_id()].SetCannonSetType(n);
		m_player[msg->chair_id()].CacluteCannonPos(msg->chair_id());

		SendCannonSet(msg->chair_id());

		return true;
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnChangeCannonSet错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnChangeCannonSet错误"));
		return false;
	}
}

bool CTableFrameSink::OnFire(CS_Fire* msg)
{
	if(msg->chair_id()>=GAME_PLAYER) return false;
	auto chair_id = msg->chair_id();

	// lee test
// 	m_player[pf->wChairID].SetLastFireTick(timeGetTime());
// 	return true;
	// lee test end.

	int mul = m_player[msg->chair_id()].GetMultiply();
	if (mul<0 || mul>=CGameConfig::GetInstance()->BulletVector.size()) return false;

	//if(!HasRealPlayer() && pIServerUserItem->IsAndroidUser())
	//	m_player[pIServerUserItem->GetChairID()].SetLastFireTick(timeGetTime());

	if (m_bAllowFire && (HasRealPlayer() || CGameConfig::GetInstance()->bImitationRealPlayer) && m_player[msg->chair_id()].CanFire())
	{
		Bullet binf = CGameConfig::GetInstance()->BulletVector[mul];
		//if(m_player[pf->wChairID].GetScore() >= binf.nMulriple/* && m_player[pf->wChairID].GetBulletCount() <= CGameConfig::GetInstance()->nMaxBullet*/)
		if (m_player[msg->chair_id()].GetScore() >= binf.nMulriple && m_player[msg->chair_id()].GetBulletCount() <= CGameConfig::GetInstance()->nMaxBullet)
		{
			m_player[msg->chair_id()].AddScore(-binf.nMulriple);
			m_player[msg->chair_id()].SetFired();

			LONGLONG lRevenue = 0;
			//if(ServerManager::m_pControl != NULL && ImitationRealPlayer(pIServerUserItem) && m_pGameServiceOption->wServerType == GAME_GENRE_GOLD)
			//	ServerManager::m_pControl->OnFire(m_pITableFrame, pIServerUserItem->GetChairID(), pIServerUserItem, binf.nMulriple, lRevenue);

			// 整理税收和玩家输赢分数
			user_revenues_[chair_id] += lRevenue;
			user_win_scores_[chair_id] -= binf.nMulriple;

			CBullet* pBullet = CommonLogic::CreateBullet(binf, m_player[msg->chair_id()].GetCannonPos(), msg->direction(),
				m_player[msg->chair_id()].GetCannonType(), m_player[msg->chair_id()].GetMultiply(), false);

			if(pBullet != NULL)
			{
				if(msg->client_id() != 0)
					pBullet->SetId(msg->client_id());

				pBullet->SetChairID(msg->chair_id());
				pBullet->SetCreateTick(msg->fire_time());

				BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id()].GetComponent(ECF_BUFFERMGR);
				if(pBMgr != NULL && pBMgr->HasBuffer(EBT_DOUBLE_CANNON))
					pBullet->setDouble(true);

				if (m_player[msg->chair_id()].GetLockFishID() != 0)
				{
					MoveCompent* pMove = (MoveCompent*)pBullet->GetComponent(ECF_MOVE);
					if(pMove != NULL)
						pMove->SetTarget(&m_FishManager, m_player[msg->chair_id()].GetLockFishID());
				}

				DWORD now = timeGetTime();
				if(msg->fire_time() > now)
				{
					//m_pITableFrame->SendTableData(pf->wChairID, SUB_S_FORCE_TIME_SYNC);
				}
				else
				{
					now = now - msg->fire_time();
					if(now > 2000) now = 2000;
					pBullet->OnUpdate(now);
				}
				m_player[msg->chair_id()].ADDBulletCount(1);
				m_BulletManager.Add(pBullet);
				SendBullet(pBullet, INVALID_CHAIR, true);
			}

			m_player[msg->chair_id()].SetLastFireTick(timeGetTime());
		}
		/*else if(!pIServerUserItem->IsAndroidUser())
		{
			m_pITableFrame->SendTableData(pf->wChairID, SUB_S_FIRE_FAILE);
		}*/
	}

	return true;
}

void CTableFrameSink::SendBullet(CBullet* pBullet, WORD wChairID, bool bNew)
{
	if(pBullet == NULL) return;

	try
	{
		SC_SendBullet csb;
		csb.set_chair_id(pBullet->GetChairID());
		csb.set_id(pBullet->GetId());
		csb.set_cannon_type(pBullet->GetCannonType());
		csb.set_multiply(pBullet->GetTypeID());
		csb.set_direction(pBullet->GetDirection());
		csb.set_x_pos(pBullet->GetPosition().x_);
		csb.set_y_pos(pBullet->GetPosition().y_);
		csb.set_score(m_player[pBullet->GetChairID()].GetScore());//pBullet->GetScore();
		csb.set_is_new(bNew ? 1 : 0);
		csb.set_is_double(pBullet->bDouble() ? 1 : 0);
		if(bNew)
			csb.set_create_tick(pBullet->GetCreateTick());
		else	
			csb.set_create_tick(timeGetTime());

		csb.set_server_tick(timeGetTime());

		send2client_pb(wChairID, &csb);
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("SendBullet错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]SendBullet错误"));
	}
}

//框架消息处理
/*bool  CTableFrameSink::OnFrameMessage(WORD wSubCmdID,  void * pDataBuffer, WORD wDataSize, IServerUserItem * pIServerUserItem)
{
	return false;
}*/

bool CTableFrameSink::OnTimeSync(CS_TimeSync* msg)
{
	SC_TimeSync css;
	css.set_chair_id(msg->chair_id());
	css.set_client_tick(msg->client_tick());
	css.set_server_tick(timeGetTime());

	send2client_pb(msg->chair_id(), &css);

	return true;
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

bool CTableFrameSink::OnChangeCannon(CS_ChangeCannon* msg)
{
	if(msg->chair_id()>=GAME_PLAYER)
	{
		//DebugString(TEXT("[Fish]OnChangeCannon Err: wTableID %d wChairID %d"),m_pITableFrame->GetTableID() ,pcc->wChairID);
		return false;
	}

	try
	{
		BufferMgr* pBMgr = (BufferMgr*)m_player[msg->chair_id()].GetComponent(ECF_BUFFERMGR);
		if(pBMgr != NULL && (pBMgr->HasBuffer(EBT_DOUBLE_CANNON) || pBMgr->HasBuffer(EBT_ION_CANNON)))
		{
			return true;//离子炮或能量炮时禁止换炮
		}

		int mul = m_player[msg->chair_id()].GetMultiply();

		if(msg->add()) ++mul;
		else --mul;

		if(mul < 0) mul = CGameConfig::GetInstance()->BulletVector.size()-1;
		if(mul >= CGameConfig::GetInstance()->BulletVector.size()) mul = 0;

		m_player[msg->chair_id()].SetMultiply(mul);

		int CannonType = CGameConfig::GetInstance()->BulletVector[mul].nCannonType;

		m_player[msg->chair_id()].SetCannonType(CannonType);

		SendCannonSet(msg->chair_id());

		m_player[msg->chair_id()].SetLastFireTick(timeGetTime());

		return true;
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnChangeCannon错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnChangeCannon错误"));
		return false;
	}
}	

void CTableFrameSink::SendCannonSet(WORD wChairID)
{
	try
	{
		SC_CannonSet ccd;
		ccd.set_chair_id(wChairID);
		ccd.set_cannon_mul(m_player[wChairID].GetMultiply());
		ccd.set_cannon_type(m_player[wChairID].GetCannonType());
		ccd.set_cannon_set(m_player[wChairID].GetCannonSetType());
		broadcast2client_pb(&ccd);
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("SendCannonSet错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]SendCannonSet错误"));
	}
}

bool CTableFrameSink::OnTreasureEND(CS_TreasureEnd* msg)
{
	//try
	//{
		//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(pce->wChairID);
		//if (pUser != NULL && pce->lScore > 0)
	if (msg->chair_id() >= 0 && msg->chair_id() < m_player.size() && m_player[msg->chair_id()].get_guid() != 0)
		{
			/*TCHAR szInfo[512];

			_sntprintf_s(szInfo, _TRUNCATE, TEXT("恭喜%第%d桌的玩家『%s』打中宝箱,　并从中获得%I64d金币!!!"), m_pGameServiceOption->szServerName, m_pITableFrame->GetTableID()+1, pUser->GetNickName(), pce->lScore);

			RaiseEvent("CatchFishBroadCast", szInfo, pUser);

			m_player[pce->wChairID].SetCanFire(true);*/

			char szInfo[512];
			std::wstring str = TEXT("恭喜%s第%d桌的玩家『%s』打中宝箱,　并从中获得%I64d金币!!!");
			std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
			std::string narrowStr = conv.to_bytes(str);
			sprintf_s(szInfo, narrowStr.c_str(), "fishing",//GameServerConfigManager::instance()->get_config().game_name(),
				get_table_id(), m_player[msg->chair_id()].get_nickname().c_str(), msg->score());

			RaiseEvent("CatchFishBroadCast", szInfo, &m_player[msg->chair_id()]);
		}

		return true;
		/*}
	catch (...)
	{
		CTraceService::TraceString(TEXT("OnTreasureEND错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnTreasureEND错误"));
		return false;
	}

	return true;*/
}

void CTableFrameSink::ReturnBulletScore(WORD wChairID)
{
#if 0
	if(wChairID>=GAME_PLAYER)
	{
		DebugString(TEXT("[Fish]ReturnBulletScore Err: wTableID %d wChairID %d"),m_pITableFrame->GetTableID() ,wChairID);
		return;
	}
	try
	{
		IServerUserItem* pIServerUserItem = m_pITableFrame->GetTableUserItem(wChairID);
		if(pIServerUserItem != NULL)
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
		CTraceService::TraceString(TEXT("ReturnBulletScore错误1"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误1"));
	}

	std::list<DWORD> rmList;
	m_BulletManager.Lock();
	try
	{
		obj_table_iter ibu = m_BulletManager.Begin();
		while(ibu != m_BulletManager.End())
		{
			CBullet* pBullet = (CBullet*)ibu->second;
			if(pBullet->GetChairID() == wChairID)
				rmList.push_back(pBullet->GetId());

			++ibu;
		}
	}
	catch (...)
	{
		CTraceService::TraceString(TEXT("ReturnBulletScore错误2"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]ReturnBulletScore错误2"));
	}
	m_BulletManager.Unlock();

	std::list<DWORD>::iterator it = rmList.begin();
	while(it != rmList.end())
	{
		m_BulletManager.Remove(*it);
		++it;
	}

	rmList.clear();
#endif
}

void CTableFrameSink::OnAdwardEvent(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "AdwardEvent") return;
	CEffectAward* pe = (CEffectAward*)pEvent->GetParam();
	CFish* pFish = (CFish*)pEvent->GetSource();
	CBullet* pBullet = (CBullet*)pEvent->GetTarget();

	if(pe == NULL || pFish == NULL || pBullet == NULL) return;

	try
	{
		m_player[pBullet->GetChairID()].SetCanFire(false);

		LONGLONG lScore = 0;
		if(pe->GetParam(1) == 0)
		{
			if(pe->GetParam(2) == 0)
				lScore = pe->GetParam(3);
			else
				lScore = pBullet->GetScore() * pe->GetParam(3);
		}
		else
		{
			BufferMgr* pBMgr = (BufferMgr*)m_player[pBullet->GetChairID()].GetComponent(ECF_BUFFERMGR);
			if(pBMgr != NULL && !pBMgr->HasBuffer(pe->GetParam(2)))
			{
				pBMgr->Add(pe->GetParam(2), 0, pe->GetParam(3));
			}
		}

		m_player[pBullet->GetChairID()].AddScore(lScore);
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnAdwardEvent错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnAdwardEvent错误"));
	}
}

void CTableFrameSink::OnAddBuffer(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "AddBuffer") return;
	CEffectAddBuffer* pe = (CEffectAddBuffer*)pEvent->GetParam();

	CFish* pFish = (CFish*)pEvent->GetSource();
	if(pFish == NULL) return;

	if(pFish->GetMgr() != &m_FishManager) return;

	if(pe->GetParam(0) == 0 && pe->GetParam(2) == EBT_CHANGESPEED && pe->GetParam(3) == 0)//定屏
	{
		m_fPauseTime = pe->GetParam(4);
	}
}

void CTableFrameSink::OnMulChange(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "FishMulChange") return;

	CFish* pFish = (CFish*)pEvent->GetParam();
	if(pFish != NULL)
	{
		try
		{
			m_FishManager.Lock();
			obj_table_iter ifs = m_FishManager.Begin();
			while(ifs != m_FishManager.End())
			{

				CFish* pf = (CFish*)ifs->second;
				if(pf != NULL && pf->GetTypeID() == pFish->GetTypeID())
				{
					SC_FishMul cm;
					
					cm.set_fish_id(pf->GetId());

					CBullet bt;
					bt.SetScore(1);
					std::list<MyObject*> llt;
					llt.clear();
					EffectMgr* pEM = (EffectMgr*)pf->GetComponent(ECF_EFFECTMGR);
					if(pEM != NULL)
					{
						cm.set_mul(pEM->Execute(&bt, llt, true));
					}

					broadcast2client_pb(&cm);
				}

				++ifs;

			}
			m_FishManager.Unlock();
		}
		catch (...)
		{
			//CTraceService::TraceString(TEXT("OnMulChange错误"),TraceLevel_Exception);
			DebugString(TEXT("[Fish]OnMulChange错误"));
		}
	}
}

void CTableFrameSink::OnFirstFire(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "FirstFire") return;

	CPlayer* pPlayer = (CPlayer*)pEvent->GetParam();

	for(WORD i = 0; i < GAME_PLAYER; ++i)
	{
		if(&m_player[i] == pPlayer)
		{
			//IServerUserItem* pUser = m_pITableFrame->GetTableUserItem(i);
			//if(pUser == NULL) break;

			int npos = -1;
			std::vector<FirstFire>::iterator it = CGameConfig::GetInstance()->FirstFireList.begin();
			while(it != CGameConfig::GetInstance()->FirstFireList.end())
			{
				//if(it->nLevel > pUser->GetMemberOrder())
				//	break;
				++npos;
				++it;
			}
			FirstFire& ff = CGameConfig::GetInstance()->FirstFireList[npos];

			int nsz = min(ff.FishTypeVector.size(), ff.WeightVector.size());
			if(nsz <= 0) continue;
			int WeightCount = 0;
			for(int iw = 0; iw < nsz; ++iw)
			{
				WeightCount += ff.WeightVector[iw];
			}

			MyPoint pt = m_player[i].GetCannonPos();
			float dir = CGameConfig::GetInstance()->CannonPos[i].m_Direction;

			for(int nc = 0; nc < ff.nCount; ++ nc)
			{
				for(int ni = 0; ni < ff.nPriceCount; ++ni)
				{
					int Fid = ff.FishTypeVector[RandInt(0, nsz)];
					int nf = RandInt(0, WeightCount);
					int wpos = 0;
					for(; wpos < nsz; ++wpos)
					{
						if(nf > ff.WeightVector[wpos])
						{
							nf -= ff.WeightVector[wpos];
						}
						else
						{
							Fid = ff.FishTypeVector[wpos];
							break;;
						}
					}

					if(wpos >= nsz)
					{
						Fid = ff.FishTypeVector[0];
					}

					dir = CGameConfig::GetInstance()->CannonPos[i].m_Direction - M_PI_2 + M_PI / ff.nPriceCount * ni;

					std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(Fid);
					if(ift != CGameConfig::GetInstance()->FishMap.end())
					{
						Fish& finf = ift->second;

						CFish* pFish = CommonLogic::CreateFish(finf, pt.x_, pt.y_, dir, RandFloat(0.0f, 1.0f)+nc, finf.nSpeed, -2);
						if(pFish != NULL)
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

void CTableFrameSink::OnProduceFish(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "ProduceFish") return;

	CEffectProduce* pe = (CEffectProduce*)pEvent->GetParam();

	CFish* pFish = (CFish*)pEvent->GetSource();
	if(pFish == NULL) return;

	if(pFish->GetMgr() != &m_FishManager) return;
	MyPoint pt = pFish->GetPosition();

	SC_SendFishList msg;
	std::map<int, Fish>::iterator ift = CGameConfig::GetInstance()->FishMap.find(pe->GetParam(0));
	if(ift != CGameConfig::GetInstance()->FishMap.end())
	{
		Fish finf = ift->second;
		float fdt = M_PI * 2.0f / (float)pe->GetParam(2);

		int fishtype = ESFT_NORMAL;
		int ndif = -1;
		for(int i = 0; i < pe->GetParam(1); ++i)
		{
			if(i == pe->GetParam(1) -1 && pe->GetParam(1) > 2 && pe->GetParam(2) > 10)
				ndif = RandInt(0, pe->GetParam(2));

			for(int j = 0; j < pe->GetParam(2); ++j)
			{
				if(j == ndif) 
					fishtype = ESFT_KING;
				else
					fishtype = ESFT_NORMAL;

				CFish* pf = CommonLogic::CreateFish(finf, pt.x_, pt.y_, fdt*j, 1.0f+pe->GetParam(3)*i, finf.nSpeed, -2, false, fishtype);
				if(pf != NULL)
				{
					m_FishManager.Add(pf);
					//SendFish(pf);
					// 换成只处理数据
					//ASSERT(fishs->dwFishCount < 300);
					//if (fishs->dwFishCount >= 300) {
						//CTraceService::TraceString(_T("SUB_S_SEND_FISHS > 300"), TraceLevel_Warning);
					//	break;
					//}
					if (msg.fishes_size() >= 300)
						break;
					
					auto fish = msg.add_fishes();

					fish->set_fish_id(pf->GetId());
					fish->set_type_id(pf->GetTypeID());
					fish->set_create_tick(pf->GetCreateTick());
					fish->set_fis_type(pf->GetFishType());
					fish->set_refersh_id(pf->GetRefershID());

					MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
					if (pMove != NULL) {
						fish->set_path_id(pMove->GetPathID());
						fish->set_offest_x(pMove->GetOffest().x_);
						fish->set_offest_y(pMove->GetOffest().y_);
						if (pMove->GetID() == EMCT_DIRECTION) {
							fish->set_offest_x(pMove->GetPostion().x_);
							fish->set_offest_y(pMove->GetPostion().y_);
						}
						fish->set_dir(pMove->GetDirection());
						fish->set_delay(pMove->GetDelay());
						fish->set_fish_speed(pMove->GetSpeed());
						fish->set_troop(pMove->bTroop() ? 1 : 0);
					}

					BufferMgr* pBM = (BufferMgr*)pf->GetComponent(ECF_BUFFERMGR);
					if (pBM != NULL && pBM->HasBuffer(EBT_ADDMUL_BYHIT)) {
						PostEvent("FishMulChange", pf);
					}

					fish->set_server_tick(timeGetTime());
				}
			}
		}
	}

	broadcast2client_pb(&msg);
}

void CTableFrameSink::LockFish(WORD wChairID)
{
	//if(wChairID >= GAME_PLAYER || m_pITableFrame->GetTableUserItem(wChairID) == NULL) return;

	DWORD dwFishID = 0;

	CFish* pf = NULL;
	try
	{
		dwFishID = m_player[wChairID].GetLockFishID();
		if(dwFishID != 0)
			pf = (CFish*)m_FishManager.Find(dwFishID);

		if(pf != NULL)
		{
			MoveCompent* pMove = (MoveCompent*)pf->GetComponent(ECF_MOVE);
			if(pf->GetState() >= EOS_DEAD || pMove == NULL || pMove->IsEndPath())
				pf = NULL;
		}

	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("LockFish错误1"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]LockFish错误1"));
		pf = NULL;
	}

	dwFishID = 0;

	CFish* pLock = NULL;

	try
	{
		std::list<DWORD>::iterator iw = m_CanLockList.begin();
		while(iw != m_CanLockList.end())
		{
			CFish* pFish  = (CFish*)m_FishManager.Find(*iw);
			if(pFish != NULL && pFish->GetState() < EOS_DEAD && pFish->GetLockLevel() > 0 && pFish->InSideScreen())
			{
				if((pf == NULL) || (pf != pFish && !m_player[wChairID].HasLocked(pFish->GetId())))
				{
					pf = pFish;

					if(pLock == NULL)
					{
						pLock = pf;
					}
					else if(pf->GetLockLevel() > pLock->GetLockLevel())
					{
						pLock = pf;
					}
				}
			}

			++iw;

		}

		if(pLock != NULL)
			dwFishID = pLock->GetId();

		m_player[wChairID].SetLockFishID(dwFishID);

		if(m_player[wChairID].GetLockFishID() != 0)
		{
			SC_LockFish cl;
			cl.set_chair_id(wChairID);
			cl.set_lock_id(dwFishID);
			broadcast2client_pb(&cl);
		}

	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("LockFish错误2"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]LockFish错误2"));
	}
}

bool CTableFrameSink::OnLockFish(CS_LockFish* msg)
{
	if(msg->chair_id()>=GAME_PLAYER)
	{
		//DebugString(TEXT("[Fish]OnLockFish Err: wTableID %d wChairID %d"),m_pITableFrame->GetTableID() ,pc->wChairID);
		return false;
	}
 	if(!HasRealPlayer()) return true;

	try
	{
		if(msg->lock())
		{
			m_player[msg->chair_id()].SetLocking(true);
			LockFish(msg->chair_id());
		}
		else
		{
			m_player[msg->chair_id()].SetLocking(false);
			m_player[msg->chair_id()].SetLockFishID(0);

			SC_LockFish cl;
			cl.set_chair_id(msg->chair_id());
			broadcast2client_pb(&cl);
		}

		m_player[msg->chair_id()].SetLastFireTick(timeGetTime());

		return true;
	}
	catch (...)
	{
		//CTraceService::TraceString(TEXT("OnLockFish错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnLockFish错误"));
		return false;
	}

}

void CTableFrameSink::OnCannonSetChange(CMyEvent* pEvent)
{
	if(pEvent == NULL || pEvent->GetName() != "CannonSetChanaged")
		return;

	CPlayer* pp = (CPlayer*)pEvent->GetParam();
	if(pp != NULL)
	{
		auto sz = m_player.size();
		for (size_t i = 0; i < sz; ++i)
		{
			if(&m_player[i] == pp)
			{
				SendCannonSet(i);
			}
		}
	}
}

bool CTableFrameSink::OnNetCast(CS_Netcast* msg)
{
	auto bullet_id = msg->bullet_id();
	auto fish_id = msg->fish_id();

	try
	{
		m_BulletManager.Lock();
		CBullet* pBullet = (CBullet*)m_BulletManager.Find(bullet_id);
		if(pBullet != NULL)
		{
			auto chair_id = pBullet->GetChairID();
			m_FishManager.Lock();
			CFish* pFish = (CFish*)m_FishManager.Find(fish_id);
			if (pFish != NULL) {
				CatchFish(pBullet, pFish, 1, 0);
			}
			else {
// #ifdef _DEBUG
// 				CString str;
// 				str.Format(_T("鱼不存在[%d]"), pcn->dwFishID);
// 				CTraceService::TraceString(str, TraceLevel_Debug);
// #endif // _DEBUG
				// 这里因为鱼不存在，所以我们吃掉了玩家一个子弹，给玩家加到玩家分数池里以便后面退给玩家
				user_score_pools_[chair_id] += pBullet->GetScore();
#ifdef _DEBUG
				//auto player = m_pITableFrame->GetTableUserItem(chair_id);
				//ASSERT(player);
				//if (player) {
					/*CString str;
					str.Format(_T("贪污子弹 玩家ID[%d] 当前贪污[%I64d]"), player->GetUserID(), user_score_pools_[chair_id]);
					CTraceService::TraceString(str, TraceLevel_Debug);*/
				//}
#endif // _DEBUG
			}
			m_FishManager.Unlock();

			SC_KillBullet csb;
			csb.set_chair_id(chair_id);
			csb.set_bullet_id(bullet_id);
			broadcast2client_pb(&csb);

			m_player[chair_id].ADDBulletCount(-1);

			//m_BulletManager.Remove(pB);
			m_BulletManager.Remove(bullet_id);
		}
		else {
// #ifdef _DEBUG
// 			CString str;
// 			str.Format(_T("子弹不存在[%d]"), pcn->dwBulletID);
// 			CTraceService::TraceString(str, TraceLevel_Debug);
// #endif // _DEBUG

			// TODO: 如果子弹不存在，也可能导致一些问题：玩家碰撞子弹的包比子弹出现的包被先一步处理了，这里后续完善 
		}
		m_BulletManager.Unlock();
	}
	catch(...)
	{
		//CTraceService::TraceString(TEXT("OnNetCast错误"),TraceLevel_Exception);
		DebugString(TEXT("[Fish]OnNetCast错误"));
	}

	return true;
}
 
void CTableFrameSink::OnCatchFishBroadCast(CMyEvent* pEvent)
{
	if(pEvent != NULL && pEvent->GetName() == "CatchFishBroadCast")
	{
		//IServerUserItem* pp = (IServerUserItem*)pEvent->GetSource();
		CPlayer* pp = (CPlayer*)pEvent->GetSource();
		if(pp != NULL)
		{
			//for(WORD i = 0; i < GAME_PLAYER; ++i)
			{
				//if(m_pITableFrame->GetTableUserItem(i) == pp)
				{
					//m_pITableFrame->SendGameMessage(pp, (LPCTSTR)pEvent->GetParam(), SMT_TABLE_ROLL);
					SC_SystemMessage msg;
					msg.set_wtype(SMT_TABLE_ROLL);
					msg.set_szstring((char*)pEvent->GetParam());
					send2client_pb(pp->get_chair_id(), &msg);
					//break;
					//m_pITableFrame->SendRoomMessage((IServerUserItem*)pEvent->GetSource(), (LPCTSTR)pEvent->GetParam(), SMT_TABLE_ROLL);					
				}
			}
		}
	}
}

void CTableFrameSink::set_guid_gateid(int chair_id, int guid, int gate_id)
{
	if (chair_id >= 0 && chair_id < (int)m_player.size())
	{
		m_player[chair_id].set_guid_gateid(guid, gate_id);
		m_player[chair_id].set_chair_id(chair_id);
	}
	else
	{
		LOG_WARN("chair_id %d error", chair_id);
	}
}

void CTableFrameSink::set_nickname(int chair_id, const char* nickname)
{
	if (chair_id >= 0 && chair_id < (int)m_player.size())
	{
		m_player[chair_id].set_nickname(nickname);
	}
}
