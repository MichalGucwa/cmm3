#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2006 Martyn Winn, Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#

import os, sys, string
import urllib
import shutil

import Model_struct
import Matches

class PISA_struct:
   """ A structure to hold details about an individual PISA assembly. """

   def __init__(self):
      self.id=""
      self.diss_energy=""
      self.bsa=""
      self.size=""
      self.chain_list=[]
      self.rotm_list=[]
      self.trans_list=[]

   def print_summary(self):
      sys.stdout.write("   Assembly with free energy of dissociation %.3f and buried surface area %.1f\n" % (self.diss_energy, self.bsa))
      sys.stdout.write("   Contains %d chains:\n" % self.size)
      for chain in self.chain_list:
         sys.stdout.write("      Chain %s\n" % chain)

class PISA:
   """ A class to retrieve the PISA results for a given set of search model templates. """

   def __init__(self):
      self.PISA_url="http://www.ebi.ac.uk/msd-srv/prot_int/cgi-bin/multimers.pisa?"
      self.pdb_file_list=[]
      self.local_xml=""
      self.pisa_assembly_list=[]
      self.pdbsetEXE       = os.path.join(os.environ['CBIN'], 'pdbset')
      self.pdbcurEXE       = os.path.join(os.environ['CBIN'], 'pdbcur')
      self.pdb_mergeEXE    = os.path.join(os.environ['CBIN'], 'pdb_merge')

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setLocalXML(self, filename):
      self.local_xml = filename
      
   def download_PISA_XML(self, pdb_id):
      """ A function to download the results XML for a given PDB from the PISA server. """

      # Check the pdb_id is ok
      if pdb_id[0].isdigit() == False or pdb_id.isalnum == False or len(pdb_id) != 4:
         print "PISA log: " + pdb_id + " is not a valid PDB identifier"

      # If all is ok then retrieve the results 
      else:
        
         # Assign the local XML filename if is not set already
         if self.local_xml == "":
            print "PISA log: Local XML file name is not set. Using pisa_" + pdb_id + ".xml"
            self.setLocalXML("pisa_" + pdb_id + ".xml")
 
         try:
            urllib.urlretrieve(self.PISA_url + pdb_id, self.local_xml)
            urllib.urlcleanup()
            print "PISA log: PISA results for " + pdb_id + " saved to file " + self.local_xml 
            print ""
         except:
            print "PISA log: PISA results could not be retrieved for " + pdb_id
            print "PISA log: The url used was:\n " + self.PISA_url + pdb_id 
            print ""

   def parseLocalXML(self):
      """ Parse the XML file for one PDB entry and create a list of assembly
          objects. One day, this could be replaced by proper XML parser! 
          Therefore, don't extend functionality beyond parsing."""

      xml_results=open(self.local_xml)

      line=xml_results.readline()
      while line:

         # Start of new assembly
         # There may be several assemblies in an asm_set
         if "<assembly>" in line:
           a=PISA_struct()

         if "<id>" in line:
           a.id=line[line.index("<id>")+4:line.index("</id>")]
         # Free energy of dissociation
         if "<diss_energy>" in line:
           a.diss_energy=float(line[line.index("<diss_energy>")+13:line.index("</diss_energy>")])
         # Buried surface area
         if "<bsa>" in line:
           a.bsa=float(line[line.index("<bsa>")+5:line.index("</bsa>")])

         # Number of chains in the assembly
         if "<size>" in line:
           a.size=int(line[line.index("<size>")+6:line.index("</size>")])

         # Chain list for assembly
         if "<chain_id>" in line:
           a.chain_list.append(line[line.index("<chain_id>")+10:line.index("</chain_id>")])

         if "<rxx-f>" in line:
           rotm = line[line.index("<rxx-f>")+7:line.index("</rxx-f>")]
         if "<rxy-f>" in line:
           rotm += ' ' + line[line.index("<rxy-f>")+7:line.index("</rxy-f>")]
         if "<rxz-f>" in line:
           rotm += ' ' + line[line.index("<rxz-f>")+7:line.index("</rxz-f>")]
         if "<ryx-f>" in line:
           rotm += ' ' + line[line.index("<ryx-f>")+7:line.index("</ryx-f>")]
         if "<ryy-f>" in line:
           rotm += ' ' + line[line.index("<ryy-f>")+7:line.index("</ryy-f>")]
         if "<ryz-f>" in line:
           rotm += ' ' + line[line.index("<ryz-f>")+7:line.index("</ryz-f>")]
         if "<rzx-f>" in line:
           rotm += ' ' + line[line.index("<rzx-f>")+7:line.index("</rzx-f>")]
         if "<rzy-f>" in line:
           rotm += ' ' + line[line.index("<rzy-f>")+7:line.index("</rzy-f>")]
         if "<rzz-f>" in line:
           rotm += ' ' + line[line.index("<rzz-f>")+7:line.index("</rzz-f>")]
           a.rotm_list.append(rotm)
         if "<tx-f>" in line:
           trans = line[line.index("<tx-f>")+6:line.index("</tx-f>")]
         if "<ty-f>" in line:
           trans += ' ' + line[line.index("<ty-f>")+6:line.index("</ty-f>")]
         if "<tz-f>" in line:
           trans += ' ' + line[line.index("<tz-f>")+6:line.index("</tz-f>")]
           a.trans_list.append(trans)

         # Copy finished assembly
         if "</assembly>" in line:
           self.pisa_assembly_list.append(a)

	 line=xml_results.readline()

      xml_results.close()

   def get_pisa_files(self, target_info, init, mstat):
      """ A function to get the PISA results for the list of search model templates. 
      Then create any relevant multimer search models. """

      mrsearchdir = init.search_dir
      multimer_list=[]
      no_of_multimers = 0

      # Loop over all of our matching PDB's
      if self.debug:
         print "sorted_MR_list (list of chains for MR) is: " 
         print mstat.sorted_MR_list
         print "sorted_list (full list of matching chains) is: " 
         print [mstat.sorted_list[i][0] for i in range(len(mstat.sorted_list))]

      # this is list of templates to be used in MR
      for chain in mstat.sorted_MR_list:

         PDBcode = mstat.chain_list[chain].PDBName
         # only do unique PDB codes in template list
         if PDBcode in self.pdb_file_list:
            continue
         self.pdb_file_list.append(PDBcode)

         if self.debug:
            sys.stdout.write("\nChecking PISA for chain: %s \n" % PDBcode)

         # create pisa files in directory of base chain
         self.setLocalXML(os.path.join(mrsearchdir, 'data', chain, 'pisa_' + PDBcode + '.xml'))
         self.download_PISA_XML(PDBcode)
         self.parseLocalXML()

         if len(self.pisa_assembly_list) > no_of_multimers:

            # for the moment we are just taking the first multimer
            multimer_index = 0
            sys.stdout.write("Multimer found:\n")
            self.pisa_assembly_list[no_of_multimers].print_summary()

            # Create a new chain object
            c=Matches.Chain_struct()
            c.setSource('PISA')
            c.setMultimerType('MULTIMER')
            c.setchainName(PDBcode + '_' + str(multimer_index))
            c.setchainID(str(multimer_index))
            c.setPDBName(PDBcode)

            # Create the directory for this multimer template e.g. 1xyz_0
            mtemplate_dir = os.path.join(mrsearchdir, 'data', c.chainName)
            os.mkdir(mtemplate_dir)
            c.setWorkingDIR(mtemplate_dir)

            # loop over requested model types
            for imod in init.model_types:

              if imod == 'PDBCLP':
                multimer_files_dir = os.path.join(mtemplate_dir, 'pdbclip')
              elif imod == 'MOLREP':
                multimer_files_dir = os.path.join(mtemplate_dir, 'molrep')
              elif imod == 'CHNSAW':
                multimer_files_dir = os.path.join(mtemplate_dir, 'chainsaw')
              elif imod == 'SCLPTR':
                multimer_files_dir = os.path.join(mtemplate_dir, 'sculptor')
              elif imod == 'PLYALA':
                multimer_files_dir = os.path.join(mtemplate_dir, 'plyala')
              os.mkdir(multimer_files_dir)
              os.mkdir(os.path.join(multimer_files_dir, 'mr'))
              if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                 os.mkdir(os.path.join(multimer_files_dir, 'mr', 'molrep'))
                 os.mkdir(os.path.join(multimer_files_dir, 'mr', 'molrep', 'refine'))
              if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                 os.mkdir(os.path.join(multimer_files_dir, 'mr', 'phaser'))
                 os.mkdir(os.path.join(multimer_files_dir, 'mr', 'phaser', 'refine'))

              first_chain = True
              number_chains = 0
              # loop over chains in specific multimer
              for mchain in self.pisa_assembly_list[no_of_multimers].chain_list:

                ChainName = PDBcode + '_' + mchain

                # Exclude chains that are not in full fasta list e.g. ligands
                # These won't have directories created for them.
                if ChainName not in [mstat.sorted_list[i][0] for i in range(len(mstat.sorted_list))]:
                  print "Skipping chain " + PDBcode + '_' + mchain + " - it appears to be different from target"
                  continue

                ### use pdbset to get chains with symmetry applied

                # Write the key file for pdbset
                ps_key =  'rotate matrix ' + self.pisa_assembly_list[no_of_multimers].rotm_list[0] + '\n'
                ps_key +=  'shift fractional ' + self.pisa_assembly_list[no_of_multimers].trans_list[0] + '\n'
                ps_key +=  'end\n'
                # Write out the key file if we are running in debug mode
                if self.debug:
                  ps_keyfile=os.path.join(multimer_files_dir, 'ps_key_' + mchain + '.in')
                  ps_key_input=open(ps_keyfile, 'w')
                  ps_key_input.write(ps_key)
                  ps_key_input.close()

                termination=False
                # Set the Pdbset logfile
                ps_logfile=os.path.join(multimer_files_dir, 'pdbset_' + mchain + '.log')
                ps_inputfile=os.path.join(mrsearchdir, 'data', PDBcode + '_' + mchain, 'pdb_file', PDBcode + '_' + mchain + '.pdb')

                # Check that the input PDB exists: a multimer may contain individual chains
                # which are not on the model list
                if not os.path.isfile(ps_inputfile):
                  unprocessed_file=os.path.join(mrsearchdir, 'PDB_files', PDBcode + '.pdb')

                  if self.debug:
                    print "Chain " + PDBcode + '_' + mchain + " is missing, downloading it."

                  pdb_get=Matches.PDB_get()
                  pdb_get.download_single_PDB(PDBcode, unprocessed_file, init.keywords.PDBDIR)

                  # the following is a cut-down version of that in Matches.py, needs to be rationalised!
                  pdbclip_DIR=os.path.join(mrsearchdir, 'data', PDBcode + '_' + mchain, 'pdbclip')

                  # Write the key file for pdbcur
                  pc_key =  'lvchain /1/' + mchain + '\n'
                  pc_key += 'delh\n'
                  pc_key += 'cutocc\n'
                  pc_key += 'mostprob\n'
                  pc_key += 'end\n'
   
                  # Write out the key file if we are running in debug mode
                  if self.debug:
                    pc_keyfile=os.path.join(pdbclip_DIR, 'pc_key.in')
                    pc_key_input=open(pc_keyfile, 'w')
                    pc_key_input.write(pc_key)
                    pc_key_input.close()

                  # Run pdbcur to strip chains and do some other editing
                  termination=False
                  if self.debug:
                    print "modifying with pdbcur....."
   
                  # Set the PDBcur logfile
                  PDBcurLog=os.path.join(pdbclip_DIR, 'pdbcur_' + mchain + '.log')
     
                  # Run pdbcur on this pdb file
                  i,o=os.popen2(self.pdbcurEXE + ' xyzin ' + unprocessed_file + ' xyzout ' + ps_inputfile)
                  i.write(pc_key)
                  i.close()

                  out=o.readline()
                  log=open(PDBcurLog, "w")
   
                  while out:
                    if 'Normal termination' in out:
                       termination=True
                    log.write(out)
                    out=o.readline()
                  o.close()
                  log.close()
   
                  if not termination:
                    print "PDB download log: pdbcur failed for %s" % CHAIN.chainName 
                    if self.debug:
                       print "PDB download log: log file can be found at: \n " + PDBcurLog
   
                  if self.debug:
                    print ""

                # Run pdbset to apply symmetry operator
                ps_outputfile = os.path.join(multimer_files_dir, PDBcode + '_' + mchain + '_s.pdb')
                i,o=os.popen2(self.pdbsetEXE + ' xyzin ' + ps_inputfile + ' xyzout ' + ps_outputfile)
                i.write(ps_key)
                i.close()

                out=o.readline()
                log=open(ps_logfile, "w")
   
                while out:
                  if 'Normal termination' in out:
                    termination=True
                  log.write(out)
                  out=o.readline()
                o.close()
                log.close()

                # next we add each chain into a single file
                if first_chain:
                  current_multimer_file = os.path.join(multimer_files_dir, PDBcode + '_' + mchain + '_mult.pdb')
                  shutil.copy(ps_outputfile, current_multimer_file)
                  last_multimer_file = current_multimer_file
                else:

                  # Write the key file for pdb_merge
                  pm_key =  'nomerge\n'
                  pm_key += 'end\n'

                  # Write out the key file if we are running in debug mode
                  if self.debug:
                    pm_keyfile=os.path.join(multimer_files_dir, 'pm_key.in')
                    pm_key_input=open(pm_keyfile, 'w')
                    pm_key_input.write(pm_key)
                    pm_key_input.close()

                  termination=False
                  # Set the pdb_merge logfile
                  PDBmergeLog=os.path.join(multimer_files_dir, 'pdbmerge_' + mchain + '.log')
     
                  # Run pdb_merge on this pdb file
                  current_multimer_file = os.path.join(multimer_files_dir, PDBcode + '_' + mchain + '_mult.pdb')
                  i,o=os.popen2(self.pdb_mergeEXE + ' xyzin1 ' + last_multimer_file + ' xyzin2 ' + ps_outputfile + ' xyzout ' + current_multimer_file)
                  i.write(pm_key)
                  i.close()
                  last_multimer_file = current_multimer_file

                  out=o.readline()
                  log=open(PDBmergeLog, "w")
   
                  while out:
                    if 'Normal termination' in out:
                       termination=True
                    log.write(out)
                    out=o.readline()
                  o.close()
                  log.close()
   
                  if not termination:
                    print "PDB download log: pdb_merge failed for %s" % CHAIN.chainName 
                    if self.debug:
                       print "PDB download log: log file can be found at: \n " + PDBmergeLog
   
                  if self.debug:
                    print ""

                first_chain = False
                number_chains += 1

              # copy final multimer file to final place e.g. data/1n5b_1/chainsaw/1n5b_1.pdb
              shutil.copy(last_multimer_file, os.path.join(multimer_files_dir, c.chainName + '.pdb'))
              c.setNumberMonomers(number_chains)
              if imod == 'PDBCLP':
                c.setClipModelPDB(os.path.join(multimer_files_dir, c.chainName + '.pdb'))

            # add "chain" to chain_list
            mstat.chain_list[c.chainName] = c
            # add multimer to list and go back for next multimer for this PDB code
            multimer_list.append(c.chainName)

         # Finished with this PDB code, update no of multimers
         no_of_multimers += len(self.pisa_assembly_list)

      # loop over all multimers, and insert before corresponding chains
      for multimer in multimer_list:
         base_code = multimer[0:4]
         for ind in range(len(mstat.sorted_MR_list)):
            if base_code in mstat.sorted_MR_list[ind]:
              mstat.sorted_MR_list.insert(ind,multimer)
              break

if __name__=='__main__':
 
   pisa=PISA()
   pisa.download_PISA_XML("1xmp")

