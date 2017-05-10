#include "GameTimeManager.h"


GameTimer::GameTimer(float delay)
	: start_(GameTimeManager::instance()->get_millisecond_time())
	, delay_(GameTimeManager::instance()->get_millisecond_time() + static_cast<long long>(delay * 1000))
{

}

GameTimer::~GameTimer()
{

}

bool GameTimer::check_time()
{
	auto cur = GameTimeManager::instance()->get_millisecond_time();
	if (cur < delay_)
		return false;

	on_time(static_cast<float>(cur - start_) / 1000.f);

	return true;
}


GameTimeManager::GameTimeManager()
{
	memset(&tm_, 0, sizeof(tm));
	memset(&tb_, 0, sizeof(timeb));
}

GameTimeManager::~GameTimeManager()
{
	while (!timers_.empty())
	{
		delete timers_.top();
		timers_.pop();
	}
}

GameTimeManager& GameTimeManager::now()
{
	ftime(&tb_);
#ifdef PLATFORM_WINDOWS
	localtime_s(&tm_, &tb_.time);
#endif

#ifdef PLATFORM_LINUX
	localtime_r(&tb_.time, &tm_);
#endif

	return *this;
}

long long GameTimeManager::get_millisecond_time() const
{
	return 1000 * (long long)tb_.time + tb_.millitm;
}

int GameTimeManager::to_days(time_t time)
{
	return static_cast<int>(time + 57600) / 86400;
}

int GameTimeManager::to_days()
{
	return to_days(tb_.time);
}

int GameTimeManager::to_weeks(time_t time)
{
	return static_cast<int>(time - 230400) / (86400 * 7);
}

int GameTimeManager::to_weeks()
{
	return to_weeks(tb_.time);
}

void GameTimeManager::add_timer(GameTimer* timer)
{
	timers_.push(timer);
}

void GameTimeManager::tick()
{
	now();

	while (!timers_.empty())
	{
		auto timer = timers_.top();
		if (!timer->check_time())
		{
			break;
		}
		delete timer;
		timers_.pop();
	}
}

#ifdef PLATFORM_LINUX
DWORD timeGetTime()
{
	timeb tb_;
	ftime(&tb_);
	return 1000 * tb_.time + tb_.millitm;
}
#endif