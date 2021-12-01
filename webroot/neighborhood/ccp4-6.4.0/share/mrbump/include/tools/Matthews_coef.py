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
# A script to run Matthews_coef 
# Ronan Keegan 30/07/07

import os, string, sys


class MattCoef:
   """ A class to run Matthews_coef. """
 
   def __init__(self):

      self.matt_EXE=os.path.join(os.environ["CCP4"], "bin", "matthews_coef")
      self.key=""

      self.best_prob=0.0
      self.best_nmol=0

      self.debug=False

      self.CELL=""
      self.SYMM=""
      self.RESO=0.0

   def setCELL(self, cell_dimensions):
      self.CELL = cell_dimensions

   def setSYMM(self, symm):
      self.SYMM = symm

   def setRESO(self, resolution):
      self.RESO = resolution

   def runMC_fixed(self, target_MW, fixed_MW, logfile):
      """ Run Matthews_coef when mol weight includes a fixed component. 
          This looks at the probabilities while increasing the number of
          target components in the molecular weight. When a max is reached
          this value is taken as the number of target moleules in the a.s.u."""

      # Iterate, increasing the mw due to the target component until the best probability
      # is found
      for i in range(20):
         j=i+1
        
         # Calculate the new molecular weight
         mol_weight=(target_MW*j) + fixed_MW
      
         # Set the keywords
         self.key ="CELL %s\n" % self.CELL
         self.key+="SYMM %s\n" % self.SYMM
         self.key+="RESO %.3f\n" % self.RESO
         self.key+="MOLW %.3f\n" % mol_weight
         self.key+="AUTO\n"
         self.key+="END\n"
       
         # run Matthes_coef
         I,O=os.popen2(self.matt_EXE)
      
         I.write(self.key)
         I.close()
       
         if os.path.isfile(logfile):
            log=open(logfile, "a")
         else:
            log=open(logfile, "w")
      
         log.write("\n")
         log.write("##############################################################\n")
         log.write("#####       Results for %d copies of target comp:        #####\n" % j)
         log.write("##############################################################\n")
         log.write("\n")

         line=O.readline()
         while line:
            if self.debug:
               sys.stdout.write(line)
      
            if "____________________" in line:
               log.write(line)
               res_line=O.readline()
               if "  1 " in res_line[0:4]: 
                  try:
                     prob=float(string.split(res_line)[-1])
                  except:
                     prob=0.0
                  if prob > self.best_prob:
                     self.best_prob=prob
                     self.best_nmol=j
               else:
                  prob=0.0
               log.write(res_line)
            else:
               log.write(line)
            
            line=O.readline()
         
         log.close()
         O.close()
    
if __name__ == "__main__":

   mc=MattCoef()

   # The 1l2w example (8 * protein "A" + 4 * protein "B")
   mc.setCELL("72.8400   73.3500   74.2600  103.4000  109.2000  107.4000")
   mc.setSYMM("P1")
   mc.setRESO(1.962)

   mc.runMC_fixed(13600, 6130*4, "matt_coef.log")

   print mc.best_nmol, mc.best_prob
