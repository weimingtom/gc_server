#include "NetworkIoServicePool.h"
#include "GameLog.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

NetworkIoServicePool::NetworkIoServicePool(size_t pool_size)
	: next_io_service_(0)
	, brun_(true)
{
	for (size_t i = 0; i < pool_size; ++i)
	{
		io_service_sptr io_service(new boost::asio::io_service);
		work_sptr work(new boost::asio::io_service::work(*io_service));
		io_services_.push_back(io_service);
		work_.push_back(work);
	}
}

void NetworkIoServicePool::start()
{
	for (size_t i = 0; i < io_services_.size(); ++i)
	{
		thread_sptr thread(new std::thread(
			&NetworkIoServicePool::run, this, io_services_[i]));
		threads_.push_back(thread);
	}
}

void NetworkIoServicePool::join()
{
	for (size_t i = 0; i < threads_.size(); ++i)
	{
		threads_[i]->join();
	}
}

void NetworkIoServicePool::stop()
{
	for (size_t i = 0; i < io_services_.size(); ++i)
	{
		io_services_[i]->stop();
	}
	brun_ = false;
}

boost::asio::io_service& NetworkIoServicePool::get_io_service()
{
	std::lock_guard<std::mutex> lock(mutex_);

	boost::asio::io_service& io_service = *io_services_[next_io_service_];
	++next_io_service_;
	if (next_io_service_ == io_services_.size())
	{
		next_io_service_ = 0;
	}
	return io_service;
}

void NetworkIoServicePool::run(io_service_sptr ioservice)
{
	seh_run(ioservice.get());
}

void NetworkIoServicePool::c_run(boost::asio::io_service* ioservice)
{
	try
	{
		boost::system::error_code ec;
		ioservice->run_one(ec);
		if (ec)
		{
			std::string err = ec.message();
			LOG_ERR("%d:%s", ec.value(), err.c_str());
		}
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

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
static int __stdcall seh_net_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	TCHAR szModuleName[MAX_PATH];
	GetModuleFileName(NULL, szModuleName, MAX_PATH);
	WCHAR szFileName[_MAX_FNAME] = L"";
	_wsplitpath_s(szModuleName, NULL, 0, NULL, 0, szFileName, _MAX_FNAME, NULL, 0);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"%s net[%u]_%d-%02d-%02d_%02d-%02d-%02d.dmp", szFileName, GetCurrentThreadId(), tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif

void NetworkIoServicePool::seh_run(boost::asio::io_service* ioservice)
{
	while (brun_)
	{
#ifdef PLATFORM_WINDOWS
	__try
#endif
		{
			c_run(ioservice);
		}
#ifdef PLATFORM_WINDOWS
	__except (seh_net_filter(GetExceptionCode(), GetExceptionInformation()))
	{
		LOG_WARN("__except net thread seh exception\n");
	}
#endif
	}

	LOG_WARN("network thread end, run=%d", brun_);
}
