#!/bin/csh -f
#
#
#
#
#goto lsq
# Will need to cat the two molecules together.
#goto shift
goto fit
goto tab

tab:
#!bin/csh -f
#####################################################3
#    tabling run: 
#####################################################3
#  rotate , shift coordinates and produce table:
#    xyzout is the rotated and shifted coordinates.
#
amore \
xyzin1  $SCRATCH/adh/ssmonomer1.pdb \
xyzout1  /f/scratch/ccp4/adh/ssmonomer1_rot.pdb \
table1  /f/scratch/ccp4/adh/ssmonomer1_rot.tab \
<<'END'

 TITLE :  Table for MODEL;ssmonomer2
#VERBOSE 
TABFUN  
MODEL 1 BREPLACE 0 BADD 0 
SAMPLE 1 TMIN 4 SHANN 2 SCALE       4.0
 
'END'
# 
#!bin/csh -f
#####################################################3
#    tabling run: 
#####################################################3
#  rotate , shift coordinates and produce table:
#    xyzout is the rotated and shifted coordinates.
#
amore \
xyzin1  $SCRATCH/adh/ssmonomer2.pdb \
xyzout1  /f/scratch/ccp4/adh/ssmonomer2_rot.pdb \
table1  /f/scratch/ccp4/adh/ssmonomer2_rot.tab \
<<'END'

 TITLE :  Table for MODEL;ssmonomer2
#VERBOSE 
TABFUN  
MODEL 1 BREPLACE 0 BADD 0 
SAMPLE 1 TMIN 4 SHANN 2 SCALE       4.0
 
'END'
# 
#   Q. for Jorge: I am still not very clear about the relationship of 
#                 "dmin" and "shann" and box "scale" here.


exit

#   Try to decide how to fit this rotated monomer fragment 
#   onto our favorite solution.
#!/bin/csh -f
#!/bin/csh -f
# monomer1 has residues 1-177 324-374
lsqkab			\
REFRCD 8adh_dim_soln.pdb \
WORKCD ssmonomer1_rot.pdb \
<< 'END-lsqkab' 
title  rot 
FIT WRES MAIN 11 to 176 WCHAIN A
MATCH RRES MAIN 11 to 176 RCHAIN A
FIT WRES MAIN 324 to 374 WCHAIN A
MATCH RRES MAIN 324 to 374 RCHAIN A
output  RMS 
end
'END-lsqkab'
#

# monomer2 has residues 178-323
lsqkab			\
REFRCD 8adh_dim_soln.pdb \
WORKCD ssmonomer2_rot.pdb \
<< 'END-lsqkab' 
title  rot 
FIT WRES MAIN 177 to 323 WCHAIN A
MATCH RRES MAIN 177 to 323 RCHAIN A
output  RMS 
end
'END-lsqkab'
#
#
# Will need to turn translations of lsqkab into fractional ones.
fit:
#!/bin/csh -f
#####################################################3
#    /fiting run: 
#####################################################3
#

#!/bin/csh -f
amore \
hklpck0 /f/scratch/ccp4/adh/adh_apo_2_amore2.hkl  \
table1  /f/scratch/ccp4/adh/ssmonomer1_rot.tab \
table2  /f/scratch/ccp4/adh/ssmonomer2_rot.tab \
<<'END'
FITFUN CB  NMOL 2  RESO 15 4  ITER 10 CONV   1.E-3
 title *** Marias   structure *** 
#VERBOSE
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0

REFSOL   AL     BE   GA     X  Y    Z   BF 

SOLUTION 1  36.20010 -135.08910  41.21732 0.0809  0.5085 0.06963 20 50
SOLUTION 2  9.88142 118.67628 168.67380  0.11374 0.71804 0.01229 20 50



'END'
exit

shift:

#!/bin/csh -f
amore \
hklpck0 /f/scratch/ccp4/adh/adh_apo_2_amore2.hkl  \
table1  /f/scratch/ccp4/adh/ssdimer_rot.tab \
FITFUN fitfun.9 \
<<'END'
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0


SOLUTION    1    65.45    58.23     8.55  0.56937  0.46560  0.05820 20.7 55.9
SOLUTION    1    65.86    48.89   203.07  0.18188  0.78870  0.06643 20.2 55.6
SOLUTION    1    53.84    68.81   274.60  0.06206  0.48132  0.27175 21.8 55.4
SOLUTION    1    11.77    45.28   308.32  0.05933  0.49391  0.30628 21.3 55.6
SOLUTION    1    28.61    53.47   155.62  0.60342  0.55872  0.34781 20.6 56.1
SOLUTION    1    56.83    66.90   275.76  0.88250  0.13548  0.42433 20.8 56.1
SOLUTION    1    15.87    59.57    61.23  0.90262  0.66828  0.34679 20.3 56.1
SOLUTION    1    -1.25    86.28   100.99  0.09673  0.74586  0.12235 25.8 56.2


SHIFT 1 COM  0.00    15.30    45.42 EULER 357.34    90.00   270.00


'END'
exit



lsq:
#!/bin/csh -f
lsqkab			\
workcd  /f/scratch/ccp4/adh/ssdimer.pdb \
LSQOP $SCRATCH/adh/ssdimer_soln.pdb  \
<< 'END-lsqkab' 
title Rotating model by amore angles
ROTAT EULER  89.29    81.69   356.24   
TRAN ORTh  26.95    49.08     8.91 
output  XYZ
end
'END-lsqkab'
exit
