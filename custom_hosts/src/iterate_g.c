#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"


void iterate_globals (lua_State *L)
{
	// printf("%s\n", "beginning iteration of global table.");
	lua_getglobal(L, "_G");
	lua_pushnil(L);

	while (lua_next(L, -2) != 0) {
		// 'key' (at index -2) ; 'value' (at index -1) 
		if (lua_type(L, -2) == LUA_TSTRING)
		{
			printf("* %s (%s)\n", lua_tostring(L, -2), lua_typename(L, lua_type(L, -1)));
		}
		lua_pop(L, 1); // removes 'value'; keeps 'key' for next iteration 
	}

	lua_pop(L, 1);
}


int main(int argc, char const *argv[])
{
    // load lua and libraries
    lua_State *L = lua_open();
    luaL_openlibs(L);

    iterate_globals(L);

    lua_close(L);
    return 0;
}