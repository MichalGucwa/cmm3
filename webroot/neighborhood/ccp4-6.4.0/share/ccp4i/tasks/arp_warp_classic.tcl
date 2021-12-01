# ======================================================================
# arp_warp_classic.tcl --
#
# =======================================================================

#----------------------------------------------------------------------
proc arp_warp_classic_prereq {} {
#----------------------------------------------------------------------
    if { [GetEnvPath warpbin 0] == "" } {
        return 0
    } else {
        return 1
    }
}

#----------------------------------------------------------------------
proc arp_warp_classic_run { arrayname } {
#----------------------------------------------------------------------

# procedure run before script is written

    upvar #0 $arrayname array

# First check the version
#
    set arpkey "0"
#
    set out_file [GetTmpFileName ]
    catch { exec [FileJoin [GetEnvPath warpbin] arp_warp ] -v ] > $out_file}
    #
    if { [ReadFile $out_file out_text] && \
	    [ExtractTextLine $out_text  "73010312" 0 all line1 ] } {
	set arpkey [expr [lindex $line1 0] ]
    }

if { $arpkey != "73010312" } {
    WarningMessage "The version of ARP/wARP you have installed is not 7.3.0 or ARP/wARP could not be found at all. Make sure you have modified your .cshrc so as it contain the definition for warpbin and has the right path, or please get and install version 7.3.0 from http://www.arp-warp.org/"
    return 0
}
#
# Set the conditional restraints mode, needed to check REFMAC versions below
#
if { $array(USE_COND) == 1 & $array(FORCE_COND) == 0} {
       set array(RESTRAINTS) 1
}
if { $array(USE_COND) == 1 & $array(FORCE_COND) == 1} {
       set array(RESTRAINTS) 2
}
if { $array(USE_COND) == 0 } {
       set array(RESTRAINTS) 0
}
#
#
# Now check if we like the refmac version as well !
# Thats only relevent for non-cluster jobs!
#

if { $array(REMOTE_JOB) == 0 } {

  set out_file [GetTmpFileName]
  catch { exec [FileJoin [GetEnvPath CBIN ] refmac5 ] -i > $out_file }
  # Initialise
  set patch_version ""
  set minor_version ""
  set major_version ""
  # Extract the information from the output of refmac5 -i
  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text "refmac5" 0 all line ] } {
    if { [llength $line] < 4 } {
      WarningMessage "Cannot extract Refmac version number!" -button Cancel
      return 0
    }
    # This will get the version number x.y.z
    set refkey [lindex $line 3]
    set lrefkey [split $refkey .]
    if { [llength $lrefkey] > 2 } {
      set patch_version [scan [lindex $lrefkey 2] %d]
    }
    if { [llength $lrefkey] > 1 } {
      set minor_version [scan [lindex $lrefkey 1] %d]
    }
    if { [llength $lrefkey] > 0 } {
      set major_version [scan [lindex $lrefkey 0] %d]
    }
  }
#
if { $major_version <= 5 } {
   if { $minor_version <= 1 } {
      if { $patch_version <= 18 || $minor_version < 1 || $major_version < 5 } {
         WarningMessage "You need Refmac5 version 5.1.19 (or higher) to run ARP/wARP 7.3.0. Please install the latest CCP4 version." -button Abort 
         return 0
      }
   } 
}
#
if { $array(TWIN) == 1 } {
   if { $major_version <= 5 } {
      if { $minor_version <= 5 } {
         if { $patch_version <= 16 || $minor_version < 5 || $major_version < 5 } {
            WarningMessage "You need Refmac5 version 5.5.16 (or higher) to use the detwinning option in REFMAC5. We suggest to visit http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html and download and install the latest Refmac5 version."  -button Abort
            return 0
         }
      }
   }
}

if { $array(RESTRAINTS) == 1 } {
   if { $major_version <= 5 } {
      if { $minor_version <= 5 } {
         if { $patch_version <= 44 || $minor_version < 5 || $major_version < 5 } {
            WarningMessage "You need Refmac5 version 5.44 (or higher) to use the conditional restraints option in REFMAC5. We suggest to visit http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html and download and install the latest Refmac5 version."  -button Abort
            return 0
         }
      }
   }
}

if { $array(SAD) == 1 } {
   if { $major_version <= 5 } {
      if { $minor_version <= 5 } {
         if { $patch_version <= 58 || $minor_version < 5 || $major_version < 5 } {
            WarningMessage "You need Refmac5 version 5.44 (or higher) to use the conditional restraints option in REFMAC5. We suggest to visit http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html and download and install the latest Refmac5 version."  -button Abort
            return 0
         }
      }
   }
}

if { $major_version <= 5 } {
    if { $minor_version <= 4 } {
		  WarningMessage "Refmac5 version 5.5.n (or higher) is strongly recommended to run ARP/wARP 7.3.0. We suggest to visit http://www.ysbl.york.ac.uk/~garib/refmac/latest_refmac.html and download and install the latest Refmac5 version." \
		  -button Acknowledge
	      }
}

}
#
# Check if input is really OK.

if { [file exists [GetFullFileName1 $array(HKLIN) $array(DIR_HKLIN) ] ] } {
    set array(INPUT_FILES) " HKLIN "		
} else {
    WarningMessage "Can not open MTZ input file." -button Cancel
    return 0
}


if { ![regexp WARPNTRACEPHASES [GetValue $arrayname ARP_MODE ] ] } { 
    if { [file exists [GetFullFileName1 $array(MODELIN) $array(DIR_MODELIN) ] ] } {
	append array(INPUT_FILES) " MODELIN "	
    } else {
	WarningMessage "Can not open PDB input file." -button Cancel
	return 0
    }
}

if { ( [regexp WARPNTRACEPHASES [GetValue $arrayname ARP_MODE ] ] || \
	[regexp WARPNTRACEMODEL [GetValue $arrayname ARP_MODE ] ] ) && \
	$array(BUILD_SIDE) == "1" } {
    if { [string length $array(SEQIN)] > 0 } {
        if { [file exists [GetFullFileName1 $array(SEQIN) $array(DIR_SEQIN) ] ] } {
	    append array(INPUT_FILES) " SEQIN "	
        } else {
	    WarningMessage "Can not open Sequence input file." -button Cancel
	    return 0
        }
    }
}


if { [regexp SAD [GetValue $arrayname REF_MODE ] ] } { 
    if { [file exists [GetFullFileName1 $array(HEAVYIN) $array(DIR_HEAVYIN) ] ] } {
	append array(INPUT_FILES) " HEAVYIN "	
    } else {
	WarningMessage "Can not open PDB file with heavy atoms scatterers." -button Cancel
	return 0
    }
}

if { $array(FP) == "Unassigned" || $array(FP) == "" } {
    WarningMessage "FP is not assigned to an mtz label." -button Cancel
    return 0
}


if { $array(FP) == "FWT" || $array(FP) == "FC" || $array(FP) == "2FOFCWT" } {
    set action [ChooseOptionDialog "Suspicious FP" "Suspicious FP" "FP appears to be assigned to a label that is typically used for calculated data. Most likely it has been assigned to the wrong label of the MTZ file." \
		{ Continue Abort } -default 1]
    if [regexp Abort $action ] { return 0 }
}


if { $array(SIGFP) == "Unassigned" || $array(SIGFP) == "" } {
    WarningMessage "SIGFP is not assigned to an mtz label." -button Cancel
    return 0
}  

if { ( [regexp WARPNTRACEPHASES [GetValue $arrayname ARP_MODE ] ] ) && \
	( $array(PHIB) == "Unassigned" || $array(PHIB) == "" ) } {
    WarningMessage "PHIB is not assigned to an mtz label." -button Cancel
    return 0
}


# See if weighting is being used and clear FBEST if it isn't
if { [regexp WARPNTRACEPHASES [GetValue $arrayname ARP_MODE ] ] } {
    if { $array(WEIGHTED_FP) == "0" } {
        if { $array(FOM) == "Unassigned" || $array(FOM) == "" } {
            WarningMessage "FOM must be assigned or a pre-weighted amplitude must be used." -button Cancel
            return 0
        } else {
            set array(FBEST) ""
        }
    }

    if { $array(WEIGHTED_FP) == "1" && ($array(FBEST) == "Unassigned" || $array(FBEST) == "") } {
	WarningMessage "FBEST must be assigned or not used at all." -button Cancel
	return 0
    }
}


if { [regexp Y [GetValue $arrayname PHASE_RESTRAIN ] ] } {
    if { $array(PHIB) == "Unassigned" || $array(PHIB) == "" } {
	WarningMessage "PHIB is not assigned to an mtz label." -button Cancel
    return 0
    }
    if { $array(FOM) == "Unassigned" || $array(FOM) == "" } {
	WarningMessage "FOM is not assigned to an mtz label." -button Cancel
    return 0
    }
}

if { $array(FOM) == "Unassigned" } {
    set array(FOM) ""
}

if { [regexp HL [GetValue $arrayname PHASE_RESTRAIN ] ] } {
    if { $array(HLA) == "Unassigned" || $array(HLA) == "" || \
	    $array(HLB) == "Unassigned" || $array(HLB) == "" || \
	    $array(HLC) == "Unassigned" || $array(HLC) == "" || \
	    $array(HLD) == "Unassigned" || $array(HLD) == "" } {
	WarningMessage "NOT all HL coefficients are assigned to an mtz label." -button Cancel
    return 0
    }
}


if { [regexp SAD [GetValue $arrayname REF_MODE ] ] } {
    if { $array(FPP) == "Unassigned" || $array(FPM) == "" || \
	    $array(SIGFPP) == "Unassigned" || $array(SIGFPM) == "" || \
	    $array(FPM) == "Unassigned" || $array(FPM) == "" || \
	    $array(SIGFPM) == "Unassigned" || $array(SIGFPM) == "" } {
	WarningMessage "F+ and F- need to be set for SAD phasing." -button Cancel
    return 0
    }
    if { [regexp LAMBDA [GetValue $arrayname ANO_OPTION ] ] } {
	if { $array(SCAT_LAMBDA_SAD) == "Unassigned" || $array(SCAT_LAMBDA_SAD) == "" } {
	WarningMessage "Wavelength must be defined for this mode" -button Cancel
    return 0
    }   } 
    if { [regexp MEASURED [GetValue $arrayname ANO_OPTION ] ] } {
	if { $array(SCAT_FP_SAD) == "Unassigned" || $array(SCAT_FP_SAD) == "" || \
	   $array(SCAT_FDP_SAD) == "Unassigned" || $array(SCAT_FDP_SAD) == "" || \
	   $array(SCAT_ATOM) == "Unassigned" || $array(SCAT_ATOM) == "" } {
	WarningMessage "The measured f' and f'' and the atom name must all be defined for this mode" -button Cancel
    return 0
    }   }
}



if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ] && \
	$array(FREE) == "Unassigned" } {
    WarningMessage "FreeRflag is not assigned to an mtz label. Please assign FreeRflag in Refmac Parameters panel." -button Cancel
    return 0
}

if { $array(NRES) == "" } {
	WarningMessage "You have to input the number of residues." -button Cancel
}

set testbin [GetEnvPath warpbin]

if { $testbin == "" } {
    WarningMessage "The environment variable $warpbin seems to be undefined. Please make sure you are sourcing the correct ARP/wARP setup file as instructed during installation." -button Cancel
return 0 
}

  set space_gp_number [GetSpaceGroupNumber $array(SPACE_GROUP)]

if { $space_gp_number == "" || $space_gp_number == "0" } {
    WarningMessage "The space group number has not been extracted succesfully. That indicates a problem with your MTZ file or with the CCP4i libraries, possibly handlign a space group like C 1 2 1. A command like: 'echo \"SYMM C2\" | mtzutils hklin cad.mtz hklout cad_fix.mtz' might fix this problem." -button Cancel
return 0 
}

if { $array(XYZLIM_1) == "" || $array(XYZLIM_2) == "" || $array(XYZLIM_3) == "" || $array(XYZLIM_4) == "" || $array(XYZLIM_5) == "" || $array(XYZLIM_6) == "" } {
    WarningMessage "The AU limits were not set; probably thats a problem with the input MTZ file than can be solved by reading it again. You can check the fields under Crystal Parameters to make sure the correct AU limits are extracted." -button Cancel
return 0 
}

if { $array(REMOTE_JOB) == 1 } {
	if { $array(USER_EMAIL) == ""} {
	WarningMessage "You have to define your Email to submit a remote job." -button Cancel
	return 0
	}
	set test [string map {@ ""} $array(USER_EMAIL)]
	if { $test == $array(USER_EMAIL) } {
		WarningMessage "The email address you provided appears to contain no @ character and is presumably invalid." -button Cancel 
        	return 0
	}	
	set test [string map {. ""} $array(USER_EMAIL)]
	if { $test == $array(USER_EMAIL) } {
		WarningMessage "The email address you provided appears to contain no . character and is presumably invalid." -button Cancel 
        	return 0
	}	
	if { $array(TOTAL_CYCLES) > 200 } {
        	WarningMessage "For a remote job submission there is a limit to 200 total cycles (refinement times autobuilding cycles). Please note that jobs longer than about ten to twenty cycles with a maximum of ten refinement cycles in between are in general useless." -button Cancel 
		return 0
        } 
}
#
#
set njob [expr [DbGetJobData ""  NJOBS] +1 ]
set workdir [GetDefaultDirPath]
#
# Here we set parameters to be written out to warp.par file style ...
#

set array(XYZLIM) "$array(XYZLIM_1) $array(XYZLIM_2) $array(XYZLIM_3)\
	$array(XYZLIM_4) $array(XYZLIM_5) $array(XYZLIM_6) " 
#
set array(DAMP) "$array(DAMP_P) $array(DAMP_B) "
#
set array(RESOL) "$array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)"
#
if { $array(BUILD_SIDE) == "0" } {
    set array(SIDE) -1 
} else {
    set array(SIDE) $array(SIDE_AFTER)
}
#
if { [regexp Y [GetValue $arrayname EXCLUDE_FREER] ]  } {
    set array(FREELABIN) "FREE=$array(FREE)"
} else {
    set array(FREELABIN) ""
}
# 

#set array(REFMETH) CGMAT
if { [regexp AUTO [GetValue $arrayname WEIGHT_MODE] ]  } {
	set array(WEIGHT) "AUTO"
	set array(WEIGHTVAL) " " 
} else {
	set array(WEIGHT) "MATRIX"
	set array(WEIGHTVAL) "$array(WMAT)"
}
# 
if { [regexp Y [GetValue $arrayname REFMAC_REF_SET] ]  } {
    set array(SCALML) "SCAL MLSC FREE"
} else {
	set array(SCALML) "SCAL MLSC"
}
#
case [GetValue $arrayname PHASE_RESTRAIN ] \
	Y {
    set array(PHASELABIN) "PHIB=$array(PHIB) FOM=$array(FOM)"
    set array(PHASEREF) "PHAS SCBL $array(PHASE_BLUR)"
} N {
    set array(PHASELABIN) ""
    set array(PHASEREF) ""
} HL {
    set array(PHASELABIN) "HLA=$array(HLA) HLB=$array(HLB) HLC=$array(HLC) HLD=$array(HLD)"
    set array(PHASEREF) "PHAS SCBL $array(PHASE_BLUR)"
}
#
# Here we set the labels needed for SAD phasing
#
if { [regexp SAD [GetValue $arrayname REF_MODE ] ] } {
    set array(PHASELABIN) "F+=$array(FPP) SIGF+=$array(SIGFPP) F-=$array(FPM) SIGF-=$array(SIGFPM)"
    set array(SAD) "1" 
    if { [regexp CUKA [GetValue $arrayname ANO_OPTION ] ] } {
	set array(SADCARD) "ANOM WAVE 1.54" 
    }
    if { [regexp LAMBDA [GetValue $arrayname ANO_OPTION ] ] } {
	set array(SADCARD) "ANOM WAVE $array(SCAT_LAMBDA_SAD)" 
    }
    if { [regexp MEASURED [GetValue $arrayname ANO_OPTION ] ] } {
	set array(SADCARD) "ANOM FORM $array(SCAT_ATOM) $array(SCAT_FP_SAD) $array(SCAT_FDP_SAD)"
    }
#
} else {
    set array(SAD) "0" 
}
#
# Check the Wilson ChiSq
#
#
  set tmtzfile [GetFullFileName0 $arrayname HKLIN]    
#    
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w
  puts $f "MODE WILSON NRES $array(NRES)\nFILES CCP4 HKLIN=$tmtzfile\nLABELS FP=$array(FP) SIGFP=$array(SIGFP) FUSE=$array(FP) \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"
#
  CloseFile $f
#
  set wilson_file [FileJoin [GetDefaultDirPath] ${njob}_wilson.loggraph]
  set array(WILSON_LOG) $wilson_file

  set badlowres 0.0
  set badhighres  0.0
  set badallres 0.0

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $wilson_file"

    if { [ReadFile $wilson_file out_text] && \
       [ExtractTextLine $out_text  "Bfactor" 0 all line1  ] } {
       set wilsonb [expr [lindex $line1 3] ]
       if { $wilsonb < 2.0 } {
          set wilsonb 2.0
          set actionw [ChooseOptionDialog "Bad Wilson Plot" "Bad Wilson Plot" "The Wilson B value from your data seems to be below 2.0 and it will be reset to 2.0. You can either continue or Abort to check your data." \
                { Continue Abort } -default 1]
#         if [regexp Abort $actionw ] { return 0 }
       }
      set array(WILSON_B) [maxdecimal $wilsonb 2]
    }
    if { [ReadFile $wilson_file out_text] && \
         [ExtractTextLine $out_text  "Solvent content" 0 all line2  ] } {
      set solventc [expr [lindex $line2 2]  ]
      set array(SOLVENTC) [maxdecimal $solventc 2 ]
    }

if { $array(CHECK_WILSON) == "0" } {

  if { [ReadFile $wilson_file out_text] && \
       [ExtractTextLine $out_text  "PoorAllData" 0 all line1  ] } {
       set badallres 10.0
  }

  if { [ReadFile $wilson_file out_text] && \
       [ExtractTextLine $out_text  "PoorLowResolution" 0 all line1  ] } {
       set badlowres [expr [lindex $line1 1] ]
  }

  if { [ReadFile $wilson_file out_text] && \
       [ExtractTextLine $out_text  "PoorHighResolution" 0 all line1  ] } {
       set badhighres [expr [lindex $line1 1] ]
  }

if { $badallres > 0.0 } {
    set action [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "The Wilson plot is poor and ARP/wARP is VERY UNLIKELY to produce sensible results. PLEASE CHECK YOUR DATA." \
	    { Continue Abort ExamineWilsonPlot } -default 2]
    
    if [regexp Abort $action ] { return 0 }
    
    if [regexp ExamineWilsonPlot $action ] { 
	catch "exec loggraph $wilson_file"
	set action2 [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "Now that you have seen the Wilson Plot you can choose what to do next" \
		{ Continue Abort } -default 0]
	if [regexp Abort $action2 ] { return 0 }
    }
}

if { $badlowres > 0.0 && $badlowres < 8.0 } {
    set action [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "The Wilson plot is very poor at low-resolution. You may want to limit the resolution and to switch off bulk solvent scaling. PLEASE CHECK YOUR DATA." \
		{ Continue Abort ExamineWilsonPlot } -default 2]

    set badlowres 8.0

    if [regexp Abort $action ] { return 0 }

    if [regexp ExamineWilsonPlot $action ] { 
	catch "exec loggraph $wilson_file"
	set action2 [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "Now that you have seen the Wilson Plot you can choose what to do next" \
		{ Continue Abort } -default 0]
	
	if [regexp Abort $action2 ] { return 0 }
    }
}

if { $badlowres > 8.001 } {
    set action [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "The Wilson plot is poor for low-resolution data. You may want to limit the resolution and to switch off bulk solvent scaling. PLEASE CHECK YOUR DATA." \
		{ Continue Abort ExamineWilsonPlot } -default 2]

    if [regexp Abort $action ] { return 0 }

    if [regexp ExamineWilsonPlot $action ] { 
	catch "exec loggraph $wilson_file"
	set action2 [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "Now that you have seen the Wilson Plot you can choose what to do next" \
		{ Continue Abort } -default 0]
	
	if [regexp Abort $action2 ] { return 0 }
    }
}

if { $badhighres > 0.0 } {
    set action [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "The Wilson plot is poor for high-resolution data. You may want to limit the resolution. PLEASE CHECK YOUR DATA." \
		{ Continue Abort ExamineWilsonPlot } -default 2]

    if [regexp Abort $action ] { return 0 }

    if [regexp ExamineWilsonPlot $action ] { 
	catch "exec loggraph $wilson_file"
	set action2 [ChooseOptionDialog "Poor Wilson Plot" "Poor Wilson Plot" "Now that you have seen the Wilson Plot you can choose what to do next" \
		{ Continue Abort } -default 0]
	
	if [regexp Abort $action2 ] { return 0 }
    }
}

}

set residues $array(NRES)
set ncs $array(NMOL)
set seqfile [GetFullFileName1 $array(SEQIN) $array(DIR_SEQIN) ]
set warpbin  [GetEnvPath warpbin]


set calcsolvent [ expr -5.7 + [ expr log10($wilsonb) * 42.2 ]]
set errorsolvent 0.2
set calcsolvent [ expr $calcsolvent / 100 ]
set maxsolvent [ expr $calcsolvent +  $errorsolvent ]
set minsolvent [ expr $calcsolvent -  $errorsolvent ]
set nres $array(NRES)

if { $solventc > $maxsolvent || $solventc < $minsolvent } { 
    set calcsolvent [maxdecimal $calcsolvent 2]
    set seqaction  [ChooseOptionDialog "Problems with Solvent Content" "Problems with NCS and number of residues" "An approximate calculated value for the expected solvent content for this resolution and Wilson B factor ($calcsolvent) does not much well with the one calculated form the unit cell volume ($solventc) and the total number of residues declared ($nres). We would advice to check this, but you can choose to Continue." { Continue Abort } -default 1]

	if [regexp Abort $seqaction ] { return 0 }
}
 

if { ![regexp MOLREP [GetValue $arrayname ARP_MODE ] ] && [string length ${seqfile}] > 0 } { 

set tmp_file [GetTmpFileName]
OpenFile $tmp_file f w

puts $f "XMLOutputFilename = 'check_sequence.xml' \n
MessageFilename = 'check_sequence.txt' \n
AbortLevel = 8 \n
MessageLevel = 3 \n
ProgramName = check_sequence  \n
DictionaryFilename = $warpbin/AAbis.XYZ  \n
NumberOfSequence = 1  \n
SequenceFilename = ${seqfile}  \n
SequenceMultiplicty = ${ncs}  \n "

CloseFile $f

set out_file [GetTmpFileName ]

catch "exec [FileJoin [GetEnvPath warpbin] check_sequence] -paramfile=- <$tmp_file > $out_file"

if  {![OpenFile $out_file f r+ ] } {
    return 1
}
set seq_text [read $f]
CloseFile $f

if { [ExtractTextLine $seq_text  "We were UNABLE to read the provided sequence file" 0 all lineseq  ] } {
    WarningMessage "   There seems to be an error in the input sequence file.\n
    Please have a look at $out_file for details." -button Acknowledge 
    return 0
}


ExtractTextLine $seq_text  "This sequence contains" 0 all lineseq

set seqres  [expr [lindex $lineseq 3] ]
set ncscalc [ expr double($residues) / double($seqres) ] 
set ncscalc [ expr round($ncscalc) ]

if { $ncscalc != $ncs } {
    set seqaction  [ChooseOptionDialog "Problems with NCS and number of residues" "Problems with NCS and number of residues" "There seems to be a descrepancy between NCS copies declared ($ncs), the number of residues declared ($residues), the number of residues in the sequence file($seqres) and the NCS copies estimated ($ncscalc) based on the latter information. Although we would advice to Abort and fix this issue you can choose to continue. An automated correction might be applied in the arp_warp procedure." { Continue Abort } -default 2]

	if [regexp Abort $seqaction ] { return 0 }
}

}

if { [regexp MOLREP [GetValue $arrayname ARP_MODE ] ] } {
       set array(TOTAL_CYCLES) $array(SMALL_CYCLES) 
   }


set array(RESOL) "$array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)"

set array(SCALEOPT) "$array(SCALE)"
if { [regexp Y [GetValue $arrayname SCANIS] ]  } {
    append array(SCALEOPT) " LSSC ANIS"
}

if { $array(SKIP_BUILD) == "0" } {
    set array(CYCSKIP) 0
    set array(SKIP_CYCLES) 0
} else {
    set array(CYCSKIP) [expr $array(SKIP_CYCLES) * $array(SMALL_CYCLES)]
}


return 1

}

#--------------------------------------------------------------------
proc arp_warp_classic_setup { typedefVar arrayname } {
#--------------------------------------------------------------------

upvar #0  $typedefVar typedef
global env

    # Confirm that the user has sourced the arpwarp setup script
    if { [info exists env(warpbin)] == 0 } {
        WarningMessage "Please check your shell startup file does source ARP/wARP 7.3. Then open another terminal window and re-launch CCP4i."
        return 0
    }

set typedef(_arp_mode) { 
    menu   
    {       
	"automated model building starting from experimental phases"
	"automated model building starting from existing model"
	"improvement of maps by atoms update and refinement"
    }
    {
	WARPNTRACEPHASES
	WARPNTRACEMODEL
	MOLREP
}   }


set typedef(_ref_mode) { 
    menu   
    {       
	"Maximum Likelihood"
        "SAD ML"
        "Phased ML"
    }
    {
	REFML
	SAD
	PHASED
}   }

set typedef(_weight_mode) { 
    menu   
    {       
	"Automatic"
	"Manual"
    }
    {
	AUTO
	MANUAL
}   }

set typedef(_phase_restrain) { 
    menu   
    {       
	"No"
	"PHIB/FOM"
	"HL"
    }
    {
	N
	Y
	HL
}   }

set typedef(_refmac_ref_set) { 
    menu     
    {       
	"working"
	"free" 
    }
    {   
	N
	Y 
}   }

set typedef(_exclude_freer) { 
    menu     
    {       
	"not use"
	"use" 
    }
    {   
	N
	Y
}   }

set typedef(_scale) { 
    menu     
    {       
	"BULK"
	"SIMPLE" 
    }
    {   
	BULK
	SIMPLE
}   }

set typedef(_scanis) { 
    menu     
    {       
	"isotropic"
	"anisotropic" 
    }
    {   
	N
	Y
}   }

set typedef(_datakeep_mode) { 
    menu   
    {       
      "must be kept confidential and deleted after the job is finished"
      "can be archived and made available to ARP/wARP-AutoRickshaw-Refmac developers"
      "can be archived and made available to any software developer that requests them"
    }
    {
      CONFIDENTIAL
      WARPTEAM
      WORLD
}   }


set typedef(_randtimes) { 
    menu     
    {       
	"Do not randomise"
	"Randomise once" 
	"Randomise twice" 
	"Randomise three times" 
    }
    {  
	0
	1
	2
	3
}   }

set typedef(_ano_option) { 
    menu     
    {       
	"at specific wavelength"
	"by fluorescence scan data" 
	"at CuK-alpha wavelength" 
    }
    {  
	LAMBDA
	MEASURED
	CUKA
}   }





  return 1
}

#--------------------------------------------------------------------
proc set_wmat { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

    set currentmode [GetValue $arrayname ARP_MODE]

    if { $array(EXCLUDE_RESOLUTION_MAX) > 0.11 } {
	set array(WMAT) 2.5
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.11 } {
	set array(WMAT) 1.2
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.41 } {
	set array(WMAT) 0.7
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 1.71 } {
	set array(WMAT) 0.5
    }

    if { $array(EXCLUDE_RESOLUTION_MAX) > 2.01 } {
	set array(WMAT) 0.3
    }

    if { $array(EXCLUDE_RESOLUTION_MIN) > 20.0} {
        set array(EXCLUDE_RESOLUTION) 
	set array(EXCLUDE_RESOLUTION_MIN) 20.0
    }

    SetValue $arrayname WEIGHT_MODE AUTO  

}


#--------------------------------------------------------------------
proc arp_get_assym { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set space_gp_number [GetSpaceGroupNumber $array(SPACE_GROUP)]

  PleaseWait "Finding ARP/wARP asymmetric unit"

  set_wmat $arrayname
  
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w
  puts $f "MODE UPDATE ALLATOMS \nSYMM $space_gp_number  \nend"
  CloseFile $f
  set out_file [GetTmpFileName ]

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $out_file"
  if { [ReadFile $out_file out_text] && \
	  [ExtractTextLine $out_text  "Asymmetric unit" 0 all line  ] } {
    eval "set lim2 \[ expr double([lindex $line 3]) / double([lindex $line 5]) \]"
    eval "set lim4 \[ expr double([lindex $line 6]) / double([lindex $line 8]) \]"
    eval "set lim6 \[ expr double([lindex $line 9]) / double([lindex $line 11])\]"

    set array(XYZLIM_1) 0.0
    set array(XYZLIM_3) 0.0
    set array(XYZLIM_5) 0.0
    set array(XYZLIM_2) [maxdecimal $lim2 4]
    set array(XYZLIM_4) [maxdecimal $lim4 4]
    set array(XYZLIM_6) [maxdecimal $lim6 4]
} else {
    WarningMessage "Cannot extract ARP/wARP asymmetric unit limits \nThe job will fail if run"
  }

  PleaseWait
}

#--------------------------------------------------------------------
proc seqinshow { arrayname }  {

    upvar #0 $arrayname array
    
    set currentmode [GetValue $arrayname ARP_MODE]
    set buildon $array(BUILD_SIDE)
    
    if { $buildon == "1" } {
	if  { [ regexp WARPNTRACEPHASES  $currentmode ] || \
		[ regexp WARPNTRACEMODEL $currentmode ] } {
	    set array(SEQINSHOW) 1
	} else {
	    set array(SEQINSHOW) 0}
	}
	
	if { $buildon == "0" } {
	    set array(SEQINSHOW) 0
	}
	
    }
    
#--------------------------------------------------------------------


proc set_res_dependent { arrayname }  {

    upvar #0 $arrayname array

   if { $array(WHICHTRACE) == "1" } {

      if { $array(DATA_RESOLUTION) >= 2.1 } {
         set array(NCS_RESTRAINTS) 1
         set array(NCS_EXTENSION) 1
      } else {
         set array(NCS_RESTRAINTS) 0
         set array(NCS_EXTENSION) 0
      }

      if { $array(EXCLUDE_RESOLUTION_MAX) >= 2.3 } {
         set array(NCYCLES) 3 
         } else {
         set array(NCYCLES) 1
         }
      if { $array(EXCLUDE_RESOLUTION_MAX) >= 2.7 } {
         set array(ALBE) 1 
         } else {
         set array(ALBE) 0
         }
      } else {
      set array(NCYCLES) 1
      set array(ALBE) 0
      } 

}

#--------------------------------------------------------------------
    proc combine_mode_checks { arrayname } {
  
     upvar #0 $arrayname array

  set array(TITLE) $array(ARP_MODE)

    set currentmode [GetValue $arrayname ARP_MODE]

	phibfomshow $arrayname
	seqinshow $arrayname
	skipset $arrayname
	randcyc $arrayname

    case $currentmode \
      WARPNTRACEPHASES {
        set array(SMALL_CYCLES) 5 
    } WARPNTRACEMODEL {
        set array(SMALL_CYCLES) 5 
    } MOLREP {
        set array(SMALL_CYCLES) 50 
	set array(REMOTE_JOB) 0
    }

       get_total_cycles $arrayname
    
    if { ![ regexp WARPNTRACEPHASES $currentmode ] } {
	set array(WEIGHTED_FP) 0
       }

       if  { [ regexp MOLREP $currentmode ] } {  
       SetValue $arrayname EXCLUDE_FREER Y  
       SetValue $arrayname REFMAC_REF_SET Y
     } else {
       SetValue $arrayname EXCLUDE_FREER N 
       SetValue $arrayname REFMAC_REF_SET N }
    }

#--------------------------------------------------------------------
proc combine_wilson_xyz { arrayname } {

    get_wilson $arrayname
	 arp_get_assym $arrayname
    set_res_dependent $arrayname

}

#--------------------------------------------------------------------
proc randcyc { arrayname }  {
    
    upvar #0 $arrayname array 
    
    set howmanyrand [GetValue $arrayname RANDTIMES]
    set currentmode [GetValue $arrayname ARP_MODE]


    if  { [ regexp WARPNTRACEPHASES $currentmode ] \
	    || [ regexp WARPNTRACEMODEL $currentmode ] } {
	set cycles $array(BIG_CYCLES)
    } else {
	set cycles $array(SMALL_CYCLES)
    }

    set disp1 0
    set disp2 0
    set disp3 0
    set array(RAND1) 0
    set array(RAND2) 0
    set array(RAND3) 0
    
    case $howmanyrand \
      1 {
	set disp1 1
	set array(RAND1) [ expr $cycles / 3 ] 
	set array(RAND2) 0
	set array(RAND3) 0
    } 2 {
	set disp1 1
	set disp2 1
	set array(RAND1) [ expr $cycles / 4 ] 
	set array(RAND2) [ expr $cycles / 2 ] 
	set array(RAND3) 0
    } 3 {
	set disp1 1
	set disp2 1
	set disp3 1
	set array(RAND1) [ expr $cycles / 5 ] 
	set array(RAND2) [ expr $cycles / 3 ] 
	set array(RAND3) [ expr $cycles / 2 ] 
    }

    if  { [ regexp WARPNTRACEPHASES $currentmode ] \
	    || [ regexp WARPNTRACEMODEL $currentmode ] } {
	set array(RANDON11) 0
	set array(RANDON22) 0
	set array(RANDON33) 0
	set array(RANDON1) $disp1
	set array(RANDON2) $disp2
	set array(RANDON3) $disp3
    } else {
	set array(RANDON11) $disp1
	set array(RANDON22) $disp2
	set array(RANDON33) $disp3
	set array(RANDON1) 0
	set array(RANDON2) 0
	set array(RANDON3) 0
    }

}

#--------------------------------------------------------------------
proc skipset { arrayname }  {
    
    upvar #0 $arrayname array
    
    set currentmode [GetValue $arrayname ARP_MODE]

    if  { [ regexp WARPNTRACEMODEL $currentmode ] } {
	set array(SKIP_CYCLES)  [ expr $array(BIG_CYCLES) / 5 ] 
    } else {
	set array(SKIP_CYCLES)  [ expr $array(BIG_CYCLES) / 10 ] 
    }

    if { $array(SKIP_CYCLES) > 2 } { set array(SKIP_CYCLES)  2 }

}

#--------------------------------------------------------------------
proc phibfomshow { arrayname }  {
    
    upvar #0 $arrayname array
    
    set currentmode [GetValue $arrayname ARP_MODE]
    set phaserestrain [GetValue $arrayname PHASE_RESTRAIN]
    set refmode [GetValue $arrayname REF_MODE]
    
    if { [ regexp Y $phaserestrain ] } {
	set array(PHIBFOMSHOW) 1
    } else {
	set array(PHIBFOMSHOW) 0
    }

    if { ![ regexp SAD $refmode ] } {
       case [GetValue $arrayname PHASE_RESTRAIN ] \
	  Y  {
          SetValue $arrayname REF_MODE PHASED 
     	  } HL {
          SetValue $arrayname REF_MODE PHASED 
	  } N  {
          SetValue $arrayname REF_MODE REFML 
       }
    }

    if  { [ regexp WARPNTRACEPHASES $currentmode ] } { 
	set array(PHIBFOMSHOW) 1
    }

}

#--------------------------------------------------------------------
    proc freebuildon { arrayname } {

    upvar #0 $arrayname array

	if { $array(FLATTEN) == "1" } {
	    set array(FREEBUILD) 1
	}

    }

#--------------------------------------------------------------------
proc set_ref_protocol { arrayname }  {

    upvar #0 $arrayname array
 
    case [GetValue $arrayname REF_MODE] \
	    REFML {
	SetValue $arrayname PHASE_RESTRAIN N
    } PHASED {
	SetValue $arrayname PHASE_RESTRAIN HL 
    } SAD {
	SetValue $arrayname PHASE_RESTRAIN N 
	set array(TWIN) 0  
    }

    phibfomshow $arrayname
}

#--------------------------------------------------------------------
proc get_total_cycles { arrayname }  {

  skipset $arrayname

  upvar #0 $arrayname array

  set array(TOTAL_CYCLES) [ expr $array(SMALL_CYCLES) * $array(BIG_CYCLES) ]
  set array(SIDE_AFTER)  0 

    randcyc $arrayname

}


#--------------------------------------------------------------------
proc get_big_cycles { arrayname }  {

  skipset $arrayname

  upvar #0 $arrayname array

  set array(BIG_CYCLES) [ expr $array(TOTAL_CYCLES) / $array(SMALL_CYCLES) ]
  set array(SIDE_AFTER) 0 

    randcyc $arrayname

}

#--------------------------------------------------------------------
proc refmac_scale { arrayname }  {

  upvar #0 $arrayname array

    set checkflag [GetValue $arrayname EXCLUDE_FREER]

    if { [regexp Y $checkflag]  } {
	SetValue $arrayname REFMAC_REF_SET Y
    } else {
	SetValue $arrayname REFMAC_REF_SET N
    }
}


#--------------------------------------------------------------------
proc get_wilson { arrayname } {
#--------------------------------------------------------------------
  upvar #0 $arrayname array

  set fobs $array(FP)
  set sig $array(SIGFP)
  set residues $array(NRES)
  set rexcl $array(EXCLUDE_RESOLUTION)
  set rmin $array(EXCLUDE_RESOLUTION_MIN)
  set rmax $array(EXCLUDE_RESOLUTION_MAX)
  set mtzfile [GetFullFileName0 $arrayname HKLIN]    
  set pdbfile [GetFullFileName0 $arrayname MODELIN]    

# Dont' try to do the calcualtion if any of the required parameters are undefined
  if { $fobs == "" || $fobs == "Unassigned" || \
       $sig == "" || $sig == "Unassigned" || \
       $residues == "" || \
       ![file exists $mtzfile] } { return }

# Don't repeat the calculation if has been done already with same parameters
  if { $array(WILSON_B) != "" && [ElementExists $arrayname WILSON_PARAMS] && \
     [StringSame $fobs [lindex $array(WILSON_PARAMS) 0]] && \
     [StringSame $sig  [lindex $array(WILSON_PARAMS) 1]] && \
     [StringSame $residues [lindex $array(WILSON_PARAMS) 2]] && \
     [StringSame $rexcl [lindex $array(WILSON_PARAMS) 3]] && \
     [StringSame $rmin [lindex $array(WILSON_PARAMS) 4]] && \
     [StringSame $rmax [lindex $array(WILSON_PARAMS) 5]] && \
     [StringSame $pdbfile [lindex $array(WILSON_PARAMS) 6]] && \
     [StringSame $mtzfile [lindex $array(WILSON_PARAMS) 7]] } {  return }
  
  PleaseWait "Calculating Wilson B, solvent content and number of atoms"
       
  set tmp_file [GetTmpFileName]
  OpenFile $tmp_file f w

  puts $f "MODE WILSON NRES $array(NRES)\nFILES CCP4 HKLIN=$mtzfile\nLABELS FP=$fobs SIGFP=$sig FUSE=$fobs \nRESO $array(EXCLUDE_RESOLUTION_MIN) $array(EXCLUDE_RESOLUTION_MAX)\nend"

  CloseFile $f

  set out_file [GetTmpFileName ]

  catch "exec [FileJoin [GetEnvPath warpbin] arp_warp] < $tmp_file > $out_file"

  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text  "Bfactor" 0 all line1  ] } {
    set wilsonb [expr [lindex $line1 3] ]
    set array(WILSON_B) [maxdecimal $wilsonb 2]
  }

  if { [ReadFile $out_file out_text] && \
       [ExtractTextLine $out_text  "Solvent content" 0 all line2  ] } {
    set solventc [expr [lindex $line2 2]  ]
    set array(SOLVENTC) [maxdecimal $solventc 2 ]
  }

    set array(WILSON_PARAMS) [list $fobs $sig $residues $rexcl $rmin $rmax $pdbfile $mtzfile]
#    check_input $arrayname WILSON_PARAMS

  PleaseWait

}

#--------------------------------------------------------------------
proc is_pir_file { arrayname } {
#--------------------------------------------------------------------

    upvar #0 $arrayname array

  set filen [GetFullFileName1 $array(SEQIN) $array(DIR_SEQIN) ]
  # Read file contents into a list split on newlines
  if { ![ReadFile $filen file_text -split] } {
    WarningMessage "Could not open file!"
    return 0
  }

  # Must have at least 3 lines in the file I guess
  set nlines [llength $file_text]
  if { $nlines < 3 } {
    WarningMessage "Not enough lines in .pir file!"
    return 0
  }

  # Start to check the format

  # First line starts with a ">" and with any trailing text
  set line [lindex $file_text 0]
  if { ![regexp -- "^>" $line] } {
    WarningMessage "First line of .pir file doesn't start with \">\"!"
    return 0
  }

  # Second line is empty - white spaces allowed
  set line [lindex $file_text 1]
  if { ![regexp -- "^\[ \t\]*$" $line] } {
    WarningMessage "Second line of .pir file is not empty!"
    return 0

  }

  # Remaining lines can only contain one or more of the characters
  # ACDEFGHIKLMNQPRSTYWV
#  for { set i 2 } { $i < $nlines } { incr i } {
#      set line [lindex $file_text $i]
#      if {![regexp -- "^\[ACDEFGHIKLMNQPRSTYWV\]+$" $line]} {
#         puts "Non-standard amino acid code in .pir file! $line"
#         return 0
#      }
#  }
  # Reached end of file successfully, so this matches
  # our description of .pir file
  return 1
}

#--------------------------------------------------------------------
proc arp_pdb_cryst { arrayname } {
#
# This I left in
# Ideally compares pdb header and mtz cell
# when both are defined ( in mode FREEEXISTS )
# produces error if not identical
# I guess easier to do before run ???
#--------------------------------------------------------------------
  upvar #0 $arrayname array
  if  {![OpenFile $array(MODEL_IN) f r+ ] } {
    return 1
  }
  set pdb_text [read $f]
  CloseFile $f
  set new_line [format "CRYST1 %8.3f %8.3f %8.3f %8.3f %8.3f %8.3f" \
        $array(CELL_1) $array(CELL_2) $array(CELL_3) \
        $array(CELL_4) $array(CELL_5) $array(CELL_6) ]
  if { ![regexp CRYST1 $pdb_text] } {
    set action [ChooseOptionDialog "PDB input to ARP/wARP" "ARP/wARP" \
"ARP/wARP will fail because there are no cell parameters in PDB file.
By default the following line will be added to PDB:
$new_line" \
    { Abort OK } -default 1 ]
    if [regexp Abort $action] { return 0 }
    OpenFile $array(MODEL_IN) f w
    puts $f $new_line
    puts $f $pdb_text
    CloseFile $f
  } else {
    set line [ExtractFromText $pdb_text CRYST1 0 0 ]
    set same 1
    for { set n 1 } { $n <= 6 } { incr n } {
      if { $array(CELL_$n) != [lindex $line $n] } { set same 0 }
    }
    if { !$same } { 
      set action [ChooseOptionDialog "PDB input to ARP/wARP" "ARP/wARP" \
"ARP/wARP will fail because cell parameters in PDB file:
$line
do not match those in MTZ file.
By default PDB file will be updated to match MTZ file:
$new_line" \
    { Abort OK } -default 1 ]

      if [regexp Abort $action] { return 0 }
      regsub -- "CRYST1\[^\n]*\n" $pdb_text "$new_line\n" new_pdb_text
      DeleteFile  $array(MODEL_IN)
      OpenFile $array(MODEL_IN) f w
      puts $f $new_pdb_text
      CloseFile $f
    }
  }
  return 1
}



#--------------------------------------------------------------------
proc arp_warp_classic_task_window { arrayname } {
#--------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "ARP/wARP Version 7.3.0: Model Building and Density Improvement" "ARP/wARP" \
        [ list "Required parameters"\
        "ARP/wARP flow parameters " \
        "Refmac parameters"\
        "Crystal parameters"\
        "Test and comparison parameters"\
        "Submit a remote job at the Hamburg Cluster"  ] ] == 0 } return 

  set help_source [file join [GetEnvPath warpdoc] warp.htm ]
  SetProgramHelpFile $help_source



#=PROTOCOL==============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE
   set arplogo [image create photo -file [ FileJoin [GetEnvPath warpbin] ARP_logo_small.gif ] ]
   set logo [label $line.log -image $arplogo]
   pack $logo

  CreateLine line \
    message "Choose  the application of ARP/wARP you want to use" \
    label "Run ARP/wARP for"\
    widget ARP_MODE \
    -command "combine_mode_checks $arrayname" 


  OpenFolder file 


#=Toggle folder depending on mode ====================================================

  OpenSubFrame frame -toggle_display ARP_MODE open { WARPNTRACEMODEL WARPNTRACEPHASES MOLREP }
  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -setlabin FREE [list FREE FreeR FreeR_flag] \
       -setfileparam space_group_name SPACE_GROUP \
        -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN \
        -setfileparam resolution_max EXCLUDE_RESOLUTION_MAX \
        -setfileparam resolution_max DATA_RESOLUTION \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
        -command "combine_wilson_xyz $arrayname" 

  CreateLabinLine line \
    "Choose Fobs amplitude (Fobs) and sigma (Sigma)" HKLIN \
        "Fobs    " FP  {} \
     -command "get_wilson $arrayname" \
     -sigma "Sigma  " SIGFP  {} 
  CloseSubFrame

  CreateLabinLine line \
    "Choose different Fobs for initial map calculation, if preweighted leave FOM as Unassigned" \
     HKLIN "FBEST" FBEST  {} \
     -toggle_display WEIGHTED_FP open 1 

  CreateLabinLine line \
    "Choose phase (PHIB) and optional weighting factor (FOM)" \
     HKLIN "PHIB" PHIB  {} \
     -sigma "FOM" FOM  {} \
     -toggle_display PHIBFOMSHOW open 1 

  CreateLabinLine4 line \
    "Hendrickson-Lattman coefficients" \
    HKLIN "HLA" HLA  HLA \
     -dependent "HLB" HLB HLB \
     -dependent "HLC" HLC HLC \
     -dependent "HLD" HLD HLD \
     -toggle_display PHASE_RESTRAIN open HL 

CreateLabinLine4 line \
    "Enter labels for Friedel pairs" \
    HKLIN "F(+)" FPP FPP \
    -sigma "SigF(+)" SIGFPP SIGFPP \
    -dependent "F(-)" FPM FPM \
    -sigma2 "SigF(-)" SIGFPM SIGFPM \
    -toggle_display REF_MODE open SAD 

  CreateInputFileLine line \
      "Enter name of file containing molecule coordinates (MODELIN)" \
      "Starting model in " \
      MODELIN DIR_MODELIN \
      -command "get_wilson $arrayname" \
      -toggle_display ARP_MODE open { WARPNTRACEMODEL MOLREP } 

  CreateInputFileLine line \
      "Enter name of file containing heavy atom coordinates (MODELIN)" \
      "Heavy atoms model in " \
      HEAVYIN DIR_HEAVYIN \
      -toggle_display REF_MODE open SAD 

  CreateInputFileLine line \
      "Enter name of file containing the sequence (SEQIN)" \
      "Sequence in " \
      SEQIN DIR_SEQIN \
      -toggle_display SEQINSHOW open 1  \
      -command "is_pir_file $arrayname" 
 

#=PARAMETERS==========================================================

  OpenFolder 1 ARP_MODE open 
# 
  CreateLine line \
    message "The total number of residues in the asymmetric unit " \
    label "There are" \
    widget NRES -oblig \
    -command "get_wilson $arrayname" \
    label "total residues in the AU, which belong to" \
    message "The total number of molecules in the AU "\
    widget NMOL \
    -width 2 \
    label "molecule(s)." \
    toggle_display ARP_MODE open { WARPNTRACEMODEL WARPNTRACEPHASES } close

  CreateLine line \
    message "The total number of residues in the asymmetric unit " \
    label "There are" \
    widget NRES -oblig \
    -command "get_wilson $arrayname" \
    label "total residues in the AU."\
    toggle_display ARP_MODE open { MOLREP } close


  CreateLine line \
    message "The number of ARP/wARP refinement cycles that will be performed " \
    label "Do" \
    widget SMALL_CYCLES -oblig \
    -width 3 \
    -command "get_total_cycles $arrayname" \
    label "ARP/REFMAC refinement cycles of the model." \
    toggle_display ARP_MODE hide { WARPNTRACEMODEL WARPNTRACEPHASES } open 

  CreateLine line   \
    message "The number of autobuilding cycles that will be performed" \
    label "Do" \
    widget BIG_CYCLES -oblig \
    -command "get_total_cycles $arrayname" \
    -width 3 \
    label "cycles of autobuilding (" \
    message "The total number of ARP refinement cycles (autobuilding cycles times ARP refinement cycles)"\
    widget TOTAL_CYCLES -oblig \
    -width 3 \
    -command "get_big_cycles $arrayname" \
    label " total cycles)." \
    toggle_display ARP_MODE open { WARPNTRACEMODEL WARPNTRACEPHASES } close

  CreateLine line \
    label "Use in REFMAC5 the"\
    message "Phased or SAD or normal ML target function " \
    widget REF_MODE \
    -command "set_ref_protocol $arrayname"\
    label " target function and do "\
    message "Include or exclude the reflections flagged for Free R" \
    widget EXCLUDE_FREER \
    -command "refmac_scale $arrayname"\
    label " the Free R flag"

  OpenSubFrame frame -toggle_display REF_MODE open { SAD } \

  CreateLine line \
      message "Choose how to determine f' and f''" \
      label "Scattering"  widget ANO_OPTION \
      label ""  \
      message "Wavelength for data" \
      widget SCAT_LAMBDA_SAD -oblig label "A."\
      toggle_display ANO_OPTION open LAMBDA

  CreateLine line \
      message "Choose how to determine f' and f''" \
      label "Scattering"  widget ANO_OPTION \
      toggle_display ANO_OPTION open CUKA

  CreateLine line \
      message "Choose how to determine f' and f''" \
      label "Scattering"  widget ANO_OPTION \
      message "Measured values" \
      label "for atom" widget SCAT_ATOM -oblig "f' ="  widget SCAT_FP_SAD  -oblig label "f'' =" widget SCAT_FDP_SAD  -oblig \
      toggle_display ANO_OPTION open MEASURED

  CloseSubFrame


#------------------------------------------------------

OpenFolder 2 ARP_MODE closed 
 
CreateLine line \
        message "Feed into REFMAC information for restraining free (dummy) atoms " \
        widget USE_COND \
        toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
        label "Use Conditional Restraints for free atoms."

CreateLine line \
        message "Feed into REFMAC information for restraining free (dummy) atoms " \
        widget FORCE_COND \
        toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
        label "Impose the use of Conditional Restraints for very large structures, time consuming."
 
CreateLine line \
        message "Set REFMAC to use non-crystallographic symmetry restraints" \
        widget NCS_RESTRAINTS \
        toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
        label "Use Non-Crystallographic Symmetry Restraints."

CreateLine line \
        message "Use non-crystallographic symmetry to extend chains" \
        widget NCS_EXTENSION \
        toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
        label "Use Non-Crystallographic Symmetry information to extend chains."

CreateLine line \
        message "Use Loopy to build loops between chain fragments at the end of the run. " \
        widget LOOPS \
        toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
        label "Use Loopy to build loops between chain fragments at the end of the run."

  CreateLine line \
    message "Dock side chains while autobuilding or not" \
    widget BUILD_SIDE\
    -command "seqinshow $arrayname"\
    label "Dock the autotraced chains to sequence after " \
    message "Only do the sequence docking after this number of autobuilding cycles"\
    widget SIDE_AFTER \
    -width 2 \
    toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
    label " autobuilding cycles."

CreateLine line \
    message "Click if the heavy atoms are the methionines" \
    widget IS_SEMET \
    -toggle_display REF_MODE open SAD \
    label "Sequence dock as a Se-Methionine substituted protein." 

  CreateLine line \
    message "Perform a quick secondary structure tracing before the actual model building to help especially in low resolution" \
    widget ALBE \
    toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
    label "Search for helices and strands before each building cycle."

  CreateLine line \
    message "Maybe need a different amplitude for initial map ? (e.g. after SHARP)" \
    widget WEIGHTED_FP \
    toggle_display ARP_MODE open { WARPNTRACEPHASES } close \
    label "Use a different (i.e. pre-weighted) Fobs for initial map calculation."

  CreateLine line \
    message "The number of ARP/wARP refinement cycles between each autobuilding" \
    label "Do" \
    widget SMALL_CYCLES -oblig \
    -width 3 \
    -command "get_total_cycles $arrayname" \
    label "ARP/REFMAC refinement cycles of the model between autobuilding." \
    toggle_display ARP_MODE open { WARPNTRACEMODEL WARPNTRACEPHASES } close

  CreateLine line \
    message "Define how the starting model is to be treated"\
    widget KEEP_MODEL\
    toggle_display ARP_MODE open WARPNTRACEMODEL \
    label "Keep the geometry of the model, do NOT convert to free atoms" 

  CreateLine line \
    message "Sometimes it helps to skip the autobuilding to let the initial model refine a bit" \
    widget SKIP_BUILD\
    label " Skip the autobuilding for the first" \
    message "The number of cycles for which to skip the autobuilding"\
    widget SKIP_CYCLES\
    -width 2 \
    toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} \
    label " autobuilding cycles." 

  CreateLine line \
    message "For bad models from molecular replacement it might help to make a free atoms model in the 2mFoDFc map" \
    widget FREEBUILD\
    -command "freebuildon $arrayname"\
    toggle_display ARP_MODE open WARPNTRACEMODEL \
    label "Before the start of autobuilding construct new free atoms model in map"

  CreateLine line \
    message "For even worse models from molecular replacement it might help to do solvent flattening before free atoms building" \
    widget FLATTEN\
    -command "freebuildon $arrayname"\
    toggle_display ARP_MODE open WARPNTRACEMODEL \
    label "Before the start of autobuilding perform density modification with DM"

  CreateLine line \
    message "Poor man's simulated annealing ... escapes local minima by applying small random shifts" \
    widget RANDTIMES \
    -command "randcyc $arrayname" \
    label " atomic positions during this run." \

  CreateLine line \
    message "Random shifts parameters" \
    label "     After cycle " \
    widget RAND1 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT1 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT1 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON11 hide 0 \

  CreateLine line \
    message "Random shifts parameters" \
    label "  After cycle " \
    widget RAND2 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT2 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT2 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON22 hide 0 \

  CreateLine line \
    message "Random shifts parameters" \
    label "     After cycle " \
    widget RAND3 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT3 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT3 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON33 hide 0 \

  CreateLine line \
    message "Random shifts parameters" \
    label "  In place of autobuild cycle " \
    widget RAND1 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT1 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT1 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON1 hide 0 \

  CreateLine line \
    message "Random shifts parameters" \
    label "     In place of autobuild cycle " \
    widget RAND2 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT2 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT2 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON2 hide 0 \

  CreateLine line \
    message "Random shifts parameters" \
    label "     In place of autobuild cycle " \
    widget RAND3 \
    -width 4 \
    label " apply " \
    widget RANDSHIFT3 \
    -width 4 \
    label " A shifts and B cutoff " \
    widget BCUT3 \
    -width 4 \
    label " * WilsonB " \
    toggle_display RANDON3 hide 0 \

  CreateLine line \
    message "It is often helpful to repeat autotracing a few times without refinement in between" \
    label "Iterate the autotracing up to" \
    widget MULTITRACE \
    toggle_display ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} hide \
    label "times."

  CreateLine line \
    message "The density levels, in sigmas' for addition and deletion of model atoms" \
    label "Add atoms in density above" \
    widget ADDATOM_SIGMA \
    label "sigma, and remove atoms in density below" \
    widget REMATOM_SIGMA \
    label "sigma."

  CreateLine line \
    message "You might want to allow the program to update more atoms than it want to ..." \
    label "Add and remove atoms" \
    widget UP_UPDATE \
    label "times more/less than calculated automatically."

  CreateLine line \
    message "You might want skip the Wilson statistics warning if you are fed up with them ..." \
    widget CHECK_WILSON \
    label "Disable Wilson plot statistics checks." 

#------------------------------------------------------

OpenFolder 3 closed

CreateLine line \
        message "Allow REFMAC to analyze the data and correct for presence of twinning." \
        widget TWIN \
        label "Attempt to correct for data collected from a twinned crystal."\
        toggle_display REF_MODE hide SAD 

CreateLine line \
        message "Number of cycles of refinement for Refmac run" \
        widget NCYCLES \
        -width 2 \
        label "cycles of refinement with Refmac." 

CreateLine line \
        message "Choose if phase restrains will be used, giving a Phase/FOM or HL coefficients" \
        label "Include"\
        widget PHASE_RESTRAIN\
        -command "phibfomshow $arrayname" \
        label "phase restraints"\
        label "(include a blurring factor of" \
	message "A blurring factor can downweight the FOM if suspected to be overestimated"\
        widget PHASE_BLUR \
        label ")" \
        toggle_display REF_MODE hide SAD 

CreateLine line \
        message "Damp shifts (for limited data or unrestrained refinement) (DAMP)" \
        label "Damp shifts using Pdamp" \
        widget DAMP_P \
        label "and Bdamp" \
        widget DAMP_B

CreateLine line \
        message "Manual or automatic weighting for Xray/geometry terms" \
        widget WEIGHT_MODE \
        label "matrix weighting for Xray / Geometry " 

CreateLine line \
        message "The relative matrix weight for xray versus geometrical terms ?" \
        label "Matrix weight for Xray / Geometry " \
        widget WMAT \
        toggle_display WEIGHT_MODE hide AUTO

CreateLine line \
        message "Use Jelly Body restraints"\
        widget RIDGE_RESTRAINTS \
        label "Jelly Body restraints"\
        toggle_display REFMAC_VERSION hide REFMAC4 

CreateLine line \
        message "Tronrud-like scaling (BULK) or a simple scaling factor"\
        label "Use for scaling the "\
        widget SCALE \
        label "scaling model, with an "\
        message "Use anisotropic scaling factors or isotropic ones"\
        widget SCANIS \
        label "scaling B factor."

CreateLine line \
        label "Determines the free R label for reflections to be excluded from refinement"  \
        message "Label for the free set of data in input MTZ file" \
        widget FREE \
        toggle_display EXCLUDE_FREER hide N

CreateLine line \
        label "Scaling and sigmaa calculation will be done with the" \
        message "Determines if Rfree reflections will be used in scaling and sigmaa calculations" \
        widget REFMAC_REF_SET \
        toggle_display EXCLUDE_FREER hide N  \
        label "set of reflections   "

CreateLine line \
        message "A Solvent Mask Correction can be used at final refinement stages"\
        widget SOLVENT \
        label "Solvent Mask correction"\
        toggle_display REFMAC_VERSION hide REFMAC4 


#------------------------------------------------------

OpenFolder 4 ARP_MODE  closed

  CreateLine line \
    message "Space group (default as in MTZ file) (SYMMETRY)" \
    label "Generate map in space group" \
    help symmetry \
    varlabel SPACE_GROUP

  CreateLine line \
    message "Cell dimensions (default taken from MTZ file" \
    help cell \
    label "Cell a="   \
    varlabel CELL_1 \
    label "b=" \
    varlabel CELL_2 \
    label "c=" \
    varlabel CELL_3 \
    label "alpha=" \
    varlabel CELL_4 \
    label "beta=" \
    varlabel CELL_5 \
    label "gamma=" \
    varlabel CELL_6

  CreateLine line \
    message "ARP/wARP asymmetric unit limits (derived when you select MTZ)" \
    label "ARP/wARP asymmetric unit" \
    varlabel XYZLIM_1 \
    varlabel XYZLIM_2 \
    varlabel XYZLIM_3 \
    varlabel XYZLIM_4 \
    varlabel XYZLIM_5 \
    varlabel XYZLIM_6

  CreateLine line \
    message "Wilson B factor and solvent content (derived when you select MTZ)" \
    label "Wilson B factor" \
    varlabel WILSON_B  \
    label "  Solvent content" \
    varlabel SOLVENTC  


  CreateLine line \
    message "Refine with reflections below and/or above resolution limit in \
                  Angstrom (RESOLUTION)" \
    help resolution \
    widget EXCLUDE_RESOLUTION \
    label "Use reflections between" \
    widget EXCLUDE_RESOLUTION_MIN \
    label "and" \
    widget EXCLUDE_RESOLUTION_MAX \
    -command "get_wilson $arrayname" \
    label "Angstrom" 
   
CloseSubFrame

#------------------------------------------------------

OpenFolder 5 ARP_MODE closed

  CreateLine line \
    message "Do not delete intermediate files" \
    widget KEEP_JUNK \
    label "Keep intermediate files."

CloseSubFrame

#------------------------------------------------------

OpenFolder 6 ARP_MODE open {WARPNTRACEPHASES WARPNTRACEMODEL} closed { MOLREP }

CreateLine line \
        message "Allows remote submission to the Hamburg cluster" \
        widget REMOTE_JOB \
        label "Submit the job for remote execution at the Hamburg cluster"\
        toggle_display ARP_MODE hide  { MOLREP }

CreateLine line \
        message "Allows remote submission to the Hamburg cluster" \
        label "Remote submission is only allowed for automated model building jobs"\
        toggle_display ARP_MODE hide  {WARPNTRACEPHASES WARPNTRACEMODEL}

CreateLine line \
        message "You need to give a valid Email address to receive instructions for how to get the results" \
        label "Your Email address " \
        toggle_display REMOTE_JOB open 1 \
        widget USER_EMAIL -oblig -width 30 

CreateLine line \
        message "Determine if you allow your data to be used by the developers community or not " \
        label "Job data " \
        toggle_display REMOTE_JOB open 1 \
        widget DATAKEEP_MODE 

CloseSubFrame



#------------------------------------------------------

}
