-- 
local lfs = require "lfs"

local join, chdir = path.join, lfs.chdir
local LUA_DIR = join('lua-5.1.5', 'src')

local LUALIB_SRC = LUA_DIR.."/*"
local LUA_SRC = LUA_DIR.."/lua "
local LUAC_SRC = LUA_DIR.."/luac "..LUA_DIR.."/print "

c.defaults { odir = true, static = true }

lualib = c.library{'lua51',src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC}
lua = c.program{'lua',src=LUA_SRC,deps=lualib,needs='math readline'}
luac = c.program{'luac',src=LUAC_SRC,deps=lualib,needs='math'}
glue = c.program{'glue',src='srlua51/glue',incdir=LUA_DIR.." srlua51/"}
srlua = c.program{'srlua',src='srlua51/srlua',deps=lualib,incdir=LUA_DIR.." srlua51/"}

default {lua,luac, srlua, glue}