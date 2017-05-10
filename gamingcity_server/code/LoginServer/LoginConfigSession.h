#pragma once

#include "NetworkConnectSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"

/**********************************************************************************************//**
 * \class	LoginConfigSession
 *
 * \brief	login连接config的session.
 **************************************************************************************************/

class LoginConfigSession : public NetworkConnectSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	ioservice	The ioservice.
	 **************************************************************************************************/

	LoginConfigSession(boost::asio::io_service& ioservice);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~LoginConfigSession();

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

public:

	/**********************************************************************************************//**
	* \brief	config返回配置
	**************************************************************************************************/

	void on_S_ReplyServerConfig(S_ReplyServerConfig* msg);

	void on_S_NotifyDBServerStart(S_NotifyDBServerStart* msg);

	void on_S_ReplyUpdateDBServerConfigByLogin(S_ReplyUpdateDBServerConfigByLogin* msg);

	void on_S_Maintain_switch(CS_QueryMaintain* msg);
private:
	NetworkDispatcherManager*			dispatcher_manager_;
};
