#include "BaseServer.h"
#include <google/protobuf/text_format.h>

BaseServer::BaseServer()
	: is_run_(true)
	, time_statistics_(0)
{
}

BaseServer::~BaseServer()
{
	release();
}

#ifdef PLATFORM_WINDOWS
// linux todo
BOOL WINAPI CtrlHandler(DWORD fdwCtrlType)
{
	switch (fdwCtrlType)
	{
	case CTRL_C_EVENT:
	case CTRL_BREAK_EVENT:
	case CTRL_CLOSE_EVENT:
	case CTRL_LOGOFF_EVENT:
	case CTRL_SHUTDOWN_EVENT:
		if (BaseServer::instance())
			BaseServer::instance()->stop();
		return TRUE;
	}
	return FALSE;
}
#endif

void BaseServer::startup()
{
	if (!init())
	{
		google::protobuf::ShutdownProtobufLibrary();
		return;
	}

#ifdef PLATFORM_WINDOWS
	SetConsoleCtrlHandler(CtrlHandler, TRUE);
#endif

	thread_ = std::thread([this]() {
		run();
		release();

		google::protobuf::ShutdownProtobufLibrary();
	});

	while (is_run_)
	{
#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
		windows_console_.read_console_input();
#endif

#ifdef PLATFORM_WINDOWS
		// linux todo
		Sleep(1);
#endif
	}

	thread_.join();
}

bool BaseServer::init()
{
	game_time_ = std::move(std::unique_ptr<GameTimeManager>(new GameTimeManager));
	game_time_->now();
	game_log_ = std::move(std::unique_ptr<GameLog>(new GameLog));

	//srand((unsigned int)GameTimeManager::instance()->now().get_second_time()); 
#ifdef PLATFORM_WINDOWS
	// linux todo
	srand(GetTickCount());
#endif

	return load_common_config();
}

void BaseServer::run()
{
}

void BaseServer::stop()
{
	is_run_ = false;
}

void BaseServer::release()
{
	game_time_.reset();
	game_log_.reset();
}

void BaseServer::on_gm_command(const char* cmd)
{
}

size_t BaseServer::get_core_count()
{
#ifdef PLATFORM_WINDOWS
	// linux todo
	SYSTEM_INFO si;
	GetSystemInfo(&si);
	return si.dwNumberOfProcessors;
#endif

#ifdef PLATFORM_LINUX
	return 1;
#endif
}

const char* BaseServer::main_lua_file()
{
	assert(false);
	return "";
}


bool BaseServer::load_file(const char* file, std::string& buf)
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

bool BaseServer::load_common_config()
{
	std::string buf;
	if (!load_file("../config/CommonConfig.pb", buf))
		return false;

	if (!google::protobuf::TextFormat::ParseFromString(buf, &common_config_))
	{
		printf("parse CommonConfig failed\n");
		return false;
	}

	printf("load_common_config ok......ip:%s port:%d\n", common_config_.config_addr().ip().c_str(), common_config_.config_addr().port());
	return true;
}

void BaseServer::send_statistics(uint16_t msgid, uint64_t byte_)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_statistics_);

	auto it = send_statistics_.find(msgid);
	if (it != send_statistics_.end())
	{
		++it->second.count_;
		it->second.byte_ += byte_;
	}
	else
	{
		send_statistics_.insert(std::make_pair(msgid, MsgStatistics(1, byte_)));
	}
}

void BaseServer::recv_statistics(uint16_t msgid, uint64_t byte_)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_statistics_);

	auto it = recv_statistics_.find(msgid);
	if (it != recv_statistics_.end())
	{
		++it->second.count_;
		it->second.byte_ += byte_;
	}
	else
	{
		recv_statistics_.insert(std::make_pair(msgid, MsgStatistics(1, byte_)));
	}
}

inline void get_byte(uint64_t v, uint64_t& m, uint64_t& k, uint64_t& n)
{
	n = v & ~0x400;
	v >>= 10;
	k = v & ~0x400;
	m = v >> 10;
}

void BaseServer::print_statistics()
{
	if (time_statistics_ == 0)
	{
		time_statistics_ = GameTimeManager::instance()->get_second_time();
		return;
	}
	if (GameTimeManager::instance()->get_second_time() - time_statistics_ < 300)
	{
		return;
	}
	time_statistics_ = GameTimeManager::instance()->get_second_time();
	
	std::unordered_map<uint16_t, MsgStatistics> t_send_statistics, t_recv_statistics;
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_statistics_);
		t_send_statistics.swap(send_statistics_);
		t_recv_statistics.swap(recv_statistics_);
	}

	if (t_send_statistics.empty() && t_recv_statistics.empty())
		return;

	std::fstream file;
	auto t = GameTimeManager::instance()->get_tm();

	std::string path = str(boost::format(filename_statistics_) % (t->tm_year + 1900) % (t->tm_mon + 1) % t->tm_mday);

	std::string strtime = str(boost::format("[%02d:%02d:%02d]") % t->tm_hour % t->tm_min % t->tm_sec);

	file.open(path.c_str(), std::ios_base::app);

	if (!t_send_statistics.empty())
	{
		file << strtime << "send++++++++++++++++++++++++++++++++++++++++++++\n";
		for (auto& item : t_send_statistics)
		{
			uint64_t m = 0;
			uint64_t k = 0;
			uint64_t n = 0;
			get_byte(item.second.byte_, m, k, n);
			file << "id:" << item.first << ",count:" << item.second.count_ << ",byte:";
			if (m > 0)
				file << m << "M";
			if (k > 0)
				file << k << "K";
			if (n > 0)
				file << n;
			file << std::endl;
		}
	}

	if (!t_recv_statistics.empty())
	{
		file << strtime << "recv--------------------------------------------\n";
		for (auto& item : t_recv_statistics)
		{
			uint64_t m = 0;
			uint64_t k = 0;
			uint64_t n = 0;
			get_byte(item.second.byte_, m, k, n);
			file << "id:" << item.first << ",count:" << item.second.count_ << ",byte:";
			if (m > 0)
				file << m << "M";
			if (k > 0)
				file << k << "K";
			if (n > 0)
				file << n;
			file << std::endl;
		}
	}

	file << "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
}

void BaseServer::set_print_filename(const std::string& filename)
{
	filename_statistics_ = "../log/%d-%d-%d Statistics_" + filename + ".log"; 
}
