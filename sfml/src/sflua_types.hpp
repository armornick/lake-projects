#ifndef _SFLUA_TYPES_HPP_
#define _SFLUA_TYPES_HPP_

template<>
struct luaU_Impl<sf::Color>
{
    static sf::Color luaU_check(lua_State* L, int index)
    {
        return to_color(L, index);
    }

    static sf::Color luaU_to(lua_State* L, int index )
    {
		return to_color(L, index);
    }

    static void luaU_push (lua_State* L, const sf::Color& val)
    {
        lua_newtable(L);
        luaU_setfield<unsigned int>(L, -1, "r", val.r);
		luaU_setfield<unsigned int>(L, -1, "g", val.g);
		luaU_setfield<unsigned int>(L, -1, "b", val.b);
		luaU_setfield<unsigned int>(L, -1, "a", val.a);
    }
};


#endif // _SFLUA_TYPES_HPP_