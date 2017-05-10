#include "NetworkDispatcher.h"
#include "GameLog.h"

NetworkDispatcherManager::NetworkDispatcherManager()
{
}

NetworkDispatcherManager::~NetworkDispatcherManager()
{
	for (auto& item : dispatcher_)
	{
		delete item.second;
	}
}

void NetworkDispatcherManager::register_dispatcher(NetworkDispatcher* dispatcher, bool show_log)
{
	if (!dispatcher_.insert(std::make_pair(dispatcher->get_msg_id(), dispatcher)).second)
	{
		if (show_log)
		{
			LOG_WARN("dispatcher duplicate registration, id=%d", dispatcher->get_msg_id());
		}

		delete dispatcher_[dispatcher->get_msg_id()];
		dispatcher_[dispatcher->get_msg_id()] = dispatcher;
	}
}

NetworkDispatcher* NetworkDispatcherManager::query_dispatcher(unsigned short id)
{
	auto it = dispatcher_.find(id);
	if (it != dispatcher_.end())
		return it->second;

	return nullptr;
}
