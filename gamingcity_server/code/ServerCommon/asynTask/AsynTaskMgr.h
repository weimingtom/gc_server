#pragma once
#include "../perinclude.h"
#include "../Singleton.h"
#include <condition_variable>
#include <memory>
#include <list>


class AsynTask
{
public:
	AsynTask(){};
	virtual ~AsynTask(){};

	virtual void ExecuteTaskHandler() = 0;
	virtual void FinishTaskHandler() = 0;
};

typedef std::shared_ptr<AsynTask> AsynTaskPtr;

class AsynTaskMgr : public TSingleton<AsynTaskMgr>
{
public:
    AsynTaskMgr();
    virtual ~AsynTaskMgr();
	
	void tick();
	void addTask(AsynTaskPtr task);
	void addTaskFinish(AsynTaskPtr task);
	void taskThread();
	void stop();

private: 
	std::mutex mu;  
	std::condition_variable_any cond;

	std::mutex			taskListLock;
	std::list<AsynTaskPtr>	taskList;

	std::mutex			taskFinishListLock;
	std::list<AsynTaskPtr>	taskFinishList;

	bool isRun = true;
};

#define sAsynTaskMgr (*AsynTaskMgr::instance())
