# $Id: imagedata.tcl,v 1.8 2010/01/21 16:02:24 rmk65 Exp $
package provide imagedata 0.1

class Imagedata {
    inherit itk::Widget

    public variable phi_start ""
    public variable phi_end ""
    public variable beam_x ""
    public variable beam_y ""
    public variable wavelength ""
    public variable two_theta ""
    public variable gain ""
    public variable pixel_size ""
    public variable distance ""
    
    public variable rotation ""
    public variable invertion ""
    public variable contrast_low ""
    public variable contrast_high ""

    public method update { a_dom }
    public method clear {}
    public method getPixelSize
    public method getPhiCentre

    constructor { args } {

	itk_option add hull.borderwidth

	itk_component add beam_x_r {
	    gRecord $itk_interior.bxr \
		-relief sunken \
		-text "Beam x (mm):" \
		-entrywidth 6 \
		-textvariable [scope beam_x]
	}

	itk_component add beam_y_r {
	    gRecord $itk_interior.byr \
		-relief sunken \
		-text "Beam y (mm):" \
		-entrywidth 6 \
		-textvariable [scope beam_y]
	}

	itk_component add phi_start_r {
	    gRecord $itk_interior.psr \
		-relief sunken \
		-text "\u3c6 start (\ub0):" \
		-entrywidth 9 \
		-textvariable [scope phi_start]
	}

	itk_component add phi_end_r {
	    gRecord $itk_interior.per \
		-relief sunken \
		-text "\u3c6 end (\ub0):" \
		-entrywidth 9 \
		-textvariable [scope phi_end]
	}

	itk_component add wavelength_r {
	    gRecord $itk_interior.wr \
		-relief sunken \
		-text "\u3bb (\uc5):" \
		-entrywidth 7 \
		-textvariable [scope wavelength]
	}

	itk_component add gain_r {
	    gRecord $itk_interior.gr \
		-relief sunken \
		-text "Gain:" \
		-entrywidth 6 \
		-textvariable [scope gain]
	}

	itk_component add two_theta_r {
	    gRecord $itk_interior.ttr \
		-relief sunken \
		-text "2\u3b8 (\ub0):" \
		-entrywidth 7 \
		-textvariable [scope two_theta]
	}

	itk_component add pixel_size_r {
	    gRecord $itk_interior.pxr \
		-relief sunken \
		-text "Pixel size (mm):" \
		-entrywidth 6 \
		-textvariable [scope pixel_size]
	}

	itk_component add distance_r {
	    gRecord $itk_interior.dr \
		-relief sunken \
		-text "Distance (mm):" \
		-entrywidth 7 \
		-textvariable [scope distance]
	}

	grid $itk_component(beam_x_r) $itk_component(phi_start_r) $itk_component(wavelength_r) \
	    -sticky we -padx 1 -pady 1 
	grid $itk_component(beam_y_r) $itk_component(phi_end_r) $itk_component(pixel_size_r) \
	    -sticky we -padx 1 -pady 1 
	grid $itk_component(distance_r) $itk_component(two_theta_r) $itk_component(gain_r) x \
	    -sticky we -padx 1 -pady 1
	grid columnconfig $itk_interior 0 -weight 1
	grid columnconfig $itk_interior 1 -weight 1
	grid columnconfig $itk_interior 2 -weight 1

	eval itk_initialize $args
    }
}

usual Imagedata {
    keep -background -cursor -foreground -font -entryfont
    keep -selectbackground -selectborderwidth -selectforeground
    keep -borderwidth
}

body Imagedata::update { a_dom } {

    # Extract data from inside header element
    set beam_x [$a_dom selectNodes normalize-space(//beam_x)]
    set beam_y [$a_dom selectNodes normalize-space(//beam_y)]
    set phi_start [$a_dom selectNodes normalize-space(//phi_start)]
    set phi_end [$a_dom selectNodes normalize-space(//phi_end)]
    set distance [$a_dom selectNodes normalize-space(//distance)]
    set two_theta [$a_dom selectNodes normalize-space(//two_theta)]
    set wavelength [$a_dom selectNodes normalize-space(//wavelength)]
    set pixel_size [$a_dom selectNodes normalize-space(//pixel_size)]
    set gain [$a_dom selectNodes normalize-space(//gain)]
    
}

body Imagedata::clear { } {
    set phi_start ""
    set phi_end ""
    set beam_x ""
    set beam_y ""
    set wavelength ""
    set two_theta ""
    set gain ""
    set pixel_size ""
    set distance ""
}
    
body Imagedata::getPixelSize { } {
    return $pixel_size
}

body Imagedata::getPhiCentre { } {
    return [expr $phi_start + (double($phi_end - $phi_start) / 2.0)]
}
