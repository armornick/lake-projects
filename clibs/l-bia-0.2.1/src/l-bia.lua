#!/usr/bin/env lua
--
--  "$Id: l-bia.lua,v 1.3 2008/07/09 20:34:03 br_lemes Exp $"
--  Lua Built-In program (L-Bia)
--  A self-running Lua interpreter. It turns your Lua program with all
--  required modules and an interpreter into a single stand-alone program.
--  Copyright (c) 2007,2008 Breno Ramalho Lemes
--
--  L-Bia comes with ABSOLUTELY NO WARRANTY; This is free software, and you
--  are welcome to redistribute it under certain conditions; see LICENSE
--  for details.
--
--  <br_lemes@yahoo.com.br>
--  http://l-bia.luaforge.net/
--

require("lbaux")

require("io")
require("os")
require("table")
require("string")
require("package")

-- Values
local LB_NAME      = "L-Bia"
local LB_VERSION   = "0.2.1"
local LB_LONGNAME  = "Lua Buit-In program"
local LB_COPYRIGHT = "Copyright (c) 2007,2008 Breno Ramalho Lemes"

local LB_IDLEN = 16

-- Data type inside overlay
local LB_LUAMAIN = 0
local LB_LMODULE = 1
local LB_CMODULE = 2
local LB_LIBRARY = 3

-- Type names
local lb_types   = {"Lua module","C module","Library"}

-- Standart packages table
local lb_stdll   = {coroutine=true,debug=true,io=true,math=true,
                    os=true,package=true,string=true,table=true}

-- Mode and options description
local lb_mdesc = {
  ["-d"]="Dump a binary representation of Lua scripts (precompile)",
  ["-r"]="Raw copy Lua scripts (keep comments and whitespace",
  ["-s"]="Strip Lua scripts by removing comments and whitespace",
}

local lb_odesc = {
  ["-o"]="<file> Write output to <file>",
  ["-i"]="<file> Read input from <file>",
  ["-l"]="<lib>  Link with dynamic library <lib>",  
  ["-h"]="Show this help message and exit (synonym for --help)",
  ["-v"]="Show version number and exit (synonym for --version)",
  ["--"]="Stop parsing options",
}

-- Return a substring from last period in FILENAME or empty if none is found
function lb_fnext(filename)
  local b,e = string.find(filename,"%.[^\\/]*$")
  if b then
    return string.sub(filename,b,e)
  end
  return ""
end

-- Return a substring after the last slash, or to the start of the FILENAME
-- if there is none, or empty if FILENAME ends with '/' */
function lb_fnname(filename)
  repeat
    local s,e = string.find(filename,"[\\/].*$")
    if s then filename = string.sub(filename,s+1,e) end
  until not s
  return filename
end

-- Return a substring before the last period in FILENAME or FILENAME if none
function lb_fnbase(filename)
  return (string.gsub(filename,"%.[^\\/]*$",""))
end

-- Print an error message and exit with exit(1)
function lb_error(msg)
  if msg then io.stderr:write(lb_fnname(arg[0])..": "..msg.."\n") end
  os.exit(1)
end

-- Get a better error message in format "cannot *what* ..." and call
-- lb_error to print it and exit
function lb_cannot(what,...)
  -- if no error, return ...
  if arg[1] then return unpack(arg) end
  return lb_error("cannot "..what.." "..arg[2])
end

local LUA_DIRSEP = '/'
local LUA_PATH_MARK = '?'
-- Find and return full filename of a package
function lb_findfile(name, pname)
  if name ~= "lua5.1" then
    name = string.gsub(name, "%.", LUA_DIRSEP)
  end
  local path = package[pname]
  assert(type(path) == "string",
         string.format("package.%s must be a string",pname))
  for c in string.gmatch(path, "[^;]+") do
    c = string.gsub(c, "%"..LUA_PATH_MARK, name)
    local f = io.open(c)
    if f then f:close() return c end
  end
  return nil -- not found
end

-- Print a brief usage
function lb_usage(progname)
  print(LB_LONGNAME.." ("..LB_NAME..") "..LB_VERSION)
  print("Usage: "..progname.." [options] <file>")
  print()
  print("Options:")
  for k,v in pairs(lb_mdesc) do
    print("  "..k..string.rep(" ",8-#k)..v)
  end
  for k,v in pairs(lb_odesc) do
    print("  "..k..string.rep(" ",8-#k)..v)
  end
  print()
  print("L-Bia comes with ABSOLUTELY NO WARRANTY; This is free software, and you are")
  print("welcome to redistribute it under certain conditions; see LICENSE for details.")
  print("Report bugs to <br_lemes@yahoo.com.br>")
end

-- Print version
function lb_version()
  print(LB_NAME.." "..LB_VERSION)
  print(LB_COPYRIGHT)
  print("L-Bia comes with ABSOLUTELY NO WARRANTY; This is free software, and you are")
  print("welcome to redistribute it under certain conditions; see LICENSE for details.")
end
  
-- Parse options and return input, script, mode (-d, -r or -s) and a
-- table of libraries.
function lb_getopts()
  local exeext = lb_fnext(arg[-1] or arg[0])
  local outext = false
  local input  = false
  local output = false
  local script = false
  local mode   = false
  local libs   = { }
  local stop   = false

  while arg[1] do
    if string.sub(arg[1],1,1) == "-" and not stop then
      if arg[1] == "--" then
        stop = true
      elseif arg[1] == "-i" then
        if not input and arg[2] then
          input = arg[2]
          table.remove(arg,1)
        else lb_error("argument to '-i' is missing") end
      elseif arg[1] == "-o" then
        if not output and arg[2] then
          output = arg[2]
          table.remove(arg,1)
        else lb_error("argument to '-o' is missing") end
      elseif arg[1] == "-l" then
        if arg[2] then
          table.insert(libs,arg[2])
          table.remove(arg,1)
        else lb_error("argument to '-l' is missing") end
      elseif arg[1] == "-v" or arg[1] == "--version" then
        lb_version()
        return nil
      elseif arg[1] == "-h" or arg[1] == "--help" then
        lb_usage(lb_fnname(arg[0]))
        return nil
      else
        if lb_mdesc[arg[1]] then
          mode = arg[1]
        else
          lb_error("unrecognized option '"..arg[1].."'")
        end
      end
    elseif not script then
      script = arg[1]
    else lb_error("too many arguments") end
    table.remove(arg,1)
  end
  if not script then lb_error("no script") end
  mode = mode or "-s"
  if not output then
    output = lb_fnbase(script)
  end
  if not input then
    if not arg[-1] then
      input = arg[0]
    else lb_error("no input") end
  end
  outext = outext or exeext
  if lb_fnext(input) == "" then input = input..exeext end
  if script and lb_fnext(script) == "" then script = script..".lua" end
  if lb_fnext(output) == "" then output = output..outext end
  return input,script,output,mode,libs
end

-- Based on code by Waldemar Celes - TeCGraf/PUC-Rio Jul 1999
-- BEGIN

-- mark up comments and strings
STR1 = "\001"
STR2 = "\002"
STR3 = "\003"
STR4 = "\004"
-- long comment
REM1 = "\008"
-- short comment
REM2  = "\005"
ANY  = "([\001-\005\008])"
-- ANY ="([\001-\005])"
ESC1 = "\006"
ESC2 = "\007"

MASK = { -- the substitution order is important
  {ESC1, "\\'"},
  {ESC2, '\\"'},
  {STR1, "'"},
  {STR2, '"'}, -- "
-- long comment
  {REM1, "%-%-%[%["},
  {STR3, "%[%["},
  {STR4, "%]%]"},
-- short comment
  {REM2 , "%-%-"},
}

function lb_mask(s)
  for i,v in ipairs(MASK)  do
    s = string.gsub(s,v[2],v[1])
  end
  return s
end

function lb_check(s)
  local code = "return function (...)\n"..s.."\nend"
  local f,e = loadstring(code)
  if not f then lb_error(e) end
  local a,b = pcall(f)
  if not a then lb_error(b) end
end

-- Return a table of requires (based on clean-up code)
function lb_reqtab(s)
  local reqpat = {
    "require%s-%(?%s-",
    "pcall%s-%(%s-require%s-,%s-",
  }
  local result = { }
  s = lb_mask(s)
  while 1 do
    b,e,d = string.find(s,ANY)
    if b then
      local p = string.sub(s,1,b-1)
      s = string.sub(s,b+1)
      if d == STR1 or d == STR2 then
        e = string.find(s,d)
        for i,v in ipairs(reqpat) do
          if string.find(p,v) then
            local r = string.sub(s,1,e-1)
            -- ignore standart packages
            if lb_stdll[r] ~= true then
              table.insert(result,string.sub(s,1,e-1))
            end
            break
          end
        end
        s = string.sub(s,e+1)
      elseif d == REM1 then
        e = string.find(s,STR4)
        s = string.sub(s,e+1)
      elseif d == STR3 then
        e = string.find(s,STR4)
        for i,v in ipairs(reqpat) do
          if string.find(p,v) then
            local r = string.sub(s,1,e-1)
            -- ignore standart packages
            if lb_stdll[r] ~= true then
              table.insert(result,string.sub(s,1,e-1))
            end
            break
          end
        end
        s = string.sub(s,e+1)
      elseif d == REM2 then
        s = string.gsub(s,"[^\n]*(\n?)","%1",1)
      else
        s = string.sub(s,b+1,-1)
      end
    else break end
  end
  return result
end

-- END

-- Return lstrip, dumped or raw string according to mode
function lb_mfunc(mode,s)
  if mode == "-s" then
    return lbaux.lstrip(s)
  elseif mode == "-d" then
    return string.dump(loadstring(s))
  else -- for sure it's mode == "-r"
    return s
  end
end

-- Return a string with a file and the appropriate header to insert
-- into overlay
function lb_insert(name,fullname,type,mode)
  if #name > 255 then
    lb_error(lb_types[type].." name greater than 255: '"..name"'")
  end
  local l_handle = lb_cannot("open",io.open(fullname,"rb"))
  local l_string = lb_cannot("read",l_handle:read("*a"))
  local len1 = #l_string
  l_handle:close()
  if type == LB_LMODULE then
    lb_check(l_string)
    l_string = lb_mfunc(mode,l_string)
  end
  local len2 = 2+#name+4+#l_string
  return string.char(type)..                  -- File type
         string.char(#name)..name..           -- Name (size and name)
         lbaux.toustr32(#l_string)..l_string, -- File (size and data)
         {name = lb_fnname(fullname),
          type = lb_types[type], len1 = len1, len2 = len2}
end

function lb_center(str,size)
  str = string.rep(" ",(size-#str)/2)..str..string.rep(" ",(size-#str)/2)
  if #str < size then str = " "..str end
  if #str > size then str = string.sub(str,1,-2) end
  return str
end

function lb_showinfo(len1,len2,type,name)
  if len1 and len1 ~= len2 then
    print(string.format("  %10d --> %10d  %s  %s",len1,len2,
                        lb_center(type,11),name))
  else
    print(string.format("  %13s  %10d  %s  %s"," ",len2,
                        lb_center(type,11),name))
  end
end

function main(input,script,output,mode,libs)
  if not input then return end

  -- output string
  local o_string = ""

  -- read input
  local i_handle = lb_cannot("open",io.open(input,"rb"))
  local i_string = lb_cannot("read",i_handle:read("*a"))
  i_handle:close()

  -- read script
  local s_handle = lb_cannot("open",io.open(script,"rb"))
  local s_string = lb_cannot("read",s_handle:read("*a"))
  local s_len1 = #s_string
  s_handle:close()

  -- strip "#!" from first line
  if string.sub(s_string,1,2) == "#!" then
    local _,i = string.find(s_string,"^#!.-\n")
    s_string = string.sub(s_string,i,-1)
  end

  lb_check(s_string)

  local info = { }
  for i,name in ipairs(libs) do
    local fullname = lb_findfile(name,"cpath")
    if fullname then
      local _data,_info = lb_insert(name,fullname,LB_LIBRARY)
      o_string  = o_string.._data
      table.insert(info,_info)
    else lb_error("Library '"..name.."' not found") end
  end
  local s_reqtab = lb_reqtab(s_string)
  for i,name in ipairs(s_reqtab) do
    local fullname = lb_findfile(name,"path")
    if fullname then
      local _data,_info = lb_insert(name,fullname,LB_LMODULE,mode)
      o_string  = o_string.._data
      table.insert(info,_info)
    else
      fullname = lb_findfile(name,"cpath")
      if fullname then
        local _data,_info = lb_insert(name,fullname,LB_CMODULE)
        o_string = o_string.._data
        table.insert(info,_info)
      else lb_error("Module '"..name.."' not found") end
    end
  end
  s_string = lb_mfunc(mode,s_string)
  local s_name = lb_fnname(script)
  if #s_name > 255 then s_name = string.sub(s_name,1,255) end
  o_string = o_string..string.char(LB_LUAMAIN)..  -- File ID
             string.char(#s_name)..s_name..       -- Name (size and name)
             lbaux.toustr32(#s_string)..s_string  -- File (size and data)
  local s_len2 = 2+#s_name+4+#s_string
  local mlzosize = 0
  local flatsize = #o_string
  local n_string = lbaux.compress(o_string)
  if #n_string < #o_string then
    mlzosize = #n_string
    o_string = n_string
  else n_string = nil end

  -- write output
  local o_handle = lb_cannot("open",io.open(output,"wb"))
  if string.sub(i_string,-LB_IDLEN,-13) == "LB02" then
    local size = lbaux.touint32(string.sub(i_string,-4))
    i_string = string.sub(i_string,1,-(size+LB_IDLEN+1))
  end
  o_handle:write(i_string)
  o_handle:write(o_string,"LB02")
  if mlzosize > 0 then 
    o_handle:write(lbaux.toustr32(flatsize),
                   lbaux.toustr32(lbaux.adler32(o_string)),
                   lbaux.toustr32(mlzosize))
  else
    o_handle:write(lbaux.toustr32(0),
                   lbaux.toustr32(lbaux.adler32(o_string)),
                   lbaux.toustr32(flatsize))
  end
  if lbaux.fchmod then lbaux.fchmod(o_handle,0775) end
  o_handle:close()

  print(LB_LONGNAME.." ("..LB_NAME..") "..LB_VERSION)
  print(LB_COPYRIGHT)
  print()
  print("          File size           File type   File name")
  print("  -------------------------  -----------  --------------------")
  for i,v in ipairs(info) do
    lb_showinfo(v.len1,v.len2,v.type,v.name)
  end
  lb_showinfo(s_len1,s_len2,"Lua script",lb_fnname(script))
  print("  -------------------------  -----------  --------------------")
  lb_showinfo(nil,#i_string,"Input",lb_fnname(input))
  if mlzosize > 0 then
    lb_showinfo(flatsize,mlzosize,"Overlay","miniLZO compression")
  else
    lb_showinfo(nil,flatsize,"Overlay","No compression")
  end
  lb_showinfo(nil,LB_IDLEN,"L-Bia ID","")
  print("  -------------------------  -----------  --------------------")
  lb_showinfo(nil,#i_string+#o_string+LB_IDLEN,"Output",lb_fnname(output))
end

if #arg == 0 then
  lb_usage(lb_fnname(arg[0]))
else
  main(lb_getopts())
end
