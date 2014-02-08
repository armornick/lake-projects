#include <ctype.h>
#include <curses.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#define LCURSES_LIBNAME "curses"

static void keycode2buffer (luaL_Buffer *b, int ch);

static int lcurses_printw (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  int i;
  lua_getglobal(L, "tostring");
  for (i=1; i<=n; i++) {
    const char *s;
    lua_pushvalue(L, -1);  /* function to be called */
    lua_pushvalue(L, i);   /* value to print */
    lua_call(L, 1, 1);
    s = lua_tostring(L, -1);  /* get result */
    if (s == NULL)
      return luaL_error(L, LUA_QL("tostring") " must return a string to "
                           LUA_QL("print"));
    if (i>1) printw("\t", stdout);
    printw(s, stdout);
    lua_pop(L, 1);  /* pop result */
  }
  printw("\n", stdout);
  refresh();
  return 0;
}

static int lcurses_getch (lua_State *L) {
	int ch;
	ch = getch();
	lua_pushinteger (L, ch);
	return 1;
}

static int lcurses_echo (lua_State *L) {
	int echo_state;
	echo_state = lua_toboolean (L, 1);

	if (echo_state) {
		echo();
	} else {
		noecho();
	}

	return 0;
}

static int lcurses_keystr (lua_State *L) {
  luaL_Buffer b;
  luaL_buffinit(L, &b);

  int ch = luaL_checkint(L, 1);
  keycode2buffer(&b, ch);
  luaL_pushresult(&b);
  return 1;
}

static void toggle_field (lua_State *L, int tabidx, const char *fieldname, int attr) {
    lua_getfield(L, tabidx, fieldname);
    int toggle = lua_toboolean(L, -1);
    if (toggle) {
        attron(attr);
    } else {
        attroff(attr);
    }
    lua_pop(L, 1);
}

static int lcurses_attributes (lua_State *L) {
    if (!lua_istable(L, 1)) luaL_argerror(L, 1, "should be a table");

    toggle_field(L, 1, "bold", A_BOLD);
    toggle_field(L, 1, "underline", A_UNDERLINE);
    toggle_field(L, 1, "reverse", A_REVERSE);
    toggle_field(L, 1, "blink", A_BLINK);
    toggle_field(L, 1, "rightline", A_RIGHTLINE);
    toggle_field(L, 1, "leftline", A_LEFTLINE);
    toggle_field(L, 1, "invisible", A_INVIS);

    return 0;
}

#ifndef uchar
#define uchar(c)        ((unsigned char)(c))
#endif

static int lcurses_addch (lua_State *L) {
    int n = lua_gettop(L);  /* number of arguments */
    int i;

    for (i=1; i<=n; i++) {
        int c = luaL_checkint(L, i);
        luaL_argcheck(L, uchar(c) == c, i, "invalid value");
        addch(c);
    }

    return 0;
}

#undef uchar


static int lcurses_pos (lua_State *L) {
    int y, x;
    getyx(stdscr, y, x);
    lua_pushinteger (L, x);
    lua_pushinteger (L, y);
    return 2;
}

static int lcurses_size (lua_State *L) {
    int y, x;
    getmaxyx(stdscr, y, x);
    lua_pushinteger (L, x);
    lua_pushinteger (L, y);
    return 2;
}

static int lcurses_locate (lua_State *L) {
    int y, x;
    x = luaL_checkinteger (L, 1);
    y = luaL_checkinteger (L, 2);
    move(y, x);
    return 0;
}


static const luaL_Reg lcurses_lib[] = {
  {"printw",     lcurses_printw},
  {"getch",     lcurses_getch},
  {"echo",     lcurses_echo},
  {"keystr",     lcurses_keystr},
  {"attributes", lcurses_attributes},
  {"addch", lcurses_addch},
  {"pos", lcurses_pos},
  {"size", lcurses_size},
  {"locate", lcurses_locate},
  {NULL, NULL}
};

LUALIB_API int luaopen_curses (lua_State *L) {
  luaL_register(L, LCURSES_LIBNAME, lcurses_lib);
  return 1;
}


///////////////////////////////////////////////////////////////////

#define case_keycode_string(B, CODE) case KEY_##CODE: luaL_addstring (B, #CODE); break;
#define case_keycode_string_r(B, CODE) case CODE: luaL_addstring (B, #CODE); break;
#ifndef uchar
#define uchar(c)        ((unsigned char)(c))
#endif

static void keycode2buffer (luaL_Buffer *b, int ch) {

  switch (ch) {
    case_keycode_string(b, BREAK)
    case_keycode_string(b, DOWN)
    case_keycode_string(b, UP)
    case_keycode_string(b, LEFT)
    case_keycode_string(b, RIGHT)
    case_keycode_string(b, HOME)
    case_keycode_string(b, BACKSPACE)
    case_keycode_string(b, F0)
    case_keycode_string(b, DL)
    case_keycode_string(b, IL)
    case_keycode_string(b, DC)
    case_keycode_string(b, IC)
    case_keycode_string(b, EIC)
    case_keycode_string(b, CLEAR)
    case_keycode_string(b, EOS)
    case_keycode_string(b, EOL)
    case_keycode_string(b, SF)
    case_keycode_string(b, SR)
    case_keycode_string(b, NPAGE)
    case_keycode_string(b, PPAGE)
    case_keycode_string(b, STAB)
    case_keycode_string(b, CTAB)
    case_keycode_string(b, CATAB)
    case_keycode_string(b, ENTER)
    case_keycode_string(b, SRESET)
    case_keycode_string(b, RESET)
    case_keycode_string(b, PRINT)
    case_keycode_string(b, LL)
    case_keycode_string(b, ABORT)
    case_keycode_string(b, SHELP)
    case_keycode_string(b, LHELP)
    case_keycode_string(b, BTAB)
    case_keycode_string(b, BEG)
    case_keycode_string(b, CANCEL)
    case_keycode_string(b, CLOSE)
    case_keycode_string(b, COMMAND)
    case_keycode_string(b, COPY)
    case_keycode_string(b, CREATE)
    case_keycode_string(b, END)
    case_keycode_string(b, EXIT)
    case_keycode_string(b, FIND)
    case_keycode_string(b, HELP)
    case_keycode_string(b, MARK)
    case_keycode_string(b, MESSAGE)
    case_keycode_string(b, MOVE)
    case_keycode_string(b, NEXT)
    case_keycode_string(b, OPEN)
    case_keycode_string(b, OPTIONS)
    case_keycode_string(b, PREVIOUS)
    case_keycode_string(b, REDO)
    case_keycode_string(b, REFERENCE)
    case_keycode_string(b, REFRESH)
    case_keycode_string(b, REPLACE)
    case_keycode_string(b, RESTART)
    case_keycode_string(b, RESUME)
    case_keycode_string(b, SAVE)
    case_keycode_string(b, SBEG)
    case_keycode_string(b, SCANCEL)
    case_keycode_string(b, SCOMMAND)
    case_keycode_string(b, SCOPY)
    case_keycode_string(b, SCREATE)
    case_keycode_string(b, SDC)
    case_keycode_string(b, SDL)
    case_keycode_string(b, SELECT)
    case_keycode_string(b, SEND)
    case_keycode_string(b, SEOL)
    case_keycode_string(b, SEXIT)
    case_keycode_string(b, SFIND)
    case_keycode_string(b, SHOME)
    case_keycode_string(b, SIC)
    case_keycode_string(b, SLEFT)
    case_keycode_string(b, SMESSAGE)
    case_keycode_string(b, SMOVE)
    case_keycode_string(b, SNEXT)
    case_keycode_string(b, SOPTIONS)
    case_keycode_string(b, SPREVIOUS)
    case_keycode_string(b, SPRINT)
    case_keycode_string(b, SREDO)
    case_keycode_string(b, SREPLACE)
    case_keycode_string(b, SRIGHT)
    case_keycode_string(b, SRSUME)
    case_keycode_string(b, SSAVE)
    case_keycode_string(b, SSUSPEND)
    case_keycode_string(b, SUNDO)
    case_keycode_string(b, SUSPEND)
    case_keycode_string(b, UNDO)
    case_keycode_string_r(b, ALT_0)
    case_keycode_string_r(b, ALT_1)
    case_keycode_string_r(b, ALT_2)
    case_keycode_string_r(b, ALT_3)
    case_keycode_string_r(b, ALT_4)
    case_keycode_string_r(b, ALT_5)
    case_keycode_string_r(b, ALT_6)
    case_keycode_string_r(b, ALT_7)
    case_keycode_string_r(b, ALT_8)
    case_keycode_string_r(b, ALT_9)
    case_keycode_string_r(b, ALT_A)
    case_keycode_string_r(b, ALT_B)
    case_keycode_string_r(b, ALT_C)
    case_keycode_string_r(b, ALT_D)
    case_keycode_string_r(b, ALT_E)
    case_keycode_string_r(b, ALT_F)
    case_keycode_string_r(b, ALT_G)
    case_keycode_string_r(b, ALT_H)
    case_keycode_string_r(b, ALT_I)
    case_keycode_string_r(b, ALT_J)
    case_keycode_string_r(b, ALT_K)
    case_keycode_string_r(b, ALT_L)
    case_keycode_string_r(b, ALT_M)
    case_keycode_string_r(b, ALT_N)
    case_keycode_string_r(b, ALT_O)
    case_keycode_string_r(b, ALT_P)
    case_keycode_string_r(b, ALT_Q)
    case_keycode_string_r(b, ALT_R)
    case_keycode_string_r(b, ALT_S)
    case_keycode_string_r(b, ALT_T)
    case_keycode_string_r(b, ALT_U)
    case_keycode_string_r(b, ALT_V)
    case_keycode_string_r(b, ALT_W)
    case_keycode_string_r(b, ALT_X)
    case_keycode_string_r(b, ALT_Y)
    case_keycode_string_r(b, ALT_Z)
    case_keycode_string_r(b, CTL_LEFT)
    case_keycode_string_r(b, CTL_RIGHT)
    case_keycode_string_r(b, CTL_PGUP)
    case_keycode_string_r(b, CTL_PGDN)
    case_keycode_string_r(b, CTL_HOME)
    case_keycode_string_r(b, CTL_END)
    case_keycode_string(b, A1)
    case_keycode_string(b, A2)
    case_keycode_string(b, A3)
    case_keycode_string(b, B1)
    case_keycode_string(b, B2)
    case_keycode_string(b, B3)
    case_keycode_string(b, C1)
    case_keycode_string(b, C2)
    case_keycode_string(b, C3)
    case_keycode_string_r(b, PADSLASH)
    case_keycode_string_r(b, PADENTER)
    case_keycode_string_r(b, CTL_PADENTER)
    case_keycode_string_r(b, ALT_PADENTER)
    case_keycode_string_r(b, PADSTOP)
    case_keycode_string_r(b, PADSTAR)
    case_keycode_string_r(b, PADMINUS)
    case_keycode_string_r(b, PADPLUS)
    case_keycode_string_r(b, CTL_PADSTOP)
    case_keycode_string_r(b, CTL_PADCENTER)
    case_keycode_string_r(b, CTL_PADPLUS)
    case_keycode_string_r(b, CTL_PADMINUS)
    case_keycode_string_r(b, CTL_PADSLASH)
    case_keycode_string_r(b, CTL_PADSTAR)
    case_keycode_string_r(b, ALT_PADPLUS)
    case_keycode_string_r(b, ALT_PADMINUS)
    case_keycode_string_r(b, ALT_PADSLASH)
    case_keycode_string_r(b, ALT_PADSTAR)
    case_keycode_string_r(b, ALT_PADSTOP)
    case_keycode_string_r(b, CTL_INS)
    case_keycode_string_r(b, ALT_DEL)
    case_keycode_string_r(b, ALT_INS)
    case_keycode_string_r(b, CTL_UP)
    case_keycode_string_r(b, CTL_DOWN)
    case_keycode_string_r(b, CTL_TAB)
    case_keycode_string_r(b, ALT_TAB)
    case_keycode_string_r(b, ALT_MINUS)
    case_keycode_string_r(b, ALT_EQUAL)
    case_keycode_string_r(b, ALT_HOME)
    case_keycode_string_r(b, ALT_PGUP)
    case_keycode_string_r(b, ALT_PGDN)
    case_keycode_string_r(b, ALT_END)
    case_keycode_string_r(b, ALT_UP)
    case_keycode_string_r(b, ALT_DOWN)
    case_keycode_string_r(b, ALT_RIGHT)
    case_keycode_string_r(b, ALT_LEFT)
    case_keycode_string_r(b, ALT_ENTER)
    case_keycode_string_r(b, ALT_ESC)
    case_keycode_string_r(b, ALT_BQUOTE)
    case_keycode_string_r(b, ALT_LBRACKET)
    case_keycode_string_r(b, ALT_RBRACKET)
    case_keycode_string_r(b, ALT_SEMICOLON)
    case_keycode_string_r(b, ALT_FQUOTE)
    case_keycode_string_r(b, ALT_COMMA)
    case_keycode_string_r(b, ALT_STOP)
    case_keycode_string_r(b, ALT_FSLASH)
    case_keycode_string_r(b, ALT_BKSP)
    case_keycode_string_r(b, CTL_BKSP)
    case_keycode_string_r(b, PAD0)
    case_keycode_string_r(b, CTL_PAD0)
    case_keycode_string_r(b, CTL_PAD1)
    case_keycode_string_r(b, CTL_PAD2)
    case_keycode_string_r(b, CTL_PAD3)
    case_keycode_string_r(b, CTL_PAD4)
    case_keycode_string_r(b, CTL_PAD5)
    case_keycode_string_r(b, CTL_PAD6)
    case_keycode_string_r(b, CTL_PAD7)
    case_keycode_string_r(b, CTL_PAD8)
    case_keycode_string_r(b, CTL_PAD9)
    case_keycode_string_r(b, ALT_PAD0)
    case_keycode_string_r(b, ALT_PAD1)
    case_keycode_string_r(b, ALT_PAD2)
    case_keycode_string_r(b, ALT_PAD3)
    case_keycode_string_r(b, ALT_PAD4)
    case_keycode_string_r(b, ALT_PAD5)
    case_keycode_string_r(b, ALT_PAD6)
    case_keycode_string_r(b, ALT_PAD7)
    case_keycode_string_r(b, ALT_PAD8)
    case_keycode_string_r(b, ALT_PAD9)
    case_keycode_string_r(b, CTL_DEL)
    case_keycode_string_r(b, ALT_BSLASH)
    case_keycode_string_r(b, CTL_ENTER)
    case_keycode_string_r(b, SHF_PADENTER)
    case_keycode_string_r(b, SHF_PADSLASH)
    case_keycode_string_r(b, SHF_PADSTAR)
    case_keycode_string_r(b, SHF_PADPLUS)
    case_keycode_string_r(b, SHF_PADMINUS)
    case_keycode_string_r(b, SHF_UP)
    case_keycode_string_r(b, SHF_DOWN)
    case_keycode_string_r(b, SHF_IC)
    case_keycode_string_r(b, SHF_DC)
    case_keycode_string(b, MOUSE)
    case_keycode_string(b, SHIFT_L)
    case_keycode_string(b, SHIFT_R)
    case_keycode_string(b, CONTROL_L)
    case_keycode_string(b, CONTROL_R)
    case_keycode_string(b, ALT_L)
    case_keycode_string(b, ALT_R)
    case_keycode_string(b, RESIZE)
    case_keycode_string(b, SUP)
    case_keycode_string(b, SDOWN)

    default:
      if (isprint(ch) || iscntrl(ch))
      {
        luaL_addchar(b, uchar(ch));
      }
      break;
  }
}

#undef uchar
#undef case_keycode_string

///////////////////////////////////////////////////////////////////