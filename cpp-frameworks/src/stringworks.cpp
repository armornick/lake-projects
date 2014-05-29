#include <string>
#include <iostream>
#include "strings/string_utilities.hpp"

inline void print(const char* title, const std::string& outputs) 
{
	std::cout << title << outputs << std::endl;
}

int main(int argc, char const *argv[]) 
{
	std::string inputs;
	std::cout << ">> ";
	std::getline(std::cin, inputs);

	print("trimmed: ", stlplus::trim(inputs));

	print("lowercase: ", stlplus::lowercase(inputs));
	print("uppercase: ", stlplus::uppercase(inputs));

	const unsigned width = 30;
	print("left aligned: ", stlplus::pad(inputs, stlplus::align_left, width, '-'));
	print("right aligned: ", stlplus::pad(inputs, stlplus::align_right, width, '-'));
	print("center aligned: ", stlplus::pad(inputs, stlplus::align_centre, width, '-'));

	std::cout << "press any key to end the program";
	std::getline(std::cin, inputs);

	return 0;
}