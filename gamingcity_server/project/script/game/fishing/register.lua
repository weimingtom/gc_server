-- 注册诈金花消息




require "game/lobby/on_login_logout"
require "game/lobby/on_bank"
require "game/lobby/on_item"
require "game/lobby/on_award"
require "game/lobby/on_room"
require "game/lobby/on_chat"
require "game/lobby/on_mail"
require "game/net_func"
require "game/fishing/on_fishing"
--------------------------------------------------------------------

register_client_dispatcher("CS_TreasureEnd", "on_cs_fishing_treasureend")
register_client_dispatcher("CS_ChangeCannonSet", "on_cs_fishing_changecannonset")
register_client_dispatcher("CS_Netcast", "on_cs_fishing_netcast")
register_client_dispatcher("CS_LockFish", "on_cs_fishing_lockfish")
register_client_dispatcher("CS_Fire", "on_cs_fishing_fire")
register_client_dispatcher("CS_ChangeCannon", "on_cs_fishing_changecannon")
register_client_dispatcher("CS_TimeSync", "on_cs_fishing_timesync")
