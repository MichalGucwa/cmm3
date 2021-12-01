#! /usr/bin/env ccp4-python
#     Copyright (C) 2008 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# MRBUMP wrapper for CCP4 program Buccaneer 
# Ronan Keegan 18/2/08


import os, string, sys
import subprocess, shlex

if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'
if not os.environ.has_key('http_proxy'):
    print "http_proxy not specified in environemnt"

# Import the CBIN directory into the python path 
sys.path.append(os.environ["CBIN"])

class Buc_Ref:
   """ Cycle buccaneer and refmac. """

   def __init__(self):

      self.pipelineEXE=os.path.join(os.environ["CBIN"], "ccp4_pipeline_simple.py")
      if os.path.isfile(self.pipelineEXE) == False:
         sys.stdout.write("Error: Could not find ccp4_pipeline_simple.py\n")
         sys.exit()
 
      self.logfile=""
      self.commandfile=""

      self.ncycles=3

      # Buccaneer variables

      self.bucc_title=""
      self.bucc_referencePDBIN=os.path.join(os.environ["CLIB"], "data", "reference_structures", "reference-1tqw.pdb")
      self.bucc_referenceMTZIN=os.path.join(os.environ["CLIB"], "data", "reference_structures", "reference-1tqw.mtz")

      self.bucc_referenceCol=dict([])
      self.bucc_referenceCol["FP"]="FP.F_sigF.F"
      self.bucc_referenceCol["SIGFP"]="FP.F_sigF.sigF"
      self.bucc_referenceCol["HLA"]="FC.ABCD.A"
      self.bucc_referenceCol["HLB"]="FC.ABCD.B"
      self.bucc_referenceCol["HLC"]="FC.ABCD.C"
      self.bucc_referenceCol["HLD"]="FC.ABCD.D"

      self.bucc_SEQIN=""
      self.bucc_workMTZIN=""

      self.bucc_workCol=dict([])
      self.bucc_workCol["FP"]=""
      self.bucc_workCol["SIGFP"]=""
      self.bucc_workCol["HLA"]=""
      self.bucc_workCol["HLB"]=""
      self.bucc_workCol["HLC"]=""
      self.bucc_workCol["HLD"]=""

      self.bucc_cycles=[]
      self.bucc_seqReliability=[]
      self.bucc_Resolution=0.0

      # Refmac variables

      self.refmac_title=""

      self.refmac_MTZIN=""
      self.refmac_PDBIN=""
      self.refmac_MTZOUT=""
      self.refmac_PDBOUT=""

      self.refmac_Col=dict([])
      self.refmac_Col["FP"]=""
      self.refmac_Col["SIGFP"]=""
      self.refmac_Col["HLA"]=""
      self.refmac_Col["HLB"]=""
      self.refmac_Col["HLC"]=""
      self.refmac_Col["HLD"]=""

      self.commandfile=""
      self.logfile="" 

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   # Buccaneer Settings

   def setbucc_title(self, name):
      self.bucc_title=name

   def setbucc_SEQIN(self, filename):
      self.bucc_SEQIN=filename

   def setbucc_workMTZIN(self, filename):
      self.bucc_workMTZIN=filename

   def setbucc_workPDBIN(self, filename):
      self.bucc_workPDBIN=filename

   def setbucc_workPDBOUT(self, filename):
      self.bucc_workPDBOUT=filename

   def setbucc_workCol(self, label, value):
      self.bucc_workCol[label]=value

   def setbucc_cycles(self, value):
      self.bucc_cycles=value

   def setbucc_seqReliability(self, value):
      self.bucc_seqReliability=value
 
   def setbucc_Resolution(self, value):
      self.bucc_Resolution=value
 
   # Refmac Settings

   def setrefmac_title(self, name):
      self.refmac_title=name

   def setrefmac_MTZIN(self, filename):
      self.refmac_MTZIN=filename

   def setrefmac_PDBIN(self, filename):
      self.refmac_PDBIN=filename

   def setrefmac_MTZOUT(self, filename):
      self.refmac_MTZOUT=filename

   def setrefmac_PDBOUT(self, filename):
      self.refmac_PDBOUT=filename

   def setrefmac_Col(self, label, value):
      self.refmac_Col[label]=value

   # Genereal Settings
  
   def setLogfile(self, filename):
      self.logfile=filename

   def setCommandfile(self, filename):
      self.commandfile=filename

   def makeCommfile(self, ncycles=3):
      """ Set up the command file for cycling buc and ref """

      self.ncycles=ncycles

      cf=open(self.commandfile, "w")
 
      cf.write("\n")
      cf.write("##############################################################\n")
      cf.write("###         Command script for running Buc/Refmac          ###\n")
      cf.write("##############################################################\n")
      cf.write("\n")

      cf.write("%%loop-cyc %d\n" % self.ncycles)
      cf.write("%prgm-loop buccaneer cbuccaneer %exit\n")
      cf.write("%prgm-loop refmac refmac5 %exit\n")

      cf.write("\n")

      cf.write("buccaneer %arg -stdin\n")
      cf.write("buccaneer title %s\n" % self.bucc_title)
      cf.write("buccaneer pdbin-ref %s\n" % self.bucc_referencePDBIN)
      cf.write("buccaneer mtzin-ref %s\n" % self.bucc_referenceMTZIN)
      cf.write("buccaneer colin-ref-fo /*/*/[%s,%s]\n" % (self.bucc_referenceCol["FP"],self.bucc_referenceCol["SIGFP"]))
      cf.write("buccaneer colin-ref-hl /*/*/[%s,%s,%s,%s]\n" % (self.bucc_referenceCol["HLA"],self.bucc_referenceCol["HLB"], \
                                                                self.bucc_referenceCol["HLC"],self.bucc_referenceCol["HLD"]))
      cf.write("buccaneer seqin-wrk %s\n" % self.bucc_SEQIN)
      cf.write("buccaneer mtzin-wrk %s\n" % self.bucc_workMTZIN)
      cf.write("buccaneer colin-wrk-fo /*/*/[%s,%s]\n" % (self.bucc_workCol["FP"],self.bucc_workCol["SIGFP"]))
      cf.write("buccaneer:0 colin-wrk-hl /*/*/[%s,%s,%s,%s]\n" % (self.bucc_workCol["HLA"],self.bucc_workCol["HLB"], \
                                                                  self.bucc_workCol["HLC"],self.bucc_workCol["HLD"]))
      cf.write("buccaneer:1-* colin-wrk-phifom /*/*/[%s,%s]\n" % (self.bucc_workCol["PHCOMB"],self.bucc_workCol["FOM"]))
      cf.write("buccaneer:1-* pdbin-wrk %s\n" % self.bucc_workPDBIN)
      cf.write("buccaneer pdbout-wrk %s\n" % self.bucc_workPDBOUT)
      cf.write("buccaneer find\n")
      cf.write("buccaneer grow\n")
      cf.write("buccaneer join\n")
      cf.write("buccaneer link\n")
      cf.write("buccaneer sequence\n")
      cf.write("buccaneer correct\n")
      cf.write("buccaneer filter\n")
      cf.write("buccaneer ncsbuild\n")
      cf.write("buccaneer prune\n")
      cf.write("buccaneer rebuild\n")
      cf.write("buccaneer:0 cycles %d\n" % self.bucc_cycles[0])
      cf.write("buccaneer:0 sequence-reliability %.3f\n" % self.bucc_seqReliability[0])
      cf.write("buccaneer:1-* cycles %d\n" % self.bucc_cycles[1])
      cf.write("buccaneer:1-* correlation-mode\n")
      cf.write("buccaneer:1-* sequence-reliability %.3f\n" % self.bucc_seqReliability[1])
      cf.write("buccaneer new-residue-name UNK\n")
      cf.write("buccaneer resolution %.3f\n" % self.bucc_Resolution)

      if os.path.isfile(self.refmac_MTZIN) == False:
         sys.stdout.write("CCP4_pipeline Error: Input MTZ for refmac not found:\n   %s\n" % self.refmac_MTZIN)
         sys.stdout.write("\n")
         sys.exit()
      else:
         cf.write("refmac %%arg HKLIN %s\n" % self.refmac_MTZIN)
      cf.write("refmac %%arg XYZIN %s\n" % self.refmac_PDBIN)
      cf.write("refmac %%arg HKLOUT %s\n" % self.refmac_MTZOUT)
      cf.write("refmac %%arg XYZOUT %s\n" % self.refmac_PDBOUT)

      cf.write("refmac title %s\n" % self.refmac_title)
      cf.write("refmac weight MATRIX 0.1\n")
      cf.write("refmac labin -\n")
      cf.write("refmac HLA=%s HLB=%s HLC=%s HLD=%s -\n" % (self.refmac_Col["HLA"],self.refmac_Col["HLB"],self.refmac_Col["HLC"],self.refmac_Col["HLD"]))
      cf.write("refmac FP=%s SIGFP=%s\n" % (self.refmac_Col["FP"],self.refmac_Col["SIGFP"]))
      cf.write("refmac make check NONE\n")
      cf.write("refmac make newligand CONTINUE\n")
      cf.write("refmac make hydrogen YES hout NO peptide NO cispeptide YES ssbridge YES symmetry YES sugar YES connectivity NO link NO\n")
      cf.write("refmac refi type REST PHASE SCBL 1.0 BBLU 0.0 resi MLKF meth CGMAT bref ISOT\n")

      cf.close()

   def run(self, ncycles=3):
      """ Run the pipeline to cycle buccaneer and refmac """

      # Record the command line to a file if a file name has been set
      if self.commandfile != "":
         if self.debug:
            sys.stdout.write("CCP4 pipeline: writing command line to file:\n   %s\n" % self.commandfile)
            sys.stdout.write("\n")
         self.makeCommfile()
      else:
         sys.stdout.write("Warning: CCP4 pipeline: command file not specified. Command string will not be written to a file.\n")
         sys.stdout.write("\n")

      # Set the command line
      command_line = "python " + self.pipelineEXE

      # Launch buccaneer
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (outp, inp) = (p.stdout, p.stdin)

      inp.write(self.commandfile)
      inp.close()

      # Write the output from cpirate to a file
      if self.logfile !="":
         if self.debug:
            sys.stdout.write("CCP4 pipeline: writing log to file:\n   %s\n" % self.logfile)
            sys.stdout.write("\n")
         logfile=open(self.logfile, "w")
         line=outp.readline()
         while line:
            logfile.write(line)
            line=outp.readline()

         logfile.close()
         outp.close()
      else:
         sys.stdout.write("Warning: CCP4 pipeline log file not specified. Log will not be written to a file.\n")
         sys.stdout.write("\n")
      
 
if __name__ == "__main__":
# Test data

   cbr=Buc_Ref()

   cbr.debug = True

   cbr.setLogfile("cbuccref.log")
   cbr.setCommandfile("cbuccref.txt")

   cbr.setbucc_title("Test")
   cbr.setbucc_SEQIN("test_data/temp.pir")
   cbr.setbucc_workMTZIN("test_data/bucc_in.mtz")
   cbr.setbucc_workPDBIN("test_data/refmac_out.pdb")
   cbr.setbucc_workPDBOUT("test_data/workout.pdb")

   cbr.bucc_workCol["FP"]="FP"
   cbr.bucc_workCol["SIGFP"]="SIGFP"
   cbr.bucc_workCol["HLA"]="pirate.ABCD.A"
   cbr.bucc_workCol["HLB"]="pirate.ABCD.B"
   cbr.bucc_workCol["HLC"]="pirate.ABCD.C"
   cbr.bucc_workCol["HLD"]="pirate.ABCD.D"
   cbr.bucc_workCol["PHCOMB"]="PHCOMB"
   cbr.bucc_workCol["FOM"]="FOM"

   cbr.bucc_cycles.append(3)
   for i in range(cbr.ncycles-1):
      cbr.bucc_cycles.append(1)

   cbr.bucc_seqReliability.append(0.95)
   for i in range(cbr.ncycles-1):
      cbr.bucc_seqReliability.append(0.95)
   cbr.setbucc_Resolution(2.0)

   cbr.setrefmac_title("Test job")
 
   cbr.setrefmac_MTZIN("test_data/workin.mtz")
   cbr.setrefmac_PDBIN("test_data/workout.pdb")
   cbr.setrefmac_MTZOUT("test_data/bucc_in.mtz")
   cbr.setrefmac_PDBOUT("test_data/refmac_out.pdb")

   cbr.refmac_Col["FP"]="FP"
   cbr.refmac_Col["SIGFP"]="SIGFP"
   cbr.refmac_Col["HLA"]="pirate.ABCD.A"
   cbr.refmac_Col["HLB"]="pirate.ABCD.B"
   cbr.refmac_Col["HLC"]="pirate.ABCD.C"
   cbr.refmac_Col["HLD"]="pirate.ABCD.D"

   cbr.run()

#%loop-cyc 2
#%copy-pre /home/rmk65/projects/mrbump-DEV/pirate/phaser_1ae7_A_CHNSAW.1_pirate1.mtz /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.mtz
#%prgm-loop buccaneer cbuccaneer %exit
#%prgm-loop refmac refmac5 %exit
#%copy-post /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.pdb /home/rmk65/projects/mrbump-DEV/pirate/phaser_1ae7_A_CHNSAW.1_pirate1_buccaneer2.pdb
#buccaneer %arg -stdin
#buccaneer title test emma soln
#buccaneer pdbin-ref /home/rmk65/opt/ccp4/6.0.99b/ccp4-6.0.99b/lib/data/reference_structures/reference-1tqw.pdb
#buccaneer mtzin-ref /home/rmk65/opt/ccp4/6.0.99b/ccp4-6.0.99b/lib/data/reference_structures/reference-1tqw.mtz
#buccaneer colin-ref-fo /*/*/[FP.F_sigF.F,FP.F_sigF.sigF]
#buccaneer colin-ref-hl /*/*/[FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D]
#buccaneer seqin-wrk /home/rmk65/projects/emma/orig_data/temp.pir
#buccaneer mtzin-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.mtz
#buccaneer colin-wrk-fo /*/*/[FP,SIGFP]
#buccaneer:0 colin-wrk-hl /*/*/[pirate.ABCD.A,pirate.ABCD.B,pirate.ABCD.C,pirate.ABCD.D]
#buccaneer:1-* colin-wrk-phifom /*/*/[PHCOMB,FOM]
#buccaneer:1-* pdbin-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.pdb
#buccaneer pdbout-wrk /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_buccaneer.pdb
#buccaneer find
#buccaneer grow
#buccaneer join
#buccaneer link
#buccaneer sequence
#buccaneer correct
#buccaneer filter
#buccaneer ncsbuild
#buccaneer prune
#buccaneer rebuild
#buccaneer:0 cycles 3
#buccaneer:0 sequence-reliability 0.95
#buccaneer:1-* cycles 1
#buccaneer:1-* correlation-mode
#buccaneer:1-* sequence-reliability 0.95
#buccaneer new-residue-name UNK
#buccaneer resolution 2.0
#refmac %arg HKLIN /home/rmk65/projects/mrbump-DEV/pirate/phaser_1ae7_A_CHNSAW.1_pirate1.mtz
#refmac %arg XYZIN /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_buccaneer.pdb
#refmac %arg HKLOUT /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.mtz
#refmac %arg XYZOUT /home/rmk65/projects/mrbump-DEV/pirate/21_temporary_refmac.pdb
#refmac title test emma soln
#refmac weight MATRIX 0.1
#refmac labin -
#refmac HLA=pirate.ABCD.A HLB=pirate.ABCD.B HLC=pirate.ABCD.C HLD=pirate.ABCD.D -
#refmac FP=FP SIGFP=SIGFP
#refmac make check NONE
#refmac make newligand CONTINUE
#refmac make hydrogen YES hout NO peptide NO cispeptide YES ssbridge YES symmetry YES sugar YES connectivity NO link NO
#refmac refi type REST PHASE SCBL 1.0 BBLU 0.0 resi MLKF meth CGMAT bref ISOT
