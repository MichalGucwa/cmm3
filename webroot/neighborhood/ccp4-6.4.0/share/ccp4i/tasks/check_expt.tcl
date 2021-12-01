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
# check_expt.tcl --
#
# CCP4Interface 
#
# =======================================================================
#
# This is a wrapper that launches the check task in
# a mode suitable for analysing experimental data
#
# This is done by wrapping the existing check task with
# dummy procedures, and over-riding defaults for the
# check task within the check_expt.def file

# Acquire the check interface procedures
source [SearchPath TOP tasks check.tcl]

#-------------------------------------------------------------------------
proc check_expt_run { arrayname } {
#-------------------------------------------------------------------------
    # Wraps the run procedure for the check task
    return [check_run $arrayname]
}

#---------------------------------------------------------------------
proc check_expt_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
    # Wraps the setup procedure for the check task
    upvar #0  $typedefVar typedef
    return [check_setup $typedefVar $arrayname]
}

#-------------------------------------------------------------------
proc check_expt_task_window { arrayname } {
#-------------------------------------------------------------------
    # Wraps the task window procedure for the check task
    check_task_window $arrayname
}
