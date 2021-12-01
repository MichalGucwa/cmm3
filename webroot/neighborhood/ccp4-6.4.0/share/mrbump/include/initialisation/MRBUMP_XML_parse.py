#! /usr/bin/env ccp4-python
#
#     Copyright (C) 2011 Ronan Keegan 
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Application.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#
# A script to read input for MrBUMP from an XML file
# 15/2/11 Ronan Keegan


import string, os, sys
import xml.dom.minidom


class readXMLInput:
   """ Class to read the XML Input file for MrBUMP """

   def __init__(self):
       self.ColLabels=dict([])
       self.MODELONLY=False
       self.LABIN=False
       self.JobID=""
       self.SEQIN=""
       self.HKLIN=""
       self.OUTDIR=""
       self.HKLOUT=""
       self.XYZOUT=""
       self.LOG=""
       self.SUMMARY=""

    
   def getDocumentFromFile(self, name=""):
       return xml.dom.minidom.parse(name)

   def getDocumentFromString(self, name=""):
       return xml.dom.minidom.parseString(name)

   def getText(nodelist):
      rc = ""
      for node in nodelist:
          if node.nodeType == node.TEXT_NODE:
              rc = rc + node.data
      return rc

   def getLABIN(self, doc):
      for i in range(len(doc.getElementsByTagName("MrBUMPJobLabinItem"))):
         for node in doc.getElementsByTagName("MrBUMPJobLabinItem")[i].childNodes:
            if node.nodeType == node.TEXT_NODE:
               if i == 0:
                  self.ColLabels["F"]=str(node.data)
               elif i == 1:
                  self.ColLabels["SIGF"]=str(node.data)
               elif i == 2:
                  self.ColLabels["FREE"]=str(node.data)
   
   def getOptions(self, Name):                 
      for i in range(len(Name)):
         for node in Name[i].childNodes:
            if node.nodeType == node.TEXT_NODE:
               if node.data == "False":
                  self.MODELONLY=False
               elif node.data == "True":
                  self.MODELONLY=True
       
   def getJobControl(self, Name):
       for i in range(len(Name)):
         for node in Name[i].childNodes:
            if node.nodeType == node.TEXT_NODE:
               if i == 0:
                  self.JobID=str(node.data)
               if i == 1:
                  if node.data == "False":
                     self.LABIN=False
                  elif node.data == "True":
                     self.LABIN=True
 
   def getJobInputData(self, Name):
       for i in range(len(Name)):
         for node in Name[i].childNodes:
            if node.nodeType == node.TEXT_NODE:
               if i == 0:
                  self.HKLIN=str(node.data)
               if i == 1:
                  self.SEQIN=str(node.data)

   def getJobOutputData(self, Name):
       for i in range(len(Name)):
         for node in Name[i].childNodes:
            if node.nodeType == node.TEXT_NODE:
               if i == 0:
                  self.OUTDIR=str(node.data)
               if i == 1:
                  self.HKLOUT=str(node.data)
               if i == 2:
                  self.XYZOUT=str(node.data)
               if i == 3:
                  self.LOG=str(node.data)
               if i == 4:
                  self.SUMMARY=str(node.data)
 


if __name__ == "__main__":

   document = """\
   <MrBUMPJob>
     <MrBUMPJobInput>
       <MrBUMPJobOptionList name="jobType">
         <MrBUMPJobOptionItem name="isUserModOnly">False</MrBUMPJobOptionItem>
       </MrBUMPJobOptionList>
       <MrBUMPJobParamList name="jobControl">
         <MrBUMPJobParamItem name="JOBID">TEST</MrBUMPJobParamItem>
         <MrBUMPJobParamItem name="LABIN">True</MrBUMPJobParamItem>
         <MrBUMPJobLabinList>
            <MrBUMPJobLabinItem name="F">FTOXD3</MrBUMPJobLabinItem>
            <MrBUMPJobLabinItem name="SIGF">SIGFTOXD3</MrBUMPJobLabinItem>
            <MrBUMPJobLabinItem name="FreeR_flag">FreeR_flag</MrBUMPJobLabinItem>
         </MrBUMPJobLabinList>
       </MrBUMPJobParamList>
       <MrBUMPJobDataList name="jobInputData">
         <MrBUMPJobDataInputItem name="hklIn">/home/rmk65/opt/ccp4/6.1.24-src/ccp4-6.1.24/examples/toxd/toxd.mtz</MrBUMPJobDataInputItem>
         <MrBUMPJobDataInputItem name="seqIn">/home/rmk65/opt/ccp4/6.1.24-src/ccp4-6.1.24/examples/toxd/toxd.seq</MrBUMPJobDataInputItem>
       </MrBUMPJobDataList>
     </MrBUMPJobInput>
     <MrBUMPJobOutput>
       <MrBUMPJobDataList name="jobOutputData">
         <MrBUMPJobDataOutputItem name="outDir">/home/rmk65/projects/ekGUI/results</MrBUMPJobDataOutputItem>
         <MrBUMPJobDataOutputItem name="hklOut">/home/rmk65/projects/ekGUI/results/_mrbump_output.mtz</MrBUMPJobDataOutputItem>
         <MrBUMPJobDataOutputItem name="xyzOut">/home/rmk65/projects/ekGUI/results/_mrbump_output.pdb</MrBUMPJobDataOutputItem>
         <MrBUMPJobDataOutputItem name="log">/home/rmk65/projects/ekGUI/results/_mrbump_output.log</MrBUMPJobDataOutputItem>
         <MrBUMPJobDataOutputItem name="summary">/home/rmk65/projects/ekGUI/results/_balbes_output.xml</MrBUMPJobDataOutputItem>
       </MrBUMPJobDataList>
     </MrBUMPJobOutput>
   </MrBUMPJob>
   """
 
   # Open a link to the XML input
   inXML=readXMLInput()

   # Read the XML input 
   doc=inXML.getDocumentFromString(name=document)
 
   # Get the run options
   inXML.getOptions(doc.getElementsByTagName("MrBUMPJobOptionItem"))
   
   # Get the job input files
   inXML.getJobInputData(doc.getElementsByTagName("MrBUMPJobDataInputItem"))
   
   # Get the job output details
   inXML.getJobOutputData(doc.getElementsByTagName("MrBUMPJobDataOutputItem"))
   
   # Get the job control options
   inXML.getJobControl(doc.getElementsByTagName("MrBUMPJobParamItem"))
   
   if inXML.LABIN:
      # Get the LABIN keywords
      inXML.getLABIN(doc)
   else:
      # Set them to defaults
      inXML.ColLabels["F"] = "F"
      inXML.ColLabels["SIGF"] = "SIGF"
      inXML.ColLabels["FREE"] = "FreeR_flag"

   sys.stdout.write("Input MTZ file:\n  %s\n" % inXML.HKLIN)
