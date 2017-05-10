#include "FishingGameSessionManager.h"
#include "FishingGameSession.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#define REG_GATE_DISPATCHER(Msg, Function) dispatcher_manager_gate_.register_dispatcher(new GateMsgDispatcher< Msg, FishingGameSession >(&FishingGameSession::Function));

FishingGameSessionManager::FishingGameSessionManager()
{
	REG_GATE_DISPATCHER(CS_TimeSync, on_cs_time_sync);
	REG_GATE_DISPATCHER(CS_ChangeScore, on_cs_change_score);
	REG_GATE_DISPATCHER(CS_ChangeCannonSet, on_cs_change_cannon_set);
	REG_GATE_DISPATCHER(CS_Netcast, on_cs_netcast);
	REG_GATE_DISPATCHER(CS_LockFish, on_cs_lock_fish);
	REG_GATE_DISPATCHER(CS_Fire, on_cs_fire);
	REG_GATE_DISPATCHER(CS_ChangeCannon, on_cs_change_cannon);
	REG_GATE_DISPATCHER(CS_TreasureEnd, on_cs_treasure_end);
}

FishingGameSessionManager::~FishingGameSessionManager()
{
}

std::shared_ptr<NetworkSession> FishingGameSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<FishingGameSession>(socket));
}
