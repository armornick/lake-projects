#include "sflua.hpp"

static int transformable_position(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	if (lua_isnumber(L, 2)) {
		float x = luaU_check<float>(L, 2);
		float y = luaU_check<float>(L, 3);
		entity->setPosition(x, y);
	} else {
		sf::Vector2f position = entity->getPosition();
		luaU_push<float>(L, position.x);
		luaU_push<float>(L, position.y);
		return 2;
	}
}

static int transformable_move(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	float dx = luaU_check<float>(L, 2);
	float dy = luaU_check<float>(L, 3);
	entity->move(dx, dy);
}

static int transformable_rotation(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	if (lua_isnumber(L, 2)) {
		float rot = luaU_check<float>(L, 2);
		entity->setRotation(rot);
	} else {
		float rotation = entity->getRotation();
		luaU_push<float>(L, rotation);
		return 1;
	}
}

static int transformable_rotate(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	float rot = luaU_check<float>(L, 2);
	entity->rotate(rot);
}

static int transformable_scale(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	if (lua_isnumber(L, 2)) {
		float x = luaU_check<float>(L, 2);
		float y = luaU_check<float>(L, 3);
		entity->setScale(x, y);
	} else {
		sf::Vector2f scale = entity->getScale();
		luaU_push<float>(L, scale.x);
		luaU_push<float>(L, scale.y);
		return 2;
	}
}

// dscale = delta-scale (relative to current scale)
static int transformable_dscale(lua_State* L)
{
	sf::Transformable *entity = luaW_check<sf::Transformable>(L, 1);
	float dx = luaU_check<float>(L, 2);
	float dy = luaU_check<float>(L, 3);
	entity->scale(dx, dy);
}

static luaL_Reg Transformable_metatable[] =
{
	{ "position", transformable_position },
	{ "move", transformable_move },
	{ "rotation", transformable_rotation },
	{ "rotate", transformable_rotate },
	{ "scale", transformable_scale },
	{ "dscale", transformable_dscale },
	{ NULL, NULL }
};


int luaopen_Transformable(lua_State* L)
{
	luaW_register<sf::Transformable>(L,
        "Transformable",
        NULL,
        Transformable_metatable,
        NULL  // abstract class: no constructor
    );
    return 1;
}