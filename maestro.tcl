pkg_mkIndex -verbose [pwd] lib/repo.tcl
lappend auto_path [pwd] lib
package require repo 1.0

pkg_mkIndex -verbose [pwd]/lib prepdata.tcl
lappend auto_path [pwd]/lib
package require prepdata 1.0

source lib/see.tcl          ;# get info from msg
source lib/communicate.tcl  ;# hear from and talk to server.
source lib/memorize.tcl     ;# record raw data
source lib/recall.tcl       ;# get actions and action chains from raw data
source lib/sleep.tcl        ;# post analyzation of data to discover structure.
source lib/understand.tcl   ;# encode raw data into a relative strucutre
source lib/intuit.tcl       ;# get action chains from relative structure

namespace eval ::maestro {}
namespace eval ::maestro::set {}
namespace eval ::maestro::handle {}
namespace eval ::maestro::client {}
namespace eval ::maestro::respond {}
namespace eval ::maestro::client::helpers {}


############################################################################
# Setup ####################################################################
############################################################################


proc ::maestro::set::up {} {
  ::repo::create $::communicate::myname
  ::memorize::set::globals
}


################################################################################
# Handle #######################################################################
################################################################################


proc ::maestro::handle::interpret msg {
  set from [::see::from $msg]
  if {$from eq "env" || [string range $from 0 1] eq "s."} {
    return [::maestro::handle::environment $msg]
  } elseif {$from eq "user"} {
    return [::maestro::handle::user $msg]
  }
}

proc ::maestro::handle::environment msg {
  ::memorize::this $msg
  set action [::decide::action $msg]
  ::encode::this [::see::message $msg] $action
  return [::maestro::format $action]
}

proc ::maestro::handle::user msg {
  if {[::see::command $msg] eq "try"} {
    return [::maestro::format [::decide::commanded::try $msg]]
  } elseif {[::see::command $msg] eq "can"} {
    return [::maestro::format [::memorize::commanded::can $msg] "" [::see::from $msg]]
  } elseif {[::see::command $msg] eq "sleep"} {
    return [::maestro::format [::memorize::commanded::sleep $msg]]
  } elseif {[::see::command $msg] eq "learn"} {
    ::memorize::set::learn [::see::message $msg] ;#encode will reference ::memorize::learn
  } elseif {[::see::command $msg] eq "acts"} {
    ::sleep::update::actions [::see::message $msg]
  } elseif {[::see::command $msg] eq "limit"} {
    #return [::memorize::commanded::limit $msg]
  } elseif {[::see::command $msg] eq "cells"} {
    #return [::memorize::commanded::cells $msg]
  }
}


################################################################################
# format #######################################################################
################################################################################


proc ::maestro::format {{msg ""} {cmd ""} {to ""}} {
  if {$msg ne "" && $cmd ne "" && $to ne ""} {
    return [list [list from $::communicate::myname to $to                    command $cmd message $msg when [clock milliseconds]]]
  } elseif {$msg ne "" && $cmd ne ""} {
    return [list [list from $::communicate::myname to $::communicate::talkto command $cmd message $msg when [clock milliseconds]]]
  } elseif {$msg ne "" && $to ne ""} {
    return [list [list from $::communicate::myname to $to                                 message $msg when [clock milliseconds]]]
  } elseif {$cmd ne "" && $to ne ""} {
    return [list [list from $::communicate::myname to $to                    command $cmd              when [clock milliseconds]]]
  } elseif {$msg ne ""} {
    return [list [list from $::communicate::myname to $::communicate::talkto              message $msg when [clock milliseconds]]]
  } elseif {$cmd ne ""} {
    return [list [list from $::communicate::myname to $::communicate::talkto command $cmd              when [clock milliseconds]]]
  } else {
    return ""
  }
}


################################################################################
# Run ##########################################################################
################################################################################


::communicate::setup
::communicate::interact
