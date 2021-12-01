#
#     Copyright (C) 1999-2006  Graeme Winter, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# ======================================================================
# xia2.tcl --
#
# Basic interface for Graeme Winter's XIA2
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------
proc xia2_prereq { } {
#------------------------------------------------------------------------
# Check that xia2 script is available
  # xia2
  if { ![file exists [FindExecutable xia2] ] || ![file exists [FindExecutable cctbx.python] ] } {
    return 0
  }
  return 1
}

#-----------------------------------------------------------------
proc xia2_setup { typedefVar arrayname } {
#-----------------------------------------------------------------
  upvar #0 $typedefVar typedef

  # Use this to set up custom menus

  # Variable menu for wavelength names defined by the user
  set typedef(_xia2_wavelengths) [list varmenu \
				      WAVELENGTH_MENU WAVELENGTH_ALIAS 10]

  # Static menu for wavelength names

  DefineMenu _xia2_wavelengthname [list "Native" "Inflection" "Peak" \
				       "Low Remote" "High Remote"] \
      [list NATIVE INFL PEAK LREM HREM]

  # procedure must return sucess code (1)
  # for drawing task window to continue
  return 1
}

#-----------------------------------------------------------------
proc xia2_task_window { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  if { [CreateTaskWindow $arrayname  \
	"Run XIA2 for data processing" "XIA2" \
	[ list \
	      "Define Wavelengths" \
	      "Define Sweeps" \
	      "Key Parameters" ] \
	   ] == 0 } return

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      label "Use XIA2 to reduce diffraction data (images) to merged structure factor amplitudes"

  CreateLine line \
      message "Set the project name for this run of XIA2" \
      label "Project:" \
      widget PROJECT_NAME \
      message "Set the crystal name for this run" \
      label "Crystal:" \
      widget XTAL_NAME \
      label "These will end up as PNAME/XNAME in the MTZ file..." \
      -italic


#=FILES================================================================

  OpenFolder file

  CreateOutputFileLine line \
      "Optionally enter name of output MTZ file" \
      "MTZ out:" \
      HKLOUT DIR_HKLOUT 

  # There are no files to be defined here at present

#=======================================================================
# FOLDER 1: DEFINE WAVELENGTHS 

  OpenFolder 1

  CreateLine linef1 label \
      "Define the wavelengths of data collection first..." \
      label "These labels will be the MTZ DNAMEs after processing." -italic


  CreateToggleFrame N_WAVELENGTHS Xia2Wavelengths \
      "Define a wavelength" "Wavelength number" \
      "Add Another Wavelength"  \
      [list \
	   WAVELENGTH_NAME \
	   WAVELENGTH_LAMBDA] \
      -edit_proc xia2_update_wavelength_menu

#=======================================================================
# FOLDER 2: DEFINE SWEEPS

  OpenFolder 2

  CreateLine linef2 label \
      "Then associate the sweeps of diffraction data with them..."

  CreateToggleFrame N_SWEEPS Xia2Sweeps \
      "Define a sweep" "Sweep number" \
      "Add Another Sweep"  \
      [list \
	   SWEEP_WAVELENGTH \
	   SWEEP_IMAGE \
	   SWEEP_DIR ]

#=======================================================================
# FOLDER 3: ALL OTHER PARAMETERS

  OpenFolder 3 closed

  CreateLine line \
      label "Less commonly used options" -italic

  # FIXME in here need to define a flag for -debug, another for 
  # -2d (default) or -3d. These will probably need to propogate 
  # back to the .def file as well as booleans...

  CreateLine line \
      widget DEBUG label "Include debugging output" \
      widget THREED label "Run processing with XDS"  

}

#-----------------------------------------------------------------
proc xia2_run { arrayname } {
#-----------------------------------------------------------------
  upvar #0 $arrayname array

  # Essentially a placeholder for now
  # Use this to do processing/checking after the user hits "run"

  # check that the output file is set correctly and add this as an
  # output file...

  set array(OUTPUT_FILES) "HKLOUT" 

  return 1
}

#---------------------------------------------------------------------
proc xia2_update_wavelength_menu { arrayname { count {} } } {
#---------------------------------------------------------------------
    # Update the variable menu WAVELENGTH_MENU
    # See the demo3 example from CCP4i workshop:
    # http://www.ccp4.ac.uk/ccp4i/workshop/extending_frames.html
    # "count" is a dummy argument which is specified when
    # CreateToggleFrame invokes the edit_proc
    upvar #0 $arrayname array
 
    # Initialise the list which will contain all of the items to appear on the menu
    set wavelength_menu {}
    set wavelength_alias {}

    # Add each of the wavelength names (WAVELENGTH_NAME) to the list
    for { set n 1 }  { $n <= $array(N_WAVELENGTHS) } { incr n } {
	lappend wavelength_menu $array(WAVELENGTH_NAME,$n) 
	lappend wavelength_alias [GetValue $arrayname WAVELENGTH_NAME,$n]
    }

    # Update the menu - this will automatically update everywhere that the menu
    # is displayed in the task interface
    UpdateVariableMenu $arrayname initialise 0 \
	WAVELENGTH_MENU $wavelength_menu \
	WAVELENGTH_ALIAS $wavelength_alias
}

#-----------------------------------------------------------------------------
proc Xia2Wavelengths { arrayname counter } {
#-----------------------------------------------------------------------------
    # Create one "line" of the "define wavelengths" toggle frame
    upvar #0 $arrayname array

    CreateLine line \
	label "Wavelength name:" \
	widget WAVELENGTH_NAME \
	-command "xia2_update_wavelength_menu $arrayname"

    CreateLine line \
	label "Wavelength" \
	widget WAVELENGTH_LAMBDA \
	label "(A)"
}

#-----------------------------------------------------------------------------
proc Xia2Sweeps { arrayname counter } {
#-----------------------------------------------------------------------------
    # Create one "line" of the "define sweeps" toggle frame
    upvar #0 $arrayname array

    # configure array contains font and colour information
    global configure

    CreateLine line \
	message "Choose a wavelength to include in this sweep" \
	label "Wavelength name:" \
	widget SWEEP_WAVELENGTH

    CreateLine line \
	message "Specify an image for this sweep" \
	label "Image name" \
	widget SWEEP_IMAGE -width 25

    CreateLine line \
	message "Specify the directory holding the images for this sweep" \
	label "Directory" \
	widget SWEEP_DIR -width 60

    # Make a "browse" button to allow the user to select directories
    # via the browser
    # This is a custom widget!

    set browse [button $line.browse -text "Browse" \
		    -command "xia2_browse $arrayname $counter"]
    $browse configure -font $configure(FONT_SMALL)
    pack $browse -after $line.e2 -side left

    CreateLine line \
	message "Optionally specify correct beam coordinates" \
	label "Beam centre X:" \
	widget SWEEP_BEAM_X \
	label "Y:" \
	widget SWEEP_BEAM_Y \
	label "(mm)"

}

#--------------------------------------------------------------
proc xia2_browse { arrayname counter } {
#--------------------------------------------------------------
# Use the file browser to select a directory containg images
# Taken from the mosflm.tcl file and modified for XIA2 interface

  upvar #0 $arrayname array

  if { [SelectFile filename -directory] } {
    # The browser can return either a filename or a directory
    # name - make sure we get the leading directory in the
    # former case
    if { [file isdirectory $filename] } {
      set dirname $filename
      set array(SWEEP_DIR,$counter) $dirname
    } else {
	set dirname [file dirname $filename]
      set image [file tail $filename]
      set array(SWEEP_DIR,$counter) $dirname
      set array(SWEEP_IMAGE,$counter) $image
    }
    # Update the parameters in the window
  }
  return
}
