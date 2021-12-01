#!/bin/sh
#   FFT has many roles. This is a very simple example.
#  See documentation.

if false;  then
#  A 3fo - 2fc map using sfall output.
#
fft \
   HKLIN  $CEXAM/toxd/toxd_sf.mtz \
   MAPOUT  $CCP4_SCR/toxd_3fo2fc.map \
   << END
resol 100 2.5
SCALE F1 3.0 0
SCALE F2 2.0 0
! LIST 100 ! uncomment this to get input FFT terms (fftkw.abcoeffs)
fftspg 19
title  2.5A 3fo2fc FOURIER toxd  - cycle 10
grid 88 144 80
xyzlim 0 87 0 143 0 40
LABIN F1=FTOXD3  SIG1=SIGFTOXD3 F2=FC PHI=AC
end
END

fi
#
#  Patterson Example
#

fft \
   HKLIN  $CEXAM/toxd/toxd.mtz \
   MAPOUT  $CCP4_SCR/toxd_aupatt.map \
   << END
PATT
resol 100 2.5
! LIST 100 ! uncomment this to get input FFT terms (fftkw.abcoeffs)
EXCLUD SIG1 4 SIG2 4 DIFF 2800
fftspg 47   ! Orignal space group + no trans + center of sym
titl  2.5A AU - NAT patterson - excluding 4 sig , and Diso > 180.
grid 88 144 80
xyzlim 0 44 0 72 0 40
binmapout
LABI F1=FAU20 SIG1=SIGFAU20 F2=FTOXD3  SIG2=SIGFTOXD3
end
END
#
