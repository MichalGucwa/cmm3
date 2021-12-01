# $Id: balloonwidget.tcl,v 1.9 2010/12/08 12:31:34 ccb Exp $
package provide balloonwidget 1.0

###############################################################################
# ########################################################################### #
# # CLASS: Balloonwidget                                                    # #
# ########################################################################### #
###############################################################################

class Balloonwidget {
    inherit itk::Widget

    itk_option define -balloonhelp balloonHelp BalloonHelp ""

    private variable balloon_queue ""
    private variable destroy_queue ""

    public method enter
    public method leave
    public method balloon

    constructor { args } {
	bind $itk_component(hull) <Enter> [code $this enter]
	bind $itk_component(hull) <Leave> [code $this leave]
	eval itk_initialize $args }
}

body Balloonwidget::enter { } {
    if {$balloon_queue != ""} {
	after cancel $balloon_queue
    }
    if {$itk_option(-balloonhelp) != ""} {
	set balloon_queue [after 750 [code $this balloon]]
    }
}

body Balloonwidget::leave { } {
    if {$balloon_queue != ""} {
	after cancel $balloon_queue
    }
    set destroy_queue [after 100 {catch {destroy .balloon_help}}]
}

body Balloonwidget::balloon { } {
    set t .balloon_help
    catch {destroy $t}
    toplevel $t
    wm overrideredirect $t 1

    if {[tk windowingsystem] == "aqua"} {
	#::tk::unsupported::MacWindowStyle style $itk_component(hull) floating sideTitlebar
	::tk::unsupported::MacWindowStyle style $t help none
    }

    label $t.l \
   	-text " $itk_option(-balloonhelp) " \
	-relief solid \
	-bd 2 \
	-bg gold \
	-fg #000000 \
	-font font_b
    pack $t.l -fill both
    set x [expr [winfo pointerx $itk_component(hull)] + 8]
    set y [expr [winfo pointery $itk_component(hull)] + 20]
    if {[expr $x + [winfo reqwidth $t.l]] > [winfo screenwidth $t.l]} {
   	set x [expr [winfo screenwidth $t.l] - [winfo reqwidth $t.l] - 2]
    }
    if {[expr $y + [winfo reqheight $t.l]] > [winfo screenheight $t.l]} {
   	set y [expr $y - 20 - [winfo reqheight $t.l] - 2]
    }
    wm geometry $t +$x\+$y
    #bind $t <Enter> [list [after cancel $destroy_queue]]
    #bind $t <Leave> "catch {destroy .balloon_help}"
}
