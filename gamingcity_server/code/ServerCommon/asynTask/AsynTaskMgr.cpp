#include "AsynTaskMgr.h"

AsynTaskMgr::AsynTaskMgr()
{
	std::thread t(boost::bind(&AsynTaskMgr::taskThread,this));
	t.detach();
}

AsynTaskMgr::~AsynTaskMgr()
{
}

void AsynTaskMgr::tick()
{
	while(true)
	{
		AsynTaskPtr tempTask;
		{
			std::unique_lock<std::mutex> lock(taskFinishListLock);
			if (taskFinishList.empty())
			{
				break;
			}
			else
			{
				tempTask = taskFinishList.front();
				taskFinishList.pop_front();
			}
		}
		if (tempTask)
		{
			tempTask->FinishTaskHandler();
		}
	}
}

void AsynTaskMgr::addTask(AsynTaskPtr task)
{
	std::unique_lock<std::mutex> lock(taskListLock);
	taskList.push_back(task);
	cond.notify_one();  
}
void AsynTaskMgr::addTaskFinish(AsynTaskPtr task)
{
	std::unique_lock<std::mutex> lock(taskFinishListLock);
	taskFinishList.push_back(task);
}
void AsynTaskMgr::stop()
{
	isRun = false;
}
void AsynTaskMgr::taskThread()
{
	while (isRun)
	{
		AsynTaskPtr tempTask;
		{
			std::unique_lock<std::mutex> lock(taskListLock);
			if (!taskList.empty())
			{
				tempTask = taskList.front();
				taskList.pop_front();
			}
		}
		if (tempTask)
		{
			tempTask->ExecuteTaskHandler();
			addTaskFinish(tempTask);
		}
		else
		{
			std::unique_lock<std::mutex> lock(mu);
			cond.wait(mu);
		}
	}
}
