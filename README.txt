Commands used (windows command line)

flex project.l
bison -d project.y
gcc project.tab.c lex.y.c -o project.exe
project.exe < test.txt