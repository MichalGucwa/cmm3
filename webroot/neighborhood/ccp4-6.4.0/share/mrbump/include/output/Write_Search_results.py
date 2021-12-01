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
# Script to write the results HTML for bulkMR
# Ronan Keegan 24.8.05

import os, string, sys
import os.path
import time
import shutil

import MRBUMP_Gnuplot
import Model_prep_scoring


class Write_html:
   """ A class to write output html as the bulkMR job progresses. """

   def __init__(self):
      self.page=''
      self.seq_array=[]
      self.elem_size=60
      self.no_elems=''

      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False
 
   def write_header(self, init, results_html):
      """ A function to write the header for the results html page. """

      # Begin the html page
      line =  '<html>\n'
 
      # Set the title for the page 
      line += '<head>\n'  
      line += '<title>BulkMR Results</title>\n'  
      line += '</head>\n'   

      # Set the background colour
      line += '<body bgcolor ="#ffffcc">\n'  

      # Add the logos
      line += '<table border=0 width="100%" cellspacing=5>\n'  
      line += '<tr>\n'  
      line += '<td><img src="' + init.relative_link + 'images/ccp4.gif" align=left/></td>\n' 
      line += '<td align="left"><img src="' + init.relative_link + 'images/cclrc-logo.jpg"></td>\n'  
      line += '</tr>\n'  
      line += ' </table>\n'  
 
      # Add a title bar and link to the e-HTPX homepage
      line += '<table border=0 width="100%" bgcolor="#d9b67f">\n' 
      line += '<tr><td> <a href="http://clyde.dl.ac.uk/e-htpx/index.htm">eHTPX Home</a></td></tr>\n' 
      line += '</table>\n' 
     
      # Open the main body of the page 
      line += '<body>\n' 
      
      res_html = open(results_html, "w")
      res_html.write(line)
      res_html.close()

 
   def write_footer(self, init, mstat, results_html):
      """ A function to write the footer for the results html page."""

      # Refresh the page every 10 seconds
      if mstat.job_end == False:
         if init.keywords.results_html == '':
            line = '<META HTTP-EQUIV="Refresh" CONTENT="10;URL=./results.html"/>\n'
         else:
            line = '<META HTTP-EQUIV="Refresh" CONTENT="10;URL=' + init.results_html + '"/>\n'
         line += '<br>\n'
         line += '<center>\n'
         line += '<img src="' + init.relative_link + 'images/slide_bar.gif" align="centre"><br>\n' 
         line += '<img src="' + init.relative_link + 'images/slide_bar.gif" align="centre"><br>\n' 
         line += '<img src="' + init.relative_link + 'images/slide_bar.gif" align="centre">\n' 
         line += '</center>\n'
      else:
         line =  '<br>\n'
         line += '<center>\n'
         line += '<i>Job completed: ' + time.ctime() + '. Time taken: %.3f seconds.</i>\n' % mstat.job_time
         line += '</center>\n'
         line += '<br>\n'

      # Add the footer bar
      line += '<br>\n'
      line += '<table border=0 width="100%" height=5 bgcolor="#ffffcc">\n' 
      line += '<tr><td></td></tr>\n' 
      line += '</table>\n'

      # put in the time when the results were generated
      line += '<table border=0 width="100%" bgcolor="#d9b67f">\n'
      line += '<tr><td><font color=green> Results generated: ' + time.ctime() + '</font></td></tr>\n' 
      line += '</table>\n' 
                
      # Close the page
      line += '</body><br>\n' 
      line += '</html>\n'

      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      mstat.len_html_footer = len(line)

   def remove_footer(self, mstat, results_html):
      """ A function to strip the footer from the results.html file so as to add extra search details. 
          Only to be used when one is about to update the results.html. """

      # Get the size of the results.html
      file_size = os.path.getsize(results_html)
      
      # We will truncate the file to exclude the footer
      truncate_size = file_size - mstat.len_html_footer
 
      # Get the file contents minus the footer
      res_html = open(results_html, "r")
      old_file = res_html.read()[0:truncate_size]
      res_html.close()

      # Re-write the file witout the footer
      res_html = open(results_html, "w")
      res_html.write(old_file)
      res_html.close()
       
   def write_target_details(self, init, mstat, target_info, results_html):
      """ A function to write the target details in the results html page. """

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      # Write the title
      line =  '<p align="center">\n'
      line += '<font size="6" face="BernhardFashion BT"><b> BulkMR results for target structure: ' \
             + target_info.chainID + '</b></font>\n'
      line += '</p>\n' 

      if mstat.InitError[0] == False:
         # Add the target details to the results.html
         line += '<b>Target Information</b><br><br>\n'
         line += '<i>Target chain ID</i>: ' + target_info.chainID + '<br>\n'
         line += '<i>Target sequence</i>: <br><br>\n'

         self.split_seq(target_info)

         line += '<font size=4><tt>\n'
         for i in range(self.no_elems):
            line += self.seq_array[i] + '<br>\n'
         line += '</tt></font>\n'

         line += '<br>\n'
         line += '<i>Sequence file</i>: <b>' + target_info.seqfilename + '</b><br>\n'
         line += '<i>Reflections file</i>: <b>' + target_info.hklin_filename + '</b><br>\n'
         line += '<i>Resolution of collected data</i>: %.3f <br>\n' % target_info.resolution
         line += '<i>Number of Residues</i>: ' + `target_info.no_of_res` + '<br>\n'
         line += '<i>Molecular Weight</i>: %.3f <br>\n\n' % target_info.mol_weight
         if init.keywords.NMASU == None:
            line += '<i>Estimated number of molecules in the a.s.u.</i>: ' + `target_info.no_of_mols` + '<br>\n'
         else:
            line += '<i>User defined number of molecules in the a.s.u.</i>: ' + `target_info.no_of_mols` + '<br>\n'
            line += '<i>Estimated number of molecules in the a.s.u.</i>: ' + `mstat.est_no_of_mols` + '<br>\n'
         line += '<br>\n'

         line += '<i>Number of generated models to be used in MR</i>: ' + `mstat.MRNUM` + '<br>\n'
         line += '<i>Number of generated models to be used in each Ensemble</i>: ' + `mstat.ENSMODNUM` + '<br>\n'
         line += '<i>Molecular Replacement program to be used</i>: ' + mstat.MRPROGRAM + '<br>\n'
         if init.keywords.PACK == None:
            line += '<i>Number of clashes to be tolerated in Phaser</i>: %d <br>\n' % int(init.keywords.PACK) 
         else:
            line += '<i>Number of clashes to be tolerated in Phaser</i>: %d <br>\n' % (int(init.keywords.PACK)*int(init.keywords.NMASU)) 

      else:
         # Report an error otherwise
         line += '<b>Error in input data</b><br><br>\n'
         line += '<i>Error report</i>: ' + mstat.InitError[1] + '<br>\n'
         mstat.setJob_End(True)

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_SEQ_search_details(self, init, mstat, results_html):
      """ A function to write the search results from the SEQ search in the results html page. """

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b><font size=6 color=red>Template Search</font></b><br><br>\n'
      line += '<b>Sequence-based Search Results (SEQ):</b><br><br>\n'

      if mstat.ignore_list != []:
         codes_line=string.join(mstat.ignore_list,', ')
         line += '<i>PDB id codes ignored in search</i>: ' + codes_line + '<br>\n'

      if mstat.include_list != []:
         codes_line=string.join(mstat.include_list,', ')
         line += '<i>Chain id codes included in search</i>: ' + codes_line + '<br>\n'

      if mstat.no_of_SEQhits != 0:
         line += '<i>Number of hits from sequence-based search</i>: ' + `mstat.no_of_SEQhits` + '<br>\n'
         line += '<i>E value used in sequence-based (SEQ) search</i>: %.2e <br>\n' % mstat.E_value
         line += '<i>To view SEQ results file click <a href="' + init.relative_link + 'data/' \
            + string.split(mstat.SEQmatchfile,'/')[-1] + '" target="_blank">here</a></i> <br>\n'
      else:
         line += '<i>No suitable homologues found in the sequence-based search</i><br>\n'
         line += '<i>Try a higher e value</i><br>\n'
         line += '<i>To view SEQ results file click <a href="' + init.relative_link + 'data/' \
            + string.split(mstat.SEQmatchfile,'/')[-1] + '" target="_blank">here</a></i> <br>\n'
         mstat.setJob_End(True)

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_SSM_search_details(self, init, mstat, results_html):
      """ A function to write the search results from the SSM search in the results html page. """

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b>Structure-based Search Results (SSM):</b><br><br>\n'
      line += '<i>Number of new hits from SSM search</i>: ' + `mstat.no_of_SSMhits` + '<br>\n'
      line += '<i>To view SSM results file (XML) click <a href="' + init.relative_link + 'data/ssm_result.xml" target="_blank">here</a></i> <br>\n'

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_ALL_search_details(self, init, mstat, target_info, results_html):
      """ A function to write a summary of all the search results in the results html page. """

      # Write the scores file for gnuplot 
      self.print_scores_file(mstat)

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b>Overall Search Results:</b><br><br>\n'
      line += '<i>Top match from search</i>: ' + mstat.top_match_chainid + '<br>\n'
      line += '<i>Top match percentage sequence identity</i>: %.3f <br>\n' % (mstat.chain_list[mstat.top_match_chainid].seqID*100.0)
      line += '<i>To view the multiple alignment results click <a href="' + init.relative_link + 'data/sequences/' \
          + target_info.chainID + '_all_align.fasta" target="_blank">here</a></i> <br>\n'

      # Plot the sequence alignment  scores
      self.plot_scores(target_info, init, mstat, 'AlignScore')

      line += '<br>\n'
      line += '<b>Alignment Score:</b><br>\n'
      line += '<br>\n'
      line += '<table border=1> \n <tr> \n<td>\n'
      line += '<img border=1 src="' + init.relative_link + 'images/align_scores.png">\n'
      line += '</td>\n'

      self.make_logfiles(mstat, 'AlignScore')
      score_table = self.compose_table(init, mstat, 'AlignScore')

      line += '<td>\n'
      line += score_table
      line += '</td> \n'
      line += '</table>\n'

      # Plot the sequence identity scores
      self.plot_scores(target_info, init, mstat, 'seqID')

      line += '<br>\n'
      line += '<b>Sequence Identity scores:</b><br>\n'
      line += '<br>\n'
      line += '<table border=1> \n <tr> \n<td>\n'
      line += '<img border=1 src="' + init.relative_link + 'images/p_id.png">\n'
      line += '</td>\n'

      self.make_logfiles(mstat, 'seqID')
      score_table = self.compose_table(init, mstat, 'seqID')

      line += '<td>\n'
      line += score_table
      line += '</td> \n'
      line += '</table>\n'

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_domains_search_details(self, init, mstat, results_html):
      """ A function to write a summary of the domain search results in the results html page. """

      # Write the SCOP results file  
      self.make_SCOP_results_file(mstat)

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b>Domains Search Results (SCOP):</b><br><br>\n'
      line += '<i>Total number of domains found</i>: ' + `mstat.no_of_SCOPhits` + '<br>\n'
      line += '<i>To view the SCOP results file click <a href="' + init.relative_link + './data/scop_results.txt" target="_blank">here</a></i> <br>\n'

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_model_prep_details(self, init, mstat, target_info, results_html):
      """ A function to write the model preparation details into the results html page. """

      # Get the scores for the Model preparation step
      prep_scores=Model_prep_scoring.Model_Prep_Scores()

      if init.keywords.MDLMOLREP:
         prep_scores.molrep_score(init, mstat)
      if init.keywords.MDLCHAINSAW:
         prep_scores.chainsaw_score(init, mstat,'multiple')

      # Re-write the scores file for gnuplot with Molrep and Chainsaw scores included
      self.print_scores_file(mstat)

      # Output to the HTML results file if required
      if init.keywords.HTMLOUT:
         # Remove the footer from the resuls page
         self.remove_footer(mstat, results_html) 
   
         line =  '<br>\n'
         line += '<b><font size=6 color=red>Model Preparation</font></b><br><br>\n'
         line += '<i>Number of Modelling jobs spwaned</i>: <b>' + `mstat.model_counter` + '</b><br>\n'
   
         # Molrep pruning scores
         if init.keywords.MDLMOLREP:
            self.plot_scores(target_info, init, mstat, 'Molrep_Score')
   
            line += '<br>\n'
            line += '<b>Molrep scores:</b><br>\n'
            line += "<i>These are the results for correcting each of the model structures to match the target sequence using Molrep</i><br>\n"
            line += '<br>\n'
            line += '<table border=1> \n <tr> \n<td>\n'
            line += '<img border=1 src="' + init.relative_link + 'images/molrep_scores.png">\n'
            line += '</td>\n'
      
            score_table = self.compose_table(init, mstat, 'Molrep')
      
            line += '<td>\n'
            line += score_table
            line += '</td> \n'
            line += '</table>\n'
   
         # Chainsaw Score
         if init.keywords.MDLCHAINSAW:
            self.plot_scores(target_info, init, mstat, 'Chainsaw_Score')
      
            line += '<br>\n'
            line += '<b>Chainsaw scores:</b><br>\n'
            line += "<i>These are the results for manipulating the model structures using Chainsaw. \
               The graph shows the % of the model structure conserved by Chainsaw.</i><br>\n"
            line += '<br>\n'
            line += '<table border=1> \n <tr> \n<td>\n'
            line += '<img border=1 src="' + init.relative_link + 'images/chainsaw_scores.png">\n'
            line += '</td>\n'
      
            score_table = self.compose_table(init, mstat, 'Chainsaw')
      
            line += '<td>\n'
            line += score_table
            line += '</td> \n'
            line += '</table>\n'
            line += '<br>\n'
   
         # Append the details onto the results.html file
         res_html = open(results_html, "a")
         res_html.write(line)
         res_html.close()
   
         # Add the footer to the results page
         self.write_footer(init, mstat, results_html)

   def write_PQS_search_details(self, init, mstat, target_info, results_html):
      """ A function to write the PQS search results the results html page. """

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b>Protein Quaternary Structure Search (PQS):</b><br><br>\n'
      line += '<i>Estimated number of molecules in the a.s.u.</i>: ' + `target_info.no_of_mols` + '<br>\n'
      line += '<i>Number of hits in PQS search</i>: ' + `mstat.no_of_PQShits` + '<br>\n'

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def write_ensemble_details(self, init, mstat, target_info, results_html):
      """ A function to write the PQS search results the results html page. """

      # Remove the footer from the resuls page
      self.remove_footer(mstat, results_html) 

      line =  '<br>\n'
      line += '<b>Preparation of an ensemble for Phaser:</b><br><br>\n'
      line += '<i>Number of template models in each Ensemble</i>: ' + `mstat.ENSMODNUM` + '<br>\n'

      # Append the details onto the results.html file
      res_html = open(results_html, "a")
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      self.write_footer(init, mstat, results_html)

   def split_seq(self, target_info):
      """ A function to parse the sequence for display on the results page. """

      seq=target_info.sequence
      if len(seq) > self.elem_size:
         remainder=len(seq)%self.elem_size
         self.no_elems=len(seq)/self.elem_size + 1
         for i in range(self.no_elems - 1):
            self.seq_array.append(seq[i*self.elem_size:(i+1)*self.elem_size])
         self.seq_array.append(seq[len(seq)-remainder:len(seq)])
      else:
         self.no_elems=1
         self.seq_array.append(seq)

   def plot_scores(self, target_info, init, mstat, plot_type):
      """ Plot the sequence identity for matching chains """

      gp=MRBUMP_Gnuplot.Gnuplot()
      gp.setPlotFile(init.search_dir + "/logs/temp.plt")
      gp.setSetLine("set xrange [1:*]")

      # Plot sequence identity
      if plot_type == 'seqID':
         gp.setTitle('Sequence identity scores for target: ' + target_info.chainID) # (optional)
         gp.setXLabel('models')
         gp.setYLabel('% identity')
         gp.gnuplot_png(mstat.scores_file, [1], [4], ["seqID"], mstat.results_dir + '/images/p_id.png')

      # Plot Alignment Score
      if plot_type == 'AlignScore':
         gp.setTitle('Alignment scores for matches to target: ' + target_info.chainID) # (optional)
         gp.setXLabel('models')
         gp.setYLabel('Alignment score')
         gp.gnuplot_png(mstat.scores_file, [1], [3], ["score"], mstat.results_dir + '/images/align_scores.png')

      # Plot Alignment Length Quality
      if plot_type == 'AlignLenScore':
         gp.setTitle('Alignment score for matches to target: ' + target_info.chainID) # (optional)
         gp.setXLabel('models')
         gp.setYLabel('align score')
         gp.gnuplot_png(mstat.scores_file, [1], [5], ["score"], mstat.results_dir + '/images/align_len_score.png')

      # Plot Molrep Score
      if plot_type == 'Molrep_Score':
         gp.setTitle('Molrep scores for matches to target: ' + target_info.chainID) # (optional)
         gp.setXLabel('models')
         gp.setYLabel('Molrep Score')
         gp.gnuplot_png(mstat.scores_file, [1], [6], ["score"],  mstat.results_dir + '/images/molrep_scores.png')

      # Plot Chainsaw Scores
      if plot_type == 'Chainsaw_Score':
         gp.setTitle('Chainsaw scores for matches to target: ' + target_info.chainID) # (optional)
         gp.setXLabel('models')
         gp.setYLabel('% of structure conserved by Chainsaw')
         gp.gnuplot_png(mstat.scores_file, [1], [7], ["score (multiple alignment)"], mstat.results_dir \
             + '/images/chainsaw_scores.png')

   def make_logfiles(self, mstat, plot_name):
      """ A function to make up a logfiles for the alignments of each of the sequences. """

      # Keep a count of the order of each template model
      count=0
      max_count=17

      # Copy the individual alignment files and add in the alignment details to the file
      for chain in mstat.chain_list.keys():
         shutil.copy(mstat.chain_list[chain].alignment.out_fasta_file, mstat.results_dir + '/data/sequences/')

         line =  "\n"
         line += "Alignment score:                 %.3f" % mstat.chain_list[chain].alignment.score + "\n"
         line += "Sequence identity:               %.3f" % mstat.chain_list[chain].alignment.seqID + "\n"
         line += "Alignment length:                %d" % mstat.chain_list[chain].alignment.align_len + "\n"
         line += "Alignment quality:               %.3f" % mstat.chain_list[chain].alignment.align_len_score + "\n"
         line += "Number of gaps:                  %d" % mstat.chain_list[chain].alignment.no_of_gaps + "\n"
         line += "Number of gap characters:        %d" % mstat.chain_list[chain].alignment.no_of_gap_chars + "\n"
         line += "Gap penalty:                     %.3f" % mstat.chain_list[chain].alignment.gap_penalty + "\n"
         line += "Number of conserved residues:    %d" % mstat.chain_list[chain].alignment.no_conserved + "\n"

         file = open(mstat.results_dir + '/data/sequences/' + chain + '_aln.fasta','a')
         file.write(line)
         file.close()

   def compose_table(self, init, mstat, plot_name):
      """ A function to make up a table of results for each plot. """

      # Keep a count of the order of each template model
      count=0
      max_count=17

      # Set upt the headings for the table of results
      table =  '<table border=1>\n'
      table += '<tr>\n'
      if plot_name == 'Chainsaw':
         table += '<td colspan=3><i>Scores (sorted by alignment score)</i></td>\n'
         table += '<td colspan=1><i>Log file (ma)</i></td>\n'
      else:
         table += '<td colspan=3><i>Top Scores (sorted by alignment score)</i></td>\n'
         table += '<td colspan=1><i>Source</i></td>\n'
         table += '<td colspan=1><i>Log file</i></td>\n'
      table += '</tr>\n'

      # Populate the scores and logfile tables for each template model
      for chain in mstat.sorted_MR_list:

         #  1) Sequence identity
         if plot_name == 'seqID':
            score = '%.3f %%' % (mstat.chain_list[chain].seqID * 100.0)
            source = '%s' % mstat.chain_list[chain].source
            logfile=init.relative_link + 'data/sequences/' + chain + '_aln.fasta'
         #  2) Alignment length score (alignment quality)
         elif plot_name == 'AlignLenScore':
            score = '%.3f' % mstat.chain_list[chain].alignment.align_len_score
            source = '%s' % mstat.chain_list[chain].source
            logfile=init.relative_link + 'data/sequences/' + chain + '_aln.fasta'
         # 3) Alignment score
         elif plot_name == 'AlignScore':
            score = '%.3f' % mstat.chain_list[chain].alignment.score
            source = '%s' % mstat.chain_list[chain].source
            logfile=init.relative_link + 'data/sequences/' + chain + '_aln.fasta'
         # 4) Molrep score
         elif plot_name == 'Molrep':
            score = '%.3f' % mstat.chain_list[chain].molrep_score
            source = '%s' % mstat.chain_list[chain].source
            #os.system('cp ' + mstat.chain_list[chain].molrep_logfile + ' ' + mstat.results_dir + '/log_files/')
            shutil.copy(mstat.chain_list[chain].molrep_logfile, mstat.results_dir + '/log_files/')
            logfile=init.relative_link + 'log_files/MODEL_MOLREP_' + mstat.chain_list[chain].chainName + '.log'
         # 5) Chainsaw scores
         elif plot_name == 'Chainsaw':
            score_m = '%.3f' % mstat.chain_list[chain].chainsaw_score
            #os.system('cp ' + mstat.chain_list[chain].chainsaw_logfile + ' ' + mstat.results_dir + '/log_files/')
            shutil.copy(mstat.chain_list[chain].chainsaw_logfile, mstat.results_dir + '/log_files/')
            logfile_m=init.relative_link + 'log_files/CHAINSAW_' + mstat.chain_list[chain].chainName + '.log'

         # Fill in the values into the table
         table += '<tr>\n'
         table += '<td>' + `count+1` + '</td>\n'
         table += '<td> <a href="http://www.ebi.ac.uk/msd-srv/msdlite/atlas/summary/' + mstat.chain_list[chain].PDBName + \
         '.html" target="_blank">' + mstat.chain_list[chain].chainName + '</a></td>\n'
         # Chainsaw is a special case as it has two sets of results
         if plot_name == 'Chainsaw':
            table += '<td>' + score_m + '</td>\n'
            table += '<td> <a href="' + logfile_m + '" target="_blank">Log file</a></td>\n'
            table += '</tr>\n'
         else:
            table += '<td>' + score + '</td>\n'
            table += '<td>' + source + '</td>\n'
            table += '<td> <a href="' + logfile + '" target="_blank">Log file</a></td>\n'
            table += '</tr>\n'

         # Increment the template model count
         count=count + 1
         if count > max_count:
            break

      # Close the table
      table += '</table>\n'

      return table

   def print_scores_file(self, mstat):
      """ A function to print out all of the scores from the searches and model preparation. """ 

      # Setup a count of the templates
      count = 1

      # Set the scores file
      outfile = mstat.results_dir + '/data/scores.dat'
      mstat.setScoresFile(outfile)

      # Write out a table of several scores to the file
      o=open(outfile, 'w')
      for chain in mstat.sorted_MR_list: 
         CHAIN=mstat.chain_list[chain]

         o.write("%d \t %s \t %.3f \t %.3f \t %.3f \t %.3f \t %.3f \t %s\n" % \
            (count, \
             CHAIN.chainName, CHAIN.alignment.score, CHAIN.alignment.seqID, \
             CHAIN.alignment.align_len_score, CHAIN.molrep_score, \
             CHAIN.chainsaw_score, CHAIN.source))
         count = count + 1
       
      o.close()


   def make_SCOP_results_file(self, mstat):
      """ A function to create a file containing the SCOP results. """ 

      # Make the title for the SCOP results file
      line =  "SCOP domains search results\n\n"
      line += "---------------------------------------------------------------------\n"
      line += "CHAIN_ID \t No. of Domains \t List of Domains \n"
      line += "---------------------------------------------------------------------\n"

      # Loop over all chains (except SCOP chains) and print the domains details
      for chain in mstat.sorted_list:
         CHAIN=mstat.chain_list[chain[0]]
 
         if CHAIN.source != "SCOP":
            line += "%s \t\t %d \t\t " % (chain[0], CHAIN.no_of_domains)
            count = 0
            for domain in CHAIN.domain_list:
               count = count + 1
               if count < CHAIN.no_of_domains:  
                  line += "%s, " % domain
               else:
                  line += "%s" % domain
            line += "\n"
                  
      #' Write the results the SCOP results file
      mstat.setSCOPResultsFile(mstat.results_dir + '/data/scop_results.txt')
      out_file=open(mstat.SCOP_results_file, 'w')
      out_file.write(line)
      out_file.close


if __name__ == '__main__':

   w=write_html()
   w.write_header(init, "res.html")
   len_footer = w.write_footer(init, "res.html")
