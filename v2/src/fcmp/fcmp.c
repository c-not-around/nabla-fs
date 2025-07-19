#include "compat.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "fcmp.h"


#define CHUNK_SIZE			(4*1024UL)

#define READ_CHUNK(f,c)		fread((void*)(c), 1, CHUNK_SIZE, f)


typedef uint64_t chunk_t;


size_t fsize(FILE *file)
{
	_fseeki64(file, 0, SEEK_END);
	size_t size = _ftelli64(file);
	_fseeki64(file, 0, SEEK_SET);
	return size;
}

DLLIMPORT int32_t CompareFiles(char *fname1, char *fname2)
{
	int32_t result = CMP_RESULT_MATCHED;
	
	FILE *f1 = NULL;
	FILE *f2 = NULL;
	
	if ((f1 = fopen(fname1, "rb")) && (f2 = fopen(fname2, "rb")))
	{
		size_t size = min(fsize(f1), fsize(f2));
		
		chunk_t chunk1[CHUNK_SIZE/sizeof(chunk_t)];
		chunk_t chunk2[CHUNK_SIZE/sizeof(chunk_t)];
		memset(chunk1, 0x00, CHUNK_SIZE);
		memset(chunk2, 0x00, CHUNK_SIZE);
		
		size_t n1 = 0;
		size_t n2 = 0;
		
		while (!result && (n1 = READ_CHUNK(f1, chunk1)) && (n2 = READ_CHUNK(f2, chunk2)))
		{
			int m = min(n1, n2);
			int n = (m + (sizeof(chunk_t)-1)) / sizeof(chunk_t);
			
			for (int i = 0; i < n; i++)
			{
				if (chunk1[i] != chunk2[i])
				{
					result = CMP_RESULT_DIFFERENT;
					break;
				}
			}
		}
	}
	else
	{
		result = CMP_RESULT_OPEN_ERROR;
	}
	
	if (f1 != NULL)
	{
		fclose(f1);
	}
	if (f2 != NULL)
	{
		fclose(f2);
	}
	
	return result;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
	switch(fdwReason)
	{
		case DLL_PROCESS_ATTACH:
		{
			break;
		}
		case DLL_PROCESS_DETACH:
		{
			break;
		}
		case DLL_THREAD_ATTACH:
		{
			break;
		}
		case DLL_THREAD_DETACH:
		{
			break;
		}
	}
	
	return TRUE;
}