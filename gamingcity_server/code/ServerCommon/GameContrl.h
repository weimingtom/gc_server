#pragma once
#include <string>
#include "RedisConnectionThread.h"
using namespace std;
class GameContrl : public TSingleton<GameContrl>
{
public:
	GameContrl();
	~GameContrl();
	static void setGameTimes(const char * GameType, int playGuid, int otherGuid, bool master_flag);
	static bool judgePlayTimes(const char * GameType, int playGuid, int otherGuid, int times, bool master_flag);
	static void show(const char * GameType, int playGuid);
	static void IncPlayTimes(const char * GameType, int playGuid, bool master_flag);
	static int  getPlayTimes(const char * GameType, int playGuid, bool master_flag);
};
