#pragma once

#include "perinclude.h"

#if 0

/**********************************************************************************************//**
 * \class	OpenSSLCryptoManager
 *
 * \brief	Manager for cryptoes.
 **************************************************************************************************/

class OpenSSLCryptoManager
{
	OpenSSLCryptoManager() = delete;
public:

	/**********************************************************************************************//**
	 * \brief	二进制转十六进制.
	 *
	 * \param	src	Source for the.
	 *
	 * \return	src as a std::string.
	 **************************************************************************************************/

	static std::string to_hex(const std::string & src);

	/**********************************************************************************************//**
	 * \brief	十六进制转二进制.
	 *
	 * \param	src	Source for the.
	 *
	 * \return	A std::string.
	 **************************************************************************************************/

	static std::string from_hex(const std::string & src);

	/**********************************************************************************************//**
	 * \brief	Md 5.
	 *
	 * \param	src	Source for the.
	 *
	 * \return	A std::string.
	 **************************************************************************************************/

	static std::string md5(const std::string& src);

	/**********************************************************************************************//**
	 * \brief	Rsa key.
	 *
	 * \param [in,out]	public_key 	The public key.
	 * \param [in,out]	private_key	The private key.
	 **************************************************************************************************/

	static void rsa_key(std::string& public_key, std::string& private_key);

	/**********************************************************************************************//**
	 * \brief	Rsa encrypt.
	 *
	 * \param	public_key	The public key.
	 * \param	src		  	Source for the.
	 *
	 * \return	A std::string.
	 **************************************************************************************************/

	static std::string rsa_encrypt(const std::string& public_key, const std::string& src);

	/**********************************************************************************************//**
	 * \brief	Rsa decrypt.
	 *
	 * \param	private_key	The private key.
	 * \param	src		   	Source for the.
	 *
	 * \return	A std::string.
	 **************************************************************************************************/

	static std::string rsa_decrypt(const std::string& private_key, const std::string& src);
};

#endif
