#include "ConfigSession.h"
#include "ConfigSessionManager.h"
#include "GameLog.h"
#include "ConfigDBManager.h"
#include "common_enum_define.pb.h"
#include "ConfigServer.h"
#include "config_define.pb.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"


ConfigSession::ConfigSession(boost::asio::ip::tcp::socket& sock)
	: NetworkSession(sock)
	, dispatcher_manager_(nullptr)
	, port_(0)
	, type_(0)
	, server_id_(0)
{
}

ConfigSession::~ConfigSession()
{
}

bool ConfigSession::on_dispatch(MsgHeader* header)
{
	if (NetworkSession::on_dispatch(header))
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool ConfigSession::on_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... [%s:%d]", ip_.c_str(), port_);

	dispatcher_manager_ = ConfigSessionManager::instance()->get_dispatcher_manager();

	return true;
}

void ConfigSession::on_closed()
{
	LOG_INFO("session disconnect ... [%s:%d] type:%d", ip_.c_str(), port_, type_);

	switch (type_)
	{
	case ServerSessionFromGate:
		ConfigDBManager::instance()->get_db_connection_config().execute("UPDATE t_gate_server_cfg SET is_start = 0 WHERE gate_id = %d;", server_id_);
		break;
	case ServerSessionFromLogin:
		ConfigDBManager::instance()->get_db_connection_config().execute("UPDATE t_login_server_cfg SET is_start = 0 WHERE login_id = %d;", server_id_);
		break;
	case ServerSessionFromDB:
		ConfigDBManager::instance()->get_db_connection_config().execute("UPDATE t_db_server_cfg SET is_start = 0 WHERE id = %d;", server_id_);
		break;
	case ServerSessionFromGame:
		ConfigDBManager::instance()->get_db_connection_config().execute("UPDATE t_game_server_cfg SET is_start = 0 WHERE game_id = %d;", server_id_);
		break;
	default:
		LOG_WARN("unknown connect closed %d", type_);
		break;
	}
}

void ConfigSession::on_SF_ChangeGameCfg(SF_ChangeGameCfg* msg)
{
    FW_ChangeGameCfg reply;
    reply.set_result(msg->result());
    ConfigSessionManager::instance()->send2server_pb(msg->webid(), &reply);
    FG_GameServerCfg nmsg;
    GameClientRoomListCfg * cfg = nmsg.mutable_pb_cfg();
    cfg->CopyFrom(msg->pb_cfg());
    ConfigSessionManager::instance()->broadcast2gate_pb(&nmsg);
}
void ConfigSession::on_WF_GetCfg(WF_GetCfg* msg)
{
    FW_GetCfg reply;
    reply.set_php_sign(ConfigSessionManager::instance()->GetPHPSign().c_str());
    ConfigSessionManager::instance()->send2server_pb(get_id(), &reply);
}
void ConfigSession::on_WF_ChangeGameCfg(WF_ChangeGameCfg* msg)
{
    int WebID = get_id();
    int game_id = msg->id();
    ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([WebID, game_id](std::vector<std::vector<std::string>>* data) {
            FS_ChangeGameCfg nmsg;
            nmsg.set_webid(WebID);
            bool bRet = true;
            if (data && !data->empty() && data->front().size() >= 4)
            {
                if (data->front().front() == "0")
                {
                    LOG_INFO("get_game_config[%d] failed", game_id);
                    return;
                }
                nmsg.set_room_list(data->front()[2]);
                nmsg.set_room_lua_cfg(data->front()[3]);

                LOG_INFO("get_game_config[%d] ok", game_id);
                bRet = ConfigSessionManager::instance()->send2server_pb_ServerID(game_id, &nmsg);
            }
            else
            {
                LOG_ERR("load cfg from db error");
                bRet = false;
            }
            if (!bRet)
            {
                FW_ChangeGameCfg reply;
                reply.set_result(0);
                ConfigSessionManager::instance()->send2server_pb(nmsg.webid(), &reply);
            }

    }, "CALL get_game_config(%d);", game_id);
    
}
void ConfigSession::on_S_RequestServerConfig(S_RequestServerConfig* msg)
{
	type_ = msg->type();
	server_id_ = msg->server_id();

	// 给mysql请求
	LOG_INFO("load cfg type=%d id=%d\n", msg->type(), msg->server_id());
	
	switch (type_)
	{
	case ServerSessionFromGate:
		get_gate_config(get_id(), server_id_);
		break;
	case ServerSessionFromLogin:
		get_login_config(get_id(), server_id_);
		break;
	case ServerSessionFromDB:
        get_db_config(get_id(), server_id_);
		break;
	case ServerSessionFromGame:
		get_game_config(get_id(), server_id_);
		break;
	default:
		LOG_WARN("unknown connecting request %d", type_);
		break;
	}
}

void ConfigSession::on_S_RequestUpdateGameServerConfig(S_RequestUpdateGameServerConfig* msg)
{
	update_gate_config(get_id(), server_id_, msg->game_id());
}

void ConfigSession::on_S_RequestUpdateLoginServerConfigByGate(S_RequestUpdateLoginServerConfigByGate* msg)
{
	update_gate_login_config(get_id(), server_id_, msg->login_id());
}

void ConfigSession::on_S_RequestUpdateLoginServerConfigByGame(S_RequestUpdateLoginServerConfigByGame* msg)
{
	update_game_login_config(get_id(), server_id_, msg->login_id());
}

void ConfigSession::on_S_RequestUpdateDBServerConfigByGame(S_RequestUpdateDBServerConfigByGame* msg)
{
	update_game_db_config(get_id(), server_id_, msg->db_id());
}

void ConfigSession::on_S_RequestUpdateDBServerConfigByLogin(S_RequestUpdateDBServerConfigByLogin* msg)
{
	update_login_db_config(get_id(), server_id_, msg->db_id());
}


void ConfigSession::get_login_config(int session_id, int login_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_login_config[%d] failed", login_id);
				return;
			}

			LoginServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse login_config[%d] failed", login_id);
				return;
			}

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromLogin);
			reply.set_server_id(login_id);
			reply.mutable_login_config()->CopyFrom(info);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			S_NotifyLoginServerStart notify;
			notify.set_login_id(login_id);

			// 通知game
			ConfigSessionManager::instance()->broadcast2game_pb(&notify);
			// 通知gate
			ConfigSessionManager::instance()->broadcast2gate_pb(&notify);

			LOG_INFO("get_login_config[%d] ok", login_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_login_config(%d);", login_id);
	//2017-04-25 by rocky add
	on_RequestMaintainSwitchConfig(session_id,login_id,3);//请求登录维护开关
}

void ConfigSession::get_game_config(int session_id, int game_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 4)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_game_config[%d] failed", game_id);
				return;
			}

			GameServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse game_config[%d] failed", game_id);
				return;
			}

			info.set_room_list(data->front()[2]);
			info.set_room_lua_cfg(data->front()[3]);

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromGame);
			reply.set_server_id(game_id);
			reply.mutable_game_config()->CopyFrom(info);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			// 通知gate
			S_NotifyGameServerStart notify;
			notify.set_game_id(game_id);
			ConfigSessionManager::instance()->broadcast2gate_pb(&notify);

			LOG_INFO("get_game_config[%d] ok", game_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_game_config(%d);", game_id);

	//2017-04-25 by rocky add
	on_RequestMaintainSwitchConfig(session_id,game_id,1);//请求提现维护开关
	on_RequestMaintainSwitchConfig(session_id, game_id,2);//请求游戏维护开关
}

void ConfigSession::get_gate_config(int session_id, int gate_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_gate_config[%d] failed", gate_id);
				return;
			}

			GateServerConfigInfo info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse gate_config[%d] failed", gate_id);
				return;
			}

			ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, info](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					S_ReplyServerConfig reply;
					for (auto& item : *data)
					{
						auto p = reply.add_client_room_cfg();
						p->set_game_id(boost::lexical_cast<int>(item[0]));
						p->set_game_name(item[1]);
						p->set_first_game_type(boost::lexical_cast<int>(item[2]));
						p->set_second_game_type(boost::lexical_cast<int>(item[3]));

						rapidjson::Document document;
						document.Parse(item[4].c_str());
						p->set_table_count(document[0]["table_count"].GetInt());
						p->set_money_limit(document[0]["money_limit"].GetInt());
						p->set_cell_money(document[0]["cell_money"].GetInt());
						p->set_tax(document[0]["tax"].GetInt());

					}

					reply.set_type(ServerSessionFromGate);
					reply.set_server_id(gate_id);
					reply.mutable_gate_config()->CopyFrom(info);

					ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

					LOG_INFO("get_gate_config[%d] ok", gate_id);
				}
				else
				{
					LOG_ERR("reload cfg from db error");
				}
			}, "SELECT game_id, game_name, first_game_type, second_game_type, room_list FROM t_game_server_cfg WHERE is_open = 1;");
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_gate_config(%d);", gate_id);
}

void ConfigSession::get_db_config(int session_id, int db_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			if (data->front().front() == "0")
			{
				LOG_INFO("get_db_config[%d] failed", db_id);
				return;
			}

			DBServerConfig info;
			if (!google::protobuf::TextFormat::ParseFromString(data->front()[1], &info))
			{
				LOG_ERR("parse db_config[%d] failed", db_id);
				return;
			}

			S_ReplyServerConfig reply;
			reply.set_type(ServerSessionFromLogin);
			reply.set_server_id(db_id);
			reply.mutable_db_config()->CopyFrom(info);

            ConfigSessionManager::instance()->SetPHPSign(info.php_sign_key().c_str());
			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			S_NotifyDBServerStart notify;
			notify.set_db_id(db_id);

			// 通知game
			ConfigSessionManager::instance()->broadcast2game_pb(&notify);
			// 通知login
			ConfigSessionManager::instance()->broadcast2login_pb(&notify);

			LOG_INFO("get_db_config[%d] ok", db_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL get_db_config(%d);", db_id);

}

void ConfigSession::update_gate_config(int session_id, int gate_id, int game_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, game_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, game_id, ip, port](std::vector<std::vector<std::string>>* data) {
				if (data)
				{
					S_ReplyUpdateGameServerConfig reply;
					for (auto& item : *data)
					{
						auto p = reply.add_client_room_cfg();
						p->set_game_id(boost::lexical_cast<int>(item[0]));
						p->set_game_name(item[1]);
						p->set_first_game_type(boost::lexical_cast<int>(item[2]));
						p->set_second_game_type(boost::lexical_cast<int>(item[3]));

						rapidjson::Document document;
						document.Parse(item[4].c_str());
						p->set_table_count(document[0]["table_count"].GetInt());
						p->set_money_limit(document[0]["money_limit"].GetInt());
						p->set_cell_money(document[0]["cell_money"].GetInt());
						p->set_tax(document[0]["tax"].GetInt());

					}

					reply.set_server_id(gate_id);
					reply.set_game_id(game_id);
					reply.set_ip(ip);
					reply.set_port(port);

					ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

					LOG_INFO("update_gate_config[%d] ok", gate_id);
				}
				else
				{
					LOG_ERR("update_gate_config reload cfg from db error");
				}
			}, "SELECT game_id, game_name, first_game_type, second_game_type, room_list FROM t_game_server_cfg WHERE is_open = 1;");
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_gate_config(%d,%d);", gate_id, game_id);
}

void ConfigSession::update_gate_login_config(int session_id, int gate_id, int login_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, gate_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateLoginServerConfigByGate reply;
			
			reply.set_server_id(gate_id);
			reply.set_login_id(login_id);
			reply.set_ip(ip);
			reply.set_port(port);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_gate_login_config[%d] ok", gate_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_gate_login_config(%d,%d);", gate_id, login_id);
}

void ConfigSession::update_game_login_config(int session_id, int game_id, int login_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id, login_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateLoginServerConfigByGame reply;

			reply.set_server_id(game_id);
			reply.set_login_id(login_id);
			reply.set_ip(ip);
			reply.set_port(port);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_game_login_config[%d] ok", game_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_game_login_config(%d,%d);", game_id, login_id);
}

void ConfigSession::update_game_db_config(int session_id, int game_id, int db_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, game_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateDBServerConfigByGame reply;

			reply.set_server_id(game_id);
			reply.set_db_id(db_id);
			reply.set_ip(ip);
			reply.set_port(port);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_game_db_config[%d] ok", game_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_game_db_config(%d,%d);", game_id, db_id);
}

void ConfigSession::update_login_db_config(int session_id, int login_id, int db_id)
{
	ConfigDBManager::instance()->get_db_connection_config().execute_query_vstring([session_id, login_id, db_id](std::vector<std::vector<std::string>>* data) {
		if (data && !data->empty() && data->front().size() >= 2)
		{
			std::string ip = data->front()[0];
			int port = boost::lexical_cast<int>(data->front()[1]);

			S_ReplyUpdateDBServerConfigByLogin reply;

			reply.set_server_id(login_id);
			reply.set_db_id(db_id);
			reply.set_ip(ip);
			reply.set_port(port);

			ConfigSessionManager::instance()->send2server_pb(session_id, &reply);

			LOG_INFO("update_login_db_config[%d] ok", login_id);
		}
		else
		{
			LOG_ERR("load cfg from db error");
		}
	}, "CALL update_login_db_config(%d,%d);", login_id, db_id);
}
void ConfigSession::on_GF_PlayerOut(GF_PlayerOut* msg)
{
    ConfigSessionManager::instance()->ErasePlayer_Gate(msg->guid());
}
void ConfigSession::on_GF_PlayerIn(GF_PlayerIn* msg)
{
    ConfigSessionManager::instance()->SetPlayer_Gate(msg->guid(), server_id_);
}

//维护开关
void ConfigSession::on_ReadMaintainSwitch(WS_MaintainUpdate* msg)
{
	int webid = get_id();
	int id = msg->id_index();
	std::string  strtemp = "";
	if (id == 1)//提现
	{
		strtemp = "cash_switch";
	}
	else if (id == 2)//游戏
	{
		strtemp = "game_switch";
	}
	else if (id == 3)//登录
	{
		strtemp = "login_switch";
	}
	else
	{
		LOG_ERR("unknown key[%d],return", id);
		SW_MaintainResult reply;
		reply.set_result(2);
		ConfigSessionManager::instance()->send2server_pb(webid, &reply);
	}

	ConfigDBManager::instance()->get_db_connection_config().execute_query_string([webid, id, strtemp](std::vector<std::string>* data) {
		if (data && !data->empty())
		{
			CS_QueryMaintain queryinfo;
			
			int value_ = boost::lexical_cast<int>(data->front());//value=0维护状态,等于1正常
			LOG_INFO("--------maintain-----------key = [%d][%s],value_ = %d\n", id, strtemp.c_str(), value_);
			queryinfo.set_maintaintype(id);
			queryinfo.set_switchopen(value_);
			if (id == 3)
			{	
				ConfigSessionManager::instance()->broadcast2login_pb(&queryinfo);
			}
			else
			{
				ConfigSessionManager::instance()->broadcast2game_pb(&queryinfo);
			}	
			SW_MaintainResult reply;
			reply.set_result(1);
			ConfigSessionManager::instance()->send2server_pb(webid, &reply);
			LOG_INFO("on_ReadMaintainSwitch ok...");
		}
		else
		{
			LOG_ERR("ReadMaintainSwitch error");
			SW_MaintainResult reply;
			reply.set_result(2);
			ConfigSessionManager::instance()->send2server_pb(webid, &reply);
		}
	}, "select value from t_globle_int_cfg where `key` = '%s' ;", strtemp.c_str());
}

void ConfigSession::on_WF_Recharge(WF_Recharge *msg)
{
    LOG_INFO("on_WF_Recharge......order_id[%d]  web[%d]", msg->order_id(), get_id());
    FD_ChangMoney notify;
    notify.set_web_id(get_id());
    notify.set_order_id(msg->order_id());
    notify.set_type_id(LOG_MONEY_OPT_TYPE_RECHARGE_MONEY);
    ConfigSessionManager::instance()->send2db_pb(&notify);
}
void ConfigSession::on_WF_CashFalse(WF_CashFalse *msg)
{
    LOG_INFO("on_WF_CashFalse......order_id[%d]  web[%d]", msg->order_id(), get_id());
    FD_ChangMoney notify;
    notify.set_web_id(get_id());
    notify.set_order_id(msg->order_id());
    notify.set_type_id(LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE);
    notify.set_other_oper(msg->del());
    ConfigSessionManager::instance()->send2db_pb(&notify);
}

void ConfigSession::on_DF_Reply(DF_Reply *msg)
{
    FW_Result reply;
    LOG_INFO("on_DF_Reply...... web[%d] reply[%d]", msg->web_id(), msg->result());
    reply.set_result(msg->result());
    ConfigSessionManager::instance()->send2server_pb(msg->web_id(), &reply);
}
void ConfigSession::on_DF_ChangMoney(DF_ChangMoney *msg)
{
    int Gate_id = ConfigSessionManager::instance()->GetPlayer_Gate(msg->info().guid());
    LOG_INFO("on_DF_ChangMoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    if (Gate_id == -1)
    {
        LOG_INFO("on_DF_ChangMoney  %d no online", msg->info().guid());
        //玩家不在线
        FD_ChangMoneyDeal nmsg;
        AddMoneyInfo * info = nmsg.mutable_info();
        info->CopyFrom(msg->info());
        nmsg.set_web_id(msg->web_id());
        ConfigSessionManager::instance()->send2db_pb(&nmsg);
    }
    else
    {
        LOG_INFO("on_DF_ChangMoney  %d  online", msg->info().guid());
        FS_ChangMoneyDeal nmsg;
        AddMoneyInfo * info = nmsg.mutable_info();
        info->CopyFrom(msg->info());
        nmsg.set_web_id(msg->web_id());
        ConfigSessionManager::instance()->send2Gate_pb_ServerID(Gate_id, &nmsg);
    }
}
void ConfigSession::on_FS_ChangMoneyDeal(FS_ChangMoneyDeal *msg)
{
    LOG_INFO("on_FS_ChangMoneyDeal  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    FD_ChangMoneyDeal nmsg;
    AddMoneyInfo * info = nmsg.mutable_info();
    info->CopyFrom(msg->info());
    nmsg.set_web_id(msg->web_id());
    ConfigSessionManager::instance()->send2db_pb(&nmsg);
}

//LoginServer和GameServer启动时找ConfigServer请求维护开关初始值
void ConfigSession::on_RequestMaintainSwitchConfig(int session_id,int game_id,int id_index)
{
	int id = id_index;
	std::string  strtemp = "";
	if (id == 1)//提现
	{
		strtemp = "cash_switch";
	}
	else if (id == 2)//游戏
	{
		strtemp = "game_switch";
	}
	else if (id == 3)//登录
	{
		strtemp = "login_switch";
	}
	else
	{
		LOG_ERR("unknown key[%d],return", id);
		return;
	}

	ConfigDBManager::instance()->get_db_connection_config().execute_query_string([session_id,game_id, id, strtemp](std::vector<std::string>* data) {
		if (data && !data->empty())
		{
			CS_QueryMaintain queryinfo;
			int value_ = 0;
			value_ = boost::lexical_cast<int>(data->front());//value=0维护状态,等于1正常
			LOG_INFO("---on_RequestMaintainSwitchConfig-----maintain-----------key = [%d][%s],value_ = %d\n", id, strtemp.c_str(), value_);
			queryinfo.set_maintaintype(id);
			queryinfo.set_switchopen(value_);
			if (id == 3)
			{
				//ConfigSessionManager::instance()->broadcast2login_pb(&queryinfo);
				ConfigSessionManager::instance()->send2server_pb(session_id,&queryinfo);
			}
			else
			{
				//ConfigSessionManager::instance()->broadcast2game_pb(&queryinfo);
				ConfigSessionManager::instance()->send2server_pb_ServerID(game_id, &queryinfo);
			}
			
			LOG_INFO("on_RequestMaintainSwitchConfig ok...");
		}
		else
		{
			LOG_ERR("on_RequestMaintainSwitchConfig error..");
			return;
		}
	}, "select value from t_globle_int_cfg where `key` = '%s' ;", strtemp.c_str());
	return;
}
