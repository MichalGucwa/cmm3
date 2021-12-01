#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
# ======================================================================
# mosflm.tcl --
#
# CCP4Interface 
#
# =======================================================================

#CCP4i_cvs_Id $Id$

#--------------------------------------------------------------------
proc mosflm_prereq { } {
#--------------------------------------------------------------------
# Check for existence of mosflm executable
  if { ![file exists [FindExecutable ipmosflm]] } {
    return 0
  }
  return 1
}

#---------------------------------------------------------------------
proc mosflm_setup { typedefVar arrayname } {
#---------------------------------------------------------------------
  upvar #0  $typedefVar typedef
  upvar #0 $arrayname array
  
  DefineMenu _mosflm_detectors [ list \
	  "Mar Research IP" "Mar Research CCD" "ADSC CCD" \
	  "Raxis II" "Raxis IV" "Raxis HTC" \
          "Rigaku Jupiter" "Rigaku Saturn" "Rigaku Mercury" \
          "SBC1" "DIP2" "DIP2030" "DIP2040" "Oxford Sapphire" \
          "Bruker" "Crystallographic Binary File"] \
	  [list \
          MAR MARCCD ADSC \
          RAXIS RAXIS4 RAXISHTC \
          JUPITER SATURN MERCURY \
          SBC1 DIP2 DIP2030 DIP2040 OXFORD \
          BRUKER CBF]

  return 1
}

# procedure to draw task window
#---------------------------------------------------------------------
proc mosflm_task_window { arrayname } {
#---------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
        "Run MOSFLM in batch mode" "Mosflm" \
	    [list "Dataset and Harvesting Parameters" \
                  "Images to Integrate" \
                  "Crystal Parameters" \
		  "Detector Parameters" \
                  "Integration Parameters" \
		  "Distortion Parameters" \
                  "Main Beam Position" \
                  "Other Beam Parameters"] \
        ] == 0 } return

  SetHarvestParams $arrayname "" -init
  SetProgramHelpFile "mosflm"

#=PROTOCOL FOLDER=======================================================

  OpenFolder protocol 

  CreateLine line \
	  label "Run MOSFLM in batch mode to integrate diffraction images" \
	  -italic

  CreateTitleLine line TITLE

  CreateLine line \
          label "Load parameters from command file" \
          varlabel BATCHFILE

  $line.l2 configure -width 60 -background $configure(COLOUR_BACKGROUND)

  # Make a "browse" button to allow the user to select the batchfile
  # This is a custom widget!
  set browse [button $line.browse -text "Browse" \
	  -command "mosflm_select_batchfile $arrayname"]
  $browse configure -font $configure(FONT_SMALL)

  # Make a "view" button to allow the user to view the original batchfile
  # This is a custom widget!
  set view [button $line.view -text "View" \
	  -command "mosflm_display_batchfile $arrayname"]
  $view configure -font $configure(FONT_SMALL)
  pack $browse $view -after $line.l2 -side left

  CreateLine line \
          message "Load parameters from an existing Mosflm batch file" \
          button "Load parameters from command file" \
             -command "mosflm_read_parameters0 $arrayname"
  pack forget $line.b1
  pack $line.b1 -side right

#=FILES FOLDER========================================================= 

  OpenFolder file

  CreateLine line \
      message "Full pathname for the image directory" \
      label "Specify where the images are located" \
      -italic

  # Display the name of the current directory to help the user
  set cwd [GetCurrentDir]
  CreateLine line \
	  message "Images are in the current working directory?" \
          widget USE_CWD \
          label "Use current working directory $cwd"

  OpenSubFrame frame -toggle_display USE_CWD open [list 0]

  # Specify one or more images directory

  CreateExtendingFrame NDIRECTORIES mosflm_directories \
     "Specify one or more directories with images" \
     "Add a directory" \
      [list DIRECTORY]

  CloseSubFrame

  CreateLine line \
    message "Use wildcards \# to indicate numbers in the name" \
    label "Image file name template:" \
    widget TEMPLATE -width 40 \
    -command "mosflm_set_hklout $arrayname"

  # Matrix file name
  CreateInputFileLine line \
    "Enter name of input MOSFLM matrix file" \
    "Matrix file" \
    MATRIX_FILE DIR_MATRIX_FILE \
    -command "mosflm_read_matrix_file $arrayname"

  # Output file name and location
  CreateOutputFileLine line \
      "Enter name of output MTZ file (HKLOUT)" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

#=====================================================================
# FOLDER 1: HARVESTING PARAMETERS

  OpenFolder 1

  CreateHarvestLine line  -dname

#=====================================================================
# FOLDER 2: IMAGES TO BE PROCESSED

  OpenFolder 2

  # Multiple process/run lines
  CreateToggleFrame NRUNS MosflmNRuns \
                "Define another run" \
                "Processing run #" \
                "Add processing run" \
             [list NPROCESS \
	           POSTREF \
		   POSTREF_MULTI \
		   POSTREF_SDFAC \
		   POSTREF_FIX_ALL \
		   POSTREF_FIX_A \
		   POSTREF_FIX_B \
		   POSTREF_FIX_C \
		   POSTREF_FIX_ALPHA \
		   POSTREF_FIX_BETA \
		   POSTREF_FIX_GAMMA \
		   POSTREF_FIX_MOSAIC \
		   POSTREF_WIDTH \
		   POSTREF_MOSADD \
		   POSTREF_MOSSMOOTH ] \
                -child MosflmNProcess

#=====================================================================
# FOLDER 3: CRYSTAL PARAMETERS

  OpenFolder 3

  CreateLine line \
        message "Space group from AutoIndexing" \
        label "Space group" \
        widget SPACEGROUP -oblig

  # Use varlabels to display the cell parameters without allowing
  # the user to edit them
  # Note that we will need to update the widgets manually when
  # reading these parameters in
  CreateLine line \
        message "Cell dimensions (lengths in Angstroms)" \
        label "Cell a" \
        varlabel CELL_1 \
        label "b" \
        varlabel CELL_2 \
        label "c" \
        varlabel CELL_3 \
        message "Cell dimensions (angles in degrees)" \
        label "alpha" \
        varlabel CELL_4 \
        label "beta" \
        varlabel CELL_5 \
        label "gamma" \
        varlabel CELL_6

  # Configure the varlabels to have a highlighted background
  # with a fixed width
  # This requires that we know the widget naming convention from
  # CreateLine, so there will be a problem if this changes
  foreach widget [list l2 l4 l6 l8 l10 l12] {
      $line.$widget configure -width 8 -background $configure(COLOUR_BACKGROUND)
  }

  CreateLine line \
        message "Value for mosaicity (in degrees) - perhaps from Estimate Mosaicity" \
	label "Mosaicity" \
	widget MOSAICITY -oblig

  CreateLine line \
        message "If not specified then the wavelength is read from the image header, if available; otherwise it defaults to Cu-K_alpha" \
        label "Wavelength of radiation used in the experiment" \
	widget WAVELENGTH \
	label "Angstrom"

#=====================================================================
# FOLDER 4: DETECTOR PARAMETERS

  OpenFolder 4

  CreateLine line \
          message "Explicitly specify the detector type (DETECTOR keyword)" \
	  widget USE_DETECTOR -toggleon \
          label "Set detector type to" \
          widget DETECTOR \
	  label "and over-ride default determined by MOSFLM"

  OpenSubFrame frame -toggle_display USE_DETECTOR open { 1 }

  CreateLine line \
	  message "This should not be changed once determined using Mosflm interactively" \
	  label "Angle between actual and virtual detector X-axes" \
	  varlabel DETECTOR_OMEGA \
	  label "with rotation axis opposite to the usual orientation" \
	  toggle_display DETECTOR_REVERSEPHI open { 1 }

  # Configure the varlabel to have a highlighted background
  # with a fixed width
  $line.l2 configure -width 8 -background $configure(COLOUR_BACKGROUND)

  CreateLine line \
	  message "This should not be changed once determined using Mosflm interactively" \
	  label "Angle between actual and virtual detector X-axes" \
	  varlabel DETECTOR_OMEGA \
	  toggle_display DETECTOR_REVERSEPHI open { 0 }

  # Configure the varlabel to have a highlighted background
  # with a fixed width
  $line.l2 configure -width 8 -background $configure(COLOUR_BACKGROUND)

  CloseSubFrame

  CreateLine line \
	label "Detector to crystal distance" \
	widget DISTANCE \
	label "mm" \
        message "Only set the swing angle if the detector is swung out" \
        label "    Detector swing angle" \
	widget TWOTHETA \
	label "degrees"

  CreateLine line \
        message "These values should have been determined from postrefinement" \
	label "Minimum spot separation: x" \
	widget SEPARATION_X \
	label "y" \
	widget SEPARATION_Y \
	label "mm" \
        message "Only set this if the spots are close to being overlapped" \
        label "    Close spots? " \
        widget SEPARATION_CLOSE

  CreateLine line \
        message "GAIN can be estimated via the Mosflm GUI" \
	label "Detector gain " \
	widget GAIN \
        message "The ADC offset should be constant for a given detector" \
	label "Scanner ADC offset " \
        widget ADCOFFSET

#=====================================================================
# FOLDER 5: INTEGRATION PARAMETERS

  OpenFolder 5

  CreateLine line \
        message "Optional: leave blank if you don't want a high resolution cutoff" \
        label "Use resolution range" \
        widget RESOLUTION_MAX \
        label "(high resolution) to" \
	message "Optional: leave blank if you don't want a low resolution cutoff" \
        widget RESOLUTION_MIN \
        label "(low resolution) (Angstroms)"

  CreateLine line \
        message "Use this option to deal with shadows on the detector" \
        label "Reject spots which contain pixels with values less than or equal to" \
        widget NULLPIX

  CreateLine line \
        message "Define parameters for the measurement box (RASTER)" \
        label "Measurement box: Width " widget RASTER_1 \
        label " Height " widget RASTER_2 \
        label " Corner cut-off " widget RASTER_3 \
        label " Horiz. bg " widget RASTER_4 \
        label " Vert. bg " widget RASTER_5

  CreateLine line \
        message "Overload cutoff value should be constant for a given detector" \
        label "Overload cutoff value " \
        widget OVERLOAD_CUTOFF \
        label "Overload flagging value " \
        widget OVERLOAD_NOVER

  CreateLine line \
        message "Inner and outer areas for profile fitting" \
        label "Profile tolerance: minimum" \
        widget PROFILE_TOL_MIN \
        label "maximum" \
        widget PROFILE_TOL_MAX

  CreateLine line \
        widget PROFILE_USE_LINES \
        label "Define the boundary lines for areas for determining the standard profiles"

  OpenSubFrame frame -toggle_display PROFILE_USE_LINES open 1

  CreateLine line \
        message "Define up to six lines parallel to the Y axis" \
        label "     Xlines (mm):" \
        widget PROFILE_XLINES_1 \
        widget PROFILE_XLINES_2 \
        widget PROFILE_XLINES_3 \
        widget PROFILE_XLINES_4 \
        widget PROFILE_XLINES_5 \
        widget PROFILE_XLINES_6 \

  CreateLine line \
        message "Define up to six lines parallel to the X axis" \
        label "     Ylines (mm):" \
        widget PROFILE_YLINES_1 \
        widget PROFILE_YLINES_2 \
        widget PROFILE_YLINES_3 \
        widget PROFILE_YLINES_4 \
        widget PROFILE_YLINES_5 \
        widget PROFILE_YLINES_6 \

  CloseSubFrame

  CreateLine line \
        widget PROFILE_OVERLOADS \
        label "Profile fit overloaded reflections"

  CreateLine line \
        message "Use partially recorded reflections, if present" \
        widget PROFILE_PARTIALS \
        label "Include partials in forming the standard profiles"

  CreateLine line \
        message "Do not optimise the overall measurement box dimensions" \
        widget PROFILE_FIXBOX \
        label "Keep the measurement box dimensions fixed"

  CreateLine line \
        widget PROFILE_OPTIMISE \
        label "Allow MOSFLM to optimise the spot profile"

#=====================================================================
# FOLDER 6: DETECTOR DISTORTION PARAMETERS

  OpenFolder 6 closed

  CreateLine line \
	label "Size of pixels in Y direction (relative to X direction)" \
	widget DISTORTION_YSCAL

  CreateLine line \
	message "Units are millimetres" \
	label "Radial offset:" \
	widget DISTORTION_ROFF \
	label "Tangential offset:" \
	widget DISTORTION_TOFF

  CreateLine line \
	message "Rotation about a vertical axis (1/100 degree units)" \
	label "Detector tilt:" \
	widget DISTORTION_TILT \
	message "Rotation about a horizontal axis (1/100 degree unit)" \
        label "Twist:" \
	widget DISTORTION_TWIST

#=====================================================================
# FOLDER 7: MAIN BEAM POSITION

  OpenFolder 7

  CreateLine line \
        label "Beam position: x" \
        widget BEAM_X \
        label "y" \
        widget BEAM_Y \
        label "(mm)  " \
        widget BEAM_SWUNG -toggleon \
	label "Beam swung out"

  CreateLine line \
        label "Backstop position: x" \
        widget BACKSTOP_X \
        label "y" \
        widget BACKSTOP_Y \
        label "Radius:" \
        widget BACKSTOP_R \
        label "(mm)"

#=====================================================================
# FOLDER 8: OTHER BEAM PARAMETERS

  OpenFolder 8 closed 

  CreateLine line \
      message "Note that these parameters are not appropriate for home source data" \
      widget SYNCHROTRON \
      label "Set additional options appropriate for data collected at a synchrotron"

  OpenSubFrame frame -toggle_display SYNCHROTRON open { 1 }

  CreateLine line \
        label "Beam polarisation" \
        message "Polarisation of the beam (SYNCHROTRON POLARISATION)" \
        widget POLARISATION

  CreateLine line \
        label "Beam divergence: horizontal:" \
        message "Horizontal width of the rocking curve (DIVERGENCE)" \
        widget DIVERGENCE_X \
        label "Vertical: " \
        message "Vertical width of the rocking curve - defaults to horizontal value if not set" \
        widget DIVERGENCE_Y \
        label "(degrees)"

  CreateLine line \
        label "Wavelength dispersion" \
        message "Wavelength dispersion (delta-lamda)/lamda (DISPERSION)" \
        widget DISPERSION

  CloseSubFrame

  # Update the display of the varlabels with the CELL
  mosflm_update_cell_display $arrayname
}
#=====================================================================

#--------------------------------------------------------------
proc mosflm_run { arrayname } {
#--------------------------------------------------------------

  upvar #0 $arrayname array
  # Check everything and set up lists of input and output files

  # Check that images exist
  # Generate glob pattern from image file template
  set template $array(TEMPLATE)
  while { [regsub -- "#" $template "?" temp] } { set template $temp }

  # Source directory for images
  if { $array(USE_CWD) != 1 } {
      # User specified directories where images are located
      for { set i 1 } { $i <= $array(NDIRECTORIES) } { incr i } {
	  if { ![file isdirectory $array(DIRECTORY,$i)] } {
	      WarningMessage "ERROR
Specified directory with image files

\"$array(DIRECTORY,$i)\"

does not exist"
	      return 0
	  } else {
	      set filen [file join $array(DIRECTORY,$i) $template]
	      if { [llength [glob -nocomplain $filen]] == 0 } {
		  # No matching files
		  WarningMessage "ERROR
No image files in directory

\"$array(DIRECTORY,$i)\"

match the template

\"$array(TEMPLATE)\""
		  return 0
	      }
	  }
      }
  } else {
      # Using CWD
      set filen [file join . $template]
      puts "Checking for $filen..."
      if { [llength [glob -nocomplain $filen]] == 0 } {
	  # No matching files
	  WarningMessage "ERROR
No image files match the template

\"$array(TEMPLATE)\"

in the current working directory."
	  return 0
      }
  }

  # Check that at least one processing run was defined
  if { $array(NRUNS) < 1 } {
    WarningMessage "No processing runs defined!

You must define at least one
processing run in the interface."
    return 0
  }

  # First and last images to process
  # Check that they are integers
  set pattern "\[0-9\]+"
  set nruns $array(NRUNS)
  for { set i 1 } { $i <= $nruns } { incr i } {
    set nprocess $array(NPROCESS,$i)
    for { set j 1 } { $j <= $nprocess } { incr j } {
      set n "[subst $i]_$j"
      # Check that FIRST and LAST are both numbers
      if { ![regexp $pattern $array(PROCESS_FIRST,$n)] || \
	      ![regexp $pattern $array(PROCESS_LAST,$n)] } {
	WarningMessage "ERROR
In processing run $i:

At least one of the first and last image numbers
is not an integer."
        return 0
      }
      # Check that FIRST is smaller than LAST
      if { $array(PROCESS_FIRST,$n) > $array(PROCESS_LAST,$n) } {
	WarningMessage "ERROR
In processing run $i:

The first image number ($array(PROCESS_FIRST,$n)) is
higher than the last ($array(PROCESS_LAST,$n)) in process
line $j."
        return 0
      }
    }
  }

  # Harvesting names
  # Only do this check if harvesting is selected
  if { ![StringSame [GetValue $arrayname HARVEST_MODE] NOHARVEST] } {
    if { ![SetHarvestParams $arrayname "" -run] } { return 0 }
  } else {
    # Force the user to set valid pname and dname even if
    # harvesting is turned off
    set dname $array(HARVEST_DNAME)
    set pname $array(HARVEST_PNAME)
    if { [string trim $dname] == "" || [string trim $pname] == "" } {
	  WarningMessage "One or more Project/Dataset pair has not been properly assigned
You must assign valid Project and Dataset names before
running this task."
          return 0
    }
  }
  # Check the crystal name
  if { [string trim $array(HARVEST_XNAME)] == "" } {
    WarningMessage "Invalid crystal name

You must assign a valid Crystal name before
running this task."
    return 0
  }
  # Determine the extreme limits of the range of images being
  # processed in order to construct the full harvest filename
  # later on
  # These are taken from the last processing run
  set n $array(NRUNS)
  set first 9999
  set last  -1
  for { set i 1 } { $i <= $array(NPROCESS,$n) } { incr i } {
     if { $array(PROCESS_FIRST,[subst $n]_$i) < $first } {
        set first $array(PROCESS_FIRST,[subst $n]_$i)
     }
     if { $array(PROCESS_LAST,[subst $n]_$i) > $last } {
        set last $array(PROCESS_LAST,[subst $n]_$i)
     }
  }
  set array(FIRST_IMAGE) $first
  set array(LAST_IMAGE) $last

  # Mosaicity must be set
  if { [catch { expr $array(MOSAICITY) } ] } {
    WarningMessage "You have not set a valid value for the mosaicity"
    return 0
  }

  # Raster values
  set array(USE_RASTER) 1
  set n_raster 0
  for { set i 1 } { $i <= 5 } { incr i } {
     if { $array(RASTER_$i) == "" || ![string is double $array(RASTER_$i)] } {
       set array(USE_RASTER) 0
     } else {
       incr n_raster
     }
  }
  if { $n_raster == 0 } {
    set array(USE_RASTER) 0
  } elseif { $n_raster < 5 } {
    WarningMessage "One or more fields defining the measurement
box (in the \"Integration Parameters\" folder)
are not set, or are not set to numerical values.

Either all fields must be set, or none, before
you can run this task."
    return 0
  }

  # Temporary file name for GENFILE
  set array(GENFILE) [GetTmpFileName -ext genfile]

  # NB Must return 1 on success for the job to run
  return 1
}

#--------------------------------------------------------------
proc mosflm_directories { arrayname counter } {
#--------------------------------------------------------------
# Draw one line of the extending frame for specifying
# directories containing image files

  upvar #0 $arrayname array
  global configure

  CreateLine line \
    message "Enter the name of a directory containing images" \
    label "Directory $counter" \
      widget DIRECTORY -width 60

  # Make a "browse" button to allow the user to select directories
  # via the browser
  # This is a custom widget!
  set browse [button $line.browse -text "Browse" \
	  -command "mosflm_browse $arrayname $counter"]
  $browse configure -font $configure(FONT_SMALL)
  pack $browse -after $line.e2 -side left
  return
}

#--------------------------------------------------------------
proc MosflmNRuns { arrayname c1 } {
#--------------------------------------------------------------
# Draw one instance of the process runs toggle frame

  CreateLine line \
	widget POSTREF \
	label "Perform postrefinement as part of this processing run"

  OpenSubFrame frame -toggle_display POSTREF,$c1 open { 1 }

    CreateLine line label "Postrefinement parameters:" -italic

    CreateLine line \
        label "Only use reflections with intensity greater than" \
        widget POSTREF_SDFAC \
        label "times the standard deviation"

    CreateLine line \
        widget POSTREF_MULTI \
	label "Use partials spread over two or more images"

    CreateLine line \
	message "Select parameters which will not refined during the postrefinement" \
        label "Fix" \
        widget POSTREF_FIX_ALL \
	label "Cell parameters" \
        widget POSTREF_FIX_MOSAIC \
	label "Mosaicity"

    CreateLine line \
        message "Reflections larger than this will be excluded (WIDTH keyword)" \
        label "Maximum width of reflections included in postrefinement:" \
        widget POSTREF_WIDTH

    CreateLine line \
        message "Use a safety factor to ensure the true mosaic spread is not underestimated (MOSADD)" \
        label "Use a safety factor of" \
        widget POSTREF_MOSADD \
        label "times the mosaic spread" 

    CreateLine line \
        message "Smoothing should provide a more stable refinement (MOSSMOOTH keyword)" \
        label "Smooth the refined mosaic spread over" \
        widget POSTREF_MOSSMOOTH \
        label "images"

  CloseSubFrame

  CreateLine line label "Processing parameters:" -italic

  CreateExtendingFrame NPROCESS MosflmNProcess \
        "Specify multiple blocks of images to process together" \
        "Add block of images" \
      [list  PROCESS_FIRST \
             PROCESS_LAST \
             PROCESS_START \
	     PROCESS_ANGLE \
             PROCESS_BLOCK \
             PROCESS_ADD \
	     PROCESS_USE_BLOCK \
	     PROCESS_USE_ADD ] \
        -counter $c1
}

#--------------------------------------------------------------
proc MosflmNProcess { arrayname c1 c2 } {
#--------------------------------------------------------------
# Draw one line of the process extending frame

  CreateLine line \
      message "Specify the range of images (as image numbers) to be integrated together" \
      label "Integrate images from" \
      widget PROCESS_FIRST -oblig \
      label "to" \
      widget PROCESS_LAST -oblig \
      message "Initial phi value for the first image in the range, if different from image header" \
      label "with starting phi value" \
      widget PROCESS_START \
      message "Oscillation angle per image, if different from value in image header" \
      label "and oscillation angle" \
      widget PROCESS_ANGLE

  CreateLine line \
      message "Output batch number will be the image number plus this increment" \
      widget PROCESS_USE_ADD -toggleon \
      label "Increment image numbers by" \
      widget PROCESS_ADD \
      label "to generate batch numbers"

  CreateLine line \
      widget PROCESS_USE_BLOCK -toggleon \
      label "Build up spot profiles using" \
      widget PROCESS_BLOCK \
      label "images in each block"

}

#--------------------------------------------------------------
proc mosflm_display_batchfile { arrayname } {
#--------------------------------------------------------------
# Display the batchfile in a text viewer

   upvar #0 $arrayname array

   if { [file exists $array(BATCHFILE)] } {
     DisplayTextFile $array(BATCHFILE)
   }
}

#--------------------------------------------------------------
proc mosflm_browse { arrayname counter } {
#--------------------------------------------------------------
# Use the file browser to select a directory containg images

  upvar #0 $arrayname array

  if { [SelectFile filename -directory] } {
    # The browser can return either a filename or a directory
    # name - make sure we get the leading directory in the
    # former case
    if { [file isdirectory [lindex $filename 0]] } {
      set dirname $filename
    } else {
      set dirname [file dirname [lindex $filename 0]]
    }
    # Update the parameters in the window
    set array(DIRECTORY,$counter) $dirname
  }
  return
}

#--------------------------------------------------------------
proc mosflm_select_batchfile { arrayname } {
#--------------------------------------------------------------
# Select a batchfile to load the initial parameters from

  upvar #0 $arrayname array
  if { ![SelectFile batchfile -filter "*"] } {
    return 0
  } elseif { ![file exists [lindex $batchfile 0]] } {
    return 0
  }
  set array(BATCHFILE) [lindex $batchfile 0]
  return 1
}

#--------------------------------------------------------------
proc mosflm_read_parameters0 { arrayname } {
#--------------------------------------------------------------
# This is a wrapper for mosflm_read_parameters which traps for
# errors encountered when reading in a parameter file

  upvar #0 $arrayname array
  
  # Check that there is a parameter file to load from
  set batchfile $array(BATCHFILE)
  if { $batchfile == "" } {
      return
  }
  if { ![file exists $batchfile] } {
      WarningMessage "The specified command file

\"$batchfile\"

doesn't exist"
      return
  }

  PleaseWait "loading parameters from file..."

  # Minimise the window
  set w $array(WINDOW)
  wm withdraw $w

  # Load the parameters  
  if { [catch { set warning_message [mosflm_read_parameters $arrayname] } errmsg] } {
    WarningMessage "ERROR: couldn't read the parameter file

Last error message:
$errmsg

This may be because the specified file is
a shell script rather than a .sav file."
  } else {
    # Display warning messages from the loading, if any
    if { $warning_message != "" } {
       WarningMessage $warning_message
    }
  }

  PleaseWait
  return
}

#--------------------------------------------------------------
proc mosflm_read_parameters { arrayname } {
#--------------------------------------------------------------
# Extract parameters from a batch file to populate the interface

  upvar #0 $arrayname array
  set contents ""

  # Check the selected batchfile exists
  set batchfile $array(BATCHFILE)
  if { $batchfile == "" || ![file exists $batchfile] } {
      return
  }

  # Load the parameters

  # Keep a record of unprocessed lines
  set unprocessed ""

  # Keep a record of unimplemented commands
  set unimplemented ""

  # Keep a record of inappropriate commands i.e.
  # those not useful in batch mode
  set inappropriate ""

  # Keep a record of redundant commands
  set redundant ""

  # Number of DIRECTORIES keywords encountered
  set ndirs 0

  # Storage for multiple PROCESS lines
  set process_lines {}

  # Template, ident and extension
  set template ""
  set ident ""
  set extension ""

  # Matrix file
  set matrix_file ""

  # Don't explicitly assume synchrotron data
  set array(SYNCHROTRON) 0

  # If no detector is specified in the sav file then
  # make sure that this option is switched off
  # (and reset the suboptions also)
  set array(USE_DETECTOR) 0
  set array(DETECTOR_OMEGA) ""
  set array(DETECTOR_REVERSEPHI) 0

  # Normally the beam is not swung out
  set array(BEAM_SWUNG) 0

  # Read the contents of the file into a list of lines
  # Ignore blank lines
  ReadFile $batchfile contents -split -noblank

  # Step through the contents a line at a time
  foreach line $contents {

      if { [llength $line] > 0 } {

	  set keyword [string toupper [lindex $line 0]]
	  
	  # Deal with keywords using a switch statement
          # Assume that only the first four characters are
	  # significant
	  switch -regexp $keyword {
	      ^ADCO {
		  # ADCOFFSET
		  set array(ADCOFFSET) [lindex $line 1]
	      }
	      ^ADDP {
		  # ADDPART - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^ALLO {
		  # ALLOUT - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^BACKG {
		  # BACKGROUND - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^BACKS {
		  # BACKSTOP
		  set array(BACKSTOP_X) [lindex $line 2]
		  set array(BACKSTOP_Y) [lindex $line 3]
		  set array(BACKSTOP_R) [lindex $line 5]
	      }
	      ^BELL {
		  # bell on/off - irrelevant to batch processing
	      }
	      ^BEAM {
		  # BEAM
		  set i 1
		  set option [string toupper [lindex $line $i]]
		  switch -regexp -- $option {
		      ^SWUN {
			  # swung out setting for beam centre
			  set array(BEAM_SWUNG) 1
			  incr i
		      }
		  }
		  set array(BEAM_X) [lindex $line $i]
		  incr i
		  set array(BEAM_Y) [lindex $line $i]
	      }
	      ^BIAS {
		  # BIAS - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^BSWA {
		  # BSWAP - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^CAMC {
		  # CAMCON - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^DEBUG {
		  # DEBUG - any keyword starting "febug*"
		  # Ignored as inappropriate for batch mode
		  append inappropriate "$line\n"
	      }
	      ^DETE|SCAN {
		  # DETECTOR, SCANNER
                  MosflmSetMenuValue $arrayname DETECTOR \
		      [string toupper [lindex $line 1]]
		  set array(USE_DETECTOR) 1
		  # Look for suboptions OMEGA <integer> and
		  # REVERSEPHI
		  set i 1
		  set nopts [llength $line]
		  while { $i < $nopts } {
		      set option [string toupper [lindex $line $i]]
		      switch -regexp -- $option {
			  ^OMEG {
			      # OMEGA <integer>
			      # Specifies the angle between the actual detector
			      # X-axis and the virtual detector X axis
			      incr i
			      set array(DETECTOR_OMEGA) [lindex $line $i]
			  }
			  ^REVERSEPHI {
			      # Detector rotation axis is not in the usual
			      # orientation
			      set array(DETECTOR_REVERSEPHI) 1
			  }
		      }
		      # Next subopt
		      incr i
		  }
	      }
	      ^DIRE {
		  # DIRECTORY
		  if { $ndirs == 0 } {
		      # We have encounted a DIRECTORIES
		      # keyword for the first time
		      # Zap any previous directories set in
		      # the window
		      if { $array(NDIRECTORIES) != 0 } {
			set array(NDIRECTORIES) 0  
		      }
		      # Make sure we turn off the option
		      # to use the current directory
		      set array(USE_CWD) 0
		  }
		  incr ndirs
		  set array(DIRECTORY,$ndirs) [lindex $line 1]
		  incr array(NDIRECTORIES)
	      }
	      ^DISP {
		  # DISPERSION
		  set array(DISPERSION) [lindex $line 1]
		  # Assume that this is synchrotron data
		  set array(SYNCHROTRON) 1
	      }
	      ^DISTA {
		  # DISTANCE
		  set array(DISTANCE) [lindex $line 1]
	      }
	      ^DISTO {
		  # DISTORTION
		  # Iterate over possible suboptions
		  set i 1
		  set nopts [llength $line]
		  while { $i < $nopts } {
		      set option [string toupper [lindex $line $i]]
		      switch -regexp -- $option {
			  ^ROFF {
			      # Radial offset
			      incr i
			      set array(DISTORTION_ROFF) [lindex $line $i]
			  }
			  ^TOFF {
			      # Tangential offest
			      incr i
			      set array(DISTORTION_TOFF) [lindex $line $i]
			  }
			  ^TILT {
			      # Detector tilt
			      incr i
			      set array(DISTORTION_TILT) [lindex $line $i]
			  }
			  ^YSCAL {
			      # Ratio of pixel size in x/y direction
			      incr i
			      set array(DISTORTION_YSCAL) [lindex $line $i]
			  }
			  ^TWIST {
			      # Detector rotation around horizontal axis
			      incr i
			      set array(DISTORTION_TWIST) [lindex $line $i]
			  }
		      }
		      incr i
		  }
	      }
	      ^DIVE {
		  # DIVERGENCE
		  # Could be followed by either one or two values
		  if { [llength $line] > 2 } {
		      set array(DIVERGENCE_X) [lindex $line 1]
		      if { [llength $line] > 3 } {
			  set array(DIVERGENCE_Y) [lindex $line 2]
		      }
		  }
		  # Assume that this is synchrotron data
		  set array(SYNCHROTRON) 1
	      }
	      ^DSTA {
		  # DSTARMAX - not implemented yet
		  append unimplemented "$line\n" 
	      }
	      ^EXIT {
		  # EXIT keyword should be read but ignored!
	      }
	      ^EXTE {
		  # EXTENSION
		  # Store this unofficially now and
		  # process later along with "ident"
		  # to make a template
		  set extension [lindex $line 1]
	      }
	      ^GAIN {
		  # GAIN
		  set array(GAIN) [lindex $line 1]
	      }
	      ^GENF {
		  # GENFILE - this is redundant for batch mode
		  append redundant "$line\n"
	      }
	      ^HARV {
		  # HARVEST - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^HKLO {
		  # output reflection file as MTZ
		  set array(HKLOUT) [lindex $line 1]
	      }
	      ^IDEN {
		  # IDENT
		  # Store this unofficially now and
		  # process later along with "extension"
		  # to make a template
		  set ident [lindex $line 1]
	      }
	      ^IMAG {
		  # this shouldn't be in a file for batch integration - 
		  # so read it but ignore it. I suppose it should be 
		  # possible to extract the template from it.
	      }
	      ^LATT {
		  # LATTICE - not implemented yet - probably no need
		  append unimplemented "$line\n"
	      }
	      ^LIMI {
		  # LIMITS - not implemented yet - only for unknown detectors, 
		  # normally
		  append unimplemented "$line\n"
	      }
	      ^MATR {
		  # MATRIX
		  # Matrix file, probably obtained from postrefinement
		  set matrix_file [lindex $line 1]
	      }
	      ^MAXW {
		  # MAXWIDTH - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^MISS {
		  # MISSET - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^MOSA {
		  # MOSAIC
		  set array(MOSAICITY) [lindex $line 1]
	      }
	      ^NEWM {
		  # NEWMATRIX
		  # New matrix file from this run
		  set new_matrix_file [lindex $line 1]
	      }
	      ^NOME {
		  # NOMEASURE - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^NULL {
		  # NULLPIX
		  set array(NULLPIX) [lindex $line 1]
	      }
	      ^OVER {
		  # OVERLOAD
		  # Iterate over possible suboptions
		  set i 1
		  set nopts [llength $line]
		  while { $i < $nopts } {
		      set option [string toupper [lindex $line $i]]
		      switch -regexp -- $option {
			  ^NOVE {
			      # overload flagging value
			      incr i
			      set array(OVERLOAD_NOVER) [lindex $line $i]
			  }
			  ^CUTO {
			      # overload cutoff value
			      incr i
			      set array(OVERLOAD_CUTOFF) [lindex $line $i]
			  }
		      }
		      incr i
		  }
	      }
	      ^PIXE {
		  # PIXEL - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^PLOT {
		  # PLOT - not implemented, irrelevant for batch
		  append inappropriate "$line\n"
	      }
              ^PNAME {
                  # PNAME - project name
		  set HARVEST_PNAME [lindex $line 1]
              }
              ^DNAME {
                  # DNAME - dataset name
		  set HARVEST_DNAME [lindex $line 1]
              }
              ^XNAME {
                  # XNAME - crystal name
		  set HARVEST_XNAME [lindex $line 1]
              }
	      ^POLA {
		  # POLARISATION - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^POST {
		  # POSTREF
		  # Store the lines for processing (haha) later on
		  lappend process_lines $line
	      }
	      ^PRIN {
		  # PRINT - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^PROC {
		  # PROCESS
		  # Store the lines for processing (haha) later on
		  lappend process_lines $line
	      }
	      ^PROF {
		  # PROFILE
                  # Subkeywords allowed here: TOLERANCE,
		  # XLINES,YLINES, OVERLOADS, PARTIALS, FIXBOX, NOOPT
		  # Initialise parameters to defaults
		  set array(PROFILE_OVERLOADS) 0
		  set array(PROFILE_PARTIALS)  0
		  set array(PROFILE_FIXBOX)    0
		  set array(PROFILE_OPTIMISE)  1
		  set array(PROFILE_USE_LINES) 0
		  # Iterate over possible suboptions
		  set i 1
		  set nopts [llength $line]
		  while { $i < $nopts } {
		      set option [string toupper [lindex $line $i]]
		      switch -regexp -- $option {
			  ^TOLE {
			      # TOLERANCE <min> <max>
			      incr i
			      set array(PROFILE_TOL_MIN) [lindex $line $i]
			      incr i
			      set array(PROFILE_TOL_MAX) [lindex $line $i]
			  }
			  ^XLIN {
			      # Initialise
			      set array(PROFILE_USE_LINES) 1
			      for { set j 1 } { $j <= 6 } { incr j } {
				  set array(PROFILE_XLINES_$j) ""
			      }
			      # XLINES followed by upto 6 integers
			      set maxopts [expr $nopts - $i]
			      if { $maxopts > 6 } { set maxopts 6 }
			      set pattern "\[0-9\]+"
			      set j 1
			      incr i
			      set subopt [lindex $line $i]
			      while { [regexp $pattern $subopt] && \
					  $j <= $maxopts } {
				  set array(PROFILE_XLINES_$j) $subopt
				  incr i
				  if { $i < $nopts } {
				      set subopt [lindex $line $i]
				  } else {
				      set subopt ""
				  }
			      }
			      # Make sure we step back to the previous
			      # argument at the end
			      incr i -1
			  }
			  ^YLIN {
			      # Initialise
			      set array(PROFILE_USE_LINES) 1
			      for { set j 1 } { $j <= 6 } { incr j } {
				  set array(PROFILE_YLINES_$j) ""
			      }
			      # yLINES followed by upto 6 integers
			      set maxopts [expr $nopts - $i]
			      if { $maxopts > 6 } { set maxopts 6 }
			      set pattern "\[0-9\]+"
			      set j 1
			      incr i
			      set subopt [lindex $line $i]
			      while { [regexp $pattern $subopt] && \
					  $j <= $maxopts } {
				  set array(PROFILE_YLINES_$j) $subopt
				  incr i
				  if { $i < $nopts } {
				      set subopt [lindex $line $i]
				  } else {
				      set subopt ""
				  }
			      }
			      # Make sure we step back to the previous
			      # argument at the end
			      incr i -1
			  }
			  ^OVER {
			      # OVERLOADS
			      set array(PROFILE_OVERLOADS) 1
			  }
			  ^PART {
			      # PARTIALS
			      set array(PROFILE_PARTIALS) 1
			  }
			  ^FIXB {
			      # FIXBOX
			      set array(PROFILE_FIXBOX) 1
			  }
			  ^NOOP {
			      # NOOPTIMISE
			      set array(PROFILE_OPTIMISE) 0
			  }
		      }
		      incr i
		  }
	      }
	      ^RAST {
		  # RASTER - has to have 5 numbers
		  for {set i 1} {$i<[llength $line]} {incr i} {
		      set array(RASTER_$i) [lindex $line $i]
		  }
	      }
	      ^REFI {
		  # REFINEMENT - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^REJE {
		  # REJECTION - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^RESO {
		  # RESOlution
                  # Expect either 1 number (which will be high res cutoff)
                  # or 2 numbers (lowres and hires)
                  # More complicated syntax not processed
		  set nopts [llength $line]
		  if { $nopts >= 2 } {
                    # Hires limit
                    set hires [lindex $line 1]
                    set array(RESOLUTION_MAX) $hires
                    if { $nopts >= 3 } {
                      # Lowres limit
                      set lowres [lindex $line 2]
                      # Check that this is a number
                      if { [string is double $lowres] } {
                        # Get the ordering right
                        if { $hires < $lowres } {
                          set array(RESOLUTION_MAX) $hires
                          set array(RESOLUTION_MIN) $lowres
			} else {
                          set array(RESOLUTION_MAX) $lowres
                          set array(RESOLUTION_MIN) $hires
                        }
                      }
                    }
                  }
	      }
	      ^RUN|GO {
		  # RUN/GO
		  # These can separate blocks of PROCESS
		  # commands
		  # Store it for now
		  lappend process_lines $line
	      }
	      ^SDMO {
		  # SDMON - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^SEPA {
		  # SEPARATION
		  # Spot separation parameters
		  set array(SEPARATION_X) [lindex $line 1]
		  set array(SEPARATION_Y) [lindex $line 2]
		  set option [string toupper [lindex $line 3]]
		  switch -regexp -- $option {
		      ^CLOS {
			  # swung out setting for beam centre
			  #incr i
			  set array(SEPARATION_CLOSE) 1
		      }
		  }
	      }
	      ^SHIF {
		  #  SHIFT - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^SITE {
		  # SITE - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^SIZE {
		  # SIZE - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^SPOT {
		  # SPOTS - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^SYMM {
		  # SYMMETRY
		  set array(SPACEGROUP) [lindex $line 1]
	      }
	      ^SYNC {
		  # SYNCHROTRON keyword
		  # Only recognise this if succeeded by POLARISATION
		  if { [llength $line] > 1 } {
		      if { [regexp -- "^POLA" [string toupper [lindex $line 1]]] } {
			  # Assume that it's synchrotron data
			  set array(SYNCHROTRON) 1
			  set array(POLARISATION) [lindex $line 2]
		      } else {
			  # Otherwise it's not implemented
			  append unimplemented "$line\n"
		      }
		  } else {
		      # Otherwise it's not implemented
		      append unimplemented "$line\n"
		  }
	      }
	      ^TEMP {
		  # TEMPLATE
		  set template [lindex $line 1]
	      }
	      ^THIC {
		  # THICKNESS - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^TIME {
		  # TIMEOUT - not implemented, irrelevant for batch
		  append inappropriate "$line\n"
	      }
	      ^TITL {
		  # TITLE
		  set array(TITLE) [lrange $line 1 end]
	      }
	      ^TWOT {
		  # Two theta swing of detector
                  set twotheta [lindex $line 1]
		  if { $twotheta == 0 } {
		      set array(BEAM_SWUNG) 0
		  } else {
		      set array(BEAM_SWUNG) 1
		  }
	      }
	      ^UNPA {
		  # UNPACK - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^UMAT {
		  #  UMATRIX - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^WAIT {
		  # WAIT - not implemented yet
		  append unimplemented "$line\n"
	      }
	      ^WAVE {
		  # WAVELENGTH
		  set array(WAVELENGTH) [lindex $line 1]
	      }
	      default {
		  # Ignore comment lines
		  if { ![regexp "^\[\#!\]" $keyword] } {
		      # Unrecognised keyword - save it and warn
		      # the user at the end that it wasn't processed
		      append unprocessed "$line\n"
		  }
	      }
	  }
      }
  }
  # Finished
  unset contents

  # Post-processing ...

  # Construct a template from ident and extension, if both
  # were supplied: TEMPLATE = IDENT + "_###." + EXTENSION
  if { $ident != "" } {
      # If the extension wasn't set then assume default "pck"
      if { $extension == "" } { set extension "pck" }
      set array(TEMPLATE) ""
      append array(TEMPLATE) $ident "_\#\#\#." $extension
      mosflm_set_hklout $arrayname
  } else {
      set array(TEMPLATE) $template
      mosflm_set_hklout $arrayname
  }

  # Check directories
  for { set i 1 } { $i <= $array(NDIRECTORIES) } { incr i } {
      # Is this a relative or an absolute path?
      if { [file pathtype $array(DIRECTORY,$i)] != "absolute" } {
	  # Relative path - try to generate absolute path
	  # First try relative to the batchfile directory
          set this_dir [file join [file dirname $batchfile] $array(DIRECTORY,$i)]
	  if { [file isdirectory $this_dir] } {
	      set array(DIRECTORY,$i) $this_dir
	  } else {
	      # Didn't work? Then try relative to the project dir
	      set this_dir [file join [GetDefaultDirPath] $array(DIRECTORY,$i)]
	      if { [file isdirectory $this_dir] } {
		  set array(DIRECTORY,$i) $this_dir
	      } else {
		  # Didn't work? Then try relative to cwd
		  set this_dir [file join [pwd] $array(DIRECTORY,$i)]
		  if { [file isdirectory $this_dir] } {
		      set array(DIRECTORY,$i) $this_dir
		  }
	      }  
	  }  
      }
  }

  # Deal with matrix file
  if { $matrix_file != "" } {
      # Try and locate the matrix file
      set filen [file tail $matrix_file]
      if { [set dirs [file dirname $matrix_file]] == "." } {
	  set dirs {}
      }
      # Other possible locations
      lappend dirs [file dirname $batchfile] [GetCurrentDir]
      for { set i 1 } { $i <= $array(NDIRECTORIES) } { incr i } {
	  lappend dirs $array(DIRECTORY,$i)
      }
      # Search for matrix file
      set ndirs [llength $dirs]
      set i 0
      set matrix_file ""
      while { $i < $ndirs && $matrix_file == "" } {
	  set matrix_file [file join [lindex $dirs $i] $filen]
	  if { ![file exists $matrix_file] } {
	      set matrix_file ""
	  }
	  incr i
      }
      # Did we find it?
      set array(MATRIX_FILE) $matrix_file
      if { $matrix_file != "" } {
	  set array(DIR_MATRIX_FILE) "Full path.."
	  mosflm_read_matrix_file $arrayname
      }
  }

  # Deal with multiple process lines
  set postref_segment 0
  if { [llength $process_lines] > 0 } {
      set array(NRUNS) 1
      set array(NPROCESS,$array(NRUNS)) 0
      # Keep a count of how many subsequent PROCESS lines
      # need to be ignored
      set ignore 0
      foreach line $process_lines {
	  if { [llength $line] > 0 } {
	      set keyword [string toupper [lindex $line 0]]
	      switch -regexp $keyword {
		  ^POST {
		      # POSTREF line
		      # If the POSTREF line contains a SEGMENT
                      # command then we ignore it, however we
                      # need to read how many SEGMENTS and then
                      # also reject this number of PROCESS lines
		      if { [set ii [lsearch -regexp $line ^SEGM]] > -1 } {
			  set ignore [lindex $line [incr ii]]
			  incr postref_segment $ignore
		      } else {
			  # Assume that this is a NOSEGMENT line
			  # Deal with subkeys MULTI/NOMULTI, FIX/UNFIX,
			  # OFF, SDFAC, MOSADD and MOSSMOOTH
			  set iopt 1
			  set i $array(NRUNS)
			  # Initialise defaults
			  mosflm_initialise_run $arrayname $i
			  # Deal with the rest of the line
			  while { $iopt < [llength $line] } {
			      set keyword [string toupper [lindex $line $iopt]]
			      switch -regexp $keyword {
				  ^OFF$ {
				      # OFF - Turn off postrefinement
				      set array(POSTREF,$i) 0
				  }
				  ^MULT {
				      # MULTI - use partials over multiple images
				      set array(POSTREF_MULTI,$i) 1
				  }
				  ^NOMUL {
				      # NOMULTI - switch off MULTI
				      set array(POSTREF_MULTI,$i) 0
				  }
				  ^SDFA {
				      # SDFAC - set threshold for using reflns
				      incr iopt
				      set array(POSTREF_SDFAC,$i) [lindex $line $iopt]
				  }
				  ^WIDT {
				      # WIDTH - maximum width of reflections to include
				      incr iopt
				      set array(POSTREF_WIDTH,$i) [lindex $line $iopt]
				  }
				  ^MOSADD {
				      # MOSADD - "safety factor" for mosiac spread
				      incr iopt
				      set array(POSTREF_MOSADD,$i) [lindex $line $iopt]
				  }
				  ^MOSSMO {
				      # MOSADD - smoothing of mosiac spread
				      incr iopt
				      set array(POSTREF_MOSSMOOTH,$i) \
					  [lindex $line $iopt]
				  }
				  ^FIX {
				      # FIX - fix parameters instead of refining them
				      # Subkeys: ALL, A, B, C, ALPHA, BETA, GAMMA,
				      # MOSAIC
				      set icontinue 1
				      incr iopt
				      while { $iopt < [llength $line] && $icontinue } {
					  set fix_opt [lindex $line $iopt]
					  switch -regexp $fix_opt {
					      ^ALL {
						  set array(POSTREF_FIX_ALL,$i) 1
					      }
					      ^A$ {
						  set array(POSTREF_FIX_A,$i) 1
					      }
					      ^B$ {
						  set array(POSTREF_FIX_B,$i) 1
					      }
					      ^C$ {
						  set array(POSTREF_FIX_C,$i) 1
					      }
					      ^ALPH {
						  set array(POSTREF_FIX_ALPHA,$i) 1
					      }
					      ^BETA {
						  set array(POSTREF_FIX_BETA,$i) 1
					      }
					      ^GAMM {
						  set array(POSTREF_FIX_GAMMA,$i) 1
					      }
					      ^MOSA {
						  set array(POSTREF_FIX_MOSAIC,$i) 1
					      }
					      default {
						  # Didn't recognise this subkey
						  # Assume that its the next POSTREF
						  # option
						  set icontinue 0
						  incr iopt -1
					      }
					  }
					  # Next subkeyword of POSTREF FIX
					  incr iopt
				      }
				  }
			      }
			      # Next subkeyword of POSTREF
			      incr iopt
			  }
		      }
		  }
		  ^PROC {
		      # PROCESS line
		      # Check whether we are ignoring this line
		      if { $ignore > 0 } {
			  incr ignore -1
		      } else {
			  incr array(NPROCESS,$array(NRUNS))
			  # Initialise array parameters
			  mosflm_initialise_process $arrayname $array(NRUNS) \
			      $array(NPROCESS,$array(NRUNS))
			  # Make shorthand for the array index
			  set i "[subst $array(NRUNS)]_$array(NPROCESS,$array(NRUNS))"
			  # Parse it
			  # Syntax is PROCESS img1 [TO] img2
			  #                   [START <phi> [ANGLE <phiangle>]]
			  #                   [ADD <nadd> BLOCK <nblock>]
			  #
			  # Get first and last image numbers
			  set array(PROCESS_FIRST,$i) [lindex $line 1]
			  set array(PROCESS_LAST,$i) [lindex $line 2]
			  set pattern "\[0-9\]+"
			  set iopt 3
			  if { ![regexp $pattern $array(PROCESS_LAST,$i)] } {
			      set keyword [string toupper [lindex $line 2]]
			      if { [regexp "TO|to" $array(PROCESS_LAST,$i)] } {
				  set array(PROCESS_LAST,$i) [lindex $line 3]
				  set iopt 4
			      }
			  }
			  # Deal with the rest of the line
			  while { $iopt < [llength $line] } {
			      set keyword [string toupper [lindex $line $iopt]]
			      switch -regexp $keyword {
				  ^START {
				      incr iopt
				      set array(PROCESS_START,$i) [lindex $line $iopt]
				  }
				  ^ANGLE {
				      incr iopt
				      set array(PROCESS_ANGLE,$i) [lindex $line $iopt]
				  }
				  ^ADD {
				      set array(PROCESS_USE_ADD,$i) 1
				      incr iopt
				      set array(PROCESS_ADD,$i) [lindex $line $iopt]
				  }
				  ^BLOCK {
				      set array(PROCESS_USE_BLOCK,$i) 1
				      incr iopt
				      set array(PROCESS_BLOCK,$i) [lindex $line $iopt]
				  }
			      }
			      # Next option...
			      incr iopt
			  }
		      }
		  }
		  ^RUN|GO {
		      # Delimits a run
		      # Initialise for the next set of process lines
		      if { $array(NPROCESS,$array(NRUNS)) > 0 } {
			  incr array(NRUNS)
			  set array(NPROCESS,$array(NRUNS)) 0
		      }
		  }
	      }
	  }
      }
      # Make sure that we don't have too many runs defined
      if { $array(NPROCESS,$array(NRUNS)) == 0 } { incr array(NRUNS) -1 }
  }

  # If there are no runs or no blocks of images defined then
  # set up the initial values here
  if { $array(NRUNS) < 1 } {
      set array(NRUNS) 1
      mosflm_initialise_run $arrayname 1
      set array(NPROCESS,1) 1
      mosflm_initialise_process $arrayname 1 1
  }  

  # Issue warnings to the user about parts of the input script that
  # were dealt with an unexpected way

  set warning_message ""

  # Were there unimplemented commands?
  if { $unimplemented != "" } {
      append warning_message "
The interface has ignored the following lines from
the script file:

$unimplemented
This is because these commands are not currently
implemented in the MOSFLM interface.\n"
  }

  # Were there inappropriate commands for batch mode?
  if { $inappropriate != "" } {
      append warning_message "
The interface has ignored the following lines from
the script file:

$inappropriate
because these commands are not appropriate when
running MOSFLM in batch mode.\n"
  }

  # Were there redundant commands for the interface?
  if { $redundant != "" } {
      append warning_message "
The interface has ignored the following lines from
the script file:

$redundant
because these commands are redundant when
running MOSFLM through the CCP4i interface.\n"
  }

  # Were there unprocessed lines?
  if { $unprocessed != "" } {
      append warning_message "
The interface was unable to process the following
lines from the script file:

$unprocessed"
  }

  # Were any POSTREF SEGMENT commands encountered?
  if { $postref_segment > 0 } {
      append warning_message "
The interface encountered POSTREF SEGMENT commands
and $postref_segment PROCESS commands were skipped as a result"
  }

  # Tidy up any warnings
  if { $warning_message != "" } {
      append warning_message "\n"
  }

  # Redraw the task window - this is the easiest way to ensure
  # that the toggle frame is updated etc
  set w $array(WINDOW)
  RerenderTask $w $arrayname mosflm

  return $warning_message
}

#--------------------------------------------------------------
proc MosflmSetMenuValue { arrayname menuvar value } {
#--------------------------------------------------------------
# Given the alias value, set a menu variable to the correct
# value for display
# PJX This is rather clumsy, and probably ought to be provided
# in the CCP4i core instead ho hum
  upvar #0 $arrayname array
  global typedef
    set type [GetType $arrayname $menuvar]
    if { ![info exists typedef($type)] } {
	puts "Error cannot find definition of $type in $typedef"
	return
    }
    if { [lindex $typedef($type) 0] != "menu" } {
	puts "Error parameter $menuvar is not of class \"menu\""
	return
    }
    set len [llength $typedef($type)]
    if { $len == 2 } {
	# No aliases defined
	set array($var) $value
    } elseif { $len == 3 } {
	# Search in the list of aliases for the
	# supplied value
	set pos [lsearch [lindex $typedef($type) 2] $value]
	if { $pos < 0 } {
	    puts "Error value not found"
	    set array($menuvar) $value
	} else {
	    set array($menuvar) [lindex [lindex $typedef($type) 1] $pos]
	}
    }      
    return
}

#--------------------------------------------------------------
proc mosflm_read_matrix_file { arrayname } {
#--------------------------------------------------------------
# Read a Mosflm A matrix file
    upvar #0 $arrayname array

    set filename [GetFullFileName0 $arrayname MATRIX_FILE]

    # Check that the file actually exists
    if { ![file exists $filename] } {
	WarningMessage "WARNING
Matrix file:

$filename

not found."
	return
    }

    # Set up an error message to use if the file contents
    # aren't what we expect
    set message "ERROR
Unexpected content in A matrix file:

$filename\n"

    # Set up a list of parameter names corresponding to the
    # expected contents
    set params [list \
		    { MAT_11 MAT_12 MAT_13 } \
		    { MAT_21 MAT_22 MAT_23 } \
		    { MAT_31 MAT_32 MAT_33 } \
		    { ADD_MISSET_1 ADD_MISSET_2 ADD_MISSET_3 } \
		    { SET_11 SET_12 SET_13 } \
		    { SET_21 SET_22 SET_23 } \
		    { SET_31 SET_32 SET_33 } \
		    { CELL_1 CELL_2 CELL_3 CELL_4 CELL_5 CELL_6 } \
		    { JUNK JUNK JUNK } ]
    set nlines [llength $params]

    # Initialise "contents"
    set contents ""

    # Read the contents of the file into a list of lines
    ReadFile $filename contents -split

    # Process the contents - match to the parameter list
    set i 0
    foreach line $contents {
	if { $i <= $nlines } {
	    set param_list [lindex $params $i]
	    if { [llength $param_list] == [llength $line] } {
		foreach param $param_list value $line {
		    set array($param) $value
		}
	    } else {
		# More (or fewer) items than expected on a line
		append message "\nMismatched number of items in a line:
Line $i: $line"
		WarningMessage $message
		return
	    }
	} else {
	    # More lines in the file than we expected
	    puts "mosflm_read_matrix_file: More lines than expected in file ($nlines)"
	    return
	}
	# Next line
	incr i
    }
    # Everything done
    return
}

#--------------------------------------------------------------
proc mosflm_update_cell_display { arrayname } {
#--------------------------------------------------------------
# Internal function: update the text display of the CELL parameters
# in the varlabels.
  upvar #0 $arrayname array
  foreach param [list CELL_1 CELL_2 CELL_3 CELL_4 CELL_5 CELL_6] {
    set field_list [GetWidget $arrayname $param]
    foreach field $field_list {
      if { [winfo exists $field] } {
        $field configure -text $array($param)
      }
    }
  }
  return
}

#--------------------------------------------------------------
proc mosflm_set_hklout { arrayname } {
#--------------------------------------------------------------
# Internal function: generate an output MTZ filename from the
# template name
  upvar #0 $arrayname array

  set template $array(TEMPLATE)
  # Strip off extension and any leading path
  set template [file tail [file rootname $template]]
  # Remove trailing wildcards
  if { [regexp "\[^\#\]*" $template basename] } {
    # Generate a unique name
    set i 0
    while { $i < 100 } {
      set filename ""
      append filename $basename $i ".mtz"
      set array(HKLOUT) $filename
      # Fetch the whole filename and see if a file with
      # this name already exists
      set filename [GetFullFileName0 $arrayname HKLOUT]
      if { ![file exists $filename] } {
        # Set i > 100 to jump out of the loop
        set i 100
      }
      incr i
    }
  } else {
    puts "mosflm_set_hklout: regexp failed!"
  }
  return
}

#--------------------------------------------------------------
proc mosflm_initialise_run { arrayname nrun } {
#--------------------------------------------------------------
# Internal function: initialise the defaults for a process run
    upvar \#0 $arrayname array
    set array(POSTREF,$nrun) 1
    set array(POSTREF_MULTI,$nrun) 1
    set array(POSTREF_SDFAC,$nrun) 3.0
    set array(POSTREF_FIX_ALL,$nrun) 1
    set array(POSTREF_FIX_CELL,$nrun) SOME
    set array(POSTREF_FIX_A,$nrun) 0
    set array(POSTREF_FIX_B,$nrun) 0
    set array(POSTREF_FIX_C,$nrun) 0
    set array(POSTREF_FIX_ALPHA,$nrun)  0
    set array(POSTREF_FIX_BETA,$nrun)   0
    set array(POSTREF_FIX_GAMMA,$nrun)  0
    set array(POSTREF_FIX_MOSAIC,$nrun) 0
    set array(POSTREF_WIDTH,$nrun) ""
    set array(POSTREF_MOSADD,$nrun) ""
    set array(POSTREF_MOSSMOOTH,$nrun) ""
    return
}

#--------------------------------------------------------------
proc mosflm_initialise_process { arrayname nrun nprocess } {
#--------------------------------------------------------------
# Internal function: initialise the defaults for a process
# block
    upvar \#0 $arrayname array
    set n "[subst $array(NRUNS)]_$array(NPROCESS,$array(NRUNS))"
    set array(PROCESS_FIRST,$n) ""
    set array(PROCESS_LAST,$n) ""
    set array(PROCESS_START,$n) ""
    set array(PROCESS_ANGLE,$n) ""
    set array(PROCESS_USE_ADD,$n) 0
    set array(PROCESS_ADD,$n) ""
    set array(PROCESS_USE_BLOCK,$n) 0
    set array(PROCESS_BLOCK,$n) ""
    return
}
