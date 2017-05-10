#pragma once

#include "perinclude.h"
#include "WindowsConsole.h"
#include "GameTimeManager.h"
#include "GameLog.h"
#include "config_define.pb.h"

/**********************************************************************************************//**
 * \class	BaseServer
 *
 * \brief	A base server.
 **************************************************************************************************/

class BaseServer : public TSingleton < BaseServer >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	BaseServer();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~BaseServer();

	/**********************************************************************************************//**
	 * \brief	调用初始化，然后开启逻辑线程，主线程监听用户输入.
	 **************************************************************************************************/

	void startup();

	/**********************************************************************************************//**
	 * \brief	初始化.
	 *
	 * \return	true if it succeeds, false if it fails.
	 **************************************************************************************************/

	virtual bool init();

	/**********************************************************************************************//**
	 * \brief	运行.
	 **************************************************************************************************/

	virtual void run();

	/**********************************************************************************************//**
	 * \brief	停止运行.
	 **************************************************************************************************/

	virtual void stop();

	/**********************************************************************************************//**
	 * \brief	释放.
	 **************************************************************************************************/

	virtual void release();

	/**********************************************************************************************//**
	 * \brief	处理gm命令.
	 *
	 * \param	cmd	The command.
	 **************************************************************************************************/

	virtual void on_gm_command(const char* cmd);

	/**********************************************************************************************//**
	 * \brief	得到cpu数.
	 *
	 * \return	cpu数.
	 **************************************************************************************************/

	size_t get_core_count();

	/**********************************************************************************************//**
	 * \brief	调用的脚本文件.
	 *
	 * \return	null if it fails, else a pointer to a const char.
	 **************************************************************************************************/

	virtual const char* main_lua_file();

	CommonServer_Config& get_common_cfg()
	{
		return common_config_;
	}

	void send_statistics(uint16_t msgid, uint64_t byte_);
	void recv_statistics(uint16_t msgid, uint64_t byte_);
	void print_statistics();
	void set_print_filename(const std::string& filename);

protected:
	bool load_file(const char* file, std::string& buf);
	virtual bool load_common_config();

protected:
#if defined(_DEBUG) && defined(PLATFORM_WINDOWS)
	WindowsConsole								windows_console_;
#endif
	std::unique_ptr<GameTimeManager>			game_time_;
	std::unique_ptr<GameLog>					game_log_;

	std::thread									thread_;
	volatile bool								is_run_;

	CommonServer_Config							common_config_;

	// 消息统计
	struct MsgStatistics
	{
		uint64_t								count_;
		uint64_t								byte_;
		MsgStatistics(uint64_t _count, uint64_t _byte)
			: count_(_count)
			, byte_(_byte)
		{
		}
	};
	std::unordered_map<uint16_t, MsgStatistics> send_statistics_;
	std::unordered_map<uint16_t, MsgStatistics> recv_statistics_;
	std::recursive_mutex						mutex_statistics_;
	std::string									filename_statistics_;
	time_t										time_statistics_;
};
