#pragma once

#include "NetworkServer.h"
#include "NetworkDispatcher.h"
#include "Singleton.h"
#include "msg_server.pb.h"
#include "ConfigSession.h"

class ConfigSession;

/**********************************************************************************************//**
 * \class	ConfigSessionManager
 *
 * \brief	Manager for db sessions.
 **************************************************************************************************/

class ConfigSessionManager : public NetworkAllocator, public TSingleton < ConfigSessionManager >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	ConfigSessionManager();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~ConfigSessionManager();

	/**********************************************************************************************//**
	 * \brief	注册服务器连接消息的处理函数.
	 **************************************************************************************************/

	void register_server_message();

	/**********************************************************************************************//**
	 * \brief	创建sesssion.
	 *
	 * \param [in,out]	socket	The socket.
	 *
	 * \return	The new session.
	 **************************************************************************************************/

	virtual std::shared_ptr<NetworkSession> create_session(boost::asio::ip::tcp::socket& socket);

	/**********************************************************************************************//**
	 * \brief	得到处理S_Connect的消息分派器.
	 *
	 * \return	null if it fails, else the dispatcher manager.
	 **************************************************************************************************/

	NetworkDispatcherManager* get_dispatcher_manager() { return &dispatcher_manager_; }

	/**********************************************************************************************//**
	 * \brief	向login server发送消息.
	 *
	 * \tparam	T	Generic type parameter.
	 * \param [in,out]	pb	If non-null, the pb.
	 **************************************************************************************************/

	template<typename T> void send2server_pb(int session_id, T* pb)
	{
		auto session = find_by_id(session_id);
		if (session)
		{
			session->send_pb(pb);
		}
		else
		{
			LOG_WARN("login server[%d] disconnect", session_id);
		}
    }
    template<typename T> bool send2Gate_pb_ServerID(int server_id, T* pb)
    {
        for (auto& item : session_)
        {
            ConfigSession* session = static_cast<ConfigSession*>(item.second.get());
            if (item.second->get_server_id() == server_id && session->get_type() == ServerSessionFromGate)
            {
                session->send_pb(pb);
                return true;
            }
        }
        return false;
    }
    template<typename T> bool send2server_pb_ServerID(int server_id, T* pb)
    {
        auto session = find_by_server_id(server_id);
        if (session)
        {
            session->send_pb(pb);
        }
        else
        {
            LOG_WARN("gamer server[%d] disconnect", server_id);
            return false;
        }
        return true;
    }

	template<typename T> void broadcast2gate_pb(T* pb)
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		for (auto& item : session_)
		{
			ConfigSession* session = static_cast<ConfigSession*>(item.second.get());
			if (session->get_type() == ServerSessionFromGate)
			{
				session->send_pb(pb);
			}
		}
	}

	template<typename T> void broadcast2game_pb(T* pb)
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		for (auto& item : session_)
		{
			ConfigSession* session = static_cast<ConfigSession*>(item.second.get());
			if (session->get_type() == ServerSessionFromGame)
			{
				session->send_pb(pb);
			}
		}
	}

	template<typename T> void broadcast2login_pb(T* pb)
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		for (auto& item : session_)
		{
			ConfigSession* session = static_cast<ConfigSession*>(item.second.get());
			if (session->get_type() == ServerSessionFromLogin)
			{
				session->send_pb(pb);
			}
		}
    }
    template<typename T> void send2db_pb(T* pb)
    {
        std::lock_guard<std::recursive_mutex> lock(mutex_);
        for (auto& item : session_)
        {
            ConfigSession* session = static_cast<ConfigSession*>(item.second.get());
            if (session->get_type() == ServerSessionFromDB)
            {
                session->send_pb(pb);
                break;
            }
        }
    }
    std::string GetPHPSign() { return m_sPhpString; }
    void SetPHPSign(std::string str) { m_sPhpString = str; }
    DBGameConfigMgr  &GetServerCfg(){ return dbgamer_config; }

    void SetPlayer_Gate(int guid, int gate_id);
    int GetPlayer_Gate(int guid);
    void ErasePlayer_Gate(int guid);
protected:
	NetworkDispatcherManager			dispatcher_manager_;
	DBGameConfigMgr                     dbgamer_config;
    std::string                         m_sPhpString;
    std::map<int, int>                  m_mpPlayer_Gate;
};