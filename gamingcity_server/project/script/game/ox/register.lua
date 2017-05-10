-- 注册牛牛消息

require "game/ox/on_ox"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_OxApplyForBanker", "on_cs_ox_apply_for_banker")  --用户申请上庄
register_client_dispatcher("CS_OxLeaveForBanker", "on_cs_ox_leave_for_banker")  --用户申请下庄(上庄列表中的用户)
register_client_dispatcher("CS_OxCurBankerLeave", "on_cs_ox_curbanker_leave")   --在当庄的用户未主动申请下庄 
register_client_dispatcher("CS_OxCallBanker", "on_cs_ox_call_banker")
register_client_dispatcher("CS_OxAddScore", "on_cs_ox_add_score")
register_client_dispatcher("CS_OxOpenCards", "on_cs_ox_open_cards")
register_client_dispatcher("CS_OxRecord","on_cs_ox_record")
register_client_dispatcher("CS_OxTop","on_cs_ox_top")
register_client_dispatcher("CS_OxPlayerConnectGame","on_cs_ox_PlayerConnectionOxMsg")   --玩家进入游戏或断线重连
register_client_dispatcher("CS_OxLeaveGame","on_cs_ox_PlayerLeaveGame")   --玩家离开游戏
