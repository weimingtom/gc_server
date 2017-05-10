#include "EffectManager.h"
#include "EffectFactory.h"
#include "MyObject.h"

EffectMgr::EffectMgr()
{

}

EffectMgr::~EffectMgr()
{
	Clear();
}

void EffectMgr::Add(CEffect* pObj)
{
	if(pObj != NULL)
		m_effects.push_back(pObj);
}

void EffectMgr::Clear()
{
	obj_table_iter it = m_effects.begin();
	while(it != m_effects.end())
	{
		EffectFactory::GetInstance()->Recovery((*it)->GetEffectType(), *it);
		++it;
	}
	m_effects.clear();
}

LONGLONG EffectMgr::Execute(MyObject* pTarget, std::list<MyObject*>& list, bool bPretreating)
{
	LONGLONG Score = 0;
	MyObject* pOwner = GetOwner();
    // 可优 也可以不优，外围传入都是空list 此循环用处不明防嵌套？
	std::list<MyObject*>::iterator io = list.begin();
	while(io != list.end())
	{
		if(pOwner == *io)
			return Score;
		++io;
	}
	//只要还没死亡，就执行
	if(pOwner->GetState() < EOS_DEAD)
	{
		list.push_back(pOwner);
		obj_table_iter it = m_effects.begin();
		while(it != m_effects.end())
		{
			CEffect* eff = *it;
			Score += eff->Execute(pOwner, pTarget, list, bPretreating);
			++it;
		}
	}

	return Score;
}
