#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# PDBClip function
# Ronan Keegan 30/06/12

import os, string, sys
import shutil
import subprocess
import shlex


if not os.environ.has_key('CCP4'):
    raise RuntimeError, 'CCP4 not found'
if not os.environ.has_key('CBIN'):
    raise RuntimeError, 'CBIN not found'

class PDBClip:
   """ A class to generate PDBClip models """

   def __init__(self):

      self.Logile=""
      
      if os.name == "nt":
         self.pdbsetEXE       = os.path.join(os.environ['CBIN'], 'pdbset.exe')
         self.pdbcurEXE       = os.path.join(os.environ['CBIN'], 'pdbcur.exe')
         self.coord_formatEXE = os.path.join(os.environ['CBIN'], 'coord_format.exe')
      else:
         self.pdbsetEXE       = os.path.join(os.environ['CBIN'], 'pdbset')
         self.pdbcurEXE       = os.path.join(os.environ['CBIN'], 'pdbcur')
         self.coord_formatEXE = os.path.join(os.environ['CBIN'], 'coord_format')

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def run(self, inputPDBFile, outputPDBFile, chainID, workingDIR, LITE=False):
      """ A function to run coord_format, pdbset and pdbcur """

      ############### Coord_format #################

      # Write the key file for coord_format
      cf_key =  'FIXBLANK\n'
      cf_key += 'END\n'

      # Write out the key file if we are running in debug mode
      if self.debug:
         cf_keyfile=os.path.join(workingDIR, 'cf_key.in')
         cf_key_input=open(cf_keyfile, 'w')
         cf_key_input.write(cf_key)
         cf_key_input.close()

      # Run coord_format to fix any chain naming errors
      termination=False
      if self.debug:
         sys.stdout.write("modifying with coord_format.....\n")
         sys.stdout.write("\n")

      # Set the logfile
      self.Logfile=os.path.join(workingDIR, 'pdbclip.log')

      # Set the command line
      command_line=self.coord_formatEXE + ' xyzin ' +  inputPDBFile \
         + ' xyzout ' + os.path.join(workingDIR, 'cf_output.pdb')
   
      # Write it out if running in debug mode
      if self.debug:
         sys.stdout.write("Coord_format command line:\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch coord_format
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.write(cf_key)
      child_stdin.close()         

      # Watch the output for successful termination
      out=child_stdout.readline()
      log=open(self.Logfile, "w")
      log.write("\n############### Coord Format ###############\n\n")
      log.write(out)

      while out:
         if 'Normal termination' in out:
            termination=True
         out = child_stdout.readline()
         log.write(out)

      child_stdout.close()         
      log.close()

      if not termination:
         sys.stdout.write("PDBClip log: coord_format failed for:\n   %s\n" % inputPDBFile)
         if self.debug:
            sys.stdout.write("PDBClip log: log file can be found at: \n   %s" % self.Logfile)

      ###############    PDBset    #################

      # Write the key file for pdbset
      if chainID.upper() == "ALL":
         ps_key =  ''
      else:
         ps_key =  'SELECT CHAIN ' + chainID + '\n'
      ps_key += 'EXCLUDE HOH\n'
      ps_key += 'EXCLUDE HYDROGRENS\n'
      ps_key += 'SELECT OCCUPANCY\n'
      ps_key += 'END\n'

      # Write out the key file if we are running in debug mode
      if self.debug:
         ps_keyfile=os.path.join(workingDIR, 'ps_key.in')
         ps_key_input=open(ps_keyfile, 'w')
         ps_key_input.write(ps_key)
         ps_key_input.close()

      # Run pdbset to remove the waters
      termination=False
      if self.debug:
         sys.stdout.write("modifying with pdbset.....\n")

      # Set the command line
      #command_line = self.pdbsetEXE + ' xyzin ' + os.path.join(workingDIR, 'cf_output.pdb') \
      #              + ' xyzout ' + os.path.join(workingDIR, 'ps_output.pdb')
      command_line = self.pdbsetEXE + ' xyzin ' + os.path.join(workingDIR, 'cf_output.pdb') \
                    + ' xyzout ' + outputPDBFile

      # Write it out if running in debug mode
      if self.debug:
         sys.stdout.write("Pdbset command line:\n")
         sys.stdout.write(command_line + "\n")
         sys.stdout.write("\n")

      # Launch pdbset
      if os.name == "nt":
         process_args = shlex.split(command_line, posix=False)
         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)
      else:
         process_args = shlex.split(command_line)
         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                stdout = subprocess.PIPE)

      (child_stdout, child_stdin) = (p.stdout, p.stdin)

      child_stdin.write(ps_key)
      child_stdin.close()         

      # Watch the output for successful termination
      out=child_stdout.readline()
      log=open(self.Logfile, "a")
      log.write("\n###############    PDBset    ###############\n\n")
      log.write(out)

      while out:
         if 'Normal completion PDBSET' in out:
            termination=True
         out = child_stdout.readline()
         log.write(out)

      child_stdout.close()         
      log.close()

      if not termination:
         sys.stdout.write("PDBClip log: pdbset failed for:\n    %s\n" % inputPDBFile)
         if self.debug:
            sys.stdout.write("PDBClip log: log file can be found at:\n   %s\n " % self.Logfile)

      ###############    PDBcur    #################

      # Write the key file for pdbcur
#      if chainID.upper() == "ALL":
#         pc_key =  ''
#      else:
#         pc_key =  'lvchain /1/' + chainID + '\n'
#      pc_key += 'mostprob\n'
#      pc_key += 'end\n'
#
#      # Write out the key file if we are running in debug mode
#      if self.debug:
#         pc_keyfile=os.path.join(workingDIR, 'pc_key.in')
#         pc_key_input=open(pc_keyfile, 'w')
#         pc_key_input.write(pc_key)
#         pc_key_input.close()
#
#      # Run pdbcur to strip chains and do some other editing
#      termination=False
#      if self.debug:
#         print "modifying with pdbcur....."
#
#      # Set the command line
#      command_line = self.pdbcurEXE + ' xyzin ' + os.path.join(workingDIR, 'ps_output.pdb') \
#                     + ' xyzout ' + outputPDBFile
#
#      # Write it out if running in debug mode
#      if self.debug:
#         sys.stdout.write("Pdbcur command line:\n")
#         sys.stdout.write(command_line + "\n")
#         sys.stdout.write("\n")
#
#      # Launch pdbset
#      if os.name == "nt":
#         process_args = shlex.split(command_line, posix=False)
#         p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
#                                stdout = subprocess.PIPE)
#      else:
#         process_args = shlex.split(command_line)
#         p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
#                                stdout = subprocess.PIPE)
#
#      (child_stdout, child_stdin) = (p.stdout, p.stdin)
#
#      child_stdin.write(pc_key)
#      child_stdin.close()         
#
#      # Watch the output for successful termination
#      out=child_stdout.readline()
#      log=open(self.Logfile, "a")
#      log.write("\n###############    PDBcur    ###############\n\n")
#      log.write(out)
#
#      while out:
#         if 'Normal termination' in out:
#            termination=True
#         out = child_stdout.readline()
#         log.write(out)
#
#      child_stdout.close()         
#      log.close()
#
#      if not termination:
#         sys.stdout.write("PDBClip log: pdbcur failed for:\n   %s\n" % inputPDBFile) 
#         if self.debug:
#            sys.stdout.write("PDBClip log: log file can be found at:\n   %s\n" % self.Logfile)

      ####################################################   
   
      # If running in LITE mode remove excess files
      if LITE:
         if os.path.isfile(os.path.join(workingDIR, 'cf_output.pdb')):
            os.remove(os.path.join(workingDIR, 'cf_output.pdb'))

      if self.debug:
         sys.stdout.write("\n")

if __name__ == "__main__":
   
   workingDIR=os.path.join(os.environ["CCP4_SCR"], "pdbclip_insulin_test")
   if os.path.isdir(workingDIR):
      shutil.rmtree(workingDIR)
   os.mkdir(workingDIR)
   inputPDBFile=os.path.join(os.environ["CEXAM"], "data", "insulin.pdb")
   outputPDBFile=os.path.join(workingDIR, "test.pdb")
   chainID="A"

   p=PDBClip()
   p.run(inputPDBFile, outputPDBFile, chainID, workingDIR, LITE=False)

