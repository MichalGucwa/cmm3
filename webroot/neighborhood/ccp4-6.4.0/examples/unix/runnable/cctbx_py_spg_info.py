#
# Martyn Winn 15/01/07
#

# Run as:
#
# cctbx.python cctbx_py_spg_info.py
#
# to ensure the correct environment. This should be on your path if you
# have source'd ccp4.setup which sources in turn:
#. $CCP4/src/phaser/phaser-${phaser_version}/build/${phaser_mtype}/setpaths.sh

# This is a short test script to test python bindings
# to sgtbx. It might also be useful!

import os
from cctbx import sgtbx

def print_sg_details(spg_name):
  sg_inf = sgtbx.space_group_info(spg_name)
  sg_type = sg_inf.type()

  print " "
  print " ############################################# "
  print "     Spacegroup details for ",spg_name
  print " ############################################# "
  print " "
  print " SYMINFO records"
  print " "

  print "begin_spacegroup"
  print "number ",sg_type.number()
# basisop note: some discepancies with distributed SYMINFO
  print "basisop ",sg_type.cb_op().as_xyz()
  print "symbol Hall '%s'" % sg_type.hall_symbol()
# note lookup_symbol() returns xHM if exists, else Hall
  print "symbol xHM '%s'" % sg_type.lookup_symbol()
  print "hklasu sgtbx '%s'" % sg_inf.reciprocal_space_asu().reference_as_string()
  print "mapasu nonz '%s'" % sg_inf.brick()
  print "end_spacegroup"

  print " "
  print " Additional information"
  print " "
  print "is_enantiomorphic",sg_type.is_enantiomorphic()
  print "conventional_centring_type_symbol ",sg_type.group().conventional_centring_type_symbol()
  print "crystal_system ",sg_type.group().crystal_system()

if (__name__ == "__main__"):
  print_sg_details("P 1 1 2")
  print_sg_details("P 41")
