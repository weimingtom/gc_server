#include "LuaScriptManager.h"
#include "GameTimeManager.h"
#include "RandomHelper.h"

class LuaGameTimer : public GameTimer
{
public:
	LuaGameTimer(float delay, int index)
		: GameTimer(delay)
		, index_(index)
	{

	}

	virtual ~LuaGameTimer()
	{
	}

protected:
	virtual void on_time(float delta)
	{
		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), "on_timer", index_, delta);
	}

private:
	int index_;
};

static void add_lua_timer(int index, float delay)
{
	GameTimeManager::instance()->add_timer(new LuaGameTimer(delay, index));
}

static int get_second_time()
{
	return (int)GameTimeManager::instance()->get_second_time();
}

static int cur_to_days()
{
	return GameTimeManager::instance()->to_days();
}

static int to_days(int t)
{
	return GameTimeManager::instance()->to_days(t);
}

static int get_random(int min, int max)
{
	return RandomHelper::Random(min,max);
}

static float get_random01()
{
	return RandomHelper::random_float(0,1.0f);
}

void bind_lua_game_timer(lua_State* L)
{
	lua_tinker::def(L, "add_lua_timer", add_lua_timer);
	lua_tinker::def(L, "get_second_time", get_second_time);
	lua_tinker::def(L, "cur_to_days", cur_to_days);
	lua_tinker::def(L, "to_days", to_days);

	lua_tinker::def(L, "boost_get_random", get_random);
	lua_tinker::def(L, "boost_get_random01", get_random01);
}
