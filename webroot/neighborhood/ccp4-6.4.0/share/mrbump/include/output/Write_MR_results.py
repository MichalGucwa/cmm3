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
# Write the Molecular Replacement results to the results.html file.
# Ronan Keegan 25.8.05 

import os, sys, string
import time, shutil

import Write_Search_results 
import Sort_dict
import printTable

class Write_MR_Results:

   def __init__(self):
      self.name = ''
      self.marginal_found = False
      try:
         self.debug=eval(os.environ['MRBUMP_DEBUG'])
      except:
         self.debug=False

   def write_MR_header(self, init, mstat):
      """ A function to write the header for the MR section of the webpage. """

      line = '<br>\n'
      line += '<b><font size=6 color=red>Molecular Replacement and Refinement:</font></b><br>\n'
      line += '<br>\n'

      # Remove the footer from the resuls page
      page=Write_Search_results.Write_html()     
      page.remove_footer(mstat, mstat.results_html) 

      # Append the results to the results page
      res_html=open(mstat.results_html, 'a')
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      page.write_footer(init, mstat, mstat.results_html)

   def write_marginal_solnSerial(self, init, mstat, model, final_rfree, diff):
      """ A function to write out a marginal solution result to the results HTML file. """
      
      # Copy the results files to the solutions folder
       
      self.marginal_found = True
      model_dir_name = model + "_" + mstat.MRPROGRAM
      if os.path.isdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name)) == False:
         os.mkdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name))
         os.mkdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name, mstat.MRPROGRAM.lower()))

      shutil.copytree(os.path.join(mstat.model_list[model].model_directory, mstat.MRPROGRAM.lower(), 'refine'), \
         os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name, mstat.MRPROGRAM.lower(), 'refine'))
 
      # Point the file links to this directory
 
      directory = os.path.join(init.relative_link, 'marginal_solns', model_dir_name, mstat.MRPROGRAM.lower(), 'refine')

      if mstat.MRPROGRAM=="MOLREP":
         logfile_name = os.path.split(mstat.model_list[model].refmac_molrep_logfile)[-1] 
         mtzfile_name = os.path.split(mstat.model_list[model].refmac_molrep_MTZOUTfile)[-1] 
         pdbfile_name = os.path.split(mstat.model_list[model].refmac_molrep_PDBfile)[-1] 
      if mstat.MRPROGRAM=="PHASER":
         logfile_name = os.path.split(mstat.model_list[model].refmac_phaser_logfile)[-1] 
         mtzfile_name = os.path.split(mstat.model_list[model].refmac_phaser_MTZOUTfile)[-1] 
         pdbfile_name = os.path.split(mstat.model_list[model].refmac_phaser_PDBfile)[-1] 

      logfile = os.path.join(directory, logfile_name) 
      mtzfile = os.path.join(directory, mtzfile_name) 
      pdbfile = os.path.join(directory, pdbfile_name) 

      if init.keywords.HTMLOUT==True:
         line =  '<br>\n'
         line += '<b>Marginal solution found using <b>%s</b> for the MR:</b><br><br>\n' % mstat.MRPROGRAM
         line += '<i>Template Model: %s has produced a marginal solution, final Rfree = %s and is %s of initial Rfree</i><br>\n' \
             % (model, final_rfree, diff)
         line += '<a href="' + pdbfile + '">PDB file</a> - refined template PDB file<br>\n'
         line += '<a href="' + mtzfile + '">MTZ file</a> - updated target MTZ file<br>\n'
         line += '<a href="' + logfile + '">Log file</a> - Refmac log file<br>\n'
         
         # Remove the footer from the resuls page
         page=Write_Search_results.Write_html()     
         page.remove_footer(mstat, mstat.results_html) 
   
         # Append the results to the results page
         res_html=open(mstat.results_html, 'a')
         res_html.write(line)
         res_html.close()
   
         # Add the footer to the results page
         page.write_footer(init, mstat, mstat.results_html)

   def write_marginal_solnParallel(self, init, mstat, model, job, final_rfree, diff):
      """ A function to write out a marginal solution result to the results HTML file. """
      
      # Copy the results files to the solutions folder
       
      self.marginal_found = True
      model_dir_name = model + "_" + mstat.jobname_dict[job].MRPROGRAM
      if os.path.isdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name)) == False:
         os.mkdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name))
         os.mkdir(os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name, mstat.jobname_dict[job].MRPROGRAM))

      shutil.copytree(os.path.join(mstat.model_list[model].model_directory, mstat.jobname_dict[job].MRPROGRAM, 'refine'), \
         os.path.join(mstat.results_dir, 'marginal_solns', model_dir_name, mstat.jobname_dict[job].MRPROGRAM, 'refine'))
 
      # Point the file links to this directory
 
      directory = os.path.join(init.relative_link, 'marginal_solns', model_dir_name, mstat.jobname_dict[job].MRPROGRAM, 'refine')

      if mstat.jobname_dict[job].MRPROGRAM=="MOLREP":
         logfile_name = os.path.split(mstat.model_list[model].refmac_molrep_logfile)[-1] 
         mtzfile_name = os.path.split(mstat.model_list[model].refmac_molrep_MTZOUTfile)[-1] 
         pdbfile_name = os.path.split(mstat.model_list[model].refmac_molrep_PDBfile)[-1] 
      if mstat.jobname_dict[job].MRPROGRAM=="PHASER":
         logfile_name = os.path.split(mstat.model_list[model].refmac_phaser_logfile)[-1] 
         mtzfile_name = os.path.split(mstat.model_list[model].refmac_phaser_MTZOUTfile)[-1] 
         pdbfile_name = os.path.split(mstat.model_list[model].refmac_phaser_PDBfile)[-1] 

      logfile = directory + '/' + logfile_name 
      mtzfile = directory + '/' + mtzfile_name 
      pdbfile = directory + '/' + pdbfile_name 

      if init.keywords.HTMLOUT==True:
         line =  '<br>\n'
         line += '<b>Marginal solution found using <b>%s</b> for the MR:</b><br><br>\n' % mstat.jobname_dict[job].MRPROGRAM
         line += '<i>Template Model: %s has produced a marginal solution, final Rfree = %s and is %s of initial Rfree</i><br>\n' \
             % (model, final_rfree, diff)
         line += '<a href="' + pdbfile + '">PDB file</a> - refined template PDB file<br>\n'
         line += '<a href="' + mtzfile + '">MTZ file</a> - updated target MTZ file<br>\n'
         line += '<a href="' + logfile + '">Log file</a> - Refmac log file<br>\n'
         
         # Remove the footer from the resuls page
         page=Write_Search_results.Write_html()     
         page.remove_footer(mstat, mstat.results_html) 
   
         # Append the results to the results page
         res_html=open(mstat.results_html, 'a')
         res_html.write(line)
         res_html.close()
   
         # Add the footer to the results page
         page.write_footer(init, mstat, mstat.results_html)
      
   def write_final_soln(self, init, mstat, target_info):
      """ A function to write out the final MR solution details to the results.html page. """ 

      # Title for this section of the results.html
      line =  '<br>\n'
      line += '<b><font size=5 color=green>Final Solution:</font></b><br>\n'
      line += '<br>\n'
 
      if mstat.solution_found == True and init.keywords.TRYALL == False:
         SOLN_MODEL=mstat.model_list[mstat.soln_model]
 
         #Reset the output files to the ones stored in the results/solution folder.
         if SOLN_MODEL.MRPROGRAM == 'Molrep':
            soln_molrep_PDBfile = init.relative_link + 'solution/mr/' + string.split(SOLN_MODEL.molrep_PDBfile,'/')[-1]
            soln_molrep_logfile = init.relative_link + 'solution/mr/' + string.split(SOLN_MODEL.molrep_logfile,'/')[-1]
            soln_refmac_PDBfile = init.relative_link + 'solution/mr/molrep/refine/' + string.split(SOLN_MODEL.refmac_molrep_PDBfile,'/')[-1]
            soln_refmac_MTZOUTfile = init.relative_link + 'solution/mr/molrep/refine/' + string.split(SOLN_MODEL.refmac_molrep_MTZOUTfile,'/')[-1]
            soln_refmac_logfile = init.relative_link + 'solution/mr/molrep/refine/' + string.split(SOLN_MODEL.refmac_molrep_logfile,'/')[-1]
         elif SOLN_MODEL.MRPROGRAM == 'Phaser':
            soln_phaser_PDBfile = init.relative_link + 'solution/mr/' + string.split(SOLN_MODEL.phaser_PDBfile,'/')[-1]
            soln_phaser_logfile = init.relative_link + 'solution/mr/' + string.split(SOLN_MODEL.phaser_logfile,'/')[-1]
            soln_refmac_PDBfile = init.relative_link + 'solution/mr/phaser/refine/' + string.split(SOLN_MODEL.refmac_phaser_PDBfile,'/')[-1]
            soln_refmac_MTZOUTfile = init.relative_link + 'solution/mr/phaser/refine/' + string.split(SOLN_MODEL.refmac_phaser_MTZOUTfile,'/')[-1]
            soln_refmac_logfile = init.relative_link + 'solution/mr/phaser/refine/' + string.split(SOLN_MODEL.refmac_phaser_logfile,'/')[-1]

         #soln_refmac_PDBfile = init.relative_link + 'solution/refine/' + string.split(SOLN_MODEL.refmac_PDBfile,'/')[-1]
         #soln_refmac_MTZOUTfile = init.relative_link + 'solution/refine/' + string.split(SOLN_MODEL.refmac_MTZOUTfile,'/')[-1]
         #soln_refmac_logfile = init.relative_link + 'solution/refine/' + string.split(SOLN_MODEL.refmac_logfile,'/')[-1]
 
         # Write out the name and details of the template that produced the solution 
         if SOLN_MODEL.chain_source[5] != '_':
            line += 'Chain ' + SOLN_MODEL.chain_source + ' of structure <b>' + SOLN_MODEL.PDBName + \
                 '</b> was found to be a good template model for the target structure.<br>\n'
         else:
            line += 'Structure <b>' + SOLN_MODEL.PDBName + \
                 '</b> was found to be a good template model for the target structure.<br>\n'
         line += 'The template was prepared using the ' + SOLN_MODEL.type + ' method.<br>\n'

         # Write out the Molecular Replacement results
         line += '<br>\n'
         line += '<b>Molecular Replacement</b><br><br>\n'
         line += 'Molecular Replacement program: ' + SOLN_MODEL.MRPROGRAM + '<br>\n'

         # Write the results for the MR job according to the program used
         if SOLN_MODEL.MRPROGRAM == 'Molrep':
            line += '<i>Correlation Coefficient</i>: %.3f <br>\n' % SOLN_MODEL.molrep_Corr
            line += '<i>Rfactor</i>: %.3f <br>\n' % SOLN_MODEL.molrep_Rfac
            line += '<a href="' + soln_molrep_PDBfile + '">PDB file</a> - phased PDB file<br>\n'
            line += '<a href="' + soln_molrep_logfile + '">Log file</a> - Molrep log file<br>\n'
         elif SOLN_MODEL.MRPROGRAM == 'Phaser':
            line += '<i>LLG Score</i>: %.3f <br>\n' % SOLN_MODEL.phaser_LLG_score
            line += '<i>Zscore</i>: %.3f <br>\n' % SOLN_MODEL.phaser_Zscore
            line += '<a href="' + soln_phaser_PDBfile + '">PDB file</a> - phased PDB file<br>\n'
            line += '<a href="' + soln_phaser_logfile + '">Log file</a> - Phaser log file<br>\n'

         # Write the refinement results includeing where to find the results files.
         line += '<br>\n'
         line += '<b>Refinement</b><br><br>\n'
         line += 'The template model was refined using ' + SOLN_MODEL.Refinement_program + '<br>\n'
         if SOLN_MODEL.MRPROGRAM == 'Molrep':
            line += '<i>Initial Rfree</i>: %.3f <br>\n' % SOLN_MODEL.refmac_molrep_initRfree
            line += '<i>Final Rfree</i>: %.3f (after 30 cycles)<br>\n' % SOLN_MODEL.refmac_molrep_finlRfree
         elif SOLN_MODEL.MRPROGRAM == 'Phaser':
            line += '<i>Initial Rfree</i>: %.3f <br>\n' % SOLN_MODEL.refmac_phaser_initRfree
            line += '<i>Final Rfree</i>: %.3f (after 30 cycles)<br>\n' % SOLN_MODEL.refmac_phaser_finlRfree
         line += '<br>\n'
         line += '<a href="' + soln_refmac_PDBfile + '">PDB file</a> - refined template PDB file<br>\n'
         line += '<a href="' + soln_refmac_MTZOUTfile + '">MTZ file</a> - updated target MTZ file<br>\n'
         line += '<a href="' + soln_refmac_logfile + '">Log file</a> - Refmac log file<br>\n'
        
      # If no solution was found just report that fact
      else:
         line +=  '<br>\n'
         line += 'No Solution found.<br>\n'
         line += '<br>\n'
         
      # Remove the footer from the resuls page
      page=Write_Search_results.Write_html()     
      page.remove_footer(mstat, mstat.results_html) 

      # Append the results to the results page
      res_html=open(mstat.results_html, 'a')
      res_html.write(line)
      res_html.close()

      # Add the footer to the results page
      page.write_footer(init, mstat, mstat.results_html)

   def display_results(self, mstat, init, target_info):
      """ A function to display results in the shell window. """
      
      len_name=len(target_info.chainID)
    
      # Tag this up as SUMMARY content
      sys.stdout.write('<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n')
      sys.stdout.write('\n')

      print "" 
      print "###########################################" + "#"*len_name + "##################"
      print "#######           Solution for Target/Job: " + target_info.chainID + "          ########"
      print "###########################################" + "#"*len_name + "##################"
      print ""
       
      print 'Solution template structure: ' + mstat.model_list[mstat.soln_model].PDBName
      print 'Chain: ' + mstat.model_list[mstat.soln_model].chain_source
      print 'Model Preparation Method: ' + mstat.model_list[mstat.soln_model].type + '\n'

      print 'Molecular Replacement Method: ' + mstat.model_list[mstat.soln_model].MRPROGRAM
      if mstat.model_list[mstat.soln_model].MRPROGRAM == 'Molrep':
         print 'Phased PDB file: ' + string.split(mstat.model_list[mstat.soln_model].molrep_PDBfile,'/')[-1] + '\n'
      elif mstat.model_list[mstat.soln_model].MRPROGRAM == 'Phaser':
         print 'Phased PDB file: ' + string.split(mstat.model_list[mstat.soln_model].phaser_PDBfile,'/')[-1] + '\n'

      print 'Refinement Method: ' + mstat.model_list[mstat.soln_model].Refinement_program
      if mstat.model_list[mstat.soln_model].Refinement_program == 'Refmac':
         if mstat.MRPROGRAM=="MOLREP":
            print 'Initial Rfree: %.3f and Rfree after 30 cycles: %.3f ' \
                % (mstat.model_list[mstat.soln_model].refmac_molrep_initRfree, mstat.model_list[mstat.soln_model].refmac_molrep_finlRfree)
            print 'Refined PDB file: ' + string.split(mstat.model_list[mstat.soln_model].refmac_molrep_PDBfile,'/')[-1]
            print 'Udpdated MTZ file: ' + string.split(mstat.model_list[mstat.soln_model].refmac_molrep_MTZOUTfile,'/')[-1] + '\n'
         if mstat.MRPROGRAM=="PHASER":
            print 'Initial Rfree: %.3f and Rfree after 30 cycles: %.3f ' \
                % (mstat.model_list[mstat.soln_model].refmac_phaser_initRfree, mstat.model_list[mstat.soln_model].refmac_phaser_finlRfree)
            print 'Refined PDB file: ' + string.split(mstat.model_list[mstat.soln_model].refmac_phaser_PDBfile,'/')[-1]
            print 'Udpdated MTZ file: ' + string.split(mstat.model_list[mstat.soln_model].refmac_phaser_MTZOUTfile,'/')[-1] + '\n'
      if init.keywords.TRYALL == True:
         print 'Solution files can be found in the following directory:\n %s' \
            % (mstat.model_list[mstat.soln_model].model_directory + '/mr/' + mstat.MRPROGRAM + '/refine')
      else:
         print 'Solution files can be found in the following directory:\n %s' \
            % (mstat.results_dir + '/solution')
      if init.keywords.HTMLOUT == True:
         print 'The results can also be viewed in HTML format in the file:\n %s' \
            % mstat.results_html
      
      print ""
      print "###########################################" + "#"*len_name + "##################"
      print ""
    
      sys.stdout.write('<!--SUMMARY_END--></FONT></B>\n')
      sys.stdout.write('\n')

   def copy_solution_files(self, mstat, soln_dir):
      """ A function to copy the solution files to the results/solution directory"""

      if os.path.isdir(soln_dir):
         print "Solution directory already exists"
      else:
         shutil.copytree(mstat.model_list[mstat.soln_model].model_directory, soln_dir) 
    
   def setTRYALL_summary(self, init, mstat):
      """ Record all of the results for the jobs when running in TRYALL mode for a given MR program. """

      for MRPROGRAM in init.keywords.MR_PROGRAM_LIST:

         # Tag this up as SUMMARY content
         line ='<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n'
         line+='\n'
   
         line+="#######################################################################\n"
         line+="###   TRYALL mode: Summary of results for all models using %s   ###\n" % MRPROGRAM
         line+="#######################################################################\n"
         line+="\n"
   
         # Put the results into a dictionary holding model name/final rfree pairs
         sorted_results=dict([])
         for model in mstat.sorted_model_list:
            if MRPROGRAM == "MOLREP":
               sorted_results[model]=mstat.model_list[model].refmac_molrep_finlRfree
            if MRPROGRAM == "PHASER":
               sorted_results[model]=mstat.model_list[model].refmac_phaser_finlRfree
   
         # Sort the dictionary of results
         s=Sort_dict.Sort_dict()
         sorted_list=s.sort(sorted_results)
   
         line+="Results sorted according to final Rfree value from Refmac (%s for MR):\n" % MRPROGRAM
         line+="(For output file details from each job see above)\n"
         line+="\n"
   
         if MRPROGRAM == "MOLREP":
            for i in sorted_list:
                  if mstat.model_list[i[0]].solution_type_MOLREP=="GOOD" or mstat.model_list[i[0]].solution_type_MOLREP=="MARGINAL":
                     line+="Model Name: %s\t -- Solution type: '%s'\t -- Final Rfree: %.3f\n" % (i[0], mstat.model_list[i[0]].solution_type_MOLREP, i[1])
            for i in sorted_list:
               if mstat.model_list[i[0]].solution_type_MOLREP!="GOOD" and mstat.model_list[i[0]].solution_type_MOLREP!="MARGINAL":
                  line+="Model Name: %s\t -- Solution type: '%s'\n" % (i[0], mstat.model_list[i[0]].solution_type_MOLREP)
               #line+="%s: %s --> Final Rfree: %.3f\n" % (i[0], mstat.model_list[i[0]].model_info_string, i[1])
         if MRPROGRAM == "PHASER":
            for i in sorted_list:
                  if mstat.model_list[i[0]].solution_type_PHASER=="GOOD" or mstat.model_list[i[0]].solution_type_PHASER=="MARGINAL":
                     line+="Model Name: %s\t -- Solution type: '%s'\t -- Final Rfree: %.3f\n" % (i[0], mstat.model_list[i[0]].solution_type_PHASER, i[1])
            for i in sorted_list:
               if mstat.model_list[i[0]].solution_type_PHASER!="GOOD" and mstat.model_list[i[0]].solution_type_PHASER!="MARGINAL":
                  line+="Model Name: %s\t -- Solution type: '%s'\n" % (i[0], mstat.model_list[i[0]].solution_type_PHASER)
              #line+="%s: %s --> Final Rfree: %.3f\n" % (i[0], mstat.model_list[i[0]].model_info_string, i[1])
         line+="\n"
   
         line+='<!--SUMMARY_END--></FONT></B>\n'
         line+='\n'
   
         # Ouput the job details to an XML file
         # Loop over the model list and give a brief summary of the results for each one
         #for model in mstat.sorted_model_list:
         #   line+="### Model: %s using MR program: %s ###\n" % (model, MRPROGRAM)
         #   if mstat.model_list[model].solution_type=="GOOD":
         #      line+="   This model produced a GOOD solution (final Rfree from refinement: %.3f)\n" \
         #                       % mstat.model_list[model].refmac_finlRfree
         #      line+="   Solution MTZ file:\n   %s\n" % mstat.model_list[model].refmac_MTZOUTfile
         #      line+="   Solution PDB file:\n   %s\n" % mstat.model_list[model].refmac_PDBfile
         #      line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="MARGINAL":
   #            line+="   This model produced a MARGINAL solution (final Rfree from refinement: %.3f)\n" \
   #                             % mstat.model_list[model].refmac_finlRfree
   #            line+="   Solution MTZ file:\n   %s\n" % mstat.model_list[model].refmac_MTZOUTfile
   #            line+="   Solution PDB file:\n   %s\n" % mstat.model_list[model].refmac_PDBfile
   #            line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="FAILED":
   #            line+="This model FAILED to produce a solution (final Rfree from refinement: %.3f)\n" \
   #                             % mstat.model_list[model].refmac_finlRfree
   #            line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="MOLREP_FAIL":
   #            line+="Molrep failed to produce a solution for this model. Molrep log file:\n   %s\n" \
   #                             % mstat.model_list[model].molrep_logfile
   #            line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="PHASER_FAIL":
   #            line+="Phaser failed to produce a solution for this model. Phaser log file:\n   %s\n" \
   #                             % mstat.model_list[model].phaser_logfile
   #            line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="REFMAC_FAIL":
   #            line+="Refmac failed to produce a solution for this model. Refmac log file:\n   %s\n" \
   #                             % mstat.model_list[model].refmac_logfile
   #            line+="\n"
   #
   #         elif mstat.model_list[model].solution_type=="":
   #            line+="This model FAILED to produce a solution\n"
   #            line+="\n"
   
         mstat.TRYALL_summary[MRPROGRAM]=line

      sys.stdout.write("\n")

   def print_references(self, init, mstat):
      """ A function to print the references for the programs used in the job. """

      # Tag this up as SUMMARY content
      line ='<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n'
      line+='\n'

      line += "<h3>MrBUMP Program References</h3>"

      line += "<P>"
      line += "Any publication arising from use of MrBUMP should"
      line += "include the following reference:</P>"
      line += "<P>"
      line += "R.M.Keegan and M.D.Winn (2007) <em>Acta Cryst.</em> <b>D63</b>, 447-457" 
      line += "</P>"
      line += "In addition, authors of specific programs should be referenced where"
      line += "applicable:"

      line += "<dl>"
      line += "<dt>CCP4"
      line += "<dd>Collaborative Computational Project, Number 4. (1994), &quot;The CCP4 Suite: Programs "
      line += "for Protein Crystallography&quot;. <em>Acta Cryst.</em> <b>D50</b>, 760-763 "
      line += "<dt>FASTA"
      line += "<dd>W. R. Pearson and D. J. Lipman (1988), &quot;Improved Tools"
      line += "for Biological Sequence Analysis&quot;, <em>PNAS</em> <b>85</b>, 2444-2448"

      if init.keywords.SSM == True:
         line += "<dt>SSM"
         line += "<dd>E.Krissinel and K.Henrick (2004), &quot;Secondary-structure matching (SSM), a new tool "
         line += "for fast protein structure alignment in three dimensions&quot;"
         line += "<em>Acta Cryst.</em> <b>D60</b>, 2256-2268"

      if init.keywords.PISA == True:
         line += "<dt>PISA"
         line += "<dd>E.Krissinel and K.Henrick (2005), &quot;Detection of Protein Assemblies in Crystals&quot;,"
         line += "edited by M.R. Berthold et.al, CompLife 2005, LNBI 3695,"
         line += "pp. 163-174. Springer-Verlag Berlin Heidelberg"

      if init.keywords.SCOP == True:
         line += "<dt>SCOP"
         line += "<dd>A.G.Murzin, S.E.Brenner, T.Hubbard & C.Chothia (1995), <em>J.Mol.Biol.</em>,"
         line += "<b>247</b>, 536-540"

      if init.keywords.MAPROGRAM == "MAFFT":
         line += "<dt>MAFFT"
         line += "<dd>K. Katoh, K. Kuma, H. Toh and T. Miyata (2005)"
         line += "&quot;MAFFT version 5: improvement in accuracy of multiple sequence alignment&quot; "
         line += "<em>Nucleic Acids Res.</em> <b>33</b>, 511-518"

      if init.keywords.MAPROGRAM == "PROBCONS":
         line += "<dt>PROBCONS"
         line += "<dd>Do, C.B., Mahabhashyam, M.S.P., Brudno, M., and Batzoglou, S. (2005)"
         line += "&quot;PROBCONS: Probabilistic Consistency-based Multiple Sequence Alignment.&quot; "
         line += "<em>Genome Research</em> <b>15</b>, 330-340"

      if init.keywords.MAPROGRAM == "T_COFFEE":
         line += "<dt>T_COFFEE"
         line += "<dd>C.Notredame, D. Higgins, J. Heringa (2000)"
         line += "&quot;T-Coffee: A novel method for multiple sequence alignments.&quot;"
         line += "<em>Journal of Molecular Biology</em> <b>302</b>, 205-217"

      if init.keywords.MAPROGRAM == "CLUSTALW":
         line += "<dt>CLUSTALW"
         line += "<dd>Chenna, Ramu, Sugawara, Hideaki, Koike,Tadashi, Lopez, Rodrigo, "
         line += "Gibson, Toby J, Higgins, Desmond G, Thompson, Julie D. (2003)"
         line += "&quot;Multiple sequence alignment with the Clustal series of programs&quot;"
         line += "<em>Nucleic Acids Res</em> <b>31</b>, 3497-500"

      if init.keywords.MDLCHAINSAW == True:
         line += "<dt>CHAINSAW"
         line += "<dd>N.D.Stein (2008) &quot;CHAINSAW: a program for mutating pdb files used as"
         line += "templates in molecular replacement&quot; <em>J. Appl. Cryst.</em> <b>41</b>, 641-643"

      if init.keywords.MDLSCULPTOR == True:
         line += "<dt>SCULPTOR"
         line += "<dd>G.Bunkoczi and R.J.Read (2011) &quot;Improvement of molecular-replacement models with Sculptor&quot;"
         line += " <em>Acta Cryst.</em> <b>D67</b>, 303-312"

      if init.keywords.MDLMOLREP or init.ONLYMODELS == False:
         line += "<dt>MOLREP"
         line += "<dd>A.A.Vagin & A.Teplyakov (1997) <em>J. Appl. Cryst.</em> <b>30</b>, 1022-1025"
  
      if init.ONLYMODELS == False:
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            line += "<dt>PHASER"
            line += "<dd>McCoy, A.J., Grosse-Kunstleve, R.W., Adams, P.D., Winn, M.D.,"
            line += " Storoni, L.C. & Read, R.J. (2007). "
            line += "&quot;Phaser crystallographic software&quot; <i>J. Appl. Cryst.</i> <b>40</b>, 658-674"

         line += "<dt>REFMAC"
         line += "<dd>G.N. Murshudov, A.A.Vagin and E.J.Dodson, (1997) &quot;Refinement of Macromolecular "
         line += "Structures by the Maximum-Likelihood Method&quot; <em>Acta Cryst.</em>"
         line += "<b>D53</b>, 240-255"

      if init.keywords.USEACORN:
         line += "<dt>ACORN"
         line += "<dd>Yao Jia-xing, Woolfson,M.M., Wilson,K.S. and Dodson,E.J. (2005) <em>Acta. Cryst.</em> <b>D61</b>, 1465-1475.\n" 

      line += "</dl>"

      line+='<!--SUMMARY_END--></FONT></B>\n'
      line+='\n'

      # Remove the footer from the resuls page
      page=Write_Search_results.Write_html()     
      page.remove_footer(mstat, mstat.results_html) 

      # Append the results to the results page
      res_html=open(mstat.results_html, 'a')
      res_html.write(line)
      res_html.close()

      # Make a note of the job completion time and set the total job execution time
      mstat.setEndTime(time.time())
      total_time = mstat.end_time - mstat.start_time
   
      mstat.setJob_Time(total_time)

      # Add the footer to the results page
      mstat.setJob_End(True)
      page.write_footer(init, mstat, mstat.results_html)

   def print_references_stdout(self, init):
      """ A function to print the references to the stdout for the programs used in the job. """

      # Tag this up as SUMMARY content
      line ='<B><FONT COLOR="#FF0000"><!--SUMMARY_BEGIN-->\n'
      line += "##############################################\n"
      line += "###        MrBUMP Program References       ###\n"
      line += "##############################################\n"
      line += "\n"

      line+="$$\n"
      line+="$TEXT:Program References: $$ References $$\n"
      line += "\n"

      line += "Any publication arising from use of MrBUMP should include the following reference:\n"
      line += "\n"
      line += "R.M.Keegan and M.D.Winn (2007) Acta Cryst. D63, 447-457\n"
      line += "\n"
      line += "In addition, authors of specific programs should be referenced where applicable:\n"

      line += "\n"
      line += "CCP4: M.D.Winn et al. (2011) Overview of the CCP4 suite and current developments \n"
      line += "Acta. Cryst. D67 , 235-242\n"
      line += "\n"
      line += "FASTA: W. R. Pearson and D. J. Lipman (1988), 'Improved Tools\n"
      line += "for Biological Sequence Analysis', PNAS 85, 2444-2448\n"

      if init.keywords.SSM == True:
         line += "\n"
         line += "SSM: E.Krissinel and K.Henrick (2004), 'Secondary-structure matching (SSM), a new tool \n"
         line += "for fast protein structure alignment in three dimensions' Acta Cryst. D60, 2256-2268\n"

      if init.keywords.PISA == True:
         line += "\n"
         line += "PISA: E.Krissinel and K.Henrick (2005), 'Detection of Protein Assemblies in Crystals',\n"
         line += "edited by M.R. Berthold et.al, CompLife 2005, LNBI 3695, pp. 163-174.\n"
         line += "Springer-Verlag Berlin Heidelberg\n"

      if init.keywords.SCOP == True:
         line += "\n"
         line += "SCOP: A.G.Murzin, S.E.Brenner, T.Hubbard & C.Chothia (1995), J.Mol.Biol., 247, 536-540\n"

      if init.keywords.MAPROGRAM == "MAFFT":
         line += "\n"
         line += "MAFFT: K. Katoh, K. Kuma, H. Toh and T. Miyata (2005) 'MAFFT version 5: improvement\n"
         line += "in accuracy of multiple sequence alignment' Nucleic Acids Res. 33, 511-518\n"

      if init.keywords.MAPROGRAM == "PROBCONS":
         line += "\n"
         line += "PROBCONS: Do, C.B., Mahabhashyam, M.S.P., Brudno, M., and Batzoglou, S. (2005)\n"
         line += "'PROBCONS: Probabilistic Consistency-based Multiple Sequence Alignment.'\n"
         line += "Genome Research, 15, 330-340\n"

      if init.keywords.MAPROGRAM == "T_COFFEE":
         line += "\n"
         line += "T_COFFEE: C.Notredame, D. Higgins, J. Heringa (2000)\n"
         line += "T-Coffee: A novel method for multiple sequence alignments.\n"
         line += "Journal of Molecular Biology, 302, 205-217\n"

      if init.keywords.MAPROGRAM == "CLUSTALW":
         line += "\n"
         line += "CLUSTALW: Chenna, Ramu, Sugawara, Hideaki, Koike,Tadashi, Lopez, Rodrigo, \n"
         line += "Gibson, Toby J, Higgins, Desmond G, Thompson, Julie D. (2003)\n"
         line += "'Multiple sequence alignment with the Clustal series of programs'\n"
         line += "Nucleic Acids Res 31, 3497-500\n"

      if init.keywords.MDLCHAINSAW == True:
         line += "\n"
         line += "CHAINSAW: N.D.Stein (2008) 'CHAINSAW: a program for mutating pdb files used as\n"
         line += "templates in molecular replacement' J. Appl. Cryst. 41, 641-643\n"

      if init.keywords.MDLSCULPTOR == True:
         line += "\n"
         line += "PHASER.SCULPTOR: Bunkoczi G. and Read R.J. (2011) 'Improvement of molecular-replacement\nmodels with Sculptor' "
         line += "Acta Cryst. D67, 303-312\n"

      if init.keywords.MDLMOLREP or init.ONLYMODELS == False:
         line += "\n"
         line += "MOLREP: Vagin A.A. & Teplyakov A. (1997) J. Appl. Cryst. 30, 1022-1025\n"

      if init.ONLYMODELS == False:
         if "PHASER" in init.keywords.MR_PROGRAM_LIST:
            line += "\n"
            line += "PHASER: McCoy, A.J., Grosse-Kunstleve, R.W., Adams, P.D., Winn, M.D.,\n"
            line += "Storoni, L.C. & Read, R.J. (2007)\n"
            line += "Phaser crystallographic software' J. Appl. Cryst. 40, 658-674\n"
         line += "\n"
         line += "REFMAC: Murshudov G.N., Vagin A.A. and Dodson E.J., (1997) 'Refinement of Macromolecular \n"
         line += "Structures by the Maximum-Likelihood Method' Acta Cryst. D53, 240-255\n"
         line += "\n"

      if init.keywords.USEACORN:
         line += "ACORN: Yao Jia-xing, Woolfson,M.M., Wilson,K.S. and Dodson,E.J.\n" 
         line += "(2005) Acta. Cryst. D61, 1465-1475.\n"
         line += "\n"

      if init.keywords.BUCCANEER:
         line += "BUCCANEER: Cowtan K. (2006) 'The Buccaneer software for automated model building'\n Acta Cryst. D62, 1002-1011.\n"
         line += "\n"

      if init.keywords.ARPWARP:
         line += "ARP/wARP: Perrakis, A., Morris, R.M. & Lamzin, V.S. (1999) Automated protein model\n building combined with iterative structure refinement. Nature Struct. Biol. 6, 458-463.\n"
         line += " \n"

      if init.keywords.SHELXE:
         line += "SHELXE: Sheldrick, G.M. (2010) 'Experimental phasing with SHELXC/D/E: combining chain\n tracing with density modification' Acta Cryst. D66, 479-485.\n"
         line += " \n"

      line+="$$\n"

      line+='<!--SUMMARY_END--></FONT></B>\n'
      line+='\n'

      print line

