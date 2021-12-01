# $Id: settings2.tcl,v 1.8 2010/01/21 16:02:26 rmk65 Exp $
package provide settings2 1.0
# Provides method for megawidgets containing settings widgets to automatically refresh them all with current session data
class Settings2 {
    public method refresh
}

body Settings2::refresh { } {
    # Loop through each component widget
    set this_window [string trimleft $this :]
    foreach i_comp_name [winfo children $this_window] {
	# Check if the widget is an settingWidget (will fail if not an itk::Widget)
	if {(![catch {$i_comp_name isa SettingWidget} t_result]) && $t_result} {
	    # if so, update the widget with the current session value
	    $i_comp_name downloadFromSession
	}
    }
}
