#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#include <stdlib.h>

#include <stdio.h>

static int lua_printglobal(lua_State *L) {
	const char *glob = luaL_checkstring(L, 1);
	printf("printing global '%s'\n", glob);
	
	lua_getglobal(L, "print");
	lua_getglobal(L, glob);
	lua_call(L, 1, 0);
	return 0;
}

static int lua_gettest (lua_State *L) {
	#include "test.lua.h"
	return 1;
}


int main(int argc, char const *argv[])
{
	lua_State *L;
	int status;

	L = luaL_newstate();
    luaL_openlibs(L); /* Load Lua libraries */

    lua_register(L, "print_global", lua_printglobal);
    lua_register(L, "test", lua_gettest);

	status = luaL_dofile(L, "boot.lua");
	if (status) {
		printf("%s\n", "Errors were detected when executing boot.lua");
	}

	lua_close(L);
	return 0;
}