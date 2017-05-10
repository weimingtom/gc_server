-- 设置IP端口
ip = "127.0.0.1"
port = 7788

-- 开启客户端数量
client_count = 500

-- 账号密码
client_account_password = {}
for i = 1, client_count do
	client_account_password[i] = { account = "test_" .. i, password = "123456" }
end
