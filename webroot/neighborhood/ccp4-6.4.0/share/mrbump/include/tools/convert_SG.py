#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# convert_SG.py
#
# Script to extract convert between Spacegroup formats.
# Ronan Keegan 18/09/07

import os
import sys
import string


class Convert:
   """ A class to convert SG formats. """

   def __init__(self):
      self.SG=""

   def xHMtoOld(self, spacegroup):
      """ Convert from xHM to old format. """

      if ":R" in spacegroup:
         sg=spacegroup.replace(":R", "")
      if ":H" in spacegroup:
         sg=(spacegroup.replace(":H", "")).replace("R", "H")
      else:
         sg=spacegroup

      self.SG=sg

      return sg

if __name__ == "__main__":
 
   SG="R 3 :R"

   c=Convert()
   c.xHMtoOld(SG)
