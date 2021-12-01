# $Id: refinementmosaicitysettings.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
# package name
package provide refinementmosaicitysettings 1.0

# Class
class Refinementmosaicitysettings {
    inherit itk::Widget Settings

    # variables
    ###########

    private variable cuttoff "2.50"
    private variable max_cell_edge_option "0"
    private variable max_cell_edge ""
    private variable exclude_ice "0"
    private variable exclude_auto "0"
    private variable exclude_specific "0"
    private variable target_cell_check "0"
    private variable target_a ""
    private variable target_b ""
    private variable target_c ""
    private variable target_alpha ""
    private variable target_beta ""
    private variable target_gamma ""
    private variable target_symmetry ""
    private variable fix_distance_indexing "0"
    private variable prerefine "0"

    private variable old_algorithm "0"
    private variable old_max_cell_edge_option "0"
    private variable old_max_cell_edge ""
    private variable old_exclude_ice "0"
    private variable old_exclude_auto "0"
    private variable old_exclude_specific "0"
    private variable old_target_cell_check "0"
    private variable old_target_a ""
    private variable old_target_b ""
    private variable old_target_c ""
    private variable old_target_alpha ""
    private variable old_target_beta ""
    private variable old_target_gamma ""
    private variable old_target_symmetry ""
    private variable old_fix_distance_indexing "0"
    private variable old_prerefine "0"


    # methods
    #########

    # widget callbacks
    public method toggleCellEdge
    public method toggleCellTarget

    # accessor methods for old value
    public method setOld
    public method setVar

    # Refresh with session settings
    public method refresh

    constructor { args } { }

}

# Bodies

body Indexsettings::constructor { args } {

    itk_component add alg_label {
        gSection $itk_interior.al  -text "Indexing algorithm"
    }

    itk_component add alg_dps_r {
        Radio $itk_interior.adr -variable [scope algorithm]  -value "dps"  -text "DPS (recommended)"
    }

    itk_component add alg_refix_r {
        Radio $itk_interior.arr -variable [scope algorithm]  -value "refix"  -text "Refix" -state "disabled"
    }

    itk_component add cell_edge_l {
        gSection $itk_interior.cel  -text "Maximum expected cell edge: "
    }

    itk_component add cell_edge_auto_r {
        Radio $itk_interior.cear -variable [scope max_cell_edge_option]  -value 0  -text "Calculate automatically"
    }

    itk_component add cell_edge_manual_r {
        Radio $itk_interior.cemr  -variable [scope max_cell_edge_option]  -value 1  -text "Specify manually (\uc5): "  -command [code $this toggleCellEdge]
    }

    itk_component add cell_edge_e {
        gEntry $itk_interior.cee  -type "int"  -textvariable [scope max_cell_edge]  -width 3  -minimum "0"  -maximum "999"  -justify right  -state disabled -command [code $this updateValue max_cell_edge]
    }

    itk_component add target_l {
        gSection $itk_interior.tl  -text "Target solution"
    }

    itk_component add target_cell_cb {
        gcheckbutton $itk_interior.tcc  -variable [scope target_cell_check]  -text "Provide target cell: "  -command [code $this toggleCellTarget] ;#-state "disabled"
    }

    itk_component add target_a_l {
        label $itk_interior.tal  -text "a: "
    }

    itk_component add target_a_e {
        gEntry $itk_interior.tae  -type "real"  -precision "2"  -minimum "0.00"  -maximum "999.99"  -textvariable [scope target_a] -width 6  -justify right  -state disabled -command [code $this updateValue target_a]
    }

    itk_component add target_b_l {
            label $itk_interior.tbl  -text "b: "
    }

    itk_component add target_b_e {
        gEntry $itk_interior.tbe  -type "real"  -precision "2"  -minimum "0.00"  -maximum "999.99"  -textvariable [scope target_b] -width 6  -justify right  -state disabled -command [code $this updateValue target_b]
        }

    itk_component add target_c_l {
        label $itk_interior.tcl  -text "c: "
    }

    itk_component add target_c_e {
        gEntry $itk_interior.tce  -type "real"  -precision "2"  -minimum "0.00"  -maximum "999.99"  -textvariable [scope target_c] -width 6  -justify right  -state disabled -command [code $this updateValue target_c]
    }

    itk_component add target_alpha_l {
        label $itk_interior.talphal  -text "\u03b1: "
    }

    itk_component add target_alpha_e {
        gEntry $itk_interior.talphae  -type "real"  -precision "2"  -minimum "0.00"  -maximum "179.99"  -textvariable [scope target_alpha]  -width 6  -justify right  -state disabled -command [code $this updateValue target_alpha]
    }

    itk_component add target_beta_l {
        label $itk_interior.tbetal  -text "\u03b2: "
    }

    itk_component add target_beta_e {
        gEntry $itk_interior.tbetae  -type "real"  -precision "2" -minimum "0.00"  -maximum "179.99"  -textvariable [scope target_beta]  -width 6  -justify right  -state disabled -command [code $this updateValue target_beta]
    }

    itk_component add target_gamma_l {
        label $itk_interior.tgammal  -text "\u03b3: "
    }

    itk_component add target_gamma_e {
        gEntry $itk_interior.tgammae  -type "real"  -precision "2"  -minimum "0.00"  -maximum "179.99"  -textvariable [scope target_gamma]  -width 6  -justify right  -state disabled -command [code $this updateValue target_gamma]
    }

    itk_component add exclusions_l {
        gSection $itk_interior.el  -text "Exclusions"
    }

    itk_component add ex_ice_check {
        gcheckbutton $itk_interior.eic  -variable [scope exclude_ice]  -text "Ice rings" -command [code $this updateValue exclude_ice]
    }

    itk_component add ex_auto_check {
        gcheckbutton $itk_interior.eac  -variable [scope exclude_auto]  -text "Automatically detected rings" -command [code $this updateValue exclude_auto]
    }

    itk_component add ex_spec_check {
        gcheckbutton $itk_interior.esc  -variable [scope exclude_specific]  -text "Specified rings:" -command [code $this updateValue exclude_specific]
    }

    set indent 20

    grid $itk_component(alg_label) - - - - - - - -sticky we
    grid x $itk_component(alg_dps_r) - - - - x -sticky w
    grid x $itk_component(alg_refix_r) - - - - x -sticky w

    grid $itk_component(cell_edge_l) - - - - - - - -sticky we
    grid x $itk_component(cell_edge_auto_r) - - - x -sticky w
    grid x $itk_component(cell_edge_manual_r) - - - $itk_component(cell_edge_e) -sticky w

    grid $itk_component(exclusions_l) - - - - - - - -sticky we
    grid x $itk_component(ex_ice_check) - - - - x -sticky w
    grid x $itk_component(ex_auto_check) - - - - x -sticky w
    #grid x $itk_component(ex_spec_check) - - - - x -sticky w

    grid $itk_component(target_l) - - - - - - - -sticky we
    grid x $itk_component(target_cell_cb) - - - - - -sticky w
    grid x x $itk_component(target_a_l) $itk_component(target_a_e) $itk_component(target_alpha_l) $itk_component(target_alpha_e) -sticky w
    grid x x $itk_component(target_b_l) $itk_component(target_b_e) $itk_component(target_beta_l) $itk_component(target_beta_e) -sticky w
    grid x x $itk_component(target_c_l) $itk_component(target_c_e) $itk_component(target_gamma_l) $itk_component(target_gamma_e) -sticky w

    grid columnconfigure $itk_interior 0 -minsize $indent
    grid columnconfigure $itk_interior 1 -minsize $indent
    grid columnconfigure $itk_interior 7 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1

}

########################################################################
# Widget callbacks                                                     #
########################################################################

body Indexsettings::toggleCellEdge { value } {
    if {$value == 0} {
	$itk_component(cell_edge_e) configure -state disabled
    } else {
      $itk_component(cell_edge_e) configure -state normal
    }
    updateValue max_cell_edge_option
}

body Indexsettings::toggleCellTarget { value } {
    if {$value == 0} {
	$itk_component(target_a_e) configure -state disabled
	$itk_component(target_b_e) configure -state disabled
	$itk_component(target_c_e) configure -state disabled
	$itk_component(target_alpha_e) configure -state disabled
	$itk_component(target_beta_e) configure -state disabled
	$itk_component(target_gamma_e) configure -state disabled
    } else {
	$itk_component(target_a_e) configure -state normal
	$itk_component(target_b_e) configure -state normal
	$itk_component(target_c_e) configure -state normal
	$itk_component(target_alpha_e) configure -state normal
	$itk_component(target_beta_e) configure -state normal
	$itk_component(target_gamma_e) configure -state normal
    }
    updateValue target_cell_check
}

########################################################################
# Accessor methods for old value                                       #
########################################################################

body Indexsettings::setOld { var value} {
    set old_$var $value
}

body Indexsettings::setVar { var value} {
    set $var $value
}

########################################################################
# Refresh with session settings                                        #
########################################################################

body Indexsettings::refresh { a_list } {
    foreach { old_algorithm old_max_cell_edge_option old_max_cell_edge old_exclude_ice old_exclude_auto old_exclude_specific old_target_cell_check old_target_a old_target_b old_target_c old_target_alpha old_target_beta old_target_gamma old_target_symmetry old_fix_distance_indexing old_prerefine } $a_list  { }

    foreach { algorithm max_cell_edge_option max_cell_edge exclude_ice exclude_auto exclude_specific target_cell_check target_a target_b target_c target_alpha target_beta target_gamma target_symmetry fix_distance_indexing prerefine } $a_list { }

}

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