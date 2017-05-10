#include "NetworkSession.h"
#include <boost/bind.hpp>
#include "GameLog.h"
#include "BaseServer.h"
#include "msg_server.pb.h"

NetworkSession::NetworkSession(boost::asio::io_service& ioservice)
	: socket_(ioservice)
	, sending_(false)
	, id_(0)
	, last_msg_time_(0)
{
}

NetworkSession::NetworkSession(boost::asio::ip::tcp::socket& sock)
	: socket_(std::move(sock))
	, sending_(false)
	, id_(0)
	, last_msg_time_(0)
{
	id_ = (socket_.native());
}

NetworkSession::~NetworkSession()
{
	for (auto p : buf2_write_)
	{
		delete p;
	}
	for (auto p : buf2_read_)
	{
		delete p;
	}
	buf2_write_.clear();
	buf2_read_.clear();
}

void NetworkSession::start()
{
	reset();

	if (!on_accept())
	{
		do_close();
		return;
	}

	boost::asio::async_read(socket_,
		boost::asio::buffer(recv_buf_.data(), recv_buf_.remain()),
		boost::asio::transfer_at_least(sizeof(MsgHeader)),
		boost::bind(&NetworkSession::handle_read, shared_from_this(),
		boost::asio::placeholders::error,
		boost::asio::placeholders::bytes_transferred));
}

bool NetworkSession::connect(const char* ip, unsigned short port)
{
	boost::system::error_code error;
	boost::asio::ip::tcp::endpoint endpoint(boost::asio::ip::address::from_string(ip, error), port);

	if (error)
	{
		LOG_WARN("ip = %s, port = %d", ip, port);
		return false;
	}

	socket_.async_connect(endpoint,
		[this](boost::system::error_code ec) {
		if (!ec)
		{
			reset();

			if (!on_connect())
			{
				do_close();
				return;
			}

			boost::asio::async_read(socket_,
				boost::asio::buffer(recv_buf_.data(), recv_buf_.remain()),
				boost::asio::transfer_at_least(sizeof(MsgHeader)),
				boost::bind(&NetworkSession::handle_read, shared_from_this(),
				boost::asio::placeholders::error,
				boost::asio::placeholders::bytes_transferred));
		}
		else
		{
			on_connect_failed();
			do_close();
		}
	});

	return true;
}

bool NetworkSession::tick()
{
	if (socket_.is_open())
	{
		// 超时
		if (last_msg_time_ == 0)
		{
			last_msg_time_ = GameTimeManager::instance()->get_second_time();
		}
		else if (GameTimeManager::instance()->get_second_time() - last_msg_time_ > MSG_TIMEOUT_LIMIT)
		{
			std::string ip;
			unsigned short port = get_remote_ip_port(ip);
			LOG_WARN("time out close socket, ip[%s] port[%d]", ip.c_str(), port);
			socket_.close();
			return true;
		}

		post();
		return true;
	}

	LOG_INFO("tick socket closed");
	on_closed();
	return false;
}

bool NetworkSession::send(MsgHeader* msg)
{
	if (nullptr == msg)
		return true;

	if (msg->len < sizeof(MsgHeader) || msg->len > MSG_ONE_BUFFER_SIZE)
	{
		LOG_ERR("send msg buf size error");
		return false;
	}

	return send(msg, msg->len);
}

bool NetworkSession::send(void* data, size_t len)
{
	if (len > MSG_ONE_BUFFER_SIZE - sizeof(MsgHeader))
	{
		LOG_ERR("send msg buf size error");
		return false;
	}

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	if (!socket_.is_open())
		return false;

	if (!write_buf_.push(data, len))
	{
		LOG_WARN("send msg buf is full");
		//close();
		//return false;
		do 
		{
			if (write_buf_.remain() > 0)
			{
				size_t lenbuf = write_buf_.remain();
				if (lenbuf > len)
				{
					lenbuf = len;
				}
				write_buf_.push(data, lenbuf);
				data = static_cast<char*>(data) + lenbuf;
				len -= lenbuf;
			}

			if (!buf2_write_.empty())
			{
				auto p = buf2_write_.back();
				size_t lenbuf = p->remain();
				if (lenbuf > len)
				{
					lenbuf = len;
				}

				p->push(data, lenbuf);
				data = static_cast<char*>(data)+lenbuf;
				len -= lenbuf;
				if (len == 0)
					break;
			}

			auto p = new MsgWirteBuffer;
			buf2_write_.push_back(p);

			p->push(data, len);
		} while (false);
	}

	return true;
}

bool NetworkSession::send_spb(unsigned short id, const std::string& pb)
{
	MsgHeader msg;
	msg.id = id;
	msg.len = sizeof(MsgHeader) + pb.size();

	if (BaseServer::instance())
		BaseServer::instance()->send_statistics(id, sizeof(msg) + pb.size());

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	if (!send(&msg, sizeof(MsgHeader)))
		return false;

	return pb.empty() || send(const_cast<char*>(pb.c_str()), pb.size());
}

bool NetworkSession::send_c_spb(int guid, unsigned short id, const std::string& pb)
{
	GateMsgHeader msg;
	msg.id = id;
	msg.guid = guid;
	msg.len = sizeof(GateMsgHeader) + pb.size();

	if (BaseServer::instance())
		BaseServer::instance()->send_statistics(id, sizeof(msg) + pb.size());

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	if (!send(&msg, sizeof(GateMsgHeader)))
		return false;

	return pb.empty() || send(const_cast<char*>(pb.c_str()), pb.size());
}

bool NetworkSession::send_cx(int guid, MsgHeader* header)
{
	GateMsgHeader msg;
	msg.id = header->id;
	msg.guid = guid;
	msg.len = header->len + sizeof(GateMsgHeader) - sizeof(MsgHeader);

	if (BaseServer::instance())
		BaseServer::instance()->send_statistics(msg.id, msg.len);

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	if (!send(&msg, sizeof(GateMsgHeader)))
		return false;

	if (header->len <= sizeof(MsgHeader))
		return true;

	return send(header + 1, header->len - sizeof(MsgHeader));
}

bool NetworkSession::send_xc(GateMsgHeader* header)
{
	MsgHeader msg;
	msg.id = header->id;
	msg.len = header->len + sizeof(MsgHeader) - sizeof(GateMsgHeader);

	if (BaseServer::instance())
		BaseServer::instance()->send_statistics(msg.id, msg.len);

	std::lock_guard<std::recursive_mutex> lock(mutex_);

	if (!send(&msg, sizeof(MsgHeader)))
		return false;

	if (header->len <= sizeof(GateMsgHeader))
		return true;

	return send(header + 1, header->len - sizeof(GateMsgHeader));
}

void NetworkSession::post()
{
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		
		if (!buf2_write_.empty())
		{
			auto p = buf2_write_.front();
			size_t len = write_buf_.remain();
			if (len > p->size())
			{
				len = p->size();
			}

			write_buf_.push(p->data(), len);
			p->move(len);
			if (p->empty())
			{
				delete p;
				buf2_write_.pop_front();
			}
		}

		if (write_buf_.empty() || send_buf_.remain() == 0)
		{
			// 没有要写入的数据
			return;
		}

		size_t len = send_buf_.remain();
		if (len > write_buf_.size())
		{
			len = write_buf_.size();
		}

		send_buf_.push(write_buf_.data(), len);

		write_buf_.move(len);
	}

	if (socket_.is_open())
	{
		socket_.get_io_service().post(boost::bind(&NetworkSession::do_write, shared_from_this()));
	}
}

bool NetworkSession::dispatch()
{
	size_t read_size = 0;
	size_t cur = 0;
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		if (!buf2_read_.empty())
		{
			auto p = buf2_read_.front();
			size_t len = read_buf_.remain();
			if (len > p->size())
			{
				len = p->size();
			}

			read_buf_.push(p->data(), len);
			p->move(len);
			if (p->empty())
			{
				delete p;
				buf2_read_.pop_front();
			}
		}

		read_size = read_buf_.size();
	}

	bool ret = false;
	for (int i = 0; i < DO_RECVMSG_PER_TICK_LIMIT; i++)
	{
		if (read_size - cur < sizeof(MsgHeader))
		{
			break;
		}

		MsgHeader* msg = reinterpret_cast<MsgHeader*>(read_buf_.data() + cur);

		if (msg->len > MSG_ONE_BUFFER_SIZE)
		{
			// 消息太长，应该错误了
			LOG_ERR("recv msg buf size error:%d", msg->len);
			close();
			return true;
		}

		if (msg->len > read_size - cur)
		{
			ret = true;
			break;
		}

		if (BaseServer::instance())
			BaseServer::instance()->recv_statistics(msg->id, msg->len);

		DWORD t0 = GetTickCount();
		if (!on_dispatch(msg))
		{
			LOG_ERR("onDispatch error, id=%d, len=%d", msg->id, msg->len);
			close();
			return true;
		}
		DWORD t = GetTickCount();
		if (t - t0 >= SERVER_TICK_TIMEOUT_GUARD)
		{
			LOG_WARN("tick guard net dispatch:%d,id:%d", t - t0, msg->id);
		}
		
		// 更新计时
		last_msg_time_ = GameTimeManager::instance()->get_second_time();

		cur += msg->len;
	}

	if (cur > 0)
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		read_buf_.move(cur);
	}

	return true;
}

bool NetworkSession::on_dispatch(MsgHeader* header)
{
	if (header->id == S_Heartbeat::ID)
	{
		send(header);

		return true;
	}
	
	return false;
}

void NetworkSession::close()
{
	if (socket_.is_open())
	{
		socket_.get_io_service().post(boost::bind(&NetworkSession::do_close, shared_from_this()));
	}
}


unsigned short NetworkSession::get_local_ip_port(std::string& ip)
{
	boost::system::error_code error;
	boost::asio::ip::tcp::endpoint ep = socket_.local_endpoint(error);
	if (error)
	{
		LOG_ERR("endpoint error");
		return 0;
	}

	ip = ep.address().to_v4().to_string(error);
	if (error)
	{
		LOG_ERR("ip error");
		return 0;
	}

	return ep.port();
}

unsigned short NetworkSession::get_remote_ip_port(std::string& ip)
{
	boost::system::error_code error;
	boost::asio::ip::tcp::endpoint ep = socket_.remote_endpoint(error);
	if (error)
	{
		LOG_ERR("endpoint error");
		return 0;
	}

	ip = ep.address().to_v4().to_string(error);
	if (error)
	{
		LOG_ERR("ip error");
		return 0;
	}

	return ep.port();
}

void NetworkSession::start_read()
{
	boost::asio::async_read(socket_,
		boost::asio::buffer(recv_buf_.data(), recv_buf_.remain()),
		boost::asio::transfer_at_least(sizeof(MsgHeader)),
		boost::bind(&NetworkSession::handle_read, shared_from_this(),
		boost::asio::placeholders::error,
		boost::asio::placeholders::bytes_transferred));
}

void NetworkSession::handle_read(const boost::system::error_code& error, size_t bytes_transferred)
{
	if (!error)
	{
		{
			std::lock_guard<std::recursive_mutex> lock(mutex_);
			
			if (!recv_buf_.add(bytes_transferred))
			{
				LOG_ERR("recv is full");
				do_close();
				return;
			}

			// 写入的数据
			if (!recv_buf_.empty())
			{
				do 
				{
					if (read_buf_.remain() > 0)
					{
						size_t len = read_buf_.remain();
						if (len > recv_buf_.size())
						{
							len = recv_buf_.size();
						}

						read_buf_.push(recv_buf_.data(), len);
						recv_buf_.move(len);
						if (recv_buf_.empty())
							break;
					}

					if (!buf2_read_.empty())
					{
						auto p = buf2_read_.back();
						size_t len = p->remain();
						if (len > recv_buf_.size())
						{
							len = recv_buf_.size();
						}

						p->push(recv_buf_.data(), len);
						recv_buf_.move(len);
						if (recv_buf_.empty())
							break;
					}

					auto p = new MsgReadBuffer;
					buf2_read_.push_back(p);

					p->push(recv_buf_.data(), recv_buf_.size());
					recv_buf_.clear();
				} while (false);
			}
		}

		boost::asio::async_read(socket_,
			boost::asio::buffer(recv_buf_.data(), recv_buf_.remain()),
			boost::asio::transfer_at_least(1),
			boost::bind(&NetworkSession::handle_read, shared_from_this(),
			boost::asio::placeholders::error,
			boost::asio::placeholders::bytes_transferred));
	}
	else
	{
		LOG_WARN(error.message().c_str());

		do_close();
	}
}

void NetworkSession::do_write()
{
	if (!sending_ && !send_buf_.empty())
	{
		boost::asio::async_write(socket_,
			boost::asio::buffer(send_buf_.data(), send_buf_.size()),
			boost::bind(&NetworkSession::handle_write, shared_from_this(),
			boost::asio::placeholders::error,
			boost::asio::placeholders::bytes_transferred));

		sending_ = true;
	}
}

void NetworkSession::handle_write(const boost::system::error_code& error, size_t bytes_transferred)
{
	if (!error)
	{
		if (bytes_transferred < send_buf_.size())
		{
			{
				std::lock_guard<std::recursive_mutex> lock(mutex_);

				send_buf_.move(bytes_transferred);
			}

			boost::asio::async_write(socket_,
				boost::asio::buffer(send_buf_.data(), send_buf_.size()),
				boost::bind(&NetworkSession::handle_write, shared_from_this(),
				boost::asio::placeholders::error,
				boost::asio::placeholders::bytes_transferred));
		}
		else if (bytes_transferred == send_buf_.size())
		{
			{
				std::lock_guard<std::recursive_mutex> lock(mutex_);

				send_buf_.move(bytes_transferred);

				
				if (!write_buf_.empty() && send_buf_.remain() > 0)
				{
					// 写入的数据
					size_t len = send_buf_.remain();
					if (len > write_buf_.size())
					{
						len = write_buf_.size();
					}

					send_buf_.push(write_buf_.data(), len);

					write_buf_.move(len);
				}

				if (send_buf_.empty())
				{
					// 发送完了
					sending_ = false;
					return;
				}
			}

			boost::asio::async_write(socket_,
				boost::asio::buffer(send_buf_.data(), send_buf_.size()),
				boost::bind(&NetworkSession::handle_write, shared_from_this(),
				boost::asio::placeholders::error,
				boost::asio::placeholders::bytes_transferred));
		}
		else
		{
			do_close();
		}
	}
	else
	{
		do_close();
	}
}

void NetworkSession::do_close()
{
	if (socket_.is_open())
	{
		socket_.close();
		//on_closed();
	}
}

void NetworkSession::reset()
{
	std::lock_guard<std::recursive_mutex> lock(mutex_);

	sending_ = false;

	send_buf_.clear(); 
	recv_buf_.clear(); 
	write_buf_.clear();
	read_buf_.clear(); 
}