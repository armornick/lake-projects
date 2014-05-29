#include <stdio.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int luaopen_hello(lua_State *L);

int main(int argc, char const *argv[])
{
	// load lua and libraries
    lua_State *L = lua_open();
    luaL_openlibs(L);

    // preload 'hello'
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    lua_pushcfunction(L, luaopen_hello); 
    lua_setfield(L, -2, "hello");
    lua_pop(L, 2);

    // run lua file
      if (luaL_dofile(L, "hello.lua"))
        printf("cannot run file: %s",
                 lua_tostring(L, -1));

    // close lua
    lua_close(L);
	return 0;
}

int luaopen_hello(lua_State *L)
{
	const char *code = "local hello = {} function hello.print() print('hello, world!') end return hello";

	int ret = (luaL_loadstring(L, code) || lua_pcall(L, 0, 1, 0));
	if (ret) return luaL_error(L, "error loading source: %s", lua_tostring(L, -1));
	else return 1;
}
