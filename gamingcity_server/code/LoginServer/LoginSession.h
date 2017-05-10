#pragma once

#include "NetworkSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "msg_server.pb.h"
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"

/**********************************************************************************************//**
 * \class	LoginSession
 *
 * \brief	gate，game连接login的session.
 **************************************************************************************************/

#include "stdarg.h" 
#define endStr "JudgeParamEnd"
#define checkJsonMember(ABC,...)  LoginSession::checkJsonMemberT(ABC,1,__VA_ARGS__,endStr)

struct stCostBankMoeny
{
	std::string m_data;
	std::function<void(int  retCode, int oldmoeny, int newmoney, std::string)> func;
};
struct stDoSql
{
	std::string m_data;
	std::function<void(int  retCode, std::string retData, std::string stData)> func;
};
class LoginSession : public NetworkSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	sock	The sock.
	 **************************************************************************************************/

	LoginSession(boost::asio::ip::tcp::socket& sock);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~LoginSession();

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
	 * \brief	收到一个【更新游戏服务器人数】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_S_UpdateGamePlayerCount(S_UpdateGamePlayerCount* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【玩家退出】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_s_logout(S_Logout* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【客户端登录】消息的处理函数.
	 *
	 * \param	session_id 	Identifier for the session.
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_cl_login(int session_id, CL_Login* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【注册账号】消息的处理函数.
	 *
	 * \param	session_id 	Identifier for the session.
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_cl_reg_account(int session_id, CL_RegAccount* msg);
	
	/**********************************************************************************************//**
	 * \brief	收到一个【用短信验证码登陆】消息的处理函数.
	 *
	 * \param	session_id 	Identifier for the session.
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_cl_login_by_sms(int session_id, CL_LoginBySms* msg);
	
	/**********************************************************************************************//**
	 * \brief	收到一个【回复login踢人】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_L_KickClient(L_KickClient* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【切换游戏服务器】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_ss_change_game(SS_ChangeGame* msg);
	void on_SL_ChangeGameResult(SL_ChangeGameResult* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【申请短信验证】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_cs_request_sms(CS_RequestSms* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【转账】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_sd_bank_transfer(SD_BankTransfer* msg);
	
	/**********************************************************************************************//**
	 * \brief	收到一个【通过guid转账】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_sd_bank_transfer_by_guid(S_BankTransferByGuid* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【转账】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_cs_chat_world(int session_id, CS_ChatWorld* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【私聊】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_sc_chat_private(SC_ChatPrivate* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【web:请求服务器信息】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_wl_request_game_server_info(WL_RequestGameServerInfo* msg);

	/**********************************************************************************************//**
	 * \brief	收到一个【web:返回服务器信息】消息的处理函数.
	 *
	 * \param [in,out]	msg	If non-null, the message.
	 **************************************************************************************************/

	void on_sl_web_game_server_info(SL_WebGameServerInfo* msg);

    /**********************************************************************************************//**
    * \brief	收到一个GmCommand消息的处理函数.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void on_wl_request_GMMessage(WL_GMMessage * msg);

    /**********************************************************************************************//**
    * \brief	判断用户是否在线.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    static void player_is_online(int guid, const std::function<void( int  gateid,  int sessionid, std::string)>& func);
    
    /**********************************************************************************************//**
    * \brief	gate发送消息完成返回.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void on_gl_NewNotice(GL_NewNotice * msg);

    /**********************************************************************************************//**
    * \brief	发送消息完成返回.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    static void Ret_GMMessage(int retCode, int retID);

    /**********************************************************************************************//**
    * \brief	处理反馈信息.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void UpdateFeedBack(rapidjson::Document &document);
    static bool checkJsonMemberT(rapidjson::Document &document, int start, ...);
	
    /**********************************************************************************************//**
    * \brief	提现失败向数据库发送查询订单.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
 //   void on_wl_request_cash_false(WL_CashFalse* msg);
    
    /**********************************************************************************************//**
    * \brief	提现失败接收游戏服务器处理结果.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void on_sl_cash_false_reply(SL_CashReply* msg);

    ///**********************************************************************************************//**
    //* \brief	充值向数据库发送查询订单.
    //*
    //* \param [in,out]	msg	If non-null, the message.
    //**************************************************************************************************/
    //void on_wl_request_recharge(WL_Recharge* msg);
    ///**********************************************************************************************//**
    //* \brief	充值接收游戏服务器处理结果.
    //*
    //* \param [in,out]	msg	If non-null, the message.
    //**************************************************************************************************/
    //void on_sl_recharge_reply(SL_RechargeReply* msg);
    
    /**********************************************************************************************//**
    * \brief	处理控制税率改变.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void on_wl_request_change_tax(WL_ChangeTax* msg);
    
    /**********************************************************************************************//**
    * \brief	控制税率改变处理结果.
    *
    * \param [in,out]	msg	If non-null, the message.
    **************************************************************************************************/
    void on_sl_change_tax_reply(SL_ChangeTax* msg); 

	/**********************************************************************************************//**
	* \brief	处理php通过gm命令加钱请求
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
	void on_wl_request_gm_change_money(WL_ChangeMoney *msg);

	void on_WL_LuaCmdPlayerResult(WL_LuaCmdPlayerResult* msg);
	void on_SL_LuaCmdPlayerResult(SL_LuaCmdPlayerResult* msg);
    
	/**********************************************************************************************//**
	* \brief	处理Game加钱失败后 回退处理
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
    void on_SL_AddMoney(SL_AddMoney* msg);
	/**********************************************************************************************//**
	* \brief	Gate服务器获取配置
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
    void on_gl_get_server_cfg(int session_id, GL_GetServerCfg* msg);
	//获取邀请人信息
	void on_cl_get_server_cfg(int session_id, CL_GetInviterInfo* msg);

	//loginServer通知所有的服务器广播客户端
	void on_wl_broadcast_gameserver_cmd(WL_BroadcastClientUpdate *msg);

	/**********************************************************************************************//**
	* \brief	扣减玩家银行类的金钱.
	*
	* \param [in,out]	msg	If non-null, the message.
	**************************************************************************************************/
	bool cost_player_bank_money(std::string keyid, int guid, int money, std::string strData, std::function<void(int  retCode, int oldmoeny, int newmoney, std::string)> func);
	void create_do_Sql(std::string  keyid, std::string database, std::string strSql, std::string strData, std::function<void(int  retCode, std::string retData, std::string stData)>);
	void on_SL_AT_ChangeMoney(SL_CC_ChangeMoney* msg);
	void on_sl_FreezeAccount(SL_FreezeAccount * msg);
	void on_DB_Request(DL_CC_ChangeMoney * msg);
	void on_do_SqlReQuest(DL_DO_SQL * msg);
	void on_AT_PL_ChangeMoney(AgentsTransferData stData);
	//修改支付宝信息
	void EditAliPay(rapidjson::Document &document);
private:
	std::map<std::string, stCostBankMoeny > m_mapCostBankFunc;
	std::map<std::string, stDoSql > m_mapDoSql;
	NetworkDispatcherManager*			dispatcher_manager_;
	std::string							ip_;
	unsigned short						port_;

	int									type_;
	int									server_id_;
};