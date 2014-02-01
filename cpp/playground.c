#include "lua.h"
#include "lauxlib.h"

int luaopen_playground (lua_State* L) {
	#include "playground.lua.h"
	lua_getglobal(L, "playground");
	return 1;
}
