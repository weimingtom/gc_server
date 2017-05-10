#include "NetworkServer.h"
#include "GameLog.h"

NetworkAllocator::NetworkAllocator()
	: network_server_(nullptr)
{
}

NetworkAllocator::~NetworkAllocator()
{
	assert(session_.empty());
}

void NetworkAllocator::close_all_session()
{
	std::lock_guard<std::recursive_mutex> lock(mutex_);

	for (auto item : session_)
	{
		item.second->close();
	}
}

void NetworkAllocator::release_all_session()
{
	LOG_INFO("release session");
	std::lock_guard<std::recursive_mutex> lock(mutex_);

	for (auto item : session_)
	{
		item.second->on_closed();
	}

	session_.clear();
}

bool NetworkAllocator::tick()
{
	std::lock_guard<std::recursive_mutex> lock(mutex_);

	for (auto it = session_.begin(); it != session_.end();)
	{
		if (it->second->tick())
		{
			++it;
		}
		else
		{
			session_.erase(it++);
		}
	}

	bool ret = true;
	for (auto item : session_)
	{
		if (!item.second->dispatch())
			ret = false;
	}

	return ret;
}

std::shared_ptr<NetworkSession> NetworkAllocator::alloc(boost::asio::ip::tcp::socket& socket)
{
	std::shared_ptr<NetworkSession> p = create_session(socket);

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	session_.insert(std::make_pair(p->get_id(), p));

	return p;
}

void NetworkAllocator::set_network_server(NetworkServer* network_server)
{
	network_server_ = network_server;
}

std::shared_ptr<NetworkSession> NetworkAllocator::find_by_id(int id)
{
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	auto it = session_.find(id);
	if (it != session_.end())
		return it->second;
	return std::shared_ptr<NetworkSession>();
}

std::shared_ptr<NetworkSession> NetworkAllocator::find_by_server_id(int server_id)
{
    std::lock_guard<std::recursive_mutex> lock(mutex_);

    for (auto session : session_)
    {
        if (session.second->get_server_id() == server_id)
        {
            return session.second;
        }
    }
    return std::shared_ptr<NetworkSession>();
}
//////////////////////////////////////////////////////////////////////////

NetworkServer::NetworkServer(unsigned short port, size_t threadCount, NetworkAllocator* pAllocator)
	: io_service_pool_(threadCount)
	, acceptor_(io_service_pool_.get_io_service(), boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v4(), port))
	, socket_(io_service_pool_.get_io_service())
	, allocator_(pAllocator)
{
	assert(pAllocator);
	allocator_->set_network_server(this);

	do_accept();
}

NetworkServer::~NetworkServer()
{
}

void NetworkServer::run()
{
	io_service_pool_.start();
}

void NetworkServer::join()
{
	io_service_pool_.join();
}

void NetworkServer::stop()
{
	io_service_pool_.stop();
}

void NetworkServer::do_accept()
{
	acceptor_.async_accept(socket_,
		[this](boost::system::error_code ec) {
		if (!ec)
		{
			std::shared_ptr<NetworkSession> new_session = allocator_->alloc(socket_);
			new_session->start();

			socket_ = boost::asio::ip::tcp::socket(io_service_pool_.get_io_service());
		}

		do_accept();
	});
}
