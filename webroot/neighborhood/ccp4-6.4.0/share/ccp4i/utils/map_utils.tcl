#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#=========================================================================#
# CCP4 Interface map_utils.tcl
#
# Map Handling Utilities 
#
#=========================================================================

#CCP4i_cvs_Id $Id$

#d_index_title Map Handling Utilities (utils/map_utils.tcl)
#d_intro These procedures are usually used in run scripts but they could \
be used within the main ccp4i process.
#d_intro Many of the utilities require function from \
$CCP4I_TOP/src/CCP4_utils.tcl and that the data in $CCP4I_TOP/etc/crystal.lib \
and these are initiallised by commands at the top of map_utils.tcl \
which are run at the global level when the file is first sourced.

#
# Make sure we have loaded the crystal/symmetry params
#

if { ![regexp InitialiseXtlData [info procs InitialiseXtlData]] } {
  source [SearchPath TOP src CCP4_utils.tcl]
  InitialiseXtlData
}

#-------------------------------------------------------------------
proc ExtendMap { mapin mapout xyzin border } {
#-------------------------------------------------------------------
#d_sum Interface to mapmask program to extend map to cover molecule
#d_arg mapin Full path name of input map
#d_arg mapout Full path name of output map
#d_arg xyzin Full path name of molecule coordinate file
#d_arg border Border in Angstrom around the molecule

  WriteComFile extend_script "BORDER $border"

  set status [Execute \
      "[BinPath mapmask] MAPIN \"$mapin\" MAPOUT \"$mapout\" XYZIN \"$xyzin\"" \
      $extend_script program_status report ]

  return $status
}

#-------------------------------------------------------------------
proc ConvertMapAsu { mapin mapout } {
#-------------------------------------------------------------------
#d_sum Run mapmask convert map to cover the standard CCP4 asymmetric unit
#d_arg mapin Full path name of input map
#d_arg mapout Full path name of output map

  WriteComFile extend_script "XYZLIM ASU"

  set status [Execute \
      "[BinPath mapmask] MAPIN \"$mapin\" MAPOUT \"$mapout\"" \
      $extend_script program_status report ]

  return $status
}


#-------------------------------------------------------------------
proc ConvertMapFormat { format mapin mapout { LOG_FILE {} } args } {
#-------------------------------------------------------------------
#d_sum Convert from CCP4 to alternative map formats
#d_desc Beware that this uses non-CCP4 programs: mapman from Uppsala and \
mbkall from MSI. The CCP4i installer must have specified, in the CCP4i \
configure window, the command used to run these programs on their installation.
#d_desc NB There is not an XtalView map format - the SF file is imported \
to XtalView and it generates maps.
#d_arg format Required format: O, QUANTA
#d_arg mapin Full path name of input map
#d_arg mapout Full path name of output map
#d_arg LOG_FILE Optional name of a log file for log output
#d_opt0 -nonorm
#d_opt1 When outputting O format files do not normalise


# Take parameters from the global array configure which has 
# beed set up as part of ccp4ish
  global configure
  global preferences

   if [lsearch -regexp nono $args] { set norm 0 }

   if { $LOG_FILE == "" } {set LOG_FILE [GetTmpFileName -ext log] }

   set tmp_log [GetTmpFileName -ext log]

   if [regexp O $format ] {

# Find out size of map - do we need to use extra large
     GetMapHeader $mapin spg cll xyzlim grid axes
     set mapsize [expr ( [lindex $xyzlim 1] - [lindex $xyzlim 0] + 1 ) * \
			( [lindex $xyzlim 3] - [lindex $xyzlim 2] + 1 ) * \
			( [lindex $xyzlim 5] - [lindex $xyzlim 4] + 1 ) ]
#     puts "mapsize $mapsize"
     set mapman_script [GetTmpFileName -ext _com ]
     set script "READ map \"$mapin\" CCP4\n"
     if { $preferences(MAPMAN_NORMALISE) }  { append script "NORMALISE map\n" }
     append script "MAPPAGE map \"$mapout\"\nQUIT \nY\n"
 
     WriteFile $mapman_script $script

# Set up command line to run mapman
     set mapman_cmd "$configure(O_MAPMAN)"
     if { $mapsize > $configure(MAPMAN_MAXSIZE) } {
	 append mapman_cmd " MAPSIZE [expr $mapsize + 10000]"
     }
# Stop Execute writing comment lines to script - 
#   mapman/mbkall don't like them
     set status [Execute $mapman_cmd $mapman_script  \
                program_status report  -success 1 -nocomments -log $tmp_log ]

     WriteToLog "Running $configure(O_MAPMAN) .. $report"

     if { !$status } {
       WriteToFile "ERROR running $configure(O_MAPMAN) - can not convert map to O format
Maybe the pathname of the program is not correct - see the configure 
documentation in CCP4I_TOP/help/general/configure.html"
     }

     TranscribeFile $tmp_log $LOG_FILE

   } elseif [regexp QUANTA $format ]  {

     set status [ Execute \
       "$configure(QUANTA_MBKALL) CCP4 $mapin $mapout byte" \
        {} program_status report -nocomments ]

     if { !$status } {
       WriteToFile "ERROR running $configure(QUANTA_MBKALL) - can not convert map to Quanta format
Maybe the pathname of the program is not correct - see the configure
documentation in CCP4I_TOP/help/general/configure.html"
     }


     WriteToLog "Running $configure(QUANTA_MBKALL) to convert  
$mapin to Quanta format $mapout\n $report"
   }
   return $status
}

#------------------------------------------------------------------------
proc CreateMap { format HKLIN mapVar title prog_labin labin args } {
#------------------------------------------------------------------------
#d_sum Create a map of optional type in various formats
#d_desc The FFT program is run to create the map and, if necessary, a file
format conversion is done.  Note that for XtalView format a SF file is created

#d_arg format Required file format: CCP4, O, QUANTA, XtalView
#d_arg HKLIN Input MTZ file
#d_arg mapVar Output map file name, if necessary the file extension is reset.
#d_arg title A title for the FFT job and the map file
#d_arg prog_labin The input program labels for FFT (in TCL list format)
#d_arg labin The input MTZ labels for FFT (in TCL list format)
#d_opt0 -cover xyzin border
#d_opt1 Extend map to cover molecule in coordinate file xyzin with border (in Angstrom)
#d_opt0 -xtal xtal_labin
#d_opt1 If output format is XtalView then xtal_labin is list of XtalView 'column labels'
#d_opt0 -fftargs fftargs
#d_opt1 Additional command file arguments for running FFT. fftargs should be \
a text string which may include line breaks
#d_opt0 -tmp
#d_opt1 Make the output file a temporary file with extension .tmp
#d_opt0 -saveccp4 ccp4map
#d_opt1 If the output format is not CCP4 then also save the CCP4 map as a file ccp4map.

  upvar $mapVar map
  set extend_mode 0
  set xtal_labin [list FP W PHIB]
  set fftargs ""
  set output_tmp_file 0
  set saveccp4map 0
  set ccp4map ""

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    cover {
      set extend_mode 1
      incr n; set cover_file [lindex $args $n]
      incr n; set cover_border [lindex $args $n]
    } xtal {
      incr n; set xtal_labin [lindex $args $n]
    } fftargs {
      incr n; set fftargs [lindex $args $n]
    } tmp {
      set output_tmp_file 1
    } saveccp4 {
      set saveccp4map 1
      incr n; set ccp4map [lindex $args $n]
    }
    incr n
  }

  set script [GetTmpFileName -ext _com ]

# Find out something about this data  - if space group is not
# one supported by FFT then it will generate whole cell in  P1
# and we'll need to run mapmask if IFASU=1
  set IFASU 0
  GetMtzParam $HKLIN SPACE_GROUP_NAME space_group
  if { [GetFFTSpaceGroups spgp_list ] } {
    if { [lsearch $spgp_list  $space_group ] < 0 } { set IFASU 1 }
  }
  

# Ensure correct extension for map file
  switch -regexp $format { \
  CCP4  { set ext map } \
  XtalView { set ext phs } \
  default { set ext mbk } }
  if { $output_tmp_file } { append ext ".tmp" } 
  set map [ChangeFileExt $map $ext]

  if { [regexp XtalView $format] } {

    set text "output user (3i5,[llength $labin]f12.1)\nlabin "
  
    set n -1; foreach lab $xtal_labin { incr n
      if { $n < [llength $labin] } {
        append text " [subst $lab]=[lindex $labin $n]" }
    }
    append text "\nend\n"
    WriteFile $script $text -overwrite

    set status [Execute "[BinPath mtz2various] HKLIN \"$HKLIN\" HKLOUT \"$map\""  \
                $script program_status report ]

# Xtalview must have 3 columns output - if only two labin defined
# then insert a dummy column

    if { [llength $labin] == 2 } {
      ReadFile $map xtl_text -split
      foreach line $xtl_text {
        append new_xtl_text [string range $line 0 26] "         0.00" \
                [string range $line 27 end] \n
      }
      WriteFile $map $new_xtl_text -overwrite
    }
    return 1
  }


# For other formats first create a CCP4 format map

  set text "title $title\nlabin"
  for { set n 0 } { $n < [llength $labin] } { incr n } {
    set lab [lindex $labin $n]
    if { $lab != "" && $lab != "Unassigned" } {
      append  text " [lindex $prog_labin $n]=$lab"
    }
  }
  if { $fftargs != "" } { append text \n "$fftargs" \n }
  append  text "\nend\n"
  set script [GetTmpFileName -ext _com ]
  WriteFile $script $text -overwrite

  set maptmp0 [GetTmpFileName -ext tmp_map]
  set status [Execute "[BinPath fft] HKLIN \"$HKLIN\" MAPOUT \"$maptmp0\""  \
              $script program_status report ]

  if { $extend_mode  == 1 } {
    set maptmp1 [GetTmpFileName -ext tmp_map]
    ExtendMap $maptmp0 $maptmp1 $cover_file $cover_border 
    DeleteFile $maptmp0
  } elseif { $IFASU } {
    set maptmp1 [GetTmpFileName -ext tmp_map]
    ConvertMapAsu $maptmp0 $maptmp1 
    DeleteFile $maptmp0
  } else {
    set maptmp1 $maptmp0
  }
    

  if { $status && ![regexp CCP4 $format] } {
    global job_params
    ConvertMapFormat $format $maptmp1 $map $job_params(LOG_FILE)
  } else {
    MoveFile $maptmp1 $map
  }

  if { $saveccp4map && ![regexp CCP4 $format] } { 
    MoveFile $maptmp1 $ccp4map 
  } else {
    DeleteFile $maptmp1
  }

  return 1
}


#-------------------------------------------------------------------
proc MakeOMapMacro { macro_file map_list label_list sigma_list \
		colour_list extent args } {
#-------------------------------------------------------------------
#d_sum Create a macro for O to display map(s)
#d_arg macro_file  Name of macro file
#d_arg map_list List of maps to be displayed (in TCL list format)
#d_arg label_list List of titles for maps (TCL list format same length as map_list)
#d_arg sigma_list List of contouring sigma levels (TCL list format same length as map_list)
#d_arg colour_list List of colours for maps ((TCL list format same length as map_list)
#d_arg extent ?Radius of map to display within O
#d_opt0 -mtz mtzfile
#d_opt1 Name of MTZ file from which to extract information on asymmetric unit \
so macro can be set up to display whole asymmetric unit
#d_opt0 -mol mollist mollabel
#d_opt1 Also display molecules from mollist (a list of PDB files) which will \
be assigned labels from mollabel.  mollist and mollabel are TCL lists of the \
same length.

  set mtzfile {}
  set extent3 "20. 20. 20. "
  set centre "0.0 0.0 0.0"
  set ifcentre 0
  set ifmol 0

  set nargs [ llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n ]  \
    mtz {
      incr n; set mtzfile [lindex $args $n]
    } centre {
      set ifcentre 1
    } mol {
      set ifmol 1
      incr n; set mollist [lindex $args $n]
      incr n; set mollabel [lindex $args $n]
    }
    incr n
  }

  if { $mtzfile != "" } {

#   get crystal data
    source [SearchPath TOP src CCP4_utils.tcl]
    ReadSymops [FileJoin [GetEnvPath CLIBD] symop.lib]
    ReadCrystalData [SearchPath TOP etc crystal.lib]

    GetMtzParam $mtzfile SPACE_GROUP_NAME space_group
    GetMtzParam $mtzfile CELL cell
    if { [set asym [GetAsymUnit $space_group]] != "" } {
      set extent3 "[expr [lindex $asym 1] * [lindex $cell 0]] "
      append extent3 "[expr [lindex $asym 3] * [lindex $cell 1]] "
      append extent3 "[expr [lindex $asym 5] * [lindex $cell 2]] "
      set centre "[expr [lindex $asym 1] * [lindex $cell 0] / 2.0] "
      append centre "[expr [lindex $asym 3] * [lindex $cell 1] / 2.0] "
      append centre "[expr [lindex $asym 5] * [lindex $cell 2] / 2.0] "
    }
  }
    
  set macro ""

# Add pdbs to the macro
  if { $ifmol } { 
    set i 0; foreach  mol $mollist {
      append macro "sam_a_i $mol [lindex $mollabel $i]
mol [lindex $mollabel $i]
obj [lindex $mollabel $i]\n"
      incr i
    }
    append macro "zone ; \nend\n"
  }


#  Add maps to the macro
  set n -1; foreach label $label_list { incr n
    append macro \
"fm_file [lindex $map_list $n] $label
fm_setup $label $extent solid 1 [lindex $sigma_list $n] [lindex $colour_list $n]
fm_draw $label\n"
  }
  if $ifcentre { append macro "centre_xyz $centre\n" }

  WriteFile $macro_file "$macro" -overwrite
  return 1
}


#----------------------------------------------------------------------------
proc MakeXtalMacro { hklin crystal_file macro_file \
		xtalfiles coefficients_list radius_list } {
#----------------------------------------------------------------------------
#d_sum Create a macro and crystal file for xtalview to display map(s)
#d_arg hklin MTZ file containing relevant crystal data
#d_arg crystal_file Name of the cystal file which will contain cell and symmetry info
#d_arg macro_file Name of macro file
#d_arg xtalfiles List of XtalView SF files (in TCL list format)
#d_arg coefficients_list List of contouring coefficients (TCL list same length as xtalfiles)
#d_arg radius_list List of map radii (TCL list same length as xtalfiles)

  source [SearchPath TOP src CCP4_utils.tcl]
  GetMtzParam $hklin SPACE_GROUP_NAME space_group
  GetMtzParam $hklin CELL cell
  set symfile [FileJoin [GetEnvPath CLIBD] symop.lib]
  if { ![file exists $symfile] || \
    ![ReadSymops [FileJoin [GetEnvPath CLIBD] symop.lib] 1 ] || \
    [set symops_list [GetSpaceGroupSymops $space_group]] == 0 } {
      WriteToLog "Can not write XtalView crystal file - can not read symops from [GetEnvPath CLIBD]/symop.lib"
  } else {
    set symm [string tolower [lindex $symops_list 0]]
    if {[llength $symops_list] > 1 } {
      foreach s [lrange $symops_list 1 end] {
        append symm "; [string tolower $s]"
      }
    }
    append symm "."

    WriteFile $crystal_file \
"name crystal file for $hklin from CCP4I
cell $cell
symm $symm" -overwrite
    }

# Write xtalview macro ot read in the map files

    set text "crystal $crystal_file"
    set n -1; foreach xtalfile $xtalfiles { incr n
      append text "\nLoadMapPhase [expr $n +1] $xtalfile
coefficients [lindex $coefficients_list $n]
fftapply
contourradius [lindex $radius_list $n]
contourmap [expr $n +1]"
    }
    WriteFile $macro_file \
		 $text -overwrite

}

#-------------------------------------------------------------------
proc GetCellfromMtz { mtzfile space_groupVar cellVar latticeVar } {
#-------------------------------------------------------------------
#d_sum Extract header information from an MTZ file
#d_desc Return spacegroup name, cell parameters and lattice type \
from named MTZ file.
#d_desc Note: the lattice type may be an empty string.
#d_arg mtzfile Input MTZ file
#d_arg space_groupVar Returned space group
#d_arg cellVar Returned cell dimensions (as Tcl list)
#d_arg latticeVar Returned cell lattice type

  upvar $space_groupVar space_group
  upvar $cellVar cell
  upvar $latticeVar lattice

  GetMtzParam $mtzfile SPACE_GROUP_NAME space_group
  GetMtzParam $mtzfile CELL cell
  GetMtzParam $mtzfile LATTICE lattice
  return
}

#-------------------------------------------------------------------
proc GetMapHeader { mapfile space_groupVar cellVar xyzlimVar gridVar \
	axesVar } {
#-------------------------------------------------------------------
#d_sum Extract header information from a map file
#d_desc Runs the mapdmp script
#d_arg mapfile Input map file
#d_arg space_groupVar Returned space group
#d_arg cellVar Returned cell dimensions (as Tcl list)
#d_arg xyzlimVar Returned xyz limits of map (as Tcl list)
#d_arg gridVar Returned number of grid points in xyz (as Tcl list)
#d_arg axesVar Return order of axes in map (as Tcl list of X Y Z)

  upvar $space_groupVar space_group
  upvar $cellVar cell
  upvar $xyzlimVar xyzlim
  upvar $gridVar grid
  upvar $axesVar axes

  set mapdmp_log [GetTmpFileName -ext log]
  WriteComFile mapdump_script "END"
  set status [ Execute "[BinPath mapdump] MAPIN \"$mapfile\"" $mapdump_script  \
                program_status report -nocomments -log $mapdmp_log ]

  ReadFile $mapdmp_log mapdmp_text


   set xyzlim_line \
       [ExtractFromText $mapdmp_text "Start and stop" 0 all ]

   set line \
       [ExtractFromText - "Grid" 0 all ]
   set ll [llength $line]; set grid ""
   for { set i [expr $ll -3] } { $i < $ll } { incr i } {
     lappend grid [lindex $line $i]
   }
   # Check: we should have three integers
   for { set i 0 } { $i < 3 } { incr i } {
     if { ![regexp "^\[0-9\]+$" [lindex $grid $i]] } { return 0 }
   }

   set line \
       [ExtractFromText - "Cell dimensions" 0 all ]
   set ll [llength $line] ; set cell ""
   for { set i [expr $ll -6] } { $i < $ll } { incr i } {
     lappend cell [lindex $line $i]
   }

   set line [ExtractFromText - "Fast, medium, slow axes" 0 all ]
   set axes {}
   for { set i 5 } { $i < 8 } { incr i } { lappend axes [lindex $line $i ]}
   # Check: we should have three characters X Y or Z
   for { set i 0 } { $i < 3 } { incr i } {
     if { ![regexp "^\[X|Y|Z\]$" [lindex $axes $i]] } { return 0 }
   }

   set space_group [ExtractFromText -  "Space-group" 0 2 ]
   # Check: we should have a single integer
   if { ![regexp "^\[0-9\]+$" $space_group] } { return 0 }

# Now we  have the axes order can work out the xyzlim

   set ll [llength $xyzlim_line] ; set xyzlim ""
   for { set i 0 } { $i < 3 } { incr i } {
     set j [lsearch $axes [lindex [list X Y Z] $i] ]
     set jj [expr $ll - 6 + ($j * 2)]
     lappend xyzlim [lindex $xyzlim_line $jj]
     incr jj; lappend xyzlim [lindex $xyzlim_line $jj]
   }
   # Check: we should have six integers
   for { set i 0 } { $i < 6 } { incr i } {
     if { ![regexp "^-?\[0-9\]+$" [lindex $xyzlim $i]] } { return 0 }
   }

   return 1
}

#-------------------------------------------------------------------
proc ConvertMapCell { mapin mapout } {
#-------------------------------------------------------------------
#d_sum Extend map to cover unit cell
#d_arg mapin Full path name of input map
#d_arg mapout Full path name of output map

  WriteComFile extend_script "XYZLIM CELL"

  set status [Execute \
      "[BinPath mapmask] MAPIN \"$mapin\" MAPOUT \"$mapout\"" \
      $extend_script program_status report ]

  return $status
}

#------------------------------------------------------------------------
proc WatPeak { mapin xyzin peakout symmetry args } {
#------------------------------------------------------------------------
#d_sum UNTESTED Search input differnce map for water peaks
#d_desc Uses the mapmask program to extend map to cover (only) the volume of \
the protein and then uses peakmax to find peaks in map without atoms. Watpeak \
then trims the peaklist to around the protein.

#d_arg mapin Full path name of input map
#d_arg xyzin Full path name of input coordinate file
#d_arg peakout List of 'water' peaks in PDB format
#d_arg symmetry Space group namr input to watpeak
#d_opt0 -title title
#d_opt1 Input a title line for watpeak (as output to PDB peaks file)

# Assume input map is a difference map and search around protein for 
# putative water peaks

  set title "Putative water peaks in  $mapin"
  set border 10
  set threshhold 3.0
  set numpeaks 5000

  set nargs [llength $args]; set n 0
  while { $n < $nargs } {
    switch -regexp -- [lindex $args $n] \
    title {
      incr n; set title [lindex $args $n]
    }
    incr n
  }

# Mapmask to limit map to area around protein

  WriteFile [set script [GetTmpFileName -ext _com ]] "border $border"
  set maptmp [GetTmpFileName -ext _map]
  set status [Execute "[BinPath mapmask] MAPIN \"$mapin\" XYZIN \"$xyzin\" MAPOUT \"$maptmp\""  \
                $script program_status report ]

# Peak search the map

   WriteFile [set script [GetTmpFileName -ext _com ]] \
"threshold rms $threshhold
numpeaks  $numpeaks"
   set allpeaks [GetTmpFileName -ext _pdb]
   set status [Execute "[BinPath peakmax] MAPIN \"$maptmp\" XYZOUT \"$allpeaks\"" \
	$script program_status report ]


# Watpeak to trim to peaks close to the protein

  WriteFile [set script [GetTmpFileName -ext _com ]] \
"symmetry $symmetry
distance 4.0 1.9
title $title"
   set status [Execute \
     "[BinPath watpeak] XYZIN \"$xyzin\" peaks \"$allpeaks\" XYZOUT \"$peakout\""  \
	$script program_status report ]

  return 1
}
  

#------------------------------------------------------------------------
proc AddXtalMapFom { hkl_file } {
#------------------------------------------------------------------------
# The XtalView phases file needs an extra column of dummy FOMs - set all to 1
#d_sum Add an extra column of dummy FOMS to an XtalView phases file
#d_desc XtalView phases file must have three columns: F, FOM phase. This \
procedure insert a FOM column to any file created without one.
#d_arg hkl_file Input/output XtalView phases file - the file is overwritten

  ReadFile $hkl_file hkl_in -split
  set hkl_out ""
  foreach line $hkl_in {
    append hkl_out [format "%5i%5i%5i%12.1f%12.1f%12.1f" \
        [lindex $line 0 ] [lindex $line 1 ] [lindex $line 2 ] \
        [lindex $line 3 ] 1.0 [lindex $line 4]] \n
  }
  DeleteFile $hkl_file
  WriteFile $hkl_file $hkl_out
}

#-----------------------------------------------------------------------
proc CalcCellVolume { cell volumeVar } {
#-----------------------------------------------------------------------
#d_sum Calculate the cell volume
#d_arg cell Cell dimensions
#d_arg volumeVar Returned cell volume
  upvar $volumeVar volume

# cell - input list of cell parameters
# volume  - return cell volume

  set dtor  3.1415927/180.0
  set a [lindex $cell 0]
  set b [lindex $cell 1]
  set c [lindex $cell 2]
  set al [expr [lindex $cell 3] * $dtor ]
  set be [expr [lindex $cell 4] * $dtor ]
  set g [expr [lindex $cell 5] * $dtor ]

  set volume [ expr ( $a * $b * $c ) *  ( sqrt  \
	1 + ( 2 * cos($al) * cos($be) * cos(*ga) ) \
	  -  pow (cos($al) ,2) \
	  -  pow (cos($be) ,2) \
	  -  pow (cos($g) ,2)  )

}

