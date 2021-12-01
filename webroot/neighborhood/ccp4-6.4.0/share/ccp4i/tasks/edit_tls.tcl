#
#     Copyright (C) 2001-2004  Martyn Winn, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# edit_tls.tcl --
#
# CCP4Interface 
#
# =======================================================================

#d_index_title Extracting Data from TLS Files

#-------------------------------------------------------------------------
proc InitialiseTLSData { } {
#-------------------------------------------------------------------------
#d_sum Initialise the TLS_file_data array which holds header parameters from \
the last selected input TLS file.

   global TLS_file_data
   set TLS_file_data(LOADED) 0
   set TLS_file_data(FILE) ""
   set TLS_file_data(N_TLSGRP) 0
   set TLS_file_data(TLS_TITLES) ""
   set TLS_file_data(N_TLSRANGE) ""
   set TLS_file_data(TLS_CHAIN) ""
   set TLS_file_data(TLS_RES_START) ""
   set TLS_file_data(TLS_RES_END) ""
   set TLS_file_data(TLS_SELECT) ""
   set TLS_file_data(TLS_ORIGIN) ""
   set TLS_file_data(TLS_T) ""
   set TLS_file_data(TLS_L) ""
   set TLS_file_data(TLS_S) ""

}

#-------------------------------------------------------------------------
proc ExtractTLSData { file } {
#-------------------------------------------------------------------------
#d_sum Read TLS file and load params into global array TLS_file_data

  global TLS_file_data

   if { ![file exists $file] } {
    set TLS_file_data(LOADED) -1
    set TLS_file_data(FILE) $file
    return 0
   }

   set changed [file mtime $file]
   if { [ElementExists TLS_file_data LOADED] && \
          $file == $TLS_file_data(FILE) && \
          $changed == $TLS_file_data(CHANGED) } {
      if { $TLS_file_data(LOADED)  == 1 } {
#     puts "Using old data "
        return 1
      } elseif { $TLS_file_data(LOADED)  == -1 } {
        return -2
      }
   }

   if { ![ReadFile $file text ] } { 
     set TLS_file_data(LOADED) -1
     return  -1
   }
# new file or old file which has been modified
   InitialiseTLSData

# get first TLS line 
   set line [ExtractFromText $text "TLS" 0 all]
   lappend TLS_file_data(TLS_TITLES) [lreplace $line 0 0]
   incr TLS_file_data(N_TLSGRP)
   set nrange 0
   set chain ""
   set res_start ""
   set res_end ""
   set select ""
   set origin ""
   set tls_t ""
   set tls_l ""
   set tls_s ""

# go through remaining lines
   while { [set key [ExtractFromText - "" 1 0 ] ] != ""} {

     switch $key {

       TLS   { set line [ExtractFromText - "" 0 all]
               lappend TLS_file_data(TLS_TITLES) [lreplace $line 0 0]
               incr TLS_file_data(N_TLSGRP)
               lappend TLS_file_data(N_TLSRANGE) $nrange
               lappend TLS_file_data(TLS_CHAIN) $chain
               lappend TLS_file_data(TLS_RES_START) $res_start 
               lappend TLS_file_data(TLS_RES_END) $res_end 
               lappend TLS_file_data(TLS_SELECT) $select 
               lappend TLS_file_data(TLS_ORIGIN) $origin
               lappend TLS_file_data(TLS_T) $tls_t
               lappend TLS_file_data(TLS_L) $tls_l
               lappend TLS_file_data(TLS_S) $tls_s
               set nrange 0
               set chain ""
               set res_start ""
               set res_end ""
               set select ""
               set origin ""
               set tls_t ""
               set tls_l ""
               set tls_s ""
              }

       RANGE { incr nrange
               set line [ExtractFromText - "" 0 all] 
               scan $line "RANGE  '%1s%4d.' '%1s%4d.'%s" res1 res2 res3 res4 res5
               lappend chain $res1
               lappend res_start $res2
               lappend res_end $res4
               lappend select $res5
             }

       ORIGIN { set line [ExtractFromText - "" 0 all] 
               scan $line "ORIGIN %f %f %f" orig1 orig2 orig3 
	       set origin [list $orig1 $orig2 $orig3]
             }

       T     { set line [ExtractFromText - "" 0 all] 
               scan $line "T %f %f %f %f %f %f" t1 t2 t3 t4 t5 t6 
	       set tls_t [list $t1 $t2 $t3 $t4 $t5 $t6]
             }

       L     { set line [ExtractFromText - "" 0 all] 
               scan $line "L %f %f %f %f %f %f" l1 l2 l3 l4 l5 l6 
	       set tls_l [list $l1 $l2 $l3 $l4 $l5 $l6]
             }

       S     { set line [ExtractFromText - "" 0 all] 
               scan $line "S %f %f %f %f %f %f %f %f" s1 s2 s3 s4 s5 s6 s7 s8  
	       set tls_s [list $s1 $s2 $s3 $s4 $s5 $s6 $s7 $s8]
             }
      }
   }

   lappend TLS_file_data(N_TLSRANGE) $nrange
   lappend TLS_file_data(TLS_CHAIN) $chain
   lappend TLS_file_data(TLS_RES_START) $res_start 
   lappend TLS_file_data(TLS_RES_END) $res_end 
   lappend TLS_file_data(TLS_SELECT) $select 
   lappend TLS_file_data(TLS_ORIGIN) $origin 
   lappend TLS_file_data(TLS_T) $tls_t
   lappend TLS_file_data(TLS_L) $tls_l
   lappend TLS_file_data(TLS_S) $tls_s

   return 1
}

#---------------------------------------------------------------------
proc edit_tls_reset { arrayname } {
#---------------------------------------------------------------------
# Clear the current settings and redraw the window
  upvar #0 $arrayname array

  ReCreateTaskWindow PROJECT edit_tls $array(WINDOW) $arrayname
}

#---------------------------------------------------------------------
proc edit_tls_update_tlspar { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  global TLS_file_data

  set nexist $array(N_TLSGRP)

# use tlsextract to generate temporary TLSIN file if necessary
  if { [GetValue $arrayname EDIT_TLS_TYPE] == "XYZIN" } {

   set cmd "[BinPath tlsextract] "
   append cmd "XYZIN [GetFullFileName0 $arrayname XYZIN] " 
   set tmp_tlsin [GetTmpFileName]
   append cmd "TLSOUT $tmp_tlsin" 

   if { ![Execute $cmd "" status report ] } {
     PleaseWait
     WarningMessage "Error running tlsextract program"
     return 0
   }

    if { [ExtractTLSData $tmp_tlsin ] <= 0 } { return 0 }

    DeleteFile $tmp_tlsin

  # get list of chains from XYZIN and generate one group per chain
  } elseif { [GetValue $arrayname EDIT_TLS_TYPE] == "PDBCHAINS" } {

    if { ![file exists [GetFullFileName0 $arrayname XYZIN]]  ||
         ![PdbGetChains [GetFullFileName0 $arrayname XYZIN] chains chainranges] } {
	return 0 }

    InitialiseTLSData
    set ngroup 0

    foreach chain $chains {

      incr ngroup
      set TLS_file_data(N_TLSGRP) $ngroup
      lappend TLS_file_data(TLS_TITLES) "chain $chain"
      lappend TLS_file_data(N_TLSRANGE) 1
      lappend TLS_file_data(TLS_CHAIN) $chain
      lappend TLS_file_data(TLS_RES_START) [lindex [lindex $chainranges [expr $ngroup - 1] ] 0]
      lappend TLS_file_data(TLS_RES_END) [lindex [lindex $chainranges [expr $ngroup - 1] ] 1]
      lappend TLS_file_data(TLS_SELECT) "*"
      lappend TLS_file_data(TLS_ORIGIN) [list 0.0 0.0 0.0]
      lappend TLS_file_data(TLS_T)  [list 0.0 0.0 0.0 0.0 0.0 0.0]
      lappend TLS_file_data(TLS_L)  [list 0.0 0.0 0.0 0.0 0.0 0.0]
      lappend TLS_file_data(TLS_S)  [list 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0]

    }

  } else {

    if { [ExtractTLSData [GetFullFileName0 $arrayname TLSIN] ] <= 0 } { return 0 }

  }

  if { $TLS_file_data(N_TLSGRP) > 0 } {
# if existing group is just initial blank one, discount it
    if { $nexist == 1 && $array(TLS_TITLE,1) == "" } { 
      update_extendingframe TlsGroupFrame 0 $arrayname N_TLSGRP \
	$nexist -1 1
      set nexist 0 
    }
    set array(N_TLSGRP) [expr $nexist + $TLS_file_data(N_TLSGRP)]
    edit_tls_update_tls_pars_frame $arrayname
    set increment $TLS_file_data(N_TLSGRP) 
# open frame for each new group
    update_extendingframe TlsGroupFrame 0 $arrayname N_TLSGRP \
	$nexist $increment 1
  } else {
   return 0
  }

# copy data from TLS file parameters to task parameters
  if [ElementExists TLS_file_data TLS_TITLES] {
    for {set ig 0; set n [expr $nexist + 1]} {$ig < $TLS_file_data(N_TLSGRP)} {incr ig; incr n} {
      set array(TLS_TITLE,$n) [lindex $TLS_file_data(TLS_TITLES) $ig]
      set array(N_TLSRANGE,$n) [lindex $TLS_file_data(N_TLSRANGE) $ig]
      set chain [lindex $TLS_file_data(TLS_CHAIN) $ig]
      set res_start [lindex $TLS_file_data(TLS_RES_START) $ig]
      set res_end [lindex $TLS_file_data(TLS_RES_END) $ig]
      set select [lindex $TLS_file_data(TLS_SELECT) $ig]
      for {set m 1} {$m <= $array(N_TLSRANGE,$n)} {incr m} {
        set array(TLS_CHAIN,${n}_${m}) [lindex $chain [expr $m - 1] ]
        set array(TLS_RES_START,${n}_${m}) [lindex $res_start [expr $m - 1] ]
        set array(TLS_RES_END,${n}_${m}) [lindex $res_end [expr $m - 1] ]
	# Atom selection is slightly different...
	set tls_select [lindex $select [expr $m - 1]]
	if { [regexp {^(MNC|mnc|SDC|sdc|ALL|all)$} $tls_select] } {
          SetValue $arrayname TLS_SELECT_TYPE,${n}_${m} $tls_select
          set array(TLS_SELECT,${n}_${m}) ""
        } else {
          SetValue $arrayname TLS_SELECT_TYPE,${n}_${m} "SELECT"
          set array(TLS_SELECT,${n}_${m}) $tls_select
        }
        if {$m > 1} {
          append_extend_frame $arrayname TlsRangeFrame $n $m
        }
      }
      set array(TLS_ORIGIN_X,$n) [lindex [lindex $TLS_file_data(TLS_ORIGIN) $ig] 0]
      set array(TLS_ORIGIN_Y,$n) [lindex [lindex $TLS_file_data(TLS_ORIGIN) $ig] 1]
      set array(TLS_ORIGIN_Z,$n) [lindex [lindex $TLS_file_data(TLS_ORIGIN) $ig] 2]
      set array(TLS_T_11,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 0]
      set array(TLS_T_22,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 1]
      set array(TLS_T_33,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 2]
      set array(TLS_T_12,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 3]
      set array(TLS_T_13,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 4]
      set array(TLS_T_23,$n) [lindex [lindex $TLS_file_data(TLS_T) $ig] 5]
      set array(TLS_L_11,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 0]
      set array(TLS_L_22,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 1]
      set array(TLS_L_33,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 2]
      set array(TLS_L_12,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 3]
      set array(TLS_L_13,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 4]
      set array(TLS_L_23,$n) [lindex [lindex $TLS_file_data(TLS_L) $ig] 5]
      set array(TLS_S_2211,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 0]
      set array(TLS_S_1133,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 1]
      set array(TLS_S_12,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 2]
      set array(TLS_S_13,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 3]
      set array(TLS_S_23,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 4]
      set array(TLS_S_21,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 5]
      set array(TLS_S_31,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 6]
      set array(TLS_S_32,$n) [lindex [lindex $TLS_file_data(TLS_S) $ig] 7]
    }
    SetSystemVar block_scroll_update 0
    update_main_scroll $array(FRAME_TlsGroupFrame_0)
  } 

  return 1

}

#---------------------------------------------------------------------
proc edit_tls_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0  $typedefVar typedef

  DefineMenu _edit_tls_type [list "from scratch" \
	                          "starting from chain list in PDB file" \
	                          "starting from an existing TLS file" \
	                          "starting from TLS REMARKS in PDB file"] \
                                 [list  "SCRATCH" \
                                        "PDBCHAINS" \
                                        "TLSIN" \
                                        "XYZIN" ]

  DefineMenu _edit_tls_select [list "all atoms" \
                                    "main chain atoms only" \
                                    "side chain atoms only" \
                                    "selected atom types"] \
                                 [list ALL MNC SDC SELECT]

  InitialiseTLSData

  return 1
}

#-------------------------------------------------------------------------
proc edit_tls_run { arrayname } {
#-------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(LOGFILE) [GetTmpFileName]

  WriteFile $array(LOGFILE) "\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\##\#\#\#\#\#\#\#\#\#"
  WriteFile $array(LOGFILE) "     TLS file writing utility   "
  WriteFile $array(LOGFILE) "\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\#\##\#"

  SetDefaultTitle $arrayname "\[No title given\]"

  set fileout [GetFullFileName0 $arrayname TLSOUT]
  if { ![OpenFile $fileout fo w] } { 
    Report 2  "ERROR cannot open TLSOUT file $fileout"
    return 
  }

  if { $array(TLS_PARS) } { 
    puts $fo "\nREFMAC"
  }

  for {set i 1} {$i <= $array(N_TLSGRP) }  {incr i } {

    set text "\nTLS    $array(TLS_TITLE,$i)"
    puts $fo $text

    for {set j 1} {$j <= $array(N_TLSRANGE,$i) }  {incr j } {

      set text "RANGE"
      append text [format "  '%1s%4s.'" \
	  $array(TLS_CHAIN,${i}_${j}) $array(TLS_RES_START,${i}_${j})]
      append text [format " '%1s%4s.'" \
          $array(TLS_CHAIN,${i}_${j}) $array(TLS_RES_END,${i}_${j})]
      if { [GetValue $arrayname TLS_SELECT_TYPE,${i}_${j}] == "SELECT" } {
        append text [format " %s" $array(TLS_SELECT,${i}_${j}) ]
      } else {
        append text [format " %s" [GetValue $arrayname TLS_SELECT_TYPE,${i}_${j}] ]
      }
      puts $fo $text
    }

    if { $array(TLS_PARS) } { 

      set text [format "ORIGIN  %7.3f %7.3f %7.3f" \
	   $array(TLS_ORIGIN_X,${i}) $array(TLS_ORIGIN_Y,${i}) \
	   $array(TLS_ORIGIN_Z,${i}) ]
      puts $fo $text

      set text [format "T    %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f" \
	   $array(TLS_T_11,${i}) $array(TLS_T_22,${i}) \
	   $array(TLS_T_33,${i}) $array(TLS_T_12,${i}) \
	   $array(TLS_T_13,${i}) $array(TLS_T_23,${i}) ]
      puts $fo $text

      set text [format "L    %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f" \
	   $array(TLS_L_11,${i}) $array(TLS_L_22,${i}) \
	   $array(TLS_L_33,${i}) $array(TLS_L_12,${i}) \
	   $array(TLS_L_13,${i}) $array(TLS_L_23,${i}) ]
      puts $fo $text

      set text [format "S    %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f %7.4f" \
	   $array(TLS_S_2211,${i}) $array(TLS_S_1133,${i}) \
	   $array(TLS_S_12,${i}) $array(TLS_S_13,${i}) \
	   $array(TLS_S_23,${i}) $array(TLS_S_21,${i}) \
	   $array(TLS_S_31,${i}) $array(TLS_S_32,${i}) ]
      puts $fo $text

    }

  }

  WriteFile $array(LOGFILE) "\nTLS file $fileout written successfully."
  WriteFile $array(LOGFILE) "\nNormal Termination"

  return [CloseFile $fo]
}
 
#------------------------------------------------------------------------
proc TlsRangeFrame { arrayname i counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
	message "Specify TLS group: 1st residue of range" \
	label "Include residues " \
	widget TLS_RES_START \
	message "Specify TLS group: last residue of range" \
	label " to " \
	widget TLS_RES_END \
	message "Specify TLS group: chain identifier" \
	label " in chain " \
	widget TLS_CHAIN \
	message "Specify TLS group: ALL, MNCH, SDCH or list of atom names" \
	label " including " \
	widget TLS_SELECT_TYPE
 
  CreateLine line \
        message "Specify a list of atom types to be included in the TLS group" \
        label "                          Include atoms with specific types:" \
        widget TLS_SELECT \
	toggle_display TLS_SELECT_TYPE,[subst $counter]_[subst $i] open { SELECT }
        
}

#------------------------------------------------------------------------
proc TlsGroupFrame { arrayname counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  CreateLine line \
	label "Group $counter" 

  CreateLine line \
	message "Give a title for the TLS group" \
	label "Group title" \
	widget TLS_TITLE

  CreateExtendingFrame N_TLSRANGE TlsRangeFrame \
                "Open another TLS range definition frame" \
                "Add TLS range" \
        [ list  TLS_CHAIN \
                TLS_RES_START \
                TLS_RES_END \
                TLS_SELECT_TYPE \
		TLS_SELECT ] \
	-counter $counter

   OpenSubFrame frame -toggle_display TLS_PARS_FRAME,$counter open { 1 } 

     CreateLine line \
	message "Specify the origin of the TLS group" \
	label "Group origin" \
	widget TLS_ORIGIN_X \
	widget TLS_ORIGIN_Y \
	widget TLS_ORIGIN_Z

     CreateLine line \
	message "Specify the translation parameters of the TLS group" \
	label "T " \
	widget TLS_T_11 \
	widget TLS_T_22 \
	widget TLS_T_33 \
	widget TLS_T_12 \
	widget TLS_T_13 \
	widget TLS_T_23

     CreateLine line \
	message "Specify the libration parameters of the TLS group" \
	label "L " \
        widget TLS_L_11 \
	widget TLS_L_22 \
	widget TLS_L_33 \
	widget TLS_L_12 \
	widget TLS_L_13 \
	widget TLS_L_23

     CreateLine line \
	message "Specify the screw-rotation parameters of the TLS group" \
	label "S " \
	widget TLS_S_2211 \
	widget TLS_S_1133 \
	widget TLS_S_12 \
	widget TLS_S_13 \
	widget TLS_S_23 \
	widget TLS_S_21 \
	widget TLS_S_31 \
	widget TLS_S_32

   CloseSubFrame

}

#------------------------------------------------------------------------
proc edit_TlsGroupFrame { arrayname counter } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

}

#---------------------------------------------------------------------
proc edit_tls_update_type { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [GetValue $arrayname EDIT_TLS_TYPE] == "SCRATCH" } {
    set array(USE_XYZIN) 0
    set array(USE_TLSIN) 0
    set array(INPUT_FILES) ""
  } elseif { [GetValue $arrayname EDIT_TLS_TYPE] == "PDBCHAINS" } {
    set array(USE_XYZIN) 1
    set array(USE_TLSIN) 0
    set array(INPUT_FILES) "XYZIN"
  } elseif { [GetValue $arrayname EDIT_TLS_TYPE] == "TLSIN" } {
    set array(USE_XYZIN) 0
    set array(USE_TLSIN) 1
    set array(INPUT_FILES) "TLSIN"
  } elseif { [GetValue $arrayname EDIT_TLS_TYPE] == "XYZIN" } {
    set array(USE_XYZIN) 1
    set array(USE_TLSIN) 0
    set array(INPUT_FILES) "XYZIN"
  } 

}

#---------------------------------------------------------------------
proc edit_tls_update_tls_pars_frame { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  for { set i 1 } { $i <= $array(N_TLSGRP) } { incr i } {
    set array(TLS_PARS_FRAME,$i) $array(TLS_PARS)
  }
}

#----------------------------------------------------------------
proc edit_tls_task_window { arrayname } {
#----------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname  \
    	"Create/Edit TLS File" "edit_tls" \
	[ list "TLS group definitions" ] \
        -action_buttons [list quit interactive ] ] == 0 } return

  set resetbutton [button $array(WINDOW).buttons.reset \
                -text "Reset" \
                -relief raised \
                -background $configure(COLOUR_PALE) \
                -font $configure(FONT_REGULAR) \
                -command "edit_tls_reset $arrayname"]

  pack $resetbutton -side left -expand 1

  SetProgramHelpFile "tlsanl"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Select source of TLS parameters, if any" \
        label "Create a TLS file " \
        widget EDIT_TLS_TYPE \
          -command "edit_tls_update_type $arrayname" 

  CreateLine line \
    message "Selecting this will create fields for ORIGIN, T, L and S" \
    widget TLS_PARS -command "edit_tls_update_tls_pars_frame $arrayname" \
    label "create/edit TLS parameters in addition to group definitions"

#=FILES================================================================

  OpenFolder file 

  OpenSubFrame frame -toggle_display USE_TLSIN open { 1 } 

  CreateInputFileLine line \
      "Enter input TLS file name (TLSIN)" \
      "TLS in" \
       TLSIN DIR_TLSIN \
     -fileout TLSOUT DIR_TLSOUT "_edit_tls" \
     -command "edit_tls_update_tlspar $arrayname" 

  CloseSubFrame

  OpenSubFrame frame -toggle_display USE_XYZIN open { 1 } 

  CreateInputFileLine line \
      "Enter input PDB file name (XYZIN)" \
      "PDB in" \
       XYZIN DIR_XYZIN \
     -fileout TLSOUT DIR_TLSOUT "_edit_tls" \
     -command "edit_tls_update_tlspar $arrayname" 

  CloseSubFrame

  CreateInputFileLine line \
      "Enter output TLS file name (TLSOUT)" \
      "TLS out" \
       TLSOUT DIR_TLSOUT 

#=PARAMETERS1===========================================================


  OpenFolder 1

  CreateExtendingFrame N_TLSGRP TlsGroupFrame \
                "Open another TLS group definition frame" \
                "Add another TLS group" \
        [ list  TLS_TITLE \
                N_TLSRANGE \
                TLS_CHAIN \
                TLS_RES_START \
                TLS_RES_END \
                TLS_SELECT \
                TLS_PARS_FRAME \
                TLS_ORIGIN_X \
                TLS_ORIGIN_Y \
                TLS_ORIGIN_Z \
                TLS_T_11 TLS_T_22 TLS_T_33 TLS_T_12 TLS_T_13 TLS_T_23 \
                TLS_L_11 TLS_L_22 TLS_L_33 TLS_L_12 TLS_L_13 TLS_L_23 \
                TLS_S_2211 TLS_S_1133 TLS_S_12 TLS_S_13 TLS_S_23 TLS_S_21 TLS_S_31 TLS_S_32] \
	-child TlsRangeFrame \
	-edit edit_TlsGroupFrame

}
