#include "util.h"

/* This file is taken from the string handling section of annoview, 2005
 *                     and the vector handling section of annoview, 2005
 * All string handling procedures are written by Heping Zheng, 2005
 * All vector handling procedures are written by Heping Zheng, 2005
 * Being copied as utility file for neighborhood program by Heping, Oct-2006 */

/*---------------------------------------------------------------------------*/
/* PART O. error handling */
/*---------------------------------------------------------------------------*/
void PWarning(const char *err) {
  fprintf(stdout, "neighborhood warning: %s\n", err);
  fflush(stdout);
}

void PFatalError(const char *err) {
  fprintf(stderr, "neighborhood error: %s\n", err);
  fflush(stderr);
  exit(1);
}

void PPointerError(const char *file, int line) {
  fprintf(stderr,"NULL-POINTER-ERROR: in %s line %i\n",file,line);
  exit(1);
}

ObjCounter* counterNew(int numFigure) {
  ObjCounter* counter;
  RecCounter* reci;
  AllocP(counter,ObjCounter,1);
  counter->maxRecords=numFigure;
  counter->numRecords=0;
  AllocP(counter->reci,RecCounter,numFigure);
  reci=counter->reci;
  reci->index =-1;
  reci->figure=-1;
  reci->count =-1;
  return counter;
}

void counterAddRecord(ObjCounter *counter,int figure) {
  int i,numRecords,figureAdded=0;
  RecCounter *reci;
  if(figure<=0) return;
  numRecords=counterNumRecords(counter);
  for(i=0;i<numRecords;i++) {
    reci=counter->reci+i;
    if(reci->figure==figure) {
      reci->count++;
      figureAdded=1;
    }
  }
  if(!figureAdded) {
    reci=counter->reci+numRecords;
    reci->index=numRecords;
    reci->figure=figure;
    reci->count=1;
    numRecords++;
    counter->numRecords++;
    reci=counter->reci+numRecords;
    reci->index=-1;
    reci->figure=-1;
    reci->count=-1;
  }
}

int counterNumRecords(ObjCounter *counter) {
  int i=0;
  RecCounter *reci=counter->reci+i;
  while(reci->index!=-1) {
    if(i>=counter->maxRecords) PFatalError("ObjCounter overflow detected\n");
    i++;
    reci=counter->reci+i;
  }
  if(i!=counter->numRecords) PFatalError("ObjCounter numRecords disagreement detected\n");
  return i;
}

int counterMostPopular(ObjCounter *counter) {
  int i,numRecords,figureMostPopular=-1,countMostPopular=-1;
  RecCounter *reci;
  numRecords=counterNumRecords(counter);
  for(i=0;i<numRecords;i++) {
    reci=counter->reci+i;
    if(reci->count>countMostPopular) {
      figureMostPopular=reci->figure;
      countMostPopular =reci->count;
    }
  }
  return figureMostPopular;
}

void counterFree(ObjCounter *counter) {
  FreeP(counter->reci);
  FreeP(counter);
}

/*---------------------------------------------------------------------------*/
/* PART I. string buffer handling */
/*---------------------------------------------------------------------------*/
char *str2cachetextfile(FILE *f) {
  int size;
  char* buffer=NULL;
  fseek(f,0,SEEK_END);
  size=ftell(f);
  fseek(f,0,SEEK_SET);
  AllocP(buffer,char,(size+255));
  fread(buffer,size,1,f);
  fclose(f);
  return buffer;
}

void str2printline(char *p) {
  /* proceed to the next line */
  while(*p) {
    if(*p==0xD) {
      p++;
      if(*p==0xA) p++;
      break;
    }
    if(*p==0xA) {
      p++;
      break;
    }
    fprintf(stderr, "%c", *p);
    p++;
  }
  fprintf(stderr, "\n");
}

char *str2nextline(char *p) {
  /* proceed to the next line */
  while(*p) {
    if(*p==0xD) {
      p++;
      if(*p==0xA) p++;
      break;
    }
    if(*p==0xA) {
      p++;
      break;
    }
    p++;
  }
  return p;
}

char *str2nskip(char *p,int n) {
  /* skip n chars except of eoln */
  while(*p) {
    if(!n) break;
    if((*p==0xD)||(*p==0xA)) break;
    p++;
    n--;
  }
  return p;
}

char *str2ncpy(char *des,char *src,int n) {
  /* copy n chars except of eoln */
  while(*src) {
    if(!n) break;
    if((*src==0xD)||(*src==0xA)) break;
    *(des++)=*(src++);
    n--;
  }
  *des=0;
  return src;
}

char *str2bskip(char *p,char c) {
  /* skip blank chars, blank chars is defined as c, or till eoln */
  while(*p) {
    if((*p==0xD)||(*p==0xA)) break;
    if(*p!=c) break;
    p++;
  }
  return p;
}

char *str2wcpy(char *des,char *src) {
  /* copy next word, except of eoln */
  while(*src) {
    if((*src==0xD)||(*src==0xA)) break;
    if((*src!=' ')&&(*src!='\t')) break;
    src++;
  }
  while(*src) {
    if((*src==0xD)||(*src==0xA)) break;
    if((*src==' ')||(*src=='\t')) {
      src++;
      break;
    }
    *(des++)=*(src++);
  }
  *des=0;
  return src;
}

char *str2cskip(char *p,char c) {
  /* skip chars until see char c, or till eoln */
  while(*p) {
    if((*p==0xD)||(*p==0xA)) break;
    if(*p==c) {
      p++;
      break;
    }
    p++;
  }
  return p;
}

char *str2ccpy(char *des,char *src,char c) {
  /* copy chars until see char c, or till eoln */
  while(*src) {
    if((*src==0xD)||(*src==0xA)) break;
    if(*src==c) {
      src++;
      break;
    }
    *(des++)=*(src++);
  }
  *des=0;
  return src;
}

int str2bcmp(char *p,char *q) {
  /* string comparison ignoring any blank */
  while(*p || *q) {
    while(*p==' ') p++;
    while(*q==' ') q++;
    if(*p && *q) {
      if(*p==*q) {
        p++;
        q++;
      } else
        return((*p)-(*q));
    } else if(*p)
      return 1;
    else if(*q)
      return -1;
    else
      return 0;
  }
  return 0;
}

int str2symbolcnt(char *p,char c) {
  int cnt=0;
  while(*p) {
    if(*p==c) cnt++;
    p++;
  }
  return cnt;
}

char *str2strip(char *p,char *sl) {
  char *q, *s;
  while(*p) {
    s=sl;
    while(*s) {
      if(*p==*s) {
        p++;
        break;
      }
      s++;
    }
    if(*s==0) break;
  }
  if(*p==0) return p;
  q=p+strlen(p)-1;
  while(q!=p) {
    s=sl;
    while(*s) {
      if(*q==*s) {
        *q=0;
        q--;
        break;
      }
      s++;
    }
    if(*s==0) break;
  }
  return p;
}

int str2contains(char *p,char *sub) {
  /* check if string p contains the substring sub */
  char *q, *s;
  while(*p) {
    s=sub;
    if(*s==*p) {
      q=p;
      while(*s) {
        if(*s==*q) {
          s++;
          q++;
        } else
          break;
      }
      if(*s==0) return 1;
    }
    p++;
  }
  return 0;
}

int str2containsword(char *p,char *sub) {
  /* check if string p contains the substring sub as a whole word */
  char *q, *s;
  while(*p) {
    s=sub;
    if(*s==*p) {
      q=p;
      while(*s) {
        if(*s==*q) {
          s++;
          q++;
        } else
          break;
      }
      if(*s==0 && !isalnum(*q)) return 1;
    }
    p++;
  }
  return 0;
}

int str2extractpdbid(char *pdbid, char *p) {
  int status=0, len=strlen(p);
  char *q;
  if (len>=11) {
    q=p+len-11;
    if(!strncasecmp(q,"pdb",3)) {
      pdbid[0]=q[3];
      pdbid[1]=q[4];
      pdbid[2]=q[5];
      pdbid[3]=q[6];
      pdbid[4]=0;
      status=1;
    }
  } else if (len>=8) {
    q=p+len-4;
    if((!strncasecmp(q,".pdb",4)) || (!strncasecmp(q,".ent",4))) {
      q=p+len-8;
      if(isalnum(q[0]) && isalnum(q[1]) && isalnum(q[2]) && isalnum(q[3])) {
        pdbid[0]=q[0];
        pdbid[1]=q[1];
        pdbid[2]=q[2];
        pdbid[3]=q[3];
        pdbid[4]=0;
        status=1;
      }
    }
  }
  if (status==0) strcpy(pdbid, "XXXX");
  return status;
}

char *str2toupper (char *str1, const char *str2) { 
  int len2,i;                                                                                                                          
  if (!str2) return NULL;                                                                                                              
  len2 = strlen(str2);
  if (len2 > 0) for (i=0; i<len2 ; i++) str1[i] = toupper(str2[i]);                                                                    
  str1[len2] = '\0';                                                                                                                   
  return str1;                                                                                                                         
}                                                                                                                                      

char *str2tolower (char *str1, const char *str2) { 
  int len2,i;                                                                                                                          
  if (!str2) return NULL;                                                                                                              
  len2 = strlen(str2);
  if (len2 > 0) for (i=0; i<len2 ; i++) str1[i] = tolower(str2[i]);                                                                    
  str1[len2] = '\0';                                                                                                                   
  return str1;                                                                                                                         
}                                                                                                                                      

char *str2replace (char *p,char a,char b) {
  int len,i;
  for(i=0;i<strlen(p);i++) {
    if(p[i]==a) p[i]=b;
  }
  return p;
}


#define M3(row,col) m[row*3+col]
#define SRC3(row,col) src[row*3+col]
#define DES3(row,col) des[row*3+col]
#define M4(row,col) m[(row<<2)+col]
#define SRC4(row,col) src[(row<<2)+col]
#define DES4(row,col) des[(row<<2)+col]

/*---------------------------------------------------------------------------*/
/* PART II: Vector related operations */
/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
int FloatSimilar(float f1, float f2) {
  if(f1>f2) {
    return (f1-f2>V_SMALL) ? 0: 1;
  } else {
    return (f2-f1>V_SMALL) ? 0: 1;
  }
}

/*---------------------------------------------------------------------------*/
double BfactorCorrelation(float b1, float b2) {
  if(b1==0 || b2==0) {
    if(b1==0 && b2==0) {
      return(0);
    } else if (b1==0) {
      return(b2*b2);
    } else {
      return(b1*b1);
    }
  } else if(b1>b2) {
    return(((b1-b2)*(b1/b2)));
  } else {
    return(((b2-b1)*(b2/b1)));
  }
}

/*---------------------------------------------------------------------------*/
double VectorLength2f(float *v) {
  double len;
  len=sqrt((v[0]*v[0])+(v[1]*v[1]));
  return(len);
}

/*---------------------------------------------------------------------------*/
double VectorLength3f(float *v) {
  double len;
  len=sqrt((v[0]*v[0])+(v[1]*v[1])+(v[2]*v[2]));
  return(len);
}

/*---------------------------------------------------------------------------*/
double VectorDistance2v(float *v1, float *v2) {
  register float dx,dy,dz;
  dx=(v1[0]-v2[0]);
  dy=(v1[1]-v2[1]);
  dz=(v1[2]-v2[2]);
  return(sqrt(dx*dx+dy*dy+dz*dz));
}

/*---------------------------------------------------------------------------*/
double VectorAngle3f(float *v) {
  register float d0,d1,d2,cos_val,acos_val;
  d0=v[0];
  d1=v[1];
  d2=v[2];
  cos_val = (d1*d1+d2*d2-d0*d0)/(2*d1*d2);
  acos_val = (cos_val<=-0.999999 && cos_val>=-1.000001) ? 180.0f : (acos(cos_val)*180.0f/M_PI);
  return(acos_val);
}

/*---------------------------------------------------------------------------*/
double VectorAngle2v(float *v1, float *v2) {
  register float cos_val, acos_val;
  cos_val=v1[0]*v2[0]+v1[1]*v2[1]+v1[2]*v2[2];
  acos_val = (cos_val<=-0.999999 && cos_val>=-1.000001) ? 180.0f : (acos(cos_val)*180.0f/M_PI);
  return(acos_val);
}

/*---------------------------------------------------------------------------*/
void VectorValidate1f(float *v,float min,float max) {
  if(v[0]<min) v[0]=min;
  if(v[0]>max) v[0]=max;
}

/*---------------------------------------------------------------------------*/
void VectorValidate3i(int *v,int *min,int *max) {
  int i;
  for(i=0;i<3;i++) {
    if(v[i]<min[i]) v[i]=min[i];
    if(v[i]>max[i]) v[i]=max[i];
  }
}

/*---------------------------------------------------------------------------*/
void VectorValidate3f(float *v,float *min,float *max) {
  int i;
  for(i=0;i<3;i++) {
    if(v[i]<min[i]) v[i]=min[i];
    if(v[i]>max[i]) v[i]=max[i];
  }
}

/*---------------------------------------------------------------------------*/
float VectorLongestDimension3f(float *v) {
  float size;
  size = (v[0]>v[1]) ? v[0] : v[1];
  return((v[2]>size) ? v[2] : size);
}

/*---------------------------------------------------------------------------*/
float VectorShortestDimension3f(float *v) {
  float size;
  size = (v[0]<v[1]) ? v[0] : v[1];
  return((v[2]<size) ? v[2] : size);
}

/*---------------------------------------------------------------------------*/
void VectorClear3f(float *v) {
  v[0]=0.0f;
  v[1]=0.0f;
  v[2]=0.0f;
}

/*---------------------------------------------------------------------------*/
void VectorLoadIdentity3f(float *v) {
  v[0]=1.0f;
  v[1]=1.0f;
  v[2]=1.0f;
}

/*---------------------------------------------------------------------------*/
void VectorCopy3f(float *des, float *src) {
  des[0]=src[0];
  des[1]=src[1];
  des[2]=src[2];
}

/*---------------------------------------------------------------------------*/
void VectorReverse3f(float *des, float *src) {
  des[0]=-src[0];
  des[1]=-src[1];
  des[2]=-src[2];
}

/*---------------------------------------------------------------------------*/
void VectorMin3f(float *des, float *src) {
  if(des[0]>src[0]) des[0]=src[0];
  if(des[1]>src[1]) des[1]=src[1];
  if(des[2]>src[2]) des[2]=src[2];
}

/*---------------------------------------------------------------------------*/
void VectorMax3f(float *des, float *src) {
  if(des[0]<src[0]) des[0]=src[0];
  if(des[1]<src[1]) des[1]=src[1];
  if(des[2]<src[2]) des[2]=src[2];
}

/*---------------------------------------------------------------------------*/
void VectorPrint3f(float *v) {
  int a;
  for(a=0;a<3;a++)
    printf("%f\t",v[a]);
  printf("\n");
}

/*---------------------------------------------------------------------------*/
void VectorPrint4f(float *v) {
  int a;
  for(a=0;a<4;a++)
    printf("%f\t",v[a]);
  printf("\n");
}

/*---------------------------------------------------------------------------*/
void VectorNormalize3f(float *des, float *src) {
  double len;
  len=VectorLength3f(src);
  if(len>VV_SMALL) {
    des[0]=(float)(src[0]/len);
    des[1]=(float)(src[1]/len);
    des[2]=(float)(src[2]/len);
  } else {
    des[0]=0.0f;
    des[1]=0.0f;
    des[2]=0.0f;
  }
}

/*---------------------------------------------------------------------------*/
void VectorDelineate3f(float *des, float *src) {
  des[0]=des[0]*src[0];
  des[1]=des[1]*src[1];
  des[2]=des[2]*src[2];
}

/*---------------------------------------------------------------------------*/
void VectorAdd3f(float *des, float *src) {
  des[0]+=src[0];
  des[1]+=src[1];
  des[2]+=src[2];
}

/*---------------------------------------------------------------------------*/
void VectorSubstract3f(float *des, float *src) {
  des[0]-=src[0];
  des[1]-=src[1];
  des[2]-=src[2];
}

/*---------------------------------------------------------------------------*/
void VectorIncrease3f(float *des, float src) {
  des[0]+=src;
  des[1]+=src;
  des[2]+=src;
}

/*---------------------------------------------------------------------------*/
void VectorDecrease3f(float *des, float src) {
  des[0]-=src;
  des[1]-=src;
  des[2]-=src;
}

/*---------------------------------------------------------------------------*/
void VectorScaleUp3f(float *des, double src) {
  des[0]*=src;
  des[1]*=src;
  des[2]*=src;
}

/*---------------------------------------------------------------------------*/
void VectorScaleDown3f(float *des, double src) {
  des[0]/=src;
  des[1]/=src;
  des[2]/=src;
}

/*---------------------------------------------------------------------------*/
void VectorAverage3f(float *des, int src) {
  des[0]/=src;
  des[1]/=src;
  des[2]/=src;
}

/*---------------------------------------------------------------------------*/
void VectorCrossproduct3f(float *v1,float *v2, float *cross) {
  cross[0]=((v1[1]*v2[2])-(v1[2]*v2[1]));
  cross[1]=((v1[2]*v2[0])-(v1[0]*v2[2]));
  cross[2]=((v1[0]*v2[1])-(v1[1]*v2[0]));
}

/*---------------------------------------------------------------------------*/
void VectorMiddle3f(float *v1,float *v2,float *mid) {
  mid[0]=(v1[0]+v2[0])/2.0f;
  mid[1]=(v1[1]+v2[1])/2.0f;
  mid[2]=(v1[2]+v2[2])/2.0f;
}

/*---------------------------------------------------------------------------*/
void VectorTransform3f33f(float *v, float *m) {
  register float v0=*v, v1=*(v+1), v2=*(v+2);
  *(v++) = m[0]*v0+m[1]*v1+m[2]*v2;
  *(v++) = m[3]*v0+m[4]*v1+m[5]*v2;
  *(v++) = m[6]*v0+m[7]*v1+m[8]*v2;
}

/*---------------------------------------------------------------------------*/
void VectorTransform3f44f(float *v, float *m) {
  float m33[9];
  float vt[3];
  MatrixDecreaseCopy(m33,m);
  VectorTransform3f33f(v,m33);
  vt[0]=m[3];
  vt[1]=m[7];
  vt[2]=m[11];
  VectorAdd3f(v,vt);
}

/*---------------------------------------------------------------------------*/
void VectorInvTransform3f44f(float *v, float *m) {
  float m33[9], inv[9];
  MatrixDecreaseCopy(m33,m);
  MatrixTranspositionCopy33f(inv,m33);
  VectorTransform3f33f(v,inv);
}


/*---------------------------------------------------------------------------*/
/* PART III: Matrix33f related operations */
/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
void MatrixLoadIdentity33f(float *m) {
  int a,b;
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      M3(a,b)=0.0f;
  M3(0,0)=1.0f;
  M3(1,1)=1.0f;
  M3(2,2)=1.0f;
}

/*---------------------------------------------------------------------------*/
void MatrixCopy33f(float *des, float *src) {
  int a,b;
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      DES3(a,b)=SRC3(a,b);
}

/*---------------------------------------------------------------------------*/
void MatrixPrint33f(float *m) {
  int a,b;
  for(a=0;a<3;a++) {
    for(b=0;b<3;b++)
      printf("%f\t",M3(a,b));
    printf("\n");
  }
}

/*---------------------------------------------------------------------------*/
void MatrixTranspositionCopy33f(float *des, float *src) {
  int a,b;
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      DES3(a,b)=SRC3(b,a);
}

/*---------------------------------------------------------------------------*/
void MatrixMultiply33f(float *des,float *src) {
  int a,b,c;
  float m[9];
  memset(m,0,9*sizeof(float));
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      for(c=0;c<3;c++)
        M3(a,b)+=DES3(a,c)*SRC3(c,b);
  MatrixCopy33f(des,m);
}

/*---------------------------------------------------------------------------*/
void MatrixRotate33f(float *m,float *axis,float angle) {
  float m33[9];
  MatrixGenerateRotate33f(m33,axis,angle);
  MatrixMultiply33f(m,m33);
}

/*---------------------------------------------------------------------------*/
void MatrixGenerateRotate33f(float *m,float *axis0,float angle) {
  /* Rotation function coming from OpenGL Programming Guide 3rd Edition Page 672
   * Let v=(x,y,z)T, and u=v/||v||=(x',y',z')T.
   * and S=[[0,-z',y'],[z',0,-x'],[-y',x',0]].
   * then m=uuT+(cos a)(1-uuT)+(sin a)S. which means
   *        | xx xy xz |    | 1 0 0 |   | 0 -zs ys |
   * m=(1-c)| yx yy yz | + c| 0 1 0 | + | zs 0 -xs |
   *        | zx zy zz |    | 0 0 1 |   | -ys xs 0 |
   * This matrix will get computed in this routine and stored in m */
  float len, s, c, axis[3];
  float xx, yy, zz, xy, yz, zx, xs, ys, zs, one_c;

  angle=(float)(-angle*M_PI/180.0);
  s = (float)sin(angle);
  c = (float)cos(angle);
  len = (float)VectorLength3f(axis0);

  if(len>=VV_SMALL) {
    VectorNormalize3f(axis,axis0);
    xx = axis[0] * axis[0];
    yy = axis[1] * axis[1];
    zz = axis[2] * axis[2];
    xy = axis[0] * axis[1];
    yz = axis[1] * axis[2];
    zx = axis[2] * axis[0];
    xs = axis[0] * s;
    ys = axis[1] * s;
    zs = axis[2] * s;
    one_c = 1.0f - c;

    M3(0,0) = (one_c * xx) + c;
    M3(0,1) = (one_c * xy) - zs;
    M3(0,2) = (one_c * zx) + ys;
    M3(1,0) = (one_c * xy) + zs;
    M3(1,1) = (one_c * yy) + c;
    M3(1,2) = (one_c * yz) - xs;
    M3(2,0) = (one_c * zx) - ys;
    M3(2,1) = (one_c * yz) + xs;
    M3(2,2) = (one_c * zz) + c;
  } else
    MatrixLoadIdentity33f(m);
}

/*---------------------------------------------------------------------------*/
void MatrixIncreaseCopy(float *des, float*src) {
  int a,b;
  MatrixLoadIdentity44f(des);
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      DES4(a,b)=SRC3(a,b);
}

/*---------------------------------------------------------------------------*/
void MatrixDecreaseCopy(float *des, float*src) {
  int a,b;
  for(a=0;a<3;a++)
    for(b=0;b<3;b++)
      DES3(a,b)=SRC4(a,b);
}

/*---------------------------------------------------------------------------*/
/* PART IV: Matrix44f related operations */
/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
void MatrixLoadIdentity44f(float *m) {
  int a,b;
  for(a=0;a<4;a++)
    for(b=0;b<4;b++)
      M4(a,b)=0.0f;
  for(a=0;a<4;a++)
    M4(a,a)=1.0f;
}

/*---------------------------------------------------------------------------*/
void MatrixCopy44f(float *des, float *src) {
  int a,b;
  for(a=0;a<4;a++)
    for(b=0;b<4;b++)
      DES4(a,b)=SRC4(a,b);
}

/*---------------------------------------------------------------------------*/
void MatrixPrint44f(float *m) {
  int a,b;
  for(a=0;a<4;a++) {
    for(b=0;b<4;b++)
      printf("%f\t",M4(a,b));
    printf("\n");
  }
}

/*---------------------------------------------------------------------------*/
void MatrixTranspositionCopy44f(float *des, float *src) {
  int a,b;
  for(a=0;a<4;a++)
    for(b=0;b<4;b++)
      DES4(a,b)=SRC4(b,a);
}

/*---------------------------------------------------------------------------*/
void MatrixMultiply44f(float *des,float *src) {
  int a,b,c;
  float m[16];
  memset(m,0,16*sizeof(float));
  for(a=0;a<4;a++)
    for(b=0;b<4;b++)
      for(c=0;c<4;c++)
        M4(a,b)+=DES4(a,c)*SRC4(c,b);
  MatrixCopy44f(des,m);
}

/*---------------------------------------------------------------------------*/
/* Same functionality as previous function, but copied from CCP4, taking different type */
void ccp4_4matmul( float c[4][4], const float  a[4][4], const float b[4][4])
{
  int i,j,k;

  for ( i = 0; i < 4; i++ ) 
    for ( j = 0; j < 4; j++ ) {
      c[i][j] = 0.0;
      for ( k = 0; k < 4; k++ ) 
        c[i][j] += a[i][k]*b[k][j];
    }
}

/*---------------------------------------------------------------------------*/
void MatrixRotate44f(float *m,float *axis,float angle) {
  float m33[9];
  float m44[16];
  MatrixGenerateRotate33f(m33,axis,angle);
  MatrixIncreaseCopy(m44,m33);
  MatrixMultiply44f(m,m44);
}

/*---------------------------------------------------------------------------*/
void MatrixGenerateRotate44f(float *m,float *axis,float angle) {
  float m33[9];
  MatrixGenerateRotate33f(m33,axis,angle);
  MatrixIncreaseCopy(m,m33);
}

/*---------------------------------------------------------------------------*/
/*   A (I)   4*4 matrix to be inverted */
/*   AI (O)   inverse matrix */
/*   returns determinant */

float invert4matrix(const float a[4][4], float ai[4][4])

{
    double c[4][4], d;
    int i, j;
    double x[3][3];
    int i1, j1, i2 ;
    double am, q;
    int ii, jj;

    /* Function Body */
    for (ii = 0; ii < 4; ++ii) {
	for (jj = 0; jj < 4; ++jj) {
            ai[ii][jj] = 0.0;
	    i = -1;
	    for (i1 = 0; i1 < 4; ++i1) {
		if (i1 != ii) {
		    ++i;
		    j = -1;
		    for (j1 = 0; j1 < 4; ++j1) {
			if (j1 != jj) {
			    ++j;
			    x[i][j] = a[i1][j1];
			}
		    }
		}
	    }

	    am = x[0][0]*x[1][1]*x[2][2] - x[0][0]*x[1][2]*x[2][1] +
                 x[0][1]*x[1][2]*x[2][0] - x[0][1]*x[1][0]*x[2][2] +
                 x[0][2]*x[1][0]*x[2][1] - x[0][2]*x[1][1]*x[2][0];
	    i2 = ii + jj;
	    c[ii][jj] = ccp4_pow_ii(-1.0, i2) * am;
	}
    }

/* ---- Calculate determinant */

    d = 0.0;

    for (i = 0; i < 4; ++i) {
	d = a[i][0] * c[i][0] + d;
    }

/* ---- Get inverse matrix */


  if (fabs(d) > 1.0e-30) {
    q = 1.0/d;
    for (i = 0; i < 4; ++i) {
	for (j = 0; j < 4; ++j) {
	  ai[i][j] = (float) (c[j][i] * q);
	}
    }
  } else {
    return 0.0;
  }

  return ((float) d);
} 

/*---------------------------------------------------------------------------*/
float ccp4_pow_ii(const float base, const int power) {

  int i = 0;
  float pow = 1;

  while (++i <= power)
    pow *= base;

  return pow;
}

#undef M3
#undef SRC3
#undef DES3
#undef M4
#undef SRC4
#undef DES4
