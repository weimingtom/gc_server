//
#ifndef _MY_OBJECT_H_
#define _MY_OBJECT_H_

#include <set>
#include <list>
#include <map>
#include <memory>
#include <string.h>
#include <Windows.h>
#include "Size.h"
#include "Point.h"

class MyComponent;
class CComEvent;
class MyObjMgr;

enum ObjectType
{
	EOT_NONE = 0,
	EOT_PLAYER,
	EOT_BULLET,
	EOT_FISH,
};

enum ObjState
{
	EOS_LIVE = 0,
	EOS_HIT,
	EOS_DEAD,
	EOS_DESTORY,
	EOS_LIGHTING,
};

enum MyEvent
{
	EME_STATE_CHANGED = 0,		//状态变化
	EME_QUERY_SPEED_MUL,		//查询速度倍率
	EME_QUERY_ADDMUL,			//查询额外增加的倍率
};

class MyObject
{
public:
	MyObject();
	virtual ~MyObject();

public:
	//设置和获取Id
	DWORD GetId()const{return id_;};
	void SetId(DWORD newId){id_ = newId;};

	int GetObjType()const{return objType_;}
	void SetObjType(int objType){objType_ = objType;}

	//响应时间流逝
	virtual void OnUpdate(int msElapsed);

	void SetMgr(MyObjMgr* mgr){m_Mgr = mgr;}
	MyObjMgr* GetMgr(){return m_Mgr;}

	MyPoint GetPosition();

	float GetDirection();
	
	/// \brief	当前对象的分数
	///
	/// \author	lik
	/// \date	2016-05-12 22:18
	///
	/// \return	The score.
	LONGLONG GetScore(){return m_Score;}
	void SetScore(LONGLONG sc){m_Score = sc;}
	void AddScore(LONGLONG sc){m_Score += sc;}

	float	GetProbability(){return m_fProbability;}
	void SetProbability(float f){m_fProbability = f;}

	DWORD GetCreateTick(){return m_dwCreateTick;}
	void SetCreateTick(DWORD tk){m_dwCreateTick = tk;}

	bool InSideScreen();

protected:
	MyObjMgr* m_Mgr;
	DWORD id_;
	int objType_;

	friend class ClientObjectFactory;

protected:
	typedef std::map< const UINT32, MyComponent* >	Component_Table_t;
	typedef std::list< CComEvent* > CCEvent_Queue_t;

	Component_Table_t components_;
	CCEvent_Queue_t ccevent_queue_;
	
	LONGLONG m_Score;

	float		m_fProbability;

	DWORD	m_dwCreateTick;

	int	m_nState;

public:
	void ProcessCCEvent(CComEvent*);//即时处理的事件
	void ProcessCCEvent(UINT32 idEvent, INT64 nParam1 = 0, void* pParam2 = 0);

	void PushCCEvent(std::auto_ptr<CComEvent>& evnt);//延迟处理的事件
	void PushCCEvent(UINT32 idEvent, INT64 nParam1 = 0, void* pParam2 = 0);

	MyComponent* GetComponent(const UINT32& familyID);
	void SetComponent( MyComponent* newComponent);

	bool DelComponent(const UINT32& familyID);//删除指定组件，如果找到并成功删除则返回ｔｒｕｅ，找不到则返回ｆａｌｓｅ
	void ClearComponent();

	void SetState(int st, MyObject* pobj = NULL);
	int GetState();

	void SetTypeID(int n){m_nTypeID = n;}
	int GetTypeID(){return m_nTypeID;}

protected:
	int			m_nTypeID;

};



#endif


