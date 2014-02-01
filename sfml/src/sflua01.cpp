#include "sflua.hpp"

int exists(const char *fname)
{
    FILE *file;
    if (file = fopen(fname, "r"))
    {
        fclose(file);
        return 1;
    }
    return 0;
}

#define lua_dofile_if_exists(fname) if (exists(fname)) luaL_dofile(L, fname)

int main(int argc, char *argv[]) {
	lua_State *L = luaL_newstate(); /* opens Lua */
	luaL_openlibs(L); /* opens the standard libraries */
	
	luaopen_Transformable(L);
	luaopen_Shape(L);
	luaopen_RenderWindow(L);
	
	lua_dofile_if_exists("boot.lua");
	lua_dofile_if_exists("app.lua");
	
	lua_close(L);
	
	return 0;
};