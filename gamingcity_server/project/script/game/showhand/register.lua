-- 注册梭哈消息

require "game/showhand/on_showhand"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_ShowHandAddScore", "on_cs_showhand_add_score")
--register_client_dispatcher("CS_ShowHandGiveUp", "on_cs_showhand_give_up")
