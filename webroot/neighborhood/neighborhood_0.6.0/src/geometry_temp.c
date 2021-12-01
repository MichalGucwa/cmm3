#include <stdio.h>
#include <math.h>
#include <string.h>

float vv_ang(float d0,float d1,float d2) {
  return(acos((d1*d1+d2*d2-d0*d0)/(2*d1*d2))*180.0/M_PI);
}

void bit_calculation() {
  int i,j,k,b[7];
  int a=6;
  int l=1<<a;
  for(i=0;i<l;i++) {
    for(j=0;j<a;j++) {
      k=(i>>j)%2;
      printf("%d,",k);
    };
    printf("\n");
  }
}

void dodecahedral(float a) {
  float b,A,B,C,D,E;
  b=sqrt(a*a-1);
  A=vv_ang(a,a,2);
  B=vv_ang(2,a,a);
  C=vv_ang(b,a,sqrt(3));
  D=vv_ang(sqrt(3),a,b);
  E=vv_ang(a,b,sqrt(3));
  printf("%f:%f,%f,%f,%f,%f=(%f)\n",a,A,B,C,D,E,B*3+D*2);
}

void square_antiprism() {
  float a=1.645328776,a2=2.707106781,A,B,C;
  A=vv_ang(2,a,a);
  C=vv_ang(2*sqrt(2),a,a);
  B=vv_ang(3.107547948,a,a);
  printf("%f,%f,%f\n",A,B,C);
}

void trigonal_biprism() {
  float a=sqrt(10.0f/3.0f),A,B,C,D;
  A=vv_ang(2,a,a);
  B=vv_ang(2*sqrt(2),a,a);
  C=vv_ang(2*sqrt(3),a,a);
  D=vv_ang(sqrt(4.55848156),a,a);
  printf("%f,%f,%f,capped_trigonal_biprism:%f\n",A,B,C,D);
  printf("%f,%f,%f\n",A,B,C);
}

int main(int argc, char** argv) {
//float a=-1.0f,b;
//char tmpstr[64];
//strcpy(tmpstr,argv[1]);
//sscanf(tmpstr,"%f",&a);
//a=sqrt(10.0f/3);
  float a=sqrt(3.0f),A,B,C,D;
  A=vv_ang(2,a,a);
  B=vv_ang(2*sqrt(2),a,a);
  printf("%f,%f\n",A,B);
  return 1;
}

