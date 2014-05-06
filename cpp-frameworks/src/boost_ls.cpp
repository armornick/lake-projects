#include <iostream>

#include "boost/format.hpp"
#include "boost/filesystem.hpp"

using boost::format;
namespace bfs = boost::filesystem;


int main(int argc, char const *argv[])
{
	int filecount = 0, dircount = 0;
	bfs::directory_iterator directory(bfs::path("."));

	for (; directory != bfs::directory_iterator(); ++directory)
	{
		const bfs::path& p = directory->path();

		if (bfs::is_regular_file(p))
		{
			filecount++;
			std::cout << format("%25s  (%d bytes)\n") % p %  bfs::file_size(p);
		}
		else if (bfs::is_directory(p))
		{
			dircount++;
			std::cout << format("%25s  (directory)\n") % p;
		}
	}


	std::cout << format("\n\t\t%d files\n") % filecount;
	std::cout << format("\t\t%d directories\n") % dircount;

	return 0;
}