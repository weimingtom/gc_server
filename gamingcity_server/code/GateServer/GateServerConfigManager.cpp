#include "GateServerConfigManager.h"
#include "GameLog.h"
#include <google/protobuf/text_format.h>
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

#if 0
GateServerConfigManager::GateServerConfigManager()
{
	cfg_file_name_ = "../config/GateServerConfig.pb";
}

GateServerConfigManager::~GateServerConfigManager()
{

}

bool GateServerConfigManager::load_file(const char* file, std::string& buf)
{
	std::ifstream ifs(file, std::ifstream::in);
	if (!ifs.is_open())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	buf = std::string(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
	if (ifs.bad())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	return true;
}

bool GateServerConfigManager::load_config()
{
	std::string buf;
	if (!load_file(cfg_file_name_.c_str(), buf))
		return false;

	if (!google::protobuf::TextFormat::ParseFromString(buf, &config_))
	{
		LOG_ERR("parse %s failed", cfg_file_name_.c_str());
		return false;
	}

	LOG_INFO("load_config ok......");
	return true;
}

bool GateServerConfigManager::load_gameserver_config()
{
	const char* cfg = "../data/game_server_cfg.json";
	std::string buf;
	if (!load_file(cfg, buf))
		return false;

	rapidjson::Document document;
	document.Parse(buf.c_str());
	for (size_t i = 0; i < document.Size(); i++)
	{
		auto cfg = gameserver_cfg_.add_pb_cfg();
		cfg->set_game_id(document[i]["game_id"].GetInt());
		cfg->set_first_game_type(document[i]["first_game_type"].GetInt());
		cfg->set_second_game_type(document[i]["second_game_type"].GetInt());
		cfg->set_game_name(document[i]["game_name"].GetString());
		for (size_t j = 0; j < document[i]["room_list"].Size(); j++)
		{
			auto room = cfg->add_pb_room_list();
			room->set_table_count(document[i]["room_list"][j]["table_count"].GetInt());
			room->set_money_limit(document[i]["room_list"][j]["money_limit"].GetInt());
			room->set_cell_money(document[i]["room_list"][j]["cell_money"].GetInt());
			room->set_tax(document[i]["room_list"][j]["tax"].GetInt());
		}
	}

	LOG_INFO("load_gameserver_config ok......");
	return true;
}

void GateServerConfigManager::load_gameserver_config_pb(LG_DBGameConfigMgr & gamecfg)
{
    dbgamer_config.clear_pb_cfg();
    for (int i = 0; i < gamecfg.pb_cfg_mgr().pb_cfg_size(); i++)
    {
        auto dbcfg = dbgamer_config.add_pb_cfg();
        dbcfg->CopyFrom(gamecfg.pb_cfg_mgr().pb_cfg(i));
    }
}
void GateServerConfigManager::load_gameserver_config_pb(DL_ServerConfig & gamecfg)
{
    for (int i = 0; i < gameserver_cfg_.pb_cfg_size(); i++)
    {
        if (gameserver_cfg_.pb_cfg(i).game_id() == gamecfg.cfg().game_id())
        {
            auto & p = (GameServerRoomListCfg &)gameserver_cfg_.pb_cfg(i);
            p.set_first_game_type(gamecfg.cfg().first_game_type());
            p.set_second_game_type(gamecfg.cfg().second_game_type());
            p.set_game_name(gamecfg.cfg().game_name());


            rapidjson::Document document;
            document.Parse(gamecfg.cfg().room_list().c_str());
            for (int j = 0; j < p.pb_room_list_size(); j++)
            {
                auto & f = (GameServerRoomCfg &)p.pb_room_list(j);
                f.set_table_count(document[j]["table_count"].GetInt());
                f.set_money_limit(document[j]["money_limit"].GetInt());
                f.set_cell_money(document[j]["cell_money"].GetInt());
                f.set_tax(document[j]["tax"].GetInt());
            }
            break;
        }
    }   
    for (int i = 0; i < dbgamer_config.pb_cfg_size(); i++)
    {
        if (dbgamer_config.pb_cfg(i).game_id() == gamecfg.cfg().game_id())
        {
            auto dbcfg = const_cast<DBGameConfig *>(&(dbgamer_config.pb_cfg(i)));
            dbcfg->CopyFrom(gamecfg.cfg());
            break;
        }
    }
    LOG_INFO("load_gameserver_config_db ok......");
}

void GateServerConfigManager::db_cfg_to_gamserver()
{
    gameserver_cfg_.clear_pb_cfg();
    for (int i = 0; i < dbgamer_config.pb_cfg_size(); i++)
    {
        auto dbcfg = dbgamer_config.pb_cfg(i);
        auto cfg = gameserver_cfg_.add_pb_cfg();
        cfg->set_game_id(dbcfg.game_id());
        cfg->set_first_game_type(dbcfg.first_game_type());
        cfg->set_second_game_type(dbcfg.second_game_type());
        cfg->set_game_name(dbcfg.game_name());

        rapidjson::Document document;
        document.Parse(dbcfg.room_list().c_str());
        for (size_t i = 0; i < document.Size(); i++)
        {
            auto room = cfg->add_pb_room_list();
            room->set_table_count(document[i]["table_count"].GetInt());
            room->set_money_limit(document[i]["money_limit"].GetInt());
            room->set_cell_money(document[i]["cell_money"].GetInt());
            room->set_tax(document[i]["tax"].GetInt());
        }
    }
}

void GateServerConfigManager::load_gameserver_config_db(const std::vector<std::vector<std::string>>& data)
{
    dbgamer_config.clear_pb_cfg();
	for (auto& item : data)
    {
        auto dbcfg = dbgamer_config.add_pb_cfg();
        dbcfg->set_cfg_name(item[0]);
        dbcfg->set_is_open(boost::lexical_cast<int>(item[1]));
        dbcfg->set_using_login_validatebox(boost::lexical_cast<int>(item[2]));
        dbcfg->set_ip(item[3]);
        dbcfg->set_port(boost::lexical_cast<int>(item[4]));
        dbcfg->set_game_id(boost::lexical_cast<int>(item[5]));
        dbcfg->set_first_game_type(boost::lexical_cast<int>(item[6]));
        dbcfg->set_second_game_type(boost::lexical_cast<int>(item[7]));
        dbcfg->set_game_name(item[8]);
        dbcfg->set_game_log(item[9]);
        dbcfg->set_default_lobby(boost::lexical_cast<int>(item[10]));
        dbcfg->set_player_limit(boost::lexical_cast<int>(item[11]));
        dbcfg->set_data_path(item[12]);
        dbcfg->set_room_list(item[13]);
        dbcfg->set_room_lua_cfg(item[14]);    
	}
    db_cfg_to_gamserver();
	LOG_INFO("load_gameserver_config_db ok......");
}

std::string GateServerConfigManager::get_title()
{
	auto pos1 = cfg_file_name_.find_last_of('/');
	if (pos1 != std::string::npos)
		pos1 += 1;
	else
		pos1 = 0;

	auto pos2 = cfg_file_name_.find_last_of('.');
	if (pos2 != std::string::npos)
		pos2 -= pos1;
	else
		pos2 = cfg_file_name_.size() - pos1;

	return cfg_file_name_.substr(pos1, pos2);
}

#endif
