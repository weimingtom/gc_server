//Ñ¸½ÝÈí¼þQQ:1975125565

#ifndef __XML_DECRYPT_H__
#define __XML_DECRYPT_H__

#include <WTypes.h>

class CXMLDecrypt
{
public:
	virtual void* ParseXMLFile(std::string szPathFile, DWORD* size) = NULL;
};

#endif
