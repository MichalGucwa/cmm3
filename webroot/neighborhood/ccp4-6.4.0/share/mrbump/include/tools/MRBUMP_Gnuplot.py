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
# Gnuplot wrapper
# Ronan Keegan 18.8.05


import os, sys, string
import Scan_path

class Gnuplot:
   """ A wrapper class to Gnuplot. """

   def __init__(self):
      self.gnuplotEXE = 'gnuplot'
      self.plot_file  = ''
      self.png_file   = ''
      self.chk_dep=Scan_path.Check_PATH()

      self.col_x=''
      self.col_y=''

      self.title=''
      self.xlabel=''
      self.ylabel=''

      self.setline=''
      self.replotline=''

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def setDEBUG(self, flag):
      self.debug=flag 

   def setPlotFile(self, filename):
      self.plot_file = filename 
 
   def setColxVariable(self, column_number):
      self.col_x = column_number
 
   def setColyVariable(self, column_number):
      self.col_y = column_number
 
   def setPNGFile(self, filename):
      self.png_file = filename
 
   def setTitle(self, title):
      self.title = title 
 
   def setXLabel(self, label):
      self.xlabel = label 
 
   def setYLabel(self, label):
      self.ylabel = label 
 
   def setSetLine(self, line):
      self.setline = self.setline + '\n' + line 
 
   def setReplotLine(self, data_file, col_x, col_y):
      line = 'replot "' + data_file + '" u ' + `col_x` + ':' + `col_y`  
      self.replotline = self.replotline + '\n' + line 
   

   def gnuplot_png(self, data_file, col_x, col_y, title, output_png):
      """ A function to call gnuplot and plot the data in a png file. """

      if self.chk_dep.find_exec(self.gnuplotEXE)==False:
         print "No graphs in output HTML file"
         return

      pline = 'plot '
      for i in range(len(col_x)):
         if i < len(col_x) - 1: 
           pline = pline + '"' + data_file + '" u ' + `col_x[i]` + ':' + `col_y[i]` + ' ti "' + title[i]  + '", '  
         else:
           pline = pline + '"' + data_file + '" u ' + `col_x[i]` + ':' + `col_y[i]` + ' ti "' + title[i] + '"' 
         

      # Set up some vaiables including the name of the output file
      self.setColxVariable(col_x)
      self.setColyVariable(col_y)
      self.setPNGFile(output_png)

      # Open the plotter file to be passed to Gnuplot
      plt_file = open(self.plot_file, "w")
 
      # Construct the plotter file

      plt_file.write('set term png\n')
      plt_file.write('set data style linespoints\n')
      plt_file.write(self.setline + '\n')
      plt_file.write('set output "' + self.png_file + '"\n') 
      plt_file.write('set title "' + self.title + '"\n')
      plt_file.write('set xlabel "' + self.xlabel + '"\n')
      plt_file.write('set ylabel "' + self.ylabel + '"\n')
      plt_file.write(pline + '\n') 
      plt_file.write('exit\n') 

      plt_file.close()
      
      # Pass the plotter file to Gnuplot
      job = os.popen(self.gnuplotEXE + " " + self.plot_file, "r")
  
      job.close()
     
      #os.remove(self.plot_file)
        
if __name__ == '__main__':
 
   g=Gnuplot()

   g.setTitle("Test Title")
   g.setXLabel("x-label")
   g.setYLabel("y-label")
   g.setReplotLine("test.dat", 1, 3)

   g.gnuplot_png("test.dat", [1,1], [2,3], ["arse", "feck"], "out.png")
