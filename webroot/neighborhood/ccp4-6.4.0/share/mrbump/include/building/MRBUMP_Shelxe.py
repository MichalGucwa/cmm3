#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2012 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Class for running Shelxe in Ample for c-alpha tracing
#
# Ronan Keegan 04/05/2012

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
   if not which("mtz2various.exe"):
      raise RuntimeError('mtz2various.exe not found')
else:
   if not which("mtz2various"):
      raise RuntimeError('mtz2various not found')
#if not which("shelxe"):
#    raise RuntimeError('shelxe not found')

class Shelxe:

   def __init__(self):
      self.pdbinFile=""
      self.mtzinFile=""
      self.hklinFile=""
      self.pdboutFile=""
      self.phsoutFile=""

      self.phaserBestCC=0.0
      self.molrepBestCC=0.0
      self.phaserShelxPDB="Not set"
      self.molrepShelxPDB="Not set"
      self.shelxScriptFile="shelx-script.sh"
      self.script=""

      self.labin=dict([])

      try:
         self.debug=eval(os.environ['AMPLE_DEBUG'])
      except:
         self.debug=False

      self.mtz2variousLogfile="mtz2various.log"
      self.shelxeLogfile="shelxe.log"
      self.workingDIR=""
     
   def setDebug(self, debugValue):
      self.debug=debugValue

   def setShelxScriptFile(self, filename):
      self.shelxScriptFile=filename

   def setShelxeLogFile(self, filename):
      self.shelxeLogfile=filename

   def setShelxWorkingDIR(self, dirname):
      self.workingDIR=dirname

   def checkFileExist(self, filename, program, type):
      """ Check to see if the PDB file has been outout from Refmac in MrBUMP """

      if os.path.isfile(filename):
         status = 0
      else:
         status = 1
         sys.stdout.write("Warning: no file output from "+ program +"  for this job\n")
      
      return status

   def runMtz2Various(self, fp="FP", sigfp="SIGFP", free="FreeR_flag"):
      """ Run mtz2various to convert the MTZ file for Shelxe """

      self.hklinFile=os.path.splitext(self.mtzinFile)[0] + ".hkl"

      command_line='mtz2various HKLIN %s HKLOUT %s' % (self.mtzinFile, self.hklinFile)

      self.script += command_line + " << eof\n"

      key  = "LABIN FP=%s SIGFP=%s FREE=%s\n" % (fp, sigfp, free)
      key += "OUTPUT SHELX\n"
      key += "FSQUARED\n"
      key += "END\n"
   
      self.script += key + "eof\n\n"

      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)


      #process_args = shlex.split(command_line)
      #p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
      #                            stdout = subprocess.PIPE, stderr=subprocess.STDOUT)
  
      (child_stdin, child_stdout_and_stderr) = (p.stdin, p.stdout)
  
      # Write the keyword input
      child_stdin.write(key)
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      log=open(self.mtz2variousLogfile, "w")

      while out:
         out=child_stdout_and_stderr.readline()
         log.write(out)
         if self.debug:
            sys.stdout.write(out)
  
      child_stdout_and_stderr.close()
      log.close()

      status=self.checkFileExist(self.hklinFile, "mtz2various", "hkl")
      if status==1:
         sys.stdout.write("Error: No output file from mtz2various\n")

   def runMtz2hkl(self, rfree_flag=""):
      """ Run mtz2hkl to convert the MTZ file for Shelx """

      if rfree_flag != "":
         command_line='mtz2hkl -2 orig -r %s' % rfree_flag
      else:
         command_line='mtz2hkl -2 orig'

      self.script += command_line + "\n"

      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

#      process_args = shlex.split(command_line)
#      p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
#                                  stdout = subprocess.PIPE, stderr=subprocess.STDOUT)
  
      (child_stdin, child_stdout_and_stderr) = (p.stdin, p.stdout)
  
      # Write the keyword input
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      while out:
         sys.stdout.write(out)
         out=child_stdout_and_stderr.readline()
  
      child_stdout_and_stderr.close()

      status=self.checkFileExist("orig.hkl", "mtz2hkl", "hkl")
      if status==1:
         sys.stdout.write("Error: No output file from mtz2hkl\n")

   def runShelxe(self, solvent, resolution, mrProgram, pdbinFile, mtzinFile, pdboutFile="shelxe-output.pdb", phsoutFile="shelxe-output.phs", traceCycles=20, \
                 fp="FP", sigfp="SIGFP", free="FreeR_flag", shelxeEXE="shelxe"):
      """ Run shelxe """

      # Give a header output
      sys.stdout.write("############################################################\n")
      sys.stdout.write("Running Shelxe to do phase improvement and c-alpha trace...\n")
      sys.stdout.write("############################################################\n")
      sys.stdout.write("\n")

      sys.stdout.write("Running directory is:\n  %s \n" % self.workingDIR)
      sys.stdout.write("\n")

      self.mtzinFile=mtzinFile
      self.pdbinFile=pdbinFile
      self.pdboutFile=pdboutFile
      self.phsoutFile=phsoutFile

      currDIR=os.getcwd()
      os.chdir(self.workingDIR)

      self.runMtz2Various(fp, sigfp, free)

      if resolution<=2.0:
         free_lunch=" -e1.0 -l5"
      else:
         free_lunch=""

      frac_solvent=solvent/100.0

      # Set up input files for shelxe
      if os.path.isfile("shelxe-input.hkl"):
         os.remove("shelxe-input.hkl")
      shutil.copyfile(self.hklinFile, "shelxe-input.hkl")
      self.script += "cp %s shelxe-input.hkl\n" % self.hklinFile
      if os.path.isfile("shelxe-input.pda"):
         os.remove("shelxe-input.pda")
      shutil.copyfile(self.pdbinFile, "shelxe-input.pda")
      self.script += "cp %s shelxe-input.pda\n\n" % self.pdbinFile

      command_line=shelxeEXE + ' shelxe-input.pda -a' + str(traceCycles) + ' -q -s' + str(frac_solvent) + ' -o -n -t3' + free_lunch
      self.script += command_line + "\n\n"

      file=open(self.shelxScriptFile, "w")
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
  
      cycle=1
      CAPTURE=False
      log=open(self.shelxeLogfile, "w")
      while out:
         log.write(out)
         if "residues left after pruning" in out and "divided into chains" in out:
            CAPTURE=True
            sys.stdout.write("---------------------------------\n")
            sys.stdout.write("SHELXE tracing cycle: %d\n" % cycle)
            sys.stdout.write("---------------------------------\n")
            sys.stdout.write("\n")
            cycle=cycle+1
         if self.debug == False and CAPTURE:
            sys.stdout.write("  " + string.strip(out) + "\n")
         if "CC for partial structure against native data" in out:
            CAPTURE=False
            sys.stdout.write("\n")
         if self.debug==False and "Best trace (cycle " in out:
            sys.stdout.write("  " + string.split(string.strip(out),"was")[0] + "\n")
            sys.stdout.write("\n")
         if self.debug:
            sys.stdout.write(out)
         out=child_stdout_and_stderr.readline()
 
      child_stdout_and_stderr.close()
      log.close()

      pdbstatus=self.checkFileExist("shelxe-input.pdb", "shelxe", "pdb")
      if pdbstatus==1:
         sys.stdout.write("Error: No output pdb file from shelxe\n")
         script = "# No output from SHELXE\n"
      else:
         shutil.move("shelxe-input.pdb", self.pdboutFile)
         script  = "mv shelxe-input.pdb %s\n" % self.pdboutFile

      phsstatus=self.checkFileExist("shelxe-input.phs", "shelxe", "phs")
      if phsstatus==1:
         sys.stdout.write("Error: No output phs file from shelxe\n")
      else:
         shutil.move("shelxe-input.phs", self.phsoutFile)
         script += "mv shelxe-input.phs %s\n\n" % self.phsoutFile
       

      scriptFile=open(self.shelxScriptFile, "a")
      scriptFile.write(script)
      scriptFile.close()
 
      # Set the best scores
      if os.path.isfile(self.pdboutFile):
         score=0.0
         f=open(self.pdboutFile, "r")
         line=f.readline()
         try:
            score=float(string.split(line)[6].replace("%",""))
         except: 
            sys.stdout.write("Warning (shelxe_trace): Can't find Shelxe output score in output pdb\n")
         f.close()
         if mrProgram.upper() == "PHASER": 
            self.phaserBestCC=score 
         if mrProgram.upper() == "MOLREP": 
            self.molrepBestCC=score 

      sys.stdout.write("Log file written to:\n  %s \n" % self.shelxeLogfile)
      sys.stdout.write("\n")

      if pdbstatus != 1:
         sys.stdout.write("Output PDB file written to:\n  %s \n" % self.pdboutFile)
         sys.stdout.write("\n")

      if self.debug == False:
        for file in self.hklinFile, "shelxe-input.hkl", "shelxe-input.pdb", \
                    "shelxe-input.pha", "shelxe-input.hat", \
                    "shelxe-input.pda": 
           if os.path.isfile(file):
              os.remove(file) 

      os.chdir(currDIR)

   def results(self, mrProgram):
      """  Compile a results log for this Shelx job """

      sys.stdout.write("SHELX>>> \n")
      sys.stdout.write("SHELX>>> ########################################################################\n")
      sys.stdout.write("SHELX>>> Shelx results for PDB: " + self.pdbinFile + "\n")
      sys.stdout.write("SHELX>>> \n")
      if mrProgram.upper() == "PHASER":
         sys.stdout.write("SHELX>>>    Best CC score for Phaser: " + str(self.phaserBestCC) + "\n")
         sys.stdout.write("SHELX>>>    Output PDB file: " + self.phaserShelxPDB + "\n")
      if mrProgram.upper() == "MOLREP":
         sys.stdout.write("SHELX>>>    Best CC score for Molrep: " + str(self.molrepBestCC) + "\n")
         sys.stdout.write("SHELX>>>    Output PDB file: " + self.molrepShelxPDB + "\n")
      sys.stdout.write("SHELX>>> \n")
      sys.stdout.write("SHELX>>> ########################################################################\n")
      sys.stdout.write("SHELX>>> \n")


if __name__ == "__main__":

   if  len(sys.argv) == 7:
      pdbinFile=sys.argv[1]
      mtzinFile=sys.argv[2]
      nmol=int(sys.argv[3])
      solvent=float(sys.argv[4])
      resolution=float(sys.argv[5])
      mrProgram=sys.argv[6]
      FP="FP"
      SIGFP="SIGFP"
      FREE="FREE"
   elif  len(sys.argv) == 10:
      pdbinFile=sys.argv[1]
      mtzinFile=sys.argv[2]
      nmol=int(sys.argv[3])
      solvent=float(sys.argv[4])
      resolution=float(sys.argv[5])
      mrProgram=sys.argv[6]
      FP=sys.argv[7]
      SIGFP=sys.argv[8]
      FREE=sys.argv[9]
   else:
      sys.stdout.write("Usage: python MRBUMP_Shelxe.py <pdb> <mtz> <nmol> <solvent> <mtz resolution> <MR program> [<FP> <SIGFP> <FREE>]\n")
      sys.stdout.write("\n")
      sys.stdout.write("       e.g. python MRBUMP_Shelxe.py foo.pdb foo.mtz 2 45.33 1.543 PHASER FP SIGFP FREE\n")
      sys.stdout.write("\n")
      sys.exit()
     
   SHELX=Shelxe()

   status=SHELX.checkFileExist(pdbinFile, "mrbump", "pdb")
   if status==1:
      sys.exit(1)

   status=SHELX.checkFileExist(mtzinFile, "mtzfile", "mtz")
   if status==1:
      sys.exit(1)

   SHELX.runMtz2Various(mtzinFile, fp=FP, sigfp=SIGFP, free=FREE)
   SHELX.runShelxe(solvent, resolution, mrProgram, pdbinFile, traceCycles=1)
   SHELX.results(mrProgram)

