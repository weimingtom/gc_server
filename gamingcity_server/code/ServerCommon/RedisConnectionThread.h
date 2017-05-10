#pragma once

#include "RedisConnection.h"
#include "RedisQueryResult.h"
#ifdef PLATFORM_WINDOWS
#include <concurrent_queue.h>
#endif
#include "Singleton.h"
 
/**********************************************************************************************//**
 * \class	RedisConnectionThread
 *
 * \brief	Redis连接线程.
 **************************************************************************************************/

class RedisConnectionThread : public TSingleton<RedisConnectionThread>
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	RedisConnectionThread();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~RedisConnectionThread();

	/**********************************************************************************************//**
	 * \brief	设置redis的ip.
	 *
	 * \param	ip	ip地址.
	 **************************************************************************************************/

	void set_ip(const std::string& ip)
	{
		ip_ = ip; 
	}

	/**********************************************************************************************//**
	 * \brief	链接哨兵
	 *
	 * \param	detail
	 **************************************************************************************************/
	void connect_sentinel();
	// 在线程中连接哨兵
	bool connnect_sentinel_thread();
	/**********************************************************************************************//**
	 * \brief	设置哨兵信息.
	 *
	 * \param	detail
	 **************************************************************************************************/
	void add_sentinel(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password);
	/*设置默认的redis master*/
	void set_master_info(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password);
	/**********************************************************************************************//**
	 * \brief	设置redis端口.
	 *
	 * \param	port	端口.
	 **************************************************************************************************/

	void set_port(int port)
	{
		port_ = port;
	}

	/**********************************************************************************************//**
	 * \brief	设置redis那个db.
	 *
	 * \param	dbnum	那个db.
	 **************************************************************************************************/

	void set_dbnum(int dbnum)
	{
		dbnum_ = dbnum;
	}

	/**********************************************************************************************//**
	 * \brief	开启线程.
	 **************************************************************************************************/

	void start();

	/**********************************************************************************************//**
	 * \brief	等待线程结束.
	 **************************************************************************************************/

	void join();

	/**********************************************************************************************//**
	 * \brief	请求关闭.
	 **************************************************************************************************/

	void stop();

	/**********************************************************************************************//**
	 * \brief	运行时，每一帧调用.
	 **************************************************************************************************/

	bool tick();

	/**********************************************************************************************//**
	 * \brief	执行一条redis语句.
	 *
	 * \param	cmd		redis语句.
	 **************************************************************************************************/

	void command(const std::string& cmd, bool master_flag = true);
	/**********************************************************************************************//**
	 * \brief	执行一条redis查询语句.
	 *
	 * \param	func	逻辑线程处理结果集.
	 * \param	cmd		redis语句.
	 **************************************************************************************************/

	void command_query(const std::function<void(RedisReply*)>& func, const std::string& cmd, bool master_flag = true);
	
	/**********************************************************************************************//**
	 * \brief	脚本中执行一条redis查询语句.
	 *
	 * \param	func	脚本回调函数名.
	 * \param	index	脚本回调号.
	 * \param	cmd 	redis语句.
	 **************************************************************************************************/

	void command_query_lua(const char* func, int index, const char* cmd, bool master_flag = true);
	redisReply * command_do(const char* cmd, bool master_flag = true);
	// 添加返回调用
	void add_reply(const std::function<void(RedisReply*)>& cmd_func, const RedisReply& reply);
	void add_reply(const std::string& query_func, int index, const RedisReply& reply);
	void add_reply(const std::function<void()>& cmd_func);
	template<typename T>
	void add_reply(const std::function<void(T*)>& cmd_func, const T& reply)
	{
		auto qr = new RedisQueryPbResult<T>(cmd_func, reply);
#ifdef PLATFORM_WINDOWS
		query_result_.push(qr);
#endif
#ifdef PLATFORM_LINUX
		query_result_.push_back(qr);
#endif
	}

	// 基本实现
	void command_impl(const std::function<void(RedisConnection*)>& func, bool master_flag = true);

private:

	/**********************************************************************************************//**
	 * \brief	运行.
	 **************************************************************************************************/

	void run();
	RedisConnection* get_connection(bool is_master);
	void close_connection();
	bool do_connect();
private:
	std::string										ip_;
	int												port_;
	int												dbnum_;

	struct redis_con_info
	{
	private:
		std::string ip;
		int port;
		std::shared_ptr<std::mutex> lock;
	public:
		RedisConnection	con;
		std::string master_name;
		int	dbnum;
		std::string password;

		redis_con_info()
		{
			lock = std::make_shared<std::mutex>();
		}
		void set_info(const std::string& ip_t, int port_t, const std::string& master_name_t, int dbnum_t, const std::string& password_t)
		{
			std::lock_guard<std::mutex> iplock(*lock);
			ip = ip_t;
			port = port_t;
			dbnum = dbnum_t;
			master_name = master_name_t;
			password = password_t;
		}
		bool connect()
		{
			do 
			{
				std::lock_guard<std::mutex> iplock(*lock);
				if (ip.empty())
				{
					return false;
				}
			} while (0);
			
			close();
			return con.connect(ip, port, dbnum, password);
		}
		void close()
		{
			con.close();
		}
	};
	redis_con_info									connection_master_;
	std::vector<redis_con_info*>					connection_slaves_;
	std::vector<redis_con_info*>					sentinel_list_;

	std::thread										thread_;
	volatile bool									is_run_;
#ifdef PLATFORM_WINDOWS
	Concurrency::concurrent_queue<std::function<void(RedisConnection*)>> command_;
	Concurrency::concurrent_queue<bool> command_master_flag_;
	Concurrency::concurrent_queue<BaseRedisQueryResult*> query_result_;
#endif

#ifdef PLATFORM_LINUX
	std::recursive_mutex							mutex_;
	std::vector<std::function<void(RedisConnection*)>> command_;
	std::vector<bool> command_master_flag_;
	std::vector<BaseRedisQueryResult*>				query_result_;
#endif
};
