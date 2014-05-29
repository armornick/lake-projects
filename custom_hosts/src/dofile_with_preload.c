#include <stdio.h>

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#ifdef _WIN32
#include <windows.h>
#endif


static const luaL_Reg preloaded_libs[] = {
  {NULL, NULL}
};

static void preload_libs(lua_State *L)
{
	lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");

	const luaL_Reg *lib = preloaded_libs;
	for (; lib->func; lib++) {
		lua_pushcfunction(L, lib->func);
		lua_setfield(L, -2, lib->name);
	}

	lua_pop(L, 2);
}

static int file_exists(const char *fname)
{
	FILE *f;
	f = fopen(fname, "r");

	if (!f) return 0;
	else {fclose(f); return 1;}
}

#define run_file_if_exists(L, fname) if (file_exists(fname)) (void)luaL_dofile(L, fname)

static void do_mainfile (lua_State *L)
{
	lua_getglobal(L, "get_mainfile");
	if (lua_isfunction(L, -1))
	{
		lua_call(L, 0, 1);
		if (lua_isstring(L, -1))
		{
			const char *mainfile = lua_tostring(L, -1);
			// printf("INFO: executing file '%s'\n", mainfile);
			run_file_if_exists(L, mainfile);
		}
		lua_pop(L, 1);
	}
	lua_pop(L, 1);
}

int main(int argc, char const *argv[])
{
	// load lua and libraries
    lua_State *L = lua_open();
    luaL_openlibs(L);
    preload_libs(L);

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
    do_mainfile(L);

    lua_close(L);
	return 0;
}