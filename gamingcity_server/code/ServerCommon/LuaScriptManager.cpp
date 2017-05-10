#include "LuaScriptManager.h"
#include "lua_tinker.h"
#include "GameLog.h"
#include "lua_extensions.h"

LuaScriptManager::LuaScriptManager()
	: L(nullptr)
{
}

LuaScriptManager::~LuaScriptManager()
{
	if (L)
	{
		lua_close(L);
		L = nullptr;
	}
}

//extern "C"
//{
	int luaopen_protobuf_c(lua_State *L);
//}
void bind_lua_game_log(lua_State* L);
void bind_lua_game_timer(lua_State* L);
void LuaScriptManager::init()
{
	L = luaL_newstate();
	luaL_openlibs(L);
	luaopen_lua_extensions(L);

	//luaopen_protobuf_c(L); // lua 5.1
	luaL_requiref(L, "protobuf.c", luaopen_protobuf_c, 1);

	bind_lua_game_log(L);
	bind_lua_game_timer(L);

	add_loader();
}

void LuaScriptManager::dofile(const char* filename)
{
	lua_tinker::dofile(L, filename);
}

static int lua_load_file(lua_State* L)
{
    std::string module = lua_tostring(L, 1);
    if (module == "GameFishingDLL")
    {
        printf("module is GameFishingDLL");
        return 0;
    }

	
	std::string filename = "../script/" + module + ".lua";
	if (luaL_loadfile(L, filename.c_str()) != 0)
	{
		LOG_ERR("lua script error loading module %s from file %s:\n\t%s", lua_tostring(L, 1), module.c_str(), lua_tostring(L, -1));
		return 0;
	}
	
	return 1;
}

void LuaScriptManager::add_loader()
{
#if 0 // lua 5.1
	// stack content after the invoking of the function  
	// get loader table  
	lua_getglobal(L, "package");                                  /* L: package */
	lua_getfield(L, -1, "loaders");                               /* L: package, loaders */

	// insert loader into index 2  
	lua_pushcfunction(L, lua_load_file);                          /* L: package, loaders, func */
	for (int i = (int)(lua_objlen(L, -2) + 1); i > 2; --i)
	{
		lua_rawgeti(L, -2, i - 1);                                /* L: package, loaders, func, function */
		// we call lua_rawgeti, so the loader table now is at -3  
		lua_rawseti(L, -3, i);                                    /* L: package, loaders, func */
	}
	lua_rawseti(L, -2, 2);                                        /* L: package, loaders */

	// set loaders into package  
	lua_setfield(L, -2, "loaders");                               /* L: package */

	lua_pop(L, 1);
#endif
	// stack content after the invoking of the function  
	// get loader table  
	lua_getglobal(L, "package");                                  /* L: package */
	lua_getfield(L, -1, "searchers");                               /* L: package, loaders */

	// insert loader into index 2  
	lua_pushcfunction(L, lua_load_file);                          /* L: package, loaders, func */
	for (int i = (int)(lua_rawlen(L, -2) + 1); i > 2; --i)
	{
		lua_rawgeti(L, -2, i - 1);                                /* L: package, loaders, func, function */
		// we call lua_rawgeti, so the loader table now is at -3  
		lua_rawseti(L, -3, i);                                    /* L: package, loaders, func */
	}
	lua_rawseti(L, -2, 2);                                        /* L: package, loaders */

	// set loaders into package  
	lua_setfield(L, -2, "searchers");                               /* L: package */

	lua_pop(L, 1);
}
