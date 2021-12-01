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
# arp_warp.tcl --
#
# Interface for CCP4 arp_warp (v5.0) has been withdrawn
# Recommend that the user gets the official arp_warp interface from Embl
#
# CCP4Interface 
#
# =======================================================================

#--------------------------------------------------------------------
proc arp_warp_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

   # Set URL for ARP/wARP homepage
   set arp_warp_url "http://www.arp-warp.org/"

   # Make sure we get rid of waiting message
   PleaseWait

   set action [ChooseOptionDialog "ARP/wARP Interface" "ARP/wARP" \
"An interface to ARP/wARP is not available.

The ARP/wARP interface doesn't appear to have been installed in
this version of CCP4i.

You can download the interface and the latest version of
the ARP/wARP suite from
$arp_warp_url" \
	{ "Go to website" Dismiss } -default 1 ]

  # Go to the ARP/wARP website
  if ![regexp Dismiss $action] {
    open_url $arp_warp_url -remote
  }

  return 0
}

#--------------------------------------------------------------------
proc arp_warp_task_window { typedefVar arrayname } {
#--------------------------------------------------------------------
# Dummy procedure required for startup only.
}
