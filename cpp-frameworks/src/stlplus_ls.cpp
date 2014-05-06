#include <string>
#include <vector>
#include <cstdio>

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
			std::printf("%20s  (%d bytes)\n", i->c_str(), stlplus::file_size(*i));
		}
		else if (stlplus::is_folder(*i))
		{
			dircount++;
			std::printf("%20s  (directory)\n", i->c_str());
		}
	}

	std::printf("\n\t\t%d files\n", filecount);
	std::printf("\t\t%d directories\n", dircount);

	return 0;
}