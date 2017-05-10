//
#ifndef __BUFFER_H__
#define __BUFFER_H__

#include <WTypes.h>
#include "MyObject.h"

class CComEvent;

enum BUFFER_TYPE
{
	EBT_NONE = 0,
	EBT_CHANGESPEED,		//改变速度
	EBT_DOUBLE_CANNON,		//双倍炮
	EBT_ION_CANNON,			//离子炮
	EBT_ADDMUL_BYHIT,		//被击吃子弹
};

class CBuffer
{
public:
	CBuffer();
	virtual ~CBuffer();

	BUFFER_TYPE GetType(){return m_BTP;}
	void SetType(BUFFER_TYPE b){m_BTP = b;}

	float GetLife(){return m_fLife;}
	void SetLife(float f){m_fLife = f;}

	virtual bool OnUpdate(int ms);

	virtual void OnCCEvent(CComEvent*) = NULL;

	void SetParam(float p){m_param = p;}

	virtual void Clear(){}

	virtual void SetOwner(MyObject* pobj){m_pOwner = pobj;}

protected:
	BUFFER_TYPE		m_BTP;
	float			m_fLife;
	MyObject*		m_pOwner;
	float			m_param;
};

class CSpeedBuffer : public CBuffer
{
public:
	CSpeedBuffer();
	virtual ~CSpeedBuffer();
	
	virtual void OnCCEvent(CComEvent*);

	virtual void Clear();
};

class CDoubleCannon : public CBuffer
{
public:
	CDoubleCannon();
	
	virtual ~CDoubleCannon();
	
	virtual void Clear();

	virtual void OnCCEvent(CComEvent*);

	virtual void SetOwner(MyObject* pobj);
};

class CIonCannon : public CBuffer
{
public:
	CIonCannon();

	virtual ~CIonCannon();

	virtual void Clear();

	virtual void OnCCEvent(CComEvent*);

	virtual void SetOwner(MyObject* pobj);
};

class CAddMulByHit : public CBuffer
{
public:
	int			nCurMul;

	CAddMulByHit();

	virtual ~CAddMulByHit();

	virtual void Clear();

	virtual void OnCCEvent(CComEvent*);

	virtual void SetOwner(MyObject* pobj);
};

#endif

