#include <string>
#include <vector>
#include <iostream>
#include <iomanip>

#include "platformstl/filesystem/filesystem_traits.hpp"
#include "platformstl/filesystem/readdir_sequence.hpp"

using std::vector; using std::string;
using platformstl::readdir_sequence;
using platformstl::filesystem_traits;


int main(int argc, char const *argv[])
{
	int filecount = 0, dircount = 0;
	readdir_sequence dir(".", readdir_sequence::files|readdir_sequence::directories);

	for (readdir_sequence::const_iterator i = dir.begin(); i != dir.end(); ++i)
	{
		if (filesystem_traits::is_file(*i))
		{
			filecount++;
			std::cout << std::setw(20) << *i << " (" << stlplus::file_size(*i) << " bytes)" << std::endl;
		}
		else if (filesystem_traits::is_directory(*i))
		{
			dircount++;
			std::cout << std::setw(20) << *i << " (directory)" << std::endl;
		}
	}

	std::cout << std::endl << '\t' << filecount << " files" << std::endl;
	std::cout << '\t' << dircount << " directories" << std::endl;

	return 0;
}