#include <string>
#include <vector>
#include <iostream>
#include <iomanip>

#include "portability/file_system.hpp"

using std::vector; using std::string;


int main(int argc, char const *argv[])
{
	int filecount = 0, dircount = 0;
	vector<string> files = stlplus::folder_all(".");

	for (vector<string>::iterator i = files.begin(); i != files.end(); ++i)
	{
		if (stlplus::is_file(*i))
		{
			filecount++;
			std::cout << std::setw(20) << *i << " (" << stlplus::file_size(*i) << " bytes)" << std::endl;
		}
		else if (stlplus::is_folder(*i))
		{
			dircount++;
			std::cout << std::setw(20) << *i << " (directory)" << std::endl;
		}
	}

	std::cout << std::endl << '\t' << filecount << " files" << std::endl;
	std::cout << '\t' << dircount << " directories" << std::endl;

	return 0;
}