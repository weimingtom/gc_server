// GameServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"

#include "GameServer.h"
#include <google/protobuf/text_format.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

GameServer::GameServer()
{
}

GameServer::~GameServer()
{
}

/*const char* GameServer::log_file_name()
{
	return "../log/%d-%d-%d game.log";
	//return GameServerConfigManager::instance()->get_game_log();
}*/

const wchar_t* GameServer::dump_file_name()
{
	return L"GameServer_%d-%02d-%02d_%02d-%02d-%02d.dmp";
}

const char* GameServer::main_lua_file()
{
	return "../script/game/main.lua";
}


//////////////////////////////////////////////////////////////////////////

int main(int argc, char* argv[])
{
#ifdef PLATFORM_WINDOWS
	_CrtSetDbgFlag(_CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF);
#endif

#ifndef _DEBUG
	DeleteMenu(GetSystemMenu(GetConsoleWindow(), FALSE), SC_CLOSE, MF_BYCOMMAND);
	DrawMenuBar(GetConsoleWindow());
#endif

	std::string game_name = "land";
	std::string title = "game";

	GameServer theServer;
	if (argc > 1)
	{
		if (argc > 2)
		{
			game_name = argv[2];
			theServer.set_game_name(game_name);
		}
		theServer.set_game_id(atoi(argv[1]));
	
		title = str(boost::format("%s%d") % game_name % theServer.get_game_id());
	}

	/*for (int i = 1; i < argc; i++)
	{
		if (strcmp(argv[i], "-db") == 0)
			theServer.set_using_db_config(true);
		else
			GameServerConfigManager::instance()->set_cfg_file_name(argv[i]);
	}*/
	
	//std::string title = GameServerConfigManager::instance()->get_title();
	theServer.set_print_filename(title);

	//if (theServer.get_using_db_config())
	//	title += "-db";

#ifdef PLATFORM_WINDOWS
	SetConsoleTitleA(title.c_str());
#endif

	theServer.startup();

#ifdef _DEBUG
	system("pause");
#endif // _DEBUG

	return 0;
}
