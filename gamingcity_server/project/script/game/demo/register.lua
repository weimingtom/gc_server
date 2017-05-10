-- 注册Demo消息

local pb = require "protobuf"

pb.register_file("../pb/common_msg_demo.proto")

require "game/demo/on_demo"


--------------------------------------------------------------------
-- 注册客户端发过来的消息分派函数
register_client_dispatcher("CS_Demo", "on_cs_demo")
