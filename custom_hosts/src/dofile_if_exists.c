#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#define run_file_if_exists(L, fname) if (file_exists(fname)) (void)luaL_dofile(L, fname)

int file_exists(const char *fname);


int main(int argc, char const *argv[])
{
	// load lua and libraries
    lua_State *L = lua_open();
    luaL_openlibs(L);

    // load arguments (and pre-arguments) into a global 'arg' table
    lua_newtable(L);
    int i;
    for(i = 0; i < argc; i++)
    {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L, -2, i);
    }
    lua_setglobal(L, "arg");

    run_file_if_exists(L, "boot.lua");
    run_file_if_exists(L, "main.lua");

    lua_close(L);
	return 0;
}

int file_exists(const char *fname)
{
	FILE *f;
	f = fopen(fname, "r");

	if (!f) return 0;
	else {fclose(f); return 1;}
}