#!/usr/bin/env ccp4-python
#
#     Copyright (C) 2013 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Class for running Hhblits in Ample for template model search
#
# Ronan Keegan 11/01/2013

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


class HHmatch:
   """ A class to hold details about the hhpred hit alignments to the target sequence """
 
   def __init__(self):
      self.name=""
      self.targetSequence=""
      self.alignment=""


class HHblits:
   """ A class to run hhblits to find template models """

   def __init__(self):
      self.inputSeqFile=""
      self.HHpdbDB=""
      self.outputAlnA3mFile=""
      self.outputAlnFastaFile=""
      self.ncpu=1
      self.hitList=[]
      self.hits=0
      self.chainDict=dict([])

      self.scriptFile="hhblits-script.sh"
      self.script=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.hhblitsLogfile="hhblits.log"
      self.hhReformatLogfile="hhreformat.log"
      self.workingDIR=""
     
   def setDebug(self, debugValue):
      self.debug=debugValue

   def setNcpu(self, number):
      self.ncpu=number

   def setInputSeqFile(self, filename):
      self.inputSeqFile=filename

   def setOutputAlnA3mFile(self, filename):
      self.outputAlnA3mFile=filename

   def setOutputAlnFastaFile(self, filename):
      self.outputAlnFastaFile=filename

   def setHHpdbDB(self, path):
      self.HHpdbDB=path

   def setScriptFile(self, filename):
      self.scriptFile=filename

   def setHhblitsLogFile(self, filename):
      self.hhblitsLogfile=filename

   def setHhReformatLogFile(self, filename):
      self.hhReformatLogfile=filename

   def setHhblitsWorkingDIR(self, dirname):
      self.workingDIR=dirname

   def checkFileExist(self, filename, program, type):
      """ Check to see if the PDB file has been outout from Refmac in MrBUMP """

      if os.path.isfile(filename):
         status = 0
      else:
         status = 1
         sys.stdout.write("Warning: no file output from "+ program +"  for this job\n")
      
      return status

   def runHHblits(self, seqFile, HHpdbDB, outputAlnA3mFile, ncpu):
      """ Run hhblits to search for template search models """

      self.inputSeqFile=seqFile
      self.outputAlnA3mFile=outputAlnA3mFile
      self.HHpdbDB=HHpdbDB
      self.ncpu=ncpu

      command_line='hhblits -i %s -d %s -oa3m %s -n %d' % (self.inputSeqFile, self.HHpdbDB, self.outputAlnA3mFile, self.ncpu)
 
      print command_line

      self.script += command_line + "\n"

      sc=open(self.scriptFile, "w")
      sc.write(command_line)
      sc.close()
 
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)


      (child_stdin, child_stdout_and_stderr) = (p.stdin, p.stdout)
  
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      log=open(self.hhblitsLogfile, "w")

      CATCH=False
      while out:
         if CATCH and string.strip(out) == "": 
            CATCH=False
         if CATCH:
            if len(string.split(out)) > 2:
               if string.split(out)[1][4]=="_":
                  self.hitList.append(string.split(out)[1])
         if "No Hit" in out:
            CATCH=True
         if self.debug:
            sys.stdout.write(out)
         log.write(out)
         out=child_stdout_and_stderr.readline()
  
      child_stdout_and_stderr.close()
      log.close()

      self.hits=(len(self.hitList))

      status=self.checkFileExist(self.outputAlnA3mFile, "hhblits", "aln")
      if status==1:
         sys.stdout.write("Error: No output file from hhblits\n")

      #self.reformat()

      # Capture the alignments from the alignment file
      if os.path.isfile(self.outputAlnA3mFile):
         alnfile=open(self.outputAlnA3mFile, "r")
         line=alnfile.readline()
         line=alnfile.readline()
         targetSequence=string.strip(line)
         while line:
            if ">" in line:
               if line[1:7] in self.hitList:
                  name=line[1:7]
                  line=alnfile.readline()
                  self.chainDict[name]=HHmatch()
                  self.chainDict[name].name=name
                  self.chainDict[name].targetSequence=targetSequence
                  self.chainDict[name].alignment=string.strip(line)
            line=alnfile.readline()
         alnfile.close()
      else:
         sys.stdout.write("WARNING: No output alignment file written by HHBlits!\n\n")

   def reformat(self):

      if self.outputAlnFastaFile=="":
         self.outputAlnFastaFile=self.outputAlnA3mFile.split(os.extsep)[0] + ".fasta"

      # Convert the a3m file to fasta format
      reformatScript=os.path.join(os.environ["HHLIB"], "scripts", "reformat.pl")
 
      command_line='perl %s %s %s' % (reformatScript, self.outputAlnA3mFile, self.outputAlnFastaFile)
 
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, bufsize=0, shell="False", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE, stderr = subprocess.STDOUT)


      (child_stdin, child_stdout_and_stderr) = (p.stdin, p.stdout)
  
      child_stdin.close()
  
      # Watch the output for successful termination
      out=child_stdout_and_stderr.readline()
  
      log=open(self.hhReformatLogfile, "w")

      while out:
         if self.debug:
            sys.stdout.write(out)
         log.write(out)
         out=child_stdout_and_stderr.readline()
  
      child_stdout_and_stderr.close()
      log.close()
     

if __name__ == "__main__":

   if  len(sys.argv) == 5:
      seqFile=sys.argv[1]
      hhpredDB=sys.argv[2]
      outputAlnA3mFile=sys.argv[3]
      ncpu=int(sys.argv[4])
   else:
      sys.stdout.write("Usage: python MRBUMP_HHpred.py <seqfile> <path_to_hhpdb_database> <outputAlnfile> <ncpu>\n")
      sys.stdout.write("\n")
      sys.stdout.write("       e.g. python MRBUMP_HHpred.py xxx.fasta /usr/local/hhpred/database output.a3m 2\n")
      sys.stdout.write("\n")
      sys.exit()
     
   HHBLITS=HHblits()

   status=HHBLITS.checkFileExist(seqFile, "hhblits", "seq")
   if status==1:
      sys.exit(1)

   HHBLITS.runHHblits(seqFile, hhpredDB, outputAlnA3mFile, ncpu)
   for i in HHBLITS.chainDict.keys():
      print HHBLITS.chainDict[i].name
      print HHBLITS.chainDict[i].targetSequence
      print HHBLITS.chainDict[i].alignment

#No Hit                             Prob E-value P-value  Score    SS Cols Query HMM  Template HMM

