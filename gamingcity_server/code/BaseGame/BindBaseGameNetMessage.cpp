#include "LuaScriptManager.h"
#include "GameSessionManager.h"
#include "LuaNetworkDispatcher.h"
#include "BaseGameServer.h"
#include "asynTask/HttpRequest.h"

static void reg_db_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	GameSessionManager::instance()->get_dispatcher_manager_db()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void reg_gate_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	GameSessionManager::instance()->get_dispatcher_manager_gate()->register_dispatcher(new LuaGateMsgDispatcher(msg, msgid, func, callback), show_log);
}
static void reg_gate_server_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
    GameSessionManager::instance()->get_dispatcher_manager_gate()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void reg_login_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	GameSessionManager::instance()->get_dispatcher_manager_login()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void reg_cfg_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
    GameConfigNetworkServer::instance()->get_dispatcher_manager()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void http_post_no_reply(const char* url, const char* data)
{
	std::string msg;
	msg.assign(data);
	std::thread th([=]()
	{
		std::string code_err;
		std::string code_ret;
		std::string split;
		AsioHttpPost_AllMsg(GameSessionManager::instance()->getNetworkServer()->get_io_server_pool().get_io_service(),
			url, msg, code_ret, code_err, split);
		LOG_INFO("http_post_no_reply url %s, msg %s,code_ret %s", url, data, code_ret.c_str());
	});
	th.detach();
}

static void send2db(unsigned short msgid, std::string pb)
{
	auto session = GameSessionManager::instance()->get_db_session();
	if (session)
	{
		session->send_spb(msgid, pb);
	}
	else
	{
		LOG_WARN("db server disconnect");
	}
}

static void send2client(int guid, int gate_id, unsigned short msgid, std::string pb)
{
	auto session = GameSessionManager::instance()->get_gate_session(gate_id);
	if (session)
	{
		session->send_c_spb(guid, msgid, pb);
	}
	else
	{
		LOG_WARN("gate server[%d] disconnect", gate_id);
	}
}

static void send2login(unsigned short msgid, std::string pb)
{
	auto session = GameSessionManager::instance()->get_login_session();
	if (session)
	{
		session->send_spb(msgid, pb);
	}
	else
	{
		LOG_WARN("login server disconnect");
	}
}

static void send2login_id(int serverid, unsigned short msgid, std::string pb)
{
    auto session = GameSessionManager::instance()->get_login_session(serverid);
    if (session)
    {
        session->send_spb(msgid, pb);
    }
    else
    {
        LOG_WARN("login server disconnect");
    }
}

static void send2cfg(unsigned short msgid, std::string pb)
{
    auto session = GameConfigNetworkServer::instance()->get_cfg_session();
    if (session)
    {
        session->send_spb(msgid, pb);
    }
    else
    {
        LOG_WARN("cfg server disconnect");
    }
}

static void broadcast_player_count(int count)
{
	GameSessionManager::instance()->broadcast_player_count(count);
}

static const char* get_gameserver_config()
{
	return static_cast<BaseGameServer*>(BaseServer::instance())->get_config().room_list().c_str();
	//if (static_cast<BaseGameServer*>(BaseServer::instance())->get_using_db_config())
	//	return BaseServer::instance()->get_gameserver_config().c_str();
	//return nullptr;
}


static const char* get_gameserver_room_lua_cfg()
{
	return static_cast<BaseGameServer*>(BaseServer::instance())->get_config().room_lua_cfg().c_str();
}

void bind_lua_net_message(lua_State* L)
{
	lua_tinker::def(L, "reg_db_dispatcher", reg_db_dispatcher);
	lua_tinker::def(L, "reg_gate_dispatcher", reg_gate_dispatcher);
    lua_tinker::def(L, "reg_login_dispatcher", reg_login_dispatcher);
    lua_tinker::def(L, "reg_cfg_dispatcher", reg_cfg_dispatcher);
    lua_tinker::def(L, "reg_gate_server_dispatcher", reg_gate_server_dispatcher);    
    lua_tinker::def(L, "send2db", send2db);
    lua_tinker::def(L, "send2cfg", send2cfg);    
	lua_tinker::def(L, "send2client", send2client);
    lua_tinker::def(L, "send2login", send2login);
    lua_tinker::def(L, "send2login_id", send2login_id);
	lua_tinker::def(L, "broadcast_player_count", broadcast_player_count);
	lua_tinker::def(L, "get_gameserver_config", get_gameserver_config);
	lua_tinker::def(L, "get_gameserver_room_lua_cfg", get_gameserver_room_lua_cfg);
	lua_tinker::def(L, "http_post_no_reply", http_post_no_reply);
}
