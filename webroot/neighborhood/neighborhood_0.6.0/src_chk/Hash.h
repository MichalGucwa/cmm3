#ifndef _H_HASH
#define _H_HASH

#include "util.h"

#define HashBorder 2

typedef struct {
  float unit,recip_unit;        /* size of each cube unit */
  int layersize;                /* total number of cubes on one layer */
  int spacesize;                /* total number of cubes in the space */
  int vertexsize;               /* total number of vertices in the coordinate */
  Vector3i Dimension;           /* dimension on each axis */
  Vector3i iMax,iMin;           /* integer of maximal and minimal values */
  Vector3f Max, Min;            /* maximal and minimal values */
  int *Space,*Link;             /* data */
} ObjHash;

/* FOOTNOTE: Space,Link are the places to keep vertex index data.
 * In Space,
 * -1 means no vertex is found in the cube,
 * any integer indicate the last vertex index in cset
 * In Link,
 * -1 means its host is the first vertex index found in the same space
 * any integer indicate that its host has previous vertex index found in the same space */

void HashInitData(int **ptr,int size);
float HashGetUnitsize(float maxdist,float *min,float *max,float *diagonal);
ObjHash *HashNew(float maxdist,float *Vertex,int numVertex);
ObjHash *HashNew5(float maxdist,float *Vertex,int numVertex,float *Min,float *Max);
void HashLocate(ObjHash *I,float *v,int *a,int *b,int *c);
void HashFree(ObjHash *I);
#define HashFirst(hash,a,b,c) (hash->Space+((a)*hash->layersize)+((b)*hash->Dimension[2])+(c))
#define HashNext(hash,j) (*(hash->Link+(j)))

#endif
