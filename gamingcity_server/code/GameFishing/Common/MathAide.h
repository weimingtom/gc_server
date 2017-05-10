////
#ifndef MATH_AIDE_H_
#define MATH_AIDE_H_

#include "MovePoint.h"

class CMathAide 
{
public:
  static int Factorial(int number);
  static int Combination(int count, int r);
  static float CalcDistance(float x1, float y1, float x2, float y2);
  static float CalcAngle(float x1, float y1, float x2, float y2);
  static void BuildLinear(float initX[], float initY[], int initCount, std::vector<MyPoint>& TraceVector, float fDistance);
  static void BuildLinear(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance);
  static void BuildBezier(float initX[], float initY[], int initCount, MovePoints& TraceVector, float fDistance);
  static void BuildCircle(float centerX, float centerY, float radius, MovePoints& FishPos, int FishCount);
  static MyPoint GetRotationPosByOffest(float xPos, float yPos, float xOffest, float yOffest, float dir, float fHScale=1.0f, float fVScale=1.0f);
  static void BuildCirclePath(float centerX, float centerY, float radius, MovePoints& FishPos, float begin, float fAngle, int nStep = 1, float fAdd = 0);
};

#endif // MATH_AIDE_H_
