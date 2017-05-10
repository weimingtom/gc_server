#pragma once

#include "perinclude.h"
#include "Singleton.h"

/**********************************************************************************************//**
 * \class	GameLog
 *
 * \brief	逻辑主线程日志.
 **************************************************************************************************/

class GameLog : public TSingleton < GameLog >
{
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	GameLog();

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	virtual ~GameLog();

	/**********************************************************************************************//**
	 * \brief	初始化log文件名，必须加上%d-%d-%d，用于确定当前日期.
	 *
	 * \param	logname	The logname.
	 **************************************************************************************************/

	virtual void init(const std::string& logname);
	
	/**********************************************************************************************//**
	 * \brief	Logs a message.
	 *
	 * \param	file	__FILE__.
	 * \param	line	__LINE__.
	 * \param	func	__FUNCTION__.
	 * \param	fmt 	日志内容.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	virtual void log_info(const char* file, int line, const char* func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	Logs an error.
	 *
	 * \param	file	__FILE__.
	 * \param	line	__LINE__.
	 * \param	func	__FUNCTION__.
	 * \param	fmt 	日志内容.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	virtual void log_error(const char* file, int line, const char* func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	Logs a warning.
	 *
	 * \param	file	__FILE__.
	 * \param	line	__LINE__.
	 * \param	func	__FUNCTION__.
	 * \param	fmt 	日志内容.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	virtual void log_warning(const char* file, int line, const char* func, const char* fmt, ...);

	/**********************************************************************************************//**
	 * \brief	Logs a debug.
	 *
	 * \param	file	The file.
	 * \param	line	The line.
	 * \param	func	The function.
	 * \param	fmt 	日志内容.
	 * \param	... 	Variable arguments providing additional information.
	 **************************************************************************************************/

	virtual void log_debug(const char* file, int line, const char* func, const char* fmt, ...);

	enum LOG_TYPE
	{
		LOG_TYPE_DEBUG,
		LOG_TYPE_WARNING,
		LOG_TYPE_ERROR,
		LOG_TYPE_INFO,
	};

	void log_string(LOG_TYPE type, const char* log);

	void log(LOG_TYPE type, const char* file, int line, const char* func, const char* str);

protected:

	/**********************************************************************************************//**
	 * \brief	计算明天的time_t.
	 **************************************************************************************************/

	void calc_tomorrow();

	/**********************************************************************************************//**
	 * \brief	打开一个日志文件.
	 **************************************************************************************************/

	void open_log_file();

protected:
	std::ofstream						log_file_;
	std::string							log_name_;
	time_t								tomorrow_;

	std::recursive_mutex				mutex_;
};


#ifdef PLATFORM_WINDOWS
#define LOG_INFO(fmt, ...) GameLog::instance()->log_info(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_ERR(fmt, ...) GameLog::instance()->log_error(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_WARN(fmt, ...) GameLog::instance()->log_warning(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#define LOG_DEBUG(fmt, ...) GameLog::instance()->log_debug(__FILE__, __LINE__, __FUNCTION__, fmt, __VA_ARGS__)
#endif

#ifdef PLATFORM_LINUX
#define LOG_INFO(fmt, args...) GameLog::instance()->log_info(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_ERR(fmt, args...) GameLog::instance()->log_error(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_WARN(fmt, args...) GameLog::instance()->log_warning(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#define LOG_DEBUG(fmt, args...) GameLog::instance()->log_debug(__FILE__, __LINE__, __FUNCTION__, fmt, ##args)
#endif
