#!/bin/csh -f
#
# ====================================================================
#
#                         This is the com-file 
# to run RESTRAINED/UNRESTRAINED ARP/wARP Version 5 with SFALL/PROTIN/PROLSQ
#
#       with (RESTRAINED ARP only) or without hydrogen contribution
#
#                    with or without Rfree monitoring
#
#        It was updated from using ARP version 4 on the 10-11-1999
#
#                 The user needs to change settings and 
#                            the inputs to
#
#    PROTIN  (CHNNAM, CHNTYP)                        RESTRAINED MODE
#    PROLSQ  (ORIGIN, DAMPING, MATRIX, TEMPERATURE)  RESTRAINED MODE
#    ARP     (REMOVE, FIND, FDISTANCE)        UNRESTRAINED or RESTRAINED MODE
#
#             Column label assignments, including FreeR_flag,
#                      can be edited if necessary
#
#        If Rfree is not used: FREE=FreeR_flag should be edited out
#        If Rfree is used: the reflection file (independent part of
#                          the reciprocal lattice) should be passed
#                          through FREERFLAG program from the CCP4
#
#          Other parameters are usually not necessary to be changed,
#               but possible, like FORM (in SFALL), etc.
#
#            See ARP and CCP4 documentations for more details
#
# ====================================================================
#
set name   = 'test_'
set last   =   0
set cycles =   5
set count  =   0
set data   = './test_p1.cad'
#
set title  = 'test'
set resol  = '10.0 1.5'
set cell   = '105.500   47.900   52.600  90.00 115.80  90.00'
#
set labin       = 'FP=FP SIGFP=SIGFP FREE=FreeR_flag'
set labout      = 'FC=FC PHIC=ALPHA'
set labinh      = 'FP=FP SIGFP=SIGFP FREE=FreeR_flag FPART=FCH PHIP=ALPHAH'
set labouth     = 'FC=FCH PHIC=ALPHAH'
set labinrstats = 'FP=FP SIGFP=SIGFP FC=FC PHIC=ALPHA FREE=FreeR_flag'
set labinfft32  = 'F1=FP SIG1=SIGFP F2=FC SIG2=SIGFP PHI=ALPHA FREE=FreeR_flag'
set labinfft11  = 'F1=FP SIG1=SIGFP F2=FC SIG2=SIGFP PHI=ALPHA FREE=FreeR_flag'
#
# Refinement mode (restrained or unrestrained)
set mode   = 'restrained'
#
# Refinement mode (hydrogens or nohydrogens)
set modeh  = 'hydrogens'
#
# Grids for SF and FFT
set grid   = '280 128 140'
#
# Asym. unit limits compatible with arp
set xyzlim = '0 0.5 0 1 0 0.5'
#
# True space group
set symm   = '5'
#
# Space group for SF and FFT (if P1 - data should be extended to P1)
set sfsg   = 'P1'
#
#
while ($count != $cycles)
@ next = $last + 1
#
#
if (${mode} == 'restrained') then
#
echo "##############################################"
echo     RESTRAINED REFINEMENT SFALL/PROTIN/PROLSQ
echo "##############################################"
#
if (${modeh} == 'hydrogens') then
#
echo "##############################################"
echo         WITH CONTRIBUTION FROM HYDROGENS
echo "##############################################"
#
hgen xyzin ${name}${last}.brk xyzout hyd.brk << e
Y
e
#
sfall HKLIN $data XYZIN hyd.brk HKLOUT hyd.mtz << e
TITL ${title}
MODE SFCALC HKLIN XYZIN
GRID ${grid}
CELL ${cell}
RESO ${resol}
RSCB ${resol}
BINS 40
VDWR 3.0
NOSCAL
SFSG ${sfsg}
FORM Fe+3
BRESET 2.0
STEP  1.0 1.0 0.3
LABIN ${labin}
LABO  ${labouth}
e
#
sfall HKLIN hyd.mtz XYZIN ${name}${last}.brk << e
TITL ${title}
MODE SFREF XYZB RESTRAINED
GRID ${grid}
CELL ${cell}
RESO ${resol}
RSCB ${resol}
BINS 40
VDWR 3.0
RATI 3.0
SFSG ${sfsg}
FORM Fe+3
BRESET 2.0
STEP  0.50 0.50 0.3
LABIN ${labinh}
e
#
/bin/rm hyd.brk
/bin/rm hyd.mtz
#
else
#
sfall HKLIN $data XYZIN ${name}${last}.brk << e
TITL ${title}
MODE SFREF XYZB RESTRAINED
GRID ${grid}
CELL ${cell}
RESO ${resol}
RSCB ${resol}
BINS 40
VDWR 3.0
RATI 3.0
SFSG ${sfsg}
!FORM Fe+3
BRESET 2.0
STEP  0.50 0.50 0.3
LABIN ${labin}
e
#
endif
#
protin XYZIN ${name}${last}.brk << e
CHNNAM ID A CHNTYP 1
CHNNAM ID W CHNTYP 2
CHNTYP 1 NTERM   1 GLY 3 CTERM 153 ALA 2 MULPLN 2 154 155
CHNTYP 2 WAT
SYMMETRY ${symm}
LIST FEW
TITLE  ${title}
END
e
#
prolsq XYZIN ${name}${last}.brk XYZOUT ${name}${next}.brk << e
TITLE  ${title}
CELL   ${cell}
ORIGIN   0 1 0 
OUTPUT XYZ
DAMPING PRESELECT 0.8 0.8
MATRIX 1.0
BATOM
DISTANCE    1.0 0.02 0.02 0.03 0.05 1.0
TEMPERATURE 1.0 2.0 3.0 3.0 4.0 1.0
MONITOR TORSION 2.0 DISTANCE 2.0 PLANE 2.5 VANDERWAAL 1.0 SHIFT 1.0
END
e
#
/bin/rm PROTCOUNTS
/bin/rm PROTOUT
/bin/rm GRADMAT
#
else
#
echo "##############################################"
echo          UNRESTRAINED REFINEMENT SFALL
echo "##############################################"
#
sfall HKLIN $data XYZIN ${name}${last}.brk XYZOUT ${name}${next}.brk << e
TITL ${title}
MODE SFREF XYZB UNRESTRAINED
GRID ${grid}
CELL ${cell}
RESO ${resol}
RSCB ${resol}
BINS 40
VDWR 3.0
RATI 3.0
SFSG ${sfsg}
!FORM Fe+3
BRESET 2.0
STEP  0.50 0.50 0.3
RMSSHIFT XYZ 0.2 B 30.0
LABIN ${labin}
e
#
#
endif
#
#
sfcalc:
sfall HKLIN $data XYZIN ${name}${next}.brk HKLOUT ${name}${next}.mtz << e
TITL ${title}
MODE SFCALC HKLIN XYZIN
GRID ${grid}
CELL ${cell}
RESO ${resol}
RSCB ${resol}
BINS 40
VDWR 3.0
SFSG ${sfsg}
!FORM Fe+3
BRESET 2.0
STEP  1.0 1.0 0.3
LABIN ${labin}
LABO  ${labout}
e
#
#
scale:
rstats HKLIN ${name}${next}.mtz HKLOUT ${name}${next}_sc.mtz << e
TITLE           ${title}
RESOLUTION      ${resol}
CYCLES          5
PRINT           ALL
LABIN           ${labinrstats}
OUTPUT          ASIN
PROCESS         FOBC
e
#
#
fft HKLIN ${name}${next}_sc.mtz MAPOUT ${name}${next}_32.map << e
TITLE            3FO-2FC 
SCALE            F1 3 0 F2 2 0
RESOLUTION       ${resol}
FFTSYMMETRY      ${sfsg}
GRID             ${grid}
BINMAPOUT
LABIN            ${labinfft32}
END
e
#
#
extend MAPIN ${name}${next}_32.map MAPOUT ${name}${next}_32.ext << e
XYZLIM ${xyzlim}
END
e
#
#
/bin/rm ${name}${next}_32.map
#
#
fft HKLIN ${name}${next}_sc.mtz MAPOUT ${name}${next}_11.map << e
TITLE            1FO-1FC 
RESOLUTION       ${resol}
FFTSYMMETRY      ${sfsg}
GRID             ${grid}
BINMAPOUT
LABIN            ${labinfft11}
END
e
#
#
extend MAPIN ${name}${next}_11.map MAPOUT ${name}${next}_11.ext << e
XYZLIM ${xyzlim}
END
e
#
#
/bin/rm ${name}${next}_11.map
#
if (${mode} == 'restrained') then
#
# The threshold value for REMO ... CUTSIGMA can be roughly estimated as:
# ( 12 * (r.m.s.Fo-Fc map) - VF000 ) / (r.m.s.3Fo-2Fc map)
#
# ( 12 * (r.m.s.Fo-Fc map) - VF000 ) is typically around 0.4 e/A**3
#
arp_waters XYZIN ${name}${next}.brk \
 MAPIN1 ${name}${next}_32.ext \
 MAPIN2 ${name}${next}_11.ext XYZOUT TMP.RES << e
MODE       UPDATE WATERS
CELL       ${cell}
SYMM       ${symm}
REMOVE     ATOMS 30 ANALYSE WATERS CUTSIGMA 0.5 MERGE 2.2
FIND       ATOMS 30 CHAIN W CUTSIGMA AUTO
REFINE     WATERS
RESOLUTION ${resol}
END
e
#
else
#
#
arp_waters XYZIN ${name}${next}.brk \
 MAPIN1 ${name}${next}_32.ext \
 MAPIN2 ${name}${next}_11.ext XYZOUT TMP.RES << e
MODE       UPDATE ALLATOMS
CELL       ${cell}
SYMM       ${symm}
REMOVE     ATOMS 30 ANALYSE ALLATOMS CUTSIGMA 1.0 MERGE 0.6
FIND       ATOMS 30 CHAIN W CUTSIGMA 4.0
RESOLUTION ${resol}
END
e
#
#
endif
#
#
/bin/rm ${name}${next}_sc.mtz
/bin/rm ${name}${next}_32.ext
/bin/rm ${name}${next}_11.ext
/bin/rm ${name}${next}.brk
mv TMP.RES ${name}${next}.brk
#
#
@ last++
@ count++
end

