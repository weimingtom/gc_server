#include "stdafx.h"
#include "CommonLogic.h"
#include "EffectManager.h"
#include "EffectFactory.h"
#include "MyObjectFactory.h"
#include "MyComponentFactory.h"
#include "MoveCompent.h"
#include "PathManager.h"
#include "BufferManager.h"

#define FORWARD 100

LONGLONG CommonLogic::GetFishEffect(CBullet* pBullet, CFish* pFish, std::list<MyObject*>& list, bool bPretreating)
{
	LONGLONG lScore = 0;
	if(pFish != NULL)
	{
		EffectMgr* pEM = (EffectMgr*)pFish->GetComponent(ECF_EFFECTMGR);
		if(pEM != NULL)
		{
			lScore = pEM->Execute(pBullet, list, bPretreating);
		}
	}
	return lScore;
}

CBullet* CommonLogic::CreateBullet(Bullet binf, const MyPoint& pos, float fDirection, int CannonType, int CannonMul, bool bForward)
{
	CBullet* pBullet = (CBullet*)CreateObject(EOT_BULLET);
	if(pBullet != NULL)
	{
		pBullet->SetScore(binf.nMulriple);
		pBullet->SetCannonType(CannonType);
		pBullet->SetCatchRadio(binf.nCatchRadio);
		pBullet->SetMaxCatch(binf.nMaxCatch);
		pBullet->SetTypeID(CannonMul);
		pBullet->SetSize(binf.nBulletSize);

		std::map<int, float>::iterator it = binf.ProbabilitySet.begin();
		while (it != binf.ProbabilitySet.end())
		{
			pBullet->AddProbilitySet(it->first, it->second);
			++it;
		}

		BufferMgr* pBM = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
		if(pBM != NULL)
			pBullet->SetComponent(pBM);

		MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
		if(pMove != NULL)
		{
			pMove->SetSpeed(binf.nSpeed);
			pMove->SetDirection(fDirection);
			pMove->SetPosition(pos);
			pMove->InitMove();
			pBullet->SetComponent(pMove);
			if(bForward)
			{
				pMove->OnUpdate(FORWARD*1000/binf.nSpeed * CGameConfig::GetInstance()->fHScale);
			}
		}
	}

	return pBullet;
}

CFish* CommonLogic::CreateFish(Fish& finf, float x, float y, float r, float d, int s, int p, bool bTroop, int ft)
{
	DWORD tt = timeGetTime();
	CFish* pFish = (CFish*)CreateObject(EOT_FISH);
	if(pFish != NULL)
	{
		pFish->SetTypeID(finf.nTypeID);
		pFish->SetFishType(ft);
		pFish->SetProbability(finf.fProbability);
		pFish->SetBoundingBox(finf.nBoundBox);
		pFish->SetLockLevel(finf.nLockLevel);
		pFish->SetBroadCast(finf.bBroadCast);
		pFish->SetName(finf.szName);
		if(ft != ESFT_NORMAL)
		{
			pFish->SetBroadCast(true);
			std::map<int, SpecialSet>* pMap = NULL;
			if(ft == ESFT_KINGANDQUAN || ft == ESFT_KING)
			{
				pMap = &(CGameConfig::GetInstance()->KingFishMap);
				TCHAR szName[256];
				_sntprintf_s(szName, _TRUNCATE, TEXT("%s鱼王"), finf.szName);
				pFish->SetName(szName);
			}
			else if(ft == ESFT_SANYUAN)
			{
				pMap = &(CGameConfig::GetInstance()->SanYuanFishMap);
				pFish->SetName(TEXT("大三元"));
			}
			else if(ft == ESFT_SIXI)
			{
				pMap = &(CGameConfig::GetInstance()->SiXiFishMap);
				pFish->SetName(TEXT("大四喜"));
			}

			if(pMap != NULL)
			{
				std::map<int, SpecialSet>::iterator ist = pMap->find(finf.nTypeID);
				if(ist != pMap->end())
				{
					SpecialSet& kks = ist->second;
				
					if(ft == ESFT_KINGANDQUAN || ft == ESFT_KING)
						pFish->SetProbability(ft == ESFT_KINGANDQUAN ? finf.fProbability / 5.0f : kks.fCatchProbability);
					else if(ft == ESFT_SANYUAN)
						pFish->SetProbability(finf.fProbability / 3.0f);
					else if(ft == ESFT_SIXI)
						pFish->SetProbability(finf.fProbability / 4.0f);

					pFish->SetLockLevel(kks.nLockLevel);

					if(ft == ESFT_KINGANDQUAN || ft == ESFT_SANYUAN || ft == ESFT_SIXI)
						pFish->SetBoundingBox(kks.nBoundingBox);
				}
			}
		}

		if(p >= 0)
		{
			MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_PATH);
			if(pMove != NULL)
			{
				pMove->SetOffest(MyPoint(x,y));
				pMove->SetDelay(d);
				pMove->SetPathID(p, bTroop);
				pMove->SetSpeed(s);
				pMove->InitMove();

				pFish->SetComponent(pMove);
			}
		}
		else 
		{
			MoveCompent* pMove = (MoveCompent*)CreateComponent(EMCT_DIRECTION);
			if(pMove != NULL)
			{
				pMove->SetPosition(x, y);
				pMove->SetDirection(r);
				pMove->SetDelay(d);
				pMove->SetRebound(p == -1);
				pMove->SetSpeed(s);
				pMove->SetPathID(p);
				pMove->InitMove();

				pFish->SetComponent(pMove);
			}
		}

		BufferMgr* pBM = (BufferMgr*)CreateComponent(EBCT_BUFFERMGR);
		if(pBM != NULL)
		{
			pFish->SetComponent(pBM);

			if(finf.BufferSet.size() > 0)
			{
				std::list<Buffer>::iterator ib = finf.BufferSet.begin();
				while(ib != finf.BufferSet.end())
				{
					pBM->Add(ib->nTypeID, ib->fParam, ib->fLife);

					++ib;
				}
			}
		}

		if(finf.EffectSet.size() > 0)
		{
			EffectMgr* pEmgre = (EffectMgr*)CreateComponent(EECT_MGR);
			if(pEmgre != NULL)
			{
				pFish->SetComponent(pEmgre);

				if(ft == ESFT_KINGANDQUAN || ft == ESFT_KING)
				{
					CEffect* pef = CreateEffect(ETP_KILL);
					if(pef != NULL)
					{
						pef->SetParam(0, 2);
						pef->SetParam(1, finf.nTypeID);

						std::map<int, SpecialSet>::iterator ist = CGameConfig::GetInstance()->KingFishMap.find(finf.nTypeID);
						if(ist != CGameConfig::GetInstance()->KingFishMap.end())
						{
							pef->SetParam(2, ist->second.nMaxScore);
						}
						pEmgre->Add(pef);
					}
					pef = CreateEffect(ETP_ADDMONEY);
					if(pef != NULL)
					{
						pef->SetParam(0, 1);
						pef->SetParam(1, 10);
						pEmgre->Add(pef);
					}

				}

				std::list<Effect>::iterator iet = finf.EffectSet.begin();
				while(iet != finf.EffectSet.end())
				{
					CEffect* pef = CreateEffect(iet->nTypeID);

					if(pef != NULL)
					{
						for(int i = 0; i < pef->GetParamSize(); ++i)
						{
							int nValue = 0;
							if(i < iet->nParam.size())
								nValue = iet->nParam[i];

							if(ft == ESFT_SANYUAN && i == 1)
								pef->SetParam(i, nValue * 3);
							else if(ft == ESFT_SIXI && i == 1)
								pef->SetParam(i, nValue * 4);
							else
								pef->SetParam(i, nValue);
						}

						pEmgre->Add(pef);
					}
					++iet;
				}

 				if(ft == ESFT_KINGANDQUAN)
 				{
 					CEffect* pef = CreateEffect(ETP_PRODUCE);
 					if(pef != NULL)
 					{
 						pef->SetParam(0, finf.nTypeID);
 						pef->SetParam(1, 3);
 						pef->SetParam(2, 30);
 						pef->SetParam(3, 1);
 						pEmgre->Add(pef);
 					}
 				}
			}
		}
	}

	tt = timeGetTime() - tt;

	return pFish;
}


const char* CommonLogic::ReplaceString(WORD wChairID, std::string& str)
{
	static char str1[64];
	if(str.find("%d") != -1)
	{
		//sprintf_s(str1, 64, str.c_str(), wChairID+1);
		_snprintf_s(str1, _TRUNCATE, str.c_str(), wChairID+1);
		
	}
	else 
	{
		return str.c_str();
	}

	return str1;
}

