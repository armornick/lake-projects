---
-- CONFIGURATION
---
local join = path.join
c.defaults { odir = true, static = true }

local LUA_DIR = join("lua-5.2.3","src")

---
-- LUA
---
local LUALIB_SRC = join(LUA_DIR,"*")
local LUA_SRC = join(LUA_DIR,"lua ")
local LUAC_SRC = join(LUA_DIR,"luac ")
-- main applications
local lualib = c.library{'lua52',src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC}
local luadll = c.shared{'lua52', defines = 'LUA_BUILD_AS_DLL', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC}
local lua = c.program{'lua',src=LUA_SRC,deps=luadll,needs='math readline'}
local luac = c.program{'luac',src=LUAC_SRC,deps=lualib,needs='math'}
-- utility applications
local glue = c.program{'glue',src=join('srlua','glue'),incdir=LUA_DIR.." srlua/"}
local srlua = c.program{'srlua',src=join('srlua','srlua'),deps=lualib,incdir=LUA_DIR.." srlua/"}
local srluad = c.program{'srluad',src=join('srlua','srlua'),deps=luadll,incdir=LUA_DIR.." srlua/"}
-- lua modules
local lfs = c.shared{'lfs', src=join('modules', 'luafilesystem-master', 'src'), deps=luadll, incdir=LUA_DIR}
local lpeg = c.shared{'lpeg', src=join('modules', 'lpeg-0.12'), deps=luadll, incdir=LUA_DIR}
local random = c.shared{'random', src=join('modules', 'lrandom-master'), deps=luadll, incdir=LUA_DIR}

local winapi = c.shared{'winapi', 
	src={join('modules', 'winapi-master','winapi.c'), join('modules', 'winapi-master','wutils.c')}, 
	deps=luadll, 
	incdir=LUA_DIR,
	defines = 'PSAPI_VERSION=1',
	libs = 'psapi Mpr'
}

local LUASYS_DIR = join('modules', 'luasys-master', 'src')
local luasys = c.shared{'sys',
	src={join(LUASYS_DIR, 'luasys.c'), join(LUASYS_DIR, 'sock', 'sys_sock.c')},
	deps=luadll,
	incdir=LUA_DIR,
	defines='WIN32',
	needs ='sockets',
	libs = 'winmm ws2_32'
}

---
-- TEST APPLICATIONS
---
local test = c.program{'test', src='modules/test',deps=lualib,incdir=LUA_DIR}


---
-- LAKE EXECUTION
---
default {lua,luac,luadll,glue,srlua,srluad,lfs,lpeg,random,winapi,luasys , test}