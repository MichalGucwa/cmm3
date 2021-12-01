#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# solomon.tcl --
#
# Template for task interface
#
# CCP4Interface 
#
# =======================================================================

#---------------------------------------------------------------------
proc solomon_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
upvar #0 $typedefVar typedef
global dependentdef

set typedef(_solomon_mode)       {menu  {  "flipping" \
                                           "flattening" }
                                        {  FLIPPING
                                           FLATTENING } }


set dependentdef(solomon_multiplier)  { { flipping flattening }
                                        { 1 0 }
                                        { -0.75 -1.0 0.0 0.0 } }

return 1

}




# procedure run before script is written

#----------------------------------------------------------------------------
proc solomon_run { arrayname } {
#----------------------------------------------------------------------------
  upvar #0 $arrayname array

#  puts "solomon_run EXTEND_RESOLUTION $array(EXTEND_RESOLUTION)"

  if { $array(EXTEND_RESOLUTION) } {

# check we've got some resolution parameters otherwise liable to bomb out later

   if { $array(INITIAL_RESOLUTION) == "" || $array(FINAL_RESOLUTION) == "" } {
      WarningMessage \
	"You must enter values for initial and final resolution.  Job will not be run.  Please reset parameters and try again."
      return 0
   }

# Check that resolution extension is reasonable

   set extend_range \
     [expr $array(INITIAL_RESOLUTION) - $array(FINAL_RESOLUTION) ]

   if  { $extend_range > $array(MAXIMUM_EXTENSION) } {
     WarningMessage \
      "Attempting to extend resolution > $array(MAXIMUM_EXTENSION) Angstrom is not reasonable.  Job will not be run.  Please reset parameters and try again."
     return 0
   }

   set extend_cycles [expr round ($extend_range * 10.0) ]
   set min_cycles [expr $extend_cycles + 6 ]

   if { $array(NCYCLES) < $min_cycles }  {

     WarningMessage "Increasing number of cycles to $min_cycles to allow for phase extension"     
     set array(NCYCLES) $min_cycles

   } else {
     set extend_cycles [ expr $array(NCYCLES) - 6 ]
   }
   
   set extend_step [expr  $extend_range / $extend_cycles ]
#   puts "extend_cycles $extend_cycles extend_step $extend_step"

   for { set i 1 } { $i <= 3 } { incr i } {
     set array(RESOLUTION,$i) $array(INITIAL_RESOLUTION)
   }
   for { set i 1 } { $i <= $extend_cycles } { incr i } {
     set  ii [expr $i + 3 ]
     set array(RESOLUTION,$ii) \
        [expr $array(INITIAL_RESOLUTION) - ($i * $extend_step)]
   }
   for { set i [expr $extend_cycles +4] } {$i <= $array(NCYCLES) } { incr i } {
     set array(RESOLUTION,$i) $array(FINAL_RESOLUTION)
   }

  } else {

# not extending resolution

    for { set i 1 } { $i <= $array(NCYCLES) } { incr i } {
     set array(RESOLUTION,$i) $array(INITIAL_RESOLUTION)
    }
  }

  return 1
}

#------------------------------------------------------------------
proc solomon_multiplier { arrayname } {
#------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(SOLVENT_MULTIPLIER) ""
#   SOLOMON_MODE AUTO_SCALING
}


#=CREATE=WINDOW=AND=SUBWINDOWS===========================================

proc solomon_task_window { arrayname } {

  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
       	"Run Solomon - Density Modification" "Solomon" \
        [ list "Required Parameters"  \
        "Infrequently Used Options"  ] ] == 0 } return

  SetDefaultMapFormat $arrayname MAPOUT_FORMAT

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
        message "Generate map" \
        widget IFMAPOUT \
        label "Create map file in" \
        widget MAPOUT_FORMAT \
        label "format"


#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name (HKLIN)" \
      "MTZ in" \
       HKLIN DIR_HKLIN \
       -fileout HKLOUT DIR_HKLOUT _solomon \
       -setfileparam resolution_max FINAL_RESOLUTION \
       -setfileparam resolution_min EXCLUDE_RESOLUTION_MIN

  CreateLabinLine line \
    "Choose amplitude (FO) and OBLIGATORY sigma (SIGFO)" \
     HKLIN "FO    " FO  {FP F_P FOBS} \
     -sigma "Sigma  " SIGFO  {SIGFP SIGP SIG_FP SIG_OBS}

  CreateLabinLine line \
    "Choose phase (PHIIN) and OBLIGATORY weight (WIN)" \
     HKLIN "PHIIN    " PHIIN  {NULL} \
     -sigma "Weight" WIN  {NULL}

  CreateOutputFileLine line \
      "Enter output MTZ file name or click file browser icon (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT


#=PARAMETERS==========================================================

  OpenFolder 1

  CreateLine line \
	message "Enter fraction of unit cell volume which is solvent (SLVFRC)" \
	help slvfrc \
	label "Fraction of solvent in unit cell" \
	widget SOLVENT_FRACTION \
		-oblig

  CreateLine line \
	message "Choose solvent flattening or flipping (MULSOLV (AUTO))" \
        help mulsolv \
	widget AUTO_SCALING \
	  -command "solomon_multiplier $arrayname" \
        label "Auto refine multiplier in solvent" \
	widget SOLOMON_MODE  \
	  -command "solomon_multiplier $arrayname" \
	label "mode"

  SetProgramHelpFile sfall

  CreateLine line \
        message "Choose to extend resolution (SFALL RESOLUTION)" \
        help resolution \
	widget EXTEND_RESOLUTION \
	label "Extend resolution from" \
	widget INITIAL_RESOLUTION \
	  -oblig \
	label "to" \
	widget FINAL_RESOLUTION \
	  -oblig \
        message "Choose number of cycles of refinement" \
        label "over" \
        widget NCYCLES \
	label "cycles of refinement" 

  CreateLine line \
        message "Use to data to minimum resolution cutoff" \
        label "Minimum resolution cutoff" \
        widget EXCLUDE_RESOLUTION_MIN


  CreateLine line \
 	message "Run in P1 for spacegroups not covered by FFT and Sfall" \
        help space_groups \
	widget RUN_IN_P1 \
	label "Use P1 spacegroup and map for whole cell"


#=Unusual parameters================================================================

  OpenFolder 2 closed

  SetProgramHelpFile solomon

  CreateLine line \
        message "Choose to truncate map for extremes of protein density range (TRUNC)" \
        help trunc \
	label "Truncate protein density for regions below " \
	widget TRUNCATE_MIN \
	label "or above" \
	widget TRUNCATE_MAX \
	label "of density range"

  CreateLine line \
        message "Reconstruct low resolution SFs (EXTRUDE & PTOS)" \
        help extrude \
	widget EXTRUDE_MODE \
	  -toggleon \
	label "Reconstruct low resolution SFs assuming mean protein/solvent density"\
	help ptos \
	widget DENSITY_RATIO

  CreateLine line \
        message "Solvent analysis - use solvent radius (RADIUS)" \
 	help radius \
	label "Solvent analysis radius" \
	widget SOLVENT_RADIUS

  SetProgramHelpFile fft

  CreateLine line \
        message "Use fixed grid for all generated maps" \
	help grid \
	widget GRID \
	  -toggleon \
	label "Use fixed grid for all maps  nx=" \
	widget GRID_1 \
        label " ny=" \
	widget GRID_2 \
        label " nz=" \
	widget GRID_3

}

#=END=======================================================================


