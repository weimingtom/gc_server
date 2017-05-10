#include "stdafx.h"
#include "IDGenerator.h"

SingletonInstance(IDGenerator);

IDGenerator::IDGenerator()
:id64_(0)
{

}

DWORD IDGenerator::GetID64()
{
	return ++id64_;
}