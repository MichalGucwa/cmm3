#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# OASIS: COMMAND SCRIPT
##################################################
1 TITLE $TITLE

##################################################
# COMPULSORY INPUT
##################################################
1 $OASIS_MODE
1 HCO $OASIS_HA_TYPE $N_HATOMS

IF { [StringSame $OASIS_MODE OAS] }
   1 ANO $OASIS_HA_TYPE $ANO_F_DPRIME
ENDIF

$COMPARE_PHI PHI

##################################################
# CELL CONTENTS
##################################################
IF { [StringSame $CELL_CONTENT_STATUS KNOWN] }
   1 CON $CELL_CONTENT
ENDIF

##################################################
# HIGH RESOLUTION CUTOFF
##################################################
IF { [IfSet $OASIS_RES] }
   $USE_RES RES $OASIS_RES
ENDIF

##################################################
# MTZ HEADER INFO
##################################################
IF { $USE_MTZ_INFO != 1 }
   1 SPG $SPACEGROUP
   1 CELL $CELL_A $CELL_B $CELL_C
   - 1 $CELL_ALPHA $CELL_BETA $CELL_GAMMA
ENDIF

##################################################
# GENERAL OPTIONS
##################################################
$OASIS_FIT FIT
1 CYC $OASIS_CYC
IF { [IfSet $OASIS_LCE] }
   IF { $OASIS_UNIFORM_FOM }
     1 LCE -$OASIS_LCE
   ELSE
     1 LCE $OASIS_LCE
   ENDIF
ENDIF
1 KMI $OASIS_KMI
IF { [IfSet $OASIS_NSIG] }
   1 SIG $OASIS_NSIG
ENDIF

##################################################
# MTZ LABELS
##################################################
LABELLINE LABIN $LABIN
LABELLINE LABOUT $LABOUT

##################################################
# HEAVY ATOM DATA
##################################################
1 POS
LOOP n 1 $N_HATOMS_ASU
- 1 $HATOM_TYPE($n) $XFRAC($n) $YFRAC($n) $ZFRAC($n) $n $HATOM_OCC($n)
ENDLOOP

1 END
