
-------------------------------
-- IUP location settings
-------------------------------
local IUP_DIR = 'iup-3.8_Win32_mingw4_lib/'
local IUP_LIBDIR = IUP_DIR
local IUP_INCDIR = IUP_DIR..'include/'

-------------------------------
-- Lua library settings
-------------------------------
local LUA_SRCDIR = 'lua-5.1.5/src/'
local LFS_SRCDIR = 'luafilesystem-master/src/'
local lualib = c.library{'lua51', src=LUA_SRCDIR..'*', exclude='lua luac print'}
local lfs = c.library{'lfs51', src=LFS_SRCDIR..'*', incdir=LUA_SRCDIR}

-------------------------------
-- Project Helper Functions
-------------------------------
function make_iup_function(outputn, srcfiles, links)
	local config = {
		outputn,
		src = srcfiles,
		incdir = {IUP_INCDIR, CD_INCDIR},
		libdir = {IUP_LIBDIR, CD_INCDIR},
		libs = links or 'iup',
		odir = true,
		-- subsystem = 'windows',
		needs = 'windows'
	}
	return c.program(config)
end

function make_iuplua_function(outputn, srcfiles, links)
	local config = {
		outputn,
		lualib, lfs,
		src = srcfiles,
		incdir = {IUP_INCDIR, LUA_SRCDIR},
		libdir = {IUP_LIBDIR,},
		libs = links or 'iuplua51 iup', -- ADJUST LUA VERSION IF NEEDED
		odir = true,
		subsystem = 'windows',
		needs = 'windows'
	}
	return c.program(config)
end

function make_iup_lua(outputn, srcfiles, links)
	local config = {
		outputn,
		lualib,
		src = srcfiles,
		incdir = {IUP_INCDIR, CD_INCDIR, LUA_SRCDIR},
		libdir = {IUP_LIBDIR, CD_INCDIR},
		libs = links or 'iup', 
		odir = true,
		-- subsystem = 'windows',
		needs = 'windows'
	}
	return c.program(config)
end

-------------------------------
-- IUP C Samples
-------------------------------
local cbutton = make_iup_function('button', 'samples-c/button')
local cdiag1 = make_iup_function('dialog1', 'samples-c/dialog1')
local cdiag2 = make_iup_function('dialog2', 'samples-c/dialog2')
local filedlg = make_iup_function('filedlg', 'samples-c/filedlg')

local iuplua = make_iuplua_function('iuplua', 'samples-lua/lua_init')
local iuplua2 = make_iuplua_function('iuplua', 'samples-lua/lua_init2')

-------------------------------
-- Lakefile entry point
-------------------------------
default {cbutton, cdiag1, cdiag2, filedlg, iuplua2}