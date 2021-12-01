#include "Hash.h"



/*---------------------------------------------------------------------------*/
void HashInitData(int **pptr,int size) {
  AllocP((*pptr),int,size);
  memset((*pptr),0xFF,size*sizeof(int));
}

/*---------------------------------------------------------------------------*/
ObjHash *HashNew(float maxdist,float *Vertex,int numVertex) {
  int i;
  float *v;
  Vector3f Min,Max;
  VectorClear3f(Min);
  VectorClear3f(Max);
  if(numVertex) {
    v=Vertex;
    VectorCopy3f(Min,v);
    VectorCopy3f(Max,v);
    for(i=0;i<numVertex;i++) {
      VectorMin3f(Min,v);
      VectorMax3f(Max,v);
      v+=3;
    }
  }
  return HashNew5(maxdist,Vertex,numVertex,Min,Max);
}

/*---------------------------------------------------------------------------*/
ObjHash *HashNew5(float maxdist,float *Vertex,int numVertex,float *Min,float *Max) {
  int i,a,b,c;
  float *v;
  int *nextvertex;
  float diagonal[3];

  /* I. Initialize values */
  OOAlloc(ObjHash);
  I->Space=NULL;
  I->Link=NULL;

  VectorCopy3f(I->Min,Min);
  VectorCopy3f(I->Max,Max);
  VectorDecrease3f(I->Min,0.1f);
  VectorIncrease3f(I->Max,0.1f);
 
  /* III. initialize units and fill the space by cubes of unit size */
  I->unit=HashGetUnitsize(maxdist,I->Min,I->Max,diagonal);
  I->recip_unit=1.0f/I->unit;
  for(i=0;i<3;i++) {
    I->Dimension[i]=(int)((diagonal[i]/I->unit)+(2*HashBorder)+1);
    I->iMax[i]=HashBorder;
    I->iMin[i]=I->Dimension[i]-HashBorder-1;
  }
  I->layersize=I->Dimension[1]*I->Dimension[2];
  I->spacesize=I->Dimension[0]*I->layersize;
  HashInitData(&I->Space,I->spacesize);
  I->vertexsize=numVertex;
  HashInitData(&I->Link,numVertex);
  
  /* IV. second pass, put all vertex in their corresponding cube in the I->Space
   * and at the same time, move existing vertex in I->Space to their I->Link */
  if(numVertex) {
    v=Vertex;
    for(i=0;i<numVertex;i++) {
      HashLocate(I,v,&a,&b,&c);
      nextvertex=HashFirst(I,a,b,c);
      I->Link[i]=*nextvertex;
      *nextvertex=i;
      v+=3;
    }
  }

  return(I);
}


/*---------------------------------------------------------------------------*/
void HashLocate(ObjHash *I,float *v,int *a,int *b,int *c) {
  int i;
  int vi[3];
  for(i=0;i<3;i++)
    vi[i]=(int)((v[i]-I->Min[i])*I->recip_unit)+HashBorder;
  //VectorValidate3i(vi,I->iMin,I->iMax);
  *a=vi[0];
  *b=vi[1];
  *c=vi[2];
}

/*---------------------------------------------------------------------------*/
void HashFree(ObjHash *I) {
  if(I) {
    FreeP(I->Space);
    FreeP(I->Link);
  }
  FreeP(I);
}

/*---------------------------------------------------------------------------*/
float HashGetUnitsize(float maxdist,float *min,float *max,float *diagonal) {
  float size, numDiv;
  VectorCopy3f(diagonal,max);
  VectorSubstract3f(diagonal,min);
  size=VectorLongestDimension3f(diagonal);
  if(size<=0) {
    VectorLoadIdentity3f(diagonal);
    size=1.0f;
  }
  numDiv=(float)(size/(maxdist+0.1f));
  //VectorValidate1f(&numDiv,1.0f,EnvGetf(ENV_HASH_MAXSIZE));
  return(size/numDiv);
}
