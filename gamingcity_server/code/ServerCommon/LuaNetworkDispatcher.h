#pragma once

#include "NetworkDispatcher.h"
#include "LuaScriptManager.h"

class LuaMsgDispatcher : public NetworkDispatcher
{
public:
	LuaMsgDispatcher(const std::string& msg, unsigned short msgid, const std::string& func, const std::string& callback)
		: msg_(msg)
		, msgid_(msgid)
		, func_(func)
		, callback_(callback)
	{
	}

	virtual ~LuaMsgDispatcher()
	{

	}

	virtual unsigned short get_msg_id()
	{
		return msgid_;
	}

	virtual bool parse(NetworkSession* session, MsgHeader* header)
	{
		std::string str;
		if (header->len > sizeof(MsgHeader))
		{
			str.assign(reinterpret_cast<char*>(header + 1), header->len - sizeof(MsgHeader));
		}

		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), callback_.c_str(), session->get_server_id(), func_.c_str(), msg_.c_str(), &str);
		
		return true;
	}

protected:
	std::string msg_;
	unsigned short msgid_;
	std::string func_;
	std::string callback_;
};

class LuaGateMsgDispatcher : public LuaMsgDispatcher
{
public:
	LuaGateMsgDispatcher(const std::string& msg, unsigned short msgid, const std::string& func, const std::string& callback)
		: LuaMsgDispatcher(msg, msgid, func, callback)
	{
	}

	virtual ~LuaGateMsgDispatcher()
	{

	}

	virtual bool parse(NetworkSession* session, MsgHeader* header)
	{
		GateMsgHeader* h = reinterpret_cast<GateMsgHeader*>(header);

		std::string str;
		if (header->len > sizeof(GateMsgHeader))
		{
			str.assign(reinterpret_cast<char*>(h + 1), h->len - sizeof(GateMsgHeader));
		}

		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), callback_.c_str(), h->guid, func_.c_str(), msg_.c_str(), &str);

		return true;
	}
};
