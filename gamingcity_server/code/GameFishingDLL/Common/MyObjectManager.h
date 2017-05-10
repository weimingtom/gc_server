////
#ifndef __MyObjMgr_h__
#define __MyObjMgr_h__

#include "MyObject.h"
#include <list>
#include <mutex>

typedef std::map< DWORD, MyObject* > obj_table_t;
typedef obj_table_t::iterator obj_table_iter;

class MyObjMgr
{
public:
	MyObject* Find(DWORD nID);

	void Add(MyObject* pObj);//添加一个角色到列表
	void Remove(MyObject* pObj);
	void Remove(DWORD nID);

	void OnUpdate(UINT32);

	obj_table_iter Begin();
	obj_table_iter End();

	void Clear();//清除所有角色

	int CountObject();//统计角色数量

	MyObjMgr();
	~MyObjMgr();
public:// add lee 2016.04.01
	void Lock(void);
	void Unlock(void);
protected:
	obj_table_t m_mapObject;

	std::recursive_mutex m_lock;// add lee 2016.04.01
};

#endif//__MyObjMgr_h__
