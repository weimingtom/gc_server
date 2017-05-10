// GameFishing.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include "GameFishing.h"
#include <google/protobuf/text_format.h>
#include "FishingGameSessionManager.h"
#include "GameFishingLuaScriptManager.h"

#include "TableframeSink.h"
#include "MyObjectFactory.h"
#include "MyComponentFactory.h"
#include "EffectFactory.h"
#include "EffectManager.h"
#include "BufferFactory.h"
#include "BufferManager.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

GameFishing::GameFishing()
{
}

GameFishing::~GameFishing()
{
}

bool GameFishing::init()
{
	if (!BaseGameServer::init())
		return false;

	table_manager_ = std::move(std::unique_ptr<TableManager>(new TableManager));

	REGISTER_OBJ_TYPE(EOT_PLAYER, CPlayer);
	REGISTER_OBJ_TYPE(EOT_BULLET, CBullet);
	REGISTER_OBJ_TYPE(EOT_FISH, CFish);

	REGISTER_EFFECT_TYPE(ETP_ADDMONEY, CEffectAddMoney);
	REGISTER_EFFECT_TYPE(ETP_KILL, CEffectKill);
	REGISTER_EFFECT_TYPE(ETP_ADDBUFFER, CEffectAddBuffer);
	REGISTER_EFFECT_TYPE(ETP_PRODUCE, CEffectProduce);
	REGISTER_EFFECT_TYPE(ETP_BLACKWATER, CEffectBlackWater);
	REGISTER_EFFECT_TYPE(ETP_AWARD, CEffectAward);

	REGISTER_BUFFER_TYPE(EBT_CHANGESPEED, CSpeedBuffer);
	REGISTER_BUFFER_TYPE(EBT_DOUBLE_CANNON, CDoubleCannon);
	REGISTER_BUFFER_TYPE(EBT_ION_CANNON, CIonCannon);
	REGISTER_BUFFER_TYPE(EBT_ADDMUL_BYHIT, CAddMulByHit);

	REGISTER_MYCOMPONENT_TYPE(EMCT_PATH, MoveByPath);
	REGISTER_MYCOMPONENT_TYPE(EMCT_DIRECTION, MoveByDirection);

	REGISTER_MYCOMPONENT_TYPE(EECT_MGR, EffectMgr);
	REGISTER_MYCOMPONENT_TYPE(EBCT_BUFFERMGR, BufferMgr);

	return true;
}

void GameFishing::release()
{
	table_manager_.reset();

	BaseGameServer::release();
}


const char* GameFishing::log_file_name()
{
	return "../log/%d-%d-%d game fishing.log";
}

/*const char* GameFishing::cfg_file_name()
{
	if (cfg_file_name_.empty())
		return "../config/GameFishingConfig.pb";
	return cfg_file_name_.c_str();
}*/

const wchar_t* GameFishing::dump_file_name()
{
	return L"GameFishing_%d-%02d-%02d_%02d-%02d-%02d.dmp";
}

const char* GameFishing::main_lua_file()
{
	//return "../script/fishing/main.lua";
	return "../script/game/main.lua";
}

GameSessionManager* GameFishing::new_session_manager()
{
	return new FishingGameSessionManager;
}

BaseGameLuaScriptManager* GameFishing::new_lua_script_manager()
{
	return new GameFishingLuaScriptManager;
}

void GameFishing::on_tick()
{
	TableManager::instance()->update();
}


//////////////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);

	GameFishing theServer;
	//if (argc > 1)
	//	GameServerConfigManager::instance()->set_cfg_file_name(argv[1]);
	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}

