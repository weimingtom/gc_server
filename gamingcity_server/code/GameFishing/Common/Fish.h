//
#ifndef __FISH_H__
#define __FISH_H__

#include "MyObject.h"
#include <tchar.h>

class CFish : public MyObject
{
public:
	CFish();
	virtual ~CFish();

	void SetBroadCast(bool bbc){m_bBroadCast = bbc;}
	bool BroadCast(){return m_bBroadCast;}

	void SetBoundingBox(int n){m_nBoundingBoxID = n;}
	int	GetBoundingBoxID(){return m_nBoundingBoxID;}

	int GetLockLevel(){return m_nLockLevel;}
	void SetLockLevel(int n){m_nLockLevel = n;}


#if _MSC_VER>1400
	void SetName(const TCHAR*  sn){_sntprintf_s(m_szName,_TRUNCATE, TEXT("%s"), sn);}
#else
	void SetName(const TCHAR*  sn){_sntprintf(m_szName, CountArray(m_szName), TEXT("%s"), sn);}
#endif
	
	TCHAR* GetName(){return m_szName;}

	void SetFishType(int type){m_FishType = type;}
	int GetFishType(){return m_FishType;}

	void SetRefershID(DWORD id){m_nRefershID = id;}
	DWORD GetRefershID(){return m_nRefershID;}

protected:
	bool			m_bBroadCast;
	int				m_nBoundingBoxID;
	int				m_nLockLevel;
	TCHAR			m_szName[256];
	int				m_FishType;
	DWORD			m_nRefershID;
};

#endif



