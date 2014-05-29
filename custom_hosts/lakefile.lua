local join = path.join

--------------------------------------------------
--------------------------------------------------

local LUA_DIR = join("lua-5.1.5","src")

local LUALIB_SRC = join(LUA_DIR,"*")
local LUA_SRC = join(LUA_DIR,"lua ")
local LUAC_SRC = join(LUA_DIR,"luac ")

local lualib = c.library{'lua51',src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC, odir='bin/lua'}
local luadll = c.shared{'lua51', defines = 'LUA_BUILD_AS_DLL', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC, odir='bin/lua'}
local lua = c.program{'lua',src=LUA_SRC,deps=luadll,needs='math readline', odir='bin/lua'}
local luac = c.program{'luac',src=LUAC_SRC,deps=lualib,needs='math', odir='bin/lua'}

local glue = c.program{'glue',src='srlua51/glue'}
local srlua = c.program{'srlua',src='srlua51/srlua',deps=lualib,compile_deps=glue,incdir=LUA_DIR.." srlua51/",odir='bin/lua'}

--------------------------------------------------
--------------------------------------------------

local iterate_g = c.program{'iterateG', src={'src/iterate_g'}, deps=lualib, incdir=LUA_DIR, odir='bin'}
local tryfile = c.program{'tryfile', src={'src/dofile_if_exists'}, deps=lualib, incdir=LUA_DIR, odir='bin'}
local preloaded = c.program{'preloaded', src={'src/dofile_with_preload'}, deps=lualib, incdir=LUA_DIR, odir='bin'}
local hello = c.program{'hello', src={'src/string_preload'}, deps=lualib, incdir=LUA_DIR, odir='bin'}

--------------------------------------------------
--------------------------------------------------

default {srlua, iterate_g, tryfile, preloaded, hello}