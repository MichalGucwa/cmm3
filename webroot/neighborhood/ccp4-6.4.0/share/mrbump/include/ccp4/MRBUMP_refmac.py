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
# MRBUMP wrapper for CCP4 program Refmac 
# Ronan Keegan 28/2/08

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

class Refmac:

   def __init__(self):
      if os.name=="nt":
         self.refmacEXE=os.path.join(os.environ["CBIN"], "refmac5.exe")
      else:
         self.refmacEXE=os.path.join(os.environ["CBIN"], "refmac5")

      self.commandarg=dict([])
      self.keywords=dict([])

      # Command line arguments:
      self.commandarg["XYZIN"]=""      # Input PDB file
      self.commandarg["HKLIN"]=""      # Input MTZ file
      self.commandarg["TLSIN"]=""      # Input TLS file
      self.commandarg["XYZOUT"]=""     # Output PDB file
      self.commandarg["HKLOUT"]=""     # Output MTZ file
      self.commandarg["TLSOUT"]=""     # Output TLS file

      # Keywords:

      # Principal keywords controlling Xray refinement:
      self.keywords["LABI"]=""       # Columns to use in input MTZ file 
      self.keywords["NCYC"]=None     # Number of cycles of refinement
      self.keywords["REFI"]=""       # Controls the type of refinement or idealisation (subkeywords)
      self.keywords["SCAL"]=""       # Controls scaling of calculated and observed structure factors (sk) 
      self.keywords["SIGM"]=""       # Calculating SigmaA estimate (SCALe MLSC keyword) (sk) 
      self.keywords["SOLV"]=""       # Parameters for solvent mask calculation (sk)
      self.keywords["WEIG"]=""       # Controls the weighting of the X-ray and geometric parts (sk) 

      # All keywords for Xray refinement:
      self.keywords["BINS"]=None     # Number of resolution bins
      self.keywords["RANGE"]=None    # Number of resolution bins
      self.keywords["BLIM"]=""       # Minimum and maximum B-factors allowed
      self.keywords["CELL"]=""       # Defines parameters of the cell
      self.keywords["DAMP"]=""       # Pdamp & Bdamp scales shifts after each cycle of refinement
      self.keywords["FREE"]=None     # Value for exclusion for the FreeR (usually zero) 
      self.keywords["LABO"]=""       # Labels for output MTZ file
      self.keywords["MODE"]=""       # Type of refinement (sk)
      self.keywords["MONI"]=""       # Controls level of monitoring statistics during refinement (sk)
      self.keywords["PHAS"]=""       # Altering the probability distribution of given phase information 
      self.keywords["RIGI"]=""       # Controls parameters of rigid body refinement (sk)
      self.keywords["SCPA"]=""       # Partial structure factor scaling
      self.keywords["SHAN"]=""       # Tells the program to change grid spacing by a given factor
      self.keywords["SYMM"]=""       # Defines the space group symmetry name or number
      self.keywords["TLSC"]=""       # Define the number of TLS refinement cycles
      self.keywords["END"]=""        # End keyword
      self.keywords["GO"]=""         # End keyword
      self.keywords["QUIT"]=""       # End keyword
      self.keywords["STOP"]=""       # End keyword

      # Keywords controlling (geometric) restraints:
      self.keywords["ANGL"]=""       # Multiplier used in calculating weights for the the bond angle restraints
      self.keywords["BFAC"]=""       # Weight for the temperature factor restraint parameters
      self.keywords["TEMP"]=""       # Weight for the temperature factor restraint parameters
      self.keywords["CHIR"]=""       # Used in weighting Chiral group restraints 
      self.keywords["DIST"]=""       # Multiplier used in calculating the weights for the the distance restraints
      self.keywords["HOLD"]=""       # For shifting the magnitude of restraints
      self.keywords["MAKE"]=""       # Controls level of automatic restraint creation (sk)
      self.keywords["NCSR"]=""       # To define non-crystallograpic ssymmetry
      self.keywords["NONX"]=""       # To define non-crystallograpic ssymmetry
      self.keywords["PLAN"]=""       # Restraints on planarity
      self.keywords["RBON"]=""       # Rigid bond restraints on anisotropic B values of bonded atoms
      self.keywords["SPHE"]=""       # Sphericity restraints on the anistropic B values
      self.keywords["TORS"]=""       # Restraints on the torsion angles
      self.keywords["VDWR"]=""       # Restraints on nonbonding interactions
      self.keywords["VAND"]=""       # Restraints on nonbonding interactions

      # Optional keywords controlling the data harvesting functionality:
      self.keywords["DNAME"]=""      # Data set name
      self.keywords["NOHARVEST"]=""  # Do not write out deposit files
      self.keywords["PNAME"]=""      # Project Name
      self.keywords["PRIVATE"]=""    # Set directory permissions for user only
      self.keywords["RSIZE"]=""      # Max. width of row in deposit file
      self.keywords["USECWD"]=""     # Use the current working directory

      self.commandfile="" 
      self.logfile="" 

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLogfile(self, filename):
      self.logfile=filename

   def setCommandfile(self, filename):
      self.commandfile=filename

   def run(self):
      """ Set the cbuccaneer input command line and run the job. """

      if self.debug:
         sys.stdout.write("Cbuccaneer: Running cbuccaneer to build structure...\n")
         sys.stdout.write("\n")

      # Set up the cbuccaneer command line
      commandline  = self.cbuccaneerEXE

      # Add the mandatory inputs. First check to see that they have all been set correctly.
      for key in "mtzin-ref", "mtzin-wrk", "pdbin-ref", "pdbout-wrk", \
                 "colin-ref-fo", "colin-ref-hl", "colin-wrk-fo", "colin-wrk-hl": 
         if self.keywords[key]=="":
            sys.stdout.write("Cbuccaneer: Error - keyword %s is not set. This keyword is required.\n" % key)
            sys.stdout.write("\n")
            sys.exit(1)

      # Check that the input files exist.
      if os.path.isfile(self.keywords["mtzin-wrk"]) == False:
         sys.stdout.write("Cbuccaneer: Error - input MTZ (working) could not be found:\n   %s\n" % self.keywords["mtzin-wrk"])
         sys.stdout.write("\n")
         sys.exit(1)
         
      if os.path.isfile(self.keywords["mtzin-ref"]) == False:
         sys.stdout.write("Cbuccaneer: Error - input MTZ (reference) could not be found:\n   %s\n" % self.keywords["mtzin-ref"])
         sys.stdout.write("\n")
         sys.exit(1)
 
      if os.path.isfile(self.keywords["pdbin-ref"]) == False:
         sys.stdout.write("Cbuccaneer: Error - input PDB (reference) could not be found:\n   %s\n" % self.keywords["pdbin-ref"])
         sys.stdout.write("\n")
         sys.exit(1)
 
      commandline += " -mtzin-ref " + self.keywords["mtzin-ref"]
      commandline += " -mtzin-wrk " + self.keywords["mtzin-wrk"]
      commandline += " -pdbin-ref " + self.keywords["pdbin-ref"]
      commandline += " -pdbout-wrk " + self.keywords["pdbout-wrk"]
      commandline += " -colin-ref-fo " + self.keywords["colin-ref-fo"]
      commandline += " -colin-ref-hl " + self.keywords["colin-ref-hl"]
      commandline += " -colin-wrk-fo " + self.keywords["colin-wrk-fo"]
      commandline += " -colin-wrk-hl " + self.keywords["colin-wrk-hl"]

      # Output the input file details (debug):
      if self.debug:
         sys.stdout.write("Cbuccaneer: Input files:\n")
         sys.stdout.write("   Reference MTZ file: %s\n" % self.keywords["mtzin-ref"])
         sys.stdout.write("   Reference PDB file: %s\n" % self.keywords["pdbin-ref"])
         sys.stdout.write("   Working MTZ file:   %s\n" % self.keywords["mtzin-wrk"])
         if self.keywords["pdbin-wrk"] != "":
            sys.stdout.write("   Working PDB file:   %s\n" % self.keywords["pdbin-wrk"])
         sys.stdout.write("   Output PDB file:    %s\n" % self.keywords["pdbout-wrk"])
         sys.stdout.write("\n")

      # Optional keywords:
      if self.keywords["pdbin-wrk"] != "":
         if os.path.isfile(self.keywords["pdbin-wrk"]) == False:
            sys.stdout.write("Cbuccaneer: Error - input PDB (pdbin-wrk) could not be found:\n   %s\n" % self.keywords["pdbin-wrk"])
            sys.stdout.write("\n")
            sys.exit(1)
         else:
            commandline += " -pdbin-wrk " + self.keywords["pdbin-wrk"]

      if self.keywords["seqin-wrk"] != "":
         if os.path.isfile(self.keywords["seqin-wrk"]) == False:
            sys.stdout.write("Cbuccaneer: Error - input sequence file (seqin-wrk) could not be found:\n   %s\n" % self.keywords["seqin-wrk"])
            sys.stdout.write("\n")
            sys.exit(1)
         else:
            commandline += " -seqin-wrk " + self.keywords["seqin-wrk"]

      if self.keywords["resolution"] != None:
         commandline += " -resolution %.4f" % self.keywords["resolution"]

      if self.keywords["title"] != "": 
         commandline += " -title %s" % self.keywords["title"]

      if self.keywords["find"]:
         commandline += " -find"

      if self.keywords["grow"]:
         commandline += " -grow"

      if self.keywords["link"]:
         commandline += " -link"

      if self.keywords["sequence"]:
         commandline += " -sequence"

      if self.keywords["correct"]:
         commandline += " -correct"

      if self.keywords["filter"]:
         commandline += " -filter"

      if self.keywords["prune"]:
         commandline += " -prune"

      if self.keywords["build"]:
         commandline += " -build"

      if self.keywords["ncsbuild"]:
         commandline += " -ncsbuild"

      if self.keywords["rebuild"]:
         commandline += " -rebuild"

      if self.keywords["cycles"] != None:
         commandline += " -cycles %d" % self.keywords["cycles"]

      if self.keywords["fragments"] != None:
         commandline += " -fragments %d" % self.keywords["fragments"]

      if self.keywords["fragments-per-100-residues"] != None:
         commandline += " -fragments-per-100-residues %d" % self.keywords["fragments-per-100-residues"]

      if self.keywords["ramachandran-filter"] != "":
         commandline += " -ramachandran-filter " + self.keywords["ramachandran-filter"]

      if self.keywords["main-chain-likelihood-radius"] != None:
         commandline += " -main-chain-likelihood-radius %.4f" % self.keywords["main-chain-likelihood-radius"]

      if self.keywords["side-chain-likelihood-radius"] != None:
         commandline += " -side-chain-likelihood-radius %.4f" % self.keywords["side-chain-likelihood-radius"]

      if self.keywords["sequence-reliability"] != None:
         commandline += " -sequence-reliability %.4f" % self.keywords["sequence-reliability"]

      if self.keywords["new-residue-name"] != "":
         commandline += " -new-residue-name " + self.keywords["new-residue-name"]

      if self.keywords["new-residue-type"] != "":
         commandline += " -new-residue-type " + self.keywords["new-residue-type"]

      if self.keywords["verbose"] != "":
         commandline += " -verbose " + self.keywords["verbose"]

      # Record the command line to a file if a file name has been set
      if self.commandfile != "":
         if self.debug:
            sys.stdout.write("Cbuccaneer: writing command line to file:\n   %s\n" % self.commandfile)
            sys.stdout.write("\n")
         cmdfile=open(self.commandfile, "w")
         cmdfile.write(commandline + "\n") 
         cmdfile.close()
      else:
         sys.stdout.write("Warning: Cbuccaneer command file not specified. Command string will not be written to a file.\n")
         sys.stdout.write("\n")

      # Launch refmac
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
            sys.stdout.write("Cbuccaneer: writing log to file:\n   %s\n" % self.logfile)
            sys.stdout.write("\n")
         logfile=open(self.logfile, "w")
         line=outp.readline()
         while line:
            logfile.write(line)
            line=outp.readline()

         logfile.close()
         outp.close()
      else:
         sys.stdout.write("Warning: Cbuccaneer log file not specified. Log will not be written to a file.\n")
         sys.stdout.write("\n")

if __name__ == "__main__":
# Test data

   cb=Cbuccaneer()

   cb.debug=True

   cb.setLogfile("cbuccaneer.log")
   cb.setCommandfile("cbuccaneer.txt")

   cb.keywords["mtzin-ref"]="mtzin-ref.mtz"
   cb.keywords["pdbin-ref"]="pdbin-ref.pdb"
   cb.keywords["mtzin-wrk"]="mtzin-wrk.mtz"
   cb.keywords["pdbout-wrk"]="pdbout-wrk.pdb" 
   cb.keywords["seqin-wrk"]="temp.pir" 
   cb.keywords["colin-ref-fo"]="/*/*/[FP.F_sigF.F,FP.F_sigF.sigF]"
   cb.keywords["colin-ref-hl"]="/*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]"
   cb.keywords["colin-wrk-fo"]="/*/*/[FP,SIGFP]"
   cb.keywords["colin-wrk-hl"]="/*/*/[pirate.ABCD.A,pirate.ABCD.B,pirate.ABCD.C,pirate.ABCD.D]"
   cb.keywords["find"] = True
   cb.keywords["grow"] = True
   cb.keywords["join"] = True
   cb.keywords["link"] = True
   cb.keywords["sequence"] = True
   cb.keywords["correct"] = True
   cb.keywords["filter"] = True
   cb.keywords["prune"] = True
   cb.keywords["ncsbuild"] = True
   cb.keywords["rebuild"] = True
   cb.keywords["cycles"] = 3
   cb.keywords["resolution"] = 2.0
   cb.keywords["new-residue-name"] = "UNK"
   cb.keywords["sequence-reliability"] = 0.95

   cb.run()

#         :1-* colin-wrk-phifom /*/*/[PHCOMB,FOM]
#         :1-* pdbin-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.pdb
#         :1-* cycles 1
#         :1-* correlation-mode
#         :1-* sequence-reliability 0.95
#
#          pdbin-ref /home/rmk65/opt/ccp4/6.0.99b/ccp4-6.0.99b/lib/data/reference_structures/reference-1tqw.pdb
#          mtzin-ref /home/rmk65/opt/ccp4/6.0.99b/ccp4-6.0.99b/lib/data/reference_structures/reference-1tqw.mtz
#          colin-ref-fo /*/*/[FP.F_sigF.F,FP.F_sigF.sigF]
#          colin-ref-hl /*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]
#          mtzin-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.mtz
#          colin-wrk-fo /*/*/[FP,SIGFP]
#         :0 colin-wrk-hl /*/*/[pirate.ABCD.A,pirate.ABCD.B,pirate.ABCD.C,pirate.ABCD.D]
#          pdbout-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_buccaneer.pdb
#          title test emma soln
#          find
#          grow
#          join
#          link
#          sequence
#          correct
#          filter
#          prune
#          ncsbuild
#          rebuild
#         :0 cycles 3
#          resolution 2.0
##          new-residue-name UNK
#         :0 sequence-reliability 0.95
#          seqin-wrk /home/rmk65/projects/emma/orig_data/temp.pir
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
