#include <cstdio>
#include <vector>
#include "dlib/dir_nav.h"


using std::vector; 

int main(int argc, char const *argv[])
{
	int dircount = 0, filecount = 0;
	dlib::directory curdir(".");
	vector<dlib::directory> dirs;
	vector<dlib::file> files;

	 curdir.get_dirs(dirs);
	for (vector<dlib::directory>::iterator i = dirs.begin(); i != dirs.end(); ++i)
	{
		dircount++;
		std::printf("%20s  (directory)\n", i->name().c_str());
	}

	curdir.get_files(files);
	for (vector<dlib::file>::iterator i = files.begin(); i != files.end(); ++i)
	{
		filecount++;
		std::printf("%20s  (%d bytes)\n", i->name().c_str(), i->size());
	}

	std::printf("\n\t\t%d files\n", filecount);
	std::printf("\t\t%d directories\n", dircount);

	return 0;
}