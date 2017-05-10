#include "NetworkConnectSession.h"
#include "GameTimeManager.h"
#include "GameLog.h"
#include "msg_server.pb.h"


NetworkConnectSession::NetworkConnectSession(boost::asio::io_service& ioservice)
	: NetworkSession(ioservice)
	, resolver_(ioservice)
	, connect_state_(CONNECT_STATE_INVALID)
	, wait_tick_(0)
	, port_(0)
	, last_heartbeat_(0)
{
}

NetworkConnectSession::~NetworkConnectSession()
{
}

bool NetworkConnectSession::connect(const char* ip, unsigned short port)
{
	boost::asio::ip::tcp::resolver::query query_(ip, boost::lexical_cast<std::string>(port));

	connect_impl(resolver_.resolve(query_));

	return true;
}

void NetworkConnectSession::connect_impl(boost::asio::ip::tcp::resolver::iterator it)
{
	boost::asio::async_connect(socket_, it,
		[this](boost::system::error_code ec, boost::asio::ip::tcp::resolver::iterator it)
	{
		if (!ec)
		{
			reset();

			if (!on_connect())
			{
				do_close();
				return;
			}

			start_read();
		}
		else
		{
			boost::asio::ip::tcp::resolver::iterator end;
			if (it != end)
			{
				connect_impl(++it);
			}
			else
			{
				on_connect_failed();
				do_close();
			}
		}
	});
}

bool NetworkConnectSession::on_connect()
{
	connect_state_ = CONNECT_STATE_CONNECTED;
	return true;
}

void NetworkConnectSession::on_connect_failed()
{
	wait_tick_ = GameTimeManager::instance()->get_millisecond_time();
	connect_state_ = CONNECT_STATE_DISCONNECT;
}

void NetworkConnectSession::on_closed()
{
	connect_state_ = CONNECT_STATE_INVALID;

	last_msg_time_ = 0;
	last_heartbeat_ = 0;
}

bool NetworkConnectSession::tick()
{
	bool ret = true;
	if (connect_state_ == CONNECT_STATE_CONNECTED)
	{
		if (socket_.is_open())
		{
			// ³¬Ê±
			if (last_msg_time_ != 0 && GameTimeManager::instance()->get_second_time() - last_msg_time_ > MSG_TIMEOUT_LIMIT)
			{
				LOG_WARN("time out close socket, ip[%s] port[%d]", ip_.c_str(), port_);
				socket_.close();
				return true;
			}

			if (last_heartbeat_ == 0 || GameTimeManager::instance()->get_second_time() - last_heartbeat_ > SERVER_HEARTBEAT_TIME)
			{
				last_heartbeat_ = GameTimeManager::instance()->get_second_time();

				S_Heartbeat msg;
				send_pb(&msg);
			}

			post();
			ret = dispatch();
		}
		else
		{
			LOG_INFO("tick socket closed");
			on_closed();
			connect_state_ = CONNECT_STATE_DISCONNECT;
		}
	}
	else
	{
		int old_state = connect_state_.load();
		if (old_state == CONNECT_STATE_INVALID)
		{
			if (connect(ip_.c_str(), port_))
			{
				connect_state_.compare_exchange_weak(old_state, CONNECT_STATE_CONNECTING);
			}
		}
		else if (old_state == CONNECT_STATE_DISCONNECT)
		{
			auto cur = GameTimeManager::instance()->get_millisecond_time();
			if (cur - wait_tick_ >= 5000)
			{
				if (connect(ip_.c_str(), port_))
				{
					connect_state_.compare_exchange_weak(old_state, CONNECT_STATE_CONNECTING);
				}
			}
		}
	}

	return ret;
}

void NetworkConnectSession::set_ip_port(const std::string& ip, unsigned short port)
{
	ip_ = ip;
	port_ = port;
}
