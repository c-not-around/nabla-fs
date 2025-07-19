#ifndef _COMPAT_H
#define _COMPAT_H


#ifdef __clang__
#define _CRT_SECURE_NO_WARNINGS
#endif

#if defined(__MINGW64__) && !defined(min)
#define min(a,b)			((a)<(b)?(a):(b))
#endif


#endif