#!/bin/csh -f
#   An insulin example.
#   Straight forward except that the rotation solution for the
#   second molecule is  25th in the list.
#  POSICIONES FINALES
#      1    36.38    75.12   162.78  0.29461  0.11458  0.25883 76.4 39.8   0.  #      1    70.90    37.84   105.72  0.87539  0.67746  0.63796 76.4 39.8   0.
#  Fitting done at higher resolution than other calculations.
#goto lsq
# Will need to cat the two molecules together.
#goto tab2_fit2
#  Done at 2.5A  - need to recalculate TABFUN
#goto fit
#goto tra2
#  Fix one molecule - search for 2nd.
#goto tra1
#  Search for single molecules - only one good solution.
#goto rot
goto tab
#####################################################3
#    sorting run: 
#####################################################3
#  mtz file contains cell and symmetry.
#
amore \
hklin  /usr/disk3/scratch/jpt/x2_ortho/x2_jo.mtz \
hklpck0 /f/scratch/ccp4/x2jo.hkl  \
<<'END'
#VERBOSE
TITLE   **  Marias Paris run - test 2 **

SORTFUN RESOL 20 4
LABI FP=FP  SIGFP=SIGFP
'END'

tab:
#!bin/csh -f
#####################################################3
#    tabling run: 
#####################################################3
#  rotate , shift coordinates and produce table:
#    xyzout is the rotated and shifted coordinates.
#
amore \
xyzin1  /f/scratch/ccp4/ortho_ins_ab.pdb \
xyzout1 /f/scratch/ccp4/ortho_ins_abrot.pdb \
TABLE1 /f/scratch/ccp4/ortho_ins_ab.tab \
<<'END'

 TITLE :  Table for MODEL;ins_pig_orth_T2_dim_lowph.pdb AB chains
#VERBOSE 
TABFUN  
MODEL 1 BREPLACE 0 BADD 3 
SAMPLE 1 RESO 4 SHANN 2 SCALE       4.0
#
#   If you give CRYSTAL information your XYZOUT will have the
# correct CRYST and SCALE1 cards for LSQKAB to use...
CRYSTAL ORTH 1 CELL 37.99 51.54 57.90 90 90 90
 
'END'
# 
#   Q. for Jorge: I am still not very clear about the relationship of 
#                 "dmin" and "shann" and box "scale" here.



#####################################################3
#    roting run: 
#####################################################3
rot:
#  choose cell for GENE which equals (min box + sphere radius + a bit)
#  It CANT be bigger than minimal_box*SCALE
#####################################################3
#####################################################3
#####################################################3
#!/bin/csh -f
# 
amore \
hklpck0 /f/scratch/ccp4/x2jo.hkl  \
CLMN0 /f/scratch/ccp4/x2jo.clmn  \
TABLE1 /f/scratch/ccp4/ortho_ins_ab.tab \
HKLPCK1 /f/scratch/ccp4/ortho_ins_ab.hkl \
CLMN1 /f/scratch/ccp4/ortho_ins_ab.clmn \
<<'END'
#
ROTFUN 
#VERB
 TITLE : Generate HKLPCK1 from MODEL FRAGMENT   1

GENE 1   RESO 8.0 4.0  CELL 80 75 65 90 90 90

CLMN CRYSTAL ORTH  1 FLIM 0.E0 1.E8   SHARP 0.0 RESO  8.0  4.0 -
SPHERE   15

CLMN MODEL 1  FLIM 0.E0 1.E8    RESO  8.0  4.0 SPHERE   15

ROTA  CROSS  MODEL 1  BESLIMI 6 120 STEP 2.5 NSR 0 0 -
 PKLIM 0.5  NPIC 50 BMAX 90

SHIFT        1  COM   0.41    18.15    17.62   -
                EULER   309.63   140.32   115.71
'END'
#

tra1:
#  Edit out the list of rotfun solutions and inset here.
#  This is the SLOW step, so go and make a cup of coffee.
#####################################################3
#    traing run:   NMOL = 1
#####################################################3
#!/bin/csh -f
# 
amore \
hklpck0 /f/scratch/ccp4/x2jo.hkl  \
TABLE1 /f/scratch/ccp4/ortho_ins_ab.tab \
<<'END'

TRAFUN CB   NMOL 1 RESO 8 4      -
 PKLIM 0.5  NPIC 10
#VERB
 TITLE : Translation function - one molecule
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0 


SOLUTIONRC   1   112.59    72.90   107.80  0.00000  0.00000  0.00000  9.7  0.0
SOLUTIONRC   1    38.04    73.93   160.84  0.00000  0.00000  0.00000  9.7  0.0
SOLUTIONRC   1    83.13   135.56   356.03  0.00000  0.00000  0.00000  8.2  0.0
SOLUTIONRC   1   175.22    85.43   124.58  0.00000  0.00000  0.00000  7.9  0.0
SOLUTIONRC   1    94.39    65.68   144.00  0.00000  0.00000  0.00000  7.8  0.0
SOLUTIONRC   1     1.44    89.54   318.36  0.00000  0.00000  0.00000  7.8  0.0
SOLUTIONRC   1    45.98    98.41   293.85  0.00000  0.00000  0.00000  7.4  0.0
SOLUTIONRC   1   139.15    66.74   310.47  0.00000  0.00000  0.00000  7.2  0.0
SOLUTIONRC   1   144.82    74.09   301.14  0.00000  0.00000  0.00000  7.2  0.0
SOLUTIONRC   1   134.35    74.56   106.50  0.00000  0.00000  0.00000  7.0  0.0
SOLUTIONRC   1   172.68    41.81    63.28  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1    52.94    83.98   179.66  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1    40.39   142.83   343.01  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1   148.65    38.62    24.14  0.00000  0.00000  0.00000  6.6  0.0
SOLUTIONRC   1   161.69   144.32   343.09  0.00000  0.00000  0.00000  6.5  0.0
SOLUTIONRC   1    97.56   105.46   253.98  0.00000  0.00000  0.00000  6.5  0.0
SOLUTIONRC   1    16.18   129.22   264.87  0.00000  0.00000  0.00000  6.4  0.0
SOLUTIONRC   1    -1.38    68.50    48.02  0.00000  0.00000  0.00000  6.3  0.0
SOLUTIONRC   1    80.65   141.62   185.96  0.00000  0.00000  0.00000  6.3  0.0
SOLUTIONRC   1    48.87    40.61    29.46  0.00000  0.00000  0.00000  6.2  0.0
SOLUTIONRC   1   150.57    70.36    18.66  0.00000  0.00000  0.00000  6.2  0.0
SOLUTIONRC   1    59.79   127.91   315.50  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    41.05    69.64   357.29  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    83.51   119.35   333.39  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    74.39    36.93   107.13  0.00000  0.00000  0.00000  6.0  0.0
SOLUTIONRC   1   117.81   104.52   326.45  0.00000  0.00000  0.00000  6.0  0.0
SOLUTIONRC   1    22.79   108.15   343.04  0.00000  0.00000  0.00000  6.0  0.0
SOLUTIONRC   1   127.20    54.98   296.22  0.00000  0.00000  0.00000  6.0  0.0
SOLUTIONRC   1    12.38    80.86   131.43  0.00000  0.00000  0.00000  6.0  0.0
'END'


# grep -i "solution " rot.log > a_file
#  I usually sort it on correlation coeff ( sort -r +8 -9  a_file > a_file1 )
#  then edit this to input into TRAFUN.
#  Choose the best solution from tra1 to FIX then run again with all 
#  solutions given to tra1..
#  Then 2nd best etc - till you get a clear amswer.
tra2:
#####################################################3
#    traing run:   NMOL = 2
#####################################################3
#!/bin/csh -f
amore \
hklpck0 /f/scratch/ccp4/x2jo.hkl  \
TABLE1 /f/scratch/ccp4/ortho_ins_ab.tab \
<<'END'
TRAFUN CB   NMOL 2 RESO 8 4     -
 PKLIM 0.5  NPIC 10
#VERB
 TITLE : Translation function - 2 mols together.
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0

SOLUTION FIX 1    38.04    73.93   160.84  0.29474  0.11207  0.25803 36.6 49.6
SOLUTIONRC   1   112.59    72.90   107.80  0.00000  0.00000  0.00000 19.8 54.3
SOLUTIONRC   1    83.13   135.56   356.03  0.00000  0.00000  0.00000  8.2  0.0
SOLUTIONRC   1   175.22    85.43   124.58  0.00000  0.00000  0.00000  7.9  0.0
SOLUTIONRC   1    94.39    65.68   144.00  0.00000  0.00000  0.00000  7.8  0.0
SOLUTIONRC   1     1.44    89.54   318.36  0.00000  0.00000  0.00000  7.8  0.0
SOLUTIONRC   1    45.98    98.41   293.85  0.00000  0.00000  0.00000  7.4  0.0
SOLUTIONRC   1   139.15    66.74   310.47  0.00000  0.00000  0.00000  7.2  0.0
SOLUTIONRC   1   144.82    74.09   301.14  0.00000  0.00000  0.00000  7.2  0.0
SOLUTIONRC   1   134.35    74.56   106.50  0.00000  0.00000  0.00000  7.0  0.0
SOLUTIONRC   1   172.68    41.81    63.28  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1    52.94    83.98   179.66  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1    40.39   142.83   343.01  0.00000  0.00000  0.00000  6.7  0.0
SOLUTIONRC   1   148.65    38.62    24.14  0.00000  0.00000  0.00000  6.6  0.0
SOLUTIONRC   1   161.69   144.32   343.09  0.00000  0.00000  0.00000  6.5  0.0
SOLUTIONRC   1    97.56   105.46   253.98  0.00000  0.00000  0.00000  6.5  0.0
SOLUTIONRC   1    16.18   129.22   264.87  0.00000  0.00000  0.00000  6.4  0.0
SOLUTIONRC   1    -1.38    68.50    48.02  0.00000  0.00000  0.00000  6.3  0.0
SOLUTIONRC   1    80.65   141.62   185.96  0.00000  0.00000  0.00000  6.3  0.0
SOLUTIONRC   1    48.87    40.61    29.46  0.00000  0.00000  0.00000  6.2  0.0
SOLUTIONRC   1   150.57    70.36    18.66  0.00000  0.00000  0.00000  6.2  0.0
SOLUTIONRC   1    59.79   127.91   315.50  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    41.05    69.64   357.29  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    83.51   119.35   333.39  0.00000  0.00000  0.00000  6.1  0.0
SOLUTIONRC   1    74.39    36.93   107.13  0.00000  0.00000  0.00000  6.0  0.0
SOLUTIONRC   1   117.81   104.52   326.45  0.00000  0.00000  0.00000  6.0  0.0



'END'

#  On a unix machine 
#  for one molecule:
#  grep -i "solution  1" tra2.log > soln_list
#  sort -r +8 -9 soln_list > aa
#  then insert the sorted list of solutions into fit.
#  Fr two molecules you will have to be cleverer..
tab2_fit2:

#####################################################3
#    tabling run at higher resolution:
#####################################################3
#  rotate , shift coordinates and produce table:
#    xyzout is the rotated and shifted coordinates.
#
amore \
xyzin1  /f/scratch/ccp4/ortho_ins_ab.pdb \
xyzout1 /f/scratch/ccp4/ortho_ins_abrot.pdb \
TABLE1 /f/scratch/ccp4/ortho_ins_ab2.5.tab \
<<'END'

 TITLE :  Table for MODEL;ins_pig_orth_T2_dim_lowph.pdb AB chains
#VERBOSE
TABFUN  
MODEL 1 BREPLACE 0 BADD 3
SAMPLE 1 RESO 2.5 SHANN 2 SCALE       4.0
#
#   If you give CRYSTAL information your XYZOUT will have the
# correct CRYST and SCALE1 cards for LSQKAB to use...
CRYSTAL ORTH 1 CELL 37.99 51.54 57.90 90 90 90

'END'
#
fit:
#!/bin/csh -f
#####################################################3
#    /fiting run:   Experiment with 2 different models
#####################################################3
#   Test fitting at 2.5A using TABLE2   and at 4.0A using TABLE1
#
# Could rerun FITFUN with resolution limits 20 2.5 perhaps?

#!/bin/csh -f
amore \
hklpck0 /f/scratch/ccp4/x2jo.hkl  \
TABLE2 /f/scratch/ccp4/ortho_ins_ab2.5.tab \
TABLE1 /f/scratch/ccp4/ortho_ins_ab.tab \
<<'END'

FITFUN CB  NMOL 2  RESO 20 4  ITER 10 CONV   1.E-3
 title *** Marias   structure *** 
#VERBOSE
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0

REFSOL   AL     BE   GA     X   Y    Z   BF 

#   Fiting will be done with PAIRS of solutions since NMOL = 2

 SOLUTIONT   1    38.04    73.93   160.84  0.29474  0.11207  0.25803 50.6 44.6
 SOLUTIONT   1    74.39    36.93   107.13  0.86640  0.66928  0.64541 50.6 44.6

 SOLUTIONT   2    38.04    73.93   160.84  0.29474  0.11207  0.25803 50.6 44.6
 SOLUTIONT   2    74.39    36.93   107.13  0.86640  0.66928  0.64541 50.6 44.6


SHIFT        1  COM   0.41    18.15    17.62   -
                EULER   309.63   140.32   115.71
SHIFT        2  COM   0.41    18.15    17.62   -
                EULER   309.63   140.32   115.71
'END'
exit
lsq:
#!/bin/csh -f
lsqkab			\
WORKCD /f/scratch/ccp4/ortho_ins_abrot.pdb \
LSQOP $SCRATCH/ins1.pdb	\
<< 'END-lsqkab' 
title Rotating model by amore angles
ROTAT EULER 36.38    75.12   162.78
TRAN FRAC 0.29461  0.11458  0.25883 
output  XYZ
end
'END-lsqkab'

