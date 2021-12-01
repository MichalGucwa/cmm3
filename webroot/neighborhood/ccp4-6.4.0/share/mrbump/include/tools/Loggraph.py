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
# Script to generate output in loggraph format
# Ronan Keegan 19/12/05

import os


class Loggraph:
   """ A class to handle the creating of output from MRBUMP in loggraph mark-up. 
       Written in general enough form to be used from anywhere."""

   def __init__(self):
      self.header=''
      self.footer=''

      self.table=''
      self.graphs  = ' $GRAPHS'
      self.labels=''

      self.no_of_cols=0
      self.no_of_graphs=0

   def setNoofCols(self, number): 
      self.no_of_cols = number

   def setHeader(self, header):
      self.header = header
  
   def setFooter(self, footer): 
      self.footer = footer

   def setTable(self, tablename): 
      self.table  = ' $TABLE: '
      self.table += tablename 

   def addGraphs(self, graphname, *columns): 
      """ Add another plot to the Graph. """

      if self.no_of_graphs >= 1:
         self.graphs += '\n        '
      self.graphs += ': ' + graphname + ' :N:'
      for i in columns:
         self.graphs += `i` + ','
      self.graphs = self.graphs[0:-1] + ':'
      self.no_of_graphs = self.no_of_graphs + 1

   def setLabels(self, *labels):
      """ Set the column labels. """
              
      count=0

      self.labels = ' $$\n '
      for i in labels:
         if count == len(labels) - 1:
            self.labels += i + ' $$'
         else:
            self.labels += i + '    '
         count = count + 1
      self.labels += '\n $$'

   def write_log(self, array):
      """ Write the output for Loggraph to interpret. 
          Requires a 2-D array of data."""
 
      # Construct the header
      h_line  = '<applet width=" 400" height=" 300" code="JLogGraph.class"\n'
      h_line += 'codebase="' + os.environ["CCP4"] + '/bin' + '"><param name="table" value="'

      # Construct the footer
      f_line  = ' $$\n'
      f_line += '"><b>For inline graphs use a Java browser</b></applet>'

      self.setHeader(h_line)
      self.setFooter(f_line)
 
      # Start outputing the code
      print ""
      print self.header
      print self.table
      print self.graphs
      print self.labels
   
      # Output the data columns 
      for i in range(len(array[0])):
         line = ''
         for j in range(len(array)):
            if type(array[j][i]) == float:
               line += '\t%.3f' % array[j][i] 
            else:
               line += '\t' + `array[j][i]`
         print line
         
 
      # Print the footer
      print self.footer
      print ""

#      Example output:
#
#      $TABLE: Search model sequence alignment scores against target sequence:
#      $GRAPHS: Alignment Score :N:1,2:
#             : Sequence Identity :N:1,3:
#       $$
#       model   Score  fractional-identity $$
#       $$
#      for i in mstat.sorted_list: 
#         print "\t %d \t %.3f \t %.3f" % \
#            (model_count, i[1], mstat.chain_list[i[0]].alignment.seqID)
#       $$
#      "><b>For inline graphs use a Java browser</b></applet>


if __name__=='__main__':
   
   l=Loggraph()
   l.setTable('Test name')
   l.addGraphs('graph1', 1, 2)
   l.addGraphs('graph2', 1, 3)
   l.setLabels('label1', 'label2', 'label3')
   a=(1,2,3,4)
   b=(2.0,3.0,6.0,2.0)
   c=(4.1,2.2,8.3,4.7)
   array=(a,b,c)
   l.write_log(array)

   


 


