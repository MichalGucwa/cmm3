#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$

{[IfSet $TITLE] } title $TITLE
#LABELLINE labin "FP SIGFP"
1 labin
IF {[StringSame $REVISE_INPUT MADDS]}
  LOOP n 1 $N_WAVELENGTHS
  LABELLINE - "FPH SIGFPH" $n
  LABELLINE - "DPH SIGDPH" $n
  ENDLOOP
ELSE
LOOP n 1 $N_WAVELENGTHS 
  LABELLINE - "FPHp SIGFPHp"  $n
  LABELLINE - "FPHm SIGFPHm"  $n
ENDLOOP
ENDIF
LABELLINE labout "FM SIGFM"
LOOP n 1 $N_WAVELENGTHS
  LABELLINE - "FPHMp SIGFPHMp" $n 
  LABELLINE - "FPHMm SIGFPHMm" $n
ENDLOOP

LOOP n 1 $N_WAVELENGTHS
  1 WAVE $n 
  - {[IfSet $LAMBDA($n)]} lam $LAMBDA($n) 
  - {[IfSet $FPRIME($n) ]} fpr $FPRIME($n)
  - {[IfSet $FDPRIME($n) ]} fdp $FDPRIME($n)
ENDLOOP

$USE_REVISE_RESO_CUTOFF reso $REVISE_RESOLUTION_MAX

{ [IfSet $RISO] || [IfSet $RANO] || [IfSet $SIGM] } excl
 - { [IfSet $RISO]} riso $RISO
 - { [IfSet $RANO]} rano $RANO
 - { [IfSet $SIGM]} sigm $SIGM
