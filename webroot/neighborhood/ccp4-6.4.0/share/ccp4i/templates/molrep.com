#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs, Alexei Vagin
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
1 DOC Y

#########################################################################
# LABIN LINE
#########################################################################
IF { ![StringSame $MOLREP_MODE FIT LN] }
IF { [StringSame $INPUT_SF_TYPE HKLIN] }
  IF { !$IFINT }
1 LABIN F=$FP 
  - {[IfSet SIGFP] && ![StringSame $SIGFP Unassigned]} SIGF=$SIGFP
  IF { $IFANOMALOUS }
    - {[IfSet FPm] && ![StringSame $FPm Unassigned]} F(-)=$FPm
    - {[IfSet SIGFPm] && ![StringSame $SIGFPm Unassigned]} SIGF(-)=$SIGFPm
    - {[IfSet DP] && ![StringSame $DP Unassigned]} DP=$DP
    - {[IfSet SIGDP] && ![StringSame $SIGDP Unassigned]} SIGDP=$SIGDP
  ENDIF
  IF { $IFDER }
    - {[IfSet FD] && ![StringSame $FD Unassigned]} FD=$FD
    - {[IfSet SIGFD] && ![StringSame $SIGFD Unassigned]} SIGFD=$SIGFD
  ENDIF

  ENDIF

  IF { $IFINT }
1 LABIN I=$I SIGI=$SIGI
  IF { $IFANOMALOUS }
    - {[IfSet Im] && ![StringSame $Im Unassigned]} I(-)=$Im
    - {[IfSet SIGIm] && ![StringSame $SIGIm Unassigned]} SIGI(-)=$SIGIm
  ENDIF
  ENDIF

  IF { [StringSame $MOLREP_MODE SEARCH PRF] }
  IF { $IFPHASES }
    - {[IfSet PHI] && ![StringSame $PHI Unassigned]} PH=$PHI
    - {[IfSet FOM] && ![StringSame $FOM Unassigned]} FOM=$FOM
{ $INVER } INVER Y
  ENDIF
  ENDIF

#{![StringSame $INVER N]} INVER Y

  IF { [StringSame $USE_GROUP_NUMBER D] }
    { [IfSet $SPACE_GROUP_NUMBER] } NOSG $SPACE_GROUP_NUMBER
  ENDIF

ENDIF

IF { [StringSame $INPUT_SF_TYPE CIFIN] }

  IF { [StringSame $USE_GROUP_NUMBER D] }
   { [IfSet $ISPACE_GROUP_NUMBER] } NOSG $ISPACE_GROUP_NUMBER
  ENDIF

  IF { $IFPHASES }
1   PHASE  +   
  ENDIF
ENDIF

  IF { [StringSame $USE_GROUP_NUMBER A ] }
1    NOSG -1
  ENDIF

IF { [StringSame $INPUT_SF_TYPE MAPIN] }
{ [IfSet $DSCALE] } DSCALE $DSCALE
{ [IfSet $DLIM] } DLIM $DLIM
{ $INVER } INVER Y
ENDIF

ENDIF



IF { [StringSame $MOLREP_MODE TRANSFORM] }
1 FUN  S
  { [IfSet $ROT_SOLUTIONS] } FILE_T $ROT_SOLUTIONS
ENDIF


IF { [StringSame $MOLREP_MODE SELF] || [StringSame $IHA R] }
1 FUN  R
{ [IfSet $SELF_CHI] } CHI $SELF_CHI
{ [IfSet $SELF_SCALE] } SCALE $SELF_SCALE
ENDIF


IF { [StringSame $MOLREP_MODE RB] }
#  NREF
1 FUN  B
{![StringSame $DOM Y]} DOM $DOM
IF { [IfSet $NCS] && $NCS > 0 } 
1 NCS  $NCS
IF { [IfSet $NCS] && $NCS > 100 } 
{[IfSet $ANGLES] } ANGLES  $ANGLES
{[IfSet $CENTRE] } CENTRE  $CENTRE
ENDIF
ENDIF
ENDIF

IF { [StringSame $MOLREP_MODE HA] }
IF { [StringSame $IHA N] }
1 FUN  D
ENDIF
IF { [StringSame $IHA R] }
1  DIFF H
ENDIF
IF { [StringSame $IHA S] }
1 FUN  T
1 DIFF H
ENDIF
ENDIF

IF { $IFPRF &&  [StringSame $MOLREP_MODE PRF] }
  { [IfSet $ROT_SOLUTIONS] } FILE_T2 $ROT_SOLUTIONS
ENDIF

IF { $MODEL_MAP }
{ [IfSet $DSCALEM] } DSCALEM $DSCALEM
{ [IfSet $DRAD] } DRAD $DRAD
{ [IfSet $ROLIM] } ROLIM $ROLIM
{ $INVERM } INVERM Y
{[IfSet $ORIGIN] } ORIGIN  $ORIGIN
ENDIF

IF { [StringSame $MOLREP_MODE CROSS SEARCH FIT LN PRF] || [StringSame $IHA S] }

IF { ![StringSame $IHA S] }
{[IfSet $FUNCTION] && ![StringSame $FUNCTION A]} FUN $FUNCTION
ENDIF

1 SURF $MODEL_CORRECTION

IF { $NMONOMERS > 0  }
{ [IfSet $NMONOMERS] } NMON $NMONOMERS
ENDIF

{ [IfSet $COMPLETENESS] } COMPL $COMPLETENESS
#{ [IfSet $SIMILARITY] } SIM $SIMILARITY
IF { [IfSet $SIMILARITY] }
  1 SIM $SIMILARITY
ELSE
  IF { [StringSame $MOLREP_MODE PRF] }
    1 SIM -1
  ENDIF
ENDIF
{ [IfSet $NMR_MODEL] && $NMR_MODEL > 0 } NMR $NMR_MODEL
{ [IfSet $NMR_MODEL] && $NMR_MODEL < 0 } NMR -$NMR_MODEL_NUM

IF { [IfSet $NCSM] && $NCSM > 0 } 
1 NCSM  $NCSM
#IF { [IfSet $NCS] && $NCS > 100 } 
#{[IfSet $ANGLES] } ANGLES  $ANGLES
#{[IfSet $CENTRE] } CENTRE  $CENTRE
#ENDIF
ENDIF

IF { ![StringSame A $PSEUDO_TRANS_MODE] } 
1 PST $PSEUDO_TRANS_MODE
{[IfSet $PSEUDO_TRANS] } VPST  $PSEUDO_TRANS
ENDIF

IF { $NPEAKS_ROT > 0  }
{ [IfSet $NPEAKS_ROT] } NP $NPEAKS_ROT
ENDIF
IF { $NPEAKS_TRAN > 0  }
{ [IfSet $NPEAKS_TRAN]} NPT $NPEAKS_TRAN
ENDIF

IF { [StringSame $MOLREP_MODE CROSS LN] }
  {$LOCK}  LOCK Y
IF { !$IFPRF } 
  { [StringSame $FUNCTION T] && [IfSet $ROT_SOLUTIONS] } FILE_T $ROT_SOLUTIONS
ENDIF
#  {$STICK}  STICK Y
  {!$STICK}  STICK N
  {$IFSEQ}  FILE_S $SEQIN
##IF {$CROSS_NSRF > 0 && !$IDYAD}
###IF {$CROSS_NSRF > 0 }
##  1  NSRF $CROSS_NSRF
##  1  FILE_TSR $SROT_SOLUTIONS
##  1  LIST L
##ENDIF

ENDIF


IF { $IDYAD  && ![StringSame $DYAD N]} 

1 DYAD $DYAD

#IF {$DYAD_NSRF > 0 }
#  1  NSRF $DYAD_NSRF
#  1  FILE_TSR $SROT_SOLUTIONS

#ENDIF
IF { [StringSame $DYAD_MODE SELF ]}
  1 NSRF $DYAD_NSRF
  1 FILE_TSR $SROT_SOLUTIONS
ELSE
$DYAD_DIST DIST $DYAD_DMIN $DYAD_DMAX $DYAD_DPAR
{[IfSet $DYAD_CHI]}  AXIS $DYAD_CHI $DYAD_DELTA
IF { [StringSame $DYAD_MODE USER] }
1 ALL  N
ENDIF
ENDIF
ELSE

IF {$CROSS_NSRF > 0 }
  1  NSRF $CROSS_NSRF
  1  FILE_TSR $SROT_SOLUTIONS
ENDIF

ENDIF

#{[IfSet $NPEAKS_TRAN]} NPT  $NPEAKS_TRAN
#{[IfSet $NPEAKS_SPEC]} NPTD $NPEAKS_SPEC

#IF { $NMONOMERS < 2}
#NMON 2
#ENDIF

IF { $IDYAD } 
IF { $IDYAD2 } 
  1 FILE_M2 $XYZIN_T2
  { [IfSet $ROT_SOLUTIONS2] } FILE_T2 $ROT_SOLUTIONS2
  {$IFSEQ2}  FILE_S2 $SEQIN2
  { [IfSet $DYAD_NP2] } NP2 $DYAD_NP2
ENDIF
ENDIF

ENDIF

ENDIF

IF { $NPEAKS_SPEC > 0  }
{[IfSet $NPEAKS_SPEC]} NPTD $NPEAKS_SPEC
ENDIF

# ------------------------------

$BSCALE BADD $BADD
IF { $IFPRF } 
{ $USE_SPHERE_AVER } PRF $PTF_MODE
ENDIF
{ [IfSet $USE_DIFF_SFS ] }  DIFF $USE_DIFF_SFS
{ [IfSet $PERCENT_MODEL ] } P2 $PERCENT_MODEL

{ [IfSet $SEARCH_RADIUS]} RAD $SEARCH_RADIUS
{  ![StringSame $ANISO D] } ANISO $ANISO
{ !$PACKING }  PACK N
{ $SCORE }  SCORE N
{ ![StringSame $MODE_PROTOCOL F ] } MODE $MODE_PROTOCOL
{ [IfSet $MAX_RESOLUTION] } RESMAX $MAX_RESOLUTION
{ [IfSet $MIN_RESOLUTION_ROT] } RESMIN $MIN_RESOLUTION_ROT
{ [IfSet $MIN_RESOLUTION_TRAN] } RES_T $MIN_RESOLUTION_TRAN
{ [IfSet $NREF]} NREF $NREF
{ [IfSet $NREFP]} NREFP $NREFP
{ [IfSet $LMIN]} LMIN $LMIN

#{ ![StringSame $ANISO N] } ANISO $ANISO
#1 END
