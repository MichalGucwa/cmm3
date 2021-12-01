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
# Python script to handle PDB files.
# Ronan Keegan 15/11/04

import os, sys, string

class PDB_info:
  """ This classs is used to extract any relavent information from a PDB file. """

  def __init__(self):
     self.residues=[]
     self.expdata=''
     self.resolution_high=0.0
     self.resolution_low=0.0
     self.SEQRESsequence=''
     self.ATOMsequence=''
     self.seq_dict=dict([])
     self.sequence_length=0
     self.residue_map={'ALA' : 'A', 'CYS' : 'C', 'ASP' : 'D', 'GLU' : 'E',
          'PHE' : 'F', 'GLY' : 'G', 'HIS' : 'H', 'ILE' : 'I', 'LYS' : 'K', 
          'LEU' : 'L', 'MET' : 'M', 'ASN' : 'N', 'PRO' : 'P', 'GLN' : 'Q', 
          'ARG' : 'R', 'SER' : 'S', 'THR' : 'T', 'VAL' : 'V', 'TRP' : 'W', 
          'TYR' : 'Y', 'ADE' : 'A', 'CYT' : 'C', 'GUA' : 'G', 'THY' : 'T',
          'MSE' : 'M', 'TTQ' : 'W', 'DAL' : 'A'}
     try:
        self.debug=eval(os.environ['MRBUMP_DEBUG'])
     except:
        self.debug=False

  def setDEBUG(self, flag):
     self.debug=flag 

  def getSEQRES(self, pdb_name, chain):
     """ Read the SEQRES record from a PDB file and return its sequence in single
     letter format for a given chain id. If no chain id in file, assumes chain 
     A. """  

     PDBfile=open(pdb_name,'r')
     line=PDBfile.readline()
     raw_sequence=[]
     unknown_res=0

     while line:
        # Extract sequence from SEQRES records
        if 'SEQRES' in line[0:7]:
           list=(string.split(line[19:70]))
           chain_id = line[11]
           if chain_id == ' ':
              chain_id = 'A'
           if chain_id == chain:
              for res in list:
                 self.residues.append(res)
                 if self.residue_map.has_key(res) == False:
                    raw_sequence.append('X')
                    unknown_res = unknown_res + 1
                 else:
                    raw_sequence.append(self.residue_map[res])
        line=PDBfile.readline()
     PDBfile.close()
     sequence=string.join(raw_sequence).replace(' ','')
     self.sequence_length=len(sequence)
   
     self.SEQRESsequence = sequence
     return sequence
  
  def getSequence(self, pdb_name, chain=''):
     """ Read the ATOM records from a PDB file and return its sequence in single
     letter format for a given chain ID. If no chain id present in PDB file it 
     will assume chain A. If no value for chain is given in input, the entire 
     sequence is extracted from the PDB. If the file contains models it will 
     extract the sequence from the first model. Returns: string"""  

     PDBfile=open(pdb_name,'r')
     line=PDBfile.readline()
     raw_sequence=[]
     unknown_res=0
     prev_res_number=0
     model_no=1
     chain_found = False

     while line:
        # Test for pressence of models.
        if 'MODEL' in line[0:6]:   
           model_no = int(string.strip(line[11:14]))
        if model_no != 1:
           break
        # Retrieve atom record.
        if 'ATOM' in line[0:6] or ('HETAT' in line[0:6] and 'MSE' in line[17:20]):
           res_number = line[23:26]
           chain_id = line[21]
           if chain_id == ' ':
              chain_id = 'A'
           if res_number != prev_res_number and (chain_id == chain or chain == ''):
              if chain_id == chain and string.strip(chain) != '':
                 chain_found = True
              res = line[17:20]
              if self.residue_map.has_key(res) == False:
                 raw_sequence.append('X')
                 unknown_res = unknown_res + 1
              else:
                 raw_sequence.append(self.residue_map[res])
              prev_res_number = res_number
        line=PDBfile.readline()
     PDBfile.close()
  
     sequence=string.join(raw_sequence).replace(' ','')
     self.sequence_length=len(sequence)

     if chain_found == False:
        sys.stdout.write("Sequence retrieval warning: Chain: %s not found in PDB file.\n  (%s)\n" % (chain, pdb_name))
        sys.stdout.write("\n")
 
     self.ATOMsequence = sequence
     return sequence     

  def getAllSeqs(self, pdb_name):
     """ A function to extract all of the chain seqeuences from an input PDB file. 
         Returns a dictionary of chains and their associated seqeucens. """

     # Do some local initialisation
     raw_sequence=[]
     unknown_res=0
     prev_res_number=0

     chain_id=""
     prev_chain_id=""

     model_no=1

     count = 0

     # Open the PDB file for reading
     PDBfile=open(pdb_name,'r')
     line=PDBfile.readline()

     # Loop over the lines in the file 
     while line:
        # Retrieve atom record.
        if 'ATOM' in line[0:6] or ('HETAT' in line[0:6] and 'MSE' in line[17:20]):
           res_number = line[23:26]

           # Extract the chain identifier for the current atom
           # Ignore any chains with blank chain IDs if chain A 
           # is already assigned. This should catch files with
           # single chains that don't have chain specified.
           if line[21] == ' ':
              if self.seq_dict.has_key('A') == False: 
                 chain_id = 'A'
              else:
                 chain_id = 'IGNORE'
           else:
              chain_id = line[21]

           # Set the previous chain id to the current one if this is the first atom
           if count == 0:
              prev_chain_id = chain_id

           # If a new chain is encountered, write out the sequence of the previous chain
           if chain_id != prev_chain_id and prev_chain_id != 'IGNORE':
              sequence=string.join(raw_sequence).replace(' ','')
              self.seq_dict[prev_chain_id]=sequence
              raw_sequence=[]
           if chain_id != prev_chain_id and prev_chain_id == 'IGNORE':
              raw_sequence=[]
 
           # Extract the residue id if a new residue is encountered
           if res_number != prev_res_number:
              res = line[17:20]
              if self.residue_map.has_key(res) == False:
                 raw_sequence.append('X')
                 unknown_res = unknown_res + 1
              else:
                 raw_sequence.append(self.residue_map[res])
              prev_res_number = res_number

           # Increment the ATOM/HETATM line counter
           count = count + 1
        
           # Finally, set the previous chain id to the current
           prev_chain_id = chain_id

        # Catch for an NMR model. If MODEL is encountered we exit if we have already read one chain
        if "MODEL" in line[0:6] and count > 0: 
           break
              
        line=PDBfile.readline()

     # Write out the last sequence
     if chain_id != 'IGNORE':
        sequence=string.join(raw_sequence).replace(' ','')
        self.seq_dict[chain_id]=sequence
 
     # Close the PDB file
     PDBfile.close()
  

  def getEXPDTA(self, pdb_name):
     """ Make a record of the EXPDTA (experimental data) section in the PDB file \
     for later processing. Useful for excluding NMR models."""

     PDBfile=open(pdb_name,'r')
     line=PDBfile.readline()

     while line:
        # Look for the EXPDTA line and other details
        if 'EXPDTA' in line[0:7]:
           self.expdata = self.expdata + " " + string.strip(line)[9:]
        if 'RESOLUTION' in line.upper() and 'RANGE' in line.upper() and 'HIGH' in line.upper() and 'ANGSTROMS' in line.upper():
           if self.is_a_float(string.split(line)[-1]):
              self.resolution_high = float(string.split(line)[-1]) 
           else:
              self.resolution_high = 0.0
        if 'RESOLUTION' in line.upper() and 'RANGE' in line.upper() and 'LOW' in line.upper() and 'ANGSTROMS' in line.upper():
           if self.is_a_float(string.split(line)[-1]):
              self.resolution_low = float(string.split(line)[-1])
           else:
              self.resolution_low = 0.0
        line=PDBfile.readline()

     PDBfile.close()
   
     return self.expdata

  def is_an_integer(self, s):
      """ A quick function to check if a string is an integer. """
   
      try: int(s)
      except ValueError: return False
      else: return True   

  def is_a_float(self, s):
      """ A quick function to check if a string is a float. """
   
      try: float(s)
      except ValueError: return False
      else: return True   


if __name__ == "__main__":

   seqS=""
   seqA=""
   seqF=""

   p=PDB_info()

   file=sys.argv[1]

   seqS=p.getSEQRES(file,"A")
   seqF=p.getSequence(file) 
   seqA=p.getSequence(file, "A") 
   seqAll=p.getAllSeqs(file)
   
   print ""
   print "SEQRES record sequence:"
   print ""
   print seqS
   print ""
   print "ATOM/HETATM record sequence:"
   print ""
   print seqF
   print ""
   print "ATOM/HETATM record 'A' sequence:"
   print ""
   print seqA
   print ""

   print ""
   print "All sequences from ATOM/HETATM records:"
   for chain in p.seq_dict.keys():
      print chain, p.seq_dict[chain]
      print ""
