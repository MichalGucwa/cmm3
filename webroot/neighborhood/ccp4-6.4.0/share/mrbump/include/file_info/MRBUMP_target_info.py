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
# A Python script to take a sequence file in Fasta format and its mtz file
# and extract a bunch of useful information from them for molecular replacement
# and refinement.
#
# Ronan Keegan 1/11/04

import string, os, sys, time
import MTZ_info 
import Nmol_calc
import Matthews_coef


class TargetInfo:
   """ Collect some information about a target structure. """

   def __init__(self):
     self.seqfile = ""
     self.seqfilename = ""
     self.hklin = ""
     self.hklin_filename = ""
     self.enant_hklin = ""
     self.refinement_hklin = ""
     self.matt_coef_logfile = ""
     self.logfile = ""
    
     self.unique_logfile=""
     self.unique_MTZOUTfile=""

     self.cad_logfile=""
     self.cad_MTZOUTfile=""

     self.aniso_logfile=""
     self.aniso_MTZOUTfile=""

     self.ecalc_logfile=""
     self.ecalc_MTZOUTfile=""
     self.target_ecalc_MTZOUTfile=""
     self.enant_ecalc_MTZOUTfile=""

     self.pickle_file = ''
     self.chainID = ''
     self.sequence = ''
     self.pretty_sequence = ''
     self.seqheader = ''
     self.no_of_res = 0
     self.mol_weight = 0.0
     self.solvent = 0.0
     self.fixed_MW = 0.0
     self.resolution = 0.0
     self.no_of_mols = 0 
     self.NCS=False
     self.TWINNED=False

     self.space_group = ""
     self.symmetry_no = 0
     self.enant_spacegroup = ""
     self.cell_dimensions=dict([])
     
     self.cell_dimensions["a"] = 0.0
     self.cell_dimensions["b"] = 0.0
     self.cell_dimensions["c"] = 0.0
     self.cell_dimensions["alpha"] = 0.0
     self.cell_dimensions["beta"] = 0.0
     self.cell_dimensions["gamma"] = 0.0

     self.hklin_SG_code = ""
     self.enant_SG_code = ""

     self.mtz_coldata=dict()
     self.col_labels=[]
     
     self.Error=[]
     self.Error.append(False)
     self.Error.append('')

      # SG codes (enantiomorphic spacegroups only)
     self.SG_Codes={"P31" : "144", "P32" : "145", "P3112" : "151", "P3212" : "153", "P3121" : "152", "P3221" : "154", "P41" : "76", "P43" : "78", "P4122" : "91", "P4322" : "95", "P4121" : "92", "P4321" : "96", "P61" : "169", "P65" : "170", "P62" : "171", "P64" : "172", "P6122" : "178", "P6522" : "179", "P6222" : "180", "P6422" : "181", "P4332" : "212", "P4132" : "213"}

     self.ENANT_SG={"144" : "145", "145" : "144", "151" : "153", "153" : "151", "152" : "154", "154" : "152", "76" : "78", "78" : "76", "91" : "95", "95" : "91", "92" : "96", "96" : "92", "169" : "170", "170" : "169", "171" : "172", "172" : "171", "178" : "179", "179" : "178", "180" : "181", "181" : "180", "212" : "213", "213" : "212"}

     self.AminoAcids = ["A","B","C","D","E","F","G","H","I","K","L","M","N","P","Q","R","S","T","V","W","Y","X","*","Z"]
     self.AminoAcidWeights = [89.09, 132.61, 121.15, 133.10, 147.13, 165.19, 75.07, 155.16, 131.17, 146.19, 131.17, 149.21, 
                              132.12, 115.13, 146.15, 174.20, 105.09, 119.12, 117.15, 204.23, 181.19, 128.16, 0.0, 146.64]
     try:
        self.debug=eval(os.environ['MRBUMP_DEBUG'])
     except:
        self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def setTargetInfo(self, init, mrsearchdir):
     """ The main function for setting the various details related to the target structure. """

     self.setTargetFile(init.seqin, init.keywords.JOBID)
     self.setTargetChainID(init.keywords.JOBID)
     self.setTargetSeq_Res()
     self.parseSeqfile(init.seqin, init.keywords.JOBID)
     self.setTargetWeight()
     self.prettySequence(80)
 
     # If running in MR mode extract MTZ details
     if init.ONLYMODELS == False:
        self.setTargetMTZdata(init.hklin)
        self.setTargetMTZinfo(mrsearchdir,init.keywords.col_labels)
        self.setTargetNum_mols(init)

     return self.Error

   def setMattCoefLogfile(self, filename):
      self.matt_coef_logfile=filename

   def printTargetInfo(self, init):
     """ Print the Target details to the stdout. """

     sys.stdout.write("\n")
     sys.stdout.write("Sequence file: %s\n" % self.seqfile)
     if init.ONLYMODELS == False:
        sys.stdout.write("Reflection (MTZ) file: %s\n" % self.hklin)
     sys.stdout.write("Number of residues: %d\n" % self.no_of_res)
     sys.stdout.write("Molecular Weight (daltons): %.3f\n" % self.mol_weight)
     if init.ONLYMODELS == False:
        sys.stdout.write("Estimated number of molecules to search for in a.s.u.: %d\n" % self.no_of_mols)
        sys.stdout.write("Resolution of collected data (angstroms): %.3f\n" % self.resolution)
     sys.stdout.write("\n")

   def setTargetFile(self, seq_file, job_id):
     """ Set the input sequence handler. """
 
     self.seqfile = seq_file
     #self.parseSeqfile(seq_file, job_id)
     self.seqfilename = string.split(seq_file,'/')[-1]

   def setTargetMTZdata(self, mtzdata):
     """ Set the input MTZ file handler. """

     self.hklin = mtzdata
     self.hklin_filename = string.split(mtzdata,'/')[-1]

   def setPickleFile(self, pickle_file):
      self.pickle_file = pickle_file

   def setTargetChainID(self, job_id):
     """ Set the Chain ID for the target. Derived from the input job name. """

     self.chainID = job_id

   def setTargetSeq_Res(self):
     """ Get the sequence string and the number of residues from the Fasta file. """

     sequence = ''

     handle = open(self.seqfile)
     line = handle.readline()
     
     # Catch for blank lines at the start of the file
     while string.strip(line)=="":
        line = handle.readline()

     #Trap for PIR format
     if ">P1" in line or ">p1" in line:
        line = handle.readline()
        line = handle.readline()

     #Trap for Fasta format
     elif ">" in line:
        line = handle.readline()

     while line:
        sequence += ((string.strip(line).replace(" ","")).replace("*","")).upper()
        line = handle.readline()
     handle.close()
     
     self.sequence = sequence
     self.no_of_res = len(sequence)
 
   def setTargetWeight(self):
     """ Work out the molecular weight of the protein from the residues it contains. """

     index = 0
     total = 0
     water_molecular_weight = 18.015

     for AA_id in self.AminoAcids:
       no_of_occurs = string.count(self.sequence, AA_id)
       weight_for_this = no_of_occurs * self.AminoAcidWeights[index]
       total = total + weight_for_this
       index = index + 1

     # Set the molecular weight
     self.mol_weight = total - ((self.no_of_res-1)*water_molecular_weight)

   def setTargetMTZinfo(self, mrsearchdir, mtz_coldata):
     """ Call the mtzdump wrapper to extract experiment details from the MTZ file. """

     mtz_dump=MTZ_info.Mtzdump()
     mtz_dump.setMTZdumpLogfile(os.path.join(mrsearchdir, "logs"))
     mtz_dump.setHklin(self.hklin)
     mtz_dump.go()
     time.sleep(2)

     self.resolution   = mtz_dump.getResolution()
     self.col_labels   = mtz_dump.getColumnData()
     self.symmetry_no  = mtz_dump.getSymmetryNumber()
     self.space_group  = mtz_dump.getSpacegroup()
  
     # Set the SG code for this spacegroup if an enant exists
     if self.SG_Codes.has_key(self.space_group):
        self.hklin_SG_code = self.SG_Codes[self.space_group]

     self.mtz_coldata["F"] = mtz_coldata["F"] 
     self.mtz_coldata["SIGF"] = mtz_coldata["SIGF"] 
     self.mtz_coldata["FREE"] = mtz_coldata["FREER_FLAG"] 
     
     sys.stdout.write("\n")

     # Test to see that the input column labels are actually in the MTZ file and exit if they are not present
     for label in self.mtz_coldata.values():
        if label not in self.col_labels:
           print "MTZ file info message: Error: Column label '%s' not found in MTZ file." % label
           print "The column labels found in the MTZ file are:"
           for name in self.col_labels:
              print name
           self.Error[0] = True
           Error_report = "MTZ column label error: column <b>'%s'</b> not found in MTZ<br>\n" % label
           Error_report += "Column labels found in MTZ:<br><br>\n"
           for name in self.col_labels:
              Error_report += "<b>" + name + "</b>, "
           self.Error[1]=Error_report.rstrip(", ")

     #mtz_dump.getColumnData(self.mtz_coldata) 

   def setTargetNum_mols(self, init):
     """ Work out the number of molecules in the ASU. """

     # Set the MW for all components in the structure
     # Get the estimated number of molecules
     nmolc=Nmol_calc.Nmol_calc()
     nmolc.calculate_nmol(self.mol_weight, self.hklin, self.seqfile, self.matt_coef_logfile)
     self.cell_dimensions=nmolc.cell_dimensions
     self.solvent=nmolc.solvent_estimate

     if init.keywords.FIXED == False: 
        self.no_of_mols=nmolc.nmol_estimate
     else:
        mc=Matthews_coef.MattCoef()
        mc.setCELL("%.3f %.3f %.3f %.3f %.3f %.3f" % (self.cell_dimensions["a"], self.cell_dimensions["b"],\
                                                     self.cell_dimensions["c"], self.cell_dimensions["alpha"],\
                                                     self.cell_dimensions["beta"], self.cell_dimensions["gamma"])) 
        mc.setSYMM("%s" % self.space_group)
        mc.setRESO(self.resolution)

        # Calculate the total molecular weight of the fixed components
        for i in init.keywords.fixed_list.keys():
           self.fixed_MW=self.fixed_MW + init.keywords.fixed_list[i].mol_weight

        if self.debug:
           sys.stdout.write("Total molecular weight for the fixed components = %.3f\n" % self.fixed_MW)
           sys.stdout.write("\n")

        # Set the log file for matthews_coef
        logfile=os.path.join(init.search_dir, "logs", "matt_coef_fixed.log")

        # Run matthews_coef for a target + fixed component to estimate the number of target molecules to search for
        mc.runMC_fixed(self.mol_weight, self.fixed_MW, logfile)
        self.no_of_mols=mc.best_nmol

        # Sanity check
        if mc.best_nmol == 0:
           sys.stdout.write("Matthews Coef Warning: There was an error calculating the optimum number of target\n" \
                            "                       components to search for in the a.s.u.\n"\
                            "                       Setting this value to a guess value of 1.\n") 
           sys.stdout.write("Check the log file for matthews_coef:\n  %s\n" % logfile)
           sys.stdout.write("\n")
           self.no_of_mols = 1

     # Work out the MW of the fixed components (if any)
     if init.keywords.FIXED:
 
        mw_fixed=0.0
        best_prob=0.0
        best_nmol=0

        # Work out the total molecular weight of the fixed components
        for i in init.keywords.fixed_list.keys():
           mw_fixed=mw_fixed+init.keywords.fixed_list[i].mol_weight

   def parseSeqfile(self, seq_file, job_id):
      """ Parse the sequence file into the correct format so that Molrep can read it properly."""

      # Open the sequence file and read it in to memory
      new_array=[]

      # Set the header for the fasta file
      header='> ' + job_id

      # Create a single string holding the entire sequence
      seq=self.sequence

      # Break up this string into blocks of 80 letters plus the remainder
      # and write it to a new array
      if len(seq) > 80:
         split=len(seq)/80
         remain=len(seq)%80
         for i in range(split):
            new_array.append(seq[i*80:(i+1)*80])
         new_array.append(seq[len(seq)-remain:len(seq)])
      else:
         new_array=seq

      new=string.join(new_array,'')

      if new!=seq:
        print 'Error in sequence parsing: New sequence differs from origional'
	print "New sequence: %s" % new
	print "Old sequence: %s" % seq
        sys.exit(1)

      # Write out the new sequence file

      o=open(seq_file,'w')

      o.write(header + '\n')
      for i in new_array:
         o.write(i + '\n')

      o.close()

   def prettySequence(self, break_pt):
      """ Prettify the sequence so that it can be displayed in logfiles. """
 
      count=0

      # Write the sequence with a carriage return every break point number of residues
      for i in self.sequence:
         self.pretty_sequence += i
         count=count+1
         if count%break_pt == 0:
            self.pretty_sequence += "\n"

      # Write a carriage return at the end if the number of residues is not a multiple of the break point
      if len(self.sequence)%break_pt == 0:
         self.pretty_sequence += "\n"
