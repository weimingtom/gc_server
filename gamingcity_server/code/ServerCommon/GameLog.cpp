#include "GameLog.h"
#include "GameTimeManager.h"
#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
#include "WindowsConsole.h"
#endif


#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG


GameLog::GameLog()
	: tomorrow_(0)
{
}

GameLog::~GameLog()
{
}

void GameLog::init(const std::string& logname)
{
	log_name_ = logname;
}

void GameLog::calc_tomorrow()
{
	tm t = *GameTimeManager::instance()->get_tm();
	++t.tm_mday;
	t.tm_hour = 0;
	t.tm_min = 0;
	t.tm_sec = 0;
	tomorrow_ = mktime(&t);
}

void GameLog::open_log_file()
{
	assert(!log_name_.empty());

	calc_tomorrow();

	auto ptm = GameTimeManager::instance()->get_tm();
	char path[MAX_PATH] = { 0 };
#ifdef PLATFORM_WINDOWS
	sprintf_s(path, log_name_.c_str(), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday);
#else
	sprintf(path, log_name_.c_str(), ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday);
#endif

	log_file_.close();
	log_file_.open(path, std::ofstream::app);
	assert(log_file_.is_open() && !log_file_.bad());
}

void GameLog::log_info(const char* file, int line, const char* func, const char* fmt, ...)
{
	char str[2048] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 2047, fmt, arg);
#else
	vsnprintf(str, 2047, fmt, arg);
#endif
	va_end(arg);

	log(LOG_TYPE_INFO, file, line, func, str);
}

void GameLog::log_error(const char* file, int line, const char* func, const char* fmt, ...)
{
	char str[2048] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 2047, fmt, arg);
#else
	vsnprintf(str, 2047, fmt, arg);
#endif
	va_end(arg);

	log(LOG_TYPE_ERROR, file, line, func, str);
}

void GameLog::log_warning(const char* file, int line, const char* func, const char* fmt, ...)
{
	char str[2048] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 2047, fmt, arg);
#else
	vsnprintf(str, 2047, fmt, arg);
#endif
	va_end(arg);

	log(LOG_TYPE_WARNING, file, line, func, str);
}

void GameLog::log_debug(const char* file, int line, const char* func, const char* fmt, ...)
{
	char str[2048] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 2047, fmt, arg);
#else
	vsnprintf(str, 2047, fmt, arg);
#endif
	va_end(arg);

	log(LOG_TYPE_DEBUG, file, line, func, str);
}

void GameLog::log_string(LOG_TYPE type, const char* log)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_);

#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
	switch (type)
	{
	case LOG_TYPE_DEBUG:
		WindowsConsole::instance()->write_console(FOREGROUND_INTENSITY | FOREGROUND_GREEN | FOREGROUND_BLUE, log);
		break;
	case LOG_TYPE_WARNING:
		WindowsConsole::instance()->write_console(FOREGROUND_INTENSITY | FOREGROUND_RED | FOREGROUND_GREEN, log);
		break;
	case LOG_TYPE_ERROR:
		WindowsConsole::instance()->write_console(FOREGROUND_INTENSITY | FOREGROUND_RED, log);
		break;
	case LOG_TYPE_INFO:
		WindowsConsole::instance()->write_console(FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE, log);
		break;
	}
#else
	printf(log);
#endif


	if (!log_file_.is_open() || GameTimeManager::instance()->get_second_time() >= tomorrow_)
		open_log_file();

	log_file_ << log << std::flush;
}

void GameLog::log(LOG_TYPE type, const char* file, int line, const char* func, const char* str)
{
	std::string buf(file);
	size_t nPos = buf.find_last_of("/\\");
	if (nPos != std::string::npos)
	{
		file = buf.c_str() + nPos + 1;
	}

	auto ptm = GameTimeManager::instance()->get_tm();
	char strdate[100] = { 0 };
#ifdef PLATFORM_WINDOWS
	sprintf_s(strdate, "[%d-%02d-%02d %02d:%02d:%02d]", ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
#else
	sprintf(strdate, "[%d-%02d-%02d %02d:%02d:%02d]", ptm->tm_year + 1900, ptm->tm_mon + 1, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec);
#endif

	std::stringstream ss;
	ss << strdate;
	switch (type)
	{
	case LOG_TYPE_DEBUG:
		ss << "DEBUG: ";
		break;
	case LOG_TYPE_WARNING:
		ss << "WARN: ";
		break;
	case LOG_TYPE_ERROR:
		ss << "ERRER: ";
		break;
	case LOG_TYPE_INFO:
		ss << "INFO: ";
		break;
	}

	ss << str << "(" << file << ":" << line << "[" << func << "])\n";
	buf = ss.str();


	std::lock_guard<std::recursive_mutex> lock(mutex_);

	log_string(type, buf.c_str());
}
