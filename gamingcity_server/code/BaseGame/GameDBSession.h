#pragma once

#include "NetworkConnectSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"
#include "GameSessionManager.h"

/**********************************************************************************************//**
 * \class	GameDBSession
 *
 * \brief	Game连接db的session.
 **************************************************************************************************/

class GameDBSession : public NetworkConnectSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	ioservice	The ioservice.
	 **************************************************************************************************/

	GameDBSession(boost::asio::io_service& ioservice);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GameDBSession();

	/**********************************************************************************************//**
	 * \brief	处理收到的消.
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

private:
	NetworkDispatcherManager*			dispatcher_manager_;
};
