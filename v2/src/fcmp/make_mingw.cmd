:: specify the path to the folder where mingw is installed
@echo off
set VER=15.1.0
set PATH=D:\Portable\Programming\MinGW\%VER%\bin;%PATH%
mingw32-make mingw GCC_VER=%VER%