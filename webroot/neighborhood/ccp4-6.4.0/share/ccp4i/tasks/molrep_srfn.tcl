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
# molrep_srfn.tcl --
#
# CCP4Interface 
#
# =======================================================================
#
# This is a wrapper that launches the molrep task in
# a mode suitable for running the self-rotation function mode
#
# This is done by wrapping the existing molrep task with
# dummy procedures, and over-riding defaults for the
# molrep task within the molrep_srfn.def file

# Acquire the Molrep interface procedures
source [SearchPath TOP tasks molrep.tcl]

#-------------------------------------------------------------------------
proc molrep_srfn_run { arrayname } {
#-------------------------------------------------------------------------
    # Wraps the run procedure for the Molrep task
    return [molrep_run $arrayname]
}

#---------------------------------------------------------------------
proc molrep_srfn_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
    # Wraps the setup procedure for the Molrep task
    upvar #0  $typedefVar typedef
    return [molrep_setup $typedefVar $arrayname]
}

#-------------------------------------------------------------------
proc molrep_srfn_task_window { arrayname } {
#-------------------------------------------------------------------
    # Wraps the task window procedure for the Molrep task
    molrep_task_window $arrayname
}
