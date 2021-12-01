# $Id: projectdialog.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide projectdialog 0.2

# image create photo ::img::mosflmicon -file [file join $env(MOSFLM_GUI_ROOT) ../images/mosflmicon.gif]

class Sessionpropertiesdialog {
   inherit Dialog

   # local variables for component widgets, initialised here
   private variable project ""
   private variable crystal ""
   private variable dataset ""

   constructor { args } {

      wm iconbitmap $itk_component(hull) [wm iconbitmap .]
      wm iconmask $itk_component(hull) [wm iconmask .]

      itk_component add sessionlabel {
         label $itk_interior.sessionlabel -image ::img::mosflmicon
      }

      itk_component add sessiontitle {
         label $itk_interior.session -text "<Session name"
      }

      itk_component add projectlabel {
         label $itk_interior.projectlabel -text "Project:"
      }

      itk_component add projectentry {
         gEntry $itk_interior.projectentry \
            -textvariable [scope project] \
      }

      itk_component add crystallabel {
         label $itk_interior.crystallabel -text "Crystal:"
      }

      itk_component add crystalentry {
         gEntry $itk_interior.crystalentry \
            -textvariable [scope crystal] \
      }

      itk_component add datasetlabel {
         label $itk_interior.datasetlabel -text "Dataset:"
      }

      itk_component add datasetentry {
         gEntry $itk_interior.datasetentry \
            -textvariable [scope dataset] \
      }

      itk_component add controls {
         frame $itk_interior.controls \
            -borderwidth 0
      }

      itk_component add okay {
         button $itk_interior.controls.okay \
            -width 7 \
            -pady 2 \
            -text "OK" \
            -command [code $this dismiss 1] \
            -highlightthickness 1
      }

      itk_component add cancel {
         button $itk_interior.controls.cancel \
            -width 7 \
            -pady 2 \
            -text "Cancel" \
            -command [code $this dismiss 0] \
            -highlightthickness 1
      }
      pack $itk_component(cancel) -side right
      pack $itk_component(okay) -side right -padx 3

      itk_component add separator {
	  frame $itk_interior.separator \
	      -height 2 \
	      -relief sunken \
	      -borderwidth 1
      }

      grid x $itk_component(sessionlabel) $itk_component(sessiontitle) x -pady 7 -sticky w
      grid x $itk_component(projectlabel) $itk_component(projectentry) x -pady 7 -sticky w
      grid x $itk_component(crystallabel) $itk_component(crystalentry) x -pady 7 -sticky w
      grid x $itk_component(datasetlabel) $itk_component(datasetentry) x -pady 7 -sticky w
      grid $itk_component(separator) - - - -pady 7 -sticky we
      grid x $itk_component(controls) - x -pady 7 -sticky we
      grid configure $itk_component(sessiontitle) -padx 2
      grid columnconfigure $itk_interior 0 -minsize 7 -weight 0
      grid columnconfigure $itk_interior 3 -minsize 7 -weight 0

      eval itk_initialize $args

   }

   public method confirm
   public method dismiss { accept }
}


body Sessionpropertiesdialog::confirm { } {
   # update dialog with current proj info before displaying each time
   #  in case of previous 'cancel'
    wm title $itk_component(hull) "[$::session cget -name] properties" 
    $itk_component(sessiontitle) configure -text [$::session cget -name]
    set project [$::session cget -project]
    set crystal [$::session cget -crystal]
    set dataset [$::session cget -dataset]

    Dialog::confirm
    focus $itk_component(okay)
}


body Sessionpropertiesdialog::dismiss { accept } {
   if {$accept == 1} {

       $::session configure \
	   -project $project \
	   -crystal $crystal \
	   -dataset $dataset

      uplevel #0 $itk_option(-updatecommand)
   }
   Dialog::dismiss $accept
}



