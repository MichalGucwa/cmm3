#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [ IfSet $TITLE ] } title $TITLE
LABELLINE labin "FP SIGFP"
LOOP n 1 $N_DERIVS
IF { ![StringSame $USE_DERIV($n) NONE] } 
  LABELLINE - "FPH SIGFPH" $n
  IF $ANOMALOUS_DATA
    LABELLINE - "DPH SIGDPH" $n
  ENDIF
ENDIF
ENDLOOP
IF $EXTERNAL_PHASES
  LABELLINE - "PHIC WC FC"
ENDIF

1 labout
 - $OUTPUT_ALLIN ALLIN
 - 1 PHIB = PHIB_$LABOUT_ID
 - 1 FOM = FOM_$LABOUT_ID
IF $OUTPUT_HL_COEFFS
 - 1 HLA = HLA_$LABOUT_ID
 - 1 HLB = HLB_$LABOUT_ID
 - 1 HLC = HLC_$LABOUT_ID
 - 1 HLD = HLD_$LABOUT_ID
ENDIF
IF $FHOUT
LOOP n 1 $N_DERIVS
 - 1 FH$n = $FPH($n)_$LABOUT_ID
 - 1 PHIH$n = PHI_$FPH($n)_$LABOUT_ID
  IF { $ANOMALOUS_DATA && ![regexp Unass $DPH($n) ] }
 - 1 FHA$n = $DPH($n)_$LABOUT_ID
 - 1 PHIHA$n = PHI_$DPH($n)_$LABOUT_ID
  ENDIF
ENDLOOP
ENDIF

$FHOUT fhout deriv
LOOP n 1 $N_DERIVS
 - 1 $n
ENDLOOP
{$FHOUT || $APPLY_SCALE } apply
$OUTPUT_HL_COEFFS HLOUT
 
{ [StringSame $MLPHARE_MODE  PHASE] } phase | cycle $MLPHARE_NCYCLES
$USE_ANGLE angle $ANGLE
{[IfSet $SCALE_SIGFP]} scale sigfp $SCALE_SIGFP

IF { $ANOMALOUS_DATA == 0 }
   $CENTRIC CENTRIC
ENDIF

IF { ! $CENTRIC }
   $USE_SKIP skip $N_SKIP
ENDIF

$EXCLUDE_SIGFP exclude sigfp $EXCLUDE_SIGFP_CUTOFF
$USE_THRESHOLD threshold $THRESHOLD_CUTOFF $THRESHOLD_DAMP
$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX

CASE $PRINT_STATS
CASEMATCH 0
  1 print NOSTATS
CASEMATCH 1
  1 print $PRIMARY_STATS
CASEMATCH 2
  1 print $PRIMARY_STATS $SECONDARY_STATS
ENDCASE
$MONITOR monitor $MONITOR_NREF
- $CORRELATION_MAT COR

LOOP n 1 $N_DERIVS
IF { ![StringSame $USE_DERIV($n) NONE] }
1 deriv $DERIV_TITLE($n)
1 dcycle 
- { [StringSame $USE_DERIV($n) PHASE BOTH ] } phase all 
- { [StringSame $USE_DERIV($n) REFINE BOTH ] } refcyc all 
- 1 kbov all

$EXCLUDE_SIGFPH($n) exclude sigfph $EXCLUDE_SIGFPH_CUTOFF($n)
$EXCLUDE_DISO($n)   exclude diso $EXCLUDE_DISO_CUTOFF($n)
$EXCLUDE_DANO($n)   exclude dano $EXCLUDE_DANO_MAX($n) $EXCLUDE_DANO_MIN($n)
{ [IfSet $RESOLUTION_MIN($n) ] } resolution $RESOLUTION_MIN($n) $RESOLUTION_MAX($n)
{ $ANOMALOUS_DATA && [IfSet $ANO_RESOLUTION_MIN($n)] } resolution ano $ANO_RESOLUTION_MIN($n) $ANO_RESOLUTION_MAX($n)

{[IfSet $DERIV_SCALE($n)] } SCALE FPH$n $DERIV_SCALE($n)
- {[IfSet $DERIV_SCALE_B($n)] } $DERIV_SCALE_B($n)
{ [IfSet $ISOERROR_1($n)] } ISOERROR $ISOERROR_1($n) $ISOERROR_2($n) $ISOERROR_3($n) $ISOERROR_4($n)
 - 1 $ISOERROR_5($n) $ISOERROR_6($n) $ISOERROR_7($n) $ISOERROR_8($n)
{ [IfSet $ANOERROR_1($n)] } ANOERROR $ANOERROR_1($n) $ANOERROR_2($n) $ANOERROR_3($n) $ANOERROR_4($n)
 - 1 $ANOERROR_5($n) $ANOERROR_6($n) $ANOERROR_7($n) $ANOERROR_8($n)

IF { [StringSame $DERIV_DATA_MODE($n) LIST] }
LOOP i 1 $N_ATOMS($n)
IF { $USE_ATOM($n,$i) }
1 atom $ATOM_ID($n,$i) $XFRAC($n,$i) $YFRAC($n,$i) $ZFRAC($n,$i) $ATOM_OCC($n,$i)
 - $ANOMALOUS_DATA $ANOMALOUS_OCC($n,$i)
 - $USE_ANISO_B($n,$i) bfac $ANISOTROPIC_B_1($n,$i) $ANISOTROPIC_B_2($n,$i) $ANISOTROPIC_B_3($n,$i) $ANISOTROPIC_B_4($n,$i) $ANISOTROPIC_B_5($n,$i) $ANISOTROPIC_B_6($n,$i) | bfac $BFACTOR($n,$i)
1 atref
 - $REFINE_XYZ($n) $XYZ_REF_DATA($n)X ALL $XYZ_REF_DATA($n)Y ALL $XYZ_REF_DATA($n)Z ALL
CASE $OCC_B_REF_MODE($n)
CASEMATCH B
 - 1 $XYZ_REF_DATA($n)B ALL
CASEMATCH occ
 - 1 $XYZ_REF_DATA($n)OCC ALL
CASEMATCH occ_B
 - 1 $XYZ_REF_DATA($n)OCC ALL $XYZ_REF_DATA($n)B ALL
CASEMATCH alt_occ_B
 - 1 $ALT_OCC_B($n)
ENDCASE
 - $REFINE_ANOM_OCC($n) AOCC ALL
ENDIF
ENDLOOP

ELSE

LOOP i 1 $N_ATOMS($n)
1 $ATOM_LIST($n,$i)
1 atref
 - $REFINE_XYZ($n) $XYZ_REF_DATA($n)X ALL $XYZ_REF_DATA($n)Y ALL $XYZ_REF_DATA($n)Z ALL
CASE $OCC_B_REF_MODE($n)
CASEMATCH B
 - 1 $XYZ_REF_DATA($n)B ALL
CASEMATCH occ
 - 1 $XYZ_REF_DATA($n)OCC ALL
CASEMATCH occ_B
 - 1 $XYZ_REF_DATA($n)OCC ALL $XYZ_REF_DATA($n)B ALL
CASEMATCH alt_occ_B
 - 1 $ALT_OCC_B($n)
ENDCASE
 - $REFINE_ANOM_OCC($n) AOCC ALL
ENDIF
ENDLOOP

ENDIF

ENDIF
ENDLOOP

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }

1 end