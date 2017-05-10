#pragma once

#include "GameSessionManager.h"

class FishingGameSessionManager : public GameSessionManager
{
public:
	FishingGameSessionManager();

	virtual ~FishingGameSessionManager();

	virtual std::shared_ptr<NetworkSession> create_session(boost::asio::ip::tcp::socket& socket);
};
