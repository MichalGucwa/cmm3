if {[catch {package require Tcl 8.4}]} return
set script ""
if {![info exists ::env(TREECTRL_LIBRARY)]
    && [file exists [file join $dir treectrl.tcl]]} {
    append script "[list set ::treectrl_library $dir]\n"
}
append script [list load [file join $dir libtreectrl2.2.so] treectrl]
package ifneeded treectrl 2.2.10 $script
