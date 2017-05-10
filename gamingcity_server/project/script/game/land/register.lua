-- 注册斗地主消息

require "game/land/on_land"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_LandCallScore", "on_cs_land_call_score")
register_client_dispatcher("CS_LandOutCard", "on_cs_land_out_card")
register_client_dispatcher("CS_LandPassCard", "on_cs_land_pass_card")
register_client_dispatcher("CS_LandTrusteeship","on_cs_LandTrusteeship")
register_client_dispatcher("CS_LandCallDouble","on_cs_land_call_double")
