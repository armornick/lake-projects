-- localize used functions
local join = path.join

-- project holder
local PROJECTS = {}

---
-- utility functions
---
local function add(proj)
	PROJECTS[#PROJECTS+1] = proj
	return proj
end

local function make_sources(args)
	-- variable declarations
	local dir, result = args.directory, {}
	-- join the source files
	for i = 1, #args do
		local file = join(dir, args[i])
		table.insert(result, file)
	end
	-- return result
	return result
end

---
-- Zlib
---
local zlib = {}
zlib.DIR = 'zlib-1.2.8'
zlib.SOURCES = make_sources {
	directory = zlib.DIR;
	'adler32',  'compress', 'crc32',  'deflate',  'gzclose', 'gzlib',  'gzread', 
    'gzwrite',  'infback',  'inffast',  'inflate',  'inftrees', 'trees',  'uncompr', 'zutil'
}
zlib.INCLUDE = zlib.DIR

zlib.lib = add (c.library{'z', src=zlib.SOURCES, incdir=zlib.INCLUDE})
zlib.def = file.group{src=join(zlib.DIR, 'win32', 'zlib.def'), odir='.'}
zlib.dll = add (c.shared {'zlib', src=zlib.SOURCES, incdir=zlib.INCLUDE, compile_deps=zlib.def})

---
-- Zlib Examples
---
zlib.example = add(c.program{'example', src=join(zlib.DIR, 'test', 'example'), incdir=zlib.INCLUDE, zlib.lib})
zlib.example_d = add(c.program{'example_d', src=join(zlib.DIR, 'test', 'example'), incdir=zlib.INCLUDE, zlib.dll})
zlib.minigzip = add(c.program{'minigzip', src=join(zlib.DIR, 'test', 'minigzip'), incdir=zlib.INCLUDE, zlib.lib})
zlib.minigzip_d = add(c.program{'minigzip_d', src=join(zlib.DIR, 'test', 'minigzip'), incdir=zlib.INCLUDE, zlib.dll})

---
-- Zziplib
---
local zziplib = {}
zziplib.DIR = 'zziplib-0.13.62'
zziplib.INCLUDE = zziplib.DIR
zziplib.DEFINES = 'WIN32 ZZIP_DLL=1 __BORLANDC__'
zziplib.SOURCES = make_sources {
	directory = join(zziplib.DIR, 'zzip');
	'dir', 'err', 'fetch', 'file', 'info', 'plugin', 'stat', 'zip'
}

zziplib.dll = add( c.shared {'zziplib', src=zziplib.SOURCES, incdir=zziplib.INCLUDE, zlib.dll, defines=zziplib.DEFINES} )

---
-- Zziplib Examples
---
zziplib.zziptest = add(c.program{'zziptest', src=join(zziplib.DIR, 'test', 'zzipsetstub'), incdir=zziplib.INCLUDE, zziplib.dll})
zziplib.zzipself = add(c.program{'zzipself', src=join(zziplib.DIR, 'test', 'zzipself'), incdir=zziplib.INCLUDE, zziplib.dll})
zziplib.zzcat = add(c.program{'zzcat', src=join(zziplib.DIR, 'bins', 'zzcat'), incdir=zziplib.INCLUDE, zziplib.dll})
zziplib.zzdir = add(c.program{'zzdir', src=join(zziplib.DIR, 'bins', 'zzdir'), incdir=zziplib.INCLUDE, zziplib.dll})

---
-- LUA
---
local LUA_DIR = join("lua-5.1.5","src")
local LUALIB_SRC = join(LUA_DIR,"*")
local LUA_SRC = join(LUA_DIR,"lua ")
local LUAC_SRC = join(LUA_DIR,"luac ") .. join(LUA_DIR,"print ")
-- main applications
local luadll = add( c.shared{'lua51', defines = 'LUA_BUILD_AS_DLL', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC} )
local lua = add( c.program{'lua',src=LUA_SRC,deps=luadll,needs='math readline'} )

---
-- LuaZip (extension library)
---
local luazip = {}
luazip.DIR = join('luazip-1.2.3', 'src')
luazip.def = file.group{src=join(luazip.DIR, 'luazip.def'), odir='.'}
luazip.dll = add( c.shared{'zip', src=join(luazip.DIR, 'luazip'), deps={luadll, zziplib.dll}, incdir={LUA_DIR, zziplib.INCLUDE}, compile_deps=luazip.def} )

---
-- LZlib (extension library)
---
local lzlib = {}
lzlib.DIR = 'lzlib-0.4-work3'
lzlib.dll = add( c.shared{'lzlib', src=join(lzlib.DIR, '*'), deps={luadll, zlib.dll}, incdir={LUA_DIR, zlib.INCLUDE} } )

---
-- L-Bia (extension library)
---
local lbia = {}
lbia.DIR = join('l-bia-0.2.1', 'src')
lbia.INCLUDE = lbia.DIR
lbia.dll = add( c.shared{'lbaux', 
	src=make_sources{ directory = lbia.DIR; 'lbaux.c' }, 
	deps=luadll, incdir={LUA_DIR, lbia.INCLUDE} } )
lbia.app = add( c.program{'lbia_host', 
	src=make_sources{ directory = lbia.DIR; 'l-bia.c' }, 
	deps=luadll, incdir={LUA_DIR, lbia.INCLUDE} } )

-- execute project build
default(PROJECTS)