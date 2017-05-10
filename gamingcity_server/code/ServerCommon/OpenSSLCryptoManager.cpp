#include "OpenSSLCryptoManager.h"

#if 0

#include <openssl/md5.h>
#include <openssl/rsa.h>

std::string OpenSSLCryptoManager::to_hex(const std::string & src)
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

		c = static_cast<unsigned char>(ch) & 0xf;
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

std::string OpenSSLCryptoManager::from_hex(const std::string & src)
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

std::string OpenSSLCryptoManager::md5(const std::string& src)
{
	if (src.empty())
		return src;

	unsigned char output_buffer[16] = { 0 };
	
	MD5_CTX c;
	MD5_Init(&c);
	MD5_Update(&c, src.c_str(), src.size());
	MD5_Final(output_buffer, &c);

	return to_hex(std::string((char*)output_buffer, 16));
}

void OpenSSLCryptoManager::rsa_key(std::string& public_key, std::string& private_key)
{
	RSA* rsa = RSA_generate_key(1024, RSA_F4, NULL, NULL);
	
	unsigned char key[1024];
	unsigned char* p_key = key;
	int len = i2d_RSAPublicKey(rsa, &p_key);
	public_key.assign((char*)key, len);

	p_key = key;
	len = i2d_RSAPrivateKey(rsa, &p_key);
	private_key.assign((char*)key, len);

	RSA_free(rsa);
}

std::string OpenSSLCryptoManager::rsa_encrypt(const std::string& public_key, const std::string& src)
{
	if (src.empty() || src.size() > 128)
		return src;

	auto p_key = public_key.c_str();
	RSA* rsa = d2i_RSAPublicKey(NULL, (const unsigned char**)&p_key, public_key.size());

	unsigned char in_buff[128] = { 0 };
	unsigned char out_buff[128] = { 0 };
	memcpy(in_buff, src.c_str(), src.size());

	RSA_public_encrypt(128, (const unsigned char*)in_buff, out_buff, rsa, RSA_NO_PADDING);

	RSA_free(rsa);

	return std::string((char*)out_buff, 128);
}

std::string OpenSSLCryptoManager::rsa_decrypt(const std::string& private_key, const std::string& src)
{
	if (src.empty() || src.size() > 128)
		return src;

	auto p_key = private_key.c_str();
	RSA* rsa = d2i_RSAPrivateKey(NULL, (const unsigned char**)&p_key, private_key.size());

	unsigned char in_buff[128] = { 0 };
	unsigned char out_buff[128] = { 0 };
	memcpy(in_buff, src.c_str(), src.size());

	RSA_private_decrypt(128, (const unsigned char*)in_buff, out_buff, rsa, RSA_NO_PADDING);
	
	RSA_free(rsa);

	return std::string((char*)out_buff);
}

#endif
