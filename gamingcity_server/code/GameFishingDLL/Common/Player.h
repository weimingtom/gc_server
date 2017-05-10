//
#ifndef __PLAYER_H__
#define __PLAYER_H__

#include "Point.h"
#include "MyObject.h"

class CPlayer : public MyObject
{
public:
	CPlayer();
	virtual ~CPlayer();

	void ClearSet(int chairid);
	//设置大炮
	void SetCannonType(int n){m_nCannonType = n;}
	int GetCannonType(){return m_nCannonType;}
	//增加消耗
	void AddWastage(LONGLONG s){m_Wastage += s;}
	LONGLONG GetWastage(){return m_Wastage;}

	void SetMultiply(int n){m_nMultiply = n;}
    //获取子弹类型
	int GetMultiply(){return m_nMultiply;}
	//大炮坐标
	void SetCannonPos(MyPoint& pt){m_CannonPos = pt;}
	const MyPoint& GetCannonPos(){return m_CannonPos;}
	//最后一次开火坐标
	void SetLastFireTick(DWORD dw){m_dwLastFireTick = dw;}
	DWORD GetLastFireTick(){return m_dwLastFireTick;}
	//锁定鱼
	void SetLockFishID(DWORD id);
	DWORD GetLockFishID(){return m_dwLockFishID;}

	bool HasLocked(DWORD id);
	void ClearLockedBuffer(){LockBuffer.clear();}

	bool bLocking(){return m_bLocking;}
	void SetLocking(bool b){m_bLocking = b;}
	//增加子弹
	void ADDBulletCount(int n){BulletCount += n;}
	void ClearBulletCount(){BulletCount = 0;}
	int GetBulletCount(){return BulletCount;}

	void SetFired();

	int	GetCannonSetType(){return m_nCannonSetType;}
	void SetCannonSetType(int n){m_nCannonSetType = n;}
	
	void CacluteCannonPos(WORD wChairID);

	bool	CanFire(){return m_bCanFire;}
	void	SetCanFire(bool b = true){m_bCanFire = b;}

public:
	void set_guid_gateid(int guid, int gate_id);
	int get_guid() { return guid_; }
	int get_gate_id() { return gate_id_; }

	void set_chair_id(int chair_id) { chair_id_ = chair_id; }
	int get_chair_id() { return chair_id_; }

	void set_nickname(const std::string& nickname) { nickname_ = nickname; }
	const std::string& get_nickname() { return nickname_; }

protected:
	LONGLONG			m_Wastage;		//损耗
	int					m_nCannonType;  //大炮类型
	int					m_nMultiply;    //子弹类型？   子弹类型是否多余 可优
	MyPoint				m_CannonPos;    //大炮坐标

	DWORD				m_dwLastFireTick;   //最后一次开火坐标

	DWORD				m_dwLockFishID;     //锁定鱼ID
	bool				m_bLocking;         //是否锁定
	std::list<DWORD>	LockBuffer;         //buff列表

	int					BulletCount;         //子弹数量

	bool				bFired;				//是否开火中

	bool				m_bCanFire;			//	是否可以开火

	int					m_nCannonSetType;    //大炮集类型

	// 发送消息相关
	int					guid_;
	int					gate_id_;
	int					chair_id_;
	std::string			nickname_;
};

#endif

