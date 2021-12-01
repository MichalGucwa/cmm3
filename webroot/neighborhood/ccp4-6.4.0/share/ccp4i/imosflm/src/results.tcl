# $Id: results.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide results 1.0

class Results {
    inherit itk::Widget Settings2
 
    # Member variables
    private variable cell ""
    private variable cell_a ""
    private variable cell_b ""
    private variable cell_c ""
    private variable cell_alpha ""
    private variable cell_beta ""
    private variable cell_gamma ""
    private variable spacegroup ""

    # Methods
    
    private method updateCell
    private method updateSpacegroup
    public method refreshCell
    public method refreshSpacegroup

    constructor { args } {

	set spacegroup [namespace current]::[Spacegroup \#auto "blank" "spacegroup"]
	set cell [namespace current]::[Cell \#auto "blank" "cell"]
	
	itk_component add cell_l {
	    label $itk_interior.cl \
		-text "Cell:"
	}
	
	itk_component add cell_a_l {
	    label $itk_interior.cal \
		-text "a:"
	}

	itk_component add cell_a_se {
	    gEntry $itk_interior.case \
		-textvariable [scope cell_a] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "9999.99" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add cell_b_l {
	    label $itk_interior.cbl \
		-text "b:"
	}

	itk_component add cell_b_se {
	    gEntry $itk_interior.cbse \
		-textvariable [scope cell_b] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "9999.99" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add cell_c_l {
	    label $itk_interior.ccl \
		-text "c:"
	}

	itk_component add cell_c_se {
	    gEntry $itk_interior.ccse \
		-textvariable [scope cell_c] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "9999.99" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add cell_alpha_l {
	    label $itk_interior.calphal \
		-text "\u03b1:"
	}

	itk_component add cell_alpha_se {
	    gEntry $itk_interior.calphase \
		-textvariable [scope cell_alpha] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "180.00" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add cell_beta_l {
	    label $itk_interior.cbetal \
		-text "\u03b2:"
	}

	itk_component add cell_beta_se {
	    gEntry $itk_interior.cbetase \
		-textvariable [scope cell_beta] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "180.00" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add cell_gamma_l {
	    label $itk_interior.cgammal \
		-text "\u03b3:"
	}

	itk_component add cell_gamma_se {
	    gEntry $itk_interior.cgammase \
		-textvariable [scope cell_gamma] \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "180.00" \
		-width 7 \
		-justify right \
		-command [code $this updateCell]
	}
	
	itk_component add symmetry_l {
	    label $itk_interior.sl \
		-text "Symmetry:"
	}

	itk_component add symmetry_sc {
	    Combo $itk_interior.ssc \
		-width 6 \
		-items {} \
		-editable 0 \
		-highlightcolor black \
		-command [code $this updateSpacegroup]
	}

	set spacegroups {}
	foreach i_lattice [array names ::spacegroup] {
	    set spacegroups [concat $spacegroups $::spacegroup($i_lattice)]
	}
	$itk_component(symmetry_sc) configure \
	    -items $spacegroups

	itk_component add mosaicity_l {
	    label $itk_interior.mosaicity_l \
		-text "Mosaicity:"
	}

	itk_component add mosaicity_se {
	    SettingEntry $itk_interior.mse mosaicity \
		-type "real" \
		-precision "2"  \
		-minimum "0.00" \
		-maximum "9999.99" \
		-width 7 \
		-justify right
	}		

	grid x $itk_component(cell_l) $itk_component(cell_a_l) $itk_component(cell_a_se) $itk_component(cell_b_l) $itk_component(cell_b_se) $itk_component(cell_c_l) $itk_component(cell_c_se) -sticky w
	grid x x $itk_component(cell_alpha_l) $itk_component(cell_alpha_se) $itk_component(cell_beta_l) $itk_component(cell_beta_se) $itk_component(cell_gamma_l) $itk_component(cell_gamma_se) -sticky w
	grid x $itk_component(symmetry_l) - $itk_component(symmetry_sc) -sticky we
	grid x $itk_component(mosaicity_l) - $itk_component(mosaicity_se) -sticky we

	grid columnconfigure $itk_interior { 0 99 } -minsize 7
	grid columnconfigure $itk_interior { 1 2 3 4 5 6 7 } -weight 1
	grid rowconfigure $itk_interior 99 -weight 1 
	
	eval itk_initialize $args
	
    }
    
}

body Results::updateCell { } {
    $cell setCell $cell_a $cell_b $cell_c $cell_alpha $cell_beta $cell_gamma
    if {[$cell reportCell] != "Unknown"} {
	$::session updateCell "User" $cell 1 0
    }
}


body Results::refreshCell { a_cell } {
    foreach { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } [$a_cell listCell] break
}


body Results::updateSpacegroup { a_spacegroup_value } {
    $spacegroup setSpacegroup $a_spacegroup_value
    $::session updateSpacegroup "User" $spacegroup 1 0
}

body Results::refreshSpacegroup { a_spacegroup } {
    $spacegroup setSpacegroup [$a_spacegroup reportSpacegroup]
}



########################################################################
# Usual configuration options                                          #
########################################################################

usual Results {
#    keep -background
#    keep -foreground
#    keep -selectbackground
#    keep -selectforeground
#    keep -textbackground
#    keep -font
#    keep -entryfont
}
