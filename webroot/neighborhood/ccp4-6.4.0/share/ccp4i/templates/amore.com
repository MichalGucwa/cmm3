#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 title $TITLE
$VERBOSE verbose

IF $SORTFUN 
  1 sortfun 
  - 1 resolution $RESOLUTION_MIN 
  -- 1 $RESOLUTION_MAX
  - $SORTFUN_MODEL MODEL
  LABELLINE labin "FP SIGFP"
ENDIF

IF $TABFUN 
  1 tabfun 
  - $TABFUN_NOROTATE norotate
  - $TABFUN_NOTRANSLATE notranslate
  - $TABFUN_NOTAB notab
  - $TABFUN_HKLOUT hklout
  LOOP n 1 $N_MODELS
    1 model $n breplace $BREPLACE($n) badd $BADD($n)
    1 sample $n resolution $RESOLUTION_MIN 
    - 1 scale $TABFUN_SCALE($n) 
    - 1 shann $TABFUN_SHANN($n)
  ENDLOOP
  $TABFUN_CRYSTAL crystal $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6 orth 1 
ENDIF

IF $ROTFUN_GENERATE
  LOOP n 1 $N_MODELS
    1 generate $n 
    - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
    - 1 cell_model $MODEL_CELL_1($n) $MODEL_CELL_2($n) $MODEL_CELL_3($n)
  ENDLOOP
ENDIF

$ROTFUN_CLMN_CRYSTAL clmn crystal 
  - 1 orth $CRYSTAL_ORTH 
  - 1 flim $CRYSTAL_FMIN $CRYSTAL_FMAX
  - 1 sharp $CRYSTAL_BADD
  - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
  - 1 sphere $CRYSTAL_IRMAX

IF $ROTFUN_CLMN_MODEL 
  LOOP n 1 $N_MODELS
    1 clmn model $n 
      - 1 flim $MODEL_FMIN($n) $MODEL_FMAX($n)
      - 1 sharp $ROTATE_MODEL_BADD($n)
      - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
      - 1 sphere $MODEL_IRMAX($n)
  ENDLOOP
ENDIF

IF $ROTFUN_ROTATE
  1 rotate $ROTFUN_ROTATE_MODE
    - { [regexp CROSS $ROTFUN_ROTATE_MODE] } model 1 pklim $ROTFUN_PKLIMC
    - { [regexp SELF $ROTFUN_ROTATE_MODE] } pklim $ROTFUN_PKLIMS
    - 1 npic $ROTFUN_NPIC
    - $BESLIM beslim $BESLIM_MIN $BESLIM_MAX
    - 1 step $ROTFUN_STEP
    - 1 bmax $ROTFUN_BMAX
    - 1 nsr $ROTFUN_NSR1R $ROTFUN_NSR2R
ENDIF

$ROTFUN_SHIFT shift $N_MODELS 
  - 1 com $MODEL_COM_1($n) $MODEL_COM_2($n) $MODEL_COM_3($n)
  - 1 euler $MODEL_EULER_1($n) $MODEL_EULER_2($n) $MODEL_EULER_3($n)

IF $TRAFUN
  1 trafun $TRAFUN_MODE $NMOL 
    - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
    - 1 npic $TRAFUN_NPIC
    - 1 pklim $TRAFUN_PKLIM
  1 crystal orth $CRYSTAL_ORTH
    - 1 flim $CRYSTAL_FMIN $CRYSTAL_FMAX
    - 1 sharp $CRYSTAL_BADD
    - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
  1 symmetry $TEST_SPACE_GROUP

  LOOP n 1 $N_TRAFUN_SOLUTIONS
    LOOP i 1 $NMOL
      1 solution
        - { $i != $NMOL } fix
        - $MODEL_NUMBER($i)  
    ENDLOOP
  ENDLOOP

ENDIF

IF $FITFUN
  fitfun $NMOL
  - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
  - 1 iter $FITFUN_NITER
  - 1 conv $FITFUN_CONV
  1 crystal orth $CRYSTAL_ORTH
    - 1 flim $CRYSTAL_FMIN $CRYSTAL_FMAX
    - 1 sharp $CRYSTAL_BADD
    - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
  1 symmetry $TEST_SPACE_GROUP
  1 refsolution $REFSOLUTION
ENDIF
