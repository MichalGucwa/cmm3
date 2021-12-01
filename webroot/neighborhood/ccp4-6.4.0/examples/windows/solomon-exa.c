/*#!/bin/csh -f
#
##########################################################
##########################################################
#
# AVERAGING PROCEDURE USING SOLOMON
#
# Script to run several cycles of density modification, in
# this case with a flip value (solvmul) of -1.0. This 
# corresponds to adding the inverted solvent density to 
# the initial map. This is similar to adding negative noise
# to an image in order to strengthen the signal/noise ratio.
#
# The resolution of the map is extended from 3.0 to 2.7
# The variable $res defines the resolution at which the
# current refinement cycle is working. This outlines the 
# general program order that is required but obviously the 
# procedure will be different for other structures. Automatic 
# refinement over a large number of cycles is not advisable, 
# the increase in map quality is the most important factor.
#
# Note that the 'final' map from each cycle is kept i.e. 
# the ones calculated from the combined structure factors.
# Along with the MTZ file that generated it and the solomon
# log files are appended.
#
##########################################################*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int main(int nNumberofArgs, char* pszArgs[])
{
int i;
int cycle;
double solvdens= 0.0;
/*int EndCycle 8          # Number of refinement cycles*/
double res[8]= {3.0, 3.0, 3.0, 2.9, 2.8, 2.7, 2.7, 2.7};
int LastCycle=0;
char cmd[200];
char previous[200];
char line[200];
char tem[9];
char scr[11];

strcpy(tem,"%TEMPRES%");
strcpy(scr,"%SCRIPTWIN%");

for(cycle =1; cycle < 8; cycle++)
{

/*##########################################################
  #  Extend the map resolution for several cycles
  ##########################################################

  ##########################################################
  #  1) Modify the density with Solomon
  ##########################################################*/

double resol =res[cycle];
bool test=false;
i= system("del solomon2.dat");
FILE* f =fopen("solomon2.dat","w");
fprintf(f,"slvfrc 0.51\nmulsolvauto -1.0\nslvdens %f\nradius 3\n",solvdens);
fprintf(f,"trunc 0.4 1\nextrude\nmapout\n\n");
fclose(f);
sprintf(cmd,"solomon mapin %s\\toxd_cycle%d.map mapout %s\\toxd_av.map < %s\\solomon2.dat  > toxd_Solomon.log",tem,LastCycle,tem,scr,tem);
i= system(cmd);

f=fopen("toxd_Solomon.log","r");
fgets(previous,200,f);
char * pch;
pch=NULL;
while(!feof(f)&&!test)
{
fgets(line,200,f);
strcpy(previous,line);
pch = strstr(previous,"new solvdens");
if(pch!=NULL) test=true;
}
fclose(f);
pch=strtok(previous," ");
pch = strtok (NULL, " ");
pch = strtok (NULL, " ");
solvdens=atof(pch);

/*
##########################################################
#  2) generate sfs and phases from this modified map
##########################################################*/

i= system("del solomon2.dat");
f =fopen("solomon2.dat","w");
fprintf(f,"TITLE   Sfs from density modification\nGRID 88 144 80\n");
fprintf(f,"MODE SFCALC MAPIN HKLIN\n");
fprintf(f,"LABIN FP=FTOXD3  SIGFP=SIGFTOXD3 F0=PHI_mir F1=W_mir F2=HLA F3=HLB -\n");
fprintf(f,"F4=HLC F5=HLD\nRESO 9999 %f\nRSCB 6 %f\nBINS 40\nSFSG 19\n",resol,resol);
fprintf(f,"LABO   FC=FCmod PHIC=PHICmod\nend\n");
fclose(f);
sprintf(cmd,"sfall HKLIN %s\\toxd_phase_mir MAPIN %s\\toxd_av.map HKLOUT %s\\junk.mtz < %s\\solomon2.dat > %s\\toxd_sfall.log",tem,tem,tem,scr,tem);
i=system(cmd);
sprintf(cmd,"echo Cycle %d >> %s\\toxd_stats.log",cycle,tem);
i=system(cmd);
sprintf(cmd,"find \"Overall Reliability index is\" %s\\toxd_sfall.log >> %s\\toxd_stats.log",tem,tem);
i=system(cmd);

/*
##########################################################
#  3) combine phases
##########################################################*/

i= system("del solomon2.dat");
f =fopen("solomon2.dat","w");
fprintf(f,"TITLE   Phase combination toxd\n LABI FP=FTOXD3  SIGFP=SIGFTOXD3                  -\n");
fprintf(f,"     HLA=HLA HLB=HLB HLC=HLC HLD=HLD PHIBP=PHI_mir  WP=W_mir     -\n");
fprintf(f,"     FC=FCmod PHIC=PHICmod\n LABO PHCMB=PHCMB1 WCMB=FOMCMB1 FWT=FWT PHFWT=PHFWT\n");
fprintf(f,"RANGES 10 1000\n RESO  9999 %f\n ERROR\n COMBINE PART 1\n END\n",resol);
fclose(f);
sprintf(cmd,"sigmaa HKLIN %s\\junk.mtz HKLOUT %s\\toxd_cycle%d.mtz < %s\\solomon2.dat > %s\\null",tem,tem,cycle,scr,tem);
i=system(cmd);
/*
##########################################################
#  4) recalculate map.
##########################################################*/

i= system("del solomon2.dat");
f =fopen("solomon2.dat","w");
fprintf(f,"TITLE F1 15-%f A, after %d averaging cycles\n",resol,cycle);
fprintf(f,"LABI F1=FWT  SIG1=FWT PHI=PHFWT\n RESO 9999 %f\n GRID 88 144 80\n",resol);
fprintf(f,"#XYZLIM 0 1.0 0 1.0 0 1.0\n end\n");
fclose(f);
sprintf(cmd,"fft HKLIN %s\\toxd_cycle%d.mtz MAPOUT %s\\toxd_cycle%d.map < %s\\solomon2.dat > %s\\null",tem,cycle,tem,cycle,scr,tem);
i=system(cmd);
LastCycle++;
}
sprintf(cmd,"MOVE toxd_Solomon.log %s",tem);
i=system(cmd);
};
