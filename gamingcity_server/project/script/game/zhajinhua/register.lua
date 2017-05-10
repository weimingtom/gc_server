-- 注册诈金花消息

require "game/zhajinhua/on_zhajinhua"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_ZhaJinHuaAddScore", "on_cs_zhajinhua_add_score")
register_client_dispatcher("CS_ZhaJinHuaGiveUp", "on_cs_zhajinhua_give_up")
register_client_dispatcher("CS_ZhaJinHuaLookCard", "on_cs_zhajinhua_look_card")
register_client_dispatcher("CS_ZhaJinHuaCompareCard", "on_cs_zhajinhua_compare_card")
register_client_dispatcher("CS_ZhaJinHuaGetPlayerStatus", "on_cs_zhajinhua_get_player_status")
register_client_dispatcher("CS_ZhaJinHuaGetSitDown", "on_cs_zhajinhua_get_sit_down")
