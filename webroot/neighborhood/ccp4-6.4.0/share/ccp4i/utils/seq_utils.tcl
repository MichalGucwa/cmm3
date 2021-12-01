#
#     Copyright (C) 2006 Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface seq_utils.tcl
#
#
# Sequence Handling Utilities
#
# See also:
#         tasks/modeller.tcl: modeller_read_aln
#                             modeller_read_aln2
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities used for reading sequence files (utils/seq_utils.tcl)
#d_intro_title Utilities used for reading sequence files
#d_intro These utilities are used for obtaining sequence files, e.g. from \
remote databases, and for checking sequence files, in particular dealing with \
the myriad formats.

#=========================================================================
# Download sequence file from remote database
# Taken from tasks/get_prot.tcl
#=========================================================================

proc DownloadSequence { local_fileout logfile database_url seq_code } {
#d_sum Download sequence file from remote database
#d_desc Given a sequence code, such as a SwissProt code, this will retrieve the \
sequence from a remote database and store in a local file. It uses the Tcl \
procedure http::geturl
#d_arg local_fileout Local file to write sequence to.
#d_arg logfile Log file for writing diagnostics and error messages.
#d_arg database_url URL of remote database (defaults to "www.ebi.ac.uk/cgi-bin/swissfetch")
#d_arg seq_code Code for the requested sequence, e.g. a SwissProt code.

   global configure
   package require http

   if { ![OpenFile $local_fileout fout w ] } { 
     WriteFile $logfile "Cannot open output file $local_fileout"
     return 0 
   }
   if { $database_url == "" } {
     set database_url "www.ebi.ac.uk/cgi-bin/swissfetch"
   }
   set url $database_url 
   append url "?" $seq_code

   WriteFile $logfile "connecting ... "

   http::config -proxyhost $configure(PROXY) -proxyport $configure(PORT) 

   set token [http::geturl $url -progress progress \
	    -headers {Pragma no-cache} -channel $fout \
	    -timeout 20000]

   upvar #0 $token state
   WriteFile $logfile "state: $state(http)"
   foreach {key value} $state(meta) {
   }

   return 1
}

proc progress { token total current } {
#d_sum Dummy routine used by DownloadSequence
#d_desc Dummy routine used by DownloadSequence
#d_arg token Passed by http::geturl
#d_arg total Passed by http::geturl
#d_arg current Passed by http::geturl
#    puts -nonewline "."
}


#-----------------------------------------------------------------------------
proc ReadSequence { seqfile sequenceVar nresVar } {
#-----------------------------------------------------------------------------
#d_sum Read a sequence file
#d_desc Skip lines beginning (> , # or ;   Ignore all white space and \
characters except range A to Z 
#d_arg seqfile Input sequence file
#d_arg sequenceVar Return text string with one letter sequence code
#d_arg nresVar Returned number of residues

  upvar $sequenceVar sequence
  upvar $nresVar nres

  set sequence {}
  set nres 0

  if { ![ReadFile $seqfile text -split] } { return 0 }

  foreach line $text {
    if { ![regexp {^(>|#|;)} $line ] } {
      regsub {[^A-Z]} [string trim [string toupper $line]] {} ll
      if { [set l [string length $ll]] > 0 } {
        append sequence $ll \n
        incr nres $l
      }
    }
  }
  return 1
}

#------------------------------------------------------------------------
proc CheckFormatClustalw { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to Clustalw format
#d_desc The given sequence file is opened and certain elements of the Clustalw format \
are looked for, such as the CLUSTAL keyword. This is a sanity check rather than \
being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has Clustal format.
  # First line and only line of header starts with "CLUSTAL"
  # Then blank lines followed by interleaved sequences

  if { ![ReadFile $seqfile output_text -split ]} {
      PleaseWait
      WarningMessage "Clustal file not present or cannot be read"
      return 0
  }

  set first_line [lindex $output_text 0]
  if { ![regsub {CLUSTAL} $first_line {} name ] } { 
     PleaseWait
     WarningMessage "Format error in ALN/Clustal file.\nNo CLUSTAL keyword."
     return 0
  }

  return 1
}

#------------------------------------------------------------------------
proc CheckFormatMSF { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to MSF/GCG format
#d_desc The given sequence file is opened and certain elements of the MSF/GCG format \
are looked for, such as the "//" separating lines. This is a sanity check rather \
than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has MSF/GCG  format.
  # Begins with a header.
  # "Name:" lines list sequences included in the alignment.
  # "//" separating line.
  # Interleaved sequences.
  # Sequences may be non-contiguous, e.g. groups of 10 residues

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "MSF file not present or cannot be read"
      return 0
  }

  set is_msf 0
  # This just checks there is a line with //
  foreach line $output_text {
      if { [regsub {//} $line {} name ] } { 
         set is_msf 1
      }
  }

  if {$is_msf == 0} {
      PleaseWait
      WarningMessage "Format error in MSF file.\nNo // separating line."
      return 0
  }

  return 1
}

#------------------------------------------------------------------------
proc CheckFormatPhylip { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to Phylip format
#d_desc The given sequence file is opened and certain elements of the Phylip format \
are looked for. This is a sanity check rather than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has Phylip format.
  # First line has 2 numbers: number of sequences, and length of alignment.
  # Followed by interleaved sequences.
  # Sequences may be non-contiguous, e.g. groups of 10 residues

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "Phylip file not present or cannot be read"
      return 0
  }

  return 1
}

#------------------------------------------------------------------------
proc CheckFormatBlast { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to Blast format
#d_desc The given sequence file is opened and certain elements of the Blast format \
are looked for. This is a sanity check rather than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has Blast format.

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "Blast file not present or cannot be read"
      return 0
  }

  return 1
}
#------------------------------------------------------------------------
proc CheckFormatOCA { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to OCA format
#d_desc The given sequence file is opened and certain elements of the OCA format \
are looked for. This is a sanity check rather than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has OCA format.

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "OCA file not present or cannot be read"
      return 0
  }

  return 1
}

#------------------------------------------------------------------------
proc CheckFormatPIR { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to PIR format
#d_desc The given sequence file is opened and certain elements of the PIR format \
are looked for, such as P1 on the first line and "*" after sequences. This is \
a sanity check rather than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has PIR format.
  # First line is ">P1;" followed by the protein code
  # Second line is 10 fields separated by colons.
  # The first 8 chars of the first field should be "structur" or "sequence"
  # but we don't enforce this: modeller expects it, but clustalw doesn't
  # provide it.
  # Subsequent lines are the sequence, terminated by "*"

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "PIR file not present or cannot be read"
      return 0
  }

  set in_sequence 0
  set namelist {}

  # This just checks there are a set of sequences enclosed
  # by ">P1;" and "*"
  foreach line $output_text {
      if { [regsub {>P1;} $line {} name ] } { 
          if {$in_sequence} {
            PleaseWait
            WarningMessage "Format error in PIR file.\nNo closing * for sequence."
            return 0
          } else {
	    lappend namelist $name 
            set in_sequence 1
          }
      } 
      if { [regsub {\*} $line {} line2 ] } { 
          if {$in_sequence} {
            set in_sequence 0
          } else {
            PleaseWait
            WarningMessage "Format error in PIR file.\nNo beginning \">P1;\" for sequence."
            return 0
          }
      } 
  }

  if {$in_sequence} {
      PleaseWait
      WarningMessage "Format error in PIR file.\nNo closing * for sequence."
      return 0
  }

  if {[llength $namelist] == 0} {
      PleaseWait
      WarningMessage "Format error in PIR file.\nNo beginning \">P1;\" for sequence."
      return 0
  }

  return 1
}

#------------------------------------------------------------------------
proc CheckFormatFasta { seqfile }  {
#------------------------------------------------------------------------
#d_sum Check whether a given sequence file conforms to Fasta format
#d_desc The given sequence file is opened and certain elements of the Fasta format \
are looked for. This is a sanity check rather than being rigorous.
#d_arg seqfile Name of sequence file.

  # Check alignment file has Fasta format.

  if { ![ReadFile $seqfile output_text ]} {
      PleaseWait
      WarningMessage "Fasta file not present or cannot be read"
      return 0
  }
  
  set is_fasta 0
  # This just checks there is a line with >
  foreach line $output_text {
      if { [regsub {>} $line {} name ] } { 
         set is_fasta 1
      }
  }

  if {$is_fasta == 0} {
      PleaseWait
      WarningMessage "Format error in Fasta file.\nNo line starting with >."
      return 0
  }

  return 1
}
