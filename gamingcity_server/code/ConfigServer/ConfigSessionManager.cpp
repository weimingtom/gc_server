#include "ConfigSessionManager.h"
#include "ConfigSession.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif  // _DEBUG

#define REG_SERVER_DISPATCHER(Msg, Function) dispatcher_manager_.register_dispatcher(new MsgDispatcher< Msg, ConfigSession >(&ConfigSession::Function));

ConfigSessionManager::ConfigSessionManager()
{
	register_server_message();
    m_sPhpString = "";
    m_mpPlayer_Gate.clear();
}

ConfigSessionManager::~ConfigSessionManager()
{
}

void ConfigSessionManager::register_server_message()
{
	REG_SERVER_DISPATCHER(S_RequestServerConfig, on_S_RequestServerConfig);
	REG_SERVER_DISPATCHER(S_RequestUpdateGameServerConfig, on_S_RequestUpdateGameServerConfig);
	REG_SERVER_DISPATCHER(S_RequestUpdateLoginServerConfigByGate, on_S_RequestUpdateLoginServerConfigByGate);
	REG_SERVER_DISPATCHER(S_RequestUpdateLoginServerConfigByGame, on_S_RequestUpdateLoginServerConfigByGame);
	REG_SERVER_DISPATCHER(S_RequestUpdateDBServerConfigByGame, on_S_RequestUpdateDBServerConfigByGame);
	REG_SERVER_DISPATCHER(S_RequestUpdateDBServerConfigByLogin, on_S_RequestUpdateDBServerConfigByLogin);
    REG_SERVER_DISPATCHER(WF_ChangeGameCfg, on_WF_ChangeGameCfg);
    REG_SERVER_DISPATCHER(WF_GetCfg, on_WF_GetCfg);
    REG_SERVER_DISPATCHER(SF_ChangeGameCfg, on_SF_ChangeGameCfg);  
    REG_SERVER_DISPATCHER(WS_MaintainUpdate, on_ReadMaintainSwitch);
    REG_SERVER_DISPATCHER(GF_PlayerIn, on_GF_PlayerIn);
    REG_SERVER_DISPATCHER(GF_PlayerOut, on_GF_PlayerOut);
    REG_SERVER_DISPATCHER(WF_Recharge, on_WF_Recharge);
    REG_SERVER_DISPATCHER(WF_CashFalse, on_WF_CashFalse);
    REG_SERVER_DISPATCHER(DF_Reply, on_DF_Reply);
    REG_SERVER_DISPATCHER(DF_ChangMoney, on_DF_ChangMoney);
    REG_SERVER_DISPATCHER(FS_ChangMoneyDeal, on_FS_ChangMoneyDeal);
    
}

std::shared_ptr<NetworkSession> ConfigSessionManager::create_session(boost::asio::ip::tcp::socket& socket)
{
	return std::static_pointer_cast<NetworkSession>(std::make_shared<ConfigSession>(socket));
}

void ConfigSessionManager::SetPlayer_Gate(int guid, int gate_id)
{
    if (gate_id >= 0)
    {
        m_mpPlayer_Gate[guid] = gate_id;
    }
    else
    {
        LOG_INFO("SetPlayer_Gate error... gate_id %d", gate_id);
    }
}

int ConfigSessionManager::GetPlayer_Gate(int guid)
{
    std::map<int, int>::iterator iter = m_mpPlayer_Gate.begin();
    for (; iter != m_mpPlayer_Gate.end();)
    {
        if (iter->first == guid)
        {
            return iter->second;
            break;
        }
        else
        {
            ++iter;
        }
    }
    return -1;
}

void ConfigSessionManager::ErasePlayer_Gate(int guid)
{
    std::map<int, int>::iterator iter = m_mpPlayer_Gate.begin();
    for (; iter != m_mpPlayer_Gate.end();)
    {
        if (iter->first == guid)
        {
            m_mpPlayer_Gate.erase(iter++);
            break;
        }
        else
        {
            ++iter;
        }
    }
}