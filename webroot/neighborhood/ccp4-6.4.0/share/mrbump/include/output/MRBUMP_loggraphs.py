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
# Script to create loggraph data from an MrBUMP job
# Ronan Keegan 7/3/06

import Loggraph


class Mrbump_logs:
   """ A class to output any loggraphs from a MrBUMP job. """

   def __init__(self):
      self.name=""

   def plot_alignment_graphs(self, init, mstat):
      """ Plot any graphs to do with the Alignment step. """

      # Print the alignment scores in Loggraph format
      a=[]
      b=[]
      c=[]
      loggraph_array=[a,b,c]
      count=0

      # Construct the data array for loggraph
      for i in mstat.sorted_list:
         a.append(count)
         b.append(i[1])
         c.append(mstat.chain_list[i[0]].alignment.seqID)
         count=count + 1

      # Call the loggraph class and construct the table
      lg=Loggraph.Loggraph()
      lg.setTable('Alignment scores after template model search')
      lg.addGraphs('Alignment score', 1, 2)
      lg.addGraphs('Sequence Identity', 1, 3)
      lg.setLabels('Model', 'Score', 'Seq-ID')
      lg.write_log(loggraph_array)


   def plot_model_prep_graphs(self, init, mstat):
      """ Plot any graphs to do with Model preparation. """

      # Print the molrep and chainsaw scores in Loggraph format

     #  Set up the arrays to store the scores. Check if all or only one are output.
      a=[]
      if init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW:
         b=[]
         c=[]
         loggraph_array=[a,b,c]
      elif init.keywords.MDLMOLREP==False or init.keywords.MDLCHAINSAW==False:
         b=[]
         loggraph_array=[a,b]
      count=0

      # Construct the data array for loggraph
      for i in mstat.sorted_MR_list:
         a.append(count)
         if init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW:
            b.append(mstat.chain_list[i].molrep_score)
            c.append(mstat.chain_list[i].chainsaw_score)
         elif init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW==False:
            b.append(mstat.chain_list[i].molrep_score)
         elif init.keywords.MDLMOLREP==False and init.keywords.MDLCHAINSAW:
            b.append(mstat.chain_list[i].chainsaw_score)

         # Output the list with the chain IDs to the log file
         if count == 0:
            print ""
            print "#####################################################################"
            print "#####             Search Model Preparation Results              #####"
            print "#####################################################################"
            print ""

            if init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW:
               print "CHAINID\t\tRESOL(A)  MOLREP-SCORE  CHAINSAW-SCORE  SOURCE  MODEL NO."
            elif init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW==False:
               print "CHAINID\t\tRESOL(A)  MOLREP-SCORE  SOURCE  MODEL NO."
            elif init.keywords.MDLMOLREP==False and init.keywords.MDLCHAINSAW:
               print "CHAINID\t\tRESOL(A)  CHAINSAW-SCORE  SOURCE  MODEL NO."
            print "----------------------------------------------------------------------------"

         # Adjust the spaceing bewtween CHAINID value and RESOL value depending model name length
         if len(mstat.chain_list[i].chainName) > 7:
            spacer="\t"
         else:
            spacer="\t\t"

         if init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW:
            print "%s%s %.3f       %.3f           %.3f          %s      %d" % \
               (mstat.chain_list[i].chainName, spacer, mstat.chain_list[i].resolution_high, \
                mstat.chain_list[i].molrep_score, \
                mstat.chain_list[i].chainsaw_score, mstat.chain_list[i].source, count)
         elif init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW==False:
            print "%s%s %.3f       %.3f           %s      %d" % \
               (mstat.chain_list[i].chainName, spacer, mstat.chain_list[i].resolution_high, \
                mstat.chain_list[i].molrep_score, \
                mstat.chain_list[i].source, count)
         if init.keywords.MDLMOLREP==False and init.keywords.MDLCHAINSAW:
            print "%s%s %.3f       %.3f          %s      %d" % \
               (mstat.chain_list[i].chainName, spacer, mstat.chain_list[i].resolution_high, \
                mstat.chain_list[i].chainsaw_score, mstat.chain_list[i].source, count)

         count=count + 1
      print ""

      # Call the loggraph class and construct the table
      lg=Loggraph.Loggraph()
      lg.setTable('Search model preparation scores')

      if init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW:
         lg.addGraphs('Molrep score', 1, 2)
         lg.addGraphs('Chainsaw score', 1, 3)
         lg.setLabels('Model', 'Molrep-Score', 'Chainsaw-Score')
      elif init.keywords.MDLMOLREP and init.keywords.MDLCHAINSAW==False:
         lg.addGraphs('Molrep score', 1, 2)
         lg.setLabels('Model', 'Molrep-Score')
      elif init.keywords.MDLMOLREP==False and init.keywords.MDLCHAINSAW:
         lg.addGraphs('Chainsaw score', 1, 2)
         lg.setLabels('Model', 'Chainsaw-Score')

      lg.write_log(loggraph_array)
