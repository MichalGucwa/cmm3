#ifndef _H_UTIL
#define _H_UTIL

#include <ctype.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* General operations */
void PWarning(const char *err);
void PFatalError(const char *err);
void PPointerError(const char *file, int line);
#define PCheckPointer(p) {if(!p) PPointerError(__FILE__,__LINE__);}
#define AllocP(hzptr,type,size2) \
{ hzptr = (type *)malloc(sizeof(type)*size2); bzero(hzptr,sizeof(type)*size2); PCheckPointer(hzptr); }

#define FreeP(ptr) \
{if(ptr) {free(ptr);ptr=NULL;}}

#define OOAlloc(type) \
type *I;\
I = (type*)malloc(sizeof(type));\
PCheckPointer(I);

/* counter Object */
typedef struct RecCounter {
  int           index;
  int           figure;
  int           count;
} RecCounter;
typedef struct ObjCounter {
  int           maxRecords;
  int           numRecords;
  RecCounter*   reci;
} ObjCounter;
ObjCounter* counterNew(int numFigure);
void counterAddRecord(ObjCounter *counter,int figure);
int  counterNumRecords(ObjCounter *counter);
int  counterMostPopular(ObjCounter *counter);
void counterFree(ObjCounter *counter);

/* String operations */
#define FileLineLength 1024
char *str2cachetextfile(FILE *f);
void str2printline(char *p);
char *str2nextline(char *p);
char *str2nskip(char *p,int n);
char *str2ncpy(char *des,char *src,int n);
char *str2bskip(char *p,char c);
char *str2wcpy(char *des,char *src);
char *str2cskip(char *p,char c);
char *str2ccpy(char *des,char *src,char c);
int str2bcmp(char *p,char *q);
int str2symbolcnt(char *p,char c);
char *str2strip(char *p,char *sl);
int str2contains(char *p,char *sub);
int str2containsword(char *p,char *sub);
int str2extractpdbid(char *pdbid, char *p);
char *str2toupper (char *str1, const char *str2);
char *str2tolower (char *str1, const char *str2);
char *str2replace (char *p,char a,char b);

#ifndef V_SMALL
#define V_SMALL 0.000000001
#endif

double BfactorCorrelation(float b1, float b2);
/* Vector operations */
typedef int Vector3i[3];
typedef float Vector3f[3];
double VectorLength2f(float *v);
double VectorLength3f(float *v);
double VectorDistance2v(float *v1, float *v2);
double VectorAngle3f(float *v);
double VectorAngle2v(float *v1, float *v2);
void VectorValidate1f(float *v,float min,float max);
void VectorValidate3i(int *v,int *min,int *max);
void VectorValidate3f(float *v,float *min,float *max);
float VectorLongestDimension3f(float *v);
float VectorShortestDimension3f(float *v);
void VectorClear3f(float *v);
void VectorLoadIdentity3f(float *v);
void VectorCopy3f(float *des, float *src);
void VectorReverse3f(float *des, float *src);
void VectorMin3f(float *des, float *src);
void VectorMax3f(float *des, float *src);
void VectorPrint3f(float *v);
void VectorPrint4f(float *v);
void VectorNormalize3f(float *des, float *src);
void VectorDelineate3f(float *des, float *src);
void VectorAdd3f(float *des, float *src);
void VectorSubstract3f(float *des, float *src);
void VectorIncrease3f(float *des, float src);
void VectorDecrease3f(float *des, float src);
void VectorScaleUp3f(float *des, double src);
void VectorScaleDown3f(float *des, double src);
void VectorAverage3f(float *des, int src);
void VectorCrossproduct3f(float *v1,float *v2, float *cross);
void VectorMiddle3f(float *v1,float *v2,float *mid);
void VectorTransform3f33f(float *v, float *m);
void VectorTransform3f44f(float *v, float *m);
void VectorInvTransform3f44f(float *v, float *m);
#define VectorTransform3f VectorTransform3f44f

/* Matrix33f operations */
void MatrixLoadIdentity33f(float *m);
void MatrixCopy33f(float *des, float *src);
void MatrixPrint33f(float *m);
void MatrixTranspositionCopy33f(float *des, float *src);
void MatrixMultiply33f(float *des,float *src);
void MatrixRotate33f(float *m,float *axis,float angle);
void MatrixGenerateRotate33f(float *m,float *axis0,float angle);
void MatrixIncreaseCopy(float *des, float*src);
void MatrixDecreaseCopy(float *des, float*src);

/* Matrix44f operations */
void MatrixLoadIdentity44f(float *m);
void MatrixCopy44f(float *des, float *src);
void MatrixPrint44f(float *m);
void MatrixTranspositionCopy44f(float *des, float *src);
void MatrixMultiply44f(float *des,float *src);
void ccp4_4matmul(float c[4][4], const float a[4][4], const float b[4][4]);
void MatrixRotate44f(float *m,float *axis,float angle);
void MatrixGenerateRotate44f(float *m,float *axis,float angle);
float ccp4_pow_ii(const float base, const int power);
float invert4matrix(const float a[4][4], float ai[4][4]);
#define MatrixLoadIdentity MatrixLoadIdentity44f
#define MatrixCopy MatrixCopy44f
#define MatrixPrint MatrixPrint44f
#define MatrixTranspositionCopy MatrixTranspositionCopy44f
#define MatrixRotate MatrixRotate44f
#define MatrixMultiply MatrixMultiply44f

#endif
