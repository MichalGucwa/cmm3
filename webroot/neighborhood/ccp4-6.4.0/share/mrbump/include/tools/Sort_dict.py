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
# Sort dictionary function
# Ronan Keegan 10.8.05

class Sort_dict:
   ''' A class to sort the the contents of dictionary according to the values. '''

   def __init__(self):
      self.name = ''
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def sort(self, in_dict, ORDER="LOWEST"):
      ''' A function to sort the dictionary and return it in asscending or descending order. '''

      # Sort the score list, highest first.
      items=[(v,k) for k,v in in_dict.items()]
      items.sort()
      if ORDER == 'HIGHEST':
         items.reverse()
      items = [(k,v) for v,k in items]

      return items

if __name__ == '__main__':

   score_list=dict([])

   score_list['a'] = 1
   score_list['b'] = 3
   score_list['c'] = 2

   s=Sort_dict()
   sorted_list=s.sort(score_list, 'HIGHEST')

   print sorted_list

