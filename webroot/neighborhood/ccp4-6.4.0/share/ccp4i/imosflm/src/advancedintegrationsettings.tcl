# $Id: advancedintegrationsettings.tcl,v 1.5 2012/05/21 13:23:39 ccb Exp $
# package name
package provide advancedintegrationsettings 1.0

# Class
class Advancedintegrationsettings {
    inherit itk::Widget Settings2

    # variables
    ###########
    private variable profile_optimise_state 1
    private variable use_scala "0"

    # methods
    #########
    public method toggleProfileOptimise
    public method getUseScalaBool
    public method setUseScalaBool

    # widget callbacks

    public method debug

    constructor { args } { }

}

# Bodies

body Advancedintegrationsettings::debug { a_val } {
}

body Advancedintegrationsettings::constructor { args } {

    itk_component add raster_l {
        gSection $itk_interior.rasterlabel  -text "Measurement box parameters (pixels) "
    }
    
    itk_component add nxs_l {
        label $itk_interior.nxsl  -text "Box width:"  -anchor w
    }

    itk_component add nxs_e {
        SettingEntry $itk_interior.nxse raster_nxs \
	    -balloonhelp "Width of spot measurement box" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add nys_l {
        label $itk_interior.nysl  -text "Box height:"  -anchor w
    }

    itk_component add nys_e {
        SettingEntry $itk_interior.nyse raster_nys \
	    -balloonhelp "Height of spot measurement box" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add nc_l {
        label $itk_interior.ncl  -text "Corner cutoff:"  -anchor w
    }

    itk_component add nc_e {
        SettingEntry $itk_interior.nce raster_nc \
	    -balloonhelp "Number of pixels from corner that diagonal corner cuts off" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add nrx_l {
        label $itk_interior.nrxl  -text "Border width:"  -anchor w
    }

    itk_component add nrx_e {
        SettingEntry $itk_interior.nrxe raster_nrx \
	    -balloonhelp "Number of pixel columns at sides of box classed as background" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add nry_l {
        label $itk_interior.nryl  -text "Border height:"  -anchor w
    }

    itk_component add nry_e {
        SettingEntry $itk_interior.nrye raster_nry \
	    -balloonhelp "Number of pixel columns at top and bottom of box classed as background" \
	    -type int \
	    -width 7 \
	    -justify right
    }


    itk_component add nullpix_l {
        label $itk_interior.nullpixl  -text "Null pixel threshold:"  -anchor w
    }

    itk_component add nullpix_e {
        SettingEntry $itk_interior.nullpixe nullpix \
	    -balloonhelp "Spots containing a pixel with a value lower than this are ignored" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add max_refl_width_l {
        label $itk_interior.mrwl  -text "Maximum reflection width in \u3c6 (\u0b0):"  -anchor w
    }

    itk_component add max_refl_width_e {
        SettingEntry $itk_interior.mrwe max_refl_width \
	    -balloonhelp "Partial spots wider in \u3c6 than this are not measured" \
	    -type real \
	    -precision 1 \
	    -minimum 0 \
	    -maximum 20 \
	    -width 7 \
	    -justify right
    }

    itk_component add profile_optimise_central_l {
   	label $itk_interior.pocl  -text "Optimise parameters for central profile "  -anchor w
    }

    itk_component add profile_optimise_standard_l {
   	label $itk_interior.posl  -text "Optimise parameters for standard profiles "  -anchor w
    }

    itk_component add optimise_box_size_l {
   	label $itk_interior.obsl  -text "Optimise overall box size "  -anchor w
    }

    itk_component add profile_optimise_central_check {
        SettingCheckbutton $itk_interior.pocc profile_optimise_central \
	    -text "" -command [code $this toggleProfileOptimise]
    }

    itk_component add profile_optimise_standard_check {
        SettingCheckbutton $itk_interior.posc profile_optimise_standard \
	    -text ""
    }

    itk_component add optimise_box_size_check {
        SettingCheckbutton $itk_interior.obsc optimise_box_size \
	    -text ""
    }

    itk_component add profile_l {
        gSection $itk_interior.profl  -text "Profiles "
    }
    
	itk_component add max_pixel_l {
    	label $itk_interior.mpl  -text "Max pixel value: "  -anchor w
    }

    itk_component add max_pixel_e {
        SettingEntry $itk_interior.mpe profile_overload_cutoff \
	    -type int \
	    -minimum "0" \
	    -maximum "4000000" \
	    -width 7 \
	    -justify right
    }
	
    itk_component add threshold_spot_inclusion_l {
    	label $itk_interior.tsil  -text "Threshold for spot inclusion (I/sigma): "  -anchor w
    }

    itk_component add threshold_spot_inclusion_e {
        SettingEntry $itk_interior.tsie threshold_spot_inclusion \
	    -type int \
	    -minimum "0" \
	    -width 7 \
	    -justify right
    }

    itk_component add profile_tolerance_l {
        label $itk_interior.ptl  -text "Tolerance: "  -anchor w
    }

    itk_component add profile_tolerance_min_l {
        label $itk_interior.ptminl  -text "Minimum (low resolution region): "  -anchor w
    }

    itk_component add profile_tolerance_min_e {
        SettingEntry $itk_interior.ptmine profile_tolerance_min \
	    -balloonhelp "Increasing this value will make the peak region of the\nmeasurement box smaller, decreasing it will make it larger.\nFor laboratory sources, 0.01 is usually a good value, for \nsynchrotrons 0.02; for very close spots or strong diffraction\n up to 0.04 may be necessary" \
	    -type real \
	    -precision 2 \
	    -minimum 0 \
	    -maximum 0.1 \
	    -width 7 \
	    -justify right
    }

    itk_component add profile_tolerance_max_l {
        label $itk_interior.ptmaxl  -text "Maximum (high resolution region): "  -anchor w
    }

    itk_component add profile_tolerance_max_e {
        SettingEntry $itk_interior.ptmaxe profile_tolerance_max \
	    -balloonhelp "Increasing this value will make the peak region of the\nmeasurement box smaller, decreasing it will make it larger.\nFor laboratory sources, 0.01 is usually a good value, for \nsynchrotrons 0.03; for very close spots or strong diffraction\n up to 0.05 may be necessary" \
	    -type real \
	    -precision 2 \
	    -minimum 0 \
	    -maximum 0.1 \
	    -width 7 \
	    -justify right
    }

    itk_component add profileav_l {
        gSection $itk_interior.proflavg -text "Profile averaging "
    }

    itk_component add profile_refl_count_av_thresh_l {
        label $itk_interior.prcatl  -text "Minimum number of spots:"  -anchor w
    }

    itk_component add profile_refl_count_av_thresh_e {
        SettingEntry $itk_interior.prcate profile_refl_count_av_thresh \
	    -balloonhelp "Profiles will be averaged if they are formed \nfrom fewer than this many spots" \
	    -type int \
	    -minimum 5 \
	    -width 7 \
	    -justify right
    }

    itk_component add profile_rmsbg_thresh_l {
        label $itk_interior.prtl  -text "Maximum RMS background variation:"  -anchor w
    }
#
    itk_component add outlexcl_l {
        gSection $itk_interior.outlexcl -text "Outlier exclusion "
    }

    itk_component add iceringwidth_l {
    	label $itk_interior.irwl  -text "Width of resolution shells for ice rings: "  -anchor w
    }

    itk_component add iceringwidth_e {
        SettingEntry $itk_interior.irwe ice_ring_width \
	    -type real \
	    -minimum 0.000 \
	    -precision 3 \
	    -width 7 \
	    -justify right
    }

    itk_component add fracstrgref_l {
    	label $itk_interior.fsrl  -text "Fraction of strongest reflections excluded: "  -anchor w
    }

    itk_component add fracstrgref_e {
        SettingEntry $itk_interior.fsre prcutval \
	    -type real \
	    -minimum 0.00 \
	    -precision 3 \
	    -width 7 \
	    -justify right
    }

    itk_component add exclicering_l {
   	label $itk_interior.xirl  -text "Exclude reflections lying near ice rings "  -anchor w
    }

    itk_component add exclicering_check {
        SettingCheckbutton $itk_interior.xirc excl_near_ice \
	    -text ""
    }
#
    itk_component add profile_rmsbg_thresh_e {
        SettingEntry $itk_interior.prte profile_rmsbg_thresh \
	    -balloonhelp "Profiles will be averaged if the RMS bacground error is greater than this" \
	    -type real \
	    -precision 1 \
	    -width 7 \
	    -justify right
    }

    itk_component add integration_l {
        gSection $itk_interior.integrationl  -text "Integration "
    }

    itk_component add sat_pixel_value_l {
        label $itk_interior.spvl  -text "Pixel saturation value"  -anchor w
    }


    itk_component add sat_pixel_value_e {
        SettingEntry $itk_interior.spve overload_cutoff \
	    -type int \
	    -minimum "0" \
	    -maximum "4000000" \
	    -width 7 \
	    -justify right
    }

    itk_component add rej_criteria_l {
        gSection $itk_interior.rejcritl  -text "Rejection Criteria "
    }

    itk_component add bgratio_l {
        label $itk_interior.bgrl  -text "BGRATIO: "  -anchor w
    }


    itk_component add bgratio_e {
        SettingEntry $itk_interior.bgre bgratio \
	    -type real \
	    -precision 1 \
	    -width 7 \
	    -justify right
    }


    itk_component add pkratio_l {
        label $itk_interior.pkrl  -text "PKRATIO: "  -anchor w
    }


    itk_component add pkratio_e {
        SettingEntry $itk_interior.pkre pkratio \
	    -type real \
	    -precision 1 \
	    -width 7 \
	    -justify right
    }

    itk_component add max_backgr_grad_l {
        label $itk_interior.mbgl  -text "Maximum background gradient: "  -anchor w
    }


    itk_component add max_backgr_grad_e {
        SettingEntry $itk_interior.mbge rejection_gradient_integration \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -justify right
    }

    itk_component add pickbox_l {
        gSection $itk_interior.pkbx -text "Pick box dimensions "
    }

    itk_component add pkbx_x_l {
        label $itk_interior.pkbx_l -text "No. pixels across: " -anchor w
    }

    itk_component add pkbx_x_e {
        SettingEntry $itk_interior.pkbx_e pickbox_size_x \
	    -type int \
	    -minimum 3 \
	    -maximum 21 \
	    -width 3 \
	    -justify right
    }

    itk_component add pkbx_y_l {
        label $itk_interior.pkby_l  -text "No. pixels down: "  -anchor w
    }

    itk_component add pkbx_y_e {
        SettingEntry $itk_interior.pkby_e pickbox_size_y \
	    -type int \
	    -minimum 3 \
	    -maximum 21 \
	    -width 3 \
	    -justify right
    }

    itk_component add pntls_scala_l {
        gSection $itk_interior.pntlscalal  -text "Pointless & Aimless/Scala switches "
    }

    itk_component add use_scala_l {
   	label $itk_interior.usescala -text "Use Scala NOT Aimless in QuickScale option "  -anchor w
    }

    itk_component add mosflm_symmetry_l {
   	label $itk_interior.usemossymm -text "Use iMosflm symmetry in QuickScale option "  -anchor w
    }

    itk_component add anomalous_data_l {
   	label $itk_interior.trtanomdat -text "Treat anomalous data in QuickScale option "  -anchor w
    }

#    itk_component add use_scala_check {
#        SettingCheckbutton $itk_interior.usescalac use_scala \
#	    -text ""
#    }

    itk_component add use_scala_check {
	checkbutton $itk_interior.usescalac -variable [scope use_scala]
    }

    itk_component add mosflm_symmetry_check {
        SettingCheckbutton $itk_interior.mossymmc use_mosflm_symmetry \
	    -text ""
    }

    itk_component add anomalous_data_check {
        SettingCheckbutton $itk_interior.anomdatac treat_anomalous_data \
	    -text ""
    }

    # layout ####################################

    set indent 20
    set margin 7

    grid x $itk_component(raster_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(nxs_l) - $itk_component(nxs_e) x x -sticky w
    grid x x $itk_component(nys_l) - $itk_component(nys_e) x x -sticky w
    grid x x $itk_component(nc_l) - $itk_component(nc_e) x x -sticky w
    grid x x $itk_component(nrx_l) - $itk_component(nrx_e) x x -sticky w
    grid x x $itk_component(nry_l) - $itk_component(nry_e) x x -sticky w
    grid x x $itk_component(profile_optimise_central_l) - $itk_component(profile_optimise_central_check) x x -sticky w
    grid x x $itk_component(profile_optimise_standard_l) - $itk_component(profile_optimise_standard_check) x x -sticky w
    grid x x $itk_component(optimise_box_size_l) - $itk_component(optimise_box_size_check) x x -sticky w

    grid x $itk_component(profile_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(max_pixel_l) - $itk_component(max_pixel_e) x x -sticky w
    grid x x $itk_component(threshold_spot_inclusion_l) - $itk_component(threshold_spot_inclusion_e) x x -sticky w
    grid x x $itk_component(profile_tolerance_l) $itk_component(profile_tolerance_min_l) $itk_component(profile_tolerance_min_e) x x -sticky w
    grid x x x $itk_component(profile_tolerance_max_l) $itk_component(profile_tolerance_max_e) x x -sticky w
    grid x $itk_component(profileav_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(profile_refl_count_av_thresh_l) - $itk_component(profile_refl_count_av_thresh_e) x x -sticky w
    grid x x $itk_component(profile_rmsbg_thresh_l) - $itk_component(profile_rmsbg_thresh_e) x x -sticky w

    grid x $itk_component(outlexcl_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(iceringwidth_l) - $itk_component(iceringwidth_e) x x -sticky w
    grid x x $itk_component(fracstrgref_l) - $itk_component(fracstrgref_e) x x -sticky w
    grid x x $itk_component(exclicering_l) - $itk_component(exclicering_check) x x -sticky w

    grid x $itk_component(integration_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(nullpix_l) - $itk_component(nullpix_e) x x -sticky w
    grid x x $itk_component(max_refl_width_l) - $itk_component(max_refl_width_e) x x -sticky w
    grid x x $itk_component(sat_pixel_value_l) - $itk_component(sat_pixel_value_e) x x -sticky w

    grid x $itk_component(rej_criteria_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(bgratio_l) - $itk_component(bgratio_e) x x -sticky w
    grid x x $itk_component(pkratio_l) - $itk_component(pkratio_e) x x -sticky w
    grid x x $itk_component(max_backgr_grad_l) - $itk_component(max_backgr_grad_e) x x -sticky w

    grid x $itk_component(pickbox_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(pkbx_x_l) - $itk_component(pkbx_x_e) x x -sticky w
    grid x x $itk_component(pkbx_y_l) - $itk_component(pkbx_y_e) x x -sticky w

    grid x $itk_component(pntls_scala_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(use_scala_l) - $itk_component(use_scala_check) x x -sticky w
    grid x x $itk_component(mosflm_symmetry_l) - $itk_component(mosflm_symmetry_check) x x -sticky w
    grid x x $itk_component(anomalous_data_l) - $itk_component(anomalous_data_check) x x -sticky w

    grid columnconfigure $itk_interior 3 -weight 1
    grid columnconfigure $itk_interior {0 5} -minsize $margin 
    grid columnconfigure $itk_interior {1} -minsize $indent
    grid rowconfigure $itk_interior {99} -minsize 7 -weight 1

    eval itk_initialize $args

}


########################################################################
# Usual config options                                                 #
########################################################################

usual Advancedintegrationsettings { 
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}

body Advancedintegrationsettings::toggleProfileOptimise {a_value} {
    if {$a_value == 0} {
	if {[$itk_component(profile_optimise_standard_check) getValue]} {
	    $itk_component(profile_optimise_standard_check) invoke
	}
	$itk_component(profile_optimise_standard_check) configure -state disabled
    } else {
	$itk_component(profile_optimise_standard_check) configure -state normal
    }
}

body Advancedintegrationsettings::getUseScalaBool { } {
    return $use_scala
}

body Advancedintegrationsettings::setUseScalaBool { a_value } {
    set use_scala $a_value
}
