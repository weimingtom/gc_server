#include "RedisConnection.h"
#include "CryptoManager.h"
#include "GameLog.h"
#include "RedisConnectionThread.h"


RedisReply::RedisReply(redisReply* r)
{
	copy(r);
}
void RedisReply::copy(redisReply* r)
{
	if (nullptr == r)
	{
		type_ = REDIS_REPLY_NIL;
		return;
	}

	type_ = r->type;
	switch (type_)
	{
	case REDIS_REPLY_NIL:
		/* Nothing... */
		break;
	case REDIS_REPLY_ERROR:
	case REDIS_REPLY_STATUS:
	case REDIS_REPLY_STRING:
		string_.assign(r->str, r->len);
		break;
	case REDIS_REPLY_INTEGER:
		integer_ = r->integer;
		break;
	case REDIS_REPLY_ARRAY:
		for (size_t i = 0; i < r->elements; i++)
		{
			element_.push_back(RedisReply(r->element[i]));
		}
		break;
	default:
	{
		type_ = REDIS_REPLY_ERROR;
		char buf[512] = { 0 };
#ifdef PLATFORM_WINDOWS
		sprintf_s(buf, "Unknown reply type: %d\n", r->type);
#else
		sprintf(buf, "Unknown reply type: %d\n", r->type);
#endif
		string_ = buf;
	}
	break;
	}
}
RedisReply::~RedisReply()
{
	//printf("===========");
}

RedisReply* RedisReply::get_element(int index)
{
	int num = element_.size();
	if ((size_t)index >= element_.size())
		return nullptr;
	return &element_[index];
}

RedisConnection::RedisConnection()
	: context_(nullptr)
	, reply_(nullptr)
	, is_sentinel_(false)
	, redis_thrd_(nullptr)
	, using_sentinel_(false)
{

}

RedisConnection::~RedisConnection()
{
	close();
}

void RedisConnection::close()
{
	free_reply();

	if (context_)
	{
		redisFree(context_);
		context_ = nullptr;
	}
}

void RedisConnection::free_reply()
{
	if (reply_)
	{
		freeReplyObject(reply_);
		reply_ = nullptr;
	}
}

bool RedisConnection::connect(const std::string& host, int port, int dbnum, const std::string& password)
{
	host_ = host;
	port_ = port;
	dbnum_ = dbnum;
	password_ = password;
	return connect_impl();
}

void RedisConnection::set_redis_thr(RedisConnectionThread* thrd)
{
	redis_thrd_ = thrd;
	using_sentinel_ = true;
}

bool RedisConnection::connect_impl()
{
	struct timeval tv;
	tv.tv_sec = 10;
	tv.tv_usec = 0;
	context_ = redisConnectWithTimeout(host_.c_str(), port_, tv);
	
	if (!context_)
	{
		LOG_ERR("redis(host=%s, port=%d, dbnum=%d) connect failed", host_.c_str(), port_, dbnum_);
		return false;
	}

	if (context_->err)
	{
		LOG_ERR("redis(host=%s, port=%d, dbnum=%d) connect failed(%d):%s", host_.c_str(), port_, dbnum_, context_->err, context_->errstr);

		redisFree(context_);
		context_ = nullptr;

		return false;
	}

	if (!is_sentinel_ && !password_.empty())
	{
		reply_ = (redisReply*)redisCommand(context_, "AUTH %s", password_.c_str());
		if (reply_)
		{
			bool result = true;
			if (reply_->type == REDIS_REPLY_ERROR) result = false;
			freeReplyObject(reply_);
			reply_ = nullptr;

			if (!result)
			{
				LOG_ERR("redis(host=%s, port=%d, dbnum=%d) auth failed", host_.c_str(), port_, dbnum_);
				return false;
			}
		}
	}

	if (dbnum_ != 0)
	{
		reply_ = (redisReply*)redisCommand(context_, "SELECT %d", dbnum_);
		if (reply_)
		{
			bool result = true;
			if (reply_->type == REDIS_REPLY_ERROR) result = false;
			freeReplyObject(reply_);
			reply_ = nullptr;

			if (!result)
			{
				LOG_ERR("redis(host=%s, port=%d, dbnum=%d) select dbnum failed", host_.c_str(), port_, dbnum_);
				return false;
			}
		}
	}

	reply_ = (redisReply*)redisCommand(context_, "PING");
	if (reply_)
	{
		bool result = true;
		if (reply_->type == REDIS_REPLY_ERROR) result = false;
		freeReplyObject(reply_);
		reply_ = nullptr;

		if (!result)
		{
			LOG_ERR("redis(host=%s, port=%d, dbnum=%d) first ping failed", host_.c_str(), port_, dbnum_);
			return false;
		}
	}

	LOG_INFO("redis(host=%s, port=%d, dbnum=%d) connect ok", host_.c_str(), port_, dbnum_);

	return true;
}

void RedisConnection::command(const std::string& cmd)
{
	if (context_)
	{
		free_reply();

		reply_ = (redisReply*)redisCommand(context_, cmd.c_str());
	}

	if (reply_ == nullptr || context_ == nullptr)
	{
		// Á¬½Ó¶Ï¿ª
		if (using_sentinel_ && redis_thrd_)
		{
			if (!redis_thrd_->connnect_sentinel_thread())
				return;
		}
		else
		{
			close();
			if (!connect_impl())
				return;
		}

		reply_ = (redisReply*)redisCommand(context_, cmd.c_str());
	}
}
redisReply * RedisConnection::get_replyT()
{
	return reply_;
}
RedisReply RedisConnection::get_reply()
{
	return RedisReply(reply_);
}

bool RedisConnection::get_player_login_info(const std::string& account, PlayerLoginInfo* info)
{
	command(str(boost::format("HGET player_login_info %1%") % account));
	RedisReply reply = get_reply();
	if (reply.is_string())
	{
		if (info && !info->ParseFromString(CryptoManager::from_hex(reply.get_string())))
		{
			LOG_ERR("ParseFromString failed, account:%s", account.c_str());
		}

		return true;
	}

	return false;
}

bool RedisConnection::get_player_login_info_temp(const std::string& account, PlayerLoginInfo* info)
{
	command(str(boost::format("HGET player_login_info_temp %1%") % account));
	RedisReply reply = get_reply();
	if (reply.is_string())
	{
		if (info && !info->ParseFromString(CryptoManager::from_hex(reply.get_string())))
		{
			LOG_ERR("ParseFromString failed, account:%s", account.c_str());
		}

		return true;
	}

	return false;
}

int RedisConnection::get_gameid_by_guid(int guid)
{
	command(str(boost::format("HGET player_online_gameid %1%") % guid));
	auto reply = get_reply();
	if (reply.is_string())
	{
		return boost::lexical_cast<int>(reply.get_string());
	}
	return 0;
}

bool RedisConnection::get_player_login_info_guid(int guid, PlayerLoginInfo* info)
{
	command(str(boost::format("HGET player_login_info_guid %1%") % guid));
	RedisReply reply = get_reply();
	if (reply.is_string())
	{
		if (info && !info->ParseFromString(CryptoManager::from_hex(reply.get_string())))
		{
			LOG_ERR("ParseFromString failed, guid:%d", guid);
		}

		return true;
	}

	return false;
}
