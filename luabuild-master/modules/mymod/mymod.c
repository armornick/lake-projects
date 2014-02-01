#include "lua.h"
#include "lauxlib.h"

int luaopen_socket_ftp (lua_State *L) {
        #include "socket.ftp.lua.h"
        lua_getglobal(L, "socket.ftp");
        return 1;
}
int luaopen_socket_http (lua_State *L) {
        #include "socket.http.lua.h"
        lua_getglobal(L, "socket.http");
        return 1;
}
int luaopen_socket (lua_State *L) {
        #include "socket.lua.h"
        lua_getglobal(L, "socket");
        return 1;
}

int luaopen_ltn12 (lua_State *L) {
        #include "ltn12.lua.h"
        lua_getglobal(L, "ltn12");
        return 1;
}
int luaopen_mime (lua_State *L) {
        #include "mime.lua.h"
        lua_getglobal(L, "mime");
        return 1;
}