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
# Output the job details to an XML file
# Ronan Keegan 5/3/07

import os, sys, string
import time, shutil


import os
import string
import sys

import MRBUMP_target_info

class writeXML:

   def __init__(self):
      self.outXML_file=""

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

      self.local_debug = False

   def write_details(self, init, mstat, target_info, filename):
      """ Write target details to an XML file. """
    
      sys.stdout.write("Outputting job details to an XML file\n")
      sys.stdout.write("XML file name:\n   %s\n" % filename)
      sys.stdout.write("\n")

      self.outXML_file=filename

      outfile=open(self.outXML_file, "w")

      outfile.write('<?xml version="1.0" encoding="ASCII" standalone="yes"?>\n')
      outfile.write('\n')

      outfile.write('<mrbump_run xmlns="http://www.ccp4.ac.uk/MrBUMP#" run="%s">\n' % target_info.chainID)
      outfile.write('  <MRBUMP  ccp4_version="6.0"  date="%s" />\n' % time.ctime())
      outfile.write('  <keyword>\n')
      outfile.write('    <n_models_use> %d </n_models_use>\n' % init.keywords.MRNUM)
      outfile.write('    <ensemnum> %d </ensemnum>\n' % init.keywords.ENSMODNUM)
      if init.keywords.NMASU == None:
         outfile.write('    <pack> %d </pack>\n' % int(init.keywords.PACK))
      else:
         outfile.write('    <pack> %d </pack>\n' % (int(init.keywords.PACK)*int(init.keywords.NMASU)))
      outfile.write('    <ncyc> %d </ncyc>\n' % init.keywords.NCYC)
      outfile.write('    <nmasu> %s </nmasu>\n' % `init.keywords.NMASU`)
      outfile.write('    <evalue> %.3f </evalue>\n' % init.keywords.E_value)
      outfile.write('  </keyword>\n')

      outfile.write('  <target>\n')

      outfile.write('    <short_name>%s<short_name>\n' % target_info.chainID)
      outfile.write('    <source>C. jejuni</source>\n')
      outfile.write('    <protein_name>dUTPase</protein_name>\n')
      outfile.write('    <sequence>%s</sequence>\n' % target_info.sequence)
      outfile.write('    <number_residues>%d<number_residues>\n' % target_info.no_of_res)
      outfile.write('    <molecular_weight>%.3f<molecular_weight>\n' % target_info.mol_weight)
      outfile.write('    <number_mols_asu>%d<number_mols_asu>\n' % target_info.no_of_mols)

      outfile.write('    <reflection_file mtz_file="%s"/>\n' % target_info.hklin)
      outfile.write('    <reflection_columns>\n')
      outfile.write('      <mtz_col_F>%s</mtz_col_F>\n' % target_info.mtz_coldata["F"])
      outfile.write('      <mtz_col_SIGF>%s</mtz_col_SIGF>\n' % target_info.mtz_coldata["SIGF"])
      outfile.write('      <mtz_col_SIGF>%s</mtz_col_SIGF>\n' % target_info.mtz_coldata["FREE"])
      outfile.write('    </reflection_columns>\n')
      outfile.write('    <resolution_low>XXXXX</resolution_low>\n')
      outfile.write('    <resolution_high>%.4f</resolution_high>\n' % target_info.resolution)

      outfile.write('    <dataset_info>\n')
      outfile.write('      <cell>\n')
      outfile.write('        <a>%.3f</a>\n' % target_info.cell_dimensions["a"])
      outfile.write('        <b>%.3f</b>\n' % target_info.cell_dimensions["b"])
      outfile.write('        <c>%.3f</c>\n' % target_info.cell_dimensions["c"])
      outfile.write('        <alpha>%.3f</alpha>\n' % target_info.cell_dimensions["alpha"])
      outfile.write('        <beta>%.3f</beta>\n' % target_info.cell_dimensions["beta"])
      outfile.write('        <gamma>%.3f</gamma>\n' % target_info.cell_dimensions["gamma"])
      outfile.write('      </cell>\n')
      outfile.write('      <spacegroup>\n')
      outfile.write('        <xHM>%s</xHM>\n' % target_info.space_group)
      outfile.write('        <hall> P 2ac 2ab?????</hall>\n')
      outfile.write('        <number>?????</number>\n')
      outfile.write('        <lattice>?????</lattice>\n')
      outfile.write("        <enant_SG_code>%s</enant_SG_code>\n" % target_info.enant_SG_code)
      outfile.write("        <symmetry_no>%s</symmetry_no>\n" % target_info.symmetry_no)
      outfile.write('      </spacegroup>\n')
      outfile.write('    </dataset_info>\n')

      outfile.write('  </target>\n')
      outfile.write('\n')

      # Output the template details
      count=0
      for chain in mstat.sorted_list:
         chain_ID=chain[0]
         outfile.write('  <template id="%d">\n' % count)

         outfile.write('    <base_target_id>%s</base_target_id>\n' % target_info.chainID)
         outfile.write('    <name>%s</name>\n' % mstat.chain_list[chain_ID].chainName)
         outfile.write('    <!-- source types: SEQ, FASTA, SSM, USER -->\n')
         outfile.write('    <source>%s</source>\n' % mstat.chain_list[chain_ID].source)
         outfile.write('    <user_specified_chain>???????</user_specified_chain>\n')
         outfile.write('    <sequence_identity>%.3f</sequence_identity>\n' % mstat.chain_list[chain_ID].seqID)
         outfile.write('    <mrbump_score>??????</mrbump_score>\n')

         outfile.write('  </template>\n')
         outfile.write('\n')

         count=count+1

      # Multiple Alignment Details
      outfile.write('<!-- this is a global block, but comes logically in this place -->\n')
      outfile.write('  <multiple_alignment>\n')
      outfile.write('    <program>%s</program>\n' % init.keywords.MAPROGRAM)
      outfile.write('    <number_sequences>%d</number_sequences>\n' % mstat.no_of_hits)
      outfile.write('  </multiple_alignment>\n')
      outfile.write('\n')

      # Output the search model details
      outfile.write('<!-- this block repeated for all search models -->\n')
      outfile.write('<!-- there is n-to-N mapping of template to search model -->\n')
      outfile.write('<!-- For the moment, it is 1-to-N, i.e. we generate several search models -->\n')
      outfile.write('<!-- from one template. Later we may consider chimeric models derived from -->\n')
      outfile.write('<!-- more than one template. -->\n')

      for model in mstat.sorted_model_list:
         outfile.write('  <search_model id="%d">\n' % mstat.model_list[model].MR_jobID)

         outfile.write('    <base_template_list>\n')
         outfile.write('      <base_template_id>%s</base_template_id>\n' % mstat.model_list[model].chain_source)
         outfile.write('    </base_template_list>\n')

         outfile.write('    <!-- model_type types: CHAIN, DOMAIN, MULTIMER, ENSEM -->\n')
         outfile.write('    <model_type>%s</model_type>\n' % mstat.model_list[model].type)
         outfile.write('    <model_editing>??????</model_editing>\n')

         outfile.write('  </search_model>\n')
         outfile.write('\n')

         # Output the MR and refinement details
         outfile.write('<!-- this block repeated for all molecular replacement (MR) jobs -->\n')
         outfile.write('<!-- At the moment, there is 1-to-1 mapping from search models to MR -->\n')
         outfile.write('<!-- i.e. we try to solve each search model once. -->\n')
         outfile.write('<!-- In future, for complexes and for multi-domain proteins, we may use several -->\n')
         outfile.write('<!-- search models in one MR run -->\n')

      for model in mstat.sorted_model_list:
         outfile.write('  <molecular_replacement id="%d">\n' % mstat.model_list[model].MR_jobID)
         outfile.write('\n')

         outfile.write('    <base_search_model_list>\n')
         outfile.write('      <base_search_model_id>??????</base_search_model_id>\n')
         outfile.write('    </base_search_model_list>\n')
         outfile.write('\n')

         # Output the molrep and refmac results if molrep was used for this model
         if "MOLREP" in init.keywords.MR_PROGRAM_LIST and mstat.model_list[model].molrep_smartie_log != None:

            # Set the molrep smartie log
            molrep_log=mstat.model_list[model].molrep_smartie_log 

            outfile.write('    <molrep_run run="1">\n')
            outfile.write('      <MOLREP molrep_version="%s" ccp4_version="%s"  date="%s"/>\n' \
                           % (molrep_log.program(0).name, \
                              molrep_log.program(0).ccp4version, \
                              molrep_log.program(0).date))
            outfile.write('      <xyzin pdb_file="%s"/>\n' % mstat.model_list[model].PDBfile[0])
            outfile.write('      <hklin mtz_file="%s"/>\n' % target_info.hklin)
            outfile.write('      <keyword>\n')
            outfile.write('        <doc> %s </doc>\n'       % mstat.model_list[model].molrep_keywords["DOC"])
            outfile.write('        <labin> %s </labin>\n'   % mstat.model_list[model].molrep_keywords["LABIN"])
            outfile.write('        <sim> %s </sim>\n'       % mstat.model_list[model].molrep_keywords["SIM"])
            outfile.write('        <nmon> %s </nmon>\n'     % mstat.model_list[model].molrep_keywords["NMON"])
            outfile.write('        <file_t> %s </file_t>\n' % mstat.model_list[model].molrep_keywords["FILE_T"])
            outfile.write('      </keyword>\n')
            outfile.write('      <n_solution>??????</n_solution>\n')
            outfile.write('      <solution id="1">\n')
            outfile.write('        <number_found>2</number_found>\n')
            outfile.write('        <mr_contrast> 2.14356 </mr_contrast>\n')
            outfile.write('        <xyzout pdb_file="%s"/>\n' % mstat.model_list[model].molrep_PDBfile)
            outfile.write('      </solution>\n')
            outfile.write('      <messages>\n')
            outfile.write('       <message_code>   0</message_code>\n')
            outfile.write('       <message_text> %s </message_text>\n' \
                           % molrep_log.program(0).termination_message)
            outfile.write('       <message_severity>information</message_severity>\n')
            outfile.write('      </messages>\n')
            outfile.write('    </molrep_run>\n')
            outfile.write('\n')

            if mstat.model_list[model].refmac_molrep_smartie_log != None:

               # Set the refmac smartie log and pick out the final table with Rfree/Rfactor
               refmac_log=mstat.model_list[model].refmac_molrep_smartie_log 
               table=refmac_log.findtable("Rfactor analysis, stats vs cycle")

               outfile.write('    <refmac_run run="1">\n')
               outfile.write('      <REFMAC refmac_version="%s" ccp4_version="%s"  date="%s"/>\n' \
                              % (refmac_log.program(0).name, \
                                 refmac_log.program(0).ccp4version, \
                                 refmac_log.program(0).date))
               outfile.write('      <xyzin pdb_file="%s"/>\n' % mstat.model_list[model].molrep_PDBfile)
               outfile.write('      <hklin mtz_file="%s"/>\n' % mstat.model_list[model].refmac_molrep_MTZINfile)
               outfile.write('      <keyword>\n')
               outfile.write('        <labin> %s </labin>\n'     % mstat.model_list[model].refmac_molrep_keywords["LABIN"])
               outfile.write('        <n_cycle> %s </n_cycle>\n' % mstat.model_list[model].refmac_molrep_keywords["NCYC"])
               outfile.write('        <make> %s </make>\n'       % mstat.model_list[model].refmac_molrep_keywords["MAKE"])
               outfile.write('        <weight> %s </weight>\n'   % mstat.model_list[model].refmac_molrep_keywords["WEIGHT"])
               outfile.write('      </keyword>\n')
               outfile.write('      <r_factor_init> %.3f </r_factor_init>\n' % float(table.col("Rfact")[0]))
               outfile.write('      <r_factor> %.3f </r_factor>\n'           % float(table.col("Rfact")[-1]))
               outfile.write('      <r_free_init> %.3f </r_free_init>\n'     % float(table.col("Rfree")[0]))
               outfile.write('      <r_free> %.3f </r_free>\n'               % float(table.col("Rfree")[-1]))
               outfile.write('      <xyzout pdb_file="%s"/>\n' % mstat.model_list[model].refmac_molrep_PDBfile)
               outfile.write('      <hklout mtz_file="%s"/>\n' % mstat.model_list[model].refmac_molrep_MTZOUTfile)
               outfile.write('      <messages>\n')
               outfile.write('        <message_code>   0</message_code>\n')
               outfile.write('        <message_text> %s </message_text>\n' \
                              % refmac_log.program(0).termination_message)
               outfile.write('        <message_severity>information</message_severity>\n')
               outfile.write('      </messages>\n')
               outfile.write('    </refmac_run>\n')
            outfile.write('\n')

         # Output the phaser and refmac results if phaser was used for this model
         if "PHASER" in init.keywords.MR_PROGRAM_LIST and mstat.model_list[model].phaser_smartie_log != None:

            # Set the phaser smartie log and pick out the final rotation and translation tables
            phaser_log=mstat.model_list[model].phaser_smartie_log 

            tableRot  = phaser_log.findtable("Rotation Function Summary", -1)
            tableTran = phaser_log.findtable("Final Translation Function Summary for model %s" % model, -1)

            if self.local_debug:
               sys.stdout.write("Final Translation Function Summary for model %s\n\n\n" % model)
               sys.stdout.write("Number of tables in phaser log file: %d\n" % phaser_log.ntables())
               sys.stdout.write("\n")
               n=phaser_log.ntables()

               sys.stdout.write("Titles of tables:\n")
               for i in range(n):
                  sys.stdout.write("============================================================\n")
                  sys.stdout.write("%d. %s\n" % (i, phaser_log.table(i).title()))
                  sys.stdout.write("============================================================\n")
                  sys.stdout.write("\n")
                  sys.stdout.write(phaser_log.table(i).loggraph())
                  sys.stdout.write("\n")
            
            outfile.write('    <phaser_run run="1">\n')
            outfile.write('      <PHASER phaser_version="%s" ccp4_version="%s"  date="%s"/>\n' \
                           % (phaser_log.program(0).name, \
                              phaser_log.program(0).ccp4version, \
                              phaser_log.program(0).date))
            outfile.write('      <xyzin pdb_file="%s"/>\n' % mstat.model_list[model].PDBfile[0])
            outfile.write('      <hklin mtz_file="%s"/>\n' % target_info.hklin)
            outfile.write('      <keyword>\n')
            outfile.write('        <mode> %s </mode>\n'               % mstat.model_list[model].phaser_keywords["MODE"])
            outfile.write('        <hklin> %s </hklin>\n'             % mstat.model_list[model].phaser_keywords["HKLIN"])
            outfile.write('        <labin> %s </labin>\n'             % mstat.model_list[model].phaser_keywords["LABIN"])
            outfile.write('        <composition> %s </composition>\n' % mstat.model_list[model].phaser_keywords["COMPosition"])
            outfile.write('        <ensemble> %s </ensemble>\n'       % mstat.model_list[model].phaser_keywords["ENSEmble"])
            outfile.write('        <search> %s </search>\n'           % mstat.model_list[model].phaser_keywords["SEARCH"])
            outfile.write('        <xyzout> %s </xyzout>\n'           % mstat.model_list[model].phaser_keywords["XYZOUT"])
            outfile.write('        <pack> %s </pack>\n'               \
                           % (int(mstat.model_list[model].phaser_keywords["PACK"])*int(init.keywords.NMASU)))
            outfile.write('        <root> %s </root>\n'               % mstat.model_list[model].phaser_keywords["ROOT"])
            if init.keywords.ENANT:
               outfile.write('        <sgalternative> %s </sgalternative>\n' % mstat.model_list[model].phaser_keywords["SGALTERNATIVE"])
            outfile.write('      </keyword>\n')
            outfile.write('      <n_solution>  1</n_solution>\n')
            outfile.write('      <solution id="1">\n')
            outfile.write('        <number_found>2</number_found>\n')
            outfile.write('        <file type="XYZ" format="PDB">%s</file>\n' % mstat.model_list[model].phaser_PDBfile)
            outfile.write('        <file type="HKL" format="MTZ">%s</file>\n' % mstat.model_list[model].phaser_MTZfile)

            if tableTran != None:
               outfile.write('        <llg> %s </llg>\n' % tableTran.col("LL-gain")[0])
               outfile.write('        <tfz> %s </tfz>\n' % tableTran.col("Z-Score")[0])
            else:
               outfile.write('        <llg> %.3f </llg>\n' % 0.000)
               outfile.write('        <tfz> %.3f </tfz>\n' % 0.000)
                     
            if tableRot != None:
               outfile.write('        <rfz> %s </rfz>\n' % tableRot.col("Z-Score")[0])
            else:
               outfile.write('        <rfz> %.3f </rfz>\n' % 0.000)

            outfile.write('      </solution>\n')
            outfile.write('      <messages>\n')
            outfile.write('        <message_code>   0</message_code>\n')
            outfile.write('        <message_text> %s </message_text>\n' \
                           % phaser_log.program(0).termination_message)
            outfile.write('        <message_severity>information</message_severity>\n')
            outfile.write('      </messages>\n')
            outfile.write('    </phaser_run>\n')
            outfile.write('\n')
         
            if mstat.model_list[model].refmac_phaser_smartie_log != None:

               # Set the refmac smartie log and pick out the final table with Rfree/Rfactor
               refmac_log=mstat.model_list[model].refmac_phaser_smartie_log 
               table=refmac_log.findtable("Rfactor analysis, stats vs cycle")

               outfile.write('    <refmac_run run="2">\n')
               outfile.write('      <REFMAC refmac_version="%s" ccp4_version="%s"  date="%s"/>\n' \
                              % (refmac_log.program(0).name, \
                                 refmac_log.program(0).ccp4version, \
                                 refmac_log.program(0).date))
               outfile.write('      <xyzin pdb_file="%s"/>\n' % mstat.model_list[model].phaser_PDBfile)
               outfile.write('      <hklin mtz_file="%s"/>\n' % mstat.model_list[model].refmac_phaser_MTZINfile)
               outfile.write('      <keyword>\n')
               outfile.write('        <labin> %s </labin>\n'     % mstat.model_list[model].refmac_phaser_keywords["LABIN"])
               outfile.write('        <n_cycle> %s </n_cycle>\n' % mstat.model_list[model].refmac_phaser_keywords["NCYC"])
               outfile.write('        <make> %s </make>\n'       % mstat.model_list[model].refmac_phaser_keywords["MAKE"])
               outfile.write('        <weight> %s </weight>\n'   % mstat.model_list[model].refmac_phaser_keywords["WEIGHT"])
               outfile.write('      </keyword>\n')
               outfile.write('      <r_factor_init> %.3f </r_factor_init>\n' % float(table.col("Rfact")[0]))
               outfile.write('      <r_factor> %.3f </r_factor>\n'           % float(table.col("Rfact")[-1]))
               outfile.write('      <r_free_init> %.3f </r_free_init>\n'     % float(table.col("Rfree")[0]))
               outfile.write('      <r_free> %.3f </r_free>\n'               % float(table.col("Rfree")[-1]))
               outfile.write('      <xyzout pdb_file="%s"/>\n' % mstat.model_list[model].refmac_phaser_PDBfile)
               outfile.write('      <hklout mtz_file="%s"/>\n' % mstat.model_list[model].refmac_phaser_MTZOUTfile)
               outfile.write('      <messages>\n')
               outfile.write('        <message_code>   0</message_code>\n')
               outfile.write('        <message_text> %s </message_text>\n' \
                              % refmac_log.program(0).termination_message)
               outfile.write('        <message_severity>information</message_severity>\n')
               outfile.write('      </messages>\n')
               outfile.write('    </refmac_run>\n')
            outfile.write('\n')

         outfile.write('    <mrbump_solution_molrep> %s </mrbump_solution_molrep>\n' % mstat.model_list[model].solution_type_MOLREP)
         outfile.write('    <mrbump_solution_phaser> %s </mrbump_solution_phaser>\n' % mstat.model_list[model].solution_type_PHASER)
         outfile.write('\n')

      outfile.write('  </molecular_replacement>\n')
      outfile.write('\n')
      outfile.write('<!-- this is a global block, but comes logically in this place -->\n')
      outfile.write('  <messages>\n')
      outfile.write('     <message_code>   0</message_code>\n')
      outfile.write('     <message_text>Normal Termination</message_text>\n')
      outfile.write('     <message_severity>information</message_severity>\n')
      outfile.write('  </messages>\n')
      outfile.write('\n')
      outfile.write('</mrbump_run>\n')

      outfile.close()

if __name__ == "__main__":

   target_info=MRBUMP_target_info.TargetInfo()
    
   target_info.seqfile="/tmp/seq.pir"
   target_info.sequence="ABCDEFGHIJKLMNOP"

   xml=writeXML()
   xml.target_details(target_info, "test.xml")
