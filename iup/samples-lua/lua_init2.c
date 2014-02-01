/* Alternative initialization when statically linking IUP and Lua.
   Usually Iup initialization functions are not necessary because 
   they are called from inside the IupLua initialization functions.  */

#include <stdlib.h>
#include <stdio.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <iup.h>
//#include <iupcontrols.h>

#include <iuplua.h>
//#include <iupluacontrols.h>


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

int main(int argc, char **argv)
{
	IupOpen(&argc, &argv);
	// IupControlsOpen();

  /* Lua 5 initialization */
	lua_State *L = luaL_newstate(); /* opens Lua */
	luaL_openlibs(L); /* opens the standard libraries */

	iuplua_open(L);      /* Initialize Binding Lua */
	luaopen_lfs(L);
	// iupcontrolslua_open(L); /* Initialize the additional controls binding Lua */

	lua_dofile_if_exists("boot.lua");
	lua_dofile_if_exists("app.lua");

	// IupMainLoop(); /* could be here or inside "myfile.lua" */

	// iuplua_close(L);
	lua_close(L);

	return EXIT_SUCCESS;

}
