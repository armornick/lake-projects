/*
 *  "$Id: l-bia.c,v 1.3 2008/07/09 20:32:39 br_lemes Exp $"
 *  Lua Built-In program (L-Bia)
 *  A self-running Lua interpreter. It turns your Lua program with all
 *  required modules and an interpreter into a single stand-alone program.
 *  Copyright (c) 2007,2008 Breno Ramalho Lemes
 *
 *  L-Bia comes with ABSOLUTELY NO WARRANTY; This is free software, and you
 *  are welcome to redistribute it under certain conditions; see LICENSE
 *  for details.
 *
 *  Report bugs to <br_lemes@yahoo.com.br>
 *  http://l-bia.luaforge.net/
 */

#ifndef L_BIA_C
#define L_BIA_C

#include "lbconf.h"

/* Data type inside overlay */
#define LB_LUAMAIN 0
#define LB_LMODULE 1
#define LB_CMODULE 2
#define LB_LIBRARY 3

/* Dynamic library extension */
#ifdef _WIN32
#define LB_DLEXT ".dll"
#else /* not _WIN32 */
#define LB_DLEXT ".so"
#endif /* not _WIN32 */

/* Global program name: lb_fnname(argv[0]) */
const char *lb_progname;

/* Global state */
lua_State *L = NULL;

/* File ID struct */
typedef struct {
  /* Flawfinder: ignore */
  char id[4];       /* LB02 */
  uint32_t dlen;    /* decompressed lenght */
  uint32_t adler32; /* adler32 checksum */
  uint32_t nlen;    /* compressed or normal lenght */
} lb_idtype;

/* Return nonzero if DIR is an existent directory. */
static int lb_direxists(const char *dir) {
  struct stat buf;
  return stat(dir, &buf) == 0 && S_ISDIR (buf.st_mode);
}

/* Return a string with the first of TMPDIR, TMP, /tmp that exists. You must
   not modify this string. If none of the searched dirs exists, the value is
   a null pointer. */
char *lb_tmppath(void) {
  char *d = NULL;
#ifndef _WIN32
  if ((getuid() == geteuid()) && (getgid() == getegid())) {
#endif /* not _WIN32 */
    d = (char*)getenv("TMPDIR"); /* Flawfinder: ignore */
    if (!d || !lb_direxists(d))
      d = (char*)getenv("TMP"); /* Flawfinder: ignore */
#ifndef _WIN32
  }
#endif /* not _WIN32 */
  if (!d || !lb_direxists(d))
    d = "/tmp";
  if (!lb_direxists(d))
    return NULL;
  return d;
}

/* Return a pointer to the character after the last slash, or to the start
   of the FILENAME if there is none, or null if FILENAME ends with '/' */
const char *lb_fnname(const char *filename) {
  const char *p,*q;
  if (!filename) return (NULL);
  q = filename;
  if (q[0] && q[1]==':') q += 2; // skip leading drive letter
  for (p = q; *p; p++) if (*p == '/' || *p == '\\') q = p+1;
  return q;
}

/* Print an error message and exit with EXIT_FAILURE */
void lb_error(const char *msg) {
  if (msg != NULL) fprintf(stderr,"%s: %s\n",lb_progname,msg);
  exit(EXIT_FAILURE);
}

/* Get a better error message in format "cannot *what* *name*: *why*"
   and call lb_error to print it and exit. If WHY is NULL, try
   strerror(errno) or omit */
void lb_cannot(const char *what, const char *name,const char *why) {
  char *emsg = NULL;
  int e = errno;
  if (why) {
    /* Flawfinder: ignore */ /* "cannot  : " + '\0' */
    size_t len = strlen(what)+strlen(name)+strlen(why)+11;
    emsg = alloca(len);
    /* Flawfinder: ignore */
    snprintf(emsg,len,"cannot %s %s: %s",what,name,why);
  } else if (e) {
    char *estr = strerror(e);
    /* Flawfinder: ignore */ /* "cannot  : " + '\0' */
    size_t len = strlen(what)+strlen(name)+strlen(estr)+11;
    emsg = alloca(len);
    /* Flawfinder: ignore */
    snprintf(emsg,len,"cannot %s %s: %s",what,name,estr);
  } else {
    /* Flawfinder: ignore */
    size_t len = strlen(what)+strlen(name)+9; /* "cannot  " + '\0' */
    emsg = alloca(len);
    /* Flawfinder: ignore */
    snprintf(emsg,len,"cannot %s %s",what,name);
  }
  lb_error(emsg);
}

/* This function create a temporary library with the specified data buf
   and size, and push it's name on the stack top. In case of any error,
   this function calls lb_error and never returns. */
void lb_libcreate(const char *libname, const char *buf, uint32_t size) {
  FILE *libfile;
#ifdef _WIN32
  /* Flawfinder: ignore */
  libfile = fopen(libname,"wb+"); /* try create a new file */
#else /* not _WIN32 */
  /* Flawfinder: ignore */
  int fd = open(libname,O_CREAT|O_TRUNC|O_RDWR,0755);
  if (fd != -1)
    libfile = fdopen(fd,"wb+");
  else
    libfile = NULL;
#endif /* not _WIN32 */
  if (libfile != NULL) {
    if (fwrite(buf,size,1,libfile)!=1) lb_cannot("write",libname,NULL);
    fclose(libfile);
  } else {
    int e = errno;
    if (e == EACCES) { /* try reuse */
      /* Flawfinder: ignore */
      if ((libfile = fopen(libname,"rb")) != NULL) {
        if(fseek(libfile,0,SEEK_END)!=0) lb_cannot("seek",libname,NULL);
        long int i = ftell(libfile);
        if (i == -1) lb_cannot("tell",libname,NULL);
        if (i == size) {
          rewind(libfile);
          char *tmp = alloca(size);
          if(fread(tmp,size,1,libfile)!=1) lb_cannot("read",libname,NULL);
          fclose(libfile);
          if(!strncmp(tmp,buf,size))
            return; /* it's ok */
          else lb_cannot("create",libname,"file exist and differ");
        } else
          lb_cannot("create",libname,"file exist and differ");
      }
    } else
      lb_cannot("create",libname,NULL);
  }
}

/* This function makes a clean up atexit */
void lb_quit(void) {
  lua_getfield(L,LUA_REGISTRYINDEX,"_LBCM");
  lua_pushnil(L);
  while (lua_next(L,-2) != 0) {
    ll_unloadlib(lua_touserdata(L,-1));
    remove(lua_tostring(L,-2));
    lua_pop(L,1);
  }
  LBCONF_USERFUNC_DONE(L);
  lua_close(L);
}

int main(int argc, char *argv[]) {
  lb_idtype lb_id;
  lzo_uint  lb_overhead;
  lzo_uint  lb_offset;
  lzo_bytep lb_data;
  lzo_bytep lb_temp;

  /* start up the stuff */
#ifdef _WIN32
  char selfname[MAX_PATH]; /* Flawfinder: ignore */
  if (GetModuleFileName(NULL,selfname,sizeof(selfname))==0)
    lb_error("cannot locate this executable");
  argv[0] = selfname;
#endif /* not _WIN32 */
  lb_progname = lb_fnname(argv[0]);
  const char *lb_path = lb_tmppath();
  if (lb_path == NULL) lb_cannot("find","tmp dir",NULL);

  if (lzo_init() != LZO_E_OK)
    lb_error("internal LZO error");
  if ((L = luaL_newstate()) == NULL) lb_error("not enough memory");
  luaL_openlibs(L);
  LBCONF_USERFUNC_INIT(L);

  /* open and load */
  FILE *lb_file = fopen(argv[0],"rb"); /* Flawfinder: ignore */
  if (lb_file == NULL)
    lb_cannot("open",argv[0],NULL);
  if (fseek(lb_file,-sizeof(lb_id),SEEK_END)!=0)
    lb_cannot("seek",argv[0],NULL);
  if (fread(&lb_id,sizeof(lb_id),1,lb_file)!=1)
    lb_cannot("read",argv[0],NULL);
  if (memcmp(lb_id.id,"LB02",4)!=0)
    lb_error("missing overlay");
  if (fseek(lb_file,-(sizeof(lb_id)+lb_id.nlen),SEEK_END)!=0)
    lb_cannot("seek",argv[0],NULL);
  if (lb_id.dlen != 0) {
    lb_overhead = lb_id.dlen / 16 + 64 + 3;
    lb_offset = lb_id.dlen + lb_overhead - lb_id.nlen;
    lb_temp = (lzo_bytep)alloca(lb_id.dlen + lb_overhead);
    lb_data = lb_temp + lb_offset;
  } else
    lb_data = (lzo_bytep)alloca(lb_id.nlen);
  if (fread(lb_data,lb_id.nlen,1,lb_file)!=1)
    lb_cannot("read",argv[0],NULL);
  fclose(lb_file);

  /* checksum */
  if (lzo_adler32(0,(lzo_bytep)lb_data,lb_id.nlen)!=lb_id.adler32)
    lb_error("bad checksum");

  /* decompress */
  if (lb_id.dlen != 0) {
    lzo_uint new_len;
    int r = lzo1x_decompress(lb_data,lb_id.nlen,lb_temp,&new_len,NULL);
    if (r != LZO_E_OK || new_len != lb_id.dlen)
      lb_error("overlapping decompression failed");
    lb_data = lb_temp;
  } else 
    lb_id.dlen = lb_id.nlen;

  /* set parameters (arg = argv) */
  lua_newtable(L);
  { int i;
    for (i=0;i <= argc; i++) {
      lua_pushstring(L,argv[i]);
      lua_rawseti(L,-2,i);
    }
  }
  lua_setglobal(L,"arg");

  /* setup the clean up */
  lua_newtable(L);
  lua_setfield(L,LUA_REGISTRYINDEX,"_LBCM");
  lua_getfield(L,LUA_REGISTRYINDEX,"_LBCM");   /* _LBCM is at index 1   */
  atexit(lb_quit);

  /* link, load and run loop */
  lua_getfield(L,LUA_REGISTRYINDEX,"_LOADED"); /* _LOADED is at index 2 */
  char *buf = lb_data;
  uint32_t ptr = 0;
  do {
    char  _type = *buf++;
    char  _nlen = *buf++;
    char *_name = alloca((size_t)_nlen+1);
    memcpy(_name,buf,_nlen); /* Flawfinder: ignore */
    _name[_nlen] = '\0';
    buf += _nlen;
    uint32_t _size;
    memcpy(&_size,buf,4); /* Flawfinder: ignore */
    buf += 4;
    switch (_type) {
      case LB_LUAMAIN: /* run */
        if (luaL_loadbuffer(L,buf,_size,_name))
          lb_error(lua_tostring(L,-1));
        int i = 1;
        for(;i <= argc;i++)
          lua_pushstring(L,argv[i]);
        if (lua_pcall(L,i-1,0,0))
          lb_error(lua_tostring(L,-1));
        return 0;
      case LB_LMODULE: /* load */
      case LB_CMODULE: /* link and load */
        lua_getfield(L,2,_name); /* _LOADED[name] */
        if (lua_toboolean(L,-1)) { /* is it there? */
          if (lua_touserdata(L,-1) == sentinel) { /* check loops */
            lua_pushfstring(L,"loop or previous error loading module '%s'",_name);
            lb_error(lua_tostring(L,-1));
          }
          lua_pop(L,2);
          break; /* package is already loaded */
        } else lua_pop(L,1);
        /* else must load it */
        if (_type == LB_LMODULE) {
          if (luaL_loadbuffer(L,buf,_size,_name))
            lb_error(lua_tostring(L,-1));
        } else {
          lua_pushfstring(L,"%s/%s%s",lb_path,_name,LB_DLEXT);
          lb_libcreate(lua_tostring(L,-1),buf,_size);
          void *_lib = ll_load(L,lua_tostring(L,-1));
          if (_lib == NULL) lb_cannot("load library",_name,lua_tostring(L,-1));
          lua_CFunction _fun = ll_sym(L,_lib,mkfuncname(L,_name));
          if (_fun == NULL) lb_cannot("find function",lua_tostring(L,-2),lua_tostring(L,-1));
          lua_pop(L,1); /* pop value from mkfuncname() */
          lua_pushlightuserdata(L,_lib);
          lua_settable(L,1); /* _LBCM[libname] = _lib */
          lua_pushcfunction(L,_fun);
        }
        lua_pushlightuserdata(L,sentinel);
        lua_setfield(L,2,_name); /* _LOADED[name] = sentinel */
        lua_pushstring(L,_name); /* pass name as argument to module */
        if (lua_pcall(L,1,1,0)) /* run loaded module */
          lb_error(lua_tostring(L,-1)); 
        if (!lua_isnil(L,-1)) /* non-nil return ? */
          lua_setfield(L,2,_name); /* _LOADED[name] = returned value */
        lua_getfield(L,2,_name);
        if (lua_touserdata(L,-1)==sentinel){ /* module did not set a value? */
          lua_pushboolean(L,1); /* use true as result */
          lua_setfield(L,2,_name); /* _LOADED[name] = true */
        }
        break;
      case LB_LIBRARY: /* link */
        lua_pushfstring(L,"%s/%s%s",lb_path,_name,LB_DLEXT);
        lb_libcreate(lua_tostring(L,-1),buf,_size);
        void *_lib = ll_load(L,lua_tostring(L,-1));
        if (_lib == NULL) lb_cannot("load library",_name,lua_tostring(L,-1));
        lua_pushlightuserdata(L,_lib);
        lua_settable(L,1); /* _LBCM[libname] = _lib */
        break;
    }
    buf += _size;
    ptr += 2 + _nlen + 4 + _size;
  } while (ptr < lb_id.dlen);
  return 0;
}

#endif /* L_BIA_C */
