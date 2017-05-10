#pragma once

#include "LuaScriptManager.h"

class BaseGameLuaScriptManager : public LuaScriptManager
{
public:
	BaseGameLuaScriptManager();

	virtual ~BaseGameLuaScriptManager();

	virtual void init();

protected:
private:
};
