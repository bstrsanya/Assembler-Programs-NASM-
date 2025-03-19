#include <stdio.h>

extern void my_printf(const char *, ...);  

int main() 
{
    // my_printf("%s %s %c %d %x %o %b %% kjbuob\n", "Hello world!", "love", '$', -1764, 160, 81, 13);
    // my_printf("%s %s %s %s %d %d %d %d", "qwdwe", "CKVSJBD", "VKSJDN", "ROIEV", 1, 8, 6, 1289);
    my_printf("%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b", -1, -1, "love", 3802, 100, 33, 127,
        -1, "love", 3802, 100, 33, 127);


    printf ("\n%o\n%d %s %x %d%%%c%b\n%d %s %x %d%%%c%b", -1, -1, "love", 3802, 100, 33, 127,
        -1, "love", 3802, 100, 33, 127);

    int a = 1;
    printf ("\n%p\n", &a);
    my_printf("%x\n", &a);
    return 0;
}

// %n %p 