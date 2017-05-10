#include "GameSession.h"
#include "GameDBSession.h"
#include "GameSessionManager.h"
#include "GameLog.h"
#include "LuaScriptManager.h"
#include "BaseGameServer.h"

GameSession::GameSession(boost::asio::ip::tcp::socket& sock)
	: NetworkSession(sock)
	, dispatcher_manager_(nullptr)
	, port_(0)
	, type_(0)
	, server_id_(0)
{
}

GameSession::~GameSession()
{
}

bool GameSession::on_dispatch(MsgHeader* header)
{
	if (NetworkSession::on_dispatch(header))
	{
		return true;
	}

	if (nullptr == dispatcher_manager_)
	{
		LOG_ERR("dispatcher manager is null");
		return false;
	}

	auto dispatcher = dispatcher_manager_->query_dispatcher(header->id);
	if (nullptr == dispatcher)
	{
		LOG_WARN("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool GameSession::on_accept()
{
	port_ = get_remote_ip_port(ip_);
	LOG_INFO("accept session ... [%s:%d]", ip_.c_str(), port_);

	dispatcher_manager_ = GameSessionManager::instance()->get_dispatcher_manager();

	return true;
}

void GameSession::on_closed()
{
	LOG_INFO("session disconnect ... [%s:%d]", ip_.c_str(), port_);
	switch (type_)
	{
	case ServerSessionFromGate:
		GameSessionManager::instance()->del_gate_session(shared_from_this());
		break;
	default:
		LOG_WARN("unknown connect closed %d", type_);
		break;
	}
}

void GameSession::on_s_connect(S_Connect* msg)
{
	type_ = msg->type();
	switch (type_)
	{
	case ServerSessionFromGate:
	{
		dispatcher_manager_ = GameSessionManager::instance()->get_dispatcher_manager_gate();
		server_id_ = msg->server_id();
		GameSessionManager::instance()->add_gate_session(shared_from_this());

		S_Connect reply;
		reply.set_type(ServerSessionFromGame);
		reply.set_server_id(static_cast<BaseGameServer*>(BaseServer::instance())->get_config().game_id());
		send_pb(&reply);

		LOG_INFO("S_Connect session gateid=%d ... [%s:%d]", server_id_, ip_.c_str(), port_);
	}
		break;
	default:
		LOG_WARN("unknown connecting %d", type_);
		close();
	}
}

void GameSession::on_s_logout(S_Logout* msg)
{
	if (msg->has_guid())
	{
		lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), "logout", msg->guid());

		if (msg->user_data() > 0)
		{
			L_KickClient notify;
			notify.set_reply_account(msg->account());
			notify.set_user_data(msg->user_data());

			GameSessionManager::instance()->send2login_pb(&notify);
		}
	}
	else
	{
		LOG_WARN("no guid");
	}
}
//
//void GameSession::sendWebSocket(std::string ip, int port, std::string host, std::string url, std::string uData, const std::function<void(int retCode, std::string retData)>& func)
//{
//    boost::shared_ptr<boost::asio::ip::tcp::socket> socketT = boost::make_shared<boost::asio::ip::tcp::socket>(GameSessionManager::instance()->getNetworkServer()->get_io_server_pool().get_io_service());
//    boost::asio::ip::tcp::endpoint end_point(boost::asio::ip::address::from_string(GameServerConfigManager::instance()->get_config().config_web_feekback().ip()), GameServerConfigManager::instance()->get_config().config_web_feekback().port());
//    boost::system::error_code error;
//    socketT->connect(end_point, error);
//    if (error){
//        // 连接web端失败 返回错误
//        func(-error.value(), error.category().name());
//    }
//    std::string u_Data = createWebRequestData(host, url, uData);
//    std::shared_ptr<GameSession> pointer = std::dynamic_pointer_cast<GameSession>(shared_from_this());
//    socketT->async_send(boost::asio::buffer(u_Data, u_Data.length()),
//        boost::bind(&GameSession::handleWebSend, pointer, socketT, u_Data, func, boost::asio::placeholders::error, boost::asio::placeholders::bytes_transferred));
//}
//void  GameSession::handleWebSend(boost::shared_ptr<boost::asio::ip::tcp::socket> sockT, std::string Data, const std::function<void(int retCode, std::string retData)>& func, const boost::system::error_code& err, size_t bytes_transferred){
//    if (!err){
//        int nLen = bytes_transferred;
//        std::shared_ptr<GameSession> pointer = std::dynamic_pointer_cast<GameSession>(shared_from_this());
//        if (Data.length() > nLen){
//            Data = Data.substr(nLen);
//            sockT->async_send(boost::asio::buffer(Data, Data.length()),
//                boost::bind(&GameSession::handleWebSend, pointer, sockT, Data, func, boost::asio::placeholders::error, boost::asio::placeholders::bytes_transferred));
//        }
//        else {
//            boost::shared_ptr<MsgSendBuffer> ubuffer = boost::make_shared<MsgSendBuffer>();
//            sockT->async_read_some(boost::asio::buffer(ubuffer->data(), ubuffer->remain()),
//                boost::bind(&GameSession::handleWebRead, pointer, sockT, ubuffer, func, boost::asio::placeholders::error, boost::asio::placeholders::bytes_transferred));
//        }
//    }
//    else {
//        sockT->close();
//        func(-err.value(), err.category().name());
//    }
//}
//void GameSession::handleWebRead(boost::shared_ptr<boost::asio::ip::tcp::socket> sockT, boost::shared_ptr<MsgSendBuffer> ubuffer, const std::function<void(int retCode, std::string retData)>& func,
//    const boost::system::error_code& err, size_t bytes_transferred){
//    if (!err){
//        if (!ubuffer->add(bytes_transferred))
//        {
//            LOG_ERR("recv is full");
//            sockT->close();
//            func(GMmessageRetCode::GMmessageRetCode_FBreadfail, "read Empty");
//            return;
//        }
//        strstr(ubuffer->data(), "")
//    }
//    else{
//        sockT->close();
//        func(-err.value(), err.category().name());
//    }
//}
//#define HTTPEND "\r\n"
//std::string GameSession::createWebRequestData(std::string host, std::string url, std::string uData){
//    std::string strOut;
//    strOut = "POST " + url + " HTTP/1.1" + HTTPEND;
//    strOut += "Host: " + host + HTTPEND;
//    strOut += "Connection: keep-alive "   	        HTTPEND;
//    strOut += "Content-Length:" + uData.length();
//    strOut += HTTPEND;
//    strOut += "Accept-Encoding:gzip, deflate"   HTTPEND;
//    strOut += "Accept-Language:zh-CN,en,*"    HTTPEND;
//    strOut += "Content-Type:application/x-www-form-urlencoded; charset=UTF-8"  HTTPEND;
//    strOut += "User-Agent: Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17 SE 2.X MetaSr 1.0"  HTTPEND;
//    strOut += uData.empty() ? "" : uData + HTTPEND;
//    strOut += HTTPEND;
//    return strOut;
//}

/*"POST /check HTTP/1.1\r\n"
"host:tmalarm.vemic.com\r\n"
"Connection:Keep-Alive\r\n"
"Accept-Encoding:gzip, deflate\r\n"
"Accept-Language:zh-CN,en,*\r\n"
"Content-Length:114\r\n"
"Content-Type:application/x-www-form-urlencoded; charset=UTF-8\r\n"
"User-Agent:Mozilla/5.0\r\n\r\n"
"请求数据\r\n\r\n";*/