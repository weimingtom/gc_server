#include "GameGmManager.h"
#include "LuaScriptManager.h"
#include "BaseGameServer.h"
#include "GameLog.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG


GameGmManager::GameGmManager()
{
}

GameGmManager::~GameGmManager()
{
}

bool GameGmManager::gm_command(std::vector<std::string>& vc)
{
	std::string key = vc[0];
	if (key == "android") // 机器人相关命令
	{
		if (vc.size() == 4)
		{
			GmAndroidOpt* p = new GmAndroidOpt;

			std::string str = vc[1];
			if (str == "+a")
			{
				p->set_opt_type(GM_ANDROID_ADD_ACTIVE);
			}
			else if (str == "-a")
			{
				p->set_opt_type(GM_ANDROID_SUB_ACTIVE);
			}
			else if (str == "+p")
			{
				p->set_opt_type(GM_ANDROID_ADD_PASSIVE);
			}
			else if (str == "-p")
			{
				p->set_opt_type(GM_ANDROID_SUB_PASSIVE);
			}

			int id = atoi(vc[2].c_str()); 
			if (id > 0)
				p->set_room_id(id);

			int n = atoi(vc[3].c_str());
			if (n > 0)
				p->set_num(n);

			std::lock_guard<std::recursive_mutex> lock(mutex_);
			gm_list_.push_back(std::shared_ptr<GmBase>(p));
		}
		else
		{
			LOG_ERR("gm android param error");
		}
		return true;
	}

	return GmManager::gm_command(vc);
}

//---------------------------------------

void GmAndroidOpt::exe()
{
	auto L = LuaScriptManager::instance()->get_lua_state();

	lua_tinker::call<void>(L, "on_gm_android_opt", opt_type_, room_id_, num_);
}
