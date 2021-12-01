# $Id: indexsettings.tcl,v 1.10 2010/12/08 12:31:48 ccb Exp $
# package name
package provide indexsettings 1.0

# Class
class Indexsettings {
    inherit itk::Widget Settings2

    # variables

    # methods

    # widget callbacks

    public method resetDefaultIndexingThreshold
    constructor { args } { }

    private variable autoindexing_relay_bool "1"
    public method getAutoindexingRelayBool
    public method setAutoindexingRelayBool


}

# Bodies

body Indexsettings::constructor { args } {
	
    itk_component add relay_check {
	checkbutton $itk_interior.relaycheck -text "Automatically index after spot finding" -variable [scope autoindexing_relay_bool]
    }

    itk_component add fix_distance_icon {
	label $itk_interior.fdi \
	    -image ::img::fix_distance16x16 \
    }

    itk_component add fix_distance_check {
        SettingCheckbutton $itk_interior.fd fix_distance_indexing \
	    -text "Fix distance"
    }

    itk_component add fix_cell_icon {
	label $itk_interior.fci \
	    -image ::img::fix_cell16x16
    }

    itk_component add fix_cell_check {
        SettingCheckbutton $itk_interior.fc fix_cell_indexing \
	    -text "Fix cell"
    }

    itk_component add ex_ice_icon {
	label $itk_interior.eii \
	    -image ::img::exclude_ice16x16
    }

    itk_component add ex_ice_check {
        SettingCheckbutton $itk_interior.eic exclude_ice \
	    -text "Exclude ice rings"
    }

    itk_component add ex_auto_icon {
	label $itk_interior.eai \
	    -image ::img::exclude_auto16x16
    }

    itk_component add ex_auto_check {
        SettingCheckbutton $itk_interior.eac exclude_auto \
	    -text "Exclude any spot rings"
    }

    itk_component add cell_edge_l {
        label $itk_interior.cel \
	    -text "Maximum expected cell edge: " \
	    -anchor w
    }

    itk_component add cell_edge_e {
        SettingEntry $itk_interior.cee max_cell_edge \
	    -image ::img::max_cell_edge16x16 \
	    -type "int" \
	    -width 6 \
	    -minimum "0" \
	    -maximum "999" \
	    -justify right
    }

    itk_component add sigma_cutoff_l {
        label $itk_interior.scl \
	    -text "Refinement \u03c3 cutoff:" \
	    -anchor w
    }

    itk_component add sigma_cutoff_e {
        SettingEntry $itk_interior.sce sigma_cutoff \
	    -image ::img::sigma16x16 \
	    -type "real" \
	    -precision "2" \
	    -minimum "0.0" \
	    -width 6 \
	    -justify right \
	    -state normal 
    }


    itk_component add i_sig_i_l {
        label $itk_interior.isil \
	    -text "I/sig(I) threshold:" \
	    -anchor w
    }

    itk_component add i_sig_i_e {
        SettingEntry $itk_interior.isie i_sig_i \
	    -image  ::img::res_cutoff16x16 \
	    -type "real" \
	    -precision "2" \
	    -minimum "0.00" \
	    -maximum "100.00" \
	    -width 6 \
	    -justify right \
	    -state normal \
		-editcommand [code .c uncheckAutothreshCheckbutton]
    }

    itk_component add auto_thresh_check {
        SettingCheckbutton $itk_interior.atc auto_thresh_indexing \
	    -text "Automatically set threshold" \
		-command [code $this resetDefaultIndexingThreshold]
    }

#Experiment with adding a shortcut to successively try reindexing while raising/lowering the i/sig(I) threshold
#    itk_component add i_sig_i_deltal {
#        label $itk_interior.isidl \
#	    -text "I/sig(I) %change in re-try:" \
#	    -anchor w
#    }
#
#    itk_component add i_sig_i_delta {
#	    SettingCombo $itk_interior.isid i_sig_i_delta \
#	    -width 3 \
#	    -items {75 50 25 10} \
#	    -editable 0 -highlightcolor black
#    } {
#	    usual
#	    ignore -textbackground -foreground
#    }
    
    itk_component add beamsearch_l {
        gSection $itk_interior.beamsearchlabel  -text "Beam-centre search"
    }

    itk_component add beamsearch_stepsize_l {
        label $itk_interior.bsssl \
	    -text "Step size (mm):" \
	    -anchor w
    }

    itk_component add beamsearch_stepsize_e {
        SettingEntry $itk_interior.bssse beamsearch_stepsize \
	    -type "real" \
	    -precision "2" \
	    -minimum "0.05" \
	    -maximum "10.00" \
	    -width 6 \
	    -justify right \
	    -state normal 
    }

    itk_component add beamsearch_stepnum_x_l {
        label $itk_interior.bssnxl \
	    -text "Max number of steps from centre in x:" \
	    -anchor w
    }

    itk_component add beamsearch_stepnum_x_e {
        SettingEntry $itk_interior.bssnxe beamsearch_stepnumx \
	    -type "int" \
	    -minimum "1" \
	    -maximum "5" \
	    -width 6 \
	    -justify right \
	    -state normal 
    }

    itk_component add beamsearch_stepnum_y_l {
        label $itk_interior.bssnyl \
	    -text "Max number of steps from centre in y:" \
	    -anchor w
    }

    itk_component add beamsearch_stepnum_y_e {
        SettingEntry $itk_interior.bssnye beamsearch_stepnumy \
	    -type "int" \
	    -minimum "1" \
	    -maximum "5" \
	    -width 6 \
	    -justify right \
	    -state normal 
    }

    set margin 7
    set pad 2

    grid x $itk_component(relay_check)   - - - - - -sticky w 
    grid x $itk_component(fix_distance_icon) $itk_component(fix_distance_check) -  x -sticky w -padx $pad -pady [list $margin $pad]
    grid x $itk_component(fix_cell_icon) $itk_component(fix_cell_check) - x -sticky w -padx $pad -pady [list $pad $margin]

#    grid x $itk_component(ex_ice_icon) $itk_component(ex_ice_check) - x -sticky w -padx $pad -pady $pad
    grid x $itk_component(ex_auto_icon) $itk_component(ex_auto_check) - x -sticky w -padx $pad -pady [list $pad $margin]

    grid x $itk_component(cell_edge_l) - $itk_component(cell_edge_e) x -sticky we -padx $pad -pady $pad
    grid x $itk_component(sigma_cutoff_l) - $itk_component(sigma_cutoff_e) x -sticky we -padx $pad -pady [list $pad $margin]
    grid x $itk_component(i_sig_i_l) - $itk_component(i_sig_i_e) x -sticky we -padx $pad -pady [list $pad $margin]
    grid $itk_component(fix_cell_icon) $itk_component(auto_thresh_check) - - x -sticky w -padx $pad -pady [list $pad $margin]
#    grid x $itk_component(i_sig_i_deltal) - $itk_component(i_sig_i_delta) x -sticky we -padx $pad -pady [list $pad $margin]
    grid $itk_component(beamsearch_l) - - -   -sticky we -pady {5 0}
    grid x $itk_component(beamsearch_stepsize_l) - $itk_component(beamsearch_stepsize_e) x -sticky we -padx $pad -pady [list $pad $margin]
    grid x $itk_component(beamsearch_stepnum_x_l) - $itk_component(beamsearch_stepnum_x_e)   x -sticky we -padx $pad -pady [list $pad $margin]
    grid x $itk_component(beamsearch_stepnum_y_l) - $itk_component(beamsearch_stepnum_y_e)   x -sticky we -padx $pad -pady [list $pad $margin]


    grid columnconfigure $itk_interior { 0 4 } -minsize $margin
    grid columnconfigure $itk_interior 2 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1

}

body Indexsettings::getAutoindexingRelayBool { } {
	return $autoindexing_relay_bool
}

body Indexsettings::setAutoindexingRelayBool {a_value} {
	set autoindexing_relay_bool $a_value
}

########################################################################
# Widget callbacks                                                     #
########################################################################


########################################################################
# Usual configuration options                                          #
########################################################################

usual Indexsettings {
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}


body Indexsettings::resetDefaultIndexingThreshold {a_value} {
	if {$a_value == "0"} {
		$::session updateSetting "i_sig_i" "20" 1 1 "User" 0
	} else {
		$::session updateSetting "i_sig_i" [$::session getParameterValue "auto_thresh_value"] 1 1 "User" 0
	}
} 

