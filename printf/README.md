# my_printf

Func realized on Nasm x86_64. My function is identical to the standard function **printf** (C).

## Program start

``` 
    ./link.sh <program.s> <program.c> <program> 
    ./<program> 
```
### For example

```
    ./link.sh asm.s main.c prog
    ./prog
```

## Implemented functionality

| specifier | functional |
| :--------:| :--------: |
| %s        | input str  |
| %d        | input decimal number |
| %b        | input binary number |
| %o        | input octal number |
| %x        | input hexadecimal number |
| %c        | input one char symbol |
| %p        | input address pointer |
| %n        | passing number printed smb |

## Comparing my function and the original one (main.c)

![My picture](img/example.png)

