//
#ifndef TABLE_FRAME_SINK_HEAD_FILE
#define TABLE_FRAME_SINK_HEAD_FILE

//#include "../消息定义/CMD_Fish.h"
#include "stdafx.h"
#include "Player.h"
#include "Bullet.h"
#include "Fish.h"
#include "MoveCompent.h"
#include "EffectManager.h"
#include "Effect.h"
#include "MyObjectManager.h"

#include "Define.h"
#include "GameSessionManager.h"
#include "common_msg_fishing.pb.h"

class CMyEvent;

struct RefershTroop
{
	bool	bSendDes;
	bool	bSendTroop;
	float	fBeginTime;
};

//游戏桌子类
class CTableFrameSink// : public ITableFrameSink, public ITableUserAction
{
	//组件变量
public:
	//ITableFrame						* m_pITableFrame;					//框架接口
	//tagGameServiceOption			* m_pGameServiceOption;				//游戏配置
	//tagGameServiceAttrib			* m_pGameServiceAttrib;				//游戏属性

	std::vector<CPlayer>			m_player;
	//函数定义
public:
	//构造函数
	CTableFrameSink();
	//析构函数
	virtual ~CTableFrameSink();

	//基础接口
public:
	//释放对象
	virtual VOID  Release();
	//接口查询
	//virtual void *  QueryInterface(const IID & Guid, DWORD dwQueryVer);

	//管理接口
public:
	void ResetTable();

	//复位接口
	virtual VOID RepositionSink();
	//配置接口
	virtual bool Initialization();

	//查询接口
public:
	//游戏状态
	//virtual bool IsUserPlaying(WORD wChairID) override;
	virtual bool IsUserPlaying(WORD wChairID);
	//查询限额
	//virtual SCORE QueryConsumeQuota(IServerUserItem * pIServerUserItem) override { return 0L; }
	//最少积分
	//virtual SCORE QueryLessEnterScore(WORD wChairID, IServerUserItem * pIServerUserItem) override { return 0L; }
	//查询是否扣服务费
	//virtual bool QueryBuckleServiceCharge(WORD wChairID) override { return true; }

	//游戏事件
public:
	//游戏开始
	virtual bool OnEventGameStart();
	//游戏结束
	virtual bool OnEventGameConclude(WORD wChairID, BYTE cbReason);
	//发送场景
	virtual bool OnEventSendGameScene(WORD wChairID, BYTE cbGameStatus, bool bSendSecret);

	//事件接口
public:
	//时间事件
	virtual bool OnTimerMessage(DWORD dwTimerID, WPARAM dwBindParameter);
	//数据事件
	//virtual bool OnDataBaseMessage(WORD wRequestID, VOID * pData, WORD wDataSize) { return true; }
	virtual bool OnDataBaseMessage(WORD, DWORD, void *, WORD)  { return true; }
	//积分事件
	//virtual bool OnUserScroeNotify(WORD wChairID, IServerUserItem * pIServerUserItem, BYTE cbReason) override { return true; }

	//网络接口
public:
	//游戏消息
	//virtual bool OnGameMessage(WORD wSubCmdID, VOID * pData, WORD wDataSize, IServerUserItem * pIServerUserItem) override;
	//框架消息
	//virtual bool OnFrameMessage(WORD wSubCmdID, VOID * pData, WORD wDataSize, IServerUserItem * pIServerUserItem) override;

	//比赛接口
public:
	//设置基数
	virtual void SetGameBaseScore(LONG lBaseScore) {}

	//时间事件
	//virtual bool OnTimerTick(DWORD dwTimerID, WPARAM dwBindParameter) override { return true; }
	//动作事件
public:
	//用户坐下
	virtual bool OnActionUserSitDown(WORD wChairID, bool bLookonUser);
	//用户起来
	virtual bool OnActionUserStandUp(WORD wChairID, bool bLookonUser);
	//用户同意
	//virtual bool OnActionUserOnReady(WORD wChairID, IServerUserItem * pIServerUserItem, VOID * pData, WORD wDataSize)  override { return true; }
	//用户断线
	//virtual bool  OnActionUserOffLine(WORD wChairID, IServerUserItem * pIServerUserItem)  override;

	/// \brief	写库存数据到数据库
	///
	/// \author	lik
	/// \date	2016-05-11 20:15
	//virtual void SaveTableData();
	
	void	OnGameUpdate();
//protected:
	bool	OnTimeSync(CS_TimeSync* msg);
	//bool	OnChangeScore(void* pData, WORD wDataSize, IServerUserItem * pIServerUserItem);
	bool	OnChangeCannon(CS_ChangeCannon* msg);
	bool	OnFire(CS_Fire* msg);

	void	CatchFish(CBullet* pBullet, CFish* pFish, int nCatch, int* nCatched);

	void	SendCatchFish(CBullet* pBullet, CFish*pFish, LONGLONG score);

	void	DistrubFish(float fdt);

	void	ResetSceneDistrub();

	void	SendFish(CFish* pFish, WORD wChairID = INVALID_CHAIR);
	void	SendBullet(CBullet* pBullet, WORD wChairID = INVALID_CHAIR, bool bNew = false);

	void	SendSceneInfo(WORD wChairID);
	void	SendPlayerInfo(WORD wChairID);
	void	SendCannonSet(WORD wChairID);
	void	SendGameConfig(WORD wChairID);

	void	ReturnBulletScore(WORD wChairID);

	void	SendAllowFire(WORD wChairID);

	void	OnProduceFish(CMyEvent* pEvent);

	void	OnAddBuffer(CMyEvent* pEvent);

	void	OnAdwardEvent(CMyEvent* pEvent);

	void	OnCannonSetChange(CMyEvent* pEvent);

	void	OnCatchFishBroadCast(CMyEvent* pEvent);

	void	OnFirstFire(CMyEvent* pEvent);

	void	OnMulChange(CMyEvent* pEvent);

    void	LockFish(WORD wChairID);

	bool    OnLockFish(CS_LockFish* msg);

	bool	OnNetCast(CS_Netcast* msg);

	bool	OnChangeCannonSet(CS_ChangeCannonSet* msg);

	bool	HasRealPlayer();

	void	AddBuffer(int btp, float parm, float ft);

	int		CountPlayer();

	//void	RecordGameScore(IServerUserItem * pIServerUserItem, tagScoreInfo & ScoreInfo);

	//bool	ImitationRealPlayer(IServerUserItem* pUser);
	public:
	static void	LoadConfig();

	bool	OnTreasureEND(CS_TreasureEnd* msg);

	// 发送消息
	template<typename T> void send2client_pb(WORD wChairID, T* pb)
	{
		if (INVALID_CHAIR == wChairID)
		{
			broadcast2client_pb(pb);
			return;
		}

		if (wChairID >= m_player.size())
		{
			LOG_WARN("wChairID %d out of range[0,%d)", wChairID, m_player.size());
			return;
		}

		int guid = m_player[wChairID].get_guid();
		if (guid == 0)
		{
			LOG_WARN("wChairID %d guid=0", wChairID);
			return;
		}

		GameSessionManager::instance()->send2client_pb(guid, m_player[wChairID].get_gate_id(), pb);
	}

	template<typename T> void broadcast2client_pb(T* pb)
	{
		for (auto& player : m_player)
		{
			int guid = player.get_guid();
			if (guid != 0)
				GameSessionManager::instance()->send2client_pb(guid, player.get_gate_id(), pb);
		}
	}

	void set_guid_gateid(int chair_id, int guid, int gate_id);

	void set_nickname(int chair_id, const char* nickname);
	void set_table_id(int table_id) { m_table_id = table_id; }
	int get_table_id() { return m_table_id; }

protected:
	DWORD							m_dwLastTick;
	float							m_fSceneTime;
	int								m_nCurScene;
	MyObjMgr						m_FishManager;
	MyObjMgr						m_BulletManager;

	bool							m_bAllowFire;
	float							m_fPauseTime;
	std::vector<SYSTEMTIME>			m_SystemTimeStart;					//开始时间

	int								m_nSpecialCount;

	std::list<DWORD>				m_CanLockList;
	std::vector<float>				m_vDistrubFishTime;
	std::vector<RefershTroop>		m_vDistrubTroop;

	std::vector<MyPoint>			m_NearFishPos;

	int								m_nFishCount;


	SCORE							user_win_scores_[MAX_TABLE_CHAIR];// 用户的总输赢
	SCORE							user_revenues_[MAX_TABLE_CHAIR];// 用户的总抽税
	SCORE							user_score_pools_[MAX_TABLE_CHAIR];// 我们无故吃掉的用户分数

	bool							m_bRun;

	int								m_table_id;
};

//////////////////////////////////////////////////////////////////////////

#endif