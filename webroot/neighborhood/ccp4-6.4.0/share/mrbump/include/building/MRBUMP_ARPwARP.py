#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2012 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Class for running ARP/wARP in MrBUMP for model building
#
# Ronan Keegan 24/08/2012

#Usage:
#auto_tracing.sh                                                                     \
#     datafile {mtzfile}			                                     \
#     [residues {number_of_residues_in_AU}]                                          \
#     [workdir {FULLPATH_WORKING_DIRECTORY}]                                         \
#     [fp {fp_label}] [sigfp {sigfp_label}] [freelabin {freer_label}]                \
#     [fbest {weighted_amplitude_label}] [phibest {phibest_label}] [fom {fom_label}] \
#     [modelin {input_PDB_file_to_use_as_initial_model}]                             \
#     [seqin {sequence_file_for_one_NCS_copy}]                                       \
#     [cgr {number_of_NCS_copies (if seqin is provided, default is 1) }]             \
#     [buildingcycles {the_number_of_autobuilding_cycles (default is 10) }]          \
#     [resol {'rmin rmax' (default is the full resolution range) }]                  \
#     [albe {1 to_always_invoke_albe, default is 0 for resol < 2.7A, else 1) }]      \
#     [restraints {1 to use conditional restraints, default is 1 }]                  \
#     [twin {1 to try de-twining and twin refinement, default is 0 }]                \
#     [sad {1 to turn on the SAD function refinement,                                \
#       needs also 'wavelength' and 'heavyin' on input, default is 0 }]              \
#     [compareto {PDB_file_for_comparison}]                                          \
#     [parfile {parfilename_if_only_parfile_is_to_be_created}]                       \
# - Optional command line arguments are given in square parentheses
# - Possible combinations of MTZ labels are:
#     For start from phases:
#       fp/sigfp/phibest/fom or fbest/sigfp/phibest to build initial free-atoms model
#       and fp/sigfp to refine the model
#       If 'fbest' is given, 'fom' will be ignored
#     For start from a model:
#       fp/sigfp to refine the model
# - All input files are assumed to be located in working directory
#   unless they are given with full path
# - If workdir is not given, the current directory will be assumed
# - All output files will be written into workdir/subdirectory
#Additional useful tips:
# - Normally the job runs in a subdirectory called YYYYMMDD_HHMMSS
#   To run the job in the current directory use: auto_tracing.sh jobId '.'
# - If you invoke auto_tracing.sh from another script and the keywords with
#   double-word argument are not properly understood, e.g. resol '20.0 2.5',
#   try resol 20.0;2.5 or resol '20.0;2.5'
# - If you have a par file from an earlier version of ARP/wARP and would like to
#   re-run that job now, use: auto_tracing.sh defaults OLD_PAR_FILE
#   This will create a par file compatible with the current ARP/wARP version
#   and the keywords, which are new to OLD_PAR_FILE will take their default values
# - NCS-based chain extension and NCS restraints with Refmac are applied
#   automatically if the resolution of the data is equal to or lower than 2.1 A.
#   Input 'ncsextension 1/0' to apply / not apply NCS extension regardless of the 
#   resolution of the data. Input 'ncsrestraints 1/0' has similar effect


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
#if not "warpbin" in sorted(os.environ.keys()):
#    raise RuntimeError('warpbin not found')
#if os.name == "nt":
#   if not which("auto_tracing.sh"):
#      raise RuntimeError('auto_tracing.sh not found')
#else:
#   if not which("auto_tracing.sh"):
#      raise RuntimeError('auto_tracing.sh not found')


class Arpwarp:

   def __init__(self):
      self.pdbinFile=""
      self.mtzinFile=""
      self.seqinFile=""
      
      self.pdboutFile=""
      self.mtzoutFile=""

      self.residues=0

      self.currentDIR=""
      self.workingDIR=""
      self.args=""

      self.arpwarpScriptFile="arpwarp-script.sh"
      self.script=""

      self.labin=dict([])

      self.fp          = ""
      self.sigfo       = ""
      self.free        = ""
      self.fbest       = ""
      self.phibest     = ""
      self.fom         = ""

      self.buildingCycles = 10 

      self.res_built=0
      self.completeness=0
      self.initRfact=1.0
      self.finalRfact=1.0
      self.initRfree=1.0
      self.finalRfree=1.0

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=True

      self.arpwarpLogfile="arpwarp.log"
     
   def setDebug(self, debugValue):
      self.debug=debugValue

   def setArpwarpScriptFile(self, filename):
      self.arpwarpScriptFile=filename

   def setArpwarpLogFile(self, filename):
      self.arpwarpLogfile=filename

   def checkFileExist(self, filename, program, type):
      """ Check to see if the PDB file has been output from Refmac in MrBUMP """

      if os.path.isfile(filename):
         status = 0
      else:
         status = 1
         sys.stdout.write("Warning: no file output from "+ program +"  for this job\n")
      
      return status

   def makeArpwarpArgs(self):
      """ Make the command line arguments for ARP/wARP """

      self.args  = " jobId '.' "
      self.args += " datafile " + self.mtzinFile
      self.args += " residues " + str(self.residues)
      self.args += " seqin " + self.seqinFile
      self.args += " fp " + self.fp
      self.args += " sigfp " + self.sigfp
      self.args += " freelabin " + self.free
      if self.fbest != "":
         self.args += " fbest " + self.fbest
      self.args += " phibest " + self.phibest
      self.args += " fom " + self.fom
      self.args += " buildingcycles " + str(self.buildingcycles)
      self.args += " workdir " + self.workingDIR

   def runARPwARP(self, seqinFile, mtzinFile, workingDIR, FP, SIGFP, FREE, PHIBEST, FOM, residues, FBEST="", cycles=10):
      """ Run ARP/wARP """

      # Give a header output
      sys.stdout.write("############################################################\n")
      sys.stdout.write("Running ARP/wARP to attempt model build...\n")
      sys.stdout.write("############################################################\n")
      sys.stdout.write("\n")

      sys.stdout.write("Running directory is:\n  %s \n" % workingDIR)
      sys.stdout.write("\n")

      self.seqinFile        = seqinFile
      self.mtzinFile        = mtzinFile
      self.residues         = residues
      self.workingDIR       = workingDIR
      self.fp               = FP
      self.sigfp            = SIGFP
      self.free             = FREE
      self.fbest            = FBEST
      self.phibest          = PHIBEST
      self.fom              = FOM
      self.buildingcycles   = cycles

      self.currentDIR=os.getcwd()
 
      self.pdboutFile=os.path.join(self.workingDIR, os.path.splitext(os.path.split(mtzinFile)[1])[0] + "_warpNtrace.pdb")
      self.mtzoutFile=os.path.join(self.workingDIR, os.path.splitext(os.path.split(mtzinFile)[1])[0] + "_warpNtrace.mtz")

      # Set up command line arguments for ARP/wARP
      self.makeArpwarpArgs()
 
      os.chdir(self.workingDIR)

      command_line=os.path.join(os.environ["warpbin"], "auto_tracing.sh") + self.args 
      self.script  = command_line + "\n"

      file=open(self.arpwarpScriptFile, "w")
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
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      CAPTURE=False
      cycle=0
      res_built=0
      Rfact=1.0
      Rfree=1.0
      log=open(self.arpwarpLogfile, "w")
      while out:
         log.write(out)
 
         if "Building Cycle" in out and "Atomic shape" in out:
            if self.debug==False:
               sys.stdout.write("\n")
               sys.stdout.write("---------------------------------\n")
               sys.stdout.write("ARP/wARP Autobuild cycle: %d\n" % cycle)
               sys.stdout.write("---------------------------------\n")
               sys.stdout.write("\n")
            cycle=cycle+1

         if "Estimated correctness" in out:
            if self.debug==False:
               sys.stdout.write(out)
         if "docked in sequence" in out:
            res_built=int(string.split(out)[2].replace("(",""))
            if self.debug==False:
               sys.stdout.write(out)
               sys.stdout.write("\n")
         if "After refmac" in out:
            CAPTURE = True
            Rfact=float(string.split(string.split(out, "R =")[1])[0])
            Rfree=float(string.split(string.split(out, "Rfree =")[1])[0].replace(").","").replace(")",""))
            Rcycle=string.split(out)[1]
            if cycle==0:
               self.initRfact=Rfact
               self.initRfree=Rfree
         if CAPTURE and "------------------" in out:
            CAPTURE = False
            if self.debug==False:
               sys.stdout.write("Refinement cycle %s R = %.3lf Rfree = %.3lf\n" % (Rcycle, Rfact, Rfree))

         if self.debug:
            sys.stdout.write(out)
         out=child_stdout_and_stderr.readline()
 
      child_stdout_and_stderr.close()
      log.close()

      self.res_built=res_built
      self.finalRfact=Rfact
      self.finalRfree=Rfree
      sys.stdout.write("Log file written to:\n  %s \n" % self.arpwarpLogfile)
      sys.stdout.write("\n")

      status=self.checkFileExist(self.pdboutFile, "arpwarp", "pdb")
      if status==1:
         sys.stdout.write("Warning: No output pdb file from arpwarp\n")
      if status==0:
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
      residues=int(sys.argv[3])
      FP="F_15sep03_1xtal"
      SIGFP="SIGF_15sep03_1xtal"
      FREE="FreeR_flag"
      PHIBEST="PHIC"
      FOM="FOM"
      cycles=5
   else:
      sys.stdout.write("Usage: python MRBUMP_ARPwARP.py <mtzin> <seqin> <nres>\n")
      sys.stdout.write("\n")
      sys.stdout.write("       e.g. python MRBUMP_ARPwARP.py foo.mtz foo.seq 120\n")
      sys.stdout.write("\n")
      sys.exit()
     
   ARPWARP=Arpwarp()

   status=ARPWARP.checkFileExist(seqinFile, "arpwap", "seq")
   if status==1:
      sys.exit(1)

   status=ARPWARP.checkFileExist(mtzinFile, "arpwarp", "mtz")
   if status==1:
      sys.exit(1)

   ARPWARP.runARPwARP(seqinFile, mtzinFile, os.getcwd(), FP, SIGFP, FREE, PHIBEST, FOM, residues, cycles=cycles)
   #SHELX.results(mrProgram)
