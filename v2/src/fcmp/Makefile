TARGET  = fcmp
TGT_SRC = $(TARGET).c
TGT_OBJ = $(TARGET).o
TGT_BIN = $(TARGET).dll

# MinGW 4.9.2 32_64-bit / 15.1.0 64-bit
GCC_VER  =
GCC_PATH = D:/Portable/Programming/MinGW/$(GCC_VER)/
GCC      = $(GCC_PATH)bin/gcc
GCC_INCS = -I"$(GCC_PATH)include" -I"$(GCC_PATH)lib/gcc/x86_64-w64-mingw32/$(GCC_VER)/include"
GCC_LIBS = -L"$(GCC_PATH)lib"

# LLVM 20.1.6 64-bit
CLANG_PATH = D:/Portable/Programming/LLVM/
CLANG      = $(CLANG_PATH)bin/clang


clean:
	rm -f $(TGT_BIN) $(TGT_OBJ)

mingw: clean
	$(GCC) -c $(TGT_SRC) -o $(TGT_OBJ) $(GCC_INCS) -DBUILDING_DLL=1 -std=gnu99 
	$(GCC) -shared $(TGT_OBJ) -o $(TGT_BIN) $(GCC_LIBS) 

llvm: clean
	$(CLANG) -c $(TGT_SRC) -o $(TGT_OBJ) -DBUILDING_DLL=1
	$(CLANG) -shared $(TGT_OBJ) -o $(TGT_BIN) -Wl,-noimplib,-noexp