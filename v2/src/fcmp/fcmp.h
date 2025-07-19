#ifndef _FCMP_H
#define _FCMP_H


#include <stdint.h>


#if BUILDING_DLL
#define DLLIMPORT __declspec(dllexport)
#else
#define DLLIMPORT __declspec(dllimport)
#endif


#define	CMP_RESULT_MATCHED		(int32_t)(0)
#define CMP_RESULT_DIFFERENT	(int32_t)(1)
#define CMP_RESULT_OPEN_ERROR	(int32_t)(-1)


DLLIMPORT int32_t CompareFiles(char *fname1, char *fname2);


#endif