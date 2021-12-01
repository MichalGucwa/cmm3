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
# pisa_web.tcl --
#
# This is a dummy interface file that launches a web browser pointing to
# the PISA website at the EBI
#
# CCP4Interface 
#
# =======================================================================

#--------------------------------------------------------------------
proc pisa_web_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

   # Set URL for PISA webpage
   set pisa_url "http://www.ebi.ac.uk/msd-srv/prot_int/pistart.html"

   # Make sure we get rid of waiting message
   PleaseWait

   # Launch a browser with the PISA webservice
   open_url $pisa_url -remote

  return 0
}

#--------------------------------------------------------------------
proc pisa_web_task_window { typedefVar arrayname } {
#--------------------------------------------------------------------
# Dummy procedure required for startup only.
}
