#include "ConfigServerConfigManager.h"
#include "GameLog.h"
#include <google/protobuf/text_format.h>

ConfigServerConfigManager::ConfigServerConfigManager()
{
	cfg_file_name_ = "../config/ConfigServer.pb";
}

ConfigServerConfigManager::~ConfigServerConfigManager()
{

}

bool ConfigServerConfigManager::load_file(const char* file, std::string& buf)
{
	std::ifstream ifs(file, std::ifstream::in);
	if (!ifs.is_open())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	buf = std::string(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
	if (ifs.bad())
	{
		LOG_ERR("load %s failed", file);
		return false;
	}

	return true;
}

bool ConfigServerConfigManager::load_config()
{
	std::string buf;
	if (!load_file(cfg_file_name_.c_str(), buf))
		return false;

	if (!google::protobuf::TextFormat::ParseFromString(buf, &config_))
	{
		LOG_ERR("parse %s failed", cfg_file_name_.c_str());
		return false;
	}

	LOG_INFO("load_config ok......");
	return true;
}
