#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#

import os, sys, string
import subprocess, shlex

mrbump = os.environ['MRBUMP']
mrbump_incl = os.environ['MRBUMP_INCL']
CLUSTER=eval(os.environ['MRBUMP_CLUSTER'])

class Refmac_submit:

   def __init__(self):
      self.name=''

   def Refmac_setup(self, target_info, mstat, mrsearchdir):
      ''' A function to compose the keyword input for Refmac. '''
 
      for model in mstat.model_list.keys():
      
         mstat.model_list[model].setRefmacWrapper(mrbump_incl + '/mr/refmac_wrap.py')
         mstat.model_list[model].setRefmacKeyFile(mrsearchdir + '/data/' + mstat.model_list[model].chain_source \
         + '/mr/ref_' + mstat.model_list[model].name + '_key.in')
         mstat.model_list[model].setRefmacLogFile(mrsearchdir + '/data/' + mstat.model_list[model].chain_source \
         + '/mr/refmac_' + mstat.model_list[model].name + '.log')

         line = 'LABIn FP = ' + target_info.mtz_coldata['F'] + ' SIGFP = ' + target_info.mtz_coldata['SIGF'] + \
         ' FREE = ' + target_info.mtz_coldata['FREE'] + '\n'
         line += 'NCYC 30 \n'
         line += 'WEIGHT MATRIX 0.01 \n'

         key=open(mstat.model_list[model].refmac_keyfile, 'w')
         key.write(line)
         key.close()

   def Refmac_start(self, target_info, mstat, mrsearchdir):
      ''' A function to submit a refmac job to an SGE queue. '''
  
      print "Molecular Replacement log message: Launching Refmac jobs"  

      for model in mstat.model_list.keys():

         mstat.model_list[model].setRefmacJobName("ref_" + mstat.model_list[model].name + "_" + target_info.chainID)
         mstat.model_list[model].setRefmacPDBfile(mrsearchdir + "/data/" + mstat.model_list[model].chain_source \
         + "/mr/ref_" + mstat.model_list[model].name + ".pdb")
         mstat.model_list[model].setRefmacMTZINfile(target_info.hklin)
         mstat.model_list[model].setRefmacMTZOUTfile(mrsearchdir + "/data/" + mstat.model_list[model].chain_source \
         + "/mr/ref_" + mstat.model_list[model].name + ".mtz")

         if CLUSTER == True:
            SGE_script=mrsearchdir + '/data/' + mstat.model_list[model].chain_source + '/mr/ref_SGE_' + mstat.model_list[model].name \
            + '_' + target_info.chainID + '.sub'

            line =  "#!/bin/sh \n#$ -cwd \n#$ -j y \n#$ -w e \n"
            line += "#$ -o " + mrsearchdir + "/logs/REFMAC_" + mstat.model_list[model].name + ".log -N " \
            + mstat.model_list[model].refmac_jobname + "\n"
            line += "cd " + mrsearchdir + "/data/" + mstat.model_list[model].chain_source + "/mr/\n"
            if mstat.MRPROGRAM=='PHASER':
               line += "python " + mstat.model_list[model].refmac_wrapper + " " + mstat.model_list[model].refmac_keyfile + " " + \
               mstat.model_list[model].refmac_MTZINfile + " " + mstat.model_list[model].refmac_MTZOUTfile + " " + \
               mstat.model_list[model].phaser_PDBfile + " " + mstat.model_list[model].refmac_PDBfile + " " + mstat.model_list[model].name + " \n"
            if mstat.MRPROGRAM=='MOLREP':
               line += "python " + mstat.model_list[model].refmac_wrapper + " " + mstat.model_list[model].refmac_keyfile + " " + \
               mstat.model_list[model].refmac_MTZINfile + " " + mstat.model_list[model].refmac_MTZOUTfile + " " + \
               mstat.model_list[model].molrep_PDBfile + " " + mstat.model_list[model].refmac_PDBfile + " " + mstat.model_list[model].name + " \n"

            sge_ref_script=open(SGE_script, 'w')
            sge_ref_script.write(line)
            sge_ref_script.close()

            # Submit the job to the SGE queue

            # Set the command line
            command_line = "qsub -V " + SGE_script
     
            # Launch
            if os.name == "nt":
               process_args = shlex.split(command_line, posix=False)
               p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
            else:
               process_args = shlex.split(command_line)
               p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

            (o, i) = (p.stdout, p.stdin)
      
            i.close()

            # Get the job ID from SGE
	    mstat.model_list[model].setRefmacJobID((int)((string.split(string.strip(o.readline())))[2]))
	    o.close()
	    mstat.jobid_array.add(mstat.model_list[model].refmac_jobID)

         # If no cluster run locally. this is temporary and will be replaced by using Graeme's schedular.
         else: 
            sys.stdout.write("Molecular Replacement log message: Running model:%s through Refmac\n" % model)  
            sys.stdout.write("                                   Running as a local script\n")  
            sys.stdout.write("\n")  

            LOCAL_script=os.path.join(mrsearchdir, 'data', mstat.model_list[model].chain_source, 'mr', 'ref_LOCAL_' + mstat.model_list[model].name \
            + '_' + target_info.chainID + '.sh')

            line =  "#!/bin/sh\n"
            line += "log=" + os.path.join(mrsearchdir, "logs", "REFMAC_" + mstat.model_list[model].name + ".log") + "\n" 
            line += "cd " + os.path.join(mrsearchdir, "data", mstat.model_list[model].chain_source, "mr") + "\n"
            line += "python " + mstat.model_list[model].refmac_wrapper + " " + mstat.model_list[model].refmac_keyfile + " " + \
            mstat.model_list[model].refmac_MTZINfile + " " + mstat.model_list[model].refmac_MTZOUTfile + " " + \
            mstat.model_list[model].phaser_PDBfile + " " + mstat.model_list[model].refmac_PDBfile \
            + " " + mstat.model_list[model].name + " > $log\n"

            local_ref_script=open(LOCAL_script, 'w')
            local_ref_script.write(line)
            local_ref_script.close()

            # Change the permissions on the script and start it 
            os.chmod(LOCAL_script, 0500)

            # Set the command line
            command_line = LOCAL_script
     
            # Launch
            if os.name == "nt":
               process_args = shlex.split(command_line, posix=False)
               p = subprocess.Popen(process_args, shell="True", stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE, stderr = subprocess.STDOUT)
            else:
               process_args = shlex.split(command_line)
               p = subprocess.Popen(process_args, stdin = subprocess.PIPE,
                                 stdout = subprocess.PIPE, stderr = subprocess.STDOUT)

            (o, i) = (p.stdout, p.stdin)
      
            i.close()

            line=o.readline()
            while line:
               if self.debug:
                  sys.stdout.write(line)
               line=o.readline()
            o.close()

	 # Increment the coounter
	 mstat.ref_counter=mstat.ref_counter+1
