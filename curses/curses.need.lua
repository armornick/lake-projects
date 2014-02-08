local join = path.join

if WINDOWS then
	CURSES_DIR = join('libs', 'pdcurses')
	CURSES_LIBS = 'pdcurses'
end