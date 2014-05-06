#include <iostream>
#include <string>

int main(int argc, char const *argv[])
{
	std::string inputs;

	while (1) {
		std::cout << "$ ";
		std::getline(std::cin, inputs);

		if (inputs == "") break;

		std::cout << ">>> " << inputs << std::endl;
	}

	return 0;
}