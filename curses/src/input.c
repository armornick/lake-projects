#include <curses.h>

int main()
{
    int x = 5;
    int y = 5;
    int ch; /* Key input variable */
    initscr();
    curs_set(0);
    keypad(stdscr, TRUE);     /* We get key input    from the main window */
    noecho(); /* Don't echo() while we do getch */
    while (1)
    {
        mvprintw(y, x, "X");
        ch = getch();
        if (ch == KEY_DOWN)
        {
            y++;
            clear();
        }
        if (ch == KEY_UP)
        {
            y--;
            clear();
        }
        if (ch == KEY_LEFT)
        {
            x--;
            clear();
        }
        if (ch == KEY_RIGHT)
        {
            x++;
            clear();
        }
        refresh();
    }
    endwin();         
    return 0;
}    
