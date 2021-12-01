#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2008 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# MRBUMP wrapper for CCP4 program Cpirate 
# Ronan Keegan 18/2/08

import os
import string
import sys
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CCP4_SCR'):
    raise RuntimeError, 'CCP4_SCR not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class Cpirate:

   def __init__(self):
      if os.name=="nt":
         self.cpirateEXE=os.path.join(os.environ["CBIN"], "cpirate.exe")
      else:
         self.cpirateEXE=os.path.join(os.environ["CBIN"], "cpirate")

      self.keywords=dict([])

      # Mandatory input:
      self.keywords["mtzin-ref"]=""
      self.keywords["mtzin-wrk"]=""
      self.keywords["mtzout"]="" 
      self.keywords["colin-ref-fo"]="" 
      self.keywords["colin-ref-hl"]="" 
      self.keywords["colin-wrk-fo"]="" 
      self.keywords["colin-wrk-hl"]="" 

      # Optional input:
      self.keywords["pdbin-ha"]="" 
      self.keywords["colin-wrk-free"]="" 
      self.keywords["colout"]="" 
      self.keywords["colout-hl"]=""
      self.keywords["colout-fc"]=""
      self.keywords["ncycles"]=None
      self.keywords["weight-expllk"]=None
      self.keywords["weight-mapllk"]=None
      self.keywords["weight-ramp"]=None
      self.keywords["resolution"]=None
      self.keywords["stats-radius"]=""
      self.keywords["skew-content"]=""
      self.keywords["auto-content"]=False
      self.keywords["unbias"]=False
      self.keywords["evaluate"]=False
      self.keywords["strict-free"]=False
      self.keywords["ncs-volume"]=None
      self.keywords["ncs-radius"]=None
      self.keywords["ncs-operator"]=""
      self.keywords["seed"]=""
      self.keywords["verbose"]=""

      # Take input from stdin (shouldn't be used, but here for completeness)
      self.keywords["stdin"]=False

      self.commandfile="" 
      self.logfile="" 

      self.finalfreeE=0.0

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLogfile(self, filename):
      self.logfile=filename

   def setCommandfile(self, filename):
      self.commandfile=filename

   def run(self):
      """ Set the cpirate input command line and run the job. """

      if self.debug:
         sys.stdout.write("Cpirate: Running cpirate to improve phases...\n")
         sys.stdout.write("\n")

      # Set up the cpirate command line
      commandline  = self.cpirateEXE

      # Add the mandatory inputs. First check to see that they have all been set correctly.
      for key in "mtzin-ref", "mtzin-wrk", "mtzout", \
                 "colin-ref-fo", "colin-ref-hl", "colin-wrk-fo", "colin-wrk-hl": 
         if self.keywords[key]=="":
            sys.stdout.write("Cpirate: Error - keyword %s is not set. This keyword is required.\n" % key)
            sys.stdout.write("\n")
            sys.exit(1)

      # Check that the input MTZ files exist.
      if os.path.isfile(self.keywords["mtzin-wrk"]) == False:
         sys.stdout.write("Cpirate: Error - input MTZ (working) could not be found:\n   %s\n" % self.keywords["mtzin-wrk"])
         sys.stdout.write("\n")
         sys.exit(1)
         
      if os.path.isfile(self.keywords["mtzin-ref"]) == False:
         sys.stdout.write("Cpirate: Error - input MTZ (reference) could not be found:\n   %s\n" % self.keywords["mtzin-ref"])
         sys.stdout.write("\n")
         sys.exit(1)
 
      commandline += " -mtzin-ref " + self.keywords["mtzin-ref"]
      commandline += " -mtzin-wrk " + self.keywords["mtzin-wrk"]
      commandline += " -mtzout " + self.keywords["mtzout"]
      commandline += " -colin-ref-fo " + self.keywords["colin-ref-fo"]
      commandline += " -colin-ref-hl " + self.keywords["colin-ref-hl"]
      commandline += " -colin-wrk-fo " + self.keywords["colin-wrk-fo"]
      commandline += " -colin-wrk-hl " + self.keywords["colin-wrk-hl"]

      # Output the input file details (debug):
      if self.debug:
         sys.stdout.write("Cpirate: Input files:\n")
         sys.stdout.write("   Reference MTZ file: %s\n" % self.keywords["mtzin-ref"])
         sys.stdout.write("   Working MTZ file:   %s\n" % self.keywords["mtzin-wrk"])
         sys.stdout.write("   Output MTZ file:    %s\n" % self.keywords["mtzout"])
         sys.stdout.write("\n")

      # Optional keywords:

      if self.keywords["pdbin-ha"] != "":
         if os.path.isfile(self.keywords["pdbin-ha"]) == False:
            sys.stdout.write("Cpirate: Error - input PDB (pdbin-ha) could not be found:\n   %s\n" % self.keywords["pdbin-ha"])
            sys.stdout.write("\n")
            sys.exit(1)
         else:
            commandline += " -pdbin-ha " + self.keywords["pdbin-ha"]

      if self.keywords["colin-wrk-free"] != "": 
         commandline += " -colin-wrk-free " + self.keywords["colin-wrk-free"]

      if self.keywords["colout"] != "": 
         commandline += " -colout " + self.keywords["colout"]

      if self.keywords["colout-hl"] != "":
         commandline += " -colout-hl " + self.keywords["colout-hl"]

      if self.keywords["colout-fc"] != "":
         commandline += " -colout-fc " + self.keywords["colout-fc"]

      if self.keywords["ncycles"] != None:
         commandline += " -ncycles %d" % self.keywords["ncycles"]

      if self.keywords["weight-expllk"] != None:
         commandline += " -weight-expllk %.4f" % self.keywords["weight-expllk"]

      if self.keywords["weight-mapllk"] != None:
         commandline += " -weight-mapllk %.4f" % self.keywords["weight-mapllk"]

      if self.keywords["weight-ramp"] != None:
         commandline += " -weight-ramp %.4f" % self.keywords["weight-ramp"]

      if self.keywords["resolution"] != None:
         commandline += " -resolution %.4f" % self.keywords["resolution"]

      if self.keywords["stats-radius"] != "":
         commandline += " -stats-radius " + self.keywords["stats-radius"]

      if self.keywords["skew-content"] != "":
         commandline += " -skew-content " + self.keywords["skew-content"]

      if self.keywords["auto-content"]:
         commandline += " -auto-content"

      if self.keywords["unbias"]:
         commandline += " -unbias"

      if self.keywords["evaluate"]:
         commandline += " -evaluate"

      if self.keywords["strict-free"]:
         commandline += " -strict-free"

      if self.keywords["ncs-volume"] != None:
         commandline += " -ncs-volume %.4f" % self.keywords["ncs-volume"]

      if self.keywords["ncs-radius"] != None:
         commandline += " -ncs-radius %.4f" % self.keywords["ncs-radius"]

      if self.keywords["ncs-operator"] != "":
         commandline += " -ncs-operator " + self.keywords["ncs-operator"]

      if self.keywords["seed"] != "":
         commandline += " -seed " + self.keywords["seed"]

      if self.keywords["verbose"] != "":
         commandline += " -verbose " + self.keywords["verbose"]

      # Record the command line to a file if we a file name has been set
      if self.commandfile != "":
         if self.debug:
            sys.stdout.write("Cpirate: writing command line to file:\n   %s\n" % self.commandfile)
            sys.stdout.write("\n")
         cmdfile=open(self.commandfile, "w")
         cmdfile.write(commandline + "\n") 
         cmdfile.close()
      else:
         sys.stdout.write("Warning: Cpirate command file not specified. Command string will not be written to a file.\n")
         sys.stdout.write("\n")

      # Launch cpirate
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (outp, inp) = (p.stdout, p.stdin)

      inp.close()

      # Write the output from cpirate to a file
      if self.logfile !="":
         if self.debug:
            sys.stdout.write("Cpirate: writing log to file:\n   %s\n" % self.logfile)
            sys.stdout.write("\n")
         logfile=open(self.logfile, "w")
         line=outp.readline()
         count=1
         while line:
            logfile.write(line)
       
            # Catch for the Free E value:
            if "Free E-correl" in line and float(string.split(line)[-1]) != 0:            
               freeE=float(string.split(line)[-1])
               sys.stdout.write("   Cycle: %d -- Free E-correl = %.3f\n" % (count, freeE))
             
               count=count + 1

            line=outp.readline()

         sys.stdout.write("\n")

         # Set the final value for FreeE
         self.finalfreeE=freeE
         sys.stdout.write("Cpirate: Final value for Free E-correl after %d cycles = %.3f\n" % (count, self.finalfreeE))
         sys.stdout.write("\n")

         logfile.close()
         outp.close()
      else:
         sys.stdout.write("Warning: Cpirate log file not specified. Log will not be written to a file.\n")
         sys.stdout.write("\n")

if __name__ == "__main__":
# Test data

   cp=Cpirate()

   cp.debug=True

   cp.setLogfile("cpirate_test.log")
   cp.setCommandfile("cpirate_test_cmd.txt")

   cp.keywords["mtzin-ref"]="mtzin-ref.mtz"
   cp.keywords["mtzin-wrk"]="mtzin-wrk.mtz"
   cp.keywords["mtzout"]="mtzout.mtz" 
   cp.keywords["colin-ref-fo"]="/*/*/[FP.F_sigF.F,FP.F_sigF.sigF]"
   cp.keywords["colin-ref-hl"]="/*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]"
   cp.keywords["colin-wrk-fo"]="/*/*/[FP,SIGFP]"
   cp.keywords["colin-wrk-hl"]="/*/*/[HLA,HLB,HLC,HLD]"
   cp.keywords["colin-wrk-free"] = "/*/*/[FREE]"
   cp.keywords["colout"] = "pirate"
   cp.keywords["ncycles"] = 3
   cp.keywords["unbias"] = True

   cp.run()

#set -e

# reference files
#mtzref_file=$CCP4/lib/data/reference_structures/reference-1ajr.mtz
#colin-ref-fo=/*/*/[FP.F_sigF.F,FP.F_sigF.sigF]
#colin-ref-hl=/*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]
#pdbref_file=$CCP4/lib/data/reference_structures/reference-1ajr.pdb

# target information
#seqin_file=~/lydia/search_100/data/../input/Mps1.seq
#colin-wrk-fo=/*/*/[F_I222,SIGF_I222]
#colin-wrk-free=/*/*/[FreeR_flag]

# MR solution
#mtzin_file=~/lydia/search_100/data/1unl_A/chainsaw/mr/phaser_1unl_A_CHNSAW.1.mtz

# output files
#mtzpir_file=~/lydia/search_100/data/1unl_A/chainsaw/building/phaser_1unl_A_CHNSAW_pirate.mtz
#pdbout_file=~/lydia/search_100/data/1unl_A/chainsaw/building/phaser_1unl_A_CHNSAW_buccaneer.pdb

# pirate in un-bias mode for MR

#cpirate -stdin << eof
#mtzin-ref $mtzref_file
#colin-ref-fo /*/*/[FP.F_sigF.F,FP.F_sigF.sigF]
#colin-ref-hl /*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]
#mtzin-wrk $mtzin_file
#colin-wrk-fo /*/*/[F_I222,SIGF_I222]
#colin-wrk-hl /*/*/[HLA,HLB,HLC,HLD]
#colin-wrk-free /*/*/[FreeR_flag]
#mtzout $mtzpir_file
#colout pirate
#ncycles 3
#unbias
##eof
