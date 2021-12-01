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

mrbump = os.environ['MRBUMP']
mrbump_incl = os.environ['MRBUMP_INCL']
CLUSTER=eval(os.environ['MRBUMP_CLUSTER'])


class Amore_submit:

   def __init__(self):
      self.name=''

   def Amore_setup(self, target_info, mstat, mrsearchdir):
      ''' A function to compose the keyword input for Amore. '''
       
      for model in mstat.model_list.keys():
      
         mstat.model_list[model].setAmoreWrapper(mrbump_incl + '/mr/amore_wrap.py')
         mstat.model_list[model].setAmoreKeyFile(mrsearchdir + '/data/' \
         + mstat.model_list[model].chain_source + '/mr/amr_' + mstat.model_list[model].name + '_key.in')
         mstat.model_list[model].setAmoreLogFile(mrsearchdir + '/data/' \
         + mstat.model_list[model].chain_source + '/mr/amr_' + mstat.model_list[model].name + '.sum')
         mstat.model_list[model].setAmoreSolnFile(mrsearchdir + '/data/' \
         + mstat.model_list[model].chain_source + '/mr/amr_' + mstat.model_list[model].name + '.sol')

         line = mstat.model_list[model].PDBfile[0] + '\n'
         line += target_info.hklin + '\n'
         line += target_info.mtz_coldata['F'] + '\n'
         line += '50 %.3f\n' % target_info.resolution
         line += `target_info.no_of_res` + '\n'
     
         key=open(mstat.model_list[model].amore_keyfile, 'w')
         key.write(line)
         key.close()

   def Amore_start(self, target_info, mstat, mrsearchdir):
      ''' A function to submit a amore job to an SGE queue. '''

      print "Molecular Replacement log message: Launching Amore jobs"  

      for model in mstat.model_list.keys():

         mstat.model_list[model].setAmoreJobName("amr_" + mstat.model_list[model].name + "_" + target_info.chainID)
         mstat.model_list[model].setAmoreMTZfile(mrsearchdir + '/data/' + mstat.model_list[model].chain_source \
         + '/mr/amr_' + mstat.model_list[model].name + '.mtz')
         mstat.model_list[model].setAmorePDBfile(mrsearchdir + '/data/' + mstat.model_list[model].chain_source \
         + '/mr/amr_' + mstat.model_list[model].name + '.pdb')
         
         if CLUSTER == True:
            SGE_script=mrsearchdir + '/data/' + mstat.model_list[model].chain_source + '/mr/amr_SGE_' + mstat.model_list[model].name \
            + '_' + target_info.chainID + '.sub'

            line =  "#!/bin/sh \n#$ -cwd \n#$ -j y \n#$ -w e \n"
            line += "#$ -o " + mrsearchdir + "/logs/AMORE_" + mstat.model_list[model].name + ".log -N " \
            + mstat.model_list[model].amore_jobname + "\n"
            line += "cd " + mrsearchdir + "/data/" + mstat.model_list[model].chain_source + "/mr/\n"
            line += "python " + mstat.model_list[model].amore_wrapper + " " + mstat.model_list[model].amore_keyfile + " \n"

            sge_amr_script=open(SGE_script, 'w')
            sge_amr_script.write(line)
            sge_amr_script.close()

            # Submit the job to the SGE queue

            #o=os.popen("qsub -V " + SGE_script, 'r')

	    # Get the job ID from SGE

	    #mstat.model_list[model].setAmoreJobID((int)((string.split(string.strip(o.readline())))[2]))
	    #o.close()
	    #mstat.jobid_array.add(mstat.model_list[model].amore_jobID)

         # If no cluster run locally. this is temporary and will be replaced by using Graeme's schedular.
#         else:
#            p=Phaser.Phaser()
#       
#            print "Molecular Replacement log message: Running model:%s through Phaser" % model  
#
#            ensm_line = ''
#            for i in range(mstat.model_list[model].num_per_ensem):
#               if i < mstat.model_list[model].num_per_ensem-1:
#                 ensm_line += "'" + mstat.model_list[model].PDBfile[i] +"', " +  mstat.model_list[model].seqID[i] + ", "   
#               else: 
#                 ensm_line += "'" + mstat.model_list[model].PDBfile[i] +"', " +  mstat.model_list[model].seqID[i]  
#           
#            p.setHklin(target_info.hklin)
#            p.setColumn_labels(target_info.mtz_coldata['F'], target_info.mtz_coldata['SIGF'])
#            p.setModel(ensm_list)
#            p.setNmol(target_info.no_of_mols)
#            p.setMolw(target_info.mol_weight)
#            p.setName(mrsearchdir + '/data/' + mstat.model_list[model].chain_source \
#            + '/mr/phr_' + mstat.model_list[model].name)
#
#            p.run()


            #LOCAL_script=mrsearchdir + '/data/' + mstat.model_list[model].chain_source + '/mr/phr_LOCAL_' + mstat.model_list[model].name \
            #+ '_' + target_info.chainID + '.sh'

            #line =  "#!/bin/sh \n"
            #line += "log=" + mrsearchdir + "/logs/PHASER_" + mstat.model_list[model].name + ".log\n"
            #line += "cd " + mrsearchdir + "/data/" + mstat.model_list[model].chain_source + "/mr/\n"
            #line += "python " + mstat.model_list[model].phaser_wrapper + " " + mstat.model_list[model].phaser_keyfile + " > $log\n"

            #local_phr_script=open(LOCAL_script, 'w')
            #local_phr_script.write(line)
            #local_phr_script.close()

            # Change the script to executable and launch the job 

	    #os.chmod(LOCAL_script, 0500)
            #os.popen(LOCAL_script, 'r')

	 # Increment the counter 

	 mstat.mr_counter=mstat.mr_counter+1
						


