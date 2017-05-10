#include "LuaScriptManager.h"
#include "DBSessionManager.h"
#include "LuaNetworkDispatcher.h"
#include "asynTask/HttpRequest.h"


static void reg_game_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	DBSessionManager::instance()->get_dispatcher_manager_game()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void reg_login_dispatcher(const char* msg, unsigned short msgid, const char* func, const char* callback, bool show_log)
{
	DBSessionManager::instance()->get_dispatcher_manager_login()->register_dispatcher(new LuaMsgDispatcher(msg, msgid, func, callback), show_log);
}

static void send2game(int game_id, unsigned short msgid, std::string pb)
{
	auto session = DBSessionManager::instance()->get_game_session(game_id);
	if (session)
	{
		session->send_spb(msgid, pb);
	}
	else
	{
		LOG_WARN("game server[%d] disconnect", game_id);
	}
}

static void send2login(int login_id, unsigned short msgid, std::string pb)
{
	auto session = DBSessionManager::instance()->get_login_session(login_id);
    if (session)
    {
        session->send_spb(msgid, pb);
    }
    else
    {
		LOG_WARN("login server[%d] disconnect", login_id);
    }
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
		AsioHttpPost_AllMsg(DBSessionManager::instance()->getNetworkServer()->get_io_server_pool().get_io_service(),
			url, msg, code_ret, code_err, split);

		LOG_INFO("http_post_no_reply url %s, msg %s,code_ret %s", url, data, code_ret.c_str());
	});
	th.detach();
}

void bind_lua_db_net_message(lua_State* L)
{
	lua_tinker::def(L, "reg_game_dispatcher", reg_game_dispatcher);
	lua_tinker::def(L, "reg_login_dispatcher", reg_login_dispatcher);
    lua_tinker::def(L, "send2game", send2game);
    lua_tinker::def(L, "send2login", send2login);
	lua_tinker::def(L, "http_post_no_reply", http_post_no_reply);
}