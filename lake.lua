#!/usr/bin/env lua
-- Lake - a build framework in Lua
-- Freely distributable for any purpose, as long as copyright notice is retained. (X11/MIT)
-- (And remember my dog did not eat your homework)
-- Steve Donovan, 2007-2013

local usage = [[
Lake version 1.4  A Lua-based Build Engine
  lake <flags> <assigments> <target(s)>
  * flags:
    -v verbose
    -q quiet
    -t test (show but don't execute commands)
    -n don't synthesize target
    -d initial directory
    -b basic print (don't show full commands)
    -s don't compile strictly
    -g debug build  (also DEBUG=1)
    -j N run jobs in parallel where possible.
    -f FILE read a named lakefile
    -e EXPR evaluate a lakefile expression
    -L MOD load a module lake.MOD first
    -l FILE build a shared library/DLL
    -lua FILE build a Lua C extension
    -p FILE build a program
    -w write out unsatisfied needs to lakeconfig.lua
    -lua FILE build a Lua binary extension
    -install FILE install a new need or language
    -C really clean a directory tree!

  * assignments: arguments of the form VAR=STRING assign the string
    to the global VAR. The env variable LAKE_PARMS may contain
    extra assignments.

  * target(s): any targets of the lakefile; if a file with a recognized
    extension, build and run, passing any remaining arguments, unless -n
    is specified. Lua scripts are run directly using Lake.

  Without arguments, use a file called 'lakefile' or 'lakefile.lua'

]]

local lfs = require 'lfs'
local append = table.insert
local env = os.getenv
local unpack = unpack
local log = print
local attributes = lfs.attributes
local verbose = false
local specific_targets = {}
local nbuild = 0
local all_targets_list = {}
local change_dir,finalize,exists,Windows

TESTING = false
DIRSEP = package.config:sub(1,1)
Windows = DIRSEP == '\\'
WINDOWS = Windows -- we'll review this later

---some useful library functions for manipulating file paths, lists, etc.
-- search for '--end_of_libs' to skip to the Meat of the Matter!
-- See lakelibs.luadoc for documentation

function warning(reason,...)
    reason = reason or '?'
    local str = reason:format(...)
    io.stderr:write('lake: ',str,'\n')
end

function quit(reason,...)
    warning(reason,...)
    finalize(reason and reason:format(...))
    os.exit(1)
end

function choose(cond,v1,v2)
    if type(cond) == 'string' then
        cond = cond~='0' and cond~='false'
    end
    if cond then return v1 else return v2 end
end

function pick(a,b)
    if a ~= nil then return a else return b end
end

file = {ext='*'}
COPY = choose(Windows,'copy','cp')
file.compile = '$(COPY) $(DEPENDS) $(TARGET)'


if Windows then
    QUIET_CMD = '> nul'
    file.filter = function() return nil end
end

function file.time(fname)
    if type(fname) ~= 'string' then
        return fname.time
    end
    local time,err = attributes(fname,'modification')
    if time then
        return time
    else
        return -1
    end
end

local function is_object(t)
    return type(t) == 'table' and #t == 0 and t.time
end

local filetime = file.time

function file.generate_target(r,tname,root)
    local odir = r.output_dir
    if root and odir then
        tname = tname:sub(#root+2)
        local d = path.dirname(path.join(odir,tname))
        if not path.isdir(d) then
            path.mkdir(d)
        end
        return tname
    end
end

local function fail (e,verbose)
    if verbose then quit(e) else return nil,e end
end

function file.copy(src,dest,v)
    local inf,err = io.open(src,'rb')
    if err then return nil,err end
    local dir = path.splitpath(dest)
    if dir ~= '' and not path.isdir(dir) then
        local ok, e = path.mkdir(dir)
        if not ok then return fail(e,v) end
    end
    local outf,err = io.open(dest,'wb')
    if err then inf:close(); return fail(err,v) end
    outf:write(inf:read('*a'))
    outf:close()
    inf:close()
    if v then
        log ('copying '..src..' to '..dest)
    end
    return true
end

function file.write (name,text)
    local outf,err = io.open(name,'w')
    if not outf then return false,err end
    outf:write(text);
    outf:close()
    return true
end

function file.read (name)
    local inf,err = io.open(name,'r')
    if not inf then return false,err end
    local res = inf:read('*a')
    inf:close()
    return res
end

function file.touch(name)
    if type(name) ~= 'string' then
        name.time = utils.clock()
    end
    if not path.exists(name) then
        return file.write(name,'dummy')
    else
        return lfs.touch(name)
    end
end

function file.temp ()
    local res = os.tmpname()
    if Windows then -- note this necessary workaround for Windows
        res = env 'TMP'..res
    end
    return res
end

function file.temp_copy (s,ext)
    local res = file.temp()
    if ext then res = res .. ext end
    local ok,err = file.write(res,s)
    if not ok then return nil,err end
    return res
end

local canonical_path

function file.copy_tree (src,dest)
    local res
    if PLAT=='Windows' then
        src = canonical_path(src)
        dest = canonical_path(dest)
        res = utils.execute('xcopy /S /E /I /Q "'..src..'" "'..dest..'"',true)
    else
        res = utils.execute('cp -R '..src..' '..dest,true)
    end
    return res
end

function file.find(...)
    local t_remove = table.remove
    local args = {...}
    if #args == 1 then return exists(args[1]) end
    for i = 1,#args do
        if type(args[i]) == 'string' then args[i] = {args[i]} end
    end
    local p,q = args[1],args[2]
    local pres = {}
    for _,pi in ipairs(p) do
        for _,qi in ipairs(q) do
            local P
            if qi:find '^%.' then  P = pi..qi
            else  P = pi..DIRSEP..qi
            end
            P = exists(P)
            if P then append(pres,P) end
        end
    end
    if #pres == 0 then return pres end
    local a1= t_remove(args,1)
    local a2 = t_remove(args,1)
    if #args > 0 then
        return file.find(pres,unpack(args))
    else
        return pres,a1,a2
    end
end

find = {}

if Windows then
    SYS_PREFIX = ''
else
    SYS_PREFIX = {'/usr','/usr/share','/usr/local'}
end

function find.include_path(candidates)
    local res = file.find(SYS_PREFIX,'include',candidates)
    if #res == 0 then return nil end -- can't find it!
    res = res[1] -- _might_ be other instances, probably pathological?
    if type(candidates)=='string' then candidates = {candidates} end
    for _,c in ipairs(candidates) do
        local i1,i2 = res:find(c..'$')
    end
    return res
end

local function at(s,i) return s:sub(i,i) end

path = {}
local join, update_pwd, splitpath

function path.exists(path,fname)
    if fname then fname = join(path,fname) else fname = path end
    if attributes(fname) ~= nil then
        return fname
    end
end
exists = path.exists
file.exists = exists

function path.isdir(path)
    if path:match '/$' then path = path:sub(1,-2) end
    return attributes(path,'mode') == 'directory'
end
local isdir = path.isdir

function path.isfile(path)
    return attributes(path,'mode') == 'file'
end
local isfile = path.isfile

function path.isabs(path)
    if Windows then return path:find '^"*%a:' ~= nil
    else return path:find '^/' ~= nil
    end
end
local isabs = path.isabs

function path.abs(...)
    local args = {...}
    if isabs(args[1]) then return args[1] end
    if not PWD then
        update_pwd()
    end
    table.insert(args,1,PWD:sub(1,-2))
    return table.concat(args,DIRSEP)
end

local function quote_if_necessary (file)
    if not file then return '' end
    if type(file) == 'string' and file:find '%s' then
        if file:find '\\$' then
            file = file .. '\\\\'
        end
        file = '"'..file..'"'
    end
    return file
end
path.quote = quote_if_necessary

-- this is used for building up strings when the initial value might be nil
--  s = concat_str(s,"hello")
local function concat_str (v,u,no_quote)
    if not no_quote then u = quote_if_necessary(u) end
    if type(v) == 'table' then v = table.concat(v,' ') end
    return (v or '')..' '..u
end

local get_files
function path.get_files (files,path,pat,recurse)
    for f in lfs.dir(path) do
        if f ~= '.' and f ~= '..' then
            local file = f
            if path ~= '.' then file  = join(path,file) end
            if recurse and isdir(file) then
                get_files(files,file,pat,recurse)
            elseif f:find(pat) then
                append(files,file)
            end
        end
    end
end
get_files = path.get_files

function path.get_directories (dir)
    local res = {}
    for f in lfs.dir(dir) do
        if f ~= '.' and f ~= '..' then
            local path = join(dir,f)
            if isdir(path) then append(res,path) end
        end
    end
    return res
end
get_directories = path.get_directories

function path.files_from_mask (mask,recurse)
    local path,pat = splitpath(mask)
    if not pat:find('%*') then return nil end
    local files = {}
    if path=='' then path = '.' end
    -- turn shell-style wildcard into Lua regexp
    pat = pat:gsub('%.','%%.'):gsub('%*','.*')..'$'
    get_files(files,path,pat,recurse)
    return files
end
local files_from_mask = path.files_from_mask

local list_

function path.mask(mask)
    return list_(files_from_mask(mask))
end
local mask = path.mask

function path.is_mask (pat)
    return pat:find ('*',1,true)
end

function path.dirs(dir)
    return list_(get_directories(dir))
end

function path.splitpath(path)
    local i = #path
    local ch = at(path,i)
    while i > 0 and ch ~= '/' and ch ~= '\\' do
        i = i - 1
        ch = at(path,i)
    end
    if i == 0 then
        return '',path
    else
        return path:sub(1,i-1), path:sub(i+1)
    end
end
splitpath = path.splitpath

function path.splitext(path)
    local i = #path
    local ch = at(path,i)
    while i > 0 and ch ~= '.' do
        if ch == '/' or ch == '\\' then
            return path,''
        end
        i = i - 1
        ch = at(path,i)
    end
    if i == 0 then
        return path,''
    else
        return path:sub(1,i-1),path:sub(i)
    end
end
local splitext = path.splitext

function path.dirname(P,strict)
    if isdir(P) then return P end
    local p1,p2 = splitpath(P)
    return p1
end
local dirname = path.dirname

function path.basename(path)
    local p1,p2 = splitpath(path)
    return p2
end
local basename = path.basename

function path.extension_of(path)
    local p1,p2 = splitext(path)
    return p2
end
local extension_of = path.extension_of

local user_home = NEW_HOME

local function find_user_home()
    if not user_home then
        user_home = env 'HOME'
        if not user_home then -- has to be Windows
            user_home = env 'USERPROFILE' or (env 'HOMEDRIVE' .. env 'HOMEPATH')
        elseif ENV.USER == 'root' then
            user_home = utils.shell("echo ~"..ENV.SUDO_USER)
        end
    end
end

function path.expanduser(path)
    if path:sub(1,1) == '~' then
        find_user_home()
        return user_home..path:sub(2)
    else
        return path
    end
end

function path.replace_extension (path,ext)
    local p1,p2 = splitext(path)
    return p1..ext
end
local replace_extension = path.replace_extension

function path.join(p1,p2,...)
    if select('#',...) > 0 then
        local p = path.join(p1,p2)
        local args = {...}
        for i = 1,#args do
            p = join(p,args[i])
        end
        return p
    end
    if isabs(p2) then return p2 end
    local endc = at(p1,#p1)
    if endc ~= '/' and endc ~= '\\' then
        p1 = p1..DIRSEP
    end
    return p1..p2
end
join = path.join

local _mkdir

function _mkdir(p)
    if p:find '^%a:/*$' then -- windows root drive case
        return true
    end
    if not path.isdir(p) then
        local subp = p:match '(.+)/[^/]+$'
        if subp and not _mkdir(subp) then return nil,'cannot create '..subp end
        return lfs.mkdir(p)
    else
        return true
   end
end

function path.mkdir (p)
    if Windows then p = p:gsub('\\','/') end
    return _mkdir(p)
end

function canonical_path (p)
    if type(p) ~= 'string' then return p end
    if Windows then
        return (p:gsub('/','\\')) --:lower())
    else
        return p
    end
end

local function canonical_paths (deps)
    if Windows then for i = 1,#deps do
        deps[i] = canonical_path(deps[i])
    end end
    return deps
end

utils = {}

local start_t, msg_t

utils.clock = os.clock

function utils.split(s,re)
    local i1 = 1
    local ls = {}
    re = re or '%s+'
    while true do
        local i2,i3 = s:find(re,i1)
        if not i2 then
            append(ls,s:sub(i1))
            return ls
        end
        append(ls,s:sub(i1,i2-1))
        i1 = i3+1
    end
end
local split = utils.split

function utils.split2(s,delim)
  return s:match('([^'..delim..']+)'..delim..'(.*)')
end

local lua52 = rawget(_G,'setfenv') == nil

function utils.execute (cmd,quiet)
    if quiet then
        local null = " > "..choose(Windows,'NUL','/dev/null').." 2>&1"
        cmd = cmd .. null
    end
    local res1,res2,res2 = os.execute(cmd)
    if not lua52 then
        return res1==0,res1
    else
        return res1,res2
    end
end

function utils.subst(str,exclude,T)
    local count
    T = T or _G
    repeat
        local excluded = 0
        str, count = str:gsub('%$%(([%w,_]+)%)',function (f)
            if exclude and exclude[f] then
                excluded = excluded + 1
                return '$('..f..')'
            else
                local s = T[f]
                if not s then return ''
                else return s end
            end
        end)
    until count == 0 or exclude
    return str
end
local subst = utils.subst

function utils.substitute (str,T) return subst(str,nil,T) end

function utils.shell_nl(cmd,...)
    cmd = subst(cmd):format(...)
    local inf = io.popen(cmd..' 2>&1','r')
    if not inf then return '' end
    local res = inf:read('*a')
    inf:close()
    return res
end

-- a convenient function which gets rid of the trailing line-feed from shell_nl()
function utils.shell(cmd,...)
    return (utils.shell_nl(cmd,...):gsub('\n$',''))
end
local shell = utils.shell

local marker = string.char(4)
local function hide_spaces(q) return q:gsub(' ',marker) end

function utils.split_list(s)
    local n_esc
    s = s:gsub('^%s+',''):gsub('%s+$','') -- trim the string
    -- spaces can be escaped with double quotes
    s, n_esc = s:gsub('"[^"]+"',hide_spaces)
    local i1 = 1
    local ls = {}
    local function append_item (item)
        item = item:gsub('\\ ',' ')
        append(ls,item)
    end
    -- In Unix spaces are escaped with \
    local pat = choose(Windows,'.','[^\\]')..'[%s,]+'
    while true do
        local i2,i3 = s:find(pat,i1)
        if not i2 then
            append_item(s:sub(i1))
            break
        end
        append_item(s:sub(i1,i2))
        i1 = i3+1
    end
    for i = 1,#ls do
        local item = ls[i]
        if item:match(marker) then
            item = item:gsub(marker,' ')
            -- unquote fully quoted items
            if item:match '^"' then
                item = item:sub(2,-2)
            end
            ls[i] = item
        end
    end
    return ls
end
local split_list = utils.split_list
local expand_args

function utils.forall(ls,action)
    ls = expand_args(ls)
    for i,v in ipairs(ls) do
        action(v)
    end
end
local forall = utils.forall

function utils.remove(items,single)
    if  type(items) == 'string' then
        if single then
            items = {items}
        else
            items = split_list(items)
        end
    end
    for _,f in ipairs(items) do
        if type(f)=='string' and os.remove(f) then
            log ('removing',f)
        end
    end
end

local exec

function utils.remove_files (mask)
    local cmd
    if Windows then
        cmd = 'del '..mask
    else
        cmd = 'rm '..mask
    end
    exec(cmd)
end

function utils.make_callable (obj,fun)
    local mt = getmetatable(obj)
    if not mt then
        mt = {}
        setmetatable(obj,mt)
    end
    mt.__call = function(obj,...) return fun(...) end
    return mt
end

function utils.quote(fun)
    return function(...) return fun(...) end
end

function utils.which (prog)
    if isabs(prog) then return prog end
    if Windows then -- no 'which' commmand, so do it directly
        if extension_of(prog) == '' then prog = prog..'.exe' end
        local path = split(env 'PATH',';')
        for dir in list_(path) do
            local file = exists(dir,prog)
            if file then return file end
        end
        return false
    else
        local res = shell('which %s 2> /dev/null',prog)
        if res == '' then return false end
        return res
    end
end

function utils.copy_table (t)
    local res = {}
    for k,v in pairs(t) do
        res[k] = v
    end
    return res
end

function is_simple_list (t)
    return type(t) == 'table' and #t > 0
end

local function append_table(l1,l2,no_overwrite)
    if not l2 then return end
    for k,v in pairs(l2) do
        if not no_overwrite or l1[k] == nil then
            l1[k] = v
        end
    end
    return l1
end
utils.append_table = append_table

list = {}

local append_list,index_list

function list.extend(l1,l2)
    for i,v in ipairs(l2) do
        append(l1,v)
    end
    return l1
end
append_list = list.extend

function list.append_unique(l,v)
    if not index_list(l,v) then
        append(l,v)
    end
end

append_unique = list.append_unique

function list.extend_unique(l1,l2)
    l1 = l1 or {}
    for i,v in ipairs(l2) do
        list.append_unique(l1,v)
    end
    return l1
end
append_list_unique = list.extend_unique

function list.copy (l1)
    return append_list({},l1)
end

function utils.set(ls)
    local res = {}
    for item in list_(ls) do
        res[item] = true
    end
    return res
end

function list.erase(l1,l2)
    for i,v in ipairs(l2) do
        local idx = index_list(l1,v)
        if idx then
            table.remove(l1,idx)
        end
    end
end

function list.concat(ls,pre,sep)
    local res = ''
    for i,v in ipairs(ls) do
        if v ~= '' then
            if v:match '%s' and not v:match '"' then
                v = quote_if_necessary(v)
            end
            res = res..pre..v..sep
        end
    end
    return res
end

function list.index(ls,val)
    for i,v in ipairs(ls) do
        if v == val then return i end
    end
end
index_list = list.index

function list.find(ls,field,value)
    for i,v in ipairs(ls) do
        if v[field] == value then
            return v
        end
    end
end

function list_(ls)
    if type(ls) == 'string' then
        ls = split_list(ls)
    end
    local n = #ls
    local i = 0
    return function()
        i = i + 1
        if i > n then return nil end
        return ls[i]
    end
end

utils.make_callable(list,list_)

function list.column(ls,f)
    local res = {}
    for i,t in ipairs(ls) do
        append(res,t[f])
    end
    return res
end
column_list = list.column

function list.parm_concat(ls,istart)
    local s = ' '
    istart = istart or 1
    for i = istart,#ls do
        local a = ls[i]
        if a:find(' ') then a = '"'..a..'"' end
        s = s..a..' '
    end
    return s
end

local found_threads, winapi, posix
if Windows then
    found_threads, winapi = pcall(require, 'winapi')
    if found_threads then
        utils.sleep = winapi.sleep
    end
else
    found_threads, posix = pcall(require, 'posix')
	if found_threads and posix.clock_gettime then
		function utils.clock()
			local secs,nsec = posix.clock_gettime()
			return secs + nsec/1e9
		end
        function utils.sleep (msec)
            local sec = math.floor(msec/1000)
            msec = msec - 1000*sec
            posix.nanosleep(sec,1e6*msec)
        end
	end
end

--end_of_libs---------------------------------------------

local job_execute, jobs_clear

local function command_line (cmd)
    local tmpfile,cmdline = file.temp()
    if cmd:match '>%s*%S+$' then
        cmdline = cmd..' 2> '..tmpfile
    else
        cmdline = cmd..' > '..tmpfile..' 2>&1'
    end
    return cmdline,tmpfile
end

local function execute_wrapper (cmd,t,callback)
    local cmdline,tmpfile = command_line(cmd)
    local ok,code = utils.execute(cmdline)
    local inf = io.open(tmpfile,'r')
    callback(ok,code,inf)
    inf:close()
    os.remove(tmpfile)
end

local n_threads = 1

if found_threads then

    local processes,outputs = {},{}
    local spawn, wait
    if winapi then
        local comspec = env('COMSPEC')..' /c '

        function spawn(cmd)
            return winapi.spawn_process(comspec..cmd)
        end

        function wait(ps)
            local idx,err = winapi.wait_for_processes(ps,false)
            if err then return nil, err end
            local p = processes[idx]
            return idx,p:get_exit_code(),err
        end
    else
        function spawn(cmd)
            local cpid = posix.fork()
            if cpid == 0 then
                if posix.exec('/bin/sh','-c',cmd) == -1 then
                    local msg,code = posix.errno()
                    os.exit(code)
                end
            else
                return cpid
            end
        end

        function wait(ps)
            local pid,status,code = posix.wait(-1)
            if not pid then return nil,nil,code end
            local idx = index_list(ps,pid)
            return idx,code
        end
    end

    local function jobs_wait()
        if #processes == 0 then return end
        local idx,code,err = wait(processes)
        if err then return nil, err end
        local item, p = outputs[idx], processes[idx]
        local inf,err = io.open(item.tmp,'r')
        item.callback(code == 0, code, inf)
        if item.read then item.read:close() end
        inf:close()
        if winapi then
            p:close()
        end
        os.remove(item.tmp)

        table.remove(processes,idx)
        table.remove(outputs,idx)
    end

    function jobs_clear()
        while #processes > 0 do jobs_wait() end
    end

    local current_rule

    function job_execute (cmd,t,callback)
        if n_threads < 2 then
            execute_wrapper(cmd,t,callback)
        else
            -- crucial bit of synchronization: only run processes in parallel
            -- generated from the _same rule_
            if t.rule ~= current_rule then -- so clear the old rule's job queue
                jobs_wait()
                current_rule = t.rule
            end
            if #processes == n_threads then -- job queue is full
                jobs_wait()
            end
            if #processes < n_threads then
                local cmdline,tmpfile = command_line(cmd)
                local p,r = spawn(cmdline)
                append(outputs,{read=r,callback=callback,tmp=tmpfile})
                append(processes,p)
            end
        end
    end

else
    job_execute = execute_wrapper
    jobs_clear = function() end
end


-- for debug purposes: dump out a table
function dump(ls,msg)
    log ('<<',msg or '')
    if type(ls) == 'table' then
        for i,v in pairs(ls) do
            log(i,v)
        end
    else
        log(ls)
    end
    log '>>'
end

--- answering the question: is an include file within the MSVC include path?
local msvc_includes
local msvc_include_cache = {}

local function within_msvc_include_path (file)
    if not msvc_includes then
        local include = env 'INCLUDE':gsub(';$',''):lower()
        msvc_includes = split(include,';')
    end
    local res = msvc_include_cache[file]
    if res ~= nil then return res end
    local dir = splitpath(file):lower()
    for d in list_(msvc_includes) do
        local i1,i2 = dir:find(d,1,true)
        if i1==1 and i2 == #d then
            res = true
            break
        end
    end
    msvc_include_cache[file] = res
    return res
end


local function concat(s1,s2) return (s1 or '')..' '..s2 end

local function concat_if_table(t,field)
    local val = t[field]
    if type(val) == 'table' then
        t[field] = table.concat(val,' ')
    end
end

local interpreters = {
    ['.lua'] = 'lua', ['.py'] = 'python',
}

local check_options

LIBS = ''
CFLAGS = ''

local function inherits_from (c)
    local mt = {__index = c}
    return function(t)
        return setmetatable(t,mt)
    end
end

local function appender ()
    local t = {}
    utils.make_callable(t,function(a)
        check_options(a)
        append_table(t,a)
    end)
    return t
end

lake = {}

function lake.set_log (f)
    log = f or function() end
end

local baselang = {}
baselang.defaults = appender()

function lake.new_lang(bl,t)
    bl = bl or baselang
    t = t or {}
    local lang = inherits_from(bl)(t)
    lang.defaults = appender()
    return lang
end
local new_lang = lake.new_lang

c = new_lang(nil,{ext='.c'})

-- these chaps inherit from C lang for their default compile behaviour
cpp = new_lang(c,{ext='.cpp'})
c99 = new_lang(c,{ext='.c'})
s = new_lang(c,{ext='.s'})

-- precompiled C++ headers
cpp_ch = new_lang(cpp,{ext='.h'})

-- experimental C++11 support
cpp11 = new_lang(cpp)

wresource = {ext='.rc'}

local extensions = {
    ['.c'] = c, ['.cpp'] = cpp, ['.cxx'] = cpp, ['.C'] = cpp,
    ['.s'] = s,
}

local deps_arg, concat_arg, isrule, istarget

function lake.register(lang,extra)
    extensions[lang.ext] = lang
    if extra then
        for e in list_(deps_arg(extra)) do
            extensions[e] = lang
        end
    end
end

-- @parms any <var>=<value> pair means set the global variable <var> to the <value>, as a string.
local function process_var_pair(a)
    local var,val = utils.split2(a,'=')
    if var then
        _G[var] = val
        return true
    end
end

local function rebase (deps,base)
    if base then
        for i = 1,#deps do
            deps[i] = join(base,deps[i])
        end
    end
    return deps
end

local get_target_list

-- @deps dependencies are stored as lists, but if you go through deps_arg, then any string
-- delimited with ' ' or ',' will be converted into an appropriate list.
-- This function is guaranteed to return a plain list, and will wrap other objects like
-- targets and rules appropriately. Strings, targets, rules and target lists are
-- allowed.
--
-- Third argument determines whether the result must be reduced to strings.
function deps_arg(deps,base,returns_strings)
    local T = type(deps)
    if T=='table' and not is_simple_list(deps) then
        if returns_strings and isrule(deps) then return deps:get_targets()
        else
            local tl = get_target_list(deps)
            if not tl and istarget(deps) then
                tl = {deps}
            end
            if tl then
                return returns_strings and column_list(tl,'target') or tl
            else
                return {deps}
            end
        end
    end
    if T=='string' then
        return rebase(split_list(deps),base)
    elseif T=='table' then
        local res = {}
        for i = 1,#deps do
            append_list(res,deps_arg(deps[i],base,returns_strings))
        end
        deps = res
    end
    return deps
end

lake.deps_arg = deps_arg

-- expand_args() goes one step further than deps_arg(); it will expand a wildcard expression into a list of files
-- as well as handling lists as strings. If the argument is a table, it will attempt
-- to expand each string - e.g. {'a','b c'} => {'a','b','c'}
function expand_args(src,ext,recurse,base)
    local items = deps_arg(src,base,true)
    local res = {}
    for i,item in ipairs(items) do
        if type(item) == 'string' then
            if ext and isdir(item) and not isfile(item..ext) then
                item = join(item,'*') -- directory is an implicit wildcard
            end
            if item:find '%*' then
                if item:find '%*$' then item = item..(ext or '*') end
                append_list(res,files_from_mask(item,recurse))
            else
                if ext and extension_of(item)=='' then item = item..ext end
                append(res,item)
            end
        end
    end
    canonical_paths(res)
    return res
end

lake.expand_args = expand_args

utils.foreach = utils.quote(forall)

local tmt,tcnt = {},1
tmt.__index = tmt

function istarget (t)
    return type(t) == 'table' and getmetatable(t) == tmt
end

function tmt:__tostring ()
    return 'target: '..self.target..(self.rule and tostring(self.rule) or '')
end

local function remove_quotes (ls)
    if not ls then return ls end
    for i,s in ipairs(ls) do
        if type(s) == 'string' and s:find '^"' then
            ls[i] = s:sub(2,-2)
        end
    end
    return ls
end

local function new_target(tname,deps,cmd,upfront,dont_massage_deps)
    local t = setmetatable({},tmt)
    if tname == '*' then
        tname = '*'..tcnt
        tcnt = tcnt + 1
    elseif not tname then
        quit("target is nil!")
    end
    t.target = canonical_path(tname)
    if not dont_massage_deps then
        deps = remove_quotes(deps_arg(deps))
    end
    t.deps = deps
    t.cmd = cmd
    if upfront then
        table.insert(all_targets_list,1,t)
    else
        append(all_targets_list,t)
    end
    return t
end

local function target_add_deps (t,deps)
    if t.deps == nil then
        t.deps = deps
    else
        append_list_unique(t.deps,deps)
    end
end

function lake.phony(deps,cmd)
    return new_target('*',deps,cmd,true)
end

--- @doc [Rule Objects] ----
-- serve two functions (1) define a conversion operation between file types (such as .c -> .o)
-- and (2) manage a list of dependent files.

local rt = {} -- metatable for rule objects
rt.__index = rt

-- create a rule object, mapping input files with extension @in_ext to
-- output files with extension @out_ext, using an action @cmd
-- Most of the customization of rules comes from setting a lang field.
function rule(out_ext,in_ext,cmd,label)
    local r = {}
    r.in_ext = in_ext
    r.out_ext = out_ext
    r.cmd = cmd
    r.targets = {}
    r.label = label
    r.depends_on = rt.depends_on
    setmetatable(r,rt)
    return r
end

function rt:__tostring ()
    return 'rule: '..(self.label or self.cmd)..' ('..#self.targets..')'
end


local deps_from_d_file

-- add a new target to a rule object, with name @tname and optional dependencies @deps.
-- @tname may have an extension which overrides the default. If the in-extension is '*',
-- then we use this extension for the output as well, which must be in a different directory
-- with r.output_dir
--
-- if there are no explicit dependencies, we assume that we are dependent on the input file.
-- Also, any global dependencies that have been set for this rule with depends_on().
-- In addition, we look for .d dependency files that have been auto-generated by the compiler.
function rt.add_target(r,tname,deps,root)
    local in_ext,out_ext, ext = r.in_ext,r.out_ext
    local lang = r.lang
    tname,ext = splitext(tname)
    if in_ext == '*' then -- assume that out_ext is also '*'
        in_ext = ext
        out_ext = ext
    end
    -- we use the given input extension by default, but fall back to the default extension
    if ext == '' then ext = in_ext end
    local input = tname..ext

    -- usually file.IN goes to file.OUT, but a language can ask
    -- for custom behaviour here.
    local new_target_name
    local target_name = tname..out_ext
    if lang and lang.generate_target then
        new_target_name = lang.generate_target(r,target_name,root)
    end
    if not new_target_name then
        target_name = basename(target_name)
    else
        target_name = new_target_name
    end
    local base = basename(tname)
    -- by default, target is created in cwd, but it can be put into a subdirectory
    if lang and lang.output_in_same_dir then
        -- this is used by compilers like javac which generate output files
        -- within the same directory as the source files
        target_name = replace_extension(input,r.out_ext)
    else
        if FULL_OUTPUTNAME then
            local dir = path.dirname(tname)
            if #dir > 0 then
                dir = dir:gsub('[/\\]','__'):gsub('%.','_') .. '__'
            end
            target_name = dir .. target_name
        end
        if r.output_dir then
            target_name = join(r.output_dir,target_name)
        end
    end

    -- the files which this target is dependent on.
    -- We are always dependent on the input!
    if deps then
        deps = deps_arg(deps)
    else
        deps = {}
    end
    table.insert(deps,1,input)
    -- we can be dependent on headers extracted from a .d file
    if lang and lang.uses_dfile and not NODEPS then
        local ddeps = deps_from_d_file(replace_extension(target_name,'.d'))
        if ddeps then
            append_list_unique(deps, ddeps)
        end
    end
    -- finally the rule may have a set of prequisites that applies to all targets;
    -- this is used for explicit headers field when compiling.
    if r.global_deps then
        append_list_unique(deps,r.global_deps)
    end

    local t = new_target(target_name,deps,r.cmd,false,true)
    t.name = tname
    t.input = input
    t.rule = r
    t.base = base
    t.cflags = r.cflags
    append(r.targets,t)
    return t
end

-- @doc the rule object's call operation is overloaded, equivalent to add_target() with
-- the same arguments @tname and @deps.
-- @tname may be a shell wildcard, however.
function rt.__call(r,tname,deps)
    if tname:find('%*') then
        if extension_of(tname) == '' then
            tname = tname..r.in_ext
        end
        for f in mask(tname) do
            r:add_target(f,deps)
        end
    else
        r:add_target(tname,deps)
    end
    return r
end


function rt:get_targets()
    local ldeps =  column_list(self.targets,'target')
    if #ldeps == 0 and self.parent then
        -- @doc no actual files were added to this rule object.
        -- But the rule has a parent, and we can deduce the single file to add to this rule
        -- (This is how a one-liner like c.program 'prog' works)
        local base = splitext(self.parent.target)
        local t = self:add_target(base)
        return {t.target}
    else
        return ldeps
    end
end

function isrule(r)
    --# return r.targets ~= nil
    return getmetatable(r) == rt
end

function rt.depends_on(r,s)
    s = deps_arg(s)
    if not r.global_deps then
        r.global_deps = s
    else
        append_list(r.global_deps,s)
    end
end


local function parse_deps_line (line)
    line = line:gsub('\n$','')
    -- each line consists of a target, and a list of dependencies; the first item is the source file.
    local drive,rest = line:match '^(%a:)(\\.+)'
    if drive then line = rest end
    local target,deps = line:match('([^:]+):%s*(.+)')
    if target and deps then
        -- paths-with-spaces remain a nuisance!
        -- cl will always put these in quotes, but gcc escapes spaces
        -- Internally, Lake keeps such filenames in quotes
        local esc,repl = '\\ ','\001'
        local escaped = deps:match(esc)
        if escaped then
            deps = deps:gsub(esc,repl)
        end
        deps = split_list(deps)
        if escaped then for i = 1,#deps do
            local f = deps[i]:gsub(repl,' ')
            deps[i] = quote_if_necessary(f)
        end end
        return target,deps
    end
end

function deps_from_d_file(fname)
    local line,err = file.read(fname)
    if not line or #line == 0 then return false,err end
    local _,deps = parse_deps_line(line:gsub(' \\',' '))
    canonical_paths(deps)
    return deps
end


function get_target_list (t)
    if type(t) == 'table' then
        if t.target_list then return t.target_list end
    end
end

function make_target_list(ls)
    return {target_list = ls}
end

-- convenient function that takes a number of dependency arguments and turns them
-- into a target list.
function depends(...)
    local ls = {}
    local args = {...}
    if #args == 1 and is_simple_list(args[1]) then
        args = args[1]
    end
    for t in list_(args) do
        local tl = get_target_list(t)
        if tl then
            append_list(ls,tl)
        else
            append(ls,t)
        end
    end
    return make_target_list(ls)
end

-- @doc returns a copy of all the targets. The variable ALL_TARGETS is
-- predefined with a copy
function lake.all_targets()
    return column_list(all_targets_list,'target')
end

-- given a filename @fname, find out the corresponding target object.
local function target_from_file(fname,target)
    return list.find(all_targets_list,target or 'target',fname)
end

local basic_print

-- these won't be initially subsituted
local basic_variables = {INPUT=true,TARGET=true,DEPENDS=true,LIBS=true,CFLAGS=true,SRC=true}

function exec(s,dont_fail,t)
    local cmd = subst(s)
    if basic_print and t then
        log('built '..t.target)
    else
        log(cmd)
    end
    if not TESTING then
        local ok,res = utils.execute(cmd)
        if not ok then
            if not dont_fail then quit ("failed with code %d",res) end
            return res
        end
    end
end

local function subst_all_but_basic(s)
    return subst(s,basic_variables)
end

local function nop (x)
    return x
end

local current_rule,first_target,combined_targets = nil,nil,{}

local function relative_to (rpath,bpath)
    rpath = rpath:gsub('\\','/')
    local i1,i2 = rpath:find(bpath)
    if i1 == 1 then
        rpath = rpath:sub(i2+2)
    else
        rpath = '../../'..rpath
    end
    return rpath
end

local function fire(t)
    if not t.fake then
        -- @doc compilers often support the compiling of multiple files at once, which
        -- can be a lot faster. The trick here is to combine the targets of such tools
        -- and make up a fake target which does the multiple compile.
        if t.rule and t.rule.can_combine then
            -- collect a list of all the targets belonging to this particular rule
            if not current_rule then
                current_rule = t.rule
                first_target = t
            end
            if current_rule == t.rule then
                local input = t.input
                if t.cdir then input = relative_to(input,t.cdir) end
                append(combined_targets,input)
                -- this is key: although we defer compilation, we have to immediately
                -- flag the target as modified
                lfs.touch(t.target)
                return
            end
        end
        -- a target with new rule was encountered, and we have to actually compile the
        -- combined targets using a fake target.
        if #combined_targets > 0 then
            local fake_target = utils.copy_table(first_target)
            fake_target.fake = true
            fake_target.input = table.concat(combined_targets,' ')
            fire(fake_target)
            current_rule,first_target,combined_targets = nil,nil,{}
            -- can now pass through and fire the target we were originally passed
        end
    end

    local ttype = type(t.cmd)
    --- @doc basic variables available to actions:
    -- they are kept in the basic_variables table above, since then we can use
    -- subst_all_but_basic() to replace every _other_ variable in command strings.
    INPUT = quote_if_necessary(t.input)
    TARGET = quote_if_necessary(t.target)
    if t.cdir then TARGET=relative_to(TARGET,t.cdir) end
    SRC = t.src and table.concat(t.src,' ')
    if t.deps and not is_object(t.deps[1]) then
        local deps = t.deps
        if t.link_lang and t.link_lang.massage_link then
            deps = t.link_lang.massage_link(t.name,deps,t)
        end
        local odeps = deps
        deps = {}
        for i = 1,#odeps do
            deps[i] = t.cdir and relative_to(odeps[i],t.cdir) or odeps[i]
            deps[i] = quote_if_necessary(deps[i])
        end
        DEPENDS = table.concat(deps,' ')
    end
    LIBS = t.libs
    CFLAGS = t.cflags
    if t.dir then change_dir(t.dir) end
    if ttype == 'string' and t.cmd ~= '' then -- it's a non-empty shell command
        if t.rule and not TESTING then
            local cmd = subst(t.cmd)
            if not basic_print then
                log(cmd)
            end
            -- whatever else happens, ensure _up front_ that target is modified,
            -- since we could be launching the tool asynchronously!
            lfs.touch(t.target)
            job_execute(cmd,t,function(ok,code,inf)
                local filter = t.rule.filter or nop
                local outf = t.rule.stdout and io.stdout or io.stderr
                if basic_print and ok then
                    log('built '..t.target)
                end
                filter({t.target,t.input,t.rule},'start')
                for line in inf:lines() do
                    line = filter(line)
                    if line then outf:write(line,'\n') end
                end
                filter(t.base,'end')
                if not ok then quit ("failed with code %d",code) end
            end)
        else
            jobs_clear()
            exec(t.cmd,false,t)
        end
    elseif ttype == 'function' then -- a Lua function
        jobs_clear()
        t.cmd(t)
        nbuild = nbuild - 1
    else -- nothing happened, but we are satisfied (empty command target)
        nbuild = nbuild - 1
    end
    if t.dir then change_dir '!' end
    nbuild = nbuild + 1
end

function check(time,t)
    if not t then return end
    if not t.deps then
        -- unconditional action
        fire(t)
        return
    end

    if t.checked then return end
    if verbose then log('target: '..tostring(t.target)) end

    if t.deps then
        -- the basic out-of-date check compares last-written file times.
        local deps_changed = false
        for dfile in list_(t.deps) do
            local tm = filetime(dfile)
            check (tm,target_from_file(dfile))
            tm = filetime(dfile)
            if verbose then log(t.target,dfile,time,tm) end
            deps_changed = deps_changed or tm > time or tm == -1
        end
        -- something's changed, so do something!
        if deps_changed then
            fire(t)
        end
    end
    t.checked = true
end

local function get_deps (deps)
    if isrule(deps) then -- this is a rule object which has a list of targets
        return deps:get_targets()
    elseif istarget(deps) then
        return deps.target
    else
        return deps
    end
end

-- flattens out the list of dependencies
local function deps_list (targets)
    deps = {}
    for target in list_(targets) do
        target = get_deps(target)
        if type(target) == 'string' or is_object(target) then
            append(deps,target)
        else
            append_list(deps,target)
        end
    end
    return deps
end

function get_dependencies (deps)
    deps = get_deps(deps)
    local tl = get_target_list(deps)
    if tl then -- this is a list of dependencies
        deps = deps_list(tl)
    elseif is_simple_list(deps) then
        deps = deps_list(deps)
    end
    return deps
end

local dumped = {}

-- often the actual dependencies are not known until we come to evaluate them.
-- this function goes over all the explicit targets and checks their dependencies.
-- Dependencies may be simple file names, or rule objects, which are here expanded
-- into a set of file names.  Also, name references to files are resolved here.
local function expand_dependencies(t)
    if not t or not t.deps then return end
    if t.expanded then return end
    local deps = get_dependencies(t.deps)
    -- we already have a list of explicit dependencies.
    -- @doc Lake allows dependency matching against target _names_ as opposed
    -- to target _files_, for instance 'lua51' vs 'lua51.dll' or 'lua51.so'.
    -- If we can't match a target by filename, we try to match by name
    -- and update the dependency accordingly.
    for i = 1,#deps do
        local name = deps[i]
        local not_object
        if type(name) ~= 'string' then
            name = get_dependencies(name)
            deps[i] = name
            not_object = not is_object(name)
        end
        if not_object then
            local target = target_from_file(name)
            if not target then
                target = target_from_file(name,'name')
                if target then
                    deps[i] = target.target
                elseif not exists(name) then
                    dump(t,'target')
                    dump(t.deps,'deps')
                    quit("cannot find dependency '%s'",name)
                end
            end
        end
    end
    if verbose  and not dumped[t.target] then
        dump(deps,t.target)
        dumped[t.target] = true
    end

    -- by this point, t.deps has become a simple array of files
    t.deps = deps
    t.expanded = true

    for dfile in list_(t.deps) do
        expand_dependencies (target_from_file(dfile))
    end
end

local getter

local function powershell_download (pathname,url)
    local pscmd = 'powershell -ExecutionPolicy Bypass -NonInteractive -File tmp.ps1'
    local templ = [[
    $url = "%s"
    $path = "%s"
    (new-object System.Net.WebClient).DownloadFile($url,$path)
    ]]
    file.write('tmp.ps1',templ:format(url,pathname))
    return utils.execute(pscmd)
end

local canonical_lake_files = REMOTE_LAKE_URL or 'http://stevedonovan.github.io/lake/plugins/'

function lake.download (url,pathname)
    if not getter then
        if utils.which 'curl' then
            getter = 'curl -s -f -o '
        elseif utils.which 'wget' then
            getter = 'wget  -O '
        elseif utils.which 'powershell' then
            getter = powershell_download
        else
            quit 'cannot find either wget or curl on your system'
        end
    end
    local res
    if url:match '^get:' then
        url = url:gsub('^get:','',1)
        url = canonical_lake_files..url
    end
    log ('downloading... '..url)
    pathname = pathname or path.basename(url)
    local stat
    if type(getter) == 'string' then
        stat = utils.execute(getter..pathname..' '..url,true)
    else
        stat = getter(pathname,url)
    end
    return stat and path.exists(pathname)
end

function lake.is_remote (file)
    return file:match '^get:' or file:match '^http:'
end

local function exists_lua(name) return exists(name..'.lua') end

--- either a file defining a need, like 'foo.need.lua' or one defining
-- a language like 'boo.lang.lua'; general packages are 'foo.lake.lua'
-- The .lua extension is not necessary and the file may be remote.
function lake.install_plugin (parm)
    if path.extension_of(parm) ~= '.lua' then parm = parm..'.lua'  end
    local fname = exists(parm)
    if not fname then
        if not lake.is_remote(parm) then  quit(parm..' not found!')
        else
            fname = lake.download(parm)
            if not fname then quit(parm..' unable to download') end
        end
    end
    local name = path.basename(fname)
    local package,kind = name:match '([^.]+)%.(.+)%.'
    if not package then
        quit('no NAME.KIND.lua file found ')
    end
    if kind=='need' then
        sub = '/lake/needs/'
    else
        sub = '/lake/'..kind..'/'
    end
    local dest = lake.home..sub..package..'.lua'
    -- convention is that plugins use quit() if they cannot load...
    dofile (fname)
    -- so if we get here we're ready to roll
    file.copy(fname, dest,true)
    if kind == 'lang' then
        -- lang packages are special since they are available
        -- without explicit require in lakefiles.
        -- So have to patch the config file to insert the needed require.
        local config = join(lake.home,'config.lua')
        local contents = {}
        local req = "require 'lake.lang."..package.."'"
        local found
        if exists(config) then
            for line in io.lines(config) do
                append(contents,line)
                if line == req then found = true end
            end
        end
        if not found then
            append(contents,req)
            file.write(config,table.concat(contents,'\n')..'\n')
        end
    end
end

local synth_target,synth_args_index

function update_pwd ()
    local dir = lfs.currentdir()
    if Windows then dir = dir:lower() end -- canonical form
    PWD = dir..DIRSEP
end

local dir_stack = {}
local push,pop = table.insert,table.remove

function lake.chdir (path)
    if not path then return end
    if path == '!' or path == '<' then
        lfs.chdir(pop(dir_stack))
        log('restoring directory')
    else
        push(dir_stack,lfs.currentdir())
        local res,err = lfs.chdir(path)
        if not res then quit(err) end
        log('changing directory '..path)
    end
    update_pwd()
end

change_dir = lake.chdir

local n_threads_override

function lake.concurrent_jobs (nj, override)
    if not found_threads then return nil,"no threading available; winapi/posix needed" end
    if type(nj) ~= 'number' then return nil,"number of jobs must be a integer" end
    if override or not n_threads_override then
        n_threads = nj
        n_threads_override = override
        return true
    else
        return nil,"overriden by -j flag"
    end
end

function lake.cleantree()
    for pat in list {'.spec','.d','.o','.obj','.so','.exe','.pdb','.pch','.gch','.lib','.exp','.dll','.a'} do
        utils.remove(lake.expand_args('*',pat,true))
    end
end

local function safe_dofile (name)
    if _DEBUG then
        dofile(name)
    else
        local stat,err = pcall(dofile,name)
        if not stat then
            quit(err)
        end
    end
end

local lakefile
local unsatisfied_needs = {}

local function set_platform()
    if not PLAT then
        PLAT = BUILD_PLAT
    end
    WINDOWS = PLAT=='Windows'
    if WINDOWS then
        EXE_EXT = '.exe'
        DLL_EXT = '.dll'
    else
        EXE_EXT = ''
        DLL_EXT = '.so'
    end
    LOCAL_EXEC = choose (Windows,'','./')
end

local function process_args()
    -- arg is not set in interactive lua!
    if arg == nil then return end
    local write_needs
    LUA_EXE = quote_if_necessary(arg[-1] or 'lua') -- srlua does not pass this!
    STRICT = true
    -- @doc [config] the environment variable LAKE_PARMS can be used to supply default global values,
    -- in the same <var>=<value> form as on the command-line; pairs are separated by semicolons.
    local parms = env 'LAKE_PARMS'
    if parms then
        for pair in list_(split(parms,';')) do
            process_var_pair(pair)
        end
    end
    -- @doc [config] try load ~/.lake/config.lua, then ./lakeconfig.lua.
    -- We also put ~./lake on the package path for Lake-specific
    -- plugins.  If the global LAKE_CONFIG_FILE is set, then we'll also try load that.
    local home = path.expanduser '~/.lake'
    lake.home = home
    package.path = home..'/?.lua;'..package.path
    local lconfig = exists_lua(join(home,'config'))
    if lconfig then
        safe_dofile(lconfig)
    end
    local lakeconfig = exists_lua 'lakeconfig'
    if lakeconfig then
        safe_dofile (lakeconfig)
    end
    if not Windows then
        BUILD_PLAT = shell('uname -s')
    else
        BUILD_PLAT='Windows'
    end
    update_pwd()

    local no_synth_target, run_file, run_rule
    local use_lakefile = true
    local i = 1
    while i <= #arg do
        local a = arg[i]
        local function getarg()
            local res = arg[i+1]
            if res == nil or res:match '^%-' then quit("parameter '%s' was expecting a value",a) end
            i = i + 1
            return res
        end
        if process_var_pair(a) then
            -- @doc <name>=<val> pairs on command line for setting globals
        elseif a:sub(1,1) == '-' then
            local opt = a:sub(2)
            if opt == 'v' then
                verbose = true
            elseif opt == 'q' then
                lake.set_log()
            elseif opt == 'h' or opt == '-help' then
                print(usage)
                os.exit(0)
            elseif opt == 'install' then
                lake.install_plugin(getarg())
                os.exit(0)
            elseif opt == 't' then
                TESTING = true
            elseif opt == 'w' then
                write_needs = true
            elseif opt == 'n' then
                no_synth_target = true
            elseif opt == 'f' then
                lakefile = getarg()
            elseif opt == 'L' then
                require('lake.'..getarg())
            elseif opt == 'e' then
                lakefile = file.temp_copy(getarg())
            elseif opt == 's' then
                STRICT = false
            elseif opt == 'g' then
                DEBUG = true
            elseif opt == 'd' then
                change_dir(getarg())
            elseif opt == 'j' then
                local ok, err = lake.concurrent_jobs (tonumber(getarg()),true)
                if not ok then quit(err) end
            elseif opt == 'b' then
                basic_print = true
            elseif opt == 'p' then
                lakefile = file.temp_copy(("tp,name = lake.deduce_tool('%s'); tp.program(name)"):format(arg[i+1]))
                i = i + 1
            elseif opt == 'lua' or opt == 'l' then
                local name,lua = getarg(),'false'
                if opt=='lua' then lua = 'true' end
                lakefile,err = file.temp_copy(("tp,name = lake.deduce_tool('%s'); tp.shared{name,lua=%s}"):format(name,lua))
            elseif opt == 'C' then
                lake.cleantree()
                os.exit()
            else
                quit("unknown option "..opt)
            end
        else
            if lake.is_remote(a) then a = lake.download(a) or '?' end
            if not no_synth_target and a:find('%.') and exists(a) then
                -- Lua scripts are run directly, unless specifically switched off with '-n'
                local ext = extension_of(a)
                if ext == '.lua' then
                    run_file = a
                    break
                elseif ext == '.lake' then
                    lakefile = a
                    break
                else  --  see if we have a suitable rule for processing  a file with this extension.
                    local _,_,rule = lake.deduce_tool(a,true)
                    if _ then
                        run_rule = rule or false
                        run_file = a
                        break
                    end
                end
            end
            -- otherwise, it has to be a target
            append(specific_targets,a)
        end
        i = i + 1
     end
    set_platform()
    if LAKE_CONFIG_FILE then
        safe_dofile (LAKE_CONFIG_FILE)
    end
    lake.set_flags()
    if run_file or run_rule then
        if run_file and run_rule == nil then
            local new_arg = {}
            for k = i+1,#arg do
                append(new_arg,arg[k])
            end
            new_arg[0] = run_file
            new_arg[-1] = arg[-1]
            arg = new_arg
            dofile(run_file)
            os.exit(0)
        end
        --- otherwise run_rule
       use_lakefile = false
       -- if there's no specific rule for this tool, we assume that there's
       -- a program target for this file; we keep the target for later,
       -- when we will try to execute its result.
         if not run_rule then
            synth_target = lake.program (run_file)
            synth_args_index = i + 1
        else
            run_rule.in_ext = extension_of(run_file)
            run_rule(run_file)
        end
    end
    -- if we are called as a program, not as a library, then invoke the specified lakefile
    if arg[0] == 'lake' or arg[0]:find '[/\\]lake$' or arg[0]:find '[/\\]lake%.lua$' or arg[0]:find '[/\\]f?lake%.exe$' then
        if use_lakefile then
            local orig_lakefile = lakefile
            lakefile = exists(lakefile or 'lakefile') or exists 'lakefile.lua'
            if not lakefile then
                quit("'%s' does not exist",orig_lakefile or 'lakefile')
            end
            safe_dofile(lakefile)
        end
        if next(unsatisfied_needs) then
            local out = io.stdout
            for package,vars in pairs(unsatisfied_needs) do
                if write_needs then
                    local needf = package..'.need.lua'
                    out = io.open(needf,'w')
                    log('writing '..needf)
                end
                out:write(('--- variables for package %s\n'):format(package))
                for _,v in ipairs(vars) do out:write(v,'\n') end
                out:write('----\n')
                if write_needs then out:close() end
            end
            log (write_needs and "please edit the needs files!"
                or "use -w to write skeleton needs files")
            quit "unsatisfied needs"
        end
        lake.go()
        finalize()
    end
end

local hooks = {}

function lake.on_exit (hook)
    append(hooks,hook)
end

function finalize(reason)
    for _,h in ipairs(hooks) do
        pcall(h,reason)
    end
end

-- recursively invoke lake at the given @path with the arguments @args
function lake_(path,args)
    args = args or ''
    exec('lake -d "'..path..'"  '..args,true)
end

utils.make_callable(lake,lake_)

function lake.go()

    if #all_targets_list == 0 then
        quit('no targets defined')
    end

    for tt in list_(all_targets_list) do
        tt.expanded = nil
        tt.checked = nil
    end

    for tt in list_(all_targets_list) do
        expand_dependencies(tt)
    end

    ALL_TARGETS = lake.all_targets()
    if verbose then dump(ALL_TARGETS,'targets') end

    local synthesize_clean
    local targets = {}
    if #specific_targets > 0 then
        for tname in list_(specific_targets) do
            t = target_from_file(tname)
            if not t then
                -- @doc 'all' is a synonym for the first target
                if tname == 'all' then
                    table.insert(targets,all_targets_list[1])
                    table.remove(all_targets_list,1)
                elseif tname ~= 'clean' then
                    quit ("no such target '%s'",tname)
                else --@doc there is no clean target, so we'll construct one later
                    synthesize_clean = true
                    append(targets,'clean')
                end
            end
            append(targets,t)
        end
    else
        -- @doc by default, we choose the first target, just like Make.
        -- (Program/library targets force themselves to the top)
        append(targets,all_targets_list[1])
    end
    -- if requested, generate a default clean target, using all the targets.
    if synthesize_clean then
        NODEPS = true
        local t = new_target('clean',nil,function()
            utils.remove(ALL_TARGETS)
            -- Object files may have associated .d dependency file
            for t in list_(ALL_TARGETS) do
                if type(t) == 'string' and extension_of(t) == baselang.obj_ext then
                    local dfile = replace_extension(t,'.d')
                    if exists(dfile) then utils.remove(dfile,true) end
                end
            end
        end)
        targets[index_list(targets,'clean')] = t
    end
    for t in list_(targets) do
        t.time = filetime(t.target)
        check(t.time,t)
    end
    jobs_clear()
    if nbuild == 0 then
        if not synth_target then log 'lake: up to date' end
    end
    -- @doc 'synth-target' a program target was implicitly created from the file on the command line;
    -- execute the target, passing the rest of the parms passed to Lake, unless we were
    -- explicitly asked to clean up.
    if synth_target and not synthesize_clean then
        local ok, res = lake.run(synth_target,arg,synth_args_index)
        if not ok then -- pass on return code
            os.exit(res)
        end
    end
end

-- @doc lake.run will run a program or a target, given some arguments. It will
-- only include arguments starting at istart, if defined. If it is a target,
-- the target's language may define a runner; otherwise we look for an interpreter
-- or default to local execution of the program.
function lake.run(prog,args,istart)
    local args = list.parm_concat(args,istart)
    local exe
    if istarget(prog) then
        local lang = prog.link_lang -- language used to link target
        if lang and lang.runner then
            return lang.runner(prog.target,args)
        end
        prog = prog.target
    end
    local ext = extension_of(prog)
    local runner = interpreters[ext]
    if runner then runner = runner..' '
    else runner = LOCAL_EXEC
    end
    return exec(runner..prog..args)
end

function lake.deduce_tool(fname,no_error)
    local name,ext,tp
    if type(fname) == 'table' then
        name,ext = fname, fname.ext
        if not ext then quit("need to specify 'ext' field for program()") end
    else
        name,ext = splitext(fname)
        if ext == '' then
            if no_error then return end
            quit('need to specify extension for input to program()')
        end
    end
    tp = extensions[ext]
    if not tp then
        if no_error then return end
        quit("unknown file extension '%s'",ext)
    end
    tp.ext = ext
    return tp,name,tp.rule
end

local flags_set

local function opt_flag (flag,opt)
    if opt then
        if opt == true then opt = OPTIMIZE
        elseif opt == false then return ''
        end
        return flag..opt
    else
        return ''
    end
end

function lake.set_flags(parms)
    if not parms then
        if not flags_set then flags_set = true else return end
    else
        for k,v in pairs(parms) do
            _G[k] = v
        end
    end
    -- @doc Microsoft Visual C++ compiler prefered on Windows, if present
    if PLAT=='Windows' and utils.which 'cl' and not CC then
        CC = 'cl'
        CXX = 'cl'
        PREFIX = ''
    else
        -- @doc if PREFIX is set, then we use PREFIX-gcc etc. For example,
        -- if PREFIX='arm-linux' then CC becomes 'arm-linux-gcc'
        if PREFIX and #PREFIX > 0 then
            if not PREFIX:match '%-$' then
                PREFIX = PREFIX..'-'
            end
            CC = PREFIX..'gcc'
            CXX = PREFIX..'g++'
        else
            PREFIX = ''
            CC = CC or 'gcc'
        end
    end
    if not CXX and CC == 'gcc' then
        CXX = 'g++'
    end
    if not OPTIMIZE then
        OPTIMIZE = 'O2'
    end
    if CC ~= 'cl' then -- must be 'gcc' or something compatible
        c.init_flags = function(debug,opt,strict)
            local flags
            -- usually either debug build or optimized build,
            -- but if debug is a string, there can be an optimization level as well
            if type(debug) ~= 'string' then
                flags = choose(debug,'-g',opt_flag('-',opt))
            elseif type(debug) == 'string' then
                flags = (debug and '-g' or '') .. ' ' .. opt_flag('-',debug)
            end
            if strict then
                -- @doc 'strict compile' (-s) uses -Wall for gcc; /WX for cl.
                flags = flags .. ' -Wall'
            end
            return flags
        end
        c.flags_handler = function(lang,args,compile)
            local flags = ''
            if PLAT == 'Darwin' then -- Framework support for OS X
                if args.framework_dir then
                    flags = flags..concat_arg('-F',args.framework_dir,' ')
                end
                if args.universal then
                    flags = flags..' -arch x86_64 -arch i386'
                    -- can't have -M flags with multiple arch flags (gcc)
                    args.nodeps = true
                end
                if not compile and args.framework then
                    flags = flags..concat_arg('-framework',args.framework,' ')
                end
                if args.min_version then
                    if args.min_version == true then args.min_version = "10.5" end
                    flags = flags..' -mmacosx-version-min='..args.min_version
                end
            end
            if lang == cpp11 then
                if compile then
                    flags = flags .. ' -std=c++0x'
                end
            end
            -- we default to stripping the executable, unless strip is explicitly specified
            -- and we're not exporting symbols or doing a debug build.
            -- Darwin, however, ceases to export symbols from executables, and doesn't
            -- understand stripping shared libraries.
            if PLAT ~= "Darwin" and not args.debug and args.strip == nil then
                args.strip = true
            end
            return flags
        end
        -- do this explicitly, in case we're switching compilers in mid-stream
        c.filter = nil
        c.auto_deps = '-MMD'
        AR = PREFIX..'ar'
        c.compile = '$(CC) -c $(CFLAGS)  $(INPUT) -o $(TARGET)'
        c.compile_combine = '$(CC) -c $(CFLAGS)  $(INPUT)'
        c99.compile = '$(CC) -std=c99 -c $(CFLAGS)  $(INPUT) -o $(TARGET)'
        c99.compile_combine = '$(CC) -std=c99 -c $(CFLAGS)  $(INPUT)'
        c.link = '$(CC) $(DEPENDS) $(LIBS) -o $(TARGET)'
        c99.link = c.link
        cpp.compile = '$(CXX) -c $(CFLAGS)  $(INPUT) -o $(TARGET)'
        cpp.compile_combine = '$(CXX) -c $(CFLAGS)  $(INPUT)'
        cpp.link = '$(CXX) $(DEPENDS) $(LIBS) -o $(TARGET)'
        c.lib = '$(AR) rcu $(TARGET) $(DEPENDS) && ranlib $(TARGET)'
        baselang.LIBPARM = '-l'
        baselang.LIBPOST = ' '
        baselang.LIBDIR = '-L'
        baselang.incdir = '-I'
        baselang.DEFDEF = '-D'
        baselang.M32 = '-m32'
        if PLAT=='Darwin' then
            c.LINK_DLL = ' -dynamiclib -undefined dynamic_lookup'
        else
            c.LINK_DLL = '-shared'
        end
        baselang.obj_ext = '.o'
        baselang.LIB_PREFIX='lib'
        baselang.LIB_EXT='.a'
        SUBSYSTEM = '-Xlinker --subsystem -Xlinker  '  -- for mingw with Windows GUI
        if PLAT ~= 'Darwin' then
            c.EXE_EXPORT = ' -Wl,-E'
        end
        baselang.STRIP = ' -Wl,-s'
        baselang.LIBSTATIC = ' -static'
        c.uses_dfile = 'slash'
        cpp_ch.obj_ext = '.gch'
        cpp_ch.use_compiled_header = '-include '
        cpp_ch.appends_extension = true

        -- @doc under Windows, we use the .def file if provided when linking a DLL
        function c.massage_link (name,deps,t)
            if t.ptype ~= 'dll' then return deps end
            local def = exists(name..'.def') or t.args.def
            if def and PLAT=='Windows' then
                deps = list.copy(deps)
                append(deps,def)
            end
            return deps
        end

        wresource.compile = 'windres $(CFLAGS) $(INPUT) $(TARGET)'
        wresource.obj_ext='.o'

    else -- Microsoft command-line compiler
        MSVC = true
        c.init_flags = function(debug,opt,strict)
            local flags = choose(debug,'/Zi',opt_flag('/',opt))
            if strict then -- 'warnings as errors' might be a wee bit overkill?
                flags = flags .. ' /WX'
            end
            return flags
        end
        c.flags_handler = function(lang,args,compile)
            local flags = ''
            if compile then
                local debug = args.debug or DEBUG
                if args.dynamic or args.static == false then
                    flags = flags .. choose(debug,' /MDd',' /MD')
                end
                flags = flags .. ' /D_CRT_SECURE_NO_DEPRECATE'
                if debug then
                    flags = flags .. ' /DDEBUG'
                else
                    flags = flags .. ' /DNDEBUG'
                end
            end
            return flags
        end
        c.compile = 'cl /nologo -c $(CFLAGS)  $(INPUT) /Fo$(TARGET)'
        c.compile_combine = 'cl /nologo -c $(CFLAGS)  $(INPUT)'
        c.link = 'link /nologo $(DEPENDS) $(LIBS) /OUT:$(TARGET)'
        -- enabling exception unwinding is a good default...
        -- note: VC 6 still has this as '/GX'
        cpp.compile = 'cl /nologo /EHsc -c $(CFLAGS)  $(INPUT) /Fo$(TARGET)'
        cpp.compile_combine = 'cl /nologo /EHsc -c $(CFLAGS) $(INPUT)'
        cpp.link = c.link
        c.lib = 'lib /nologo $(DEPENDS) /OUT:$(TARGET)'
        c.auto_deps = '/showIncludes'
        function c.post_build(ptype,args)
            if args and (args.static==false or args.dynamic) then
                local mtype = choose(ptype=='exe',1,2)
                return 'mt -nologo -manifest $(TARGET).manifest -outputresource:$(TARGET);'..mtype
            end
        end
        function c.massage_link (name,deps,t)
            local odeps = deps
            -- a hack needed because we have to link against the import library, not the DLL
            deps = {}
            for l in list_(odeps) do
                if extension_of(l) == '.dll' then l = replace_extension(l,'.lib') end
                append(deps,l)
            end
            if t.ptype == 'dll' then
                -- @doc [link:win] if there was an explicit .def file, use it; it will be relative to any base
                local bname = t.basedir and path.join(t.basedir,name) or name
                local def = exists(bname..'.def') or t.args.def
                if def then
                    append(deps,'/DEF:'..def)
                elseif t.lua or t.llua ~= nil then
                    -- somewhat ugly hack: if no .def and this is a Lua extension, then make sure
                    -- the Lua extension entry point is visible. llua=false will suppress this,
                    -- if it's a DLL linked against Lua that is not itself an extension, or already
                    -- exports its symbols
                    local _,mname
                    if t.llua == nil then
                        _,mname = splitpath(name)
                    elseif type(t.llua) == 'string' then
                        mname = t.llua
                    else
                        mname = nil
                    end
                    if mname then
                        mname = mname:gsub('%.','_')
                        append(deps,'/EXPORT:luaopen_'..mname)
                    end
                end
            end
            -- @doc [link:CL]a proper debug link should generate a PDB in the same directory as the executable
            if t.debug and t.ptype ~= 'lib' then
                append(deps,'/DEBUG')
                append(deps,'/PDB:'..splitext(t.target)..'.pdb')
            end
            return deps
        end
        -- @compile A language can define a filter which operates on the output of the
        -- compile tool. It is used so that Lake can parse the output of /showIncludes
        -- when using MSVC and create .d files in the same format as generated by GCC
        -- with the -MMD option.
        local rule,file_pat,dfile,input,target,ls
        local function write_deps()
            if not dfile then quit("dependencies file is undefined") end
            local outd,err = io.open(dfile,'w')
            if outd then
                outd:write(target,': ',table.concat(ls,' '),'\n')
                outd:close()
            else
                quit("unable to open '"..dfile.."'")
            end
        end
        if not NODEPS then
        function c.filter(line,action)
          -- these are the three ways that the filter is called; initially with
          -- the input and the target, finally with the name, and otherwise
          -- with each line of output from the tool. This stage can filter the
          -- the output by returning some modified string.
          if action == 'start' then
            target,input,rule = line[1],line[2],line[3]
            file_pat = '^[^:]-%'..rule.in_ext..'$'
            dfile = nil
          elseif action == 'end' then
            write_deps()
          elseif line:match(file_pat) then
            -- the line containing the input file
            if dfile then write_deps() end
            dfile = path.replace_extension(target,'.d')
            ls = {quote_if_necessary(input)}
          else
              local file = line:match('Note: including file:%s+(.+)')
              if file then
                -- we only want _our_ include files as dependencies!
                if not isabs(file) or not within_msvc_include_path(file) then
                    append(ls,quote_if_necessary(file))
                end
              else
                return line
              end
            end
        end
        end
        c.stdout = true
        baselang.LIBPARM = ''
        baselang.LIBPOST = '.lib '
        baselang.LIBDIR = '/LIBPATH:'
        baselang.incdir = '/I'
        baselang.DEFDEF = '/D'
        c.LINK_DLL = '/DLL'
        baselang.obj_ext = '.obj'
        baselang.LIB_PREFIX=''
        baselang.STRIP = ''
        baselang.LIB_EXT='_static.lib'
        SUBSYSTEM = '/SUBSYSTEM:'
        baselang.LIBDYNAMIC = '' --'msvcrt.lib' -- /NODEFAULTLIB:libcmt.lib'
        c.uses_dfile = 'noslash'

        -- a hack: CL.EXE is quite happy with compiling a file as a compiled header,
        -- but does not like /Fo$(TARGET) in this context. So we remove it...
        cpp_ch.compile = cpp.compile:gsub('%S+$','')
        cpp_ch.obj_ext = '.pch'
        cpp_ch.use_compiled_header = '/Yu'
        cpp_ch.make_compiled_header = '/Yc /Tp'

        wresource.compile = 'rc $(CFLAGS) /fo$(TARGET) $(INPUT) '
        wresource.obj_ext='.res'
        wresource.incdir ='/i'

    end
end

function lake.output_filter (lang,filter)
    local old_filter = lang.filter
    local filter = function(line,action)
        if not action then
            if old_filter then line = old_filter(line) end
            if line then return filter(line) end
        else
            if old_filter then old_filter(line,action) end
        end
    end
    if istarget(lang) then
        if not lang.rule then lang.rule = {} end
        lang.rule.filter = filter
    else
        lang.filter = filter
    end
end

function concat_arg(pre,arg,sep,base)
    return ' '..list.concat(deps_arg(arg,base),pre,sep)
end
lake.concat_arg = concat_arg

local function _compile(name,compile_deps,lang)
    local args = (type(name)=='table') and name or {}
    local cflags = ''
    if lang.init_flags then
        cflags = lang.init_flags(pick(args.debug,DEBUG), pick(args.optimize,OPTIMIZE), pick(args.strict,STRICT))
    end
    -- @MSVC C99: best we can do is compile as C++
    if lang == c99 and CC == 'cl' then
        cflags = cflags .. ' /TP'
    end
    compile_deps = compile_deps or args.compile_deps or args.headers
    -- preprocessor symbols can be defined with a Lua map-like table, if desired
    if args.defines then
        local defs = args.defines
        if type(defs)=='table' and #defs == 0 then
            local mdefs = defs
            defs = {}
            for key,value in pairs(mdefs) do
                if value ~= true then
                    key = key..'='..quote_if_necessary(value)
                end
                append(defs,key)
            end
        end
        cflags = cflags..concat_arg(lang.DEFDEF,defs,' ')
    end
    if args.incdir then
        cflags = cflags..concat_arg(lang.incdir,args.incdir,' ',args.base)
    end
    -- @lang can define flags_handler() to add to cflags
    if lang.flags_handler then
       cflags = cflags..lang:flags_handler(args,true)
    end
    if args.flags then
        cflags = cflags..' '..args.flags
    end
    if not args.nodeps and not NODEPS and lang.auto_deps then
        cflags = cflags .. ' ' .. lang.auto_deps
    end
    local can_combine = lang.please_combine or (not args.odir and COMBINE and lang.compile_combine)
    local compile_cmd = lang.compile
    if can_combine then compile_cmd = lang.compile_combine end
    local compile_str = subst_all_but_basic(compile_cmd)
    local ext = args and args.ext or lang.ext

    local cr = rule(lang.obj_ext or ext,ext,compile_str,lang.label or lang.ext)

    -- @doc 'compile_deps' can provide a list of files which all members of the rule
    -- are dependent on.
    if compile_deps then cr:depends_on(compile_deps) end
    cr.cflags = cflags
    cr.can_combine = can_combine
    cr.lang = lang
    return cr
end

function find_include (f)
    if not Windows then
        return exists('/usr/include/'..f) or exists('/usr/share/include/'..f)
    else
       -- ??? no way to tell ???
    end
end

------------ Handling needs ------------

local extra_needs = {}

local function define_need (name,callback)
    extra_needs[name] = callback
end
lake.define_need = define_need

local function get_extra_needs (name,args,static)
    local res = extra_needs[name](args,static)
    if not res then return nil end
    return res
end

local function examine_config_vars(package,subtype)
    -- @needs If we're trying to match a need 'frodo', then we
    -- generate FRODO_INCLUDE_DIR, FRODO_LIB_DIR, FRODO_LIBS, FRODO_DIR
    -- and look them up globally.  Not all of these are needed. For instance, if only
    -- FRODO_DIR is specified then Lake will try FRODO_DIR/include and FRODO_DIR/lib,
    -- and assume that the libname is simply frodo (unless FRODO_LIBS is also specfiied)
    -- On Unix, a C/C++ need generally needs include and lib dirs, plus library name if
    -- it isn't identical to the need name. However a lib dir is only essential for Windows,
    -- which has no convenient system-wide lib directory.
    --
    -- A need may insist on a certain language using FRODO_LANG
    --
    -- You may also directly define FRODO_CFLAGS and FRODO_LFLAGS to provide
    -- arbitrary compile/link flags; in this case the directory checks are skipped
    --
    -- If this check fails, then Lake can generate skeleton configuration files for
    -- the needs.
    local upack = package:upper():gsub('%W','_')
    local incdir_v = upack..'_INCLUDE_DIR'
    local libdir_v = upack..'_LIB_DIR'
    local libs_v = upack..'_LIBS'
    local libss_v = upack..'_LIBS_STATIC'
    local dir_v = upack..'_DIR'
    local cflags_v = upack..'_CFLAGS'
    local lflags_v = upack..'_LFLAGS'
    local lang_v = upack..'_LANG'

    local incdir,libdir,libs,libss,dir,cflags,lflags,lang =
        _G[incdir_v],_G[libdir_v],_G[libs_v],_G[libss_v],_G[dir_v],_G[cflags_v],_G[lflags_v],_G[lang_v]

    local function checkdir(val,var,default)
        local none = val == nil
        local nodir
        if not default then nodir = not none and not path.isdir(val) end
        default = default or 'NIL'
        if none or nodir then
            if not unsatisfied_needs[package] then
                unsatisfied_needs[package] = {}
            end
            append(unsatisfied_needs[package],("%s = '%s' --> %s!"):format(var,val or default,none and 'please set' or 'not a dir'))
            return false
        end
        return true
    end

    if dir ~= nil then -- this is a common pattern on Windows; FOO\include, FOO\lib
        if checkdir(dir,dir_v) then
            if not incdir then incdir = join(dir,'include') end
            if not libdir then libdir = join(dir,'lib') end
            if not libs then libs = package end
        end
    end
    if not cflags then
        checkdir(incdir,incdir_v)
    end
    -- generally you will always need a libdir for Windows; otherwise only check if specified
    if not lflags then
        if PLAT=='Windows' or libdir ~= nil then checkdir(libdir,libdir_v) end
        checkdir(libs,libs_v,package)
    end
    -- the program wants to link statically against this need
    if subtype == 'static' then
        if libss then -- specifically specified!
            libs = libss
        -- otherwise we use lake convention for MSVC
        elseif libs and CC == 'cl' and subtype == 'static' then
            libs = concat_arg('',libs,'_static ')
        end
    end
    local res = {incdir = incdir, libdir = libdir, libs = libs, flags = cflags,
        libflags = lflags, lang = lang}
    if not next(res) then -- we found nuffink...
        res = nil
    end
    return res
end

local pkg_config_present

-- @doc [needs] handling external needs - if an alias @name for @package is provided,
-- then this package is available using the alias (e.g. 'gtk') and _must_ be handled by
-- pkg-config.
function lake.define_pkg_need (name,package)
    local alias = package ~= nil
    define_need(name,function()
        local knows_package
        if not alias then package = name end
        if pkg_config_present == nil then
            pkg_config_present = utils.which 'pkg-config'
        end
        if alias and not pkg_config_present then
            quit("package "..package.." requires pkg-config on the path")
        end
        if pkg_config_present then
            if utils.execute('pkg-config '..package,true) then
                knows_package = true
            elseif alias then
                quit("package "..package.." not known by pkg-config; please install")
            end
            if knows_package then
                local gflags = shell ('pkg-config --cflags '..package)
                local glibs = shell ('pkg-config --libs '..package)
                return {libflags=glibs,flags=gflags}
            end
        end
    end)
end


-- @doc [needs] unknown needs searched in this order:
-- lake.needs.name, config vars (NAME_INCLUDE_DIR etc) and then pkg-config

local function handle_unknown_need (name,args,static)
    define_need(name,function()
        local ok,needs,nfun,needs_package
        local pack,sub = utils.split2(name,'%-')
        pack = pack or name
        sub = sub or (static and 'static' or nil)
        needs_package = 'lake.needs.'..pack

        ok,nfun = pcall(require,needs_package)
        --log("trying to load "..needs_package,sub,ok)
        if ok then
            if type(nfun) == 'function' then return nfun(sub) end
        else
            local nfile = exists_lua(name..'.need')
            if nfile then safe_dofile(nfile) end
        end
        needs = examine_config_vars(pack,sub)
        if not needs then
            lake.define_pkg_need(name)
            needs = get_extra_needs(name,args,static)
            if needs then
                unsatisfied_needs[name] = nil
            end
        end
        return needs
    end)
end

local function append_to_field (t,name,value)
    if value then
        value = deps_arg(value)
        if not t[name] then
            t[name] = {}
        elseif type(t[name]) == 'string' then
            t[name] = deps_arg(t[name])
        end
        append_list(t[name],value)
    end
end
lake.append_to_field = append_to_field

-- @doc [needs] these are currently the built-in needs supported by Lake
local builtin_needs = {math=true,readline=true,dl=true,sockets=true,lua=true}

local update_lua_flags  -- forward reference

local function update_needs(ptype,args)
    local libs = {}
    for need in list_(args.needs) do
        local static
        if need:match '%-static$' then
            static = true
            need = need:gsub('%-static$','')
        end
        if not extra_needs[need] and not builtin_needs[need] then
            handle_unknown_need(need,args,static)
        end
        if extra_needs[need] then
            if need == 'lua' then
                args.lua = true
            end
            local res = get_extra_needs(need,args,static)
            if res then
                append_to_field(args,'libs',res.libs)
                append_to_field(args,'incdir',res.incdir) -- ?? might be multiple!
                append_to_field(args,'defines',res.defines)
                append_to_field(args,'libdir',res.libdir)
                if res.libflags then args.libflags = concat_str(args.libflags,res.libflags,true) end
                if res.flags then args.flags = concat_str(args.flags,res.flags,true) end
                -- @needs a need may override the default language, e.g insist on C99
                if res.lang then args.lang = res.lang end
            end
        else
            if PLAT ~= 'Windows' then
                if need == 'math' then append(libs,'m')
                elseif need == 'readline' then
                    append(libs,'readline')
                    if PLAT=='Linux' then
                        append_list(libs,{'ncurses','history'})
                    end
                elseif need == 'dl' and PLAT=='Linux' then
                    append(libs,'dl')
                end
            else
                if need == 'sockets' then append(libs,'wsock32') end
            end
        end
    end
    if #libs > 0 then
        append_to_field(args,'libs',libs)
    end
end

lake.define_pkg_need('gtk','gtk+-2.0')
lake.define_pkg_need('gthread','gthread-2.0')

define_need('windows',function()
    return { libs = 'user32 kernel32 gdi32 ole32 advapi32 shell32 imm32  uuid comctl32 comdlg32'}
end)

define_need('unicode',function()
    return { defines = 'UNICODE _UNICODE' }
end)


local function check_luarocks_variables ()
    if IGNORE_LUAROCKS then return false end
    local ok,lr_cfg = pcall(require,'luarocks.cfg')
    if not ok then return false end
    return lr_cfg.variables
end

-- the assumption here that the second item on your Lua paths is the 'canonical' location. Adjust accordingly!
function get_lua_path (p)
    return package.path:match(';(/.-)%?'):gsub('/lua/$','')
end

local using_LfW

local function find_lua_dll (path)
    return exists(path,'lua5.1.dll') or exists(path,'lua51.dll') or exists(path,'liblua51.dll')
end

function update_lua_flags (args,static)
    local res = {}
    if not LUA_LIBS then
        LUA_LIBS = 'lua5.1'
    end
    -- this var is set by Lua for Windows
    using_LfW = env 'LUA_DEV'
    if LUA_INCLUDE_DIR == nil then
        -- if LuaRocks is available, we ask it where the Lua headers are found...
        local lr_vars = check_luarocks_variables()
        if lr_vars then
            LUA_INCLUDE_DIR = lr_vars.LUA_INCDIR
            LUA_LIB_DIR = lr_vars.LUA_LIBDIR
            if Windows then
                LUA_DLL = find_lua_dll(lr_vars.LUAROCKS_PREFIX..'/2.0')
            end
        elseif Windows then -- no standard place, have to deduce this ourselves!
            local lua_path = utils.which(LUA_EXE)  -- usually lua, could be lua51, etc!
            if not lua_path then quit ("cannot find Lua on your path") end
            local path = dirname(lua_path)
            LUA_DLL = find_lua_dll(path)
            LUA_INCLUDE_DIR = exists(path,'include') or exists(path,'..\\include')
            if not LUA_INCLUDE_DIR then quit ("cannot find Lua include directory") end
            LUA_LIB_DIR = exists(path,'lib') or exists(path,'..\\lib')
            if not LUA_INCLUDE_DIR or not LUA_LIB_DIR then
                quit("cannot find Lua include and/or library files\nSpecify LUA_INCLUDE_DIR and LUA_LIB_DIR")
            end
        else
            -- 'canonical' Lua install puts headers in sensible place
            if not find_include 'lua.h' then
                -- except for Debian, which also supports 5.0 and 5.2
                LUA_INCLUDE_DIR = find_include (LUA_LIBS..'/lua.h')
                if not LUA_INCLUDE_DIR then
                    quit ("cannot find Lua include files\nSpecify LUA_INCLUDE_DIR")
                end
                LUA_INCLUDE_DIR = splitpath(LUA_INCLUDE_DIR)
                -- generally no need to link explicitly against Lua shared library
            else
                LUA_INCLUDE_DIR = ''
                LUA_LIB_DIR = nil
            end
        end
    end
    res.incdir = LUA_INCLUDE_DIR
    if Windows then
        -- recommended practice for MinGW is to link directly against the DLL
        local libs
        if CC=='gcc' and not using_LfW then
            res.libflags = LUA_DLL
            use_import_lib = false
        else
            res.libs = {LUA_LIBS}
            res.libdir = quote_if_necessary(LUA_LIB_DIR)
        end
        res.incdir = quote_if_necessary(res.incdir)
    end
    if using_LfW then -- specifically, Lua for Windows
        if CC=='gcc' then -- force link against VS2005 runtime
            append(res.libs,'msvcr80')
        else -- CL link may assume the runtime is installed
            res.flags = '/MD'
        end
    end
    return res
end

define_need('lua',update_lua_flags)

----- end of handling needs -----------


local program_fields = {
    name=true, -- name of target (or first value of table)
    lua=true,  -- build against Lua libs
    args=true,  -- any default arguments (works like lang.defaults, doesn't override)
    needs=true, -- higher-level specification of target link requirements
    libdir=true, -- list of lib directories
    libs=true, -- list of libraries
    libflags=true, -- list of flags for linking
    subsystem=true, -- (Windows) GUI application
    def=true, -- (Windows) explicit .def file
    strip=true,  -- strip symbols from output
    rules=true,inputs=true, -- explicit set of compile targets
    shared=true,dll=true, -- a DLL or .so (with lang.library)
    deps=true, -- explicit dependencies of a target (or subsequent values in table)
    compile_deps=true, -- explicit dependencies of source files
    export=true, -- this executable exports its symbols
    dynamic=true, -- link dynamically against runtime (default true for GCC, override for MSVC)
    static=true, -- statically link this target
    headers=true, -- explicit list of header files (not usually needed with auto deps)
    odir=true,output_directory=true, -- output directory; if true then use 'debug' or 'release'; if non-nil use it as output directory directly; prepends PREFIX
    src=true, -- src files, may contain directories or wildcards (extension deduced from lang or `ext`)
    exclude=true,	-- a similar list that should be excluded from the source list (e.g. if src='*')
    recurse=true, -- recursively find source files specified in src=wildcard
    ext=true, -- extension of source, if not the usual. E.g. ext='.cxx'
    defines=true, -- C preprocessor defines
    incdir=true, -- list of include directories
    flags=true,cflags=true,	 -- extra compile flags
    cdir=true,compile_directory=true, -- run tool in this directory
    debug=true, -- override global default set by -g or DEBUG variable
    optimize=true, -- override global default set by OPTIMIZE variable
    strict=true, -- strict compilation of files
    base=true, -- base directory for source and includes
    precompiled_header=true, -- provide a header to be precompiled and used
    llua=true, -- name of Lua module being built
    m32=true, -- 32-bit build on 64-bit platform
    ---- OS X support
    framework=true, -- link against framework (-framework flag)
    framework_dir=true, -- provide framework path (-F flag)
    universal=true,  -- universal 32bit/64bit Intel binary
    min_version=true, -- minimum OS X version (default 10.5)
}

function lake.add_program_option(options)
    options = deps_arg(options)
    utils.append_table(program_fields,utils.set(options))
end

function check_options (args,fields,where)
    if not fields then
        fields = program_fields
        where = 'program'
    end
    for k,v in pairs(args) do
        if type(k) == 'string' and not (k:match '^_' or fields[k]) then
            quit("unknown %s option '%s'",where,k)
        end
    end
end

local function tail (t,istart)
    istart = istart or 2
    if #t < istart then return nil end
    return {select(istart,unpack(t))}
end


local function _program(ptype,name,deps,lang)
    local dependencies,src,except,cr,args
    local libs = ''
    if type(name) == 'string' then name = { name } end
    if type(name) == 'table' then
        args = name
        check_options(args,program_fields,'program')
        -- @needs specifying libraries etc by 'needs', not explicitly
        if args.needs or NEEDS then
            -- @needs extra needs for all compile targets can be set with the NEEDS global.
            append_to_field(args,'needs',NEEDS)
            -- @lang a language may take over needs processing by defining process_needs()
            if lang.process_needs then
                lang.process_needs(ptype,args)
            else
                update_needs(ptype,args)
            end
        end
        -- @lang @needs default language can be overriden, explicitly or through a need
        if args.lang then
            lang = _G[args.lang]
            if lang == nil then quit("unknown language: "..args.lang) end
        end
        --- how default values can be set
        append_table(args,lang.defaults,true)
        append_table(args,args.args,true)
        --- the name can be the first element of the args table;
        --- the rest of the array will be considered as dependencies.
        args.name = args.name or args[1]
        args.deps = args.deps or tail(args)
        args.debug = args.debug or DEBUG
        args.cdir = args.cdir or args.compile_dir

        if lang.args_handler then -- language can modify args
            lang:args_handler(args)
        end

        name, deps = args.name, args.deps
        if args.cdir then
            args.base = args.cdir
        end
        --- if the name contains wildcards, then we make up a new unique target
        --- that depends on all the files. So for instance 'c.program '*' will compile
        --- all C files in a directory as programs.
        if name and path.is_mask(name) then
            local names = expand_args(name,args.ext or lang.ext,args.recurse,args.base)
            targets = {}
            for i,name in ipairs(names) do
                args.name = splitext(name)
                targets[i] = _program(ptype,args,'',lang)
            end
            return lake.phony(targets,'')
        end
        if args.shared or args.dll then ptype = 'dll' end
        src = args.src
        except = args.exclude
        args.flags = args.flags or args.cflags
        if args.m32 or M32 then
            if not lang.M32 then quit("no support for separate 32-bit compilation with this compiler") end
            append_to_field(args,'flags',lang.M32)
            append_to_field(args,'libflags',lang.M32)
        end
        concat_if_table(args,'flags')
        concat_if_table(args,'libflags')
        if args.libdir then
            libs = libs..concat_arg(baselang.LIBDIR,args.libdir,' ')
        end
        -- @lang an opportunity for this anguage to modify the lib flags
        if lang.flags_handler then
            libs = libs..lang:flags_handler(args,false)
        end
        -- @link'static' this program is statically linked against the runtime
        -- By default, GCC doesn't do this, but CL does
        if args.static then
            if not MSVC then libs = libs..lang.LIBSTATIC	end
        elseif args.static==false then
            args.dynamic = true
        end
        if args.dynamic then
            if MSVC then libs = libs..lang.LIBDYNAMIC	end
        end
        -- @link we may depend on static libraries which have explicit link needs!
        if deps then
            local xlibs,lflags = {}
            for d in list_(deps) do
                if istarget(d) and d.ptype == 'lib'  then
                    if d.libs then -- the lib has a list of libraries
                        list.extend_unique(xlibs,deps_arg(d.libs))
                    end
                    if d.libflags then -- the lib has special link flags
                        lflags = concat(lflags,d.libflags)
                    end
                end
            end
            if #xlibs > 0 then
                args.libs = list.extend_unique(args.libs,xlibs)
            end
            if lflags then
                args.libflags = concat(args.libflags,lflags)
            end
        end
        -- (if we're a static library, then these libs will be used when finally linking)
        if args.libs and ptype ~= 'lib' then
            local libstr
            if lang.lib_handler then
                libstr = lang.lib_handler(args.libs)
            else
                libstr = concat_arg(lang.LIBPARM,args.libs,lang.LIBPOST)
            end
            libs = libs..libstr
        end
        if args.libflags then
            libs = libs..args.libflags
            if not args.defines then args.defines = '' end
        end
        if args.strip then
            libs = libs..lang.STRIP
        end
        args.rules = args.rules or args.inputs
        if args.rules then
            cr = args.rules
            if is_simple_list(cr) then
                cr = depends(cr)
            end
            if src then warning('providing src= with explicit rules= is useless') end
        else
            if src == nil then src = {name} end
        end
        if args.export and lang.EXE_EXPORT then
            libs = libs..lang.EXE_EXPORT
        end
    else
        args = {} -- _probably_ an error??
    end
    ---- setting output directory and ensuring that it exists ----
    args.odir = args.odir or args.output_directory
    local odir = args.odir
    -- @compile setting 'odir' means we want a separate output directory. If a boolean,
    -- then we use prefix and debug/release.
    if odir then
        if odir == true then
            odir = PREFIX..choose(args.debug,'debug','release')
        end
    end
    -- by default, setting base also sets the output directory,
    -- if not specified (args.odir = false will suppress this)
    if args.base then
        if odir then
            if not isabs(odir) then
                odir = join(args.base,odir)
            end
        else
            odir = args.base
        end
        args.odir = odir
    end
    if odir and not isdir(odir) then path.mkdir(odir) end

    if args.def and WINDOWS then
        args.def = join(args.base,args.def)
    end

    -- we can now create a rule object to compile files of this type to object files,
    -- using the appropriate compile command.
    local pcr
    if not cr and lang.compile then
        -- generally a good idea for Unix shared libraries
        -- for OS X, -fPIC is on by default
        if ptype == 'dll' and not (PLAT=='Windows' or PLAT=='Darwin') then
            args.flags = concat(args.flags,'-fpic')
        end
        if args.precompiled_header then
            -- this is a header which must be specially compiled with the correct
            -- incantations
            local precomp = args.precompiled_header
            local oflags, odeps = args.flags, args.nodeps
            if cpp_ch.make_compiled_header then
                args.flags = concat(oflags,cpp_ch.make_compiled_header)
            end
            args.nodeps = true
            pcr = _compile(args,nil,cpp_ch)
            pcr.output_dir = odir
            pcr:add_target(precomp)
            args.flags, args.nodeps = oflags, odeps
            -- the source files are all compiled using this header
            args.flags = concat(args.flags,cpp_ch.use_compiled_header..precomp)
        end
        cr = _compile(args,args.compile_deps,lang)
        cr.output_dir = odir
    end

    -- can now generate a target for generating the executable or library, unless
    -- this is just a group of files
    local t
    if ptype ~= 'group' then
        if not name then quit('no name provided for program') end
        -- @deps we may have explicit dependencies, but we are always dependent on the files
        -- generated by the compile rule.
        if cr then
            dependencies = choose(deps,depends(cr,deps),cr)
        else
            dependencies = deps
        end
        local tname
        local btype = 'link'
        local link_prefix = ''
        if ptype == 'exe' then
            tname = name..(lang.EXE_EXT or EXE_EXT)
        elseif ptype == 'dll' then
            tname = name..(lang.DLL_EXT or DLL_EXT)
            libs = libs..' '..lang.LINK_DLL
        elseif ptype == 'lib' then
            local dir,fname = splitpath(name)
            tname = lang.LIB_PREFIX..fname..lang.LIB_EXT
            if dir ~= '' then
                tname = join(dir,tname)
            end
            btype = 'lib'
        end
        -- @doc 'subsystem' with Windows, have to specify subsystem='windows' for pure GUI applications; ignored otherwise
        if args.subsystem and PLAT=='Windows' then
            libs = libs..' '..SUBSYSTEM..args.subsystem
        end
        local link_str = link_prefix..subst_all_but_basic(lang[btype])
        -- @lang conditional post-build step if a language defines a function 'post_build'
        -- that returns a string
        if btype == 'LINK' and lang.post_build then
            local post = lang.post_build(ptype,args)
            if post then link_str = link_str..' && '..post end
        end
        local target = tname

        -- @doc [target,odir] if the target looks like 'dir/name' then
        -- we make sure that 'dir' does exist. Otherwise, if `odir` exists it
        -- will be prepended.
        local tpath,tname = splitpath(target)
        if tname == '' then quit("target name cannot be empty, or a directory") end
        if tpath == '' then
            if odir then target = join(odir,target) end
        else
            path.mkdir(tpath)
        end


        t = new_target(target,dependencies,link_str,true)
        t.name = name
        t.libs = ptype ~= 'lib' and libs or args.libs
        t.libflags = args.libflags
        t.link_lang = lang
        t.input = name..lang.obj_ext
        t.lua = args.lua
        t.llua = args.llua
        t.debug = args.debug
        t.ptype = ptype
        t.basedir = args.base
        t.args = args
        if args.cdir then
            t.dir = args.cdir
            t.cdir = args.cdir
        end
        if cr then cr.parent = t end
        t.compile_rule = cr
    end
    if cr then
        cr.filter = lang.filter
        cr.stdout = lang.stdout
    end
    -- we have been given a list of source files, without extension
    if src then
        local ext = args.ext or lang.ext
        local root
        -- hack: ext is '*' in a rule means that the output extension equals the input extension
        if ext == '*' then ext = '' end
        if args.recurse then
            local first = type(src) == 'table' and src[1] or src
            root = dirname(first,true)
        end
        src = expand_args(src,ext,args.recurse,args.base)
        if except then
            except = expand_args(except,ext,false,args.base)  -- args.recurse?
            list.erase(src,except)
        end
        -- all these compile targets can depend on a precompiled header...
        if pcr then pcr = pcr:get_targets() end

        if cr then
            for f in list_(src) do cr:add_target(f,pcr,root) end
        else
            -- for languages where compilation occurs at 'link' stage (e.g. C#)
            t.src = src
            -- and update dependencies!!
            target_add_deps(t,src)
        end
    end
    return t,cr
end

function lake.add_proglib (fname,lang,kind)
    lang[fname] = function (name,deps)
        return _program(kind,name,deps,lang)
    end
end

function lake.add_prog (lang) lake.add_proglib('program',lang,'exe') end
function lake.add_shared (lang) lake.add_proglib('shared',lang,'dll') end
function lake.add_library (lang) lake.add_proglib('library',lang,'lib') end

function lake.add_group (lang)
    lang.group = function (name,deps)
        local _,cr = _program('group',name,deps,lang)
        return cr
    end
end

for lang in list_ {c,c99,cpp,cpp11,s} do
    lake.add_prog(lang)
    lake.add_shared(lang)
    lake.add_library(lang)
    lake.add_group(lang)
end

lake.add_group(wresource)
lake.add_group(file)

function lake.program(fname,deps)
    local tp,name = lake.deduce_tool(fname)
    return tp.program(name,deps)
end

function lake.compile(args,deps)
    local tp,name = lake.deduce_tool(args.ext or args[1])
    append_table(args,tp.defaults)
    local rule = _compile(args,deps,tp)
    rule:add_target(name)
    return rule
end

function lake.shared(fname,deps)
    local tp,name = lake.deduce_tool(fname)
    return tp.shared(name,deps)
end

--- defines the default target for this lakefile
function default(...)
    if select('#',...) ~= 1 then quit("default() expects one argument!\nDid you use {}?") end
    local args = select(1,...)
    new_target('default',args,'',true)
end

target = {}
local tmm = utils.make_callable(target,new_target)
tmm.__index = function(obj,name)
    return function(...)
        return new_target(name,...)
    end
end

action = {}
local function  action_(name,action,...)
    local args
    if type(name) == 'function' then
        args = {action,...}
        action = name
        name = '*'
    else
        args = {...}
    end
    return new_target(name,nil,function() action(unpack(args)) end)
end

function lake.run_target(t,args)
	local name = t.name .. '-output'
	args = args or {}
	append(args,'>'..name)
	return new_target(name,t,function()
		lake.run(t,args,1)
	end)
end
tmt.run = lake.run_target

local amt = utils.make_callable(action,action_)
amt.__index = function(obj,name)
    return function(...)
        return action_(name,...)
    end
end

ENV = {SEP=Windows and ';' or ':'}
setmetatable(ENV,{
    __index = function(self,key)
        return env(key)
    end;
    __newindex = function(self,key,value)
        local M = winapi or posix or quit("need winapi/posix for setenv")
        M.setenv(key,value)
    end
})

IF = choose

local function L_impl(t)
    if type(t) ~= 'table' then
        return lake.deps_arg(t)
    end
    local res,indices = {},{}
    for k,v in pairs(t) do
        if type(k) ~= 'number' then -- just copy string keys
            res[k] = v
        else
            append(indices,k)
        end
    end
    table.sort(indices) -- voila, hole free array!
    for _,k in ipairs(indices) do
        list.extend(res,L_impl(t[k]))
    end
    return res
end

L = L_impl

function lake.compiler_version (cc)
    local text,major, minor, rev
    cc = cc or CC
    if cc=='cl' then
        text = utils.shell 'cl'
        major, minor, rev  = text:match("[Cc]ompiler [Vv]ersion%s+(%d+)%.(%d+)%.(%d+)")
        if not major then return end
    else
        text = utils.shell (cc..' -v')
        major, minor, rev = text:match("gcc version (%d+)%.(%d+)%.(%d+)")
        if not major then return end
    end
    return {
        MAJOR = tonumber(major),
        MINOR = tonumber(minor),
        REV   = tonumber(rev),
    }
end

process_args()