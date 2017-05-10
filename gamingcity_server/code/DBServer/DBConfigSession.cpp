#include "DBConfigSession.h"
#include "GameLog.h"
#include "common_enum_define.pb.h"
#include "DBServer.h"
#include "DBConfigNetworkServer.h"

DBConfigSession::DBConfigSession(boost::asio::io_service& ioservice)
    : NetworkConnectSession(ioservice)
    , dispatcher_manager_(nullptr)
{
    dispatcher_manager_ = DBConfigNetworkServer::instance()->get_dispatcher_manager();
}

DBConfigSession::~DBConfigSession()
{
}

bool DBConfigSession::on_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		return true;
	}

    auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
    if (nullptr == dispatcher)
    {
        LOG_ERR("msg[%d] not registered", header->id);
        return true;
    }

    return dispatcher->parse(this, header);
}

bool DBConfigSession::on_connect()
{
    LOG_INFO("login->config connect success ... [%s:%d]", ip_.c_str(), port_);

	if (!static_cast<DBServer*>(BaseServer::instance())->get_init_config_server())
	{
		S_RequestServerConfig msg;
		msg.set_type(ServerSessionFromDB);
		msg.set_server_id(static_cast<DBServer*>(BaseServer::instance())->get_db_id());
		send_pb(&msg);
	}

    return NetworkConnectSession::on_connect();
}

void DBConfigSession::on_connect_failed()
{
    LOG_INFO("login->config connect failed ... [%s:%d]", ip_.c_str(), port_);

    NetworkConnectSession::on_connect_failed();
}

void DBConfigSession::on_closed()
{
    LOG_INFO("login->config disconnect ... [%s:%d]", ip_.c_str(), port_);

    NetworkConnectSession::on_closed();
}


void DBConfigSession::on_S_ReplyServerConfig(S_ReplyServerConfig* msg)
{
    static_cast<DBServer*>(BaseServer::instance())->on_loadConfigComplete(msg->db_config());
    printf("load config complete type=%d id=%d\n", msg->type(), msg->server_id());
}
void DBConfigSession::on_fd_changemoney(FD_ChangMoney* msg)
{
    int order_id = msg->order_id();
    int web_id = msg->web_id();
    int type_id = msg->type_id();
    if (msg->type_id() == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)
    {
        DBManager::instance()->get_db_connection_recharge().execute_query<Recharge>([type_id, web_id, order_id](Recharge* data) {
            if (data && (data->pay_status() != 2) && (data->server_status() == 0))
            {
                DF_ChangMoney reply;
                reply.set_web_id(web_id);
                AddMoneyInfo * info = reply.mutable_info();
                info->set_guid(data->guid());
                info->set_type_id(type_id);
                info->set_gold(data->exchange_gold());
                info->set_order_id(order_id);
                DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
            }
            else
            {
                DF_Reply reply;
                reply.set_web_id(web_id);
                reply.set_result(2);
                DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
            }
        }, nullptr, "SELECT guid, id, exchange_gold, pay_status,server_status FROM t_recharge_order WHERE id='%d';", order_id);
    }
    else if (msg->type_id() == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
    {
        int del = msg->other_oper();
        DBManager::instance()->get_db_connection_recharge().execute_query<CashFalse>([type_id, web_id, order_id, del](CashFalse* data) {
            if (data && (data->status() != 1) && (data->status() != 0) && (data->status() != 4) && (data->status_c() == 0))
            {
                DF_ChangMoney reply;
                reply.set_web_id(web_id);
                AddMoneyInfo * info = reply.mutable_info();
                info->set_guid(data->guid());
                info->set_type_id(type_id);
                info->set_gold(data->coins());
                info->set_order_id(order_id);
                DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
                int guid = data->guid();
                if (del){
                    DBManager::instance()->get_db_connection_account().execute("UPDATE t_account SET `alipay_account_y` = NULL, alipay_name_y = NULL, alipay_account = NULL, alipay_name = NULL  WHERE guid = %d;", guid);
                }
            }
            else
            {
                DF_Reply reply;
                reply.set_web_id(web_id);
                reply.set_result(2);
                DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
            }
        }, nullptr, "SELECT guid, order_id, coins, status, status_c FROM t_cash WHERE order_id='%d';", order_id);
    }
    else
    {

    }
}
void insert_into_changemoney(FD_ChangMoneyDeal* msg)
{
    LOG_INFO("on_DF_ChangMoney  web[%d] gudi[%d] order_id[%d] type[%d]", msg->web_id(), msg->info().guid(), msg->info().order_id(), msg->info().type_id());
    int web_id = msg->web_id();
    AddMoneyInfo info;
    info.CopyFrom(msg->info());
    DBManager::instance()->get_db_connection_recharge().execute_query_string([web_id, info](std::vector<std::string>* data) {
        if (data)
        {
            LOG_INFO("on_DF_ChangMoney  order[%d] is  deal", info.order_id());
            DF_Reply reply;
            reply.set_web_id(web_id);
            reply.set_result(6);
            DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
        }
        else
        {
            LOG_INFO("on_DF_ChangMoney  order[%d] is not deal", info.order_id());
            DBManager::instance()->get_db_connection_recharge().execute_update([web_id, info](int ret) {
                DF_Reply reply;
                reply.set_web_id(web_id);
                if (ret > 0)
                {//插入成功
                    LOG_INFO("on_DF_ChangMoney  order[%d] insert t_re_recharge  true", info.order_id());
                    reply.set_result(6);
                    if (info.type_id() == LOG_MONEY_OPT_TYPE_RECHARGE_MONEY)
                    {
                        DBManager::instance()->get_db_connection_recharge().execute("UPDATE t_recharge_order SET `server_status` = '6' WHERE id = %d;", info.order_id());
                    }
                    else if (info.type_id() == LOG_MONEY_OPT_TYPE_CASH_MONEY_FALSE)
                    {
                        if (info.order_id() != -1)
                        {//-1为非订单失败
                            DBManager::instance()->get_db_connection_recharge().execute("UPDATE t_cash SET `status_c` = '6' WHERE order_id = %d;", info.order_id());
                        }
                    }
                }
                else
                {//插入失败
                    LOG_INFO("on_DF_ChangMoney  order[%d] insert t_re_recharge  false", info.order_id());
                    reply.set_result(4);
                }
                if (web_id != -1)
                {
                    LOG_INFO("on_DF_ChangMoney  order[%d] reply web[%d]", web_id);
                    DBConfigNetworkServer::instance()->send2cfg_pb(&reply);
                }
            }, "INSERT INTO t_re_recharge(`guid`,`money`,`type`,`order_id`,`created_at`)VALUES('%d', '%I64d', '%d', '%d', current_timestamp)", info.guid(), info.gold(), info.type_id(), info.order_id());
        }
    }, "select id, guid from t_re_recharge where type = '%d' and order_id = '%d';", info.type_id(), info.order_id());
}
void DBConfigSession::on_fd_changemoneydeal(FD_ChangMoneyDeal* msg)
{
    insert_into_changemoney(msg);
}
