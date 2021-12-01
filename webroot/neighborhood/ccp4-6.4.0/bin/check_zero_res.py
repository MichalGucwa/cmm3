#!/usr/bin/python
# checks the number of residues built by buccaneer and returns error if it is zero

import os,sys

if len(sys.argv)<2:
  sys.exit("check_zero_res needs a PDB filename on input.")
if os.path.isfile(sys.argv[1]):
  with open(sys.argv[1],'r') as f:
    for line in f:
      if line.startswith("ATOM") or line.startswith("HETATM"):
        break
    else:
      sys.exit("No residues could be traced!".format(sys.argv[1]))
else:
  sys.exit("The PDB file {0} input to check_zero_res does not exist or cannot be open for reading.".format(sys.argv[1]))
