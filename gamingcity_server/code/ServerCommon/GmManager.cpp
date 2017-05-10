#include "GmManager.h"
#include "LuaScriptManager.h"
#include "GameLog.h"
#include "BaseServer.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG


GmManager::GmManager()
{
}

GmManager::~GmManager()
{
}

bool GmManager::gm_command(std::vector<std::string>& vc)
{
	std::string key = vc[0];
	if (key == "lua") // lua cmd
	{
		GmLuaCommand* p = new GmLuaCommand;
		if (vc.size() >= 2)
			p->set_command(vc[1]);
		else
			LOG_ERR("gm lua param error");

		std::lock_guard<std::recursive_mutex> lock(mutex_);
		gm_list_.push_back(std::shared_ptr<GmBase>(p));
	}
#ifdef _DEBUG
	else if (key == "rs") // reload script
	{
		GmReloadScript* p = new GmReloadScript;
		
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		gm_list_.push_back(std::shared_ptr<GmBase>(p));
	}
#endif // _DEBUG
	else
	{
		LOG_ERR("gm command error:%s", key.c_str());
		return false;
	}

	return true;
}

void GmManager::exe_gm_command()
{
	std::vector<std::shared_ptr<GmBase>> gms;
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		gms.swap(gm_list_);
	}

	for (auto& item : gms)
	{
		item->exe();
	}
}

//---------------------------------------

void GmReloadScript::exe()
{
	auto L = LuaScriptManager::instance()->get_lua_state();

	lua_tinker::call<void>(L, "reload_script");
	lua_tinker::dofile(L, BaseServer::instance()->main_lua_file());
	LOG_INFO("reload_script ok");
}

//---------------------------------------

void GmLuaCommand::exe()
{
	auto L = LuaScriptManager::instance()->get_lua_state();
	
	lua_tinker::dostring(L, cmd_.c_str());
}
