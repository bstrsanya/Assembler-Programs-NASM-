#include <stdio.h>

extern void my_printf(const char *, ...);  

int main() 
{
    int a = 0;
    printf ("---------------------------------------\n");
    my_printf ("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", 
              -1, -1, "love", 3802, 100, 33, 238,
              -1, "love", 3802, 100, 33, 238);
    printf ("---------------------------------------\n");

    a = 0;
    printf ("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b\n", 
            -1, -1, "love", 3802, 100, 33, 238,
            -1, "love", 3802, 100, 33, 238);
    printf ("---------------------------------------\n");
    
   

    return 0;
}

