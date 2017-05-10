#pragma once

#include "NetworkSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "common_enum_define.pb.h"
#include "msg_server.pb.h"

/**********************************************************************************************//**
 * \class	ConfigSession
 *
 * \brief	其他服务器连接db的session.
 **************************************************************************************************/

class ConfigSession : public NetworkSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	sock	The sock.
	 **************************************************************************************************/

	ConfigSession(boost::asio::ip::tcp::socket& sock);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~ConfigSession();

	/**********************************************************************************************//**
	 * \brief	处理接受回调.
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
	 * \brief	收到一个【请求服务器配置】消息的处理函数.
	 *
	 * \param [in]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_S_RequestServerConfig(S_RequestServerConfig* msg);

	void on_S_RequestUpdateGameServerConfig(S_RequestUpdateGameServerConfig* msg);

	void on_S_RequestUpdateLoginServerConfigByGate(S_RequestUpdateLoginServerConfigByGate* msg);

	void on_S_RequestUpdateLoginServerConfigByGame(S_RequestUpdateLoginServerConfigByGame* msg);

	void on_S_RequestUpdateDBServerConfigByGame(S_RequestUpdateDBServerConfigByGame* msg);

	void on_S_RequestUpdateDBServerConfigByLogin(S_RequestUpdateDBServerConfigByLogin* msg);

	/**********************************************************************************************//**
	* \brief	处理game服务器配置
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
    void on_WF_ChangeGameCfg(WF_ChangeGameCfg* msg);
    
	/**********************************************************************************************//**
	* \brief	Web获取Php_sign
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
    void on_WF_GetCfg(WF_GetCfg* msg);
	/**********************************************************************************************//**
	* \brief	处理game返回状态
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
    void on_SF_ChangeGameCfg(SF_ChangeGameCfg* msg);
	void on_ReadMaintainSwitch(WS_MaintainUpdate* msg);
	//void on_RequestMaintainSwitchConfig(int id_index); 
	void on_RequestMaintainSwitchConfig(int session_id, int game_id, int id_index);
	void on_GF_PlayerOut(GF_PlayerOut* msg);
    void on_GF_PlayerIn(GF_PlayerIn* msg);
    void on_WF_Recharge(WF_Recharge *msg);
    void on_WF_CashFalse(WF_CashFalse *msg);
    void on_DF_Reply(DF_Reply *msg); 
    void on_DF_ChangMoney(DF_ChangMoney *msg);
    void on_FS_ChangMoneyDeal(FS_ChangMoneyDeal *msg);
    int get_type() { return type_; }
private:
	void get_login_config(int session_id, int login_id);
	void get_game_config(int session_id, int game_id);
	void get_gate_config(int session_id, int gate_id);
	void get_db_config(int session_id, int db_id);

	void update_gate_config(int session_id, int gate_id, int game_id);
	void update_gate_login_config(int session_id, int gate_id, int login_id);
	void update_game_login_config(int session_id, int game_id, int login_id);
	void update_game_db_config(int session_id, int game_id, int db_id);
	void update_login_db_config(int session_id, int login_id, int db_id);
private:
	NetworkDispatcherManager*			dispatcher_manager_;

	std::string							ip_;
	unsigned short						port_;

	int									type_;
	int									server_id_;
};
