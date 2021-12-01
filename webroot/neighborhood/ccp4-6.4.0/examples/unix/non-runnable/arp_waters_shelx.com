#!/bin/csh -f
#
# ====================================================================
#
#                         This is the com-file 
#            to run RESTRAINED ARP_WARP Version 5 with SHELX
#
#                 The user needs to change settings and 
#                            the inputs to
#
#                 ARP     (REMOVE, FIND, FDISTANCE) 
#
# Some recomendations for shelx.ins file:
#   CGLS 2. Use of more cycles within shelx lowers arp contribution
#   CELL, LATT/SYMM and SHEL should be consistent with 
#     cell, symm and resol in the script
#   WPDB -1
#   LIST 3
#   ISOR and CONN include O1 > last as the number of waters changes
#   Waters should have RESI 0
#
# Prepform and prepshel are format specific and use standard shelx
# format only
#
#            Column label assignments should be edited if necessary
#
#            See ARP, CCP4 and SHELX documentations for more details
#
# ====================================================================
#
set name   = 'test_'
set last   =   1
set cycles =  10
set count  =   0
#
set title  = 'test'
set resol  = '20.0 1.0'
set cell   = '64.200   77.800   38.280  90.00  90.00  90.00'
#
# Grids for SF and FFT
set grid   = '280 128 140'
#
# Asym. unit limits compatible with arp
set xyzlim = '0 1 0 1 0 0.25'
#
# True space group
set symm   = '19'
#
# Space group for SF and FFT (if P1 - data should be extended to P1)
set sfsg   = '19'
#
#
while ($count != $cycles)
@ next = $last + 1
#
#
shelxl97 ${nam}${last}
#
prepform:
#
prepform HKLIN ${name}${last}.fcf \
         HKLOUT ${name}${next}.form \
         XYZIN ${name}${last}.pdb  XYZOUT ${name}${next}.brk
#
#
f2mtz hklin ${name}${next}.form hklout ${name}${next}.mtz << e
TITLE   ${title}
CELL    ${cell}
SYMM    ${symm}
LABOUT H K L FP SIGFP FC PHIC
CTYP   H H H F  Q     F  P
END
e
#
#
cad HKLIN1 ${name}${next}.mtz  HKLOUT ${name}${next}.cad << e
TITLE  AFTER CAD
OUTLIM SPACEGROUP ${symm}
RESOLUTION OVERALL ${resol}
LABIN  FILE 1 E1=FP E2=SIGFP E3=FC E4=PHIC
LABOUT FILE 1 E1=FP E2=SIGFP E3=FC E4=PHIC
CTYP   FILE 1 E1=F  E2=Q     E3=F  E4=P
END
e
#
#
fft HKLIN ${name}${next}.mtz MAPOUT ${name}${next}_32.map << e
TITLE            3FO-2FC 
SCALE            F1 3 0 F2 2 0
RESOLUTION       ${resol}
FFTSYMMETRY      ${sfsg}
GRID             ${grid}
BINMAPOUT
LABIN            F1=FP SIG1=SIGFP F2=FC SIG2=SIGFP PHI=PHIC
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
fft HKLIN ${name}${next}.mtz MAPOUT ${name}${next}_11.map << e
TITLE            1FO-1FC 
RESOLUTION       ${resol}
FFTSYMMETRY      ${sfsg}
GRID             ${grid}
BINMAPOUT
LABIN            F1=FP SIG1=SIGFP F2=FC SIG2=SIGFP PHIC
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
# The threshold (CUTSIGMA) value for REMO ... can roughly be estimated as:
# ( 12 * (r.m.s.Fo-Fc map) - VF000 ) / (r.m.s.3Fo-2Fc map)
#
# ( 12 * (r.m.s.Fo-Fc map) - VF000 ) is typically around 0.4 e/A**3
#
arp_waters XYZIN ${name}${next}.brk \
 MAPIN1 ${name}${next}_32.ext \
 MAPIN2 ${name}${next}_11.ext XYZOUT TMP.RES << e
MODE UPDATE WATERS
CELL       ${cell}
REFINE     WATERS
SYMM       ${symm}
RESOLUTION ${resol}
FIND       ATOMS 10 CHAIN W CUTSIGMA AUTO
REMOVE     ATOMS 10 CUTSIGMA 1.0 MERGE 2.2
END
e
#
#
/bin/rm ${nam}${next}_32.ext
/bin/rm ${nam}${next}_11.ext
/bin/rm ${nam}${next}.mtz
/bin/rm ${nam}${next}.form
#/bin/rm ${nam}${last}.fcf
#
#
prepshel XYZIN1 ${name}${last}.res XYZIN2 TMP.RES INS ${name}${next}.ins
#
/bin/rm TMP.RES
mv ${name}${last}.hkl  ${name}${next}.hkl
#
@ last++
@ count++
end
