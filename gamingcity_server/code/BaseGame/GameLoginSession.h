#pragma once

#include "NetworkConnectSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"
#include "GameSessionManager.h"

/**********************************************************************************************//**
 * \class	GameLoginSession
 *
 * \brief	game连接login的session.
 **************************************************************************************************/

class GameLoginSession : public NetworkConnectSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	ioservice	The ioservice.
	 **************************************************************************************************/

	GameLoginSession(boost::asio::io_service& ioservice);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GameLoginSession();

	/**********************************************************************************************//**
	 * \brief	处理收到的消息.
	 *
	 * \param [in,out]	header	If non-null, the header.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool on_dispatch(MsgHeader* header);

	/**********************************************************************************************//**
	 * \brief	处理连接回调.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool on_connect();

	/**********************************************************************************************//**
	 * \brief	处理连接失败回调.
	 **************************************************************************************************/

	virtual void on_connect_failed();

	/**********************************************************************************************//**
	 * \brief	关闭socket前回调.
	 **************************************************************************************************/

	virtual void on_closed();

public:
	
	/**********************************************************************************************//**
	 * \brief	收到一个【web:请求服务器信息】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_wl_request_game_server_info(WL_RequestGameServerInfo* msg);

	/**********************************************************************************************//**
	* \brief	收到一个【php请求通过gm命令加钱】消息的处理函数.
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
	void on_wl_request_php_gm_cmd_change_money(LS_ChangeMoney * msg);
	void on_wl_broadcast_gameserver_gmcommand(WL_BroadcastClientUpdate * msg);

	void on_wl_request_LS_LuaCmdPlayerResult(LS_LuaCmdPlayerResult* msg);
private:
	NetworkDispatcherManager*			dispatcher_manager_;
};
