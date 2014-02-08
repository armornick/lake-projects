#include <curses.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

extern int luaopen_curses (lua_State *L);

// global lua state
static lua_State *L;

static void lua_setargs(lua_State *L, int argc, char *argv[]) {
	int i;
	lua_newtable(L);
	for (i=0; i < argc; i++) {
		lua_pushstring(L, argv[i]);
		lua_rawseti(L, -2, i);
	}
	lua_setglobal(L, "arg");
}

static void init() {
	// init curses library
	initscr();
	raw();
	keypad(stdscr, TRUE);
	// init lua interpreter
	L = luaL_newstate();
	luaL_openlibs(L);
	// init lua curses interop
	luaopen_curses(L);
}

static void deinit() {
	// close libraries
	lua_close(L);
	endwin();
}

static void run_file(const char *fname) {
	int ret;
	ret = luaL_dofile(L, fname);
	if (ret) {
		printw("error: %s\n", lua_tostring(L, -1));
		getch();
	}
}

int main (int argc, char *argv[]) {
	// initialize application
	init();
	// get argument table
	lua_setargs(L, argc, argv);
	// execute file
	run_file("app.lua");
	// close application
	deinit();
	return 0;
}