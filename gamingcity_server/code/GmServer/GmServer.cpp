// GmServer.cpp : 定义控制台应用程序的入口点。
//

#include "stdafx.h"
#include "PbClientSocket.h"
#include "WebRequestDispatch.h"
#include <string>  
#include <fstream>
#include "GmConfig.h"


int init_win_socket()
{
	WSADATA wsaData;
	if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0)
	{
		return -1;
	}
	return 0;
}

GmConfig g_cfg;
std::string g_php_sign;
#define BUF_MAX 1024 * 16
static char _buf[BUF_MAX];

void post_handler(struct evhttp_request *req, void *arg)
{
	std::string out;

	size_t post_size = EVBUFFER_LENGTH(req->input_buffer);

	if (post_size > 0)
	{
		size_t copy_len = post_size > BUF_MAX ? BUF_MAX : post_size;
		memcpy(_buf, EVBUFFER_DATA(req->input_buffer), copy_len);
		out.assign(_buf, copy_len);
	}

	auto p = evhttp_find_header(req->input_headers, "Content-Type");
	if (nullptr == p)
	{
		printf("Content-Type = null\n");
		return;
	}

	// process posted data
	rapidjson::Document document;
	document.Parse(out.c_str());

	std::string strType = p;
	if (strType == "info")
	{
		webRequestGameServerInfo(out);
	}
    else if (strType == "GMCommand"){
        webRequestGmCommand(document, out);
        printf("ret: [%s]\n", out.c_str());
    }
    else if (strType == "cash")
    {
        webRequestCashFalse(document, out);
    }
    else if (strType == "recharge")
    {
        webRequestRcharge(document, out);
    }
    else if (strType == "changetax")
    {
        webChangeTax(document, out);
    }
    else if (strType == "update-game-cfg")
    {
        webChangeGameCfg(document, out);
    }
	else if (strType == "lua")
	{
		webGmCommandChangeMoney(document, out);
		//printf("ret: [%s]\n", out.c_str());
	}
	else if (strType == "broadcast-client-update-info")
	{
		webBroadcastClientUpdate(document, out);
	}
	else if (strType == "cmd-player-result")
	{
		webLuaCmdPlayerResult(document, out);
	}
	else if (strType == "Maintain-switch")
	{
		webLuaCmdQueryMaintain(document, out);
	}

	struct evbuffer *pe = evbuffer_new();

	evbuffer_add(pe, out.data(), out.size());
	evhttp_send_reply(req, HTTP_OK, "OK", pe);
	evbuffer_free(pe);
}

void WebConectCfg(std::string& out)
{
    printf("WebConectCfg~~~~strat:\n");
    PbClientSocket sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second, false);

    WF_GetCfg msg;
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
    DWORD cur_time = GetTickCount();
    while (flag && GetTickCount() - cur_time < 20000)
    {
        if (sock.recv_msg<FW_GetCfg>([&flag, &out](FW_GetCfg* msg) {
            printf("WebConectCfg~~~~end :%d\n", msg->php_sign());
            out = msg->php_sign().c_str();
            flag = false;
            return true;
        }))
        {
            Sleep(1);
        }
    }

    sock.Destroy();
}
int _tmain(int argc, _TCHAR* argv[])
{
#ifdef WIN32
	init_win_socket();
#endif
	if (!g_cfg.load())
	{
		return -1;
	}

    g_php_sign = "";
	struct event_base * base = event_base_new();

	struct evhttp * http_server = evhttp_new(base);
	if (!http_server)
	{
		return -1;
	}

	int ret = evhttp_bind_socket(http_server, g_cfg.get_http_addr().c_str(), g_cfg.get_http_port());
	if (ret != 0)
	{
		return -1;
	}

	evhttp_set_gencb(http_server, post_handler, NULL);

    //system("pause");
    while (g_php_sign == "")
    {
        WebConectCfg(g_php_sign);
        if (g_php_sign == "")
        {
            Sleep(1000);
        }
    }

	printf("http server start OK! \n");
	event_base_dispatch(base);

	evhttp_free(http_server);

	WSACleanup();
	return 0;
}

