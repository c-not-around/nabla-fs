:: specify the path to the folder where MSVC is installed
call "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
set TARGET=fcmp
set SOURCE_FILE=%TARGET%.c
set OUTPUT_FILE=%TARGET%.dll
set CL=/DBUILDING_DLL=1
cl /D_USRDLL /D_WINDLL "%SOURCE_FILE%" /MT /link /DLL /OUT:"%OUTPUT_FILE%" /NOIMPLIB /NOEXP