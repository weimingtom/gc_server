-- 注册老虎机消息

require "game/slotma/on_slotma"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_SlotmaPlayerConnectGame","on_cs_slotma_PlayerConnectionMsg")   --玩家进入游戏
register_client_dispatcher("CS_SlotmaLeaveGame","on_cs_slotma_PlayerLeaveGame")   --玩家离开游戏
register_client_dispatcher("CS_Slotma_Start", "on_cs_slotma_start")