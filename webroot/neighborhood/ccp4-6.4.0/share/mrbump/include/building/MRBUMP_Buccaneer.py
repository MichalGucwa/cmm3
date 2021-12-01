#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2012 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Class for running Buccaneer in MrBUMP for model building
#
# Ronan Keegan 21/08/2012

import sys, os, string
import shlex, subprocess
import shutil

def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file

    return None

# Test for environment variables and required executables

if not "CCP4" in sorted(os.environ.keys()):
    raise RuntimeError('CCP4 not found')
if os.name == "nt":
   if not which("cbuccaneer.exe"):
      raise RuntimeError('cbuccaneer.exe not found')
else:
   if not which("cbuccaneer"):
      raise RuntimeError('cbuccaneer not found')


class Buccaneer:

   def __init__(self):
      self.pdbinFile=""
      self.mtzinFile=""
      self.hklinFile=""
      self.pdboutFile=""
      self.mtzoutFile=""
      self.currentDIR=""
      self.workingDIR=""

      self.phaserBestCC=0.0
      self.molrepBestCC=0.0
      self.phaserShelxPDB="Not set"
      self.molrepShelxPDB="Not set"
      self.buccScriptFile="buccaneer-script.sh"
      self.script=""

      self.labin=dict([])

      self.seqinFile    = ""
      self.mtzinFile    = ""
      self.pdboutFile   = ""
      self.colin_fo     = ""
      self.colin_free   = ""
      self.colin_phifom = ""
      self.colin_fc     = ""
      self.cycles       = 5

      self.prefix=""
      self.pdbin_ref=os.path.join(os.environ["CCP4"],"lib", "data", "reference_structures","reference-1tqw.pdb")
      self.mtzin_ref=os.path.join(os.environ["CCP4"],"lib", "data", "reference_structures","reference-1tqw.mtz")

      self.colin_ref_fo="FP.F_sigF.F,FP.F_sigF.sigF"
      self.colin_ref_hl="FC.ABCD.A,FC.ABCD.B,FC.ABCD.C,FC.ABCD.D"

      self.buccaneer_anisotropy_correction        = True
      self.buccaneer_fast                         = True
      self.buccaneer_1st_cycles                   = 3
      self.buccaneer_1st_sequence_reliability     = 0.95
      self.buccaneer_nth_cycles                   = 2
      self.buccaneer_nth_sequence_reliability     = 0.95
      self.buccaneer_nth_correlation_mode         = True
      self.buccaneer_new_residue_name             = "UNK"
      self.buccaneer_resolution                   = 2.0
      self.refmac_mlhl                            = 1
      self.refmac_twin                            = 0
  
      self.res_built=0
      self.completeness=0
      self.initRfact=1.0
      self.finalRfact=1.0
      self.initRfree=1.0
      self.finalRfree=1.0

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.buccLogfile="buccaneer.log"
     
   def setDebug(self, debugValue):
      self.debug=debugValue

   def setBuccScriptFile(self, filename):
      self.buccScriptFile=filename

   def setBuccLogFile(self, filename):
      self.buccLogfile=filename

   def checkFileExist(self, filename, program, type):
      """ Check to see if the PDB file has been output from Refmac in MrBUMP """

      if os.path.isfile(filename):
         status = 0
      else:
         status = 1
         sys.stdout.write("Warning: no file output from "+ program +"  for this job\n")
      
      return status

   def makeBuccStdin(self):
      """ Make the stdin for Buccaneer """

      self.buccStdin  = "pdbin-ref " + self.pdbin_ref + "\n"
      self.buccStdin += "mtzin-ref " + self.mtzin_ref + "\n"

      self.buccStdin += "colin-ref-fo " + self.colin_ref_fo + "\n"
      self.buccStdin += "colin-ref-hl " + self.colin_ref_hl + "\n"

      self.buccStdin += "seqin " + self.seqinFile + "\n"
      if os.path.isfile(os.path.join(self.workingDIR, os.path.basename(self.mtzinFile))):
         self.buccStdin += "mtzin " + os.path.basename(self.mtzinFile) + "\n"
      else:
         self.buccStdin += "mtzin " + self.mtzinFile + "\n"

      self.buccStdin += "colin-fo " + self.colin_fo + "\n"
      self.buccStdin += "colin-free " + self.colin_free + "\n"
      self.buccStdin += "colin-phifom " + self.colin_phifom + "\n"
      self.buccStdin += "colin-fc " + self.colin_fc + "\n"

      self.buccStdin += "pdbout " + self.pdboutFile + "\n"
      self.buccStdin += "cycles " + str(self.cycles) + "\n"

      if self.buccaneer_anisotropy_correction:
         self.buccStdin += "buccaneer-anisotropy-correction\n"
      if self.buccaneer_fast:
         self.buccStdin += "buccaneer-fast\n"
      self.buccStdin += "buccaneer-1st-cycles " + str(self.buccaneer_1st_cycles) + "\n"
      self.buccStdin += "buccaneer-1st-sequence-reliability " + str(self.buccaneer_1st_sequence_reliability) + "\n"
      self.buccStdin += "buccaneer-nth-cycles " + str(self.buccaneer_nth_cycles) + "\n"
      self.buccStdin += "buccaneer-nth-sequence-reliability " + str(self.buccaneer_nth_sequence_reliability) + "\n"
      if self.buccaneer_nth_correlation_mode:
         self.buccStdin += "buccaneer-nth-correlation-mode\n"
      self.buccStdin += "buccaneer-new-residue-name " + self.buccaneer_new_residue_name  + "\n"
      self.buccStdin += "buccaneer-resolution " + str(self.buccaneer_resolution) + "\n"
      self.buccStdin += "refmac-mlhl " + str(self.refmac_mlhl) + "\n"
      self.buccStdin += "refmac-twin " + str(self.refmac_twin) + "\n"
      self.buccStdin += "prefix " + self.prefix + "\n"

   def runBuccaneer(self, seqinFile, mtzinFile, pdboutFile, workingDIR, F, SIGF, FreeR_flag, PHIC, FOM, FWT, PHWT, cycles=5):
      """ Run Buccaneer """

      # Give a header output
      sys.stdout.write("############################################################\n")
      sys.stdout.write("Running Buccaneer to attempt model build...\n")
      sys.stdout.write("############################################################\n")
      sys.stdout.write("\n")

      sys.stdout.write("Running directory is:\n  %s \n" % workingDIR)
      sys.stdout.write("\n")

      self.seqinFile    = seqinFile
      self.mtzinFile    = mtzinFile
      self.pdboutFile   = pdboutFile
      self.workingDIR    = workingDIR
      self.colin_fo     = F + ", " + SIGF
      self.colin_free   = FreeR_flag
      self.colin_phifom = PHIC + ", " + FOM
      self.colin_fc     = FWT + ", " + PHWT
      self.cycles       = cycles
      self.prefix="buccaneer_pipeline/"

      self.currentDIR=os.getcwd()

      # Set up stdin details for buccaneer
      self.makeBuccStdin()
 
      os.chdir(self.workingDIR)

      command_line='python -u ' + os.path.join(os.environ["CCP4"], "bin", "buccaneer_pipeline") + ' -stdin'
      self.script  = command_line + " <<eof\n"
      self.script += self.buccStdin + "eof\n"

      file=open(self.buccScriptFile, "w")
      file.write(self.script) 
      file.close()

      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

      (child_stdin, child_stdout_and_stderr) = (p.stdin, p.stdout)
  
      # Write the keyword input
      child_stdin.write(self.buccStdin)
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      CAPTURE=False
      CAPTUREREFMAC=False
      cycle=1
      HEADER=False
      log=open(self.buccLogfile, "w")
      while out:
         log.write(out)
 
         if "Copyright" in out and "Kevin Cowtan and University of York" in out:
            if HEADER:
               sys.stdout.write("---------------------------------\n")
               sys.stdout.write("Buccaneer Autobuild round: %d\n" % cycle)
               sys.stdout.write("---------------------------------\n")
               sys.stdout.write("\n")
               cycle=cycle+1
               HEADER=False

         if "<!--SUMMARY_END--></FONT></B>" in out and CAPTURE:
            CAPTURE=False
         if CAPTURE:
            if "Internal cycle" in out:
               sys.stdout.write(out)
            if "residues were uniquely allocated" in out:
               self.res_built=int(string.split(out)[0])
               sys.stdout.write("  " + string.strip(out) + "\n")
            if "Completeness of chains" in out:
               try:
                  self.completeness=float(string.split(out)[-2].replace("%",""))
               except:
                  self.completeness=0.0
               sys.stdout.write("  " + string.strip(out) + "\n")
               sys.stdout.write("\n")
         if "<B><FONT COLOR='#FF0000'><!--SUMMARY_BEGIN-->" in out:
            CAPTURE=True
            HEADER=True

         if "$$" in string.strip(out) and CAPTUREREFMAC:
            CAPTUREREFMAC=False
            sys.stdout.write("\n")
         if CAPTUREREFMAC:
            if "Initial" in out and "Final" in out:
               sys.stdout.write(out)
            if "R factor" in out:
               self.initRfact=float(string.split(out)[2])
               self.finalRfact=float(string.split(out)[3])
               sys.stdout.write(out)
            if "R free" in out:
               self.initRfree=float(string.split(out)[2])
               self.finalRfree=float(string.split(out)[3])
               sys.stdout.write(out)
         if "$TEXT:Result: $$ Final results $$" in out:
            CAPTUREREFMAC=True
            sys.stdout.write("Refinement Results for this round:\n")
            sys.stdout.write("\n")

         if self.debug:
            sys.stdout.write(out)
         out=child_stdout_and_stderr.readline()
 
      child_stdout_and_stderr.close()
      log.close()

      status=self.checkFileExist(self.pdboutFile, "cbuccaneer", "pdb")
      if status==1:
         sys.stdout.write("Error: No output pdb file from cbuccaneer\n")

      sys.stdout.write("Log file written to:\n  %s \n" % self.buccLogfile)
      sys.stdout.write("\n")
      sys.stdout.write("PDB output file written to:\n  %s \n" % self.pdboutFile)
      sys.stdout.write("\n")

      os.chdir(self.currentDIR)

      # Set the best scores
#      if os.path.isfile(self.pdboutFile):
#         score=0.0
#         f=open(self.pdboutFile, "r")
#         line=f.readline()
#         try:
#            score=float(string.split(line)[6].replace("%",""))
#         except: 
#            sys.stdout.write("Warning (shelxe_trace): Can't find Shelxe output score in output pdb\n")
#         f.close()
#         if mrProgram.upper() == "PHASER": 
#            self.phaserBestCC=score 
#         if mrProgram.upper() == "MOLREP": 
#            self.molrepBestCC=score 

#      if self.debug == False:
#        for file in self.hklinFile, "shelxe-input.hkl", "shelxe-input.pdb", \
#                    "shelxe-input.pha", "shelxe-input.hat", \
#                    "shelxe-input.pda": 
#           if os.path.isfile(file):
#              os.remove(file) 

if __name__ == "__main__":

   if  len(sys.argv) == 4:
      mtzinFile=sys.argv[1]
      seqinFile=sys.argv[2]
      pdboutFile=sys.argv[3]
      F="F_15sep03_1xtal"
      SIGF="SIGF_15sep03_1xtal"
      FreeR_flag="FreeR_flag"
      PHIC="PHIC"
      FOM="FOM"
      FWT="FWT"
      PHWT="PHWT"
      cycles=5
   else:
      sys.stdout.write("Usage: python MRBUMP_Buccaneer.py <mtzin> <seqin> <pdbout>\n")
      sys.stdout.write("\n")
      sys.stdout.write("       e.g. python MRBUMP_Bucccaneer.py foo.mtz foo.seq fooout.pdb\n")
      sys.stdout.write("\n")
      sys.exit()
     
   BUCCANEER=Buccaneer()

   status=BUCCANEER.checkFileExist(seqinFile, "buccaneer", "pdb")
   if status==1:
      sys.exit(1)

   status=BUCCANEER.checkFileExist(mtzinFile, "buccaneer", "mtz")
   if status==1:
      sys.exit(1)

   BUCCANEER.runBuccaneer(seqinFile, mtzinFile, pdboutFile, "./", F, SIGF, FreeR_flag, PHIC, FOM, FWT, PHWT, cycles)
   #SHELX.results(mrProgram)
