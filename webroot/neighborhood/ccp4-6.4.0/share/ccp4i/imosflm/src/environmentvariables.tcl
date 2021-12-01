# $Id: environmentvariables.tcl,v 1.4 2011/01/10 17:23:41 ccb Exp $
package provide environmentvariables 1.0

class EnvironmentVariables {
    inherit Amodaldialog

   # local variables for component widgets, initialised here
   #private variable project ""    

# methods
    #########
    public method toggleMosflmLogging
    constructor { args } { }
}
    # Bodies

body EnvironmentVariables::constructor { args } {

    # Main frame ###########################################################

    # entries ##############################################################

    itk_component add environment_restart_l {
	gSection $itk_interior.environment_restart_label -text "You will need to start a new iMosflm session for these changes to take effect"
    }
    
    itk_component add environment_immediate_l {
	gSection $itk_interior.environment_immediate_label -text "These changes take effect immediately"
    }
    
    itk_component add mosdir_label {
	label $itk_interior.mosdir_label -text "Working directory (MOSDIR):"
    }
    
    itk_component add mosdir_entry {
	SettingEntry $itk_interior.mosdir_entry "mosdir"
    }
    
    itk_component add mosflm_exec_label {
	label $itk_interior.mosflm_exec_label -text "Mosflm executable (MOSFLM_EXEC):"
    }
    itk_component add mosflm_exec_entry {
	SettingEntry $itk_interior.mosflm_exec_entry "mosflm_exec"
    }

    itk_component add web_browser_label {
	label $itk_interior.web_browser_label -text "Web browser (CCP4_BROWSER):"
    }
    
    itk_component add web_browser_entry {
	SettingEntry $itk_interior.web_browser_entry "web_browser"
    }

    itk_component add ccp4_bin_label {
	label $itk_interior.ccp4_bin_label -text "Directory containing CCP4 executables (CBIN):"
    }

    itk_component add ccp4_bin_entry {
	SettingEntry $itk_interior.ccp4_bin_entry "ccp4_bin"
    }

    itk_component add mosflm_logging {
	SettingCheckbutton $itk_interior.mosflm_logging \
	    mosflm_logging \
	    -text "Debug output"
    }

    # Add a Close button
    itk_component add button {
        button $itk_interior.button  -highlightthickness 0  -takefocus 0  -text "Close"  -command [code $this hide]
    }

    # layout ####################################

    set indent 20
    set margin 7

    grid x $itk_component(environment_restart_l) - - - -sticky w -pady {3 0}
    grid x $itk_component(mosdir_label) x $itk_component(mosdir_entry) x -pady 7 -sticky ew
    grid x $itk_component(mosflm_exec_label) x $itk_component(mosflm_exec_entry) x -pady 7 -sticky ew
    grid x $itk_component(mosflm_logging) -pady 7 -sticky w
    grid x $itk_component(environment_immediate_l) - - - -sticky w -pady {4 0}
    grid x $itk_component(ccp4_bin_label) x $itk_component(ccp4_bin_entry) x -pady 7 -sticky ew
    grid x $itk_component(web_browser_label) x $itk_component(web_browser_entry) x -pady 7 -sticky ew

    # place Close button in a grid cell near centre
    grid x x $itk_component(button) x x

    grid columnconfigure $itk_interior { 0 1 2 4 } -minsize 7 -weight 0
    grid columnconfigure $itk_interior { 3 } -weight 1
#   grid rowconfigure $itk_interior 4 -weight 1
#
    set wd [expr 3*[winfo reqwidth $itk_component(hull)]]
    set ht [winfo reqheight $itk_component(hull)]
#   wm geometry $itk_component(hull) ${wd}x${ht}
    
    eval itk_initialize $args
}

########################################################################
# Usual configuration options                                          #
########################################################################

usual EnvironmentVariables {
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}
