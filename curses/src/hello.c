#include <curses.h>

int main()
{    
    initscr(); /* Start curses mode  */
    curs_set(0); /* Makes the cursor invisible */
    printw("Hello World !!!"); /* Print Hello World */
    refresh(); /* Print it on to the real screen */
    getch(); /* Wait for user input */
    endwin(); /* End curses mode */
    
    return 0;
}
