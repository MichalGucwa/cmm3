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
# A script to read the command line arguments for mrbump
# 15/1/09 Ronan Keegan

import string, sys, os
import shutil


class Seqin:
   """ A class to hold details specific to an input sequence. """

   def __init__(self):
      self.args=""
      self.filename=""
      self.file=""
      self.ratio=1
      self.seqID=0

class CommandLine:
   """ A class to hold functions and variables related to the command line input to MrBUMP. """

   def __init__(self):
      self.cmd_line=""
      self.cmd_list=[]
      self.len_cmds=0
      self.arguments=["HKLIN", "SEQIN", "HKLOUT", "XYZOUT", "PREPDIR"]

      self.HKLIN=""
      self.HKLOUT=""
      self.XYZOUT=""
      self.PREPDIR=""
      self.SEQIN=dict([])
      
   def printInputs(self):
      """ Output the values of each of the input variables. """

      # Print the HKLIN details
      if self.HKLIN != "":
         print "HKLIN: %s" % self.HKLIN
      else:
         print "HKLIN is not set"

      # Print the HKLOUT details
      if self.HKLOUT != "":
         print "HKLOUT: %s" % self.HKLOUT
      else:
         print "HKLOUT is not set"

      # Print the XYZOUT details
      if self.XYZOUT != "":
         print "XYZOUT: %s" % self.XYZOUT
      else:
         print "XYZOUT is not set"

      # Print the PREPDIR details
      if self.PREPDIR != "":
         print "PREPDIR: %s" % self.PREPDIR
      else:
         print "PREPDIR is not set"

      # Print the SEQIN details
      for i in self.SEQIN.keys():
         print "%s -> args: %s" %(i, self.SEQIN[i].args)
         print "   -> seqID: %d" % self.SEQIN[i].seqID
         print "   -> filename: %s" % self.SEQIN[i].filename
         print "   -> ratio: %d" % self.SEQIN[i].ratio

   def parse(self, cmd_line):
      """ Parse the command line arguments. The cmd_line should be all arguments to the program name and does not
          include the program name (e.g. mrbump). """

      self.cmd_line=cmd_line
      self.cmd_list=string.split(self.cmd_line)
      self.len_cmds=len(self.cmd_list)
      error=False

      # Grab the HKLIN value
      catch=False
      hklin_string=""
      for i in self.cmd_list:
         if catch==True:
            if i in self.arguments:
               catch=False
            else:
               hklin_string+=i + " "
         if i.upper()=="HKLIN":
            catch=True
            hklin_string="HKLIN "
      if hklin_string!="":
         self.HKLIN=string.strip(hklin_string.replace("HKLIN",""))

         # Check to see that the HKLIN file actually exists
         if os.path.isfile(self.HKLIN) == False:
            sys.stdout.write("Command line error: File '%s' specified for keyword HKLIN could not be found\n" % self.HKLIN)
            sys.stdout.write("\n")
            error=True

      # Grab the HKLOUT value
      catch=False
      hklout_string=""
      for i in self.cmd_list:
         if catch==True:
            if i in self.arguments:
               catch=False
            else:
               hklout_string+=i + " "
         if i.upper()=="HKLOUT":
            catch=True
            hklout_string="HKLOUT "
      if hklout_string!="":
         self.HKLOUT=string.strip(hklout_string.replace("HKLOUT",""))

      # Grab the XYZOUT value
      catch=False
      xyzout_string=""
      for i in self.cmd_list:
         if catch==True:
            if i in self.arguments:
               catch=False
            else:
               xyzout_string+=i + " "
         if i.upper()=="XYZOUT":
            catch=True
            xyzout_string="XYZOUT "
      if xyzout_string!="":
         self.XYZOUT=string.strip(xyzout_string.replace("XYZOUT",""))

      # Grab the PREPDIR value
      catch=False
      prepdir_string=""
      for i in self.cmd_list:
         if catch==True:
            if i in self.arguments:
               catch=False
            else:
               prepdir_string+=i + " "
         if i.upper()=="PREPDIR":
            catch=True
            prepdir_string="PREPDIR "
      if prepdir_string!="":
         self.PREPDIR=string.strip(prepdir_string.replace("PREPDIR",""))

         # Check to see that the PREPDIR directory actually exists
         if os.path.isdir(self.HKLIN) == False:
            sys.stdout.write("Command line error: File '%s' specified for keyword PREPDIR could not be found\n" % self.PREPDIR)
            sys.stdout.write("\n")
            error=True

      # Grab the SEQIN values
      catch=False
      seqin_string=""
      seqID_list=[]
      for i in self.cmd_list:
         # If we are catching the arguments to a SEQIN keyword check to see if we have
         # a new keyword or the arguments to the current SEQIN
         if catch==True:
            if (i.upper() in self.arguments) or (i.upper()[0:5] in self.arguments):
               catch=False
               if seqin_string != "":
                  self.SEQIN[seq].args=seqin_string
            else:
               seqin_string+=i + " "
         # If SEQIN is found in the list of arguments then set catch to true and check 
         # that it is a valid keyword
         if "SEQIN" in i.upper()[0:5]:
            catch=True
            seq=i.upper()
            seqin_string=""
            if i.upper() == "SEQIN":
               seqID=0
            else:
               try:
                  seqID=int(i.upper()[5:])
               except:
                  sys.stdout.write("Command line error: %s is not a valid keyword\n" % seq)
                  sys.stdout.write("\n")
                  sys.exit()
            if seqID in seqID_list:
               sys.stdout.write("Command line error: Keyword %s has been used more than once\n" % seq)
               sys.stdout.write("\n")
               sys.exit()
            else:
               seqID_list.append(seqID)
               s=Seqin()
               self.SEQIN[seq]=s
               self.SEQIN[seq].args=""
               self.SEQIN[seq].seqID=seqID
            
      # If SEQIN occurs at the end of the command list catch its argument(s)
      if catch == True:
         self.SEQIN[seq].args=self.SEQIN[seq].args + seqin_string 

      # Sort out what's what in the SEQIN argument(s)
      for i in self.SEQIN.keys():
         if len(string.split(self.SEQIN[i].args)) == 2:
            self.SEQIN[i].filename=string.split(self.SEQIN[i].args)[0]
            self.SEQIN[i].file=os.path.split(self.SEQIN[i].filename)[-1]
            try:
               self.SEQIN[i].ratio=int(string.split(self.SEQIN[i].args)[1])
            except:
               sys.stdout.write("Command line error: Value '%s' given to keyword %s is invalid - should be a positive integer" \
                                  % (string.split(self.SEQIN[i].args)[1], i))
               sys.stdout.write("\n")
               error=True
         elif len(string.split(self.SEQIN[i].args)) == 1:
            self.SEQIN[i].filename=string.split(self.SEQIN[i].args)[0]
            self.SEQIN[i].file=os.path.split(self.SEQIN[i].filename)[-1]
         else:
            sys.stdout.write("Command line error: Incorrect number of arguments given to keyword %s\n" % i)
            sys.stdout.write("\n")
            error=True

         # Some error checking
         if os.path.isfile(self.SEQIN[i].filename) == False:
            sys.stdout.write("Command line error: File '%s' specified for keyword %s could not be found\n" % (self.SEQIN[i].filename, i))
            sys.stdout.write("\n")
            error=True

      # If an error was found then exit
      if error==True:
         sys.exit()
 

if __name__ == "__main__":
 
   c=CommandLine()
   c.parse("HKLIN test.mtz SEQIN test1.seq 1 SEQIN1 arse2.fec 3 SEQIN2 test3.seq 3 SEQIN3 test4.seq 1 HKLOUT testout.mtz XYZOUT testout.pdb")
   #c.parse("SEQIN test4.seq 3")
   print c.cmd_line
   c.printInputs()
