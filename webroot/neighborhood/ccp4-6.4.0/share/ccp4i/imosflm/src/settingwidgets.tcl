# $Id: settingwidgets.tcl,v 1.10 2012/03/26 16:36:39 ccb Exp $
package provide settingwidgets 1.0

class SettingWidget {
    
    # Common variables
    private common widgets ; # array  

    # Procedures
    public proc refresh { a_parameter }
    public proc refreshAll { }

    # Member variables
    protected variable parameter ""
    private variable old_value ""

    
    # Methods
    protected method getValue ; # virtual
    public method setValue ; # virtual
    
    public method downloadFromSession
    protected method uploadToSessionIfChanged

    constructor { a_parameter } { }

}

body SettingWidget::constructor { a_parameter } {
    set parameter $a_parameter
    lappend widgets($a_parameter) $this
}

body SettingWidget::refresh { a_parameter } {
    if {[info exists widgets($a_parameter)]} {
	foreach i_widget $widgets($a_parameter) {
	    $i_widget downloadFromSession
	}
    }
}

body SettingWidget::refreshAll { } {
    foreach i_parameter [array names widgets] {
	refresh $i_parameter
    }
}
    
body SettingWidget::getValue { } { error "Virtual method SettingWidget::getValue not overridden" }

body SettingWidget::setValue { } { error "Virtual method SettingWidget::getValue not overridden" }

body SettingWidget::uploadToSessionIfChanged { } {

    # If one presses return in a setting entry while it is blank, the interpreter gave an error
    # The if statement below catches that case and leaves the old_value unchanged - except for
    # mtz_file where one might want to delete the filename entered.
    if {([getValue] == "") && ($parameter != "mtz_file")} {
	$::session updateSetting $parameter $old_value 1 1	
    } else {
	# if the current value doesn't match the old value
	if {[getValue] != $old_value} {
	    # update the session with the current value
	    $::session updateSetting $parameter [getValue] 1 1
    
	    # update the old value
	    set old_value [getValue]
    
	    # A hack to send the detector and reversephi keywords.
	    if {$parameter == "detector_manufacturer"} {
		$::mosflm sendCommand "detector $old_value"
	    }
	    #  reversephi should only be sent to ipmosflm if the detector manufacturer is already set.
	    if {$parameter == "reverse_phi" && [$::session getDetectorManufacturer] != ""} {
		$::mosflm sendCommand "detector reversephi"
	    }
	}
    }
}

body SettingWidget::downloadFromSession { } {
    set l_new_value [$::session getParameterValue $parameter]
    set old_value $l_new_value
    setValue $l_new_value
}


##########################################################################################

class SettingEntry {
    inherit gEntry SettingWidget

#     itk_option define -parameter parameter Parameter "" {
# 	set parameter $itk_option(-parameter)
#     } 

    public method update
    public method getValue
    public method setValue
    public method publicUploadToSessionIfChanged

    constructor { a_parameter args } {
	eval gEntry::constructor $args
	SettingWidget::constructor $a_parameter
    } {
	bind $itk_component(entry) <FocusOut> +[code $this uploadToSessionIfChanged]
	bind $itk_component(entry) <Return> +[code $this uploadToSessionIfChanged]
    }
}

body SettingEntry::update { a_value } {
    gEntry::update $a_value
    uploadToSessionIfChanged
}

body SettingEntry::getValue { } {
    return [$itk_component(entry) get]
}

body SettingEntry::setValue { a_value } {
    $itk_component(entry) configure -state normal
    $itk_component(entry) delete 0 end
    $itk_component(entry) insert end $a_value
    $itk_component(entry) configure -state $itk_option(-state)
}

usual SettingEntry {
    usual gEntry
}

body SettingEntry::publicUploadToSessionIfChanged {} {
    uploadToSessionIfChanged
    #puts "did it"
}

##########################################################################################

class MultiSettingEntry {
    inherit gEntry

    private common widgets_by_parameter ; # array
    public proc refresh

    # Member variables
    private variable parameters {}
    private variable inverse_parameters {}
    private variable old_value ""

    public method uploadToSessionIfChanged
    public method update

    constructor { a_parameters a_inverse_parameters  args } {
	eval gEntry::constructor $args
    } {
	set parameters $a_parameters
	set inverse_parameters $a_inverse_parameters
	foreach i_param [concat $parameters $inverse_parameters] {
	    set widgets_by_parameter($i_param) $this
	}
	bind $itk_component(entry) <FocusOut> +[code $this uploadToSessionIfChanged]
	bind $itk_component(entry) <Return> +[code $this uploadToSessionIfChanged]
    }
}

body MultiSettingEntry::refresh { a_varname } {
    if {[info exists widgets_by_parameter($a_varname)]} {
	$widgets_by_parameter($a_varname) update
    }
}

body MultiSettingEntry::uploadToSessionIfChanged { } {
    set l_new_value [$itk_component(entry) get]
    if {$l_new_value != $old_value} {
	foreach i_parameter $parameters {
	    # update the session with the current value
	    $::session updateSetting $i_parameter $l_new_value 1 1
	}
	foreach i_parameter $inverse_parameters {
	    # update the session with the current value
	    $::session updateSetting $i_parameter [format %.$itk_option(-precision)f [expr 1.0 / $l_new_value]] 1 1
	}
	# update the old value
	set old_value [$itk_component(entry) get]
    }
}

body MultiSettingEntry::update { } {
    set l_value [$::session getParameterValue [lindex $parameters 0]]
    set l_mismatch 0
    foreach i_parameter [lrange $parameters 1 end] {
	if {[$::session getParameterValue $i_parameter] != $l_value} {
	    set l_mismatch 1
	    break
	}
    }
    if {!$l_mismatch} {
	foreach i_parameter $inverse_parameters {
	    if {[$::session getParameterValue $i_parameter] != [format %.$itk_option(-precision)f [expr 1.0 / $l_value]]} {
		set l_mismatch 1
		break
	    }
	}
    }	
    
    if {$l_mismatch} {
	set l_value ""
    }
    $itk_component(entry) configure -state normal
    $itk_component(entry) delete 0 end
    $itk_component(entry) insert end $l_value
    $itk_component(entry) configure -state $itk_option(-state)
    set old_value $l_value
}

usual MultiSettingEntry {
    usual gEntry
}

##########################################################################################

class SettingFileentry {
    inherit Fileentry SettingWidget

#     itk_option define -parameter parameter Parameter "" {
# 	set parameter $itk_option(-parameter)
#     } 

    public method getValue
    public method setValue

    constructor { a_parameter args } {
	Fileentry::constructor
	SettingWidget::constructor $a_parameter
    } {
	bind $itk_component(entry) <FocusOut> +[code $this uploadToSessionIfChanged]
	eval itk_initialize $args
    }
}

body SettingFileentry::getValue { } {
    return [$itk_component(entry) get]
}

body SettingFileentry::setValue { a_value } {
    $itk_component(entry) configure -state normal
    $itk_component(entry) delete 0 end
    $itk_component(entry) insert end $a_value
    $itk_component(entry) configure -state $itk_option(-state)
}

usual SettingFileentry {
    usual Fileentry
}
    
##########################################################################################

class SettingCombo {
    inherit Combo SettingWidget

#     itk_option define -parameter parameter Parameter "" {
# 	set parameter $itk_option(-parameter)
#     } 

    private method getValue
    public method setValue
    public method execute

    constructor { a_parameter args } {
	Combo::constructor
	SettingWidget::constructor $a_parameter
    }  {
	bind $itk_component(hull) <FocusOut> +[code $this uploadToSessionIfChanged]
	eval itk_initialize $args
    }
}

body SettingCombo::getValue { } {
    return [$itk_component(entry) get]
}

body SettingCombo::setValue { a_value } {
    set l_state [$itk_component(entry) cget -state]
    $itk_component(entry) configure -state normal
    $itk_component(entry) delete 0 end
    $itk_component(entry) insert end $a_value
    $itk_component(entry) configure -state $l_state
}

body SettingCombo::execute { } {
    uploadToSessionIfChanged
    Combo::execute
}

usual SettingCombo {
    usual Combo
}
    
##########################################################################################

class SettingCheckbutton {
    inherit gcheckbutton SettingWidget

#     itk_option define -parameter parameter Parameter "" {
# 	set parameter $itk_option(-parameter)
#     } 

    public method getValue
    private method setValue
    
    private method change
    public method invoke

    constructor { a_parameter args } {
	gcheckbutton::constructor
	SettingWidget::constructor $a_parameter
    }  {
	eval itk_initialize $args
    }
}

body SettingCheckbutton::getValue { } {
    return $value
}

body SettingCheckbutton::setValue { a_value } {
    set value $a_value
    updateImage
}

body SettingCheckbutton::change { args } {
    gcheckbutton::change $args
    uploadToSessionIfChanged
}

body SettingCheckbutton::invoke { args } {
    gcheckbutton::invoke
    uploadToSessionIfChanged
}

usual SettingCheckbutton {
    usual gcheckbutton
}
    
##########################################################################################

class SettingRadio {
     inherit Radio SettingWidget

    #itk_option define -parameter parameter Parameter "" {} 

    private method invoke
    private method getValue
    private method setValue

    constructor { a_parameter args } {
	Radio::constructor
	SettingWidget::constructor $a_parameter
    }  {
	eval itk_initialize $args
    }
}

body SettingRadio::invoke { } {
    if {$current_value != $value} {
	# update the session with the current value
	$::session updateSetting $parameter $value 0
	# create a history event
	$::session addHistoryEvent "ParameterUpdateEvent" "User" "group" $parameter $current_value $value
	Radio::invoke
    }
}

body SettingRadio::getValue { } {
    return $value
}

body SettingRadio::setValue { a_value } {
    set value $a_value
}


usual SettingRadio {
    usual Radio
}

##########################################################################################

class SettingToolbutton {
    inherit Toolbutton SettingWidget

    public method execute
    public method invoke
    public method cancel
    private method getValue
    private method setValue

    constructor { a_parameter args } {
	Toolbutton::constructor -type "modal"
	SettingWidget::constructor $a_parameter
    } { 
	eval itk_initialize $args
    }
}

body SettingToolbutton::execute { } {
    Toolbutton::execute
    uploadToSessionIfChanged    
}

body SettingToolbutton::invoke { } {
    Toolbutton::invoke
    uploadToSessionIfChanged
}

body SettingToolbutton::cancel { } {
    Toolbutton::cancel
    uploadToSessionIfChanged
}

body SettingToolbutton::getValue { } {
    return $mode
}

body SettingToolbutton::setValue { a_value } {
    if {$a_value == 0} {
	Toolbutton::cancel
    } else {
	Toolbutton::invoke
    }
}

usual SettingToolbutton {
    usual Toolbutton
}
