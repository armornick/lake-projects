
local join, append = path.join, table.insert
local projects = {}

cpp.defaults { static=true, odir='bin' }
cpp11.defaults { static=true, odir='bin' }

------------------------------------------
-- DLIB
------------------------------------------
local DLIB_DIR = 'dlib-18.3'
local DLIB_INCDIR = DLIB_DIR
local DLIB_SRC = join(DLIB_DIR,'dlib','all','source.cpp')
local dlib = cpp.library{'dlib', src=DLIB_SRC, needs='windows sockets', odir='lib/dlib'}

------------------------------------------
-- STLPLUS
------------------------------------------
local STLPLUS_DIR = 'stlplus3-03-11'
local STLPLUS_INCDIR = STLPLUS_DIR
local stlpport = cpp.library{'portability', src=join(STLPLUS_DIR,'portability','*'), needs='sockets', odir='lib/stlplus'}
local stlpstr = cpp.library{'strings', src=join(STLPLUS_DIR,'strings','*'), defines='NO_STLPLUS_INF NO_STLPLUS_CONTAINERS', odir='lib/stlplus'}

------------------------------------------
-- BOOST
------------------------------------------
local BOOST_DIR = join('..', 'boost_1_55_0')
local BOOST_INCDIR = BOOST_DIR
local BOOST_SRCDIR = join(BOOST_DIR, 'libs')
local boostfs = cpp.library {'filesystem', src={join(BOOST_SRCDIR,'system','src','*'), 
	join(BOOST_SRCDIR,'filesystem','src','*')}, incdir = BOOST_INCDIR, odir='lib/boost'}

------------------------------------------
-- Helper functions
------------------------------------------
function application ( args )
	local p = cpp11.program(args)
	append(projects, p)
end

function stlplus_app ( args )
	args.deps = {stlpport, stlpstr}
	args.incdir = STLPLUS_INCDIR
	application(args)
end

function dlib_app ( args )
	args.deps = dlib
	args.incdir = DLIB_INCDIR
	args.needs = 'windows sockets'
	application(args)
end

function boost_app ( args )
	args.deps = boostfs
	args.incdir = BOOST_INCDIR
	application(args)
end

------------------------------------------
-- Applications
------------------------------------------
application {'stlplus_ls', src='src/stlplus_ls', deps=stlpport, incdir=STLPLUS_INCDIR}
stlplus_app {'stlplus_ls_io', src='src/stlplus_ls_io'}
dlib_app {'dlib_ls', src='src/dlib_ls'}
boost_app {'boost_ls', src='src/boost_ls'}

stlplus_app {'stringworks', src='src/stringworks'}

application {'readlines', src='src/readlines'}

------------------------------------------
-- Lakefile entry point
------------------------------------------
default{projects}
