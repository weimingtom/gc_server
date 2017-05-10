#include "GmConfig.h"
#include <fstream>
#include "rapidjson/document.h"
#include "rapidjson/writer.h"
#include "rapidjson/stringbuffer.h"


GmConfig::GmConfig()
	: cur_attr(0)
{

}

GmConfig::~GmConfig()
{

}

std::pair<std::string, int> GmConfig::get_login_attr()
{
	if (cur_attr >= login_attr.size())
	{
		cur_attr = 0;
	}
	return login_attr[cur_attr];
}
std::pair<std::string, int> GmConfig::get_cfg_attr()
{
    if (cur_attr >= cfg_attr.size())
    {
        cur_attr = 0;
    }
    return cfg_attr[cur_attr];
}

bool GmConfig::load_file(const char* filename, std::string& out)
{
	std::ifstream file(filename);
	if (!file.is_open())
	{
		printf("open %s failed\n", filename);
		return false;
	}

	std::string str((std::istreambuf_iterator<char>(file)),
		std::istreambuf_iterator<char>());

	out.swap(str);
	return true;
}


bool GmConfig::load()
{
	return load_cfg();
}

bool GmConfig::load_cfg()
{
	std::string str;
	if (!load_file("../config/GmServerConfig.json", str))
		return false;

	rapidjson::Document document;
	document.Parse(str.c_str());

	http_addr = document["ip"].GetString();
	http_port = (unsigned short)document["port"].GetInt();
	size_t sz = document["login"].Size();
	for (size_t i = 0; i < sz; i++)
	{
		std::string ip = document["login"][i]["ip"].GetString();
		int port = document["login"][i]["port"].GetInt();
		login_attr.push_back(std::make_pair(ip, port));
    }
    sz = document["cfg"].Size();
    for (size_t i = 0; i < sz; i++)
    {
        std::string ip = document["cfg"][i]["ip"].GetString();
        int port = document["cfg"][i]["port"].GetInt();
        cfg_attr.push_back(std::make_pair(ip, port));
    }

	return true;
}
