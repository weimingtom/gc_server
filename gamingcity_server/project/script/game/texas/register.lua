-- 注册Demo消息

--local pb = require "protobuf"
--pb.register_file("../pb/common_msg_texas.proto")

require "game/texas/on_texas"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_TexasUserAction","on_cs_texas_action")
register_client_dispatcher("CS_TexasEnterTable", "on_cs_texas_sit_down")
register_client_dispatcher("CS_TexasLeaveTable", "on_cs_texas_leave")