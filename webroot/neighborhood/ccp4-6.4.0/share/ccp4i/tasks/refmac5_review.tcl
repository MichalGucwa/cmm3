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
# refmac5_review.tcl --
#
# CCP4Interface 
#
# =======================================================================
#
# This is a wrapper that launches the Refmac5 task in
# "review restraints" mode
#
# This is done by wrapping the existing refmac5 task with
# dummy procedures, and over-riding defaults for the
# refmac5 task within the refmac5_review.def file

# Acquire the Refmac5 interface procedures
source [SearchPath TOP tasks refmac5.tcl]

#-------------------------------------------------------------------------
proc refmac5_review_run { arrayname } {
#-------------------------------------------------------------------------
    # Wraps the run procedure for Refmac5
    return [refmac5_run $arrayname]
}

#---------------------------------------------------------------------
proc refmac5_review_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
    # Wraps the setup procedure for Refmac5
    upvar #0  $typedefVar typedef
    return [refmac5_setup $typedefVar $arrayname]
}

#-------------------------------------------------------------------
proc refmac5_review_task_window { arrayname } {
#-------------------------------------------------------------------
    # Wraps the task window procedure for Refmac5
    refmac5_task_window $arrayname
}
