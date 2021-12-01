#! /usr/bin/env ccp4-python
#
# Wrapper script for setting the input HKLIN for refmac on CLuster or 
# local job. Required for determining the enantiomorphic SG stuff.
#
# Ronan Keegan 20/12/06
#

import os, sys
import shutil

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'

mrbump_incl = os.path.join(os.environ["CCP4"], "src", "mrbump", "include") 
sys.path.append(os.path.join(mrbump_incl, 'file_info'))

import MTZ_info

class SetRefineHKLIN:
   """ A class to set the input HKLIN for Refmac. """

   def __init__(self):
      self.spacegroup_dict=dict([])
     
      self.debug=False

   def check_spacegroup(self, hklin, tag_name):
      """ Check the spacegroup of the phaser hklout solution file. """
     
      # Setup and run the Mtzdump job
      md=MTZ_info.Mtzdump()
      md.setMTZdumpLogfile(os.getcwd())
      md.setHklin(hklin)
      md.go()

      # Set the spacegroup for this MTZ file
      self.spacegroup_dict[tag_name]=md.getSpacegroup()

      # Clean up
      os.remove(md.logfile)

   def set_RefineHKLIN(self, MR_hklin, i_hklin, e_hklin, refinement_hklin):
      """ Set the refinement MTZ file. """  

      # Default to original MTZ
      REFHKLIN=i_hklin

      # Check the spacegroups for the original input MTZ, 
      # the enant MTZ and the Phaser output MTZ
      self.check_spacegroup(i_hklin, "Input_hklin")
      self.check_spacegroup(e_hklin, "Enant_hklin")
      self.check_spacegroup(MR_hklin, "MRprog_hklin")

      # Copy the relevant MTZ file to the refinement input MTZ file
      if self.spacegroup_dict["Input_hklin"] == self.spacegroup_dict["MRprog_hklin"]:
         REFHKLIN=i_hklin
         shutil.copyfile(i_hklin, refinement_hklin) 
         if self.debug:
            sys.stdout.write("MR solution space group: %s\n" % self.spacegroup_dict["Input_hklin"])
            sys.stdout.write("\n")
      else:
         REFHKLIN=e_hklin
         shutil.copyfile(e_hklin, refinement_hklin) 
         if self.debug:
            sys.stdout.write("MR solution space group: %s\n" % self.spacegroup_dict["Enant_hklin"])
            sys.stdout.write("\n")

      return REFHKLIN
      
    
if __name__ == "__main__":

   if len(sys.argv) != 5:
      print "Usage: setrefineMTZ <MR HKLOUT> <input HKLIN> <enant HKLIN> <refinement HKLIN>"
      sys.exit()

   MR_hklin=sys.argv[1]
   input_hklin=sys.argv[2]
   enant_hklin=sys.argv[3]
   refinement_hklin=sys.argv[4]

   srh=SetRefineHKLIN()
   srh.debug=True
   
   srh.set_RefineHKLIN(MR_hklin, input_hklin, enant_hklin, refinement_hklin)


