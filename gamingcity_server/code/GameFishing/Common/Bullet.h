//
#ifndef __BULLET_H__
#define __BULLET_H__

#include "MyObject.h"
#include "Fish.h"
#include <map>

class CBullet : public MyObject
{
public:
	CBullet();
	virtual ~CBullet();

	void AddProbilitySet(int ftp, float pp);
	float GetProbilitySet(int ftp);

	void SetMaxCatch(int n){m_nMaxCatch = n;}
	int GetMaxCatch(){return m_nMaxCatch;}

	void SetCatchRadio(int n){m_nCatchRadio = n;}
	int	GetCatchRadio(){return m_nCatchRadio;}

	void SetCannonType(int n){m_nCannonType = n;}
	int GetCannonType(){return m_nCannonType;}

	void SetChairID(WORD id){m_wChairID = id;}
	WORD GetChairID(){return m_wChairID;}

	bool HitTest(CFish* pFish);

	bool NetCatch(CFish* pFish);

	void SetSize(int n){m_nSize = n;}
	int  GetSize(){return m_nSize;}

	virtual void OnUpdate(int msElapsed);

	bool	bDouble(){return m_bDouble;}
	void	setDouble(bool b){m_bDouble = b;}
// 	void SetInvincibility(bool b){m_bInvincibility = b;}

protected:
	std::map<int, float>	ProbabilitySet;
	int						m_nMaxCatch;
	int						m_nCatchRadio;
	int						m_nCannonType;
	WORD					m_wChairID;
	int						m_nSize;
	bool					m_bDouble;
// 	bool					m_bInvincibility;
};

#endif

