#ifndef _IUP_OBJECT_HPP_
#define _IUP_OBJECT_HPP_

#include <iup.h>

class IupObject {
protected:
	Ihandle *_handle;
public:
	void attribute(const char *attribName, const char *attribValue);
	char* attribute(const char *attribName);
};

class Textbox : IupObject {
public:
	Textbox();
	Textbox(const char* handle);
	
	
};


#endif // _IUP_OBJECT_HPP_