# $Id: bespokedetectorsettings.tcl,v 1.11 2012/03/26 16:36:38 ccb Exp $
package provide bespokedetectorsettings 1.0

# add classes both for refineable detector parameters and fixed ones. The latter 
# should be hidden except for experts.
# Class
class BespokeDetectorSettings {
    inherit itk::Widget Settings2
    
    # variables
    ###########
    # none #
    
    # methods
    #########
    
    #public method tabbing
	#simply a wrapper for the session resetDetector method because
	# we draw this winidow before we initialise session
	public method resetDetector
    
    constructor { args } {
    }
}
body BespokeDetectorSettings::constructor { args } {
    itk_component add yScaleLabel {
	label $itk_interior.yScaleLabel -text "Y Scale: " 
    }

    itk_component add yScaleEntry {
	SettingEntry $itk_interior.yScaleEntry yscale \
	    -type real \
	    -precision 3 \
	    -minimum "0.25" \
	    -maximum "4" \
	    -width 6 \
	    -justify right
    }

    itk_component add RoffLabel {
	label $itk_interior.radial_offset -text "Offsets: radial:"
    }

    itk_component add RoffEntry {
	SettingEntry $itk_interior.radialOffsetEntry radial_offset \
	    -type real \
	    -precision 3 \
	    -minimum "-10.0" \
	    -maximum "10.0" \
	    -width 6 \
	    -justify right
    }

    itk_component add ToffLabel {
	label $itk_interior.tangential_offset -text " tangential: " 
    }

    itk_component add ToffEntry {
	SettingEntry $itk_interior.tangentialOffsetEntry tangential_offset \
	    -type real \
	    -precision 3 \
	    -minimum "-10.0" \
	    -maximum "10.0" \
	    -width 6 \
	    -justify right
    }

    itk_component add CCOMLabel {
	label $itk_interior.ccomegal -text "ccomega " 
    }

    itk_component add CCOMEntry {
	SettingEntry $itk_interior.ccomagae ccomega \
	    -type real \
	    -precision 3 \
	    -minimum "-10.0" \
	    -maximum "10.0" \
	    -width 6 \
	    -justify right
    }

    itk_component add TiltLabel {
	label $itk_interior.tilt -text "Detector tilt: "
    }

    itk_component add TiltEntry {
	SettingEntry $itk_interior.tiltEntry tilt \
	    -type real \
	    -minimum "-5.0" \
	    -maximum "+5.0" \
	    -width 6 \
	    -justify right
    }

    itk_component add TwistLabel {
	label $itk_interior.twist -text " twist: " 
    }

    itk_component add TwistEntry {
	SettingEntry $itk_interior.twistEntry twist \
	    -type real \
	    -minimum "-5.0" \
	    -maximum "+5.0" \
	    -width 6 \
	    -justify right
    }
#
# detector manufacturer and type
    itk_component add MachineLabel {
	label $itk_interior.machine_label -text "Detector: " 
    }
    
    itk_component add MachineEntry {
	SettingEntry $itk_interior.machine_entry detector_manufacturer \
	    -width 8 \
	    -justify right
	}
    
    itk_component add ModelLabel {
	label $itk_interior.model_label -text " model: " 
    }
    
    itk_component add ModelEntry {
	SettingEntry $itk_interior.model_entry detector_model \
	    -width 8 \
	    -justify right
    }

    itk_component add SernoLabel {
	label $itk_interior.serno_label -text "serial number: " 
    }
    
    itk_component add SernoEntry {
	SettingEntry $itk_interior.serno_entry detector_serno \
	    -width 14 \
	    -justify right
    }

    itk_component add gain_label {
	label $itk_interior.gl  -text "Gain: "
    }

    itk_component add gain_entry {
	SettingEntry $itk_interior.ge gain \
	    -type real \
	    -precision 2 \
	    -minimum "0" \
	    -maximum "100" \
	    -width 6 \
	    -justify right
    }

    itk_component add adcoffset_label {
	label $itk_interior.aol  -text "ADC offset: "
    }

    itk_component add pixel_label {
	label $itk_interior.pixell  -text "Pixel size: "
    }

    itk_component add pixel_entry {
	SettingEntry $itk_interior.pixele pixel_size \
	    -type real \
	    -precision 3 \
	    -minimum "0.01" \
	    -maximum "1" \
	    -width 6 \
	    -justify right
    }
    
    itk_component add adcoffset_entry {
	SettingEntry $itk_interior.aoe adcoffset\
	    -type int \
	    -minimum "0" \
	    -width 6 \
	    -justify right
    }

    itk_component add reset_defaults_label {
	label $itk_interior.rstdbl  -text "Default parameters: "
    }

    itk_component add reset_detector_button {
	button $itk_interior.rstdb \
	    -text "Reset" \
	    -command [code $this resetDetector] 
    }

    itk_component add refineable_parameters_l {
	gSection $itk_interior.refineable_parameters_label -text "Refineable detector parameters "
    }

    itk_component add non_refineable_parameters_l {
	gSection $itk_interior.non_refineable_parameters_label -text "Non-refineable detector parameters "
    }
   
    grid  $itk_component(refineable_parameters_l) - - - - - - -sticky we -pady {4 0}
    grid  x $itk_component(yScaleLabel) $itk_component(yScaleEntry)  x -sticky we
    grid  x $itk_component(RoffLabel) $itk_component(RoffEntry) x $itk_component(ToffLabel)   $itk_component(ToffEntry) -sticky we 
    grid  x $itk_component(CCOMLabel) $itk_component(CCOMEntry) -sticky we 
    grid  x $itk_component(TiltLabel) $itk_component(TiltEntry) x $itk_component(TwistLabel)  $itk_component(TwistEntry) -sticky we
    grid  $itk_component(non_refineable_parameters_l) - - - - - - -sticky we -pady {4 0}    
    grid  x $itk_component(MachineLabel) $itk_component(MachineEntry) x $itk_component(ModelLabel)  $itk_component(ModelEntry) -pady 4 -sticky we
    grid  x $itk_component(SernoLabel) $itk_component(SernoEntry) -sticky we
    grid  x $itk_component(gain_label) $itk_component(gain_entry) x -sticky we    
    grid x $itk_component(adcoffset_label) $itk_component(adcoffset_entry) x -sticky we -pady {4 0}
    grid  x $itk_component(pixel_label) $itk_component(pixel_entry) x -sticky we
    grid x $itk_component(reset_defaults_label) $itk_component(reset_detector_button) x -sticky e -pady {40 0}
    grid columnconfigure $itk_interior { 0 1 3 4 5 } -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    
    eval itk_initialize $args
    
}

body BespokeDetectorSettings::resetDetector { } {
	$::session resetDetector
}
    
########################################################################
# Usual config options                                                 #
########################################################################

usual BespokeDetectorSettings {
    keep -background
    keep -foreground
    keep -selectbackground
    keep -selectforeground
    keep -textbackground
    keep -font
    keep -entryfont
}

########################################################################
# Expert options for adding new detectors                                                #
########################################################################
class HiddenDetectorSettings {
    inherit itk::Widget Settings2
    

    # variables
    ###########
    # none #
    
    # methods
    #########
    
    #public method tabbing
    constructor { args } {
    }
}
    
body HiddenDetectorSettings::constructor { args } {
    
    # spiral or orthogonal scan #########################################
    itk_component add spiral_check {
	SettingCheckbutton $itk_interior.spiral spiral \
	    -text "Spiral readout" 
    }

    # invert X direction of scan #########################################
        itk_component add invertx_check {
	SettingCheckbutton $itk_interior.invertx invertx \
	    -text "Invert X direction" 
    }
    #  
    # layout ####################################
    
    # physical detector constants #######################################
    
    itk_component add omega_label {
	label $itk_interior.omegal  -text "Detector omega: "
    }
    
    itk_component add omega_entry {
	SettingCombo $itk_interior.omegae detector_omega \
	    -width 3 \
	    -items { 0 90 180 270 } \
	    -editable 0
    }
    
    #
    # image header size & image size (NREC & IYLEN)
    itk_component add header_label {
	label $itk_interior.header_label -text "Number of header bytes: " 
    }
    
    itk_component add header_entry {
	SettingEntry $itk_interior.header_entry header_size \
	    -width 8 \
	    -justify right
    }
    
    itk_component add image_size_label {
	label $itk_interior.image_size_label -text "Image size (pixels): " 
    }
    
    itk_component add image_height_entry  {
	SettingEntry $itk_interior.image_height_entry image_height \
	    -width 8 \
	    -justify right
    }
    
    itk_component add image_width_entry {
	SettingEntry $itk_interior.image_width_entry image_width \
	    -width 8 \
	    -justify right
    }
    
    itk_component add pixel_label {
	label $itk_interior.pixel_label -text "Pixel size (mm): " 
    }
    
    itk_component add pixel_entry  {
	SettingEntry $itk_interior.pixel_entry pixel_size \
	    -width 8 \
	    -justify right
    }
    
    itk_component add gain_label {
	label $itk_interior.gl  -text "Gain: "
    }
    
    itk_component add gain_entry {
	SettingEntry $itk_interior.ge gain \
	    -type real \
	    -precision 2 \
	    -minimum "0" \
	    -maximum "100" \
	    -width 6 \
	    -justify right
    }

    itk_component add bias_label {
	label $itk_interior.biasl  -text "Bias: "
    }
    
    itk_component add bias_entry {
	SettingEntry $itk_interior.biase bias \
	    -type int \
	    -minimum "0" \
	    -width 6 \
	    -justify right
    }
    
    itk_component add adcoffset_label {
	label $itk_interior.adcoffsetl  -text "ADC offset: "
    }
    
    itk_component add adcoffset_entry {
	SettingEntry $itk_interior.adcoffsete adcoffset \
	    -type int \
	    -minimum "0" \
	    -width 6 \
	    -justify right
    }
    
    itk_component add fixed_parameters_l {
	gSection $itk_interior.fixed_parameters_label -text "Fixed detector parameters "
    }
    
    itk_component add fixed_parameters_w1 {
	label $itk_interior.fixed_parameters_warnings1 \
	    -text "(1) You probably don't need to change these unless you \nhave an unusual detector!" \
		-font font_i
    } {
	usual
	ignore -font
    }
	
    itk_component add fixed_parameters_w2 {
	label $itk_interior.fixed_parameters_warnings2 \
	    -text "(2) Don't be tempted to play with these if you only think\nyou know what you are doing" \
	    -font font_i
    } {
	usual
	ignore -font
    }
    grid  $itk_component(fixed_parameters_l) - - - - - - -sticky we -pady {9 0}
    grid  $itk_component(fixed_parameters_w1) -columnspan 8 -pady 2 -sticky w 
    grid  $itk_component(fixed_parameters_w2) -columnspan 8 -pady 2 -sticky w 
    grid  x $itk_component(spiral_check) -columnspan 4 -sticky we
    grid  x $itk_component(invertx_check) -columnspan 4 -sticky we
    grid  x $itk_component(omega_label) $itk_component(omega_entry) x  -sticky we
    grid  x $itk_component(header_label) $itk_component(header_entry) x -sticky we
    grid  x $itk_component(image_size_label) $itk_component(image_height_entry) x $itk_component(image_width_entry) x -sticky we
    grid  x $itk_component(pixel_label) $itk_component(pixel_entry) x -sticky we
    grid  x $itk_component(bias_label)  $itk_component(bias_entry) x   -sticky we	
    grid  x $itk_component(adcoffset_label)  $itk_component(adcoffset_entry) x  -sticky we
    grid columnconfigure $itk_interior { 0 1 3 4 5 } -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    eval itk_initialize $args
    
}


########################################################################
# Usual config options                                                 #
########################################################################

usual HiddenDetectorSettings {
    keep -background
    keep -foreground
    keep -selectbackground
    keep -selectforeground
    keep -textbackground
    keep -font
    keep -entryfont
}

########################################################################
# Options for adding new detectors customizing this detector           #
########################################################################

class AdjustableDetectorSettings {
    inherit itk::Widget Settings2
    
    # variables
    ###########
    # none #
    
    # methods
    #########
    
    #public method tabbing
    constructor { args } {
    }
}
body AdjustableDetectorSettings::constructor { args } {

    itk_component add adjul {
	label $itk_interior.adjul -text "Adjustable detector parameters"
    }

    itk_component add usablel {
	label $itk_interior.usablel -text "Usable areas of the detector"
    }

# overloads
    itk_component add overloadCutoffLabel {
	label $itk_interior.olcl -text "Overload cutoff: "
    }
    itk_component add overloadCutoffEntry {
	SettingEntry $itk_interior.olce overload_cutoff \
	    -type int \
	    -minimum "0" \
	    -maximum "4000000" \
	    -width 7 \
	    -justify right
    }
    
    itk_component add profileOverloadCutoffLabel {
	label $itk_interior.polcl -text "Profile overload cutoff: "
    }

    itk_component add profileOverloadCutoffEntry {
	SettingEntry $itk_interior.polce profile_overload_cutoff \
	    -type int \
	    -minimum "0" \
	    -maximum "4000000" \
	    -width 7 \
	    -justify right
    }
# 
# usable area of detector - LIMITS XMIN, XMAX, XSCAN, YMIN, YMAX, YSCAN, RMIN, 
# RMAX, RSCAN - sometime later we'll put in something for masks here as well
# 
# also PROFILE XLINES, YLINES
#
    itk_component add limits_xmin_Label {
	label $itk_interior.xminl -text "xmin: "
    }

    itk_component add limits_xmin_Entry {
	SettingEntry $itk_interior.xmine  limits_xmin \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }

    itk_component add limits_xmax_Label {
	label $itk_interior. -text "xmax: "
    }

    itk_component add limits_xmax_Entry {
	SettingEntry $itk_interior.xmaxe  limits_xmax \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }

    itk_component add limits_xscan_Label {
	label $itk_interior.xscanl -text "xscan: "
    }

    itk_component add limits_xscan_Entry {
	SettingEntry $itk_interior.xscane limits_xscan \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }

# limits in Y

    itk_component add limits_ymin_Label {
	label $itk_interior.yminl -text "ymin: "
    }

    itk_component add limits_ymin_Entry {
	SettingEntry $itk_interior.ymine limits_ymin \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }
    
    itk_component add limits_ymax_Label {
	label $itk_interior.ymaxl -text "ymax: "
    }

    itk_component add limits_ymax_Entry {
	SettingEntry $itk_interior.ymaxe limits_ymax \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }

    itk_component add limits_yscan_Label {
	label $itk_interior.yscanl -text "yscan: "
    }

    itk_component add limits_yscan_Entry {
	SettingEntry $itk_interior.yscane limits_yscan \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }

# radial limits

    itk_component add limits_rmin_Label {
	label $itk_interior.rminl -text "rmin: "
    }

    itk_component add limits_rmin_Entry {
	SettingEntry $itk_interior.rmine  limits_rmin \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }
    
    itk_component add limits_rmax_Label {
	label $itk_interior.rmaxl -text "rmax: "
    }

    itk_component add limits_rmax_Entry {
	SettingEntry $itk_interior.rmaxe limits_rmax \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }
    
    itk_component add limits_rscan_Label {
	label $itk_interior.rscanl -text "xscan: "
    }

    itk_component add limits_rscan_Entry {
	SettingEntry $itk_interior.rscane limits_rscan \
	    -type int \
	    -minimum "0" \
	    -maximum "999" \
	    -width 3 \
	    -justify right
    }
#
# now to pack them in a grid
#
    grid  $itk_component(adjul) - - - - - - -sticky we -pady {9 0}
    grid  x $itk_component(overloadCutoffLabel)  $itk_component(overloadCutoffEntry) x -sticky we
    grid  x $itk_component(profileOverloadCutoffLabel)  $itk_component(profileOverloadCutoffEntry) x -sticky we
    grid  $itk_component(usablel) - - - - - - -sticky we -pady {9 0}
    grid  x $itk_component(limits_xmin_Label)  $itk_component(limits_xmin_Entry) x -sticky we
    grid  x $itk_component(limits_xmax_Label)  $itk_component(limits_xmax_Entry) x -sticky we
    grid  x $itk_component(limits_xscan_Label)  $itk_component(limits_xscan_Entry) x -sticky we
    grid  x $itk_component(limits_ymin_Label)  $itk_component(limits_ymin_Entry) x -sticky we
    grid  x $itk_component(limits_ymax_Label)  $itk_component(limits_ymax_Entry) x -sticky we
    grid  x $itk_component(limits_yscan_Label)  $itk_component(limits_yscan_Entry) x -sticky we
    grid  x $itk_component(limits_rmin_Label)  $itk_component(limits_rmin_Entry) x -sticky we
    grid  x $itk_component(limits_rmax_Label)  $itk_component(limits_rmax_Entry) x -sticky we
    grid  x $itk_component(limits_rscan_Label)  $itk_component(limits_rscan_Entry) x -sticky we
    grid columnconfigure $itk_interior { 0 1 3 4 5 } -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    
    eval itk_initialize $args

}
########################################################################
# Usual config options                                                 #
########################################################################

usual AdjustableDetectorSettings {
    keep -background
    keep -foreground
    keep -selectbackground
    keep -selectforeground
    keep -textbackground
    keep -font
    keep -entryfont
}

