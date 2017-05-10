#pragma once

#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"
#include <iostream>
#include <string>

#include "stdarg.h" 
#define endStr "JudgeParamEnd"
#define judgeJsonMember(ABC,...)  judgeJsonMemberT(ABC,__VA_ARGS__,endStr)

void webRequestGameServerInfo(std::string& out);

void webRequestGmCommand(rapidjson::Document& document, std::string& out);

void webRequestCashFalse(rapidjson::Document& document, std::string& out);

void webRequestRcharge(rapidjson::Document& document, std::string& out);

void webChangeTax(rapidjson::Document& document, std::string& out);

void webChangeGameCfg(rapidjson::Document& document, std::string& out);

void webGmCommandChangeMoney(rapidjson::Document& document, std::string& out);

void webBroadcastClientUpdate(rapidjson::Document& document, std::string& out);

// lua命令，针对玩家，返回结果
void webLuaCmdPlayerResult(rapidjson::Document& document, std::string& out);
//lua命令,不同类型维护开关通知服务器响应
void webLuaCmdQueryMaintain(rapidjson::Document& document, std::string& out);