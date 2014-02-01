#include "sflua.hpp"

static int shape_color(lua_State *L)
{
	sf::Shape *shape = luaW_check<sf::Shape>(L, 1);
	sf::Color color = luaU_check<sf::Color>(L, 2);
	shape->setFillColor(color);
	return 0;
}

static int shape_outline(lua_State *L)
{
	sf::Shape *shape = luaW_check<sf::Shape>(L, 1);
	float thickness = luaU_opt<float>(L, 2, 0);
	sf::Color color = luaU_opt<sf::Color>(L, 3);
	shape->setOutlineThickness(thickness);
	shape->setOutlineColor(color);
	return 0;
}

static int shape_outline_thickness(lua_State *L)
{
	sf::Shape *shape = luaW_check<sf::Shape>(L, 1);
	float thickness = luaU_opt<float>(L, 2, 0);
	shape->setOutlineThickness(thickness);
	return 0;
}

static int shape_outline_color(lua_State *L)
{
	sf::Shape *shape = luaW_check<sf::Shape>(L, 1);
	sf::Color color = luaU_opt<sf::Color>(L, 2);
	shape->setOutlineColor(color);
	return 0;
}

static luaL_Reg Shape_metatable[] =
{
	{ "color", shape_color },
	{ "outline", shape_outline },
	{ "outline_thickness", shape_outline_thickness },
	{ "outline_color", shape_outline_color },
	{ NULL, NULL }
};


static sf::RectangleShape* rectangleshape_new(lua_State *L)
{
	float width = luaU_check<float>(L, 1);
	float height = luaU_opt<float>(L, 2, 0);
	return new sf::RectangleShape (sf::Vector2f(width, height));
}

static sf::CircleShape* circleshape_new(lua_State *L)
{
	float radius = luaU_check<float>(L, 1);
	float points = luaU_opt<float>(L, 2, 30);
	return new sf::CircleShape (radius, points);
}

static int circleshape_radius(lua_State* L)
{
	sf::CircleShape *circle = luaW_check<sf::CircleShape>(L, 1);
	if (lua_isnumber(L, 2)) {
		float radius = luaU_check<float>(L, 2);
		circle->setRadius(radius);
		return 0;
	} else {
		float radius = circle->getRadius();
		luaU_push<float>(L, radius);
		return 1;
	}
}

static luaL_Reg CircleShape_metatable[] =
{
	{ "radius", circleshape_radius },
	{ NULL, NULL }
};

int luaopen_Shape(lua_State* L)
{
	lua_newtable(L);
	
	luaW_register<sf::Shape>(L,
        "Shape",
        NULL,
        Shape_metatable,
        NULL  // abstract class: no constructor
    );
	luaW_extend<sf::Shape, sf::Transformable>(L);
	lua_setfield(L, -2, "Shape");
	
	luaW_register<sf::RectangleShape>(L,
        "RectangleShape",
        NULL,
        NULL,
        rectangleshape_new 
    );
	luaW_extend<sf::RectangleShape, sf::Shape>(L);
	lua_setfield(L, -2, "RectangleShape");
	
	luaW_register<sf::CircleShape>(L,
        "CircleShape",
        NULL,
        CircleShape_metatable,
        circleshape_new 
    );
	luaW_extend<sf::CircleShape, sf::Shape>(L);
	lua_setfield(L, -2, "CircleShape");
	
    return 1;
}