#pragma once

#include "perinclude.h"
#include "common_enum_define.pb.h"
#include "GmManager.h"


class GmAndroidOpt : public GmBase
{
public:
	GmAndroidOpt() 
		: opt_type_(GM_ANDROID_ADD_ACTIVE)
		, room_id_(1)
		, num_(1)
	{}
	virtual ~GmAndroidOpt() {}

	virtual void exe();

	void set_opt_type(int opt_type)
	{
		opt_type_ = opt_type;
	}

	void set_room_id(int room_id)
	{
		room_id_ = room_id;
	}

	void set_num(int num)
	{
		num_ = num;
	}

protected:
	int										opt_type_;
	int										room_id_;
	int										num_;
};

class GameGmManager : public GmManager
{
public:
	GameGmManager();

	virtual ~GameGmManager();

	virtual bool gm_command(std::vector<std::string>& vc);
};
