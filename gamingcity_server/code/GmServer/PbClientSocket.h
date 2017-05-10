#pragma once

#include <functional>
#include "ClientSocket.h"
#include "msg_server.pb.h"
#include "common_enum_define.pb.h"

#pragma pack(1)
struct MsgHeaderT
{
	unsigned short							len;		// 消息总长度
	unsigned short							id;			// 消息id
};
#pragma pack()


class PbClientSocket : public ClientSocket
{
public:
	bool connect(const char* ip, int port, bool bRet = true)
	{
		if (Create(ip, port) && bRet)
		{
			S_Connect msg;
			msg.set_type(ServerSessionFromWeb);
			return send_pb(&msg);
		}
		return false;
	}

	template<typename T>
	bool send_pb(T* pb)
	{
		std::string str = pb->SerializeAsString();

		MsgHeaderT msg;
		msg.id = T::ID;
		msg.len = sizeof(MsgHeaderT) + str.size();

		if (!SendMsg(&msg, sizeof(MsgHeaderT)))
			return false;

		return str.empty() || SendMsg(const_cast<char*>(str.c_str()), str.size());
	}

	template<typename T>
	bool recv_msg(const std::function<bool(T*)>& func)
	{
		if (!Check()) {
			// 掉线了 
			return false;
		}

		// 接收数据（取得缓冲区中的所有消息，直到缓冲区为空） 
		while (true)
		{
			char buffer[_MAX_MSGSIZE] = { 0 };
			int nSize = sizeof(buffer);
			char* pbufMsg = buffer;
			if (!ReceiveMsg(pbufMsg, nSize)) {
				break;
			}

			MsgHeaderT* header = (MsgHeaderT*)pbufMsg;
			T msg;
			if (header->len > sizeof(MsgHeaderT) && !msg.ParseFromArray(header + 1, header->len - sizeof(MsgHeaderT)))
			{
				printf("ParseFromArray failed, id=%d", header->id);
				return false;
			}

			if (!func(&msg))
			{
				return false;
			}
		}

		return true;
	}
};
