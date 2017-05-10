#include "stdafx.h"
#include "MoveCompent.h"
#include "MathAide.h"
#include "PathManager.h"
//#include "../消息定义/CMD_Fish.h"
#include "MyObject.h"
#include "GameConfig.h"
#include <math.h>

MoveCompent::MoveCompent()
:m_bPause(false)
,m_fSpeed(1.0f)
,m_nPathID(0)
,m_bEndPath(false)
,m_fDelay(0.0f)
,m_bBeginMove(false)
,m_bRebound(true)
,m_dwTargetID(0)
,m_pObjMgr(NULL)
,m_bTroop(false)
{
	SetPosition(-5000, -5000);
}

void MoveCompent::OnDetach()
{
	m_bPause = false;
	m_fSpeed = 1.0f;
	m_nPathID = 0;
	m_bEndPath = false;
	m_fDelay = 0.0f;
	m_bBeginMove = false;
	m_bRebound = true;
	m_dwTargetID = 0;
	m_pObjMgr = NULL;
	SetPosition(-5000, -5000);
}

void MoveCompent::OnCCEvent(CComEvent* pEvent)
{
	if(pEvent != NULL)
	{
		switch(pEvent->GetID())
		{
		case EME_STATE_CHANGED:
			{
				if(pEvent->GetParam1() >= EOS_DEAD)
				{
					SetPause(true);
				}
				break;
			}
		}
	}
}

void MoveByPath::InitMove()
{
	MovePoints* pPath = PathManager::GetInstance()->GetPathData(GetPathID(), bTroop());
	if(pPath != NULL)
	{
		m_fDuration = pPath->size();
	}

	m_Elaspe = 0.0f;
	m_bEndPath = false;
}

void MoveByPath::OnUpdate(int ms)
{
 	if(m_bPause || m_bEndPath) return;

	MovePoints* pPath = PathManager::GetInstance()->GetPathData(GetPathID(), bTroop());
	if(pPath == NULL) return;

	if(ms < 0) ms = 1000/GAME_FPS;

	float fdt =  ms / 1000.0f;
	MyObject* pOwner = GetOwner();
	if(pOwner != NULL)
	{
		CComEvent se;
		se.SetID(EME_QUERY_SPEED_MUL);
		se.SetParam1(0);
		se.SetParam2(&fdt);

		pOwner->ProcessCCEvent(&se);
	}

	if(m_fDelay > 0)
	{
		m_fDelay -= fdt;
		return;
	}

	if(m_bBeginMove == false && m_Elaspe > 0)
	{
		m_bBeginMove = true;
	}
	m_Elaspe += fdt * GetSpeed();

	CMovePoint mp(MyPoint(-5000, -5000), 0.0f);
	float time = min(1.0f, (m_Elaspe / m_fDuration));
	float fDiff;
	float fIndex = time * pPath->size();
	int index = fIndex;
	fDiff = fIndex - index;

	if (index >= pPath->size())
	{
		index = pPath->size() - 1;
	}
	else if(index < 0 || fDiff < 0)
	{
		index = 0;
		fDiff = 0;
	}

	if (index<pPath->size()-1)
	{
		CMovePoint move_point1 = pPath->at(index);
		CMovePoint move_point2 = pPath->at(index+1);

		mp.m_Position = move_point1.m_Position*(1.0-fDiff)+ move_point2.m_Position*fDiff;
		mp.m_Direction = move_point1.m_Direction*(1.0-fDiff)+ move_point2.m_Direction*fDiff;

		if (std::abs(move_point1.m_Direction-move_point2.m_Direction) > M_PI)
		{
			mp.m_Direction = move_point1.m_Direction;
		}
	}
	else
	{
		mp = pPath->at(index);
		m_bEndPath = true;
	}

 	SetPosition(mp.m_Position + m_Offest);
 	SetDirection(mp.m_Direction);
}

void MoveByDirection::OnUpdate(int ms)
{
	if(m_bPause || m_bEndPath) return;

	if(ms < 0) ms = 1000/GAME_FPS;

	if(m_pObjMgr != NULL && m_dwTargetID != 0)
	{
		MyObject* pObj = m_pObjMgr->Find(m_dwTargetID);
		if(pObj != NULL && pObj->GetState() < EOS_DEAD && pObj->InSideScreen())
		{
			if(CMathAide::CalcDistance(pObj->GetPosition().x_, pObj->GetPosition().y_, GetPostion().x_, GetPostion().y_) > 10)
			{
				SetDirection(CMathAide::CalcAngle(pObj->GetPosition().x_, pObj->GetPosition().y_, GetPostion().x_, GetPostion().y_));
				InitMove();
			}
			else
			{
				SetPosition(pObj->GetPosition());
				SetDirection(pObj->GetDirection());
				return;
			}
		}
		else
		{
			m_dwTargetID = 0;
		}
	}

	float fdt =  ms / 1000.0f;
	MyObject* pOwner = GetOwner();
	if(pOwner != NULL)
	{
		CComEvent se;
		se.SetID(EME_QUERY_SPEED_MUL);
		se.SetParam1(0);
		se.SetParam2(&fdt);

		pOwner->ProcessCCEvent(&se);
	}

	if(m_fDelay > 0)
	{
		m_fDelay -= fdt;
		return;
	}

	if(m_bBeginMove == false)
	{
		m_bBeginMove = true;
	}

	MyPoint pt(GetPostion());

	pt.x_ += m_fSpeed* dx_ * fdt;
	pt.y_ += m_fSpeed* dy_ * fdt;

	float fWidth = CGameConfig::GetInstance()->nDefaultWidth;
	float fHeigth = CGameConfig::GetInstance()->nDefaultHeight;

	if(Rebound())
	{
		if (pt.x_ < 0.0f) { pt.x_ = 0 + (0 - pt.x_); dx_ = -dx_; angle_ =  - angle_; }
		if (pt.x_ > fWidth)  {pt.x_ = fWidth - (pt.x_ - fWidth); dx_ = -dx_; angle_ =  - angle_;}

		if (pt.y_ < 0.0f) { pt.y_ = 0 + (0 - pt.y_); dy_ = -dy_; angle_ = M_PI - angle_;}
		if (pt.y_ > fHeigth)  {pt.y_ = fHeigth - (pt.y_ - fHeigth); dy_ = -dy_; angle_ = M_PI - angle_;}
	}
	else
	{
		if(pt.x_ < 0 || pt.x_ > fWidth || pt.y_ < 0 || pt.y_ > fHeigth)
			m_bEndPath = true;
	}

	if(pOwner != NULL)
	{
		SetDirection(pOwner->GetObjType() == EOT_FISH ? angle_ - M_PI_2 : angle_);
	}
	SetPosition(pt);
}

void MoveByDirection::InitMove()
{
	angle_ = GetDirection();
	dx_ = cosf(angle_ - M_PI_2);
	dy_ = sinf(angle_ - M_PI_2);
	m_bEndPath = false;
}





