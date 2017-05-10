#include "GameDBSession.h"
#include "GameSession.h"
#include "GameLog.h"
#include "BaseGameServer.h"

GameDBSession::GameDBSession(boost::asio::io_service& ioservice)
	: NetworkConnectSession(ioservice)
	, dispatcher_manager_(nullptr)
{
}

GameDBSession::~GameDBSession()
{
}

bool GameDBSession::on_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
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
		LOG_ERR("msg[%d] not registered", header->id);
		return true;
	}

	return dispatcher->parse(this, header);
}

bool GameDBSession::on_connect()
{
	LOG_INFO("game->db connect success ... [%s:%d]", ip_.c_str(), port_);

	dispatcher_manager_ = GameSessionManager::instance()->get_dispatcher_manager_db();

	S_Connect msg;
	msg.set_type(ServerSessionFromGame);
	msg.set_server_id(static_cast<BaseGameServer*>(BaseServer::instance())->get_config().game_id());
	send_pb(&msg);

	GameSessionManager::instance()->set_first_connect_db();

	return NetworkConnectSession::on_connect();
}

void GameDBSession::on_connect_failed()
{
	LOG_INFO("game->db connect failed ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_connect_failed();
}

void GameDBSession::on_closed()
{
	LOG_INFO("game->db disconnect ... [%s:%d]", ip_.c_str(), port_);

	NetworkConnectSession::on_closed();
}
