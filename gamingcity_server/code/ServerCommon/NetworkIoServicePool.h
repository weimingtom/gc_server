#pragma once

#include "perinclude.h"

/**********************************************************************************************//**
 * \class	NetworkIoServicePool
 *
 * \brief	参考libs\asio\example\cpp03\http\server2\io_service_pool.hpp实现多线程.
 **************************************************************************************************/

class NetworkIoServicePool
	: public boost::noncopyable
{
public:

	/**********************************************************************************************//**
	 * \brief	Constructor.
	 *
	 * \param	pool_size	Size of the pool.
	 **************************************************************************************************/

	explicit NetworkIoServicePool(size_t pool_size);

	/**********************************************************************************************//**
	 * \brief	开始运行线程.
	 **************************************************************************************************/

	void start();

	/**********************************************************************************************//**
	 * \brief	等待相关线程关闭.
	 **************************************************************************************************/

	void join();

	/**********************************************************************************************//**
	 * \brief	结束.
	 **************************************************************************************************/

	void stop();

	/**********************************************************************************************//**
	 * \brief	Gets io_service.
	 *
	 * \return	The io_service.
	 **************************************************************************************************/

	boost::asio::io_service& get_io_service();

private:
	typedef std::shared_ptr<boost::asio::io_service> io_service_sptr;
	typedef std::shared_ptr<boost::asio::io_service::work> work_sptr;
	typedef std::shared_ptr<std::thread> thread_sptr;

	void run(io_service_sptr ioservice);
	void c_run(boost::asio::io_service* ioservice);
	void seh_run(boost::asio::io_service* ioservice);

	std::mutex								mutex_;

	std::vector<io_service_sptr>			io_services_;
	std::vector<work_sptr>					work_;
	std::vector<thread_sptr>				threads_;
	size_t									next_io_service_;

	volatile bool							brun_;
};
