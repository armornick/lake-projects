---
-- CONFIGURATION
---
local join, append, writefile, readfile, concat = path.join, table.insert, file.write, file.read, table.concat
c.defaults { odir = 'build', static = true }

LUA_DIR = join("lua-5.1.5","src")
local modules = require "modules"

local function build_source (name, env)
	local tmpl = readfile(join('src', name..'.tmpl'))
	local outname = join('src', name..'.c')
	writefile(outname, utils.substitute(tmpl, env))
	return outname
end

------------------------------------
------------------------------------

local LUALIB_SRC = join(LUA_DIR,"*")
local LUA_SRC = join(LUA_DIR,"lua ")
local LUAC_SRC = join(LUA_DIR,"luac ")

-- lua libraries
local lualib = c.library{'lua51',src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC}
local luadll = c.shared{'lua51', defines = 'LUA_BUILD_AS_DLL', src=LUALIB_SRC,exclude=LUA_SRC..LUAC_SRC}

-- utility applications
local luac = c.program{'luac',src=LUAC_SRC,deps=lualib,needs='math'}
local glue = c.program{'glue',src=join('srlua','glue')}

------------------------------------
------------------------------------

local projects = {}
dofile("conf.lua")

local preloaded_modules, registers = {}, {}

if MODULES and type(MODULES) == "table" then
	for i = 1, #MODULES do
		local modname = MODULES[i]
		local M = modules[modname]
		if not M then error(string.format("module with name '%s' not found", modname)) end

		for i=1,#M do
			local modname, loader = M[i], M[i]:gsub('%.', '_')
			local mdecl = utils.substitute('\t\tREGISTER_LOADER("$(modname)", luaopen_$(loader));', {modname=modname,loader=loader})
			append(registers, mdecl)
		end

		M.incdir = LUA_DIR
		if DYNAMIC then
			M.deps = luadll; M = c.shared(M)
			append(projects, M)
		else
			M.deps = lualib; M = c.library(M)
			append(preloaded_modules, M)
		end
	end

	registers = concat(registers, "\n")
else
	registers = ""
end

-- build main lua application
local lua = {'lua',src=LUA_SRC,deps=luadll,needs='math readline'}
if DYNAMIC then
	lua.deps = luadll
else
	lua.src = build_source('lua', {PRELOAD = registers})
	append(preloaded_modules, lualib)
	lua.incdir = LUA_DIR; lua.deps = preloaded_modules
end
lua = c.program(lua)
append(projects, lua)


-- if requested, build srlua
if SRLUA then
	local srlua = {src=join('srlua','srlua'),incdir=LUA_DIR,compile_deps=glue}
	
	if type(SRLUA) == "string" then
		srlua[1] = SRLUA
	else
		srlua[1] = "srlua"
	end
	
	if DYNAMIC then
		srlua.deps = luadll
	else
		srlua.src = build_source('srlua', {PRELOAD = registers})
		srlua.incdir = 'srlua '..LUA_DIR; srlua.deps = preloaded_modules
	end

	srlua = c.program(srlua)
	append(projects, srlua)
end

------------------------------------
------------------------------------

default(projects)