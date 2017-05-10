#include "UtilsHelper.h"
#include "RSAEuro/rsaeuro.h"
//#include "../TestLuaClient/stdafx.h"
#include <stdlib.h>
#include "FileMD5.h"

std::string UtilsHelper::to_hex(const std::string & src)
{
	std::string ret;
	for (auto ch : src)
	{
		unsigned char c = static_cast<unsigned char>(ch) >> 4;
		if (c < 10)
		{
			ret += ('0' + c);
		}
		else
		{
			ret += 'a' + c - 10;
		}

		c = static_cast<unsigned char>(ch)& 0xf;
		if (c < 10)
		{
			ret += ('0' + c);
		}
		else
		{
			ret += 'a' + c - 10;
		}
	}

	return ret;
}

std::string UtilsHelper::from_hex(const std::string & src)
{
	std::string ret;
	size_t sz = src.size();
	if (sz == 0 || (sz % 2) == 1)
		return ret;

	for (size_t i = 0; i < sz; i += 2)
	{
		char c = 0;
		if (src[i] >= 'a')
		{
			c |= (src[i] - 'a' + 10) << 4;
		}
		else
		{
			c |= (src[i] - '0') << 4;
		}

		if (src[i + 1] >= 'a')
		{
			c |= (src[i + 1] - 'a' + 10);
		}
		else
		{
			c |= (src[i + 1] - '0');
		}

		ret += c;
	}

	return ret;
}

std::string UtilsHelper::md5(const std::string& src)
{
	return MD5(src).toString();
}

//std::string UtilsHelper::md5OfFile(const std::string &path)//md5 file
//{
//	Data data = FileUtils::getInstance()->getDataFromFile(path);
//	std::string md5Result = MD5(data.getBytes(), data.getSize()).toString();
//	return md5Result;
//}
void UtilsHelper::rsa_key(std::string& pubKeyStr, std::string& privateKeyStr)
{
	R_RSA_PUBLIC_KEY  PubKey;
	R_RSA_PRIVATE_KEY PriKey;
	R_RANDOM_STRUCT   RandSt;
	R_RSA_PROTO_KEY   ProKey;
	//生成密钥对
	R_RandomCreate(&RandSt);
	ProKey.bits = 512;//512 or 1024 or 2048
	ProKey.useFermat4 = 1;
	R_GeneratePEMKeys(&PubKey, &PriKey, &ProKey, &RandSt);
	//将pubkey privekey转化为base64
	int len = sizeof(R_RSA_PUBLIC_KEY);
	unsigned char *pubKey_buff;
	pubKey_buff = (unsigned char *)malloc(sizeof(R_RSA_PUBLIC_KEY) + 1);
	memcpy(pubKey_buff, &PubKey, sizeof(PubKey));

	pubKeyStr.assign((char *)pubKey_buff, len);
	//static std::string	pubKey64Str = base64_encode((const unsigned char *)pubKey_buff, len);
	free(pubKey_buff);
	unsigned char *privateKeyBuffer;
	privateKeyBuffer = (unsigned char *)malloc(sizeof(R_RSA_PRIVATE_KEY) + 1);
	int privLen = sizeof(R_RSA_PRIVATE_KEY);
	memcpy(privateKeyBuffer, &PriKey, sizeof(PriKey));

	privateKeyStr.assign((char *)privateKeyBuffer, privLen);
	free(privateKeyBuffer);
	/**---------Test------------------**/
	//std::string src = "asdasd财政项目支持的发射点法发";
	//char *TestBuffer = (char *)src.c_str();
	//公钥加密私钥解密
	//std::string encode = UtilsHelper::rsa_encrypt(pubKeyStr, src);
	//std::cout << "encode:" << encode << std::endl;
	//printf("encode:%s\n", encode.c_str());
	//std::string decode = UtilsHelper::rsa_decrypt(privateKeyStr, encode);
	//std::cout << "cc encode:" << decode << std::endl;
	//printf("decode:%s\n", decode.c_str());
	//std::string inputStr = "中国";
	//std::string xx =  UtilsHelper::md5OfString(inputStr);
	//printf("md5:%s\n", xx.c_str());
}
std::string  UtilsHelper::rsa_encrypt(const std::string& pubKeyStr,const std::string &src)
{
	R_RSA_PUBLIC_KEY  PubKey;
	memcpy(&PubKey, pubKeyStr.c_str(), sizeof(R_RSA_PUBLIC_KEY));
	R_RANDOM_STRUCT   RandSt;
	//公钥加密私钥解密
	char *TestBuffer = (char *)src.c_str();
	unsigned char EncryptBuffer[256] = { 0 };
	unsigned int InputLen = sizeof(EncryptBuffer);
	R_RandomCreate(&RandSt);
	RSAPublicEncrypt(EncryptBuffer, &InputLen, (unsigned char*)TestBuffer, strlen(TestBuffer), &PubKey, &RandSt);
	std::string encryptStr;
	encryptStr.assign((char *)EncryptBuffer, sizeof(EncryptBuffer));
	return encryptStr;
}
//私钥解密
std::string UtilsHelper::rsa_decrypt(const std::string& privateKeyStr,const std::string &encryptStr)
{
	R_RSA_PRIVATE_KEY PriKey;
	memcpy(&PriKey, privateKeyStr.c_str(), sizeof(R_RSA_PRIVATE_KEY));
	unsigned char DecryptBuffer[256] = { 0 };
	unsigned int OutputLen = sizeof(DecryptBuffer);
	int inputLength = encryptStr.size();
	RSAPrivateDecrypt(DecryptBuffer, &OutputLen, (unsigned char*)encryptStr.c_str(), (PriKey.bits + 7) / 8, &PriKey);
	std::string decryptStr;
	decryptStr.assign((char *)DecryptBuffer, OutputLen);
	return decryptStr;
}
