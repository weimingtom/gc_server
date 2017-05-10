#pragma once

#include "NetworkSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"
//#include "PbClientSocket.h"
//#include "rapidjson/document.h"
//#include "rapidjson/writer.h"
//#include "rapidjson/stringbuffer.h"

/**********************************************************************************************//**
 * \class	GameSession
 *
 * \brief	gate连接game的session.
 **************************************************************************************************/

class GameSession : public NetworkSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	sock	The sock.
	 **************************************************************************************************/

	GameSession(boost::asio::ip::tcp::socket& sock);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GameSession();

	/**********************************************************************************************//**
	 * \brief	处理收到的消息.
	 *
	 * \param [in,out]	header	If non-null, the header.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool on_dispatch(MsgHeader* header);

	/**********************************************************************************************//**
	 * \brief	处理接受回调.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool on_accept();

	/**********************************************************************************************//**
	 * \brief	关闭socket前回调.
	 **************************************************************************************************/

	virtual void on_closed();

	/**********************************************************************************************//**
	 * \brief	得到服务器id.
	 *
	 * \return	The server identifier.
	 **************************************************************************************************/

	virtual int get_server_id() { return server_id_; }

	/**********************************************************************************************//**
	 * \brief	设置服务器id.
	 *
	 * \param	server_id	Identifier for the server.
	 **************************************************************************************************/

	void set_server_id(int server_id) { server_id_ = server_id; }

public:

	/**********************************************************************************************//**
	 * \brief	收到一个【服务器连接】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_s_connect(S_Connect* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【玩家退出】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_s_logout(S_Logout* msg);


    ///************************************************************************/
    ///* web 发送相关函数                                                                     */
    ///************************************************************************/
    //typedef MsgBuffer<MSG_SEND_BUFFER_SIZE> MsgSendBuffer;

    //void sendWebSocket(std::string ip,int port,std::string host,std::string url,std::string uData,const std::function<void(int retCode,std::string retData)>& func);
    //void handleWebSend(boost::shared_ptr<boost::asio::ip::tcp::socket> sockT, std::string Data, const std::function<void(int retCode, std::string retData)>& func,
    //    const boost::system::error_code& err, size_t bytes_transferred);
    //void handleWebRead(boost::shared_ptr<boost::asio::ip::tcp::socket> sockT, boost::shared_ptr<MsgSendBuffer> ubuffer, const std::function<void(int retCode, std::string retData)>& func,
    //    const boost::system::error_code& err, size_t bytes_transferred);
    //std::string createWebRequestData(std::string host, std::string url, std::string uData);
private:
	NetworkDispatcherManager*			dispatcher_manager_;

	std::string							ip_;
	unsigned short						port_;

	int									type_;
	int									server_id_;
};