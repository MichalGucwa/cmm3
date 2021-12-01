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
#
#This file contains any develop functions for testing purposes
#Ronan Keegan 20/04/05

import os, string, sys


class Developer:
   ''' Development code for testing purposes. '''

   def __init__(self):
      self.name=''
      self.ignore_list=[]

   def ignore_PDBcodes(self, mstat, ignore_file):
      
      file=open(ignore_file,'r')
      line=file.readline()
      while line:
         mstat.ignore_list.append(string.strip(line))      
         line=file.readline()

