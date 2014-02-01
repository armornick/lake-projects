/*
 *  "$Id: lbconf.h,v 1.3 2008/07/09 20:31:37 br_lemes Exp $"
 *  Config file for the Lua Built-In program (L-Bia)
 *  A self-running Lua interpreter. It turns your Lua program with all
 *  required modules and an interpreter into a single stand-alone program.
 *  Copyright (c) 2007,2008 Breno Ramalho Lemes
 *
 *  L-Bia comes with ABSOLUTELY NO WARRANTY; This is free software, and you
 *  are welcome to redistribute it under certain conditions; see LICENSE
 *  for details.
 *
 *  Report bugs to <br_lemes@yahoo.com.br>
 *  http://l-bia.luaforge.net/
 */

#ifndef LBCONF_H
#define LBCONF_H

#include <stdint.h>
#include <sys/stat.h>

#ifndef _WIN32
#define LUA_USE_POSIX
#define LUA_USE_DLOPEN
#include <fcntl.h>
#include <unistd.h>
#endif /* not _WIN32 */

#ifdef LBAUX_C
#include "lapi.c"
#include "lcode.c"
#include "ldebug.c"
#include "ldo.c"
#include "ldump.c"
#include "lfunc.c"
#include "lgc.c"
#include "llex.c"
#include "lmem.c"
#include "lobject.c"
#include "lopcodes.c"
#include "lparser.c"
#include "lstate.c"
#include "lstring.c"
#include "ltable.c"
#include "ltm.c"
#include "lundump.c"
#include "lvm.c"
#include "lzio.c"
#include "lauxlib.c"
#define MINILZO_CFG_SKIP_LZO_PTR
#define MINILZO_CFG_SKIP_LZO_STRING
#define MINILZO_CFG_SKIP_LZO1X_DECOMPRESS
#define MINILZO_CFG_SKIP_LZO1X_DECOMPRESS_SAFE
#include "minilzo.c"
#endif /* not LBAUX_C */

#ifdef L_BIA_C
#define luaall_c
#include "lapi.c"
#include "lcode.c"
#include "ldebug.c"
#include "ldo.c"
#include "ldump.c"
#include "lfunc.c"
#include "lgc.c"
#include "llex.c"
#include "lmem.c"
#include "lobject.c"
#include "lopcodes.c"
#include "lparser.c"
#include "lstate.c"
#include "lstring.c"
#include "ltable.c"
#include "ltm.c"
#include "lundump.c"
#include "lvm.c"
#include "lzio.c"
#include "lauxlib.c"
#include "lbaselib.c"
#include "ldblib.c"
#include "liolib.c"
//#include "linit.c"
#include "lmathlib.c"
#include "loadlib.c"
#include "loslib.c"
#include "lstrlib.c"
#include "ltablib.c"
#define MINILZO_CFG_SKIP_LZO_PTR
#define MINILZO_CFG_SKIP_LZO_STRING
#define MINILZO_CFG_SKIP_LZO1X_DECOMPRESS_SAFE
#include "minilzo.c"
#ifdef _WIN32
#include <windows.h>
#endif /* _WIN32 */
static const luaL_Reg lualibs[] = {
  {"", luaopen_base},
  {LUA_LOADLIBNAME, luaopen_package},
  {LUA_TABLIBNAME, luaopen_table},
  {LUA_IOLIBNAME, luaopen_io},
  {LUA_OSLIBNAME, luaopen_os},
  {LUA_STRLIBNAME, luaopen_string},
  {LUA_MATHLIBNAME, luaopen_math},
//{LUA_DBLIBNAME, luaopen_debug},
  {NULL, NULL}
};
LUALIB_API void luaL_openlibs (lua_State *L) {
  const luaL_Reg *lib = lualibs;
  for (; lib->func; lib++) {
    lua_pushcfunction(L, lib->func);
    lua_pushstring(L, lib->name);
    lua_call(L, 1, 0);
  }
}
//#include "usercode.c"
//#define LBCONF_USERFUNC_INIT(L) userfunc_init(L);
//#define LBCONF_USERFUNC_DONE(L) userfunc_done(L);
#ifndef LBCONF_USERFUNC_INIT
#define LBCONF_USERFUNC_INIT(L)
#endif /* not LBCONF_USERFUNC_INIT */
#ifndef LBCONF_USERFUNC_DONE
#define LBCONF_USERFUNC_DONE(L)
#endif /* not LBCONF_USERFUNC_DONE */
#endif /* not L_BIA_C */

#endif /* LBCONF_H */
