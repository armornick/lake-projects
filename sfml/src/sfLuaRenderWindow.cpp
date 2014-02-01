#include "sflua.hpp"

// allocator
static sf::RenderWindow* window_new (lua_State *L)
{
	// variable declarations
	int width = 800, height = 600;
	const char *title = "untitled window";
	// arguments: (number, number, string)
	if (lua_isnumber(L, 1)) {
		width = lua_tointeger(L, 1);
		height = lua_tointeger(L, 2);
		title = lua_tostring(L, 3);
	// arguments: (table, string)
	} else if (lua_istable(L, 1)) {
		lua_getfield(L, 1, "width");
		// {number, number}
		if (lua_isnil(L, -1)) {
			lua_rawgeti (L, 1, 1);
			width = lua_tointeger(L, -1);
			lua_rawgeti (L, 1, 2);
			height = lua_tointeger(L, -1);
			lua_pop(L, 3);
		// {width = number, height = number}
		} else {
			width = lua_tointeger(L, -1);
			lua_getfield(L, 1, "height");
			height = lua_tointeger(L, -1);
			lua_pop(L, 2);
		}
		title = lua_tostring(L, 2);
	}
	// create and return RenderWindow
	sf::RenderWindow*window = new sf::RenderWindow(sf::VideoMode(width, height), title);
	window->setFramerateLimit(60);
	return window;
}

static int window_isopen(lua_State *L) 
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	lua_pushboolean (L, window->isOpen());
	return 1;
}


static void push_event(lua_State *L, sf::Event& event)
{
	lua_newtable(L);
	
	switch (event.type) {
		case sf::Event::Closed:
			luaU_setfield<const char*>(L, -1, "type", "Closed");
			break;
	
		case sf::Event::Resized:
			luaU_setfield<const char*>(L, -1, "type", "Resized");
			luaU_setfield<int>(L, -1, "width", event.size.width);
			luaU_setfield<int>(L, -1, "height", event.size.height);
			break;
	
		case sf::Event::LostFocus:
			luaU_setfield<const char*>(L, -1, "type", "LostFocus");
			break;
		
		case sf::Event::GainedFocus:
			luaU_setfield<const char*>(L, -1, "type", "GainedFocus");
			break;
		
		case sf::Event::KeyPressed:
			luaU_setfield<const char*>(L, -1, "type", "KeyPressed");
			luaU_setfield<const char*>(L, -1, "key", tostring(event.key.code));
			luaU_setfield<bool>(L, -1, "system", event.key.system);
			luaU_setfield<bool>(L, -1, "control", event.key.control);
			luaU_setfield<bool>(L, -1, "alt", event.key.alt);
			luaU_setfield<bool>(L, -1, "shift", event.key.shift);
			break;
			
		case sf::Event::KeyReleased:
			luaU_setfield<const char*>(L, -1, "type", "KeyReleased");
			luaU_setfield<const char*>(L, -1, "key", tostring(event.key.code));
			luaU_setfield<bool>(L, -1, "system", event.key.system);
			luaU_setfield<bool>(L, -1, "control", event.key.control);
			luaU_setfield<bool>(L, -1, "alt", event.key.alt);
			luaU_setfield<bool>(L, -1, "shift", event.key.shift);
			break;
		
		case sf::Event::MouseWheelMoved:
			luaU_setfield<const char*>(L, -1, "type", "MouseWheelMoved");
			luaU_setfield<int>(L, -1, "delta", event.mouseWheel.delta);
			luaU_setfield<int>(L, -1, "x", event.mouseWheel.x);
			luaU_setfield<int>(L, -1, "y", event.mouseWheel.y);
			break;
		
		case sf::Event::MouseButtonPressed:
			luaU_setfield<const char*>(L, -1, "type", "MouseButtonPressed");
			luaU_setfield<const char*>(L, -1, "button", tostring(event.mouseButton.button));
			luaU_setfield<int>(L, -1, "x", event.mouseButton.x);
			luaU_setfield<int>(L, -1, "y", event.mouseButton.y);
			break;
		
		case sf::Event::MouseButtonReleased:
			luaU_setfield<const char*>(L, -1, "type", "MouseButtonReleased");
			luaU_setfield<const char*>(L, -1, "button", tostring(event.mouseButton.button));
			luaU_setfield<int>(L, -1, "x", event.mouseButton.x);
			luaU_setfield<int>(L, -1, "y", event.mouseButton.y);
			break;
		
		case sf::Event::MouseMoved:
			luaU_setfield<const char*>(L, -1, "type", "MouseMoved");
			luaU_setfield<int>(L, -1, "x", event.mouseMove.x);
			luaU_setfield<int>(L, -1, "y", event.mouseMove.y);
			break;
		
		case sf::Event::MouseEntered:
			luaU_setfield<const char*>(L, -1, "type", "MouseEntered");
			break;
		
		case sf::Event::MouseLeft:
			luaU_setfield<const char*>(L, -1, "type", "MouseLeft");
			break;
		
		default:
			luaU_setfield<const char*>(L, -1, "type", "Unknown");
			break;
	}
}

static int window_poll(lua_State *L) 
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	sf::Event event;
	if (window->pollEvent(event)) {
		push_event(L, event);
	} else {
		lua_pushboolean(L, 0 );
	}
	if (lua_istable(L, -1) || lua_isboolean(L, -1)) {
		return 1;
	}
	return luaL_error(L, "could not poll RenderWindow");
}

static int window_close(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	window->close();
	return 0;
}

static int window_position(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	if (lua_isnone(L, 2)) {
		sf::Vector2i pos = window->getPosition();
		lua_pushinteger(L, pos.x);
		lua_pushinteger(L, pos.y);
		return 2;
	} else {
		int x = 0, y = 0;
		if (lua_isnumber(L, 2)) {
			x = luaL_checkint(L, 2);
			y = luaL_checkint(L, 3);
		} else if (lua_istable(L, 2)) {
			x = luaU_getfield<int>(L, 2, "x");
			y = luaU_getfield<int>(L, 2, "y");
		}
		window->setPosition(sf::Vector2i(x, y));
		return 0;
	}
}

static int window_size(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	if (lua_isnone(L, 2)) {
		sf::Vector2u pos = window->getSize();
		lua_pushinteger(L, pos.x);
		lua_pushinteger(L, pos.y);
		return 2;
	} else {
		unsigned int x = 0, y = 0;
		if (lua_isnumber(L, 1)) {
			x = luaL_checkint(L, 2);
			y = luaL_checkint(L, 3);
		} else if (lua_istable(L, 1)) {
			x = luaU_getfield<int>(L, 2, "x");
			y = luaU_getfield<int>(L, 2, "y");
		}
		window->setSize(sf::Vector2u(x, y));
		return 0;
	}
}

static int window_title(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	const char *title = const_cast<const char*>(luaL_checkstring(L, 2));
	window->setTitle(title);
	return 0;
}

static int window_clear(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	sf::Color color = luaU_check<sf::Color>(L, 2);
	window->clear(color);
	return 0;
}

static int window_display(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);
	window->display();
	return 0;
}

static int window_draw(lua_State *L)
{
	sf::RenderWindow *window = luaW_check<sf::RenderWindow>(L, 1);

	if (luaW_is<sf::Shape>(L, 2)) {
		sf::Shape *shape = luaW_check<sf::Shape>(L, 2);
		window->draw(*shape);
	}

	return 0;
}

static luaL_Reg RenderWindow_metatable[] =
{
	{ "is_open", window_isopen },
	{ "poll", window_poll },
	{ "close", window_close },
	{ "position", window_position },
	{ "size", window_size },
	{ "title", window_title },
	{ "clear", window_clear },
	{ "display", window_display },
	{ "draw", window_draw },
	{ NULL, NULL }
};


int luaopen_RenderWindow(lua_State* L)
{
	luaW_register<sf::RenderWindow>(L,
        "RenderWindow",
        NULL,
        RenderWindow_metatable,
        window_new // If your class has a default constructor you can omit this argument,
                        // LuaWrapper will generate a default allocator for you.
    );
    return 1;
}