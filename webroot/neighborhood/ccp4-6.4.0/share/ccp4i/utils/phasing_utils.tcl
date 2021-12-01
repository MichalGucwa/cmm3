#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface phasing_utils.tcl
#
#
# Utilities for Phasing Tasks
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Utilities for Phasing Tasks (utils/phasing_utils.tcl)
#d_intro Mostly used by run scripts for experimental phasing. Only Uniqueify \
may have some general use.
#------------------------------------------------------------------------------
proc ExtractShelxLog { filename attype } {
#------------------------------------------------------------------------------
#d_sum UNTESTED - Extract info from the Shelx log file
#d_desc  This is intended to be used to create a 'crossword table' of \
distances between heavy atom sites.  Need to discuss this with Eleanor.
#d_arg filename Name of shelx log file
#d_arg attype Name of heavy atom type expected in log file

  set patfom_cutoff 80.0
  set symfom_cutoff 80.0
  set readatom 0
  set nsol 0
  set nsoltot 0

  if { ![ReadFile $filename logtext -split] } {
     return 0
  }

  foreach line $logtext {
    if { [regexp CFOM $line] } {
      incr nsoltot
      if { [lindex $line 7] > $patfom_cutoff && [lindex $line 14] > $symfom_cutoff } { 
        set readatom 1
        incr nsol
        set solnum($nsol) [lindex $line 1]
        set cfom($nsol) [lindex $line 4]
        set patfom($nsol) [lindex $line 7]
        set correl($nsol) [lindex $line 11]
        set symfom($nsol) [lindex $line 14]
        lappend cfom_list $cfom($nsol)
        lappend correl_list $correl($nsol)
        set natoms 0
        set dist_list($nsol) ""
      } else {
        set readatom 0
      }
    } elseif { $readatom && [regexp {^$attype} [string trimleft $line] ] } {
      incr natoms
      lappend atom_score [lrange $line 1]
      lappend xyz($nsol) [lrange $line 2 5]
      lappend dist_list($nsol) [lrange $line 6 end]
    }
  }

  sortorder $cfom_list cfom_order

  puts "nsol $nsol nsoltot $nsoltot"
  puts "cfom_list $cfom_list"
  puts "cfom_order $cfom_order"
  puts "dist_list $dist_list"

}

#------------------------------------------------------------------------------
proc MakeShelxDismat { dist_list dismatVar } {
#------------------------------------------------------------------------------
#d_sum Convert the distance list from shelx log file into a neat distance matrix
  upvar $dismatVar dismat
  set dismat {}

  set nat [llength $dist_list]
  set dismat {}

  for { set n 0 } { $n < $nat } { incr n } {
    set line {}
    for { set m 0 } { $m < $nat } { incr m } {
      if { $m > $n } {
        lappend line [lindex [lindex $dist_list $m] [expr $m - $n] ]
      } else {
        lappend line [lindex [lindex $dist_list $n ] [expr $n - $m ] ]
      }
    }
#    puts $line
    lappend dismat $line
  }
}


#---------------------------------------------------------------------------
proc NpoMapScale { space_group cell N_SECTIONS axes_list NPO_MAX_SIZE \
	NPO_SCALEVar } {
#---------------------------------------------------------------------------
#d_sum Devise scale for NPO plots with orthogonal sections on same scale
#d_arg space_group space group
#d_arg cell Unit cell
#d_arg N_SECTIONS Not used
#d_arg axes_list List of axes along with sections are required (as X, Y or Z)
#d_arg NPO_MAX_SIZE Maximum acceptable size of plot
#d_arg NPO_SCALEVar Returned proposed scale

upvar $NPO_SCALEVar NPO_SCALE

# Work out reasonable scale for NPO plots so orthogonal sections still
# on same scale

  set asym_unit [GetAsymUnit $space_group]

# Trap case where asym_unit is null because SG not in crystal.lib

  if { $asym_unit == ""} {
    set asym_unit "0.0 1.0 0.0 1.0 0.0 1.0"
  }

# Work out the longest map axis (ignore that its not orthonormal etc)
# NB If plotting Z section then length of z-axis not important

  for { set i 0 } { $i <= 2 } { incr i } { set getlen($i)  0 }
  foreach axes $axes_list {
    if { [regexp X axes ] } {
      set getlen(1) 1; set getlen(2) 1
    } elseif { [regexp Y axes ] } {
      set getlen(0) 1; set getlen(2) 1
    } else {
      set getlen(0) 1;set getlen(1) 1
    }
  }
   
  set max_length 0.0
  for { set i 0 } { $i <= 2 } { incr i } {
    if { $getlen($i) } {
      set max_length [ max $max_length \
     [expr [lindex $cell $i] * [lindex $asym_unit [expr ($i * 2) + 1] ] ] ]
    }
  }
  set NPO_SCALE [expr $NPO_MAX_SIZE * 10.0 / $max_length ]

  return 1

}

#----------------------------------------------------------------------
proc FindScaleitDiff { HKLIN F1 SIG1 F2 SIG2 diffVar } {
#----------------------------------------------------------------------
#d_sum Run scaleit to find optimal value for exclude cutoff for Patterson
#d_arg HKLIN Input MTZ file
#d_arg F1 Input MTZ FP column
#d_arg SIG1 Input MTZ SIGFP column
#d_arg F2 Input MTZ FPH column
#d_arg SIG2 Input MTZ SIGFPH column
#d_arg diffVar Returned proposed exclude difference cutoff

  upvar $diffVar diff

  WriteToLog "Running Scaleit program to get statistics on isomorphous differences" -nofoot

# Run scaleit ot find optimal value for exclude cutoff
  set N_DERIVS 1
  set LABIN_FP "FP SIGFP"
  set LABIN_FPH "FPH SIGFPH"
  set FP $F2
  set SIGFP $SIG2
  set FPH(1) $F1
  set SIGFPH(1) $SIG1
  set tmp_log [GetTmpFileName -ext log]
  CreateComScript scaleit scaleit_script
  set status [ Execute "[BinPath scaleit] HKLIN \"$HKLIN\""  \
      $scaleit_script program_status report -log $tmp_log ]
  if { [ReadFile $tmp_log text]}   {
    ExtractTextLine $text "Isomorphous Differences" 0 0 tt
    ExtractTextLine - "acceptable differences" 0 6 diff
    WriteToLog "Acceptable isomorphous differences $diff" -noheader
    return 1
  } else {
    return 0 
  }
}

#-----------------------------------------------------------
proc scaleit_analysis { mode arrayname log { n {}} { m {}} } {
#-----------------------------------------------------------
#d_sum Extract date from scaleit log file for correlation analysis
#d_arg mode Can be all, pair or disp
#d_arg arrayname Name of array used to carry output data
#d_arg log  Name of input log file
#d_arg n Optional identifier for the first dataset in pairwise analysis
#d_arg m Optional identifier for the ssecond dataset in pairwise analysis

  upvar #0 $arrayname array

  if { ![ReadFile $log logtext] } { return 0 }

  switch $mode \
  all {

  set anomalous 0
  if { [ExtractTextLine $logtext \
         "RMS  anomalous   difference" 0 all data ] } { set anomalous 1 }

  if [ExtractTextLine $logtext "SCALEIT" 0 all data] {

    while { [ExtractTextLine - \
      "RMS  isomorphous difference" 0 [list 5 7] data ]  } {
      set nn [lindex $data 0]
      set array(RMS,$nn,1) [lindex $data 1]
      if { $anomalous && [ExtractTextLine - \
         "RMS  anomalous   difference" 0 [list 5 7] adata] } {
        set array(RMS,$nn,2) [lindex $adata 1]
      }
    }
  }

  set nn 1
  ExtractTextLine $logtext "SCALEIT" 0 all data
  while { $nn <= 20 && [ExtractTextLine - "THE TOTALS" 0 all data ] } {
    incr nn
    if { [llength $data] == 16 } {
      set array(nref,1,$nn) [expr int([lindex $data 2])]
      set array(NRiso,1,$nn) [lindex $data 6]
      set array(maxDiso,1,$nn) [lindex $data 10]
      set array(maxDano,1,$nn) [lindex $data 14]
    } else {
      set array(nref,1,$nn) 0
      set array(NRiso,1,$nn) 0.0
      set array(maxDiso,1,$nn) 0.0
      set array(maxDano,1,$nn) 0.0
    }
    set array(nref,$nn,1) $array(nref,1,$nn)
    set array(NRiso,$nn,1) $array(NRiso,1,$nn)
    set array(maxDiso,$nn,1) $array(maxDiso,1,$nn)
    set array(maxDano,$nn,1) $array(maxDano,1,$nn)
  }
  

  } pair {

    if { [ExtractTextLine $logtext "Centric Normal probability " 0 all data] &&
    [ExtractTextLine - "Total " 0 all data ] } {
      if [regexp cen $data ] {
        set array(NprobC,$n,$m) [lindex $data 7]
      } else {
        set array(NprobC,$n,$m) [lindex $data 6]
      }
    } else {
      set array(NprobC,$n,$m) 0.0
    }
    set array(NprobC,$m,$n) $array(NprobC,$n,$m)

    if { [ExtractTextLine $logtext "Acentric Normal probability " 0 all data] &&
         [ExtractTextLine - "Total " 0 all data ] } {
      if [regexp cen $data ] {
        set array(NprobA,$n,$m) [lindex $data 7]
      } else {
        set array(NprobA,$n,$m) [lindex $data 6]
      }
    } else {
      set array(NprobA,$n,$m) 0.0
    }
    set array(NprobA,$m,$n) $array(NprobA,$n,$m)

    if [ExtractTextLine - "THE TOTALS" 0 [list 2 6] data ] {
      set array(nref,$n,$m) [expr int([lindex $data 0])]
      set array(NRiso,$n,$m) [lindex $data 1]
      set array(nref,$m,$n) $array(nref,$n,$m)
      set array(NRiso,$m,$n) [lindex $data 1]
    } else {
      set array(nref,$n,$m) 0.0
      set array(NRiso,$n,$m) 0.0
      set array(nref,$m,$n) 0.0
      set array(NRiso,$m,$n) 0.0
    }

  } disp {

# Get the dispersive difference data - save as array(disp,?,n) where:
# ? = 1 number of centric reflections
#   = 2 Normprob for centric reflections
#   = 3 number of acentric reflections
#   = 4 Normprob for acentric reflections
#   = 5 Rfactor

    if { [ExtractTextLine $logtext "Centric Normal probability " 0 all data]  && 
     [ExtractTextLine - "Total " 0 all data] } {
      if [regexp cen $data] {
        set array(disp,$n,1) [expr int([lindex $data 2])]
        set array(disp,$n,2) [lindex $data 7]
      } else {
        set array(disp,$n,1) [expr int([lindex $data 1])]
        set array(disp,$n,2) [lindex $data 6]
      }
    } else {
      set array(disp,$n,1) 0
      set array(disp,$n,2) 0.0
    }
    
    if { [ExtractTextLine $logtext "Acentric Normal probability " 0 all data ] &&
    [ExtractTextLine - "Total " 0 all data] } {
      if [regexp cen $data] {
        set array(disp,$n,3) [expr int([lindex $data 2])]
        set array(disp,$n,4) [lindex $data 7]
      } else {
        set array(disp,$n,3) [expr int([lindex $data 1])]
        set array(disp,$n,4) [lindex $data 6]
      }
    } else {
      set array(disp,$n,3) 0
      set array(disp,$n,4) 0.0
    }
   

    if [ExtractTextLine - "THE TOTALS" 0 6 data] {
      set array(disp,$n,5) [lindex $data 0]
    } else {
      set array(disp,$n,5) 0.0
    }
  }
}

#------------------------------------------------------------------------
proc scaleit_write_tab { arrayname tab nsets disp_diff } {
#------------------------------------------------------------------------
#d_sum  Write the summary of the scaleit log file(s) to the table file
#d_arg arrayname Name of array used to carry analysis data
#d_arg tab name of the table output file
#d_arg nset Number of sets of derivative data
#d_arg disp_diff Logical 1= output anomalous differences table

  upvar #0 $arrayname array
  global job_params

  set nsetsp1 [expr $nsets + 1 ]

  set text ""
  append text \n \
"     Scaleit Summary for Project $job_params(PROJECT) Job $job_params(JOB_ID)"
  append text \n \n \
"        Input MTZ: $array(hklin)" \n \n
  

# Set up list of the data items to use as row/column labels
  set setlabels $array(FP)
  for { set n 1 } { $n <= $nsets } { incr n } { 
    lappend setlabels "[lindex $array(data,$n) 0]"
    lappend setlabelsFD "[lindex $array(data,$n) 2] v [lindex $array(data,$n) 3]"
  }

  append text \n \n " Table: RMS differences" \
    " RMSiso is for FPHi v. FP = $array(FP)" \
    " RMSano is for DPHi" \n \n

  WriteTable $arrayname RMS 2 $nsets "RMS differences" \
	[list "RMSiso" "RMSano"] [lrange $setlabels 1 end] \
          15 12 12.2f text 

  append text \n \n \
    " Table: Number of reflections" \n \n

  WriteTable $arrayname nref $nsetsp1 $nsetsp1 "#reflections" \
	$setlabels $setlabels  \
	15 12 12i text -nodiag

  append text \n \n " Table: The Rfactor" \n \n

  WriteTable $arrayname NRiso $nsetsp1 $nsetsp1 "Riso" \
	$setlabels $setlabels  \
	15 12 12.3f text -nodiag

  if [ElementExists $arrayname NprobA,1,2 ] {

  append text \n \n " Table: Normal Probability for acentric data" \n  \n

  WriteTable $arrayname NprobA $nsetsp1 $nsetsp1 "Normal Prob." \
	$setlabels $setlabels  \
	15 12 12.3f text -nodiag

  }

  if [ElementExists $arrayname NprobC,1,2 ] {

  append text \n \n " Table: Normal Probability for Centric data" \n  \n

  WriteTable $arrayname NprobC $nsetsp1 $nsetsp1 "Normal Prob." \
        $setlabels $setlabels  \
        15 12 12.3f text -nodiag

  }


  if $disp_diff {

  append text \n\n " Table: Anomalous Differences ( FPHi+ v. FPHi-)" \n\n

  WriteTable $arrayname disp 5 $nsets  "Anom difference" \
   [list nref_cent Prob_cent nref_acent Prob_acent Rfactor ] \
	$setlabelsFD 25 12 [list 12i 12.3f 12i 12.3f 12.3f] text

  }

  if [OpenFile $tab f w] {
    puts $f $text
    CloseFile $f
    return 1
  } else {
    return 0
  }
}

#---------------------------------------------------------------------------
proc Uniqueify { HKLIN HKLOUT args } {
#---------------------------------------------------------------------------
#d_sum Run the Tcl version of 'uniqueify' script to standardise MTZ and add FreeR column
#d_arg HKLIN Input MTZ file
#d_arg HKLOUT Output MTZ file
#d_opt0 -extend RESOLUTION_MAX
#d_opt1 Extend the resolution to RESOLUTION_MAX
#d_opt0 -import IMPORT_FREER_MTZ IMPORT_FREER_LABIN
#d_opt1 Import the FreeR column from another MTZ file
#d_opt0 -keep LABIN_FREER
#d_opt1 Keep the FreeR column in the input file
#d_opt0 frac -FREER_FRACTION
#d_opt1 Override the usual fraction for FreeR reflections (0.05)
#d_opt0 -sysa
#d_opt1 Keep the systematically absent reflections in the MTZ file

  set EXTEND_RESOLUTION 0
  set RESOLUTION_MAX ""
  set FREER_FRACTION 0.05
  set INCL_SYS_ABS ""


# FREER_MODE 1=keep existing FreeR data
#            2=generate FreeR data
#            3=copy FreeR data from another MTZ file

  set FREER_MODE 2

  set nargs [llength $args]; set n 0
  while { $n < $nargs } { 
    switch -regexp -- [lindex $args $n] \
    extend {
      set EXTEND_RESOLUTION 1
      incr n; set RESOLUTION_MAX [lindex $args $n]
    } copy {
      set FREER_MODE 3
      incr n; set IMPORT_FREER_MTZ [lindex $args $n]
      incr n; set IMPORT_FREER_LABIN [lindex $args $n]
    } keep {
      set FREER_MODE 1
      incr n; set LABIN_FREER [lindex $args $n]
    } frac {
      incr n; set FREER_FRACTION [lindex $args $n]
    } sysa {
      set INCL_SYS_ABS SYSABS_KEEP
    }
  incr n
  }

# Get some temporary file names

  set temp1 [GetTmpFileName -ext mtz ]
  set temp2 [GetTmpFileName -ext mtz ]
  set temp3 [GetTmpFileName -ext mtz ]

# From the input MTZ file , extract what `unique' needs and then feed it:

  set mtzdmp_log [GetTmpFileName ]
  WriteComFile mtzdump_script "NREF 0\nSYMMETRY\nEND"

  set status [ Execute "[BinPath mtzdump] HKLIN \"$HKLIN\"" $mtzdump_script \
	program_status report -nocomments -copy_log $mtzdmp_log]

#
# Get the key parameters from the mtzdmp log file
#

  ReadFile $mtzdmp_log mtzdmp_text
  DeleteFile $mtzdmp_log

  set cell 		[ExtractFromText $mtzdmp_text "Cell Dimensions" 2 \
						[list 0 1 2 3 4 5 ] ]
  set resolution 	[ExtractFromText - "Resolution Range" 2  [list 3 5 ] ]
  set t0        	[ExtractFromText -  "Space Group ="  0 all  ]
  set space_group       [lrange $t0 5 end]
  set resolution_min [lindex $resolution 0]
  set resolution_max [lindex $resolution 1]

# if FREE column to be used, check it is valid
  if { $FREER_MODE == 1 } {
    set free_limits       [ExtractFromText - $LABIN_FREER 0 [list 2 3 ] ]
    set free_min          [lindex $free_limits 0]
    set free_max          [lindex $free_limits 1]
    if { $free_min == $free_max } {
      WriteToLog "Problem with FREE column in input file. All flags apparently identical.\nCheck input file." 
      TerminateScript 0
    }
  }
#
# run Unique
#
  if { $EXTEND_RESOLUTION } { set resmax $RESOLUTION_MAX } else {
		set resmax $resolution_max }
	
  WriteComFile unique_script \
"CELL $cell
SYMMETRY $space_group
LABOUT F=FUNI SIGF=SIGFUNI
RESOLUTION $resmax"


  set status [ Execute "[BinPath unique] HKLOUT \"$temp1\"" \
                  $unique_script program_status report ]


if { $FREER_MODE == 1 || $FREER_MODE == 3 } {

#
#   Add this list to your existing F and SIGF and FREE
#

  set text "$INCL_SYS_ABS\nLABIN FILE 1  ALLIN\nLABIN FILE 2  ALLIN\n"
  if { $FREER_MODE == 3 } { append text "LABIN FILE 3 E1 = $IMPORT_FREER_LABIN\n" }
#  append text "RESOLUTION OVERALL $resolution_min $resmax\n"
  append text END

  WriteComFile cad_script "$text"

 set cmd "[BinPath cad] HKLIN2 \"$temp1\" HKLIN1 \"$HKLIN\" HKLOUT \"$temp2\""
 if { $FREER_MODE == 3  } { 
   append cmd " HKLIN3 \"$IMPORT_FREER_MTZ\"" 
   set LABIN_FREER $IMPORT_FREER_LABIN
 }

 set status [ Execute $cmd $cad_script program_status report ]

#
#  Extend FREE flags for extra hkl
#
  WriteComFile freer_script "COMPLETE FREE=$LABIN_FREER\nEND"

  set status [ Execute "[BinPath freerflag] HKLIN \"$temp2\" \
                     HKLOUT \"$temp3\"" \
                     $freer_script program_status report ]

#
#  mtzutils to get rid of useless UNIQUE labels, FUNI and SIGFUNI
#
  WriteComFile freerflag_script "EXCLUDE FUNI SIGFUNI\nEND"

  set status [Execute  "[BinPath mtzutils] HKLIN \"$temp3\" HKLOUT \"$HKLOUT\" " \
		     $freerflag_script program_status report ]


} else {

#
# Assign FreeR flags to these indices
# 

  WriteComFile freerflag_script "FREERFRAC $FREER_FRACTION\nEND"

  set status [ Execute  "[BinPath freerflag] HKLIN \"$temp1\" HKLOUT \"$temp2\"" \
                      $freerflag_script program_status report ]

#
# Use cad to append these FreeR flags to the real data.
#

  WriteComFile cad_script \
    "$INCL_SYS_ABS\nLABI FILE 2  E1=FreeR_flag\nLABI FILE 1  ALLIN\nEND"

  set status [ Execute "[BinPath cad] HKLIN2 \"$temp2\" HKLIN1 \"$HKLIN\" HKLOUT \"$temp3\"" \
	       $cad_script program_status report ]

#
# Ensure FreeR flags assigned to every reflection.
#

  WriteComFile freerflag_script "COMPLETE FREE=FreeR_flag\nEND"

  set status [ Execute "[BinPath freerflag] HKLIN \"$temp3\" HKLOUT \"$HKLOUT\""  \
                     $freerflag_script program_status report ]

}

}
