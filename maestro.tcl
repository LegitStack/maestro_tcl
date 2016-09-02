pkg_mkIndex -verbose [pwd] lib/repo.tcl
lappend auto_path [pwd] lib
package require repo 1.0

pkg_mkIndex -verbose [pwd]/lib prepdata.tcl
lappend auto_path [pwd]/lib
package require prepdata 1.0

source lib/see.tcl          ;# get info from msg
source lib/communicate.tcl  ;# hear from and talk to server.
source lib/memorize.tcl     ;# record raw data
source lib/recall.tcl       ;# get action chains from raw data
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
  ::wick::set::globals
}


################################################################################
# Handle #######################################################################
################################################################################


## ::interpret msg as message
#
# Entery and exit point. Work on this, make it aseries of chains if you have to.
# format once all data is gathered rather than formatting in various procs.
#
proc ::maestro::handle::interpret msg {
  set from [::see::from $msg]
  if {$from eq "env" || [string range $from 0 1] eq "s."} {
    return [::maestro::handle::environment $msg]
  } elseif {$from eq "user"} {
    return [::maestro::handle::user $msg]
  }
}

proc ::maestro::handle::environment msg {
  # record raw data
  ::wick::raw $msg
  # choose behavior
    # get path or choose randomly, etc.
  # incorporate into causal structure
  # return behavior.
}



proc ::maestro::handle::user msg {
  if {[::see::command $msg] eq "can"} {
    return [::wick::commanded::can $msg]
  } elseif {[::see::command $msg] eq "try"} {
    return [::wick::commanded::try $msg]
  } elseif {[::see::command $msg] eq "sleep"} {
    return [::wick::commanded::sleep $msg]
  }
}


################################################################################
# Environment ##################################################################
################################################################################


proc ::maestro::record msg {
  ::wick::evaluate $msg
  return $msg
}

proc ::maestro::choose msg {
  ::wax::evaluate $msg
  return $msg
}

proc ::maestro::encode msg {
  ::encode::evaluate $msg
  return $msg
}

proc ::maestro::respond msg {
  # format response of our motor command from choose
}


::communicate::setup
::communicate::interact
