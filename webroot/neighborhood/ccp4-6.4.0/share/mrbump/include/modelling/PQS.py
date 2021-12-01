#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2005 Ronan Keegan
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# Ronan Keegan 23/11/04

import os, sys, string, operator, time
from urllib import urlretrieve
import shutil

import Model_struct
import PDB_info 
import MRBUMP_MAFFT
import MRBUMP_PROBCONS
import MRBUMP_T_COFFEE
import MRBUMP_CLUSTALW
import MRBUMP_pdbset
import MRBUMP_pdbcur
import MRBUMP_chainsaw

class PQS_struct:
   """ A structure to hold details about each of the PQS models that are found. """
   """ file_list in PQS is a dictionary that will hold these structures. """

   def __init__(self):
      self.chainname=""
      self.filename=""
      self.parent_chain=""
      self.seqID=0.0
      self.source=""

   def setSource(self, source):
      self.source=source

class PQS:
   """ A class to retrieve any multimer structure files from the PQS database at the
   EBI that a relevent to our search. """

   def __init__(self):
      self.pdb_code=''
      self.pqs_files=[]

      self.pqs_list_file=''
      self.pqs_asalist_file=''

      self.pqs_biolist_file=''

      self.chainsaw_ALIGNIN=''
      self.process_success=False

      self.search_num=0

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setPDBcode(self, pdb_code):
      self.pdb_code=pdb_code

   def set_pqs_list(self, MRBUMP_SETUP_DIR):
      """ A function to set the PQS list files from the EBI database. Sets
      the file, ASA and BIO list files."""
      
      # File list
      self.pqs_list_file=MRBUMP_SETUP_DIR + "/pqs_LIST.txt"
  
      # Test to see if the file exists.
      if not (os.path.isfile(self.pqs_list_file)) and debug:
         print "Error accessing PQS List file: file not found." 

      # ASA list
      self.pqs_asalist_file=MRBUMP_SETUP_DIR + "/pqs_ASALIST.txt"
  
      # Test for files existance. 
      if not (os.path.isfile(self.pqs_asalist_file)) and debug:
         print "Error accessing PQS ASA List file: file not found." 

      # BIO list
      self.pqs_biolist_file=MRBUMP_SETUP_DIR + "/pqs_BIOLIST.txt"
  
      # Test for files existance. 
      if not (os.path.isfile(self.pqs_biolist_file)):
         print "Error accessing PQS BIO List file: file not found." 

   def getAlignment(self, input_PDB, chain, target_info, number_mols, MAPROGRAM):
      """ A function to retrieve the sequence of the multimer and align it with the target
      sequence for chainsaw. Returns: string"""
 
      # Call PDB_info the get the sequence of the multimer
      p=PDB_info.PDB_info() 
      sequence = p.getSequence(input_PDB)
      
      # Write this sequence and the target sequence to a fasta file so they can be aligned
      aln_in_file = os.path.join(os.environ['CCP4_SCR'], 'alignment_' + chain + '_in.fasta') 
      aln_out_file = os.path.join(os.environ['CCP4_SCR'], 'alignment_' + chain + '_out.pir') 
      infile=open(aln_in_file, 'w')

      infile.write(">" + target_info.chainID + "\n")
      infile.write(target_info.sequence * number_mols + "\n")
      infile.write(">" + chain + "\n")
      infile.write(sequence + "\n")

      infile.close()
      
      # Set the log file for the alignment program output
      aln_logfile=os.path.join(os.environ['CCP4_SCR'], "pqs_alignment.log")

      # Now do the alignment (using MAFFT, Probcons, TCoffee or Clustalw)
      if MAPROGRAM=='MAFFT':
         ma=MRBUMP_MAFFT.Mafft() 
         ma.Mafft(aln_in_file, aln_out_file, aln_logfile) 
         ma.convert_to_pir(aln_out_file)
      elif MAPROGRAM=='PROBCONS':
         pc=MRBUMP_PROBCONS.Probcons()
         pc.setLogFile(aln_logfile)
         pc.Probcons(aln_in_file, aln_out_file)
      elif MAPROGRAM=='T_COFFEE':
         tc=MRBUMP_T_COFFEE.T_coffee()
         tc.setLogFile(aln_logfile)
         tc.T_coffee(aln_in_file, aln_out_file)
      elif MAPROGRAM=='CLUSTALW':
         cl=MRBUMP_CLUSTALW.Clustalw()
         cl.Clustalw(aln_in_file, aln_out_file, aln_logfile)

      return aln_out_file


   def processPDB(self, mstat, input_PDB, output_PDB, chain, target_info, number_mols, MAPROGRAM):
      """ A function to process the coordinate files for the PQS matches. Processes them
      using PDBset and PDBcur. """
       
      # Set the processing success flag to true
      self.process_success = True

      # set up some temporay files for intermediate steps in the processing
      pdbset_output_PDB = os.path.join(os.environ['CCP4_SCR'], 'pdbset_' + chain + '.pdb')
      pdbcur_output_PDB = os.path.join(os.environ['CCP4_SCR'], 'pdbcur_' + chain + '.pdb')

      # exlcude waters using PDBset
      pset=MRBUMP_pdbset.PDBset()
      pset.setKEYWORD("EXCLUDE HOH")
      pset_code = pset.pdbset(input_PDB, pdbset_output_PDB)
      if pset_code == 1:
         if self.debug:
            sys.stdout.write("\n")
            sys.stdout.write("Chain: %s failed in PQS PDB processing (pdbset)\n" % chain)
         sys.stdout.write("\n")

         self.process_success = False
      
      else: 
         # delete hydrogens and select most probable confimations for side chains with PDBcur 
         pcur=MRBUMP_pdbcur.PDBcur() 
         pcur.setKEYWORD("delh")
         pcur.setKEYWORD("cutocc")
         pcur.setKEYWORD("mostprob")
         pcur_code = pcur.pdbcur(pdbset_output_PDB, pdbcur_output_PDB)
         if pcur_code == 1:
            if self.debug:
               sys.stdout.write("\n")
               sys.stdout.write("Chain: %s failed in PQS PDB processing (pdbcur)\n" % chain)
            sys.stdout.write("\n")

            self.process_success = False
   
         else:
            # Get the alignment to give to Chainsaw 
            #alignin = self.getAlignment(pdbcur_output_PDB, chain, target_info, number_mols, MAPROGRAM)
            alignin = self.chainsaw_ALIGNIN 

            # Call chainsaw to do the side-chain pruning
            csaw=MRBUMP_chainsaw.Chainsaw()
            csaw_code = csaw.chainsaw(pdbcur_output_PDB, alignin, output_PDB)
            if csaw_code == 1:
               if self.debug:
                  sys.stdout.write("\n")
                  sys.stdout.write("Chain: %s failed in PQS PDB processing (chainsaw)\n" % chain)
                  sys.stdout.write("     XYZIN:   %s\n"   % pdbcur_output_PDB)
                  sys.stdout.write("     ALIGNIN: %s\n" % alignin)
                  sys.stdout.write("     XYZOUT:  %s\n"  % output_PDB)
               sys.stdout.write("\n")

               self.process_success = False

   def get_pqs_files(self, init, target_info, mstat, MAPROGRAM):
      """ A function to scan the PQS list file and download any multimers related to 
      our search models. """

      # Setup a dictionary for storing the multimer information
      multi_list=dict([])
      file_list=dict([])

      no_of_multimers = 0
      
      list=open(self.pqs_list_file)
      asalist=open(self.pqs_asalist_file)

      ignore=[]

      # Loop over all of our matching PDB's
      for chain in mstat.chain_list.keys():
         self.setPDBcode(mstat.chain_list[chain].PDBName)

         # Scan the PQS list file for any possible multimer files
         line=list.readline()
         while line:
            if self.pdb_code in line:

               # Create a PQS structure
               p=PQS_struct()
               p.filename=string.strip(line)
               p.chainname=(string.split(p.filename, "."))[0]
               p.parent_chain=chain
               p.seqID=mstat.chain_list[chain].seqID
               p.setSource("PQS")

               # Add this file to the file list dict
	       file_list[p.filename]=p
               self.pqs_files.append(p.filename)
            line=list.readline()
         list.seek(0)

      list.close()
	
      # Populate the multimer structure and download each of the multimeric files found
      for file in file_list.keys():
            
            m=Model_struct.Models_struct()
            name=string.split(file,'.')

            # Set the number of molecules in this multimer. If not found in ASA list default is
            # a monomer or = 1
	    line=asalist.readline()
	    while line:
              if name[0] in line: 
                 m.setNumberMols(int(string.split(line)[4]))
                 m.setMultiType(string.split(line)[2])
	      line=asalist.readline()
            asalist.seek(0)

	    # Check to see that the multimer is useful
	    #if m.num_mols == 1 or 'HOMO' not in m.multi_type or operator.mod(target_info.no_of_mols, m.num_mols) != 0:
	    if m.number_mols == 1 or 'HOMO' not in m.multi_type:
	       if m.number_mols == 1:
		  print "PQS log message: " + name[0] + " rejected as it has no non-monomer multimers"
	       elif 'HOMO' not in m.multi_type:
		  print "PQS log message: " + name[0] + " rejected as it has hetrogeneous molecules"
	       #else:
		#  print "PQS log message: " + name[0] + " rejected as it does not have the correct number of molecules for this target"

	    # Otherwise, add this multimer to the list
	    else:
            	if '_' in name[0]:
                   m.setPDBName(name[0][0:4])
                   m.setModelChainSource(name[0])
                   m.setModelName(name[0])

            	else: 
                   m.setPDBName(name[0])
                   m.setModelChainSource(name[0] + '_0')
                   m.setModelName(name[0] + '_0')

                m.seqID.append(file_list[file].seqID)
                m.setModelTypeExtension(name[1])
                m.setModelType('MULTMR')

            	# Make a directory for this match
                m.setModel_directory(os.path.join(init.search_dir, 'data', m.chain_source))
                if not os.path.exists(m.model_directory):
            	  os.mkdir(m.model_directory)
                pdb_file_dir = os.path.join(m.model_directory, 'pdb_file')
                if not os.path.exists(pdb_file_dir):
            	  os.mkdir(pdb_file_dir)
                mr_dir = os.path.join(m.model_directory, 'mr')
                if not os.path.exists(mr_dir):
            	  os.mkdir(mr_dir)
                if "MOLREP" in init.keywords.MR_PROGRAM_LIST:
                   os.mkdir(os.path.join(m.model_directory, 'mr', 'molrep'))
                   os.mkdir(os.path.join(m.model_directory, 'mr', 'molrep', 'refine'))
                if "PHASER" in init.keywords.MR_PROGRAM_LIST:
                   os.mkdir(os.path.join(m.model_directory, 'mr', 'phaser'))
                   os.mkdir(os.path.join(m.model_directory, 'mr', 'phaser', 'refine'))

                # Set the location of the PDB file
                m.PDBfile.append(os.path.join(m.model_directory, 'pdb_file', m.chain_source + '.pdb'))
                unprocessedPDBfile = os.path.join(init.search_dir, 'PDB_files', m.chain_source + '.' + m.type_extension)

            	pqs_file_url="http://pqs.ebi.ac.uk/pqs-doc/macmol/" + file
            	#local_file=init.search_dir + '/data/' + m.chain_source + '/pdb_files/' + m.PDBfile[0]
                try:
            	   urlretrieve(pqs_file_url, unprocessedPDBfile)

                   # Set the input alignment file for chainsaw
                   self.chainsaw_ALIGNIN=mstat.chain_list[file_list[file].parent_chain].pir_aln_file

                   # Process the coordinate file
                   self.processPDB(mstat, unprocessedPDBfile, m.PDBfile[0], m.chain_source, target_info, m.number_mols, MAPROGRAM)

                   # Add this multimer to the dictionary list
                   if self.process_success == True:
               	      mstat.model_list[m.chain_source]=m
                      no_of_multimers = no_of_multimers + 1
                except:
                   sys.stdout.write("\n")
                   sys.stdout.write("PQS download Error: Could not retrieve PQS file for chain: %s\n" % m.chain_source)
                   sys.stdout.write("                    There may be a problem with the internet connection.\n")
                   sys.stdout.write("                    Do you need to set a proxy server?\n")
                   sys.stdout.write("\n")
  
                   
      asalist.close()

      # Set the number of multimers tracker variable
      mstat.setNoofPQSHits(no_of_multimers)

      print "\n"
      print "PQS log message: %d multimers have been found and added to model list\n" % mstat.no_of_PQShits
      for model in mstat.model_list.keys():
         if mstat.model_list[model].number_mols > 1:
            print "PQS log message: Multimer found, chain ID: %s" % mstat.model_list[model].chain_source
            print "PQS log message: Base PDB code: %s" % mstat.model_list[model].PDBName
            print "PQS log message: Type: %s, Num of molecules: %s\n" % (mstat.model_list[model].type, mstat.model_list[model].number_mols)
             
      # Insert the multimers into the sorted list for MR
      for name in mstat.sorted_MR_list:
      # Make a note of the position of the current chain in the sorted list
         position = mstat.sorted_MR_list.index(name)
         
      # Loop over the model list and append the multimers in the correct order
         for model in mstat.model_list.keys():

      # Check that we have not added it already
            if name not in ignore and mstat.chain_list.has_key(name) and \
                mstat.chain_list[name].PDBName not in ignore:

      # If we have a multimer and the PDB id is the same as that in the list inset the multimer after the monomer(s)
               if mstat.model_list[model].number_mols > 1 and mstat.model_list[model].PDBName == mstat.chain_list[name].PDBName:
                  mstat.sorted_MR_list.insert(position, mstat.model_list[model].chain_source)

      # Add the multimer and its parent PDB id to the ignore list
                  ignore.append(mstat.model_list[model].chain_source)
                  ignore.append(mstat.chain_list[name].PDBName)
      
