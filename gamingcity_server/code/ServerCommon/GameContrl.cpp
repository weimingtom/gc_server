#include "GameContrl.h"

GameContrl::GameContrl()
{
}

GameContrl::~GameContrl()
{
}
//ip_contrl+guid+first_game_type second_game_type otherguid playerTimes  自己的ip+游戏类型 与 对手的id  场次
void GameContrl::setGameTimes(const char * GameType, int playGuid, int otherGuid, bool master_flag){
	string strCmd = boost::str(boost::format("hset ip_contrl%1%_%2% %3% %4%") % playGuid % GameType % otherGuid % getPlayTimes(GameType , playGuid, master_flag));
	RedisConnectionThread::instance()->command_do(strCmd.c_str(), master_flag);
	//更新时间 expire 一天后删除ip设置
	strCmd = boost::str(boost::format("expire ip_contrl%1%_%2% %3%") % playGuid % GameType % (24 * 3600));
	RedisConnectionThread::instance()->command_do(strCmd.c_str(), master_flag);
}
bool GameContrl::judgePlayTimes(const char * GameType, int playGuid, int otherGuid, int times, bool master_flag){
	string strCmd = boost::str(boost::format("hkeys ip_contrl%1%_%2%") % playGuid % GameType);
	RedisReply redisT(RedisConnectionThread::instance()->command_do(strCmd.c_str(), true));
	if (redisT.is_array()){
		std::map<string, string> m_map;
		for (int i = 0; i < redisT.size_element(); i++){
			if (redisT.get_element(i)->is_string()){
				string key = redisT.get_element(i)->get_string();
				RedisReply redisR(RedisConnectionThread::instance()->command_do(boost::str(boost::format("hget ip_contrl%1%_%2% %3%") % playGuid % GameType % key).c_str(), true));
				if (redisR.is_string()){
					string strData = redisR.get_string();
					m_map[key] = strData;
				}
			}
		}
		string strKey = boost::lexical_cast<string>(otherGuid);
		auto atorData = m_map.find(strKey);
		if (atorData != m_map.end()){
			//有记录
			int PlayTimes = GameContrl::getPlayTimes(GameType, playGuid, master_flag);
			int tPlayTimes = boost::lexical_cast<int>(atorData->second);
			if (PlayTimes - tPlayTimes > times){
				return true;
			}
			else{
				return false;
			}
		}
	}
	return true;
}
void GameContrl::show(const char * GameType, int playGuid){
	string strCmd = boost::str(boost::format("hkeys ip_contrl%1%_%2%") % playGuid % GameType);
	RedisReply redisT(RedisConnectionThread::instance()->command_do(strCmd.c_str(), true));
	if (redisT.is_array()){
		std::map<string, string> m_map;
		for (int i = 0; i < redisT.size_element(); i++){
			if (redisT.get_element(i)->is_string()){
				string key = redisT.get_element(i)->get_string();
				RedisReply redisR(RedisConnectionThread::instance()->command_do(boost::str(boost::format("hget ip_contrl%1%_%2% %3%") % playGuid % GameType % key).c_str(), true));
				if (redisR.is_string()){
					string strData = redisR.get_string();
					m_map[key] = strData;
				}
			}
		}
		for (auto ss : m_map){
			printf("%s [%s]\n", ss.first.c_str(), ss.second.c_str());
		}
	}
// 	if (lpRedis->type == REDIS_REPLY_ARRAY){
// 		std::map<string, string> m_map;
// 		for (size_t i = 0; i < lpRedis->elements; i++)
// 		{
// 			if (lpRedis->element[i]->type == REDIS_REPLY_STRING){
// 				printf("showID ========= %s\n", lpRedis->element[i]->str);
// 				string key = lpRedis->element[i]->str;
// 				redisReply * lpRedisK = RedisConnectionThread::instance()->command_do(boost::str(boost::format("hget ip_contrl%1% %2%") % playGuid % lpRedis->element[i]->str).c_str(),true);
// 				if (lpRedisK->type == REDIS_REPLY_STRING){
// 					string strTemp = lpRedisK->str;
// 					m_map[key] = strTemp;
// 				}
// 			}
// 		}
// 		for (auto ss : m_map){
// 			printf("%s [%s]\n", ss.first, ss.second);
// 		}
// 	}
}

void GameContrl::IncPlayTimes(const char * GameType, int playGuid, bool master_flag){
	string strCmd = boost::str(boost::format("incr playTimes_%1%_%2%") % playGuid % GameType);
	RedisConnectionThread::instance()->command_do(strCmd.c_str(), master_flag);
	//更新时间 expire 一天后删除ip设置
	strCmd = boost::str(boost::format("expire playTimes_%1%_%2% %3%") % playGuid % GameType % (24 * 3600));
	RedisConnectionThread::instance()->command_do(strCmd.c_str(), master_flag);
}

int  GameContrl::getPlayTimes(const char * GameType, int playGuid, bool master_flag){
	int num = 0;
	string strCmd = boost::str(boost::format("get playTimes_%1%_%2%") % playGuid % GameType);
	RedisReply redisT(RedisConnectionThread::instance()->command_do(strCmd.c_str(), master_flag));
	if (redisT.is_nil()){
		num = 0;
	}else if (redisT.is_string()){
		num = boost::lexical_cast<int>(redisT.get_string());
	}
	return num;
}