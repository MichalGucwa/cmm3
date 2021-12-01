#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]} title $TITLE
$VERBOSE verbose

1 rotfun

IF $ROTFUN_GENERATE
  1 generate 1
  - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
  - {[IfSet $MODEL_CELL_1]} cell_model $MODEL_CELL_1 $MODEL_CELL_2 $MODEL_CELL_3
ENDIF

$ROTFUN_CLMN_CRYSTAL clmn crystal 
  - {[IfSet $CRYSTAL_ORTH]}  orth $CRYSTAL_ORTH 
  - {[IfSet $CRYSTAL_FMIN ]} flim $CRYSTAL_FMIN $CRYSTAL_FMAX
  - {[IfSet $CRYSTAL_BADD ]} sharp $CRYSTAL_BADD
  - 1  resolution $RESOLUTION_MIN $RESOLUTION_MAX
  -  {[IfSet $CRYSTAL_IRMAX ]} sphere $CRYSTAL_IRMAX

IF $ROTFUN_CLMN_MODEL 
 1 clmn 
   - { [regexp SELF $ROTFUN_ROTATE_MODE] } crystal | model 1
   - {[IfSet $MODEL_FMIN]} flim $MODEL_FMIN $MODEL_FMAX
   - {[IfSet  $MODEL_BADD]} sharp $MODEL_BADD
   - {[IfSet $RESOLUTION_MIN]} resolution $RESOLUTION_MIN $RESOLUTION_MAX
   - {[IfSet $MODEL_IRMAX ]} sphere $MODEL_IRMAX
ENDIF

IF $ROTFUN_ROTATE 
  1 rotate $ROTFUN_ROTATE_MODE
    - { [regexp CROSS $ROTFUN_ROTATE_MODE] } model 1 pklim $ROTFUN_PKLIMC
    - { [regexp SELF $ROTFUN_ROTATE_MODE] } pklim $ROTFUN_PKLIMS
    - {[IfSet $ROTFUN_NPIC]} npic $ROTFUN_NPIC
    - $BESLIM beslim $BESLIM_MIN $BESLIM_MAX
    - {[IfSet $ROTFUN_STEP]} step $ROTFUN_STEP
    - {[IfSet $ROTFUN_BMAX]} bmax $ROTFUN_BMAX
    - {[IfSet $ROTFUN_NSR1R]} nsr $ROTFUN_NSR1R $ROTFUN_NSR2R
ENDIF

$SHIFT shift 1
  - 1 com $MODEL_COM_1 $MODEL_COM_2 $MODEL_COM_3
  - 1 euler $MODEL_EULER_1 $MODEL_EULER_2 $MODEL_EULER_3

