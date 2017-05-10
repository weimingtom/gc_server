////
#ifndef __EVENT_MGR_H__
#define __EVENT_MGR_H__

#include "TSingleton.h"
#include "Callback.h"
#include "Event.h"
#include <algorithm>
#include <list>
#include <map>

class CEventMgr: public Singleton<CEventMgr>
{
protected:
	CEventMgr();
	~CEventMgr();

	FriendBaseSingleton(CEventMgr);

protected:
	typedef std::list< TemplateCallback< CMyEvent* >* >	list_handler_t;
	typedef std::map< EventID, list_handler_t > map_handler_t;

	map_handler_t mapHandler_;
	bool bEnabled_;

public:
	void RegisterEvent(const EventID& id, TemplateCallback< CMyEvent* > *handler);
	void UnregisterEvent(const EventID& id, TemplateCallback< CMyEvent* > *handler);
	void ProcessEvent(CMyEvent* pEvent);
	//此输入事件将在下一个循环被处理,然后被删除
	void PostEvent(CMyEvent* &pEvent);

	void RaiseEvent(const EventID& szEventName);

	void Enable(bool bEnabled);

	void Update(int ms);

protected:
	std::list< CMyEvent* > m_listEvent;
};

#define Register_Event_Handler( event_, func_)	{CEventMgr::GetInstance()->RegisterEvent( (event_),  (func_));}
#define Bind_Event_Handler(event_, module_, func_)	{CEventMgr::GetInstance()->RegisterEvent( (event_), new TemplateMemFunc< module_, CMyEvent* > (this, &module_::func_));}


inline void RaiseEvent(const EventID& i_strEventName,void* i_pParam = NULL,void* i_pSource = NULL,void* i_pTarget = NULL)
{
	CMyEvent ie;
	ie.SetName(i_strEventName);
	ie.SetParam(i_pParam);
	ie.SetSource(i_pSource);
	ie.SetTarget(i_pTarget);
	CEventMgr::GetInstance()->ProcessEvent(&ie);
}

inline void PostEvent(const EventID& strEventName, void *pParam = 0, void* pSource = 0, void* pTarget = 0)
{
	CMyEvent* pEvent = new CMyEvent;
	pEvent->SetName(strEventName);
	pEvent->SetParam(pParam);
	pEvent->SetSource(pSource);
	pEvent->SetTarget(pTarget);
	CEventMgr::GetInstance()->PostEvent(pEvent);
}

#endif//__EVENT_MGR_H__
