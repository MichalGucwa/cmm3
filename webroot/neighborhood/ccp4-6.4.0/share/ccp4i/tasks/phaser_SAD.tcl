# =======================================================================
# phaser_SAD.tcl --
#
# Phaser SAD Phasing
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_SAD_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_SAD_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  return 1
  }

#------------------------------------------------------------------------
proc phaser_SAD_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

  return 1
  }

#------------------------------------------------------------------------
  proc phaser_SAD_task_window {arrayname} {
#------------------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  WarningMessage "For {Phaser SAD phasing} use {Phaser SAD pipeline}\nunder the {Automated Search & Phasing} menu"
  return 0

}

