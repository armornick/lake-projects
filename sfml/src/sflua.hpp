#ifndef _SFLUA_HPP_
#define _SFLUA_HPP_

// header imports
extern "C"
{
#include "lua.h"
#include <lualib.h>
#include "lauxlib.h"
}
#include "luawrapper.hpp"
#include "luawrapperutil.hpp"

#include <SFML/Graphics.hpp>

// lua utility functions
sf::Color to_color(lua_State* L, int index);

#include "sflua_types.hpp"

// utility functions
const char* tostring (sf::Keyboard::Key keycode);
const char* tostring (sf::Mouse::Button mousebutton);

// lua register functions
int luaopen_RenderWindow(lua_State* L);
int luaopen_Transformable(lua_State* L);
int luaopen_Shape(lua_State* L);


#endif // _SFLUA_HPP_