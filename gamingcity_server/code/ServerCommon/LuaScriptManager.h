#pragma once

#include "perinclude.h"
#include "Singleton.h"
#include "lua_tinker_ex.h"

class LuaScriptManager : public TSingleton<LuaScriptManager>
{
public:
	LuaScriptManager();

	virtual ~LuaScriptManager();

	virtual void init();

	void dofile(const char* filename);

	lua_State* get_lua_state() { return L; }

protected:
	void add_loader();

protected:
	lua_State* L;
};
