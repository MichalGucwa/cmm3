
namespace eval qtrview {
   variable available 0

   global tcl_platform
   if { [string equal windows $tcl_platform(platform)] } {
      proc file_executable { file } {
         return [file isfile $file]
      }
   } else {
      proc file_executable { file } {
         return [file executable $file]
      }
   }

   if { [string length [array names ::env -exact CCP4]] } {
      set ccp4path [file normalize $::env(CCP4)]

      variable ddef_file_path [file normalize directories.def]
      if { ! [file isfile $ddef_file_path] } { set ddef_file_path [datapath directories.def -domain] }

      variable viewer [file join $ccp4path bin qtrview]
      if { ! [file_executable $viewer] } { set viewer $viewer.exe }

      variable viewer_py [file join $ccp4path bin qtrview.py]

      variable generator [file join $ccp4path share smartie qtrgeneric.py]

      variable ccp4python python
      if { ![catch { exec ccp4-python -c "import sys ; print sys.executable" } python_path] } {
         set ccp4python [file normalize $python_path]
      }

      set available [expr [file_executable $viewer] && [file_executable $ccp4python] && [file isfile $generator]]
   }

   proc isAvailable {} {
      variable available
      return $available
   }

   proc isEnabled {} {
      global preferences
      if { ! [string length [array names preferences -exact QTREPORT_YES]] } { return 0 }
      variable available
      return [expr $available && $preferences(QTREPORT_YES)]
   }

   proc onScriptFinished {} {
      variable available
      if { $available } {
         set rep_suffix qt
         set rep_roottail report

         set log_file_path $::job_params(LOG_FILE)
         set job_id $::job_params(JOB_ID)
         set taskname $::job_params(TASKNAME)
         set project $::job_params(PROJECT)
         set db_dir_path [file normalize [GetDbDirPath $project]]

         set rep_dir_path [file join $db_dir_path [join [list $job_id $taskname $rep_suffix] _]]
         if { ! [file isdir $rep_dir_path] } {
            if { [file exists $rep_dir_path] } { file delete -force $rep_dir_path }
            file mkdir $rep_dir_path
         }
         set rep_rootname [file join $rep_dir_path $rep_roottail]
         set rep_inp_unit [open $rep_rootname.inp w]

         variable ccp4python
         variable generator
         variable ddef_file_path
         puts $rep_inp_unit "PYTHON $ccp4python"
         puts $rep_inp_unit "XRT_GEN $generator"
         puts $rep_inp_unit "JOB_ID $job_id"
         puts $rep_inp_unit "PROJECT $project"
         puts $rep_inp_unit "DIR_DEF $ddef_file_path"
         puts $rep_inp_unit "LOGFILE $log_file_path"
         puts $rep_inp_unit "REP_DIR $rep_dir_path"
         puts $rep_inp_unit "REP_XRT $rep_rootname.xrt"
         puts $rep_inp_unit "REP_XML $rep_rootname.xml"
         puts $rep_inp_unit "STATUS FINISHED"
         puts $rep_inp_unit "CLEANUP NO"
         global configure
         if { $configure(EXPORT_TO_QTRVIEW) } {
            puts $rep_inp_unit "RUN_COOT $configure(RUN_COOT)"
            puts $rep_inp_unit "RUN_CCP4MG $configure(RUN_CCP4MG)"
         }
         close $rep_inp_unit
         catch { exec $ccp4python $generator $rep_rootname.inp }
      }
   }


   proc launchReportViewer { job_id } {
      variable available
      if { $available } {
         set rep_suffix qt
         set rep_roottail report

         set log_file_path [file normalize [GetLogFileName $job_id]]

         set project [GetCurrentProject]
         set db_dir_path [file normalize [GetDbDirPath $project]]
         set db_dir_path [file normalize [GetProjectDBPath $project]]

         set job_status [DbGetJobData $job_id STATUS]
         set cleanup YES
         if { ! [string equal RUNNING $job_status] } {
            set job_status FINISHED
            if { [file writable $db_dir_path] } { set cleanup NO }
         }

         set taskname [DbGetJobData $job_id TASKNAME]
         set rep_dir_path [file join $db_dir_path [join [list $job_id $taskname $rep_suffix] _]]
         if { [string equal YES $cleanup] } {
            set rep_dir_path [file normalize [join [list [GetTmpFileName] $rep_suffix] _]]
            file delete -force $rep_dir_path
         }
         if { ! [file isdir $rep_dir_path] } {
            if { [file exists $rep_dir_path] } { file delete -force $rep_dir_path }
            file mkdir $rep_dir_path
         }
         set rep_rootname [file join $rep_dir_path $rep_roottail]
         set rep_inp_unit [open $rep_rootname.inp w]

         variable ccp4python
         variable generator
         variable ddef_file_path
         puts $rep_inp_unit "PYTHON $ccp4python"
         puts $rep_inp_unit "XRT_GEN $generator"
         puts $rep_inp_unit "JOB_ID $job_id"
         puts $rep_inp_unit "PROJECT $project"
         puts $rep_inp_unit "DIR_DEF $ddef_file_path"
         puts $rep_inp_unit "LOGFILE $log_file_path"
         puts $rep_inp_unit "REP_DIR $rep_dir_path"
         puts $rep_inp_unit "REP_XRT $rep_rootname.xrt"
         puts $rep_inp_unit "REP_XML $rep_rootname.xml"
         puts $rep_inp_unit "STATUS $job_status"
         puts $rep_inp_unit "CLEANUP $cleanup"
         global configure
         if { $configure(EXPORT_TO_QTRVIEW) } {
            puts $rep_inp_unit "RUN_COOT $configure(RUN_COOT)"
            puts $rep_inp_unit "RUN_CCP4MG $configure(RUN_CCP4MG)"
         }
         close $rep_inp_unit

         if { ! [file isfile nograph] } {
            variable viewer
            variable viewer_py
            if { [file isfile $viewer_py] } {
               exec $ccp4python $viewer_py $viewer $rep_rootname.inp &
            } else {
               exec $viewer --inp-file $rep_rootname.inp &
            }
         } else {
            exec $ccp4python $generator $rep_rootname.inp
         }
      }
   }

   proc cleanup { job_id } {
      set rep_suffix qt
      set db_dir_path [GetDbDirPath [GetCurrentProject]]
      set rep_dir_path [file join $db_dir_path [join [list $job_id [DbGetJobData $job_id TASKNAME] $rep_suffix] _]]
      file delete -force $rep_dir_path
   }
}

