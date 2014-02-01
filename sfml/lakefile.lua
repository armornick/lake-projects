
-------------------------------
-- Lua library settings
-------------------------------
local LUA_SRCDIR = 'deps/lua-5.1.5/src/'
local lualib = c.library{'lua', src=LUA_SRCDIR..'*', exclude='lua luac print'}

local compile_test = cpp.program {'sfml-test',src='src/test', static=true, needs='sfGraphics', subsystem='windows'}

local sflua_sources = 'src/sfLuaUtils src/sfLuaRenderWindow src/sfLuaTransformable src/sfLuaShape'

local renderwindow = cpp11.program {'sflua1', src='src/sflua01 '..sflua_sources, lualib, incdir='includes '..LUA_SRCDIR, static = true, needs = 'sfGraphics'}



default {compile_test, renderwindow }