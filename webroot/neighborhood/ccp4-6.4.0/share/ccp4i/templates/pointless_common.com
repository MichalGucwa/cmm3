#
#     Copyright (C) 1999-2006  Peter Briggs, Liz Potterton
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE pointless

# Note all "legacy" Pointless scripts (i.e. laue, centre and index) use
# this single template to generate keyworded input for Pointless

#####################################
# Laue group determination mode
#####################################

IF { [StringSame $POINTLESS_MODE "LAUE"] }

   IF { [StringSame $POINTLESS_LAUE_MODE "ALLPOSSIBLE"] }
      $LAUEGROUP_ALL LAUEGROUP ALL
   ELSE
      1 LAUEGROUP
      - { [StringSame $POINTLESS_LAUEGROUP "HKLIN"] } HKLIN | $LAUEGROUP_NAME
   ENDIF

   $USE_ACCEPT ACCEPT $ACCEPT_LIMIT

   IF { [StringSame $LATTICE_MODE "CELL"] }
      $USE_TOLERANCE TOLERANCE $LATTICE_TOLERANCE
   ENDIF

   # CHIRALITY keyword
   # Default is CHIRALITY CHIRAL (no special output required)
   # Commented out for now
   ##CASE $POINTLESS_NONCHIRAL
   ##CASEMATCH "NONCHIRAL"
   ##   1 CHIRALITY NONCHIRAL
   ##CASEMATCH "CENTROSYMMETRIC"
   ##   1 CHIRALITY CENTROSYMMETRIC
   ##ENDCASE
ENDIF

#####################################
# Alternative indexing mode
#####################################

IF { [StringSame $POINTLESS_MODE "INDEX"] }
   $MERGED_DATA LABIN F=$F_IN
   $MERGED_REF_DATA LABREF F=$F_REF
ENDIF

#####################################
# Check centre mode
#####################################

IF { [StringSame $POINTLESS_MODE "CENTRE"] }
   1 CENTRE
   - $USE_HKL_GRID $HGRID $KGRID $LGRID
   $RESET_SYMMETRY LAUEGROUP $LAUEGROUP_NAME
ENDIF

#####################################
# Keywords available in all modes
#####################################

# PARTIALS available in all modes
IF { $PARTIALS_NOCHECK || $PARTIALS_TEST || $PARTIALS_CORRECT || $PARTIALS_GAP }
   1 PARTIALS
   - { $PARTIALS_NOCHECK } NOCHECK
   - { $PARTIALS_TEST } TEST $PARTIALS_LOWER $PARTIALS_UPPER
   - { $PARTIALS_CORRECT } CORRECT $PARTIALS_MINIMUM
   - { $PARTIALS_GAP } GAP $PARTIALS_GAP_LIMIT
ENDIF

IF { [StringSame $LATTICE_MODE "ORIGINALLATTICE"] }
   1 ORIGINALLATTICE
ENDIF

# RESOLUTION/ISIGLIMIT available in all modes
IF { $USE_RESOL_CUTOFF }
CASE $RESOL_CUTOFF_MODE
CASEMATCH "RESOLUTION"
   { [IfSet $RESMIN] || [IfSet $RESMAX] } RESOLUTION
   - { [IfSet $RESMIN] } LOW $RESMIN
   - { [IfSet $RESMAX] } HIGH $RESMAX
CASEMATCH "ISIGLIMIT"
   { [IfSet $ISIGLIMIT] } ISIGLIMIT $ISIGLIMIT
ENDCASE
ENDIF

1 END

