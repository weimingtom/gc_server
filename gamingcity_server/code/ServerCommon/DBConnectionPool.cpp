#include "DBConnectionPool.h"
#include "GameLog.h"
#include <boost/algorithm/string.hpp>

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

DBConnection* DBConnectionPool::get_db_connection()
{
	if (!con_ptr_.get())
	{
		con_ptr_.reset(new DBConnection);
	}

	return con_ptr_.get();
}

DBConnectionPool::DBConnectionPool()
	: is_run_(true)
{
	work_.reset(new boost::asio::io_service::work(io_service_));
}

DBConnectionPool::~DBConnectionPool()
{
}

std::mutex g_mutex_;

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
static int __stdcall seh_db_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	TCHAR szModuleName[MAX_PATH];
	GetModuleFileName(NULL, szModuleName, MAX_PATH);
	WCHAR szFileName[_MAX_FNAME] = L"";
	_wsplitpath_s(szModuleName, NULL, 0, NULL, 0, szFileName, _MAX_FNAME, NULL, 0);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"%s db[%u]_%d-%02d-%02d_%02d-%02d-%02d.dmp", szFileName, GetCurrentThreadId(), tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void DBConnectionPool::run(size_t thread_count)
{
	for (size_t i = 0; i < thread_count; i++)
	{
		std::shared_ptr<std::thread> thrd(new std::thread([this] {
#ifdef PLATFORM_WINDOWS
			__try
#endif
			{
				run_thread();
			}
#ifdef PLATFORM_WINDOWS
			__except (seh_db_filter(GetExceptionCode(), GetExceptionInformation()))
			{
				printf("db thread seh exception\n");
			}
#endif
		}));
		thread_.push_back(thrd);
	}
}

void DBConnectionPool::run_thread()
{
	while (is_run_)
	{
		std::lock_guard<std::mutex> lock(g_mutex_);

		try
		{
			DBConnection* con = get_db_connection();
			con->connect(host_, user_, password_, database_);
			break;
		}
		catch (const sql::SQLException& e)
		{
			LOG_ERR("sql err[%d]:%s, %s", e.getErrorCode(), e.what(), e.getSQLStateCStr());
#ifdef PLATFORM_WINDOWS
			// linux todo
			Sleep(5000);
#endif
		}
	}
	while (is_run_)
	{
		try
		{
			boost::system::error_code ec;
			io_service_.run_one(ec);
			if (ec)
			{
				std::string err = ec.message();
				LOG_ERR("%d:%s", ec.value(), err.c_str());
			}
		}
		catch (const sql::SQLException& e)
		{
			LOG_ERR("sql err[%d]:%s, %s", e.getErrorCode(), e.what(), e.getSQLStateCStr());
		}
		catch (const std::exception& e)
		{
			LOG_ERR(e.what());
		}
		catch (...)
		{
			LOG_ERR("unknown exception");
		}
	}

	LOG_WARN("db thread end, run=%d", is_run_);

	try
	{
		DBConnection* con = get_db_connection();
		con->close();
	}
	catch (const sql::SQLException& e)
	{
		LOG_ERR("sql err[%d]:%s, %s", e.getErrorCode(), e.what(), e.getSQLStateCStr());
	}
}

void DBConnectionPool::join()
{
	for (auto& item : thread_)
	{
		item->join();
	}
}

void DBConnectionPool::stop()
{
	work_.reset();
	is_run_ = false;
}

bool DBConnectionPool::tick()
{
	bool ret = true;
	std::deque<BaseDBQueryResult*> vc;
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		if (!query_result_.empty())
		{
			if (query_result_.size() <= DO_MYSQL_PER_TICK_LIMIT)
				vc.swap(query_result_);
			else
			{
				for (int i = 0; i < DO_MYSQL_PER_TICK_LIMIT; i++)
				{
					vc.push_back(query_result_.front());
					query_result_.pop_front();
				}
				ret = false;
			}
		}
	}

	for (auto item : vc)
	{
		DWORD t0 = GetTickCount();
		item->on_query_result();
		DWORD t = GetTickCount();
		if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
		{
			LOG_WARN("tick guard db query result:%d,sql:%s", t - t0, item->get_sql());
		}

		delete item;
	}

	return ret;
}

void DBConnectionPool::execute(const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([this, sql] {
		DBConnection* con = get_db_connection();
		con->execute(sql);
	});
}

void DBConnectionPool::execute(const google::protobuf::Message& message, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql;
	google::protobuf::TextFormat::PrintToString(message, &sql);
	boost::algorithm::replace_all(sql, ":", "=");
	boost::algorithm::replace_all(sql, "\n", ",");
	boost::algorithm::trim_if(sql, boost::algorithm::is_any_of(" \t\r\n,"));

	sql = boost::algorithm::replace_all_copy(std::string(str), "$FIELD$", sql);

	io_service_.post([this, sql] {
		DBConnection* con = get_db_connection();
		con->execute(sql);
	});
}

void DBConnectionPool::execute_update(const std::function<void(int)>& func, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		int ret = con->execute_update(sql);

		auto p = new DBQueryUpdateResult(sql, func, ret);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void DBConnectionPool::execute_update(const std::function<void(int)>& func, const google::protobuf::Message& message, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql;
	google::protobuf::TextFormat::PrintToString(message, &sql);
	boost::algorithm::replace_all(sql, ":", "=");
	boost::algorithm::replace_all(sql, "\n", ",");
	boost::algorithm::trim_if(sql, boost::algorithm::is_any_of(" \t\r\n,"));

	sql = boost::algorithm::replace_all_copy(std::string(str), "$FIELD$", sql);

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		int ret = con->execute_update(sql);

		auto p = new DBQueryUpdateResult(sql, func, ret);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void DBConnectionPool::execute_try(const std::function<void(int)>& func, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();
		int ret = con->execute_try(sql);

		auto p = new DBQueryUpdateResult(sql, func, ret);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void DBConnectionPool::execute_update_try(const std::function<void(int, int)>& func, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();
		int ret = 0;
		int err = con->execute_update_try(sql, ret);

		auto p = new DBQueryUpdateTryResult(sql, func, ret, err);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void DBConnectionPool::execute_query_string(const std::function<void(std::vector<std::string>*)>& func, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		std::vector<std::string> str;
		bool ret = con->execute_query_string(str, sql);

		auto p = new DBQueryStringResult(sql, func, ret, str);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}

void DBConnectionPool::execute_query_vstring(const std::function<void(std::vector<std::vector<std::string>>*)>& func, const char* fmt, ...)
{
	char str[4096] = { 0 };

	va_list arg;
	va_start(arg, fmt);
#ifdef PLATFORM_WINDOWS
	_vsnprintf_s(str, 4095, fmt, arg);
#else
	vsnprintf(str, 4095, fmt, arg);
#endif
	va_end(arg);

	std::string sql = str;

	io_service_.post([=] {
		DBConnection* con = get_db_connection();

		std::vector<std::vector<std::string>> str;
		bool ret = con->execute_query_vstring(str, sql);

		auto p = new DBQueryVStringResult(sql, func, ret, str);

		std::lock_guard<std::recursive_mutex> lock(mutex_query_result_);
		query_result_.push_back(p);
	});
}
