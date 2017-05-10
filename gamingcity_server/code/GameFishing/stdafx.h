// stdafx.h : 标准系统包含文件的包含文件，
// 或是经常使用但不常更改的
// 特定于项目的包含文件
//

#pragma once

#include "targetver.h"

#include <stdio.h>
#include <tchar.h>



// TODO:  在此处引用程序需要的其他头文件
#include "perinclude.h"

#define ASSERT(x) assert(x)
using std::min;
using std::max;

#include <mmsystem.h>
#pragma comment(lib, "winmm.lib")

// 游戏人数
#define GAME_PLAYER			CGameConfig::GetInstance()->nPlayerCount

#define MAX_PROBABILITY		1000.0f
//#define GAME_FPS			60// del lee 2016.03.07
#define GAME_FPS			30// 修改成30帧 add lee 2016.03.07
#define MAX_TABLE_CHAIR	4// 每张桌子椅子个数

#define SCENE_CHANAGE_NONE	 -1

#define	SWITCH_SCENE_END	8


#define SAFE_DELETE(x) { if (NULL != (x)) { delete (x); (x) = NULL; } }

//////////////////////////////////////////////////////////////////////////
inline void DebugString(LPCTSTR lpszFormat, ...)
{
	va_list   args;
	int       nBuf;
	TCHAR     szBuffer[1024];

	va_start(args, lpszFormat);

#if _MSC_VER>1400
	nBuf = _vsnwprintf_s(szBuffer, _TRUNCATE, lpszFormat, args);
#else
	nBuf = _vsnwprintf(szBuffer, CountArray(szBuffer), lpszFormat, args);
#endif

	OutputDebugString(szBuffer);

	va_end(args);
}



static unsigned int g_seed = 0;
static void RandSeed(int seed)
{
	if (!seed) g_seed = GetTickCount();
	else g_seed = seed;
}

static int RandInt(int min, int max)
{
	if (min == max) return min;

	g_seed = 214013 * g_seed + 2531011;

	return min + (g_seed ^ g_seed >> 15) % (max - min);
}

static float RandFloat(float min, float max)
{
	if (min == max) return min;

	g_seed = 214013 * g_seed + 2531011;

	return min + (g_seed >> 16) * (1.0f / 65535.0f) * (max - min);
}

