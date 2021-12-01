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
# A class to hold the details of any solutions found in MR. Used by the Write_Best function.
# Ronan Keegan 13/10/08

import os, sys, string
import shutil
import smartie


class Soln_Model:
   """ A class structure to hold solution model details. """
   
   def __init__(self):
      self.model_source=''
      self.mrprogram=""
      self.soln_model_name=""
      self.PDBfile=""
      self.solution_type=""
