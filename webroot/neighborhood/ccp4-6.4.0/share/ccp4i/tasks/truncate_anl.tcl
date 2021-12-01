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
# truncate_anl.tcl --
#
# CCP4Interface 
#
# =======================================================================
#
# This is a wrapper that launches the truncate task in
# a mode suitable for running just the data analysis
#
# This is done by wrapping the existing truncate task with
# dummy procedures, and over-riding defaults for the
# truncate task within the truncate_anl.def file

# Acquire the Truncate interface procedures
source [SearchPath TOP tasks truncate.tcl]

#-------------------------------------------------------------------------
proc truncate_anl_run { arrayname } {
#-------------------------------------------------------------------------
    # Wraps the run procedure for the Truncate task
    return [truncate_run $arrayname]
}

#---------------------------------------------------------------------
proc truncate_anl_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
    # Wraps the setup procedure for the Truncate task
    upvar #0  $typedefVar typedef
    return [truncate_setup $typedefVar $arrayname]
}

#-------------------------------------------------------------------
proc truncate_anl_task_window { arrayname } {
#-------------------------------------------------------------------
    # Wraps the task window procedure for the Truncate task
    truncate_task_window $arrayname
}
