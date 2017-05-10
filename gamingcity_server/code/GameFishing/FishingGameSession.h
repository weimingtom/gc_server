#pragma once

#include "GameSession.h"
#include "common_msg_fishing.pb.h"

class FishingGameSession : public GameSession
{
public:
	FishingGameSession(boost::asio::ip::tcp::socket& sock);

	virtual ~FishingGameSession();

public:
	void on_cs_time_sync(int guid, CS_TimeSync* msg);
	void on_cs_change_score(int guid, CS_ChangeScore* msg);
	void on_cs_change_cannon_set(int guid, CS_ChangeCannonSet* msg);
	void on_cs_netcast(int guid, CS_Netcast* msg);
	void on_cs_lock_fish(int guid, CS_LockFish* msg);
	void on_cs_fire(int guid, CS_Fire* msg);
	void on_cs_change_cannon(int guid, CS_ChangeCannon* msg);
	void on_cs_treasure_end(int guid, CS_TreasureEnd* msg);
};
