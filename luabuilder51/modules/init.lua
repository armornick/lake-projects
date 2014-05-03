local join = path.join

local modules = {}
local MODULEDIR = 'modules'

------------------------------------
------------------------------------

modules.lfs = {'lfs', src=join(MODULEDIR, 'luafilesystem-master', 'src')}

modules.lpeg = {'lpeg', src=join(MODULEDIR, 'lpeg-0.12')}

modules.random = {'random', src=join(MODULEDIR, 'lrandom-master')}

modules.winapi = {'winapi', 
	src={join(MODULEDIR, 'winapi-master','winapi'), join(MODULEDIR, 'winapi-master','wutils')}, 
	defines = 'PSAPI_VERSION=1',
	libs = 'psapi Mpr'
}

local LUASYS_DIR = join(MODULEDIR, 'luasys-master', 'src')
modules.sys = {'sys', 'sys.sock',
	src={join(LUASYS_DIR, 'luasys'), join(LUASYS_DIR, 'sock', 'sys_sock')},
	defines='WIN32',
	needs ='sockets',
	libs = 'winmm ws2_32'
}

------------------------------------
------------------------------------

return modules