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

	void SetCannonType(int n){m_nCannonType = n;}
	int GetCannonType(){return m_nCannonType;}

	void AddWastage(LONGLONG s){m_Wastage += s;}
	LONGLONG GetWastage(){return m_Wastage;}

	void SetMultiply(int n){m_nMultiply = n;}
	int GetMultiply(){return m_nMultiply;}

	void SetCannonPos(MyPoint& pt){m_CannonPos = pt;}
	const MyPoint& GetCannonPos(){return m_CannonPos;}

	void SetLastFireTick(DWORD dw){m_dwLastFireTick = dw;}
	DWORD GetLastFireTick(){return m_dwLastFireTick;}

	void SetLockFishID(DWORD id);
	DWORD GetLockFishID(){return m_dwLockFishID;}

	bool HasLocked(DWORD id);
	void ClearLockedBuffer(){LockBuffer.clear();}

	bool bLocking(){return m_bLocking;}
	void SetLocking(bool b){m_bLocking = b;}

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
	int					m_nCannonType;
	int					m_nMultiply;
	MyPoint				m_CannonPos;

	DWORD				m_dwLastFireTick;

	DWORD				m_dwLockFishID;
	bool				m_bLocking;
	std::list<DWORD>	LockBuffer;

	int					BulletCount;

	bool				bFired;

	bool				m_bCanFire;

	int					m_nCannonSetType;

	// 发送消息相关
	int					guid_;
	int					gate_id_;
	int					chair_id_;
	std::string			nickname_;
};

#endif

