#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface xml_utils.tcl
#
#
# Utilities used for reading XML files
#
# Created Feb02 by Peter Briggs, Martyn Winn
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities used for reading XML files (src/xml_utils.tcl)
#d_intro_title Utilities used for reading XML files
#d_intro These utilities are used for dealing with specific XML output \
from specific CCP4 programs.

# PJX This is a horrible piece of code which should be made redundant
# by using namespaces and package loading properly in the next
# revision of CCP4i.
package ifneeded xml 1.9 {
  source [file join $env(CRANK) bin sgml.tcl]
  source [file join $env(CRANK) bin xml.tcl]
}

# Make sure that the xml commands are available
package require xml 1.9

#---------------------------------------------------------------------
proc XmlStatus { } {
#---------------------------------------------------------------------
#d_sum Query/return status of XML switch in CCP4i preferences
#d_desc Returns the current value of the XML_OUTPUT logical parameter \
in the user's preferences. If XML_OUTPUT is not defined in the \
preferences then 0 is returned.
   global preferences
   if { [info exists preferences(XML_OUTPUT)] } {
     return $preferences(XML_OUTPUT)
   }
   return 0
}

#---------------------------------------------------------------------
proc XmlDataLoaded { xmlfile } {
#---------------------------------------------------------------------
#d_sum Check whether data from an XML file has been loaded into xmldata
#d_desc Returns 1 if data from the named XML file has already been \
parsed and loaded into the xmldata array, otherwise returns 0
#d_arg xmlfile Full pathname of the XML file to check
  global xmldata
  if {![ElementExists xmldata XML_LOADED] } {
    return 0
  } elseif { $xmldata(XML_LOADED) == 0} {
    return 0
  } elseif { $xmldata(XML_FILE) != $xmlfile} {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
proc XmlDataReset { } {
#---------------------------------------------------------------------
#d_sum Reset the status of xmldata force rereading of XML files
#d_desc Resets XML_LOADED to zero, to force rereading of XML files \
next time data is requested.
  global xmldata
  set xmldata(XML_LOADED) 0
}

#---------------------------------------------------------------------
proc GetXmlAttributeValue { attlist attribute } {
#---------------------------------------------------------------------
#d_sum Return the value of an XML attribute
#d_desc Returns the values an XML attribute given the attribute list \
passed to the handling commands by the XML parser. If the attribute \
cannot be found in the list, or if no corresponding value can be \
found then an empty string is returned.
#d_arg attlist Attribute list passed from the XML parser
#d_arg attribute The attribute whose value is required
  set position [lsearch -exact $attlist $attribute]
  if { $position < 0 } {
    return ""
  }
  if { [incr position] == [llength $attlist] } {
    return ""
  }
  return [string trim [lindex $attlist $position]]
}

#---------------------------------------------------------------------
proc GetCCP4XmlData { xmlfile element } {
#---------------------------------------------------------------------
#d_sum Return data extracted from a CCP4 XML file
#d_desc Returns the value of an element in the xmldata global array \
which is populated by parsing the named CCP4 XML file.
#d_arg xmlfile Full path name of the CCP4 XML file
#d_arg element Name of the element in the array of which to return the value
   global xmldata

   # Valid string?
   if { [string trim $element] == "" } {
     return ""
   }

   # Check whether the data from this file has been loaded already
   if {![XmlDataLoaded $xmlfile]} {
     ccp4_parse_xmlfile $xmlfile
   }

   # Return the element
   if {[ElementExists xmldata $element]} {
     return $xmldata($element)
   }
   return ""
}

#---------------------------------------------------------------------
proc ccp4_parse_xmlfile { xmlfile } {
#---------------------------------------------------------------------
#d_sum Extract information from CCP4 XML files
#d_desc Parse a CCP4 XML file and load the data into \
the global array xmldata.
#d_desc This is a generic version which will read any XML file.
#d_arg xmlfile Full path name of the XML file to be parsed.
  global xmldata

  # Initialise and configure the XML parser
  set parser [ xml::parser ]
  $parser configure -elementstartcommand HandleStartCCP4Xml
  $parser configure -elementendcommand HandleEndCCP4Xml

  # Read and parse the specified file
  if { [ReadFile $xmlfile xmltext] } {
     $parser parse $xmltext
     set xmldata(XML_FILE) $xmlfile
     set xmldata(XML_LOADED) 1
  } else {
     # Couldn't load the data
     set xmldata(XML_LOADED) 0
  }
}

#---------------------------------------------------------------------
proc HandleStartCCP4Xml { name attlist } {
#---------------------------------------------------------------------
#d_sum Internal parsing procedure for processing CCP4 XML files
#d_desc See also HandleEndCCP4Xml
#d_arg name Name of the XML element
#d_arg attlist Attribute list for that element
  global xmldata

  # Each arm of the switch statement deals with a different
  # element in a CCP4 XML file
  switch $name {
      almn_run {
          # ALMN output
	  # Element <almn_run>
	  set xmldata(almn_run) 1
      }
      ALMN {
          # ALMN output
	  # Element <ALMN ccp4_version=... date=...>
	  set xmldata(ALMN) 1
          set xmldata(ALMN_ccp4_version) \
		  [GetXmlAttributeValue $attlist ccp4_version]
	  set xmldata(ALMN_date) [GetXmlAttributeValue $attlist date]
      } 
      reindex_operator {
          # ALMN output
	  # Element <reindex_operator required=... operator=...>
	  set xmldata(reindex_operator) 1
	  set xmldata(reindex_operator_required) \
		  [GetXmlAttributeValue $attlist required]
	  set xmldata(reindex_operator_operator) \
		  [GetXmlAttributeValue $attlist operator]
      }
      matthews_run {
          # MATTHEWS output
          # Element <matthews_run>
          set xmldata(num_results) 0
      }
      result {
          # MATTHEWS output
          # Element <result nmol_in_asu=... percent_solvent=...>
          incr xmldata(num_results)
          set xmldata(nmol_[subst $xmldata(num_results)]) \
		  [GetXmlAttributeValue $attlist "nmol_in_asu"]
          set xmldata(persolv_[subst $xmldata(num_results)]) \
		  [GetXmlAttributeValue $attlist "percent_solvent"]
      } 
      peakmax_run {
          # MR_ANALYSE output
          # Element <peakmax_run>
          set xmldata(peakmax_num_results) 0
      }
      peakmax_result {
          # MR_ANALYSE data output
          # Element <peakmax_run ...>
          incr xmldata(peakmax_num_results)
          set xmldata(peakmax_height_[subst $xmldata(peakmax_num_results)]) \
		  [GetXmlAttributeValue $attlist "height_over_rms"]
          set xmldata(peakmax_frac_x_[subst $xmldata(peakmax_num_results)]) \
		  [GetXmlAttributeValue $attlist "peak_frac_x"]
          set xmldata(peakmax_frac_y_[subst $xmldata(peakmax_num_results)]) \
		  [GetXmlAttributeValue $attlist "peak_frac_y"]
          set xmldata(peakmax_frac_z_[subst $xmldata(peakmax_num_results)]) \
		  [GetXmlAttributeValue $attlist "peak_frac_z"]
      }
      *  {
	  # Catch-all generic element - do nothing
	  return 0
      }
  }
  return 1
}

#---------------------------------------------------------------------
proc HandleEndCCP4Xml { name } {
#---------------------------------------------------------------------
#d_sum Internal parsing procedure for processing CCP4 XML files.
#d_desc See also HandleStartCCP4Xml
#d_arg name Name of the XML element
  global xmldata

  switch $name {
       almn_run { 
	   # Do nothing
       }
       ALMN {
	   # Do nothing
       }
       reindex_operator {
	   # Do nothing
       }
       matthews_run {
           # Originally contained the code for calculating
           # nmol_ideal which is now in GetMolrepNMonomers
           # so ... Do nothing!
       }
       * {
	   # Unrecognised closing element
	   return 0
       }
  }
  return 1
}
#---------------------------------------------------------------------
proc GetAlmnReindexOp { xmlfile } {
#---------------------------------------------------------------------
#d_sum Return a reindexing operator from an ALMN XML output file
#d_desc If ALMN has produced an XML output file then this command \
returns the reindexing operator specified in the attribute list of \
the reindex_operator element.
#d_desc If no reindexing operator is specified then the command \
returns None. If there is an error reading the XML file then an \
empty string is returned.
#d_arg xmlfile The full path name of the ALMN XML file to be read.

  set reindex_required [GetCCP4XmlData $xmlfile reindex_operator_required]
  if { $reindex_required == "yes" } {
     set reindex_op [GetCCP4XmlData $xmlfile reindex_operator_operator]
  } elseif { $reindex_required == "no" } {
     set reindex_op "None"
  } else {
     set reindex_op ""
  }
  return $reindex_op
}

#---------------------------------------------------------------------
proc GetMolrepNMonomers { xmlfile } {
#---------------------------------------------------------------------
#d_sum Return the ideal number of monomers from Matthews XML output
#d_desc Returns the ideal number of monomers based on data extracted \
from the Matthews XML output file. The Matthews results are analysed \
and the number of monomers giving a solvent content closest to 50% \
is returned as the ideal number of monomers in the asu.
#d_arg xmlfile Full path name of the Matthews XML file

   # Default ideal number is one
   set nmol_ideal 1
   set ideal_solc 50
   set max_diff_solc 100

   # Fetch total number of results from the Matthews XML file
   if { [set n_results [GetCCP4XmlData $xmlfile num_results]] == "" } {
     # Probably ought to return an error instead? but ...
     return ""
   }

   # Loop over the results and find the number of monomers giving
   # solvent content closest to 50 percent
   for { set i 1 } { $i <= $n_results } { incr i } {
     set solc [GetCCP4XmlData $xmlfile persolv_[subst $i]]
     set diff_solc [expr abs($solc - $ideal_solc)]
     if { $diff_solc < $max_diff_solc } {
       set max_diff_solc $diff_solc
       set nmol_ideal [GetCCP4XmlData $xmlfile nmol_[subst $i]]
     }
   }
   return $nmol_ideal
}

#---------------------------------------------------------------------
proc GetMolrepPseudoTransPeak { xmlfile } {
#---------------------------------------------------------------------
#d_sum Return peak number of pseudotranslation from mr_analyse XML file
#d_desc Returns the peak number of pseudotranslation extracted from an XML \
file written by the mr_analyse task
#d_arg xmlfile Full path name of the mr_analyse XML file

   # threshold for pseudo-translation peak
   set threshold 0.3

   # default is no pseudo-translation vector
   set pst_peak 0

   # Fetch total number of results from the mr_analyse XML file
   if { [set n_results [GetCCP4XmlData $xmlfile peakmax_num_results]] == "" } {
     # Probably ought to return an error instead? but ...
     return 0
   }

   # first result should be origin peak
   set origin_height [GetCCP4XmlData $xmlfile peakmax_height_1]

   # Loop over the results and identify pseudo-translation peak
   for { set i 2 } { $i <= $n_results } { incr i } {
     set height [GetCCP4XmlData $xmlfile peakmax_height_[subst $i]]
     set rel_height [expr $height / $origin_height]
   # pseudo-translation peaks should have significant height
     if { $rel_height > $threshold } {
       set pst_peak $i
       break
     }
   }

   return $pst_peak
}

#---------------------------------------------------------------------
proc GetMolrepPseudoTrans { xmlfile peak_no } {
#---------------------------------------------------------------------
#d_sum Return pseudotranslation vector from mr_analyse XML file
#d_desc Returns the pseudotranslation vector extracted from an XML \
file written by the mr_analyse task
#d_arg xmlfile Full path name of the mr_analyse XML file

return [list [GetCCP4XmlData $xmlfile peakmax_frac_x_[subst $peak_no] ] \
             [GetCCP4XmlData $xmlfile peakmax_frac_y_[subst $peak_no] ] \
             [GetCCP4XmlData $xmlfile peakmax_frac_z_[subst $peak_no] ] ]
}
