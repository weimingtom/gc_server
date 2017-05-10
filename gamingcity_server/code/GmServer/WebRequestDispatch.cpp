#include "WebRequestDispatch.h"
#include "PbClientSocket.h"
#include "GmConfig.h"
#include "UtilsHelper.h"
#include <boost/format.hpp>

extern GmConfig g_cfg;
extern std::string g_php_sign;
void webRequestGameServerInfo(std::string& out)
{
	PbClientSocket sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);

	WL_RequestGameServerInfo msg;
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ResponseGameServerInfo>([&flag, &out](LW_ResponseGameServerInfo* msg) {
			rapidjson::Document document;
			document.SetArray();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			for (auto& item : msg->info_list())
			{
				rapidjson::Value object(rapidjson::kObjectType);
				object.AddMember("cpu", item.cpu(), allocator);
				object.AddMember("memory", item.memory(), allocator);
				object.AddMember("status", item.status(), allocator);
				rapidjson::Value strObject(rapidjson::kStringType);
				strObject.SetString(item.ip().c_str(), allocator);
				object.AddMember("ip", strObject, allocator);
				object.AddMember("port", item.port(), allocator);
				object.AddMember("first_game_type", item.first_game_type(), allocator);
				object.AddMember("second_game_type", item.second_game_type(), allocator);
				document.PushBack(object, allocator);
			}

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);


			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
	sock.Destroy();
}

char * utf82gbk(char* strutf)
{
    //utf-8转为Unicode
    int size = MultiByteToWideChar(CP_UTF8, 0, strutf, -1, NULL, 0);
    WCHAR   *strUnicode = new   WCHAR[size];
    MultiByteToWideChar(CP_UTF8, 0, strutf, -1, strUnicode, size);

    //Unicode转换成UTF-8;
    int i = WideCharToMultiByte(CP_ACP, 0, strUnicode, -1, NULL, 0, NULL, NULL);
    char   *strGBK = new   char[i];
    WideCharToMultiByte(CP_ACP, 0, strUnicode, -1, strGBK, i, NULL, NULL);
    return strGBK;
}
void RetOut(int iRet, std::string & out){
    rapidjson::Document document;
    document.SetObject();
    rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
    document.AddMember("result", iRet, allocator);
    rapidjson::StringBuffer buffer;
    rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
    document.Accept(writer);
    out = buffer.GetString();
}

#define endStr "JudgeParamEnd"
#define checkJsonMember(ABC,...)  checkJsonMemberS(ABC,1,__VA_ARGS__,endStr)
#define LOG_ERR printf
bool checkJsonMemberS(rapidjson::Document& document,int start, ...){
    va_list args;
    char * lp = NULL;
    char * lp_type = NULL;
    va_start(args, start);
    do
    {
        lp = va_arg(args, char *);
        if (lp != NULL){
            if (strcmp(lp, endStr) == 0){
                break;
            }
            if (!document.HasMember(lp)){
                LOG_ERR("param [%s] not find", lp);
                return true;
            }
        }
        lp_type = va_arg(args, char *);
        if (lp_type != NULL){
            if (strcmp(lp_type, endStr) == 0){
                break;
            }
            if (strcmp(lp_type, "int") == 0){
                if (!document[lp].IsInt()){
                    return true;
                }
            }
            if (strcmp(lp_type, "int64") == 0){
                if (!document[lp].IsInt64()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "string") == 0){
                if (!document[lp].IsString()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "bool") == 0){
                if (!document[lp].IsBool()){
                    return true;
                }
            }
            else if (strcmp(lp_type, "float") == 0){
                if (!document[lp].IsFloat()){
                    return true;
                }
            }
        }
    } while (true);
    va_end(args);
    return false;
}
void webRequestGmCommand(rapidjson::Document& document, std::string& out){
    PbClientSocket sock;
    printf("%s\n", out.c_str());
    auto attr = g_cfg.get_login_attr();
    if (sock.connect(attr.first.c_str(), attr.second)){
        if (checkJsonMember(document, "Command","string","Data","string","sign","string")){
            RetOut(GMmessageRetCode::GMmessageRetCode_GmParamMiss, out);
            return;
        }

        WL_GMMessage msg;
        msg.set_gmcommand(document["Command"].GetString());
        msg.set_data(document["Data"].GetString());


        //校验
        std::string stmpA = "";
        std::string stmpB = "";
        std::string stmpC = "";
        stmpA = boost::str(boost::format("Command=%1%&Data=%2%%3%") % msg.gmcommand() % msg.data().c_str() % g_php_sign.c_str());
        stmpC = UtilsHelper::md5(stmpA).c_str();
        printf("/n stmp:%s", stmpC);
        stmpB = document["sign"].GetString();
        printf("/n stmp:%s", stmpB);
		if (stmpC != stmpB /*&& stmpB != "testABCA#$%^&@!#"*/)
        {
            out = "{ \"result\" : 0 }";
            return;
        }

        sock.send_pb(&msg);
        sock.Flush();

        volatile bool flag = true;
		DWORD cur_time = GetTickCount();
		while (flag && GetTickCount() - cur_time < 20000)
		{
			if (sock.recv_msg<LW_GMMessage>([&flag, &out](LW_GMMessage* msg) {
				printf("===================================:%d\n", msg->result());
				RetOut(msg->result(), out);
				flag = false;
				return true;
			}))
			{
				Sleep(1);
			}
		}
		
        sock.Destroy();
    }
    else {
        RetOut(GMmessageRetCode::GMmessageRetCode_SocketConnectFail, out);
        return;
    }
}

void webRequestCashFalse(rapidjson::Document& document, std::string& out)
{
    printf("webRequestCashFalse~~~~strat: %s\n", out.c_str());
    PbClientSocket sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second);
    if (!document.HasMember("id") || !document["id"].IsInt())
    {
        printf("\n webRequestCashFalsefalse~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }
	if (!document.HasMember("del") || !document["del"].IsInt())
	{
		printf("\n webRequestCashFalsefalse~~~~end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}
    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        printf("\n webChangeGameCfg~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }

    WF_CashFalse msg;
	msg.set_order_id(document["id"].GetInt());
	msg.set_del(document["del"].GetInt());


    //校验
    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("id=%1%%2%") % msg.order_id() % g_php_sign.c_str());
    stmpC = UtilsHelper::md5(stmpA).c_str();
    printf("/n stmp:%s", stmpC);
    stmpB = document["sign"].GetString();
    printf("/n stmp:%s", stmpB);
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
        if (sock.recv_msg<FW_Result>([&flag, &out](FW_Result* msg) {
			printf("webRequestCashFalse~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);


			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
    sock.Destroy();
}

void webRequestRcharge(rapidjson::Document& document, std::string& out)
{
    printf("webRequestRcharge~~~~strat:%s\n", out.c_str());
    PbClientSocket sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second);
    if (!document.HasMember("serial_order_no") || !document["serial_order_no"].IsInt())
    {
        printf("\n webRequestRcharge~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }


    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        printf("\n webChangeGameCfg~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }

    WF_Recharge msg;
    msg.set_order_id(document["serial_order_no"].GetInt());


    //校验
    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("serial_order_no=%1%%2%") % msg.order_id() % g_php_sign.c_str());
    stmpC = UtilsHelper::md5(stmpA).c_str();
    printf("/n stmp:%s", stmpC);
    stmpB = document["sign"].GetString();
    printf("/n stmp:%s", stmpB);
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
        return;
    }
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
        if (sock.recv_msg<FW_Result>([&flag, &out](FW_Result* msg) {
			printf("webRequestRcharge~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
    sock.Destroy();
}

void webChangeTax(rapidjson::Document& document, std::string& out)
{
    printf("webChangeTax~~~~strat:%s\n", out.c_str());
    PbClientSocket sock;
    auto attr = g_cfg.get_login_attr();
    sock.connect(attr.first.c_str(), attr.second);
    if (!document.HasMember("id") || !document["id"].IsInt())
    {
        printf("\n webChangeTax~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }
    if (!document.HasMember("tax") || !document["tax"].IsInt())
    {
        printf("\n webChangeTax~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }

    if (!document.HasMember("is_enable") || !document["is_enable"].IsInt())
    {
        printf("\n webChangeTax~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }

    if (!document.HasMember("is_show") || !document["is_show"].IsInt())
    {
        printf("\n webChangeTax~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }


    WL_ChangeTax msg;
    msg.set_id(document["id"].GetInt());
    msg.set_tax(document["tax"].GetInt());
    msg.set_is_show(document["is_show"].GetInt());
    msg.set_is_enable(document["is_enable"].GetInt());
    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ChangeTax>([&flag, &out](LW_ChangeTax* msg) {
			printf("webChangeTax~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
	
    sock.Destroy();
}

void webChangeGameCfg(rapidjson::Document& document, std::string& out)
{
    printf("webChangeGameCfg~~~~strat:%s\n", out.c_str());
    PbClientSocket sock;
    auto attr = g_cfg.get_cfg_attr();
    sock.connect(attr.first.c_str(), attr.second, false);
    if (!document.HasMember("id") || !document["id"].IsInt())
    {
        printf("\n webChangeGameCfg~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }
    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        printf("\n webChangeGameCfg~~~~end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }

    WF_ChangeGameCfg msg;
    msg.set_id(document["id"].GetInt());


    //校验
    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("id=%1%%2%") % msg.id() % g_php_sign.c_str());
    stmpC = UtilsHelper::md5(stmpA).c_str();
    printf("/n stmp:%s", stmpC);
    stmpB = document["sign"].GetString();
    printf("/n stmp:%s", stmpB);
    if (stmpC != stmpB)
    {
        out = "{ \"result\" : 0 }";
        return;
    }

    sock.send_pb(&msg);
    sock.Flush();

    volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<FW_ChangeGameCfg>([&flag, &out](FW_ChangeGameCfg* msg) {
			printf("webChangeGameCfg~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}
	}
    
    sock.Destroy();
}

void webGmCommandChangeMoney(rapidjson::Document& document, std::string& out)
{
	printf("webChangeMoney~~~~strat:%s\n", out.c_str());
	PbClientSocket sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);
	if (!document.HasMember("guid") || !document["guid"].IsInt())
	{
		printf("\n webChangeMoney~~~~guid end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("GmCommand") || !document["GmCommand"].IsString())
	{
		printf("\n webChangeMoney~~~~GmCommand end :0\n");
		out = "{ \"result\" : 0 }";
		return;
    }

    if (!document.HasMember("sign") || !document["sign"].IsString())
    {
        printf("\n webChangeMoney~~~~GmCommand end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }
	WL_ChangeMoney msg;
	msg.set_guid(document["guid"].GetInt());
	msg.set_gmcommand(document["GmCommand"].GetString());

    //校验
    std::string stmpA = "";
    std::string stmpB = "";
    std::string stmpC = "";
    stmpA = boost::str(boost::format("guid=%1%&GmCommand=%2%%3%") % msg.guid() % msg.gmcommand().c_str() % g_php_sign.c_str());
    stmpC = UtilsHelper::md5(stmpA).c_str();
    printf("/n stmp:%s", stmpC);
    stmpB = document["sign"].GetString();
    printf("/n stmp:%s", stmpB);
    if (stmpC != stmpB)
    {
        printf("\n webChangeMoney~~~~GmCommand end :0\n");
        out = "{ \"result\" : 0 }";
        return;
    }
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ChangeMoney>([&flag, &out](LW_ChangeMoney* msg) {
			printf("webChangeMoney recived~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void webBroadcastClientUpdate(rapidjson::Document& document, std::string& out)
{
	printf("webBroadcastClientUpdate~~~~strat:%s\n", out.c_str());
	PbClientSocket sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);

	if (!document.HasMember("GmCommand") || !document["GmCommand"].IsString())
	{
		printf("\n webBroadcastClientUpdate~~~~GmCommand end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	WL_BroadcastClientUpdate msg;
	msg.set_gmcommand(document["GmCommand"].GetString());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_ClientUpdateResult>([&flag, &out](LW_ClientUpdateResult* msg) {
			printf("webBroadcastClientUpdate recived~~~~end :%d\n", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void webLuaCmdPlayerResult(rapidjson::Document& document, std::string& out)
{
	printf("webLuaCmdPlayerResult~~~~strat:%s\n", out.c_str());
	PbClientSocket sock;
	auto attr = g_cfg.get_login_attr();
	sock.connect(attr.first.c_str(), attr.second);
	if (!document.HasMember("guid") || !document["guid"].IsInt())
	{
		printf("\n webLuaCmdPlayerResult~~~~guid end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("cmd") || !document["cmd"].IsString())
	{
		printf("\n webLuaCmdPlayerResult~~~~GmCommand end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	WL_LuaCmdPlayerResult msg;
	msg.set_guid(document["guid"].GetInt());
	msg.set_cmd(document["cmd"].GetString());
	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<LW_LuaCmdPlayerResult>([&flag, &out](LW_LuaCmdPlayerResult* msg) {
			printf("webLuaCmdPlayerResult recived~~~~end :%d\n", msg->result());
			printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}

void webLuaCmdQueryMaintain(rapidjson::Document& document, std::string& out)
{
	printf("webLuaCmdQueryMaintain~~~~strat:%s\n", out.c_str());
	PbClientSocket sock;
	auto attr = g_cfg.get_cfg_attr();
	sock.connect(attr.first.c_str(), attr.second);


	if (!document.HasMember("id_index") || !document["id_index"].IsInt())
	{
		printf("\n webLuaCmdQueryMaintain~~~~guid end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	if (!document.HasMember("sign") || !document["sign"].IsString())
	{
		printf("\n webChangeGameCfg~~~~end :0\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	WS_MaintainUpdate msg;
	msg.set_id_index(document["id_index"].GetInt());

	//校验
	std::string stmpA = "";
	std::string stmpB = "";
	std::string stmpC = "";
	stmpA = boost::str(boost::format("id_index=%1%%2%") % msg.id_index() % g_php_sign.c_str());
	stmpC = UtilsHelper::md5(stmpA).c_str();
	//printf("/n stmp:%s", stmpC);
	stmpB = document["sign"].GetString();
	//printf("/n stmp:%s", stmpB);
	if (stmpC != stmpB)
	{
		printf("webLuaCmdQueryMaintain sign error.\n");
		out = "{ \"result\" : 0 }";
		return;
	}

	sock.send_pb(&msg);
	sock.Flush();

	volatile bool flag = true;
	DWORD cur_time = GetTickCount();
	while (flag && GetTickCount() - cur_time < 20000)
	{
		if (sock.recv_msg<SW_MaintainResult>([&flag, &out](SW_MaintainResult* msg) {
			printf("SW_MaintainResult recived~~~~end :%d\n", msg->result());
			//printf("%d", msg->result());

			rapidjson::Document document;
			document.SetObject();
			rapidjson::Document::AllocatorType& allocator = document.GetAllocator();
			document.AddMember("result", msg->result(), allocator);

			rapidjson::StringBuffer buffer;
			rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
			document.Accept(writer);

			out = buffer.GetString();

			flag = false;
			return true;
		}))
		{
			Sleep(1);
		}

	}
	sock.Destroy();
}