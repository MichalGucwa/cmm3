#!/bin/csh -f
#   A simple example.
goto lsq
goto shift
#goto fit
goto fit2
#  Done at 2.5A  - need to recalculate TABFUN
goto tra1
#  Search for single molecules - only one good solution.
goto rot
#goto tab
#####################################################3
#    sorting run: 
#####################################################3
#  mtz file contains cell and symmetry.
#
amore \
hklin  egv_ct_tru.mtz \
hklpck0 /f/scratch/davies/egv_ct.hkl \
<<'END'
#VERBOSE
TITLE  egv ct complex frozen 

SORTFUN RESOL 8 4.0
LABI FP=F_ct  SIGFP=SIGF_ct
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
xyzin1  egv.pdb \
xyzout1 /f/scratch/davies/egv_rot.pdb       \
TABLE1 /f/scratch/davies/egv_rot.tab    \
<<'END'

 TITLE :  Table for egv ct complex 
#VERBOSE 
TABFUN  
CRYSTAL ORTH 1 CELL ???????
MODEL 1 BREPLACE 0 BADD 3 
SAMPLE 1 TMIN 4 SHANN 2 SCALE       4.0
 
'END'
# 
#   Q. for Jorge: I am still not very clear about the relationship of 
#                 "dmin" and "shann" and box "scale" here.



exit
#####################################################3
#    roting run: 
#####################################################3
rot:
#  choose cell for GENE which equals (min box + sphere radius +...)
#!/bin/csh -f
# 
amore \
hklpck0 /f/scratch/davies/egv_ct.hkl \
CLMN0 /f/scratch/davies/egv_ct.clmn \

TABLE1 /f/scratch/davies/egv_rot.tab    \
HKLPCK1 /f/scratch/davies/egv_rot.hkl    \
CLMN1 /f/scratch/davies/egv_rot.clmn    \
<<'END'
#
ROTFUN 
#VERB
 TITLE : Generate HKLPCK1 from MODEL FRAGMENT   1

GENE 1   RESO 8.00 4.0  CELL 70 70 60 90 90 90  

CLMN CRYSTAL ORTH  1 FLIM 0.E0 1.E8   SHARP 0.0 RESO  8.0  4.0 -
SPHERE  0.0 17 

CLMN MODEL 1  FLIM 0.E0 1.E8    RESO  8.0   4.0 SPHERE  0.0 17

ROTA  CROSS  MODEL 1  BESLIMI 6 120 STEP 2.5 NSR 0 0 -
 PKLIM 0.5  NPIC 20  BMAX 180

'END'
#
#   Q. for Jorge: I am still not very clear about the relationship of 
#                 "bessel limits" and "dang" here.
#   Q2.   No idea about NSR values.

#   Q3.   PKLIM?  DELTA??? - seems very small..
exit

tra1:
#####################################################3
#    traing run:   NMOL = 1
#####################################################3
#!/bin/csh -f
# 
amore \
hklpck0 /f/scratch/davies/egv_ct.hkl \
TABLE1 /f/scratch/davies/egv_rot.tab    \
TRAFUN trafun.9 \
<<'END'

TRAFUN CB   NMOL 1 RESO 8 4     -
 PKLIM 0.5  NPIC 5  
#VERB
 TITLE : Translation function - one molecule
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0 
SOLUTION     1   269.98    92.86   285.37  0.00000  0.00000  0.00000 46.0  0.0
SOLUTION     1   270.02    87.14   105.37  0.00000  0.00000  0.00000 46.0  0.0
'END'

#   Qs.  TMIN SHANN??
#   Comment SOLUTION stuff cut out of LOG file. Not sure that it is worth
#           writing fort.9 and having all the oic stuff. Just as easy with
#           an editor.


exit
fit:

#####################################################3
#    tabling run at higher resolution for rigid body fitting:
#####################################################3
#  rotate , shift coordinates and produce table:
#    xyzout is the rotated and shifted coordinates.
#
amore \
xyzin1  egv.pdb \
xyzout1 /f/scratch/davies/egv_rot.pdb       \
TABLE1 /f/scratch/davies/egv_rot_3.tab      \
TABLOUT tablout.9 \
<<'END'

 TITLE :  
#VERBOSE
TABFUN  
MODEL 1 BREPLACE 0 BADD 3
SAMPLE 1 TMIN 3.0 SHANN 2 SCALE       4.0

'END'
#
fit2:
#!/bin/csh -f
#####################################################3
#    /fiting run: 
#####################################################3
#

#!/bin/csh -f
amore \
hklpck0 /f/scratch/davies/egv_ct.hkl \
TABLE1 /f/scratch/davies/egv_rot_3.tab      \
FITFUN fitfun.9 \
<<'END'
FITFUN CB  NMOL 1  RESO 8 3   ITER 10 CONV   1.E-3
 title *** Marias   structure *** 
#VERBOSE
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0

REFSOL   AL     BE   GA     X       Z   BF 


SOLUTION  1   270.02    87.14   105.37  0.38365  0.00000  0.18876 57.6 38.5

SHIFT 1 COM        -4.27    19.15    34.19 -
        EULER     274.19   105.50    55.47

'END'
exit
shift:
#!/bin/csh -f
#####################################################3
#    /shifting run: 
#####################################################3
#

#!/bin/csh -f
amore \
hklpck0 /f/scratch/davies/egv_ct.hkl \
<<'END'
CRYSTAL ORTH  1 FLIMI 0.E0 1.E8   SHARP 0.0


SOLUTION  1  271.64    85.49   106.20  0.38624  0.00000  0.18524 69.8 31.4 

SHIFT 1 COM        -4.27    19.15    34.19 -
        EULER     274.19   105.50    55.47

'END'
exit
#####################################################3
#    lsqkab to rotate original model by output of shifting step.
#####################################################3
lsq:
#!/bin/csh -f
lsqkab			\
WORKCD egv.pdb \
LSQOP $SCRATCH/egv_ct.pdb	\
<< 'END-lsqkab' 
title Rotating model by amore angles
ROTATE EULER 31.84   157.14   172.07 
TRAN ORTH  -7.70    10.38    39.70
output  XYZ
end
'END-lsqkab'
#####################################################3
#    lsqkab to rotate model outut by tabling using output of fiting.
#####################################################3

#!/bin/csh -f
# Dont forget to CHANGE PDB HEADER.
#
coord_conv    				\
xyzin /f/scratch/davies/egv_rot.pdb       \
xyzout /f/scratch/davies/egv_rot2.pdb       \
<< 'END-convrnxp' 
INPUT PDB ORTH 1 
OUTPUT PDB ORTH 1
cell  41.63   51.62   44.90   90.00  114.28   90.00
END
'END-convrnxp'

#!/bin/csh -f
lsqkab                  \
WORKCD $SCRATCH/egv_rot2.pdb \
LSQOP $SCRATCH/egv_ct1.pdb       \
<< 'END-lsqkab'
title Rotating model by amore angles
ROTATE EULER 271.64    85.49   106.20
TRAN FRAC 0.38624  0.00000  0.18524
output  XYZ
end
'END-lsqkab'
