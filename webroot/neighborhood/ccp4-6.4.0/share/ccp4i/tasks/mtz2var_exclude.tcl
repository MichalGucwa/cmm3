#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# mtz2var_exclude.tcl --
#
# Exclude options for mtz2various as used in export and revise tasks
#
# CCP4Interface
#
# =======================================================================

  CreateLine line \
    message "Exclude reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
	-toggleon \
    label "Resolution less than" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "Angstrom or greater than" \
    widget EXCLUDE_RESOLUTION_MAX \
    label "Angstrom"

  CreateLine line \
    message "Exclude reflections in set selected for FreeR \
                             calculation (FREERFLAG&FREE)" \
    help include_freer \
    widget EXCLUDE_FREER \
    label "FreeR label" \
    widget EXCLUDE_FREER_LABEL \
    label "of value " \
    widget EXCLUDE_FREER_VALUE

  CreateLineTemplate "EXCLUDE" {0.0 0.6 0.8}

  CreateLine line \
   message "Exclude FPs which are small compared to sigma FP (EXCLUDE SIGP)" \
    help exclude_sigp \
    widget EXCLUDE_SIGP \
	-toggleon \
    label "FP less than n * sigmaF where n is " \
    widget EXCLUDE_SIGP_FACTOR \
    format template "EXCLUDE"

  CreateLine line \
   message "Exclude FPHs which are small compared to sigma FPH(EXCLUDE SIGH)" \
    help exclude_sigp \
    widget EXCLUDE_SIGH \
	-toggleon \
    label "FPH less than n * sigmaFH where n is " \
    widget EXCLUDE_SIGH_FACTOR \
    format template "EXCLUDE"

  CreateLine line \
    message "Exclude refs with small absolute FP values(EXCLUDE FPMAX)" \
    help exclude_fpmax \
    widget EXCLUDE_FPMAX \
	-toggleon \
    label "F absolute value less than " \
    widget EXCLUDE_FPMAX_MAX \
    format template "EXCLUDE"

  CreateLine line \
    message "Exclude refs with small absolute FPH values (EXCLUDE FPHMAX)" \
    help exclude_fphmax \
    widget EXCLUDE_FPHMAX \
	-toggleon \
    label "FPH absolute value less than " \
    widget EXCLUDE_FPHMAX_MAX \
    format template "EXCLUDE"


  CreateLine line \
   message "Exclude refs with large diff between FP and FPH (EXCLUDE DIFF)" \
    help exclude_diff \
    widget EXCLUDE_DIFF \
	-toggleon \
    label "Difference between F1 and F2 greater than" \
    widget EXCLUDE_DIFF_LIMIT \
    format template "EXCLUDE"
   
