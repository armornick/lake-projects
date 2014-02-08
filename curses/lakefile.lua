local TARGETS = {}
local function add(target)
	TARGETS[#TARGETS+1] = target
	return target
end
-----------------------------------------------------
local join = path.join
c.defaults { odir='bin', static=true }
-----------------------------------------------------
-- LUA
local LUA_DIR = join("libs", "lua-5.1.5","src")
local LUALIB_SRC = join(LUA_DIR,"*")
local LUA_SRC = join(LUA_DIR,"lua ")
local LUAC_SRC = join(LUA_DIR,"luac ") .. join(LUA_DIR,"print ")
-- lua libraries
local lualib = add( c.library{'lua51', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC, odir=join("libs","lua-5.1.5",'bin')} )
local luadll = add( c.shared{'lua51', defines = 'LUA_BUILD_AS_DLL', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC,odir=join("libs","lua-5.1.5",'bin')} )
-- lua application
local lua_icon = wresource.group {src='src/lua_icon', odir=join("libs","lua-5.1.5",'bin')}
local lua = add( c.program{'lua',src={lua_icon, LUA_SRC},deps=luadll, odir=join("libs","lua-5.1.5",'bin')} )
-----------------------------------------------------
local icon = wresource.group {src='src/app', odir='bin'}

-- example applications
local hello = add( c.program{'hello', src={'src/hello', icon}, needs='curses'} )
local colors = add( c.program{'colors', src={'src/colors', icon}, needs='curses'} )
local input = add( c.program{'input', src={'src/input', icon}, needs='curses'} )
local borders = add( c.program{'borders', src={'src/borders', icon}, needs='curses'} )

-- lua curses
local lcurses = add( c.program{'lcurses', src={'src/lcurses', 'src/luacurses', icon}, deps=luadll, needs='curses', incdir=LUA_DIR} )
-----------------------------------------------------
default(TARGETS)