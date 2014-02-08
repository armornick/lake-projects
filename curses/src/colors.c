#include <curses.h>

int main()
{    
    initscr();
    start_color(); /* Be sure not to forget this, it will enable colors */
    init_pair(1, COLOR_RED, COLOR_CYAN); /* You can make as much color pairs as you want, be sure to change the ID number */
    init_pair(2, COLOR_YELLOW, COLOR_GREEN);
    attron(A_UNDERLINE | COLOR_PAIR(1)); /* This turns on the underlined text and color pair 1 */
    printw("This is underlined red text with cyan background\n");
    attroff(A_UNDERLINE | COLOR_PAIR(1));
    attron(A_BOLD | COLOR_PAIR(2));
    printw("This is bold yellow text with green background");
    attroff(A_BOLD | COLOR_PAIR(2));
    refresh();            
    getch();          
    endwin();     
    return 0;
}
