#include <cstring>
#include <cctype>
#include "sflua.hpp"

const char* tostring (sf::Keyboard::Key keycode)
{
	switch(keycode) {
	case sf::Keyboard::Unknown:
		return  "Unknown";
		break;
	case sf::Keyboard::A:
		return  "A";
		break;
	case sf::Keyboard::B:
		return  "B";
		break;
	case sf::Keyboard::C:
		return  "C";
		break;
	case sf::Keyboard::D:
		return  "D";
		break;
	case sf::Keyboard::E:
		return  "E";
		break;
	case sf::Keyboard::F:
		return  "F";
		break;
	case sf::Keyboard::G:
		return  "G";
		break;
	case sf::Keyboard::H:
		return  "H";
		break;
	case sf::Keyboard::I:
		return  "I";
		break;
	case sf::Keyboard::J:
		return  "J";
		break;
	case sf::Keyboard::K:
		return  "K";
		break;
	case sf::Keyboard::L:
		return  "L";
		break;
	case sf::Keyboard::M:
		return  "M";
		break;
	case sf::Keyboard::N:
		return  "N";
		break;
	case sf::Keyboard::O:
		return  "O";
		break;
	case sf::Keyboard::P:
		return  "P";
		break;
	case sf::Keyboard::Q:
		return  "Q";
		break;
	case sf::Keyboard::R:
		return  "R";
		break;
	case sf::Keyboard::S:
		return  "S";
		break;
	case sf::Keyboard::T:
		return  "T";
		break;
	case sf::Keyboard::U:
		return  "U";
		break;
	case sf::Keyboard::V:
		return  "V";
		break;
	case sf::Keyboard::W:
		return  "W";
		break;
	case sf::Keyboard::X:
		return  "X";
		break;
	case sf::Keyboard::Y:
		return  "Y";
		break;
	case sf::Keyboard::Z:
		return  "Z";
		break;
	case sf::Keyboard::Num0:
		return  "Num0";
		break;
	case sf::Keyboard::Num1:
		return  "Num1";
		break;
	case sf::Keyboard::Num2:
		return  "Num2";
		break;
	case sf::Keyboard::Num3:
		return  "Num3";
		break;
	case sf::Keyboard::Num4:
		return  "Num4";
		break;
	case sf::Keyboard::Num5:
		return  "Num5";
		break;
	case sf::Keyboard::Num6:
		return  "Num6";
		break;
	case sf::Keyboard::Num7:
		return  "Num7";
		break;
	case sf::Keyboard::Num8:
		return  "Num8";
		break;
	case sf::Keyboard::Num9:
		return  "Num9";
		break;
	case sf::Keyboard::Escape:
		return  "Escape";
		break;
	case sf::Keyboard::LControl:
		return  "LControl";
		break;
	case sf::Keyboard::LShift:
		return  "LShift";
		break;
	case sf::Keyboard::LAlt:
		return  "LAlt";
		break;
	case sf::Keyboard::LSystem:
		return  "LSystem";
		break;
	case sf::Keyboard::RControl:
		return  "RControl";
		break;
	case sf::Keyboard::RShift:
		return  "RShift";
		break;
	case sf::Keyboard::RAlt:
		return  "RAlt";
		break;
	case sf::Keyboard::RSystem:
		return  "RSystem";
		break;
	case sf::Keyboard::Menu:
		return  "Menu";
		break;
	case sf::Keyboard::LBracket:
		return  "LBracket";
		break;
	case sf::Keyboard::RBracket:
		return  "RBracket";
		break;
	case sf::Keyboard::SemiColon:
		return  "SemiColon";
		break;
	case sf::Keyboard::Comma:
		return  "Comma";
		break;
	case sf::Keyboard::Period:
		return  "Period";
		break;
	case sf::Keyboard::Quote:
		return  "Quote";
		break;
	case sf::Keyboard::Slash:
		return  "Slash";
		break;
	case sf::Keyboard::BackSlash:
		return  "BackSlash";
		break;
	case sf::Keyboard::Tilde:
		return  "Tilde";
		break;
	case sf::Keyboard::Equal:
		return  "Equal";
		break;
	case sf::Keyboard::Dash:
		return  "Dash";
		break;
	case sf::Keyboard::Space:
		return  "Space";
		break;
	case sf::Keyboard::Return:
		return  "Return";
		break;
	case sf::Keyboard::BackSpace:
		return  "BackSpace";
		break;
	case sf::Keyboard::Tab:
		return  "Tab";
		break;
	case sf::Keyboard::PageUp:
		return  "PageUp";
		break;
	case sf::Keyboard::PageDown:
		return  "PageDown";
		break;
	case sf::Keyboard::End:
		return  "End";
		break;
	case sf::Keyboard::Home:
		return  "Home";
		break;
	case sf::Keyboard::Insert:
		return  "Insert";
		break;
	case sf::Keyboard::Delete:
		return  "Delete";
		break;
	case sf::Keyboard::Add:
		return  "Add";
		break;
	case sf::Keyboard::Subtract:
		return  "Subtract";
		break;
	case sf::Keyboard::Multiply:
		return  "Multiply";
		break;
	case sf::Keyboard::Divide:
		return  "Divide";
		break;
	case sf::Keyboard::Left:
		return  "Left";
		break;
	case sf::Keyboard::Right:
		return  "Right";
		break;
	case sf::Keyboard::Up:
		return  "Up";
		break;
	case sf::Keyboard::Down:
		return  "Down";
		break;
	case sf::Keyboard::Numpad0:
		return  "Numpad0";
		break;
	case sf::Keyboard::Numpad1:
		return  "Numpad1";
		break;
	case sf::Keyboard::Numpad2:
		return  "Numpad2";
		break;
	case sf::Keyboard::Numpad3:
		return  "Numpad3";
		break;
	case sf::Keyboard::Numpad4:
		return  "Numpad4";
		break;
	case sf::Keyboard::Numpad5:
		return  "Numpad5";
		break;
	case sf::Keyboard::Numpad6:
		return  "Numpad6";
		break;
	case sf::Keyboard::Numpad7:
		return  "Numpad7";
		break;
	case sf::Keyboard::Numpad8:
		return  "Numpad8";
		break;
	case sf::Keyboard::Numpad9:
		return  "Numpad9";
		break;
	case sf::Keyboard::F1:
		return  "F1";
		break;
	case sf::Keyboard::F2:
		return  "F2";
		break;
	case sf::Keyboard::F3:
		return  "F3";
		break;
	case sf::Keyboard::F4:
		return  "F4";
		break;
	case sf::Keyboard::F5:
		return  "F5";
		break;
	case sf::Keyboard::F6:
		return  "F6";
		break;
	case sf::Keyboard::F7:
		return  "F7";
		break;
	case sf::Keyboard::F8:
		return  "F8";
		break;
	case sf::Keyboard::F9:
		return  "F9";
		break;
	case sf::Keyboard::F10:
		return  "F10";
		break;
	case sf::Keyboard::F11:
		return  "F11";
		break;
	case sf::Keyboard::F12:
		return  "F12";
		break;
	case sf::Keyboard::F13:
		return  "F13";
		break;
	case sf::Keyboard::F14:
		return  "F14";
		break;
	case sf::Keyboard::F15:
		return  "F15";
		break;
	case sf::Keyboard::Pause:
		return  "Pause";
		break;
	default:
		return  "Unknown";
	}
}

const char* tostring (sf::Mouse::Button mousebutton)
{
	switch (mousebutton) {
	case sf::Mouse::Left:
		return  "Left";
		break;
	case sf::Mouse::Right:
		return  "Right";
		break;
	case sf::Mouse::Middle:
		return  "Middle";
		break;
	case sf::Mouse::XButton1:
		return  "XButton1";
		break;
	case sf::Mouse::XButton2:
		return  "XButton2";
		break;
	default:
		return  "Unknown";
	}
}

sf::Color to_color(lua_State* L, int index)
{
	if (lua_isstring(L, index)) {
		const char* color = lua_tostring(L, index);
		if (!std::strcmp(color, "black")) {
			return sf::Color::Black;
		} else if (!std::strcmp(color, "white")) {
			return sf::Color::White;
		} else if (!std::strcmp(color, "red")) {
			return sf::Color::Red;
		} else if (!std::strcmp(color, "green")) {
			return sf::Color::Green;
		} else if (!std::strcmp(color, "blue")) {
			return sf::Color::Blue;
		} else if (!std::strcmp(color, "yellow")) {
			return sf::Color::Yellow;
		} else if (!std::strcmp(color, "magenta")) {
			return sf::Color::Magenta;
		} else if (!std::strcmp(color, "cyan")) {
			return sf::Color::Cyan;
		} else if (!std::strcmp(color, "transparent")) {
			return sf::Color::Transparent;
		}
		return sf::Color();
	} else {
		return sf::Color(
			luaU_getfield<unsigned int>(L, index, "r"),
			luaU_getfield<unsigned int>(L, index, "g"),
			luaU_getfield<unsigned int>(L, index, "b"),
			luaU_optfield<unsigned int>(L, index, "a", 255)
		);
	}
	return sf::Color();
}