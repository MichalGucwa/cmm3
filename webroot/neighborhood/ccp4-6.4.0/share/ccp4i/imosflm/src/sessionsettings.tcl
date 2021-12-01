# $Id: sessionsettings.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide sessionsettings 1.0

class Sessionsettings {
   inherit itk::Widget Settings2

   # local variables for component widgets, initialised here
   #private variable project ""
   private variable crystal ""
   private variable dataset ""

   #private variable old_project ""
   private variable old_crystal ""
   private variable old_dataset ""

    # accessor methods for old value
    #public method setOld
    #public method setVar

    # Refresh with session settings
    #public method refresh

   constructor { args } {

#       itk_component add sessionlabel {
#          label $itk_interior.sessionlabel -image ::img::mosflmicon
#       }

#       itk_component add sessiontitle {
#          label $itk_interior.session -text "<Session name"
#       }

      itk_component add projectlabel {
         label $itk_interior.projectlabel -text "Project:"
      }

      itk_component add projectentry {
         SettingEntry $itk_interior.projectentry project
      }

      itk_component add crystallabel {
         label $itk_interior.crystallabel -text "Crystal:"
      }

      itk_component add crystalentry {
         SettingEntry $itk_interior.crystalentry "crystal"
      }

      itk_component add datasetlabel {
         label $itk_interior.datasetlabel -text "Dataset:"
      }

      itk_component add datasetentry {
         SettingEntry $itk_interior.datasetentry "dataset"
      }

      itk_component add titlelabel {
         label $itk_interior.titlelabel -text "Title:"
      }

      itk_component add titleentry {
         SettingEntry $itk_interior.titleentry "title"
      }

       #grid x $itk_component(sessionlabel) $itk_component(sessiontitle) x -pady 7 -sticky we
       grid x $itk_component(projectlabel) $itk_component(projectentry) x -pady 7 -sticky we
       grid x $itk_component(crystallabel) $itk_component(crystalentry) x -pady 7 -sticky we
       grid x $itk_component(datasetlabel) $itk_component(datasetentry) x -pady 7 -sticky we
       grid x $itk_component(titlelabel) $itk_component(titleentry) x -pady 7 -sticky we
       #grid configure $itk_component(sessiontitle) -padx 2
       grid columnconfigure $itk_interior { 0 3 } -minsize 7 -weight 0
       grid columnconfigure $itk_interior { 1 2 } -weight 1
       grid rowconfigure $itk_interior 4 -weight 1
       
       eval itk_initialize $args
   }

}

########################################################################
# Accessor methods for old value                                       #
########################################################################

# body Sessionsettings::setOld { var value} {
#     set old_$var $value
# }

# body Sessionsettings::setVar { var value} {
#     set $var $value
# }

########################################################################
# Refresh with session settings                                        #
########################################################################

#body Sessionsettings::refresh { a_list } {
#    foreach { old_project old_dataset old_crystal } $a_list  { }
#    foreach { project dataset crystal } $a_list  { }
#}

########################################################################
# Usual configuration options                                          #
########################################################################

usual Sessionsettings {
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}
