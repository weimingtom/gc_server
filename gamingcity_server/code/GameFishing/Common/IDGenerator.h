////
#ifndef __IDGENERATOR_H__
#define __IDGENERATOR_H__

#include "TSingleton.h"
#include <Windows.h>

class IDGenerator : public Singleton< IDGenerator >
{
public:
	DWORD GetID64();

	void SetSeed(DWORD seed){id64_ = seed;}

protected:
	IDGenerator();
	virtual ~IDGenerator(){};
	FriendBaseSingleton(IDGenerator);

private:
	DWORD id64_;
};


#endif//__IDGENERATOR_H__
