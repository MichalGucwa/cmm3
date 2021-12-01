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
# Read in various environment variables for MRBUMP
# Ronan Keegan 14.10.05

import os, sys, string

class Environment:
   """ A class to handle all aspects of the environment setup in MRBUMP. """
  
   def __init__(self):
      self.USER=''
      self.USERHOME=''
      self.SETUP_DIR=''
 
   def read_environment(self):
      """ A function to read the environment settings for MRBUMP. """
    
      if os.name == 'nt':
         self.USER = os.environ['USERNAME']
         self.USERHOME = os.environ['USERPROFILE']
         self.SETUP_DIR=os.path.join(self.USERHOME, 'ccp4_mrbump')
      else:
         self.USER=os.environ['USER']
         self.USERHOME=os.environ['HOME']
         self.SETUP_DIR=os.path.join(self.USERHOME, '.ccp4_mrbump')


