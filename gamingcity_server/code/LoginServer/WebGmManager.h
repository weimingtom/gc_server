#pragma once

#include "Singleton.h"
#include "msg_server.pb.h"

class WebGm
{
public:
	WebGm(int id) : id_(id) {}
	virtual ~WebGm() {}

	virtual int get_id() { return id_; }
protected:
	int								id_;
};

class WebGmGameServerInfo : public WebGm
{
public:
	WebGmGameServerInfo(int id, int count);
	virtual ~WebGmGameServerInfo();

	bool add_info(WebGameServerInfo* info);

	LW_ResponseGameServerInfo* get_msg() { return &msg_; }
private:
	int								count_;
	LW_ResponseGameServerInfo		msg_;
};

class WebGmManager : public TSingleton<WebGmManager>
{
public:
	WebGmManager();

	~WebGmManager();

	void addWebGm(WebGm* p);

	void removeWebGm(WebGm* p);

	WebGm* getWebGm(int id);

private:
	std::map<int, WebGm*>			web_gm_;
};
