
namespace eval CCP4_Updates {
   variable on_windows [string equal windows $::tcl_platform(platform)]

   if { $on_windows } {
      proc task_name { id } {
         if { [catch { exec TASKLIST /FI "PID eq $id" /FO CSV /NH } stdeo] } { return }
         return [lindex [split $stdeo \"] 1]
      }
   } else {
      proc task_name { id } {
         if { [catch { exec ps -o comm= -p $id } stdeo] } { return }
         return $stdeo
      }
   }

   proc toLOG { args } {
      variable LOG
      set pname [lindex [split [info level [expr [info level] - 1]] " "] 0]
      foreach vname $args {
         upvar $vname vvalue
         if { [llength [split $vvalue "\n"]] > 1 } {
            puts $LOG [format "%-42s %s" $pname $vname]
            puts $LOG $vvalue
         } else {
            puts $LOG [format "%-42s %-24s %s" $pname $vname $vvalue]
         }
      }
      flush $LOG
   }

   proc config_update_button { state } {
      toLOG state
      variable update_button
      variable ccp4_writable
      if { $state && $ccp4_writable } {
         $update_button configure -state normal
      } else {
         $update_button configure -state disabled
      }
   }

   proc config_update_label { text } {
      toLOG text
      variable update_label
      $update_label configure -text $text
   }

   proc initialise { label button rname } {
      variable update_label $label
      variable update_button $button
      grid remove $update_label
      grid remove $update_button

      variable dir_ccp4 [file normalize $::env(CCP4)]
      variable update_off 1
      if { ! [file isdir [file join $dir_ccp4 restore]] } {
         return
      }

      set file_log $rname.log
      set exe_ccp4um [file join $dir_ccp4 bin ccp4um]
      variable file_temp $rname.tmp
      variable exe_version [list $exe_ccp4um-bin -version]
      variable LOG stdout
      set update_off [catch { set LOG [open $file_log "w"] ; close [open $file_temp "w"] ; eval exec $exe_version } stdoe]
      toLOG file_log file_temp dir_ccp4 exe_ccp4um exe_version stdoe update_off
      if { $update_off } {
         return
      }

      variable exe_silent [list $exe_ccp4um-bin -check-silent]
      toLOG exe_silent

      variable on_windows
      variable exe_active $exe_ccp4um
      variable ccp4_writable 1
      if { !$on_windows && ![file writable $dir_ccp4] } {
         if { [catch { exec which osascript } stdoe] } {
            toLOG stdoe
            if { [catch { exec which gksudo } stdoe] } {
               toLOG stdoe
               if { 1 } {
                  set exe_active $exe_ccp4um-bin
               } else {
                  set ccp4_writable 0
               }
            } else {
               set exe_active [list gksudo -g -m "CCP4 Update needs your sudo password" "$exe_active"]
            }
         } else {
            set osascript "do shell script \"$exe_active\" with administrator privileges without altering line endings"
            set exe_active [list osascript -e $osascript]
         }
      }
      toLOG exe_active ccp4_writable

      $update_button configure -command [namespace current]::updates_button_pressed
      bind $update_button <Return> [namespace current]::updates_button_pressed
      grid $update_label
      grid $update_button

      variable update_check_timeout ""
      variable manage_updates ""
      variable mode_active $ccp4_writable
      variable mode_silent 1
      after idle [namespace current]::preferences_saved                               ;#
   }

   proc preferences_saved {} {
      variable update_off
      toLOG update_off
      if { $update_off } {
         return
      }
      global preferences
      variable update_check_timeout
      variable manage_updates
      variable mode_active
      variable mode_silent
      set b1 [string equal $manage_updates $preferences(MANAGE_UPDATES)]
      set b2 [string equal $update_check_timeout $preferences(UPDATE_CHECK_TIMEOUT)]
      if { [expr $b1 && $b2] } return

      variable manage_updates $preferences(MANAGE_UPDATES)
      variable update_check_timeout $preferences(UPDATE_CHECK_TIMEOUT)
      switch $manage_updates {
         default -
         disable { set mode_silent 0 ; set mode_active 0 }
         notify { set mode_silent 1 ; set mode_active 0 }
         manage { set mode_silent 1 }
      }
      variable check_silent_timeout [expr int( 1000* $update_check_timeout )]
      variable check_silent_timeout_plus [expr $check_silent_timeout + 500]

      variable update_label
      if { $mode_silent } {
         config_update_button 0
         grid $update_label
         config_update_label "Checking for new updates"
         after idle [namespace current]::check_silent_init                            ;#
      } else {
         config_update_label ""
         grid remove $update_label
         config_update_button 1
      }
   }

   proc updates_button_pressed {} {
      variable update_off
      toLOG update_off
      if { $update_off } { return }
      config_update_button 0
      config_update_label "Managing updates"
      after idle [namespace current]::check_active_init                               ;#
   }

   proc check_active_init {} {
      variable mode_active 0
      variable exe_active
      variable process_id 0
      variable process_name {}
      variable time_incr 200
      toLOG time_incr
      variable LOG
      if { [catch { eval exec $exe_active >&@ $LOG & } process_id] } {
         toLOG process_id
         after idle [namespace current]::check_active_finished -2                     ;#
         return
      }
      set process_name [task_name $process_id]
      toLOG process_id process_name
      if { [string equal $process_name {}] } {
         after idle [namespace current]::check_active_finished -1                     ;#
         return
      }
      after $time_incr [namespace current]::check_active_wait                         ;#
   }

   proc check_active_wait {} {
      variable time_incr
      variable process_id
      variable process_name
      if { ! [string equal $process_name [task_name $process_id]] } {
         after idle [namespace current]::check_active_finished 0                      ;#
         return
      }
      after $time_incr [namespace current]::check_active_wait                         ;#
   }

   proc check_active_finished { status } {
      toLOG status
      variable exe_version
      if { [catch { eval exec $exe_version } stdoe] } {
         variable update_label
         config_update_label "Restart CCP4I"
         grid $update_label
         config_update_button 0
         variable update_off 1
         toLOG stdoe update_off
      } else {
         variable mode_silent
         toLOG mode_silent
         if { $mode_silent } {
            config_update_label "Checking for new updates"
            after idle [namespace current]::check_silent_init                         ;#
         } else {
            config_update_label "X"
            config_update_button 1
         }
      }
   }

   proc check_silent_init {} {
      variable file_temp
      variable exe_silent
      variable time_incr 200
      variable time_spent 0
      variable check_silent_timeout
      toLOG time_incr check_silent_timeout
      if { [catch { file delete -force $file_temp } stdoe] } {
         toLOG stdoe
      }
      if { [file exists $file_temp] } {
         after idle [namespace current]::check_silent_finished -5                     ;#
         return
      }
      variable LOG
      if { [catch { eval exec $exe_silent $file_temp >&@ $LOG & } process_id] } {
         toLOG process_id
         after idle [namespace current]::check_silent_finished -4                     ;#
         return
      }
      after $time_incr [namespace current]::check_silent_wait                         ;#
   }

   proc check_silent_wait {} {
      variable time_spent
      variable time_incr
      variable check_silent_timeout_plus
      if { [incr time_spent $time_incr] > $check_silent_timeout_plus } {
         after idle [namespace current]::check_silent_finished -3                     ;#
         return
      }
      variable file_temp
      if { [file isfile $file_temp] } {
         if { [catch { check_silent_file } status] } { set status -2 }
         toLOG status
         after idle [namespace current]::check_silent_finished $status                ;#
         return
      }
      after $time_incr [namespace current]::check_silent_wait                         ;#
   }

   proc check_silent_file {} {
      variable file_temp
      set data [read [set cha [open $file_temp]]]
      close $cha
      toLOG data
      return [expr [lindex [split [string trimleft $data]] 0]]
   }

   proc check_silent_finished { status } {
      variable mode_active
      toLOG status mode_active
      config_update_button 1
      if { $status < 0 } {
         config_update_label "Update check off (Network?)"
      }\
      elseif { $status == 0 } {
         config_update_label "CCP4 is up to date"
      }\
      elseif { $status > 111 } {
         config_update_label "New CCP4 release is available"
      }\
      elseif { $mode_active } {
         config_update_button 0
         after idle [namespace current]::updates_button_pressed                       ;#
      }\
      else {
         config_update_label "$status new updates available"
      }
      set mode_active 0
   }
}

