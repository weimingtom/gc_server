#pragma once

#include "perinclude.h"

/**********************************************************************************************//**
 * \class	Singleton
 *
 * \brief	单例.
 *
 * \tparam	T	Generic type parameter.
 **************************************************************************************************/

template <typename T>
class TSingleton
{
	TSingleton(const TSingleton&);
	TSingleton& operator =(const TSingleton&);
public:

	/**********************************************************************************************//**
	 * \brief	Default constructor.
	 **************************************************************************************************/

	TSingleton()
	{
		assert(!ms_Singleton);
		ms_Singleton = static_cast<T*>(this);
	}

	/**********************************************************************************************//**
	 * \brief	Destructor.
	 **************************************************************************************************/

	~TSingleton()
	{
		assert(ms_Singleton);
		ms_Singleton = NULL;
	}

	/**********************************************************************************************//**
	 * \brief	得到唯一实例.
	 *
	 * \return	null if it fails, else a pointer to a T.
	 **************************************************************************************************/

	inline static T* instance()
	{
		return ms_Singleton;
	}

protected:
	static T* ms_Singleton;
};

template<typename T> T* TSingleton<T>::ms_Singleton = nullptr;
