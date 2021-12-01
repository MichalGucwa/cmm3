# $Id: imagenumbers.tcl,v 1.10 2012/03/26 16:36:39 ccb Exp $
package provide imagenumbers 1.0

class ImagenumbersSingle {
    inherit itk::Widget

    itk_option define -command command Command ""

    private variable templates
    private variable indices_by_template ;# array
    private variable index "1"

    private variable old_template ""
    public method toggleTemplate

    public method clear
    public method addSector
    public method deleteSector
    public method execute
    public method updateSector
    public method getContent
   
    constructor { args } { }
}

body ImagenumbersSingle::constructor { args } {
    itk_component add singlesectorcombo {
	combobox::combobox $itk_interior.singlesectorcombo \
	    -listvar [scope templates] \
	    -width 32 \
	    -editable 0 \
	    -highlightcolor black \
	    -command [code $this toggleTemplate]
    } {
	keep -state
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }
    
    set old_template "\n"	
    #puts $old_template

    itk_component add entry {
	gEntry $itk_interior.entry \
	    -relief sunken \
	    -borderwidth 2
    } {
	usual
	ignore -borderwidth -relief
	keep -state
    }
    bind [$itk_component(entry) component entry] <Return> [code $this execute]
    bind [$itk_component(entry) component entry] <FocusOut> [code $this execute]

    pack $itk_component(singlesectorcombo) -side left
    pack $itk_component(entry) -side right -fill x -expand 1

    eval itk_initialize $args

}

body ImagenumbersSingle::clear { } {
    set old_template ""
    set templates {}
    $itk_component(singlesectorcombo) delete 0 end
    $itk_component(entry) update ""
}

body ImagenumbersSingle::addSector { a_sector } {
    lappend templates [$a_sector getTemplate]
    $itk_component(singlesectorcombo) select [expr [llength $templates] -1]
    set l_text [$itk_component(singlesectorcombo) get]
    if {$l_text == ""} {
	$itk_component(singlesectorcombo) select 0
    }

    # Make sure template labels are shown if more than one sector is present
    if {[llength $templates] > 1} {
	pack $itk_component(singlesectorcombo) -side left
    } else {
	pack forget $itk_component(singlesectorcombo)	
    }
}

body ImagenumbersSingle::deleteSector { a_sector } {   
    set l_template [$a_sector getTemplate]
    set l_index [lsearch $templates $l_template]
    if {$l_index != -1} {
	set templates [lreplace $templates $l_index $l_index]
	set l_text [$itk_component(singlesectorcombo) get]
	if {$l_text == $l_template} {
	    $itk_component(singlesectorcombo) select 0
	}
    }    
    # Make sure template labels are shown if more than one sector is present
    if {[llength $templates] > 1} {
	pack $itk_component(singlesectorcombo) -side left
    } else {
	pack forget $itk_component(singlesectorcombo)	
    }
}

body ImagenumbersSingle::execute { } {
    if {$itk_option(-command) != ""} {
	#puts "Command is $itk_option(-command)"
	set l_num_list [uncompressNumList [$itk_component(entry) query]]
	#puts "ImagenumbersSingle::execute num_list is $l_num_list"
	# execute is called if a new session is started so check for an empty list
	#if { $l_num_list == "" } {
	#    puts "Empty so could build num_list from all current sector\'s images"
	#    foreach l_image [[$::session getCurrentSector] getImages] {
	#	puts "lappend l_num_list [$l_image getNumber]"
	#    }
	#}
	# Dont pass list back to indexwizard else spot finding commences for all images
	# or cellrefinement wizard when all images are selected for cell refinement due to
	# Mosflm::getCellRefinementSegments not knowing the current selected.
	# Command in both cellrefinement and integration wizards is defaultImageSelection
	#puts "Try [$itk_component(singlesectorcombo) get] [list $l_num_list]"

	# template and image numbers list returned for Indexwizard::chooseImages
	uplevel \#0 $itk_option(-command) [$itk_component(singlesectorcombo) get] [list $l_num_list]
    }
}

body ImagenumbersSingle::updateSector { a_template { a_num_list "" } } {

    #puts "ImagenumbersSingle::updateSector template $a_template num_list $a_num_list"
    $::session setCurrentSector [$::session getSectorByTemplate $a_template]
    set l_index [lsearch $templates $a_template]
    #puts "updateSector: index $l_index $templates"
    if {$l_index != -1} {
	# Disable singlesectorcombo's command before updating to prevent recursive updating!
	set l_command [$itk_component(singlesectorcombo) cget -command]
	$itk_component(singlesectorcombo) configure -command {}
	$itk_component(singlesectorcombo) select $l_index
	# ... and restore command after update
	$itk_component(singlesectorcombo) configure -command $l_command
        $itk_component(entry) update $a_num_list
    }
    # If no matrix for this sector disable processing stages
    if { ![[[$::session getCurrentSector] getMatrix] isValid] } {
	.c disableProcessing
    } else {
	.c enableProcessing
    }
}

body ImagenumbersSingle::getContent { } {
    set l_content {}
    set l_template [$itk_component(singlesectorcombo) get]
    set l_nums [uncompressNumList [$itk_component(entry) query]]
    if {($l_template != "") && ($l_nums != "")} {
	set l_content [list [list $l_template $l_nums]]
        updateSector $l_template [compressNumList $l_nums]
	return $l_content
    }
}

body ImagenumbersSingle::toggleTemplate { a_combo a_value } {

    if {$a_value != $old_template} { 
	#puts "Template was $old_template changing to $a_value"
        updateSector $a_value ;# why? - to update session's current sector
	set old_template $a_value
	$itk_component(entry) update ""
	focus [$itk_component(entry) component entry]
	execute

	focus $a_combo ;# but unsure why
    }
}

usual ImagenumbersSingle {
    usual gEntry
}
