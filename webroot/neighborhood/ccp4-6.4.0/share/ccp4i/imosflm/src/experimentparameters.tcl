# $Id: experimentparameters.tcl,v 1.9 2010/01/21 16:02:24 rmk65 Exp $
# package name
package provide experimentparameters 1.0

image create photo ::img::beam_div_x16x16 -data ""

image create photo ::img::beam_div_y16x16 -data ""

image create photo ::img::two_theta16x16 -data ""

image create photo ::img::lambda16x16 -data ""

image create photo ::img::gain16x16 -data ""

image create photo ::img::16x16 -data ""

# Class
class Experimentparameters {
    inherit itk::Widget Settings2

    # variables
    ###########

    # methods
    #########

    public method promptBeamSpecification    

    constructor { args } { } 
}

# Bodies

body Experimentparameters::constructor { args } {

    itk_component add beam_heading_l {
        gSection $itk_interior.beam_heading -text "Beam position"
    }
    
    itk_component add beam_pos_l {
	label $itk_interior.beam_pos_l -text "Beam position: "
    } 

    itk_component add beam_x_label {
        label $itk_interior.bxl  -text "X (mm) :"
    }

    itk_component add beam_x_entry {
        SettingEntry $itk_interior.bxe beam_x \
	    -image ::img::beam_x16x16 \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add beam_y_label {
        label $itk_interior.byl  -text "Y (mm): "
    }

    itk_component add beam_y_entry {
        SettingEntry $itk_interior.bye beam_y \
	    -image ::img::beam_y16x16 \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right
    }

    itk_component add distance_heading {
        gSection $itk_interior.dh  -text "Distance"
        }

    itk_component add distance_label {
        label $itk_interior.dl  -text "Crystal to detector distance (mm): "
    }

    itk_component add distance_entry {
        SettingEntry $itk_interior.de distance \
	    -image ::img::distance16x16 \
	    -type real \
	    -precision 2 \
	    -minimum "0" \
	    -width 6 \
	    -justify right
    }

    itk_component add divergence_heading {
        gSection $itk_interior.divh  -text "Beam divergence: "
        }

    itk_component add divergence_label {
        label $itk_interior.divl  -text "Beam divergence: "
        }

    itk_component add divergence_x_label {
        label $itk_interior.divxl  -text "X (\ub0): "
    }

    itk_component add divergence_x_entry {
        SettingEntry $itk_interior.divxe divergence_x \
	    -type real \
	    -precision 3 \
	    -minimum "0" \
	    -maximum "1.000" \
	    -width 6 \
	    -justify right
    }

    itk_component add divergence_y_label {
        label $itk_interior.divyl  -text "Y (\ub0): "
    }

    itk_component add divergence_y_entry {
        SettingEntry $itk_interior.divye divergence_y \
	    -type real \
	    -precision 3 \
	    -minimum "0" \
	    -maximum "1.000" \
	    -width 6 \
	    -justify right
    }

    itk_component add wavelength_heading {
        gSection $itk_interior.wh  -text "Wavelength"
        }

    itk_component add wavelength_label {
        label $itk_interior.wl  -text "Wavelength (\u3bb, \uc5): "
    }

    itk_component add wavelength_entry {
        SettingEntry $itk_interior.we wavelength \
	    -type real \
	    -precision 6 \
	    -minimum 0 \
	    -width 6 \
	    -justify right
    }

    itk_component add dispersion_label {
        label $itk_interior.disp_l  -text "Wavelength dispersion (\uc5): "
    }

    itk_component add dispersion_entry {
        SettingEntry $itk_interior.dispe dispersion \
	    -type real \
	    -precision 4 \
	    -minimum 0 \
	    -maximum 0.1 \
	    -width 6 \
	    -justify right
    }

    itk_component add polarization_label {
        label $itk_interior.polar_l  -text "Beam polarization: "
    }

    itk_component add polarization_entry {
        SettingEntry $itk_interior.polare polarization \
	    -type real \
	    -precision 2 \
	    -minimum 0 \
	    -maximum 1 \
	    -width 6 \
	    -justify right
    }

    itk_component add two_theta_heading {
        gSection $itk_interior.tth  -text "Detector angle"
        }

    itk_component add two_theta_label {
        label $itk_interior.ttl  -text "Detector angle (2\u3b8, \ub0): "
    }

    itk_component add two_theta_entry {
        SettingEntry $itk_interior.tte two_theta \
	    -type real \
	    -precision 2 \
	    -minimum "-180" \
	    -maximum "180" \
	    -width 6 \
	    -justify right
    }
    itk_component add reversePhi {
	SettingCheckbutton $itk_interior.rphi reverse_phi \
	    -text "Reverse direction of spindle rotation" 
    }


    # Layout #########################################

    set indent 20
    set margin 7

    #grid $itk_component(beam_heading_l) - - - - -sticky we
    grid x $itk_component(beam_pos_l) $itk_component(beam_x_label) $itk_component(beam_x_entry) x -sticky nw
    grid x x $itk_component(beam_y_label) $itk_component(beam_y_entry)  x -sticky nw

    # grid $itk_component(distance_heading) - - - - -sticky nwe
    grid x $itk_component(distance_label) -  $itk_component(distance_entry) x -sticky nw
    # grid $itk_component(divergence_heading) - - - - -sticky nwe
    grid x $itk_component(divergence_label) $itk_component(divergence_x_label) $itk_component(divergence_x_entry) x -sticky nw
    grid x x $itk_component(divergence_y_label) $itk_component(divergence_y_entry) x -sticky nw
    # grid $itk_component(wavelength_heading) - - - - -sticky nwe
    grid x $itk_component(wavelength_label) - $itk_component(wavelength_entry) x -sticky nw
    grid x $itk_component(dispersion_label) - $itk_component(dispersion_entry) x -sticky nw
    grid x $itk_component(polarization_label) - $itk_component(polarization_entry) x -sticky nw
    # grid $itk_component(two_theta_heading) - - - - -sticky nwe
    grid x $itk_component(two_theta_label) - $itk_component(two_theta_entry) x -sticky nw

    grid  x $itk_component(reversePhi) -columnspan 4 -sticky we 

    grid columnconfigure $itk_interior { 0 4 } -minsize $margin
    grid columnconfigure $itk_interior { 1 2 3 } -weight 1
    grid rowconfigure $itk_interior { 1 2 4 5 7 }  -weight 1
    grid rowconfigure $itk_interior 99 -minsize $margin -weight 1

}


usual Experimentparameters {
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}
