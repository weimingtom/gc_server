#include "RedisConnectionThread.h"
#ifdef PLATFORM_WINDOWS
#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")
#endif

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG


RedisConnectionThread::RedisConnectionThread()
: port_(0)
, dbnum_(0)
, is_run_(true)
{
}

RedisConnectionThread::~RedisConnectionThread()
{
	for (auto item : sentinel_list_)
	{
		delete item;
	}
}

#ifdef PLATFORM_WINDOWS

#include "minidump.h"
static int __stdcall seh_redis_filter(unsigned int code, struct _EXCEPTION_POINTERS *ep)
{
	time_t t = time(nullptr);
	tm tm_;
	localtime_s(&tm_, &t);

	TCHAR szModuleName[MAX_PATH];
	GetModuleFileName(NULL, szModuleName, MAX_PATH);
	WCHAR szFileName[_MAX_FNAME] = L"";
	_wsplitpath_s(szModuleName, NULL, 0, NULL, 0, szFileName, _MAX_FNAME, NULL, 0);

	WCHAR buf[MAX_PATH] = { 0 };
	wsprintf(buf, L"%s redis[%u]_%d-%02d-%02d_%02d-%02d-%02d.dmp", szFileName, GetCurrentThreadId(), tm_.tm_year + 1900, tm_.tm_mon + 1, tm_.tm_mday, tm_.tm_hour, tm_.tm_min, tm_.tm_sec);

	CreateMiniDump(ep, buf);

	return EXCEPTION_EXECUTE_HANDLER;
}

#endif
RedisConnection* RedisConnectionThread::get_connection(bool is_master)
{
	if (!is_master)
	{
		static unsigned char index = 0;
		unsigned char slave_count = connection_slaves_.size();
		if (slave_count > 0)
		{
			return &(connection_slaves_[index++ % slave_count]->con);
		}
	}
	return &connection_master_.con;
}
void RedisConnectionThread::close_connection()
{
	connection_master_.close();
	for (auto ins : connection_slaves_)
	{
		ins->close();
	}
}
bool RedisConnectionThread::do_connect()
{
	bool do_connect_suc = false;
	do_connect_suc = connection_master_.connect();
	for (auto ins : connection_slaves_)
	{
		ins->connect();
	}
	return do_connect_suc;
}

void RedisConnectionThread::set_master_info(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password)
{
	connection_master_.set_info(ip, port, master_name, dbnum, password);
}

void RedisConnectionThread::add_sentinel(const std::string& ip, int	port, const std::string& master_name, int	dbnum, const std::string& password)
{
	auto tmp = new redis_con_info;
	tmp->set_info(ip, port, master_name, dbnum, password);
	sentinel_list_.emplace_back(tmp);
}

void RedisConnectionThread::connect_sentinel()
{
	assert(sentinel_list_.size());
	std::thread([this] {
		bool suc = false;
		do 
		{
			for (auto sentinel : sentinel_list_)
			{
				sentinel->con.set_is_sentinel();
				if (sentinel->connect())
				{
					sentinel->con.command("sentinel masters");
					RedisReply reply = sentinel->con.get_reply();
					if (reply.is_array())
					{
						int reply_size_element = reply.size_element();
						for (int i = 0; i < reply_size_element; i++)
						{
							RedisReply* master_ins = reply.get_element(i);
							int master_ins_size = master_ins->size_element();
							
							std::string master_ip;
							int master_port;
							std::string master_name_tmp;
							for (int j = 0; j < master_ins_size; j++)
							{
								RedisReply* area = master_ins->get_element(j);
								if (area->is_string() && 0 == strcmp("name", area->get_string()))
								{
									j++;
									master_name_tmp = master_ins->get_element(j)->get_string();
								}
								if (area->is_string() && 0 == strcmp("ip", area->get_string()))
								{
									j++;
									master_ip = master_ins->get_element(j)->get_string();
								}
								if (area->is_string() && 0 == strcmp("port", area->get_string()))
								{
									j++;
									master_port = std::atoi(master_ins->get_element(j)->get_string());
								}
							}

							if (master_name_tmp == sentinel->master_name)
							{
								connection_master_.set_info(master_ip, master_port, sentinel->master_name, sentinel->dbnum, sentinel->password);
								suc = true;
								connection_master_.con.set_redis_thr(this);
								break;
							}
						}
					}
					
					/*std::string slaves_info_cmd("sentinel slaves ");
					slaves_info_cmd.append(sentinel.master_name);
					sentinel.con.command(slaves_info_cmd.c_str());
					reply = sentinel.con.get_reply();
					if (reply.is_array())
					{
						int reply_size_element = reply.size_element();
						for (int i = 0; i < reply_size_element; i++)
						{
							RedisReply* slave_ins = reply.get_element(i);
							int slave_ins_size = slave_ins->size_element();
							
							std::string slave_ip;
							int slave_port = 0;
							for (int j = 0; j < slave_ins_size; j++)
							{
								RedisReply* area = slave_ins->get_element(j);
								if (area->is_string() && 0 == strcmp("ip", area->get_string()))
								{
									j++;
									slave_ip = slave_ins->get_element(j)->get_string();
								}
								if (area->is_string() && 0 == strcmp("port", area->get_string()))
								{
									j++;
									slave_port = std::atoi(slave_ins->get_element(j)->get_string());
								}
							}
							
							if (slave_port != 0 && !slave_ip.empty())
							{
								redis_con_info tmp_slaves;
								tmp_slaves.set_info(slave_ip, slave_port, sentinel.master_name, sentinel.dbnum, sentinel.password);
								connection_slaves_.emplace_back(tmp_slaves);
							}
						}
					}*/
					
					
					break;
				}
			}
#ifdef PLATFORM_WINDOWS
			// linux todo
			Sleep(1);
#endif
		} while (!suc);
	}).detach();
}

bool RedisConnectionThread::connnect_sentinel_thread()
{
	bool suc = false;
	bool ret = false;
	do
	{
		for (auto sentinel : sentinel_list_)
		{
			sentinel->con.set_is_sentinel();
			if (sentinel->connect())
			{
				sentinel->con.command("sentinel masters");
				RedisReply reply = sentinel->con.get_reply();
				if (reply.is_array())
				{
					int reply_size_element = reply.size_element();
					for (int i = 0; i < reply_size_element; i++)
					{
						RedisReply* master_ins = reply.get_element(i);
						int master_ins_size = master_ins->size_element();

						std::string master_ip;
						int master_port;
						std::string master_name_tmp;
						for (int j = 0; j < master_ins_size; j++)
						{
							RedisReply* area = master_ins->get_element(j);
							if (area->is_string() && 0 == strcmp("name", area->get_string()))
							{
								j++;
								master_name_tmp = master_ins->get_element(j)->get_string();
							}
							if (area->is_string() && 0 == strcmp("ip", area->get_string()))
							{
								j++;
								master_ip = master_ins->get_element(j)->get_string();
							}
							if (area->is_string() && 0 == strcmp("port", area->get_string()))
							{
								j++;
								master_port = std::atoi(master_ins->get_element(j)->get_string());
							}
						}

						if (master_name_tmp == sentinel->master_name)
						{
							connection_master_.set_info(master_ip, master_port, sentinel->master_name, sentinel->dbnum, sentinel->password);
							suc = true;
							connection_master_.con.set_redis_thr(this);
							connection_master_.con.close();
							connection_master_.con.connect(master_ip, master_port, sentinel->dbnum, sentinel->password);
							ret = true;
							break;
						}
					}
				}

				/*std::string slaves_info_cmd("sentinel slaves ");
				slaves_info_cmd.append(sentinel.master_name);
				sentinel.con.command(slaves_info_cmd.c_str());
				reply = sentinel.con.get_reply();
				if (reply.is_array())
				{
					int reply_size_element = reply.size_element();
					for (int i = 0; i < reply_size_element; i++)
					{
						RedisReply* slave_ins = reply.get_element(i);
						int slave_ins_size = slave_ins->size_element();

						std::string slave_ip;
						int slave_port = 0;
						for (int j = 0; j < slave_ins_size; j++)
						{
							RedisReply* area = slave_ins->get_element(j);
							if (area->is_string() && 0 == strcmp("ip", area->get_string()))
							{
								j++;
								slave_ip = slave_ins->get_element(j)->get_string();
							}
							if (area->is_string() && 0 == strcmp("port", area->get_string()))
							{
								j++;
								slave_port = std::atoi(slave_ins->get_element(j)->get_string());
							}
						}

						if (slave_port != 0 && !slave_ip.empty())
						{
							redis_con_info tmp_slaves;
							tmp_slaves.set_info(slave_ip, slave_port, sentinel.master_name, sentinel.dbnum, sentinel.password);
							connection_slaves_.emplace_back(tmp_slaves);
						}
					}
				}*/


				break;
			}
		}
#ifdef PLATFORM_WINDOWS
		// linux todo
		Sleep(1);
#endif
	} while (!suc);

	return ret;
}

void RedisConnectionThread::run()
{
	bool is_con = false;
	DWORD t0 = 0;
	while (is_run_)
	{
		if (!is_con)
		{
			DWORD t = timeGetTime();
			if (t - t0 >= 15 * 1000)
			{
				is_con = do_connect();
				if (!is_con)
				{
					t0 = t;
#ifdef PLATFORM_WINDOWS
					// linux todo
					Sleep(1);
#endif
					continue;
				}
			}
			else
			{
#ifdef PLATFORM_WINDOWS
				// linux todo
				Sleep(1);
#endif
				continue;
			}
		}

#ifdef PLATFORM_WINDOWS
		std::function<void(RedisConnection*)> func;
		while (command_.try_pop(func))
		{
			bool is_master = true;
			command_master_flag_.try_pop(is_master);
			func(get_connection(is_master));
		}
#endif

#ifdef PLATFORM_LINUX
		std::vector<std::function<void(RedisConnection*)>> temp;
		std::vector<bool> command_master_flag_tmp;
		{
			std::lock_guard<std::recursive_mutex> lock(mutex_);
			temp.swap(command_);
			command_master_flag_tmp.swap(command_master_flag_);
		}
		for(int i=0; i<temp.size(); i++)
		{
			bool is_master = true;
			if (i<command_master_flag_tmp.size())
			{
				is_master = command_master_flag_tmp[i];
			}
			temp[i](get_connection(is_master));
		}
#endif

#ifdef PLATFORM_WINDOWS
		// linux todo
		Sleep(1);
#endif
	}

	close_connection();
}

void RedisConnectionThread::start()
{
	thread_ = std::thread([this] {
#ifdef PLATFORM_WINDOWS
		__try
#endif
		{
			run();
		}
#ifdef PLATFORM_WINDOWS
		__except (seh_redis_filter(GetExceptionCode(), GetExceptionInformation()))
		{
			printf("redis thread seh exception\n");
		}
#endif
	});
}

void RedisConnectionThread::join()
{
	thread_.join();

	tick();
}

void RedisConnectionThread::stop()
{
	is_run_ = false;
}

bool RedisConnectionThread::tick()
{
	bool ret = false;
#ifdef PLATFORM_WINDOWS
	for (int i = 0; i < DO_REDIS_PER_TICK_LIMIT; i++)
	{
		BaseRedisQueryResult* p;
		if (query_result_.try_pop(p))
		{
			p->on_command_result();

			delete p;
		}
		else
		{
			ret = true;
			break;
		}
	}
#endif

#ifdef PLATFORM_LINUX
	std::vector<BaseRedisQueryResult*> temp;
	{
		std::lock_guard<std::recursive_mutex> lock(mutex_);
		temp.swap(query_result_);
	}
	for (auto p : temp)
	{
		p->on_command_result();

		delete p;
	}
#endif
	return ret;
}

void RedisConnectionThread::command(const std::string& cmd, bool master_flag)
{
#ifdef PLATFORM_WINDOWS
	command_.push([this, cmd](RedisConnection* con) {
		con->command(cmd);
	});
	command_master_flag_.push(master_flag);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	command_.push_back([this, cmd](RedisConnection* con) {
		con->command(cmd);
});
	command_master_flag_.push_back(master_flag);
#endif
}

void RedisConnectionThread::command_query(const std::function<void(RedisReply*)>& func, const std::string& cmd, bool master_flag)
{
#ifdef PLATFORM_WINDOWS
	command_.push([this, func, cmd](RedisConnection* con) {
		con->command(cmd);
		add_reply(func, con->get_reply());
	});
	command_master_flag_.push(master_flag);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	command_.push_back([this, func, cmd](RedisConnection* con) {
		con->command(cmd);
		add_reply(func, con->get_reply());
	});
	command_master_flag_.push_back(master_flag);
#endif
}
redisReply * RedisConnectionThread::command_do(const char* cmd, bool master_flag){
	RedisConnection* con = get_connection(master_flag);
	con->command(cmd);
	return con->get_replyT();
	//RedisReply& reply
	//lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), cmd_func_.c_str(), index_, &lua_tinker::call<void>(LuaScriptManager::instance()->get_lua_state(), cmd_func_.c_str(), index_, &reply_););
	//add_reply(func, index, con->get_reply());
}
void RedisConnectionThread::command_query_lua(const char* func, int index, const char* cmd, bool master_flag)
{
	std::string strFunc = func;
	std::string strCmd = cmd;

#ifdef PLATFORM_WINDOWS
	command_.push([this, strFunc, index, strCmd](RedisConnection* con) {
		con->command(strCmd);
		add_reply(strFunc, index, con->get_reply());
	});
	command_master_flag_.push(master_flag);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	command_.push_back([this, strFunc, index, strCmd](RedisConnection* con) {
		con->command(strCmd);
		add_reply(strFunc, index, con->get_reply());
	});
	command_master_flag_.push_back(master_flag);
#endif
}

void RedisConnectionThread::add_reply(const std::function<void(RedisReply*)>& cmd_func, const RedisReply& reply)
{
	auto qr = new RedisQueryResult(cmd_func, reply);
#ifdef PLATFORM_WINDOWS
	query_result_.push(qr);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	query_result_.push_back(qr);
#endif
}

void RedisConnectionThread::add_reply(const std::string& query_func, int index, const RedisReply& reply)
{
	auto qr = new RedisQueryLuaResult(query_func, index, reply);
#ifdef PLATFORM_WINDOWS
	query_result_.push(qr);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	query_result_.push_back(qr);
#endif
}

void RedisConnectionThread::add_reply(const std::function<void()>& cmd_func)
{
	auto qr = new RedisQueryNullResult(cmd_func);
#ifdef PLATFORM_WINDOWS
	query_result_.push(qr);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	query_result_.push_back(qr);
#endif
}


void RedisConnectionThread::command_impl(const std::function<void(RedisConnection*)>& func, bool master_flag)
{
#ifdef PLATFORM_WINDOWS
	command_.push(func);
	command_master_flag_.push(master_flag);
#endif
#ifdef PLATFORM_LINUX
	std::lock_guard<std::recursive_mutex> lock(mutex_);
	command_.push_back(func);
	command_master_flag_.push_back(master_flag);
#endif
}
