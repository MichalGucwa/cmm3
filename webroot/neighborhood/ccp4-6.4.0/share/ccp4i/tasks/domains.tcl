#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
# =======================================================================
# domain.tcl --
#
# Interface for system manager to define machine domains
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc domains_task_window { arrayname } {
#------------------------------------------------------------------------------
 upvar #0 $arrayname array
 global domains
 global configure

 WarningMessage "Option not fully implemented yet"
 return 0

  if { ![file writable [file join [GetEnvPath CCP4I_TOP] etc domains.def.dist]] } {
    WarningMessage "Only the system manager or someone with write permission for the CCP4i source directory can set up the machine domains" 
    return 0
  }

  set helpfile [SearchPath HELP general configure.html ]
  SetProgramHelpFile [SearchPath HELP general configure.html ]
  InitialisePreferences domains $arrayname  -nouser

  if { [CreateTaskWindow $arrayname  \
        "Define Machine Domains" "Domains" {} \
	-action_buttons quit \
	-help_file $helpfile ] == 0 } return

  set savebutton [button $array(WINDOW).buttons.save\
		-text "Save" \
		-background $configure(COLOUR_PALE) \
		-font $configure(FONT_REGULAR) \
		-command "domains_save
		InitialisePreferences domains domains"]

  pack  $savebutton -side left -expand 1

  OpenFolder protocol

  CreateLine line \
  label "Define the machine domains for your installation" -italic

  CreateExtendingFrame N_DOMAINS domains_machines \
        "Specify machine domains" \
        "Add a domain" \
      [ list DOMAIN_NAME DOMAIN_MACHINES ]
}

#-------------------------------------------------------------------
proc domains_machines { arrayname counter } {
#-------------------------------------------------------------------

  CreateLine line \
    message "Enter name of domain to be seen by user" \
    label "Name for the machine domain" \
    help domains \
    widget DOMAIN_NAME \
	-width 30  \
    label "and hostnames of machines within the domain.." 

  CreateLine line \
    message "Hostnames of machines in the domain" \
    widget DOMAIN_MACHINES -expand

}

#---------------------------------------------------------------------
proc domains_save { } {
#---------------------------------------------------------------------
  set filename [SearchPath TOP etc domains.def]

  if { ![file exists $filename] || [file writable $filename ] } {
    SaveArray domains $filename domains -save_types
  } else {
    WarningMessage "Error attempting to write to file $filename
You do not have write permission for this file"
  }
}

