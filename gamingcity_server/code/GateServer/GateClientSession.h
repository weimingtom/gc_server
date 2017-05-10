#pragma once

#include "NetworkSession.h"
#include "NetworkDispatcher.h"
#include "common_msg_define.pb.h"
#include "GateSessionManager.h"
#include "GateServerConfigManager.h"
#include "GameLog.h"

/**********************************************************************************************//**
 * \class	GateClientSession
 *
 * \brief	client连接gate的session.
 **************************************************************************************************/

class GateClientSession : public NetworkSession
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param [in,out]	sock	The sock.
	 **************************************************************************************************/

	GateClientSession(boost::asio::ip::tcp::socket& sock);

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GateClientSession();

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
	 * \brief	得到guid.
	 *
	 * \return	The unique identifier.
	 **************************************************************************************************/

	int get_guid() { return guid_; }

	/**********************************************************************************************//**
	 * \brief	设置guid.
	 *
	 * \param	guid	Unique identifier.
	 **************************************************************************************************/

	void set_guid(int guid) {
        LOG_WARN("set guid old[%d] new[%d]", guid_, guid);
        guid_ = guid; 
    }

	/**********************************************************************************************//**
	 * \brief	得到当前玩家在哪个游戏服务器.
	 *
	 * \return	The game server identifier.
	 **************************************************************************************************/

	int get_game_server_id() { return game_server_id_; }

	/**********************************************************************************************//**
	 * \brief	设置当前玩家在哪个游戏服务器.
	 *
	 * \param	server_id	Identifier for the server.
	 **************************************************************************************************/

	void set_game_server_id(int server_id) { game_server_id_ = server_id; }

	virtual bool tick();

	// 设置账号
	void set_account(const std::string& account) { account_ = account; }

	std::string get_account() { return account_; }

	void set_user_data(int user_data) { user_data_ = user_data; }
	int get_user_data() { return user_data_; }

	void set_login(bool iflag) {
		LOG_WARN("set m_login [%d] guid[%d]", iflag, guid_);
		LOG_WARN("ip[%s] port[%d]", ip_.c_str(), port_);
        LOG_WARN("this address [%d]", this);
		m_islogin = iflag;
	}
	bool get_login() { return m_islogin; }

	// 设置短信验证码
	void set_sms(const std::string& tel, const std::string& sms_no);
	void clear_sms();

	void reset_is_send_login() { is_send_login_ = false; }
public:
	void do_get_sms_http(const std::string& phone);
private:
	bool on_C_RequestPublicKey(MsgHeader* header);
	bool on_CL_RegAccount(MsgHeader* header);
	bool on_CL_Login(MsgHeader* header);
	bool on_CL_LoginBySms(MsgHeader* header);
	bool on_CS_RequestSms(MsgHeader* header);
	bool on_CG_GameServerCfg(MsgHeader* header);
	bool on_CS_ResetAccount(MsgHeader* header);
	bool on_CS_SetNickname(MsgHeader* header);
	bool on_CS_SetPassword(MsgHeader* header);
	bool on_CS_SetPasswordBySms(MsgHeader* header);
	bool on_CS_BankSetPassword(MsgHeader* header);
	bool on_CS_BankChangePassword(MsgHeader* header);
	bool on_CS_BankLogin(MsgHeader* header);
	bool on_CL_GetInviterInfo(MsgHeader* header);
	

	bool check_string(const std::string& str);

private:
	std::string							ip_;
	unsigned short						port_;

	int									guid_;

	int									game_server_id_;
	int									user_data_; // 回复login

	std::string							private_key_;
	time_t								timeout_limit_;
	//time_t								last_msg_time_;

	std::string							account_; // 账号名字
	bool                                m_islogin;

	std::string							tel_; // 手机号
	std::string							sms_no_; // 手机验证码
	time_t								last_sms_time_; // 上次请求时间
	time_t								sms_time_limit_;

	bool								is_send_login_;				// 是否发送登陆消息
};
