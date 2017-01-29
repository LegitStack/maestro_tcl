namespace eval ::decide {}
namespace eval ::decide::set {}
namespace eval ::decide::commanded {}
namespace eval ::decide::help {}
namespace eval ::decide::actions {}


################################################################################################################################################################
# SETUP #########################################################################################################################################################
################################################################################################################################################################


proc ::decide::set::globals {} {
  set ::decide::path    {}        ;# list we're currently compiling to send as motor commands
  set ::decide::goal    ""        ;# the goal.
  set ::decide::explore ""        ;# if commanded to explore this should be random or curious
  set ::decide::cangoal ""        ;# potential goal
  set ::decide::canpath ""        ;# potential actionslist
  set ::decide::acts [string trim [::repo::get::actions] \{\}] ;# all avilable actions.
  if {[llength $::decide::acts] < 2 } {
    for {set i 1} {$i <= 20} {incr i} { ;# put back to 101 please
      lappend actions $i
    }
    set ::decide::acts $actions
  }
}

proc ::decide::set::actions {actions} {
  # this is commented out because it don't work well and takes a lot of time during exploration.
  #foreach act $::decide::acts {
  #  if {[lsearch $actions $act] eq "-1"} {
  #   ::encode::prune::node $act a action
  #  }
  #}
  set ::decide::acts $actions
}




################################################################################################################################################################
# commanded #########################################################################################################################################################
################################################################################################################################################################


proc ::decide::commanded::explore msg {
  if {[::see::message $msg] eq "random"} {
    set ::decide::explore "random"
  } elseif {[::see::message $msg] eq "off"} {
    set ::decide::explore ""
  } else {  ;# default is to explore curiously.
    set ::decide::explore "curious"
  }
  if {$::memorize::loc eq ""} {
    return [::decide::commanded::location]
  }
  return [::decide::commanded::guess]
}

proc ::decide::commanded::try msg {
  set ::decide::goal [::see::message $msg]
  if {$::decide::goal               eq $::decide::cangoal
  &&  $::decide::canpath            ne  ""
  } then {
    set ::decide::explore ""
    set ::decide::goal $::decide::cangoal
    set ::decide::path $::decide::canpath
    return [::decide::commanded::exists $msg]
  } elseif {$::decide::goal eq "" && $::decide::explore eq ""} {
    ::decide::commanded::stop
  } elseif {$::decide::goal eq "" && $::decide::explore ne ""} {
    return [::decide::commanded::guess]
  } elseif {$::decide::goal eq $::memorize::input} {
    ::decide::commanded::stop
  } else {
    return [::decide::commanded::find $msg]
  }
}



proc ::decide::commanded::do msg {
  ::decide::commanded::stop
  if {[llength [::see::message $msg]] == 1 } {
    set ::decide::path [::see::message $msg]
  } else {
    if {[lindex [::see::message $msg] 0] == "list" } {
      for {set i 0} {$i < [llength [::see::message $msg]]} {incr i} {
        lappend ::decide::path [lindex [::see::message $msg] $i]
      }
    } elseif {[lindex [::see::message $msg] 0] == "repeat"} {
      for {set i 0} {$i < [lindex [::see::message $msg] 2]} {incr i} {
        lappend ::decide::path [lindex [::see::message $msg] 1]
      }
    } else {
      puts "unknown command: [::see::message $msg]"
      set ::decide::path [lindex [::see::message $msg] 0]
    }
  }
  return [::decide::actions::do]
}


proc ::decide::commanded::can msg {
  set goal [::see::message $msg]
  set path [::recall::main $::memorize::input $goal]
  set newgoal [lindex $goal 0]
  set path [string trim [lrange $path 1 end] \{\}]
  set ::decide::canpath $path
  set ::decide::cangoal $newgoal
  if {$path             eq  ""  ||
      [lindex $path 0]  eq  "_"
  } then {
    return no
  } else {
    return yes
  }
}

proc ::decide::commanded::exists msg {
  if {[lsearch [::see::message $msg] $::memorize::input] >= 0} {
    set path [::recall::main $::memorize::input $::decide::goal]
    set ::decide::goal [lindex $path 0]
    set ::decide::path [string trim [lrange $path 1 end] \{\}]
  }
  return [::decide::actions::do]
}

proc ::decide::commanded::stop {} {
  set ::decide::explore ""
  set ::decide::goal    ""
  set ::decide::path    {}
}

proc ::decide::commanded::acts msg {
  if {$msg eq ""} {
    return [::decide::commanded::resetActions]
  }
  ::sleep::update::actions $msg
  ::decide::set::actions $msg
}

proc ::decide::commanded::sleep msg {
  ::decide::commanded::stop
  if {[::repo::get::randomSet] eq ""} {
    return "nothing in database"
  }
  set subcommand [::see::message $msg]
  if {$subcommand eq ""} { set subcommand $msg }

  if {$subcommand eq "acts"} {
    set ::decide::acts [::sleep::find::actions $::decide::acts]
  } elseif {$subcommand eq "opps"} {
    return [::sleep::find::opposites $::decide::acts]
  } elseif {$subcommand eq "effects"} {
    return [::sleep::find::effects no]
  } elseif {$subcommand eq "always"} {
    return [::sleep::find::always no]
  } elseif {$subcommand eq "effects predict"} {
    return [::sleep::find::effects yes]
  } elseif {$subcommand eq "always predict"} {
    return [::sleep::find::always yes]
  } elseif {$subcommand eq "regions"} {
    return [::sleep::find::regions]
  } else {
    puts "sleeping..."
    puts "acts"
    after 1000
    ::decide::commanded::sleep acts
    puts $::decide::acts
    puts "opps"
    ::decide::commanded::sleep opps
    #might be useful but not currently used.
    #puts "effects"
    #::decide::commanded::sleep effects
    #puts "always"
    #::decide::commanded::sleep always
    puts "regions"
    ::decide::commanded::sleep regions
    puts "awake!"
    return $::decide::acts
  }
}

proc ::decide::commanded::resetActions {} {
  for {set i 1} {$i < 101} {incr i} {
    lappend actions $i
  }
  set ::decide::acts $actions
  sleep::update::actions $actions
}

proc ::decide::commanded::location {} {
  set ::decide::path [::recall::location]
  return [::decide::actions::do]
}

proc ::decide::commanded::guess {} {
  if {$::decide::explore eq "curious"} {
    set ::decide::path [::recall::curious   $::memorize::input $::decide::acts]
    if {$::decide::path eq "_"} {
      set ::decide::path [::recall::guess   $::memorize::input $::decide::acts]
    }
  }
  if {$::decide::explore eq "random"} {
    set ::decide::path [::recall::guess   $::memorize::input $::decide::acts]
  }
  return [::decide::actions::do]
}

proc ::decide::commanded::find msg {
  ::decide::commanded::stop
  set ::decide::goal [::see::message $msg]
  return [::decide::commanded::single $msg]
}

proc ::decide::commanded::single msg {
  # old way
  #set path [::recall::main $::memorize::input $::decide::goal]

  # new way - calls the old way when necessary
  #set path [::recall::roots::path::find $::memorize::input $::decide::goal] # not this one, this one is if we know the goal is in main, but we may have to generalize first...
  set path [::recall::roots $::decide::goal]

  set ::decide::path $path
  return [::decide::commanded::goal $msg]
}

proc ::decide::commanded::goal msg {
  if {[lindex $::decide::path 0] eq "_"} {
    set goal [lindex $::decide::path 1]
    set ::decide::path [lrange $::decide::path 2 end]
  } else {
    set goal $::decide::goal
  }
  return [::decide::actions::do]
}


################################################################################################################################################################
# environment #########################################################################################################################################################
################################################################################################################################################################

proc ::decide::action {msg} {
  if {$::decide::explore eq "curious" && $::decide::goal ne ""} {
    if {$::memorize::input eq $::decide::goal} {
      set ::decide::goal ""
      set ::decide::path [::recall::guess   $::memorize::input $::decide::acts]
    }
    return [::decide::actions::do]
  } elseif {$::decide::explore eq "curious"} {

    return [::decide::commanded::guess]
  } elseif {$::decide::explore eq "random"} {

    set ::decide::path [::recall::guess   $::memorize::input $::decide::acts]
    return [::decide::actions::do]
  } elseif {$::decide::explore eq "roots"} {

    set ::decide::path [::recall::roots::path::finding $::memorize::input [::recall::roots::nextCandidate]]
    return [::decide::actions::do]
  } elseif {$::decide::path ne ""} {

    if {$::memorize::input eq $::decide::goal} {
      set ::decide::goal ""
      ::decide::commanded::stop
    } else {
      return [::decide::actions::do]
    }
  } elseif {$::decide::goal eq ""} {
  } else {
    if {$::decide::path eq ""} { ;# we have no path, try to make one.
      if {$::memorize::input eq $::decide::goal} {
        set ::decide::goal ""
        ::decide::commanded::stop
      } else {
        if {[::decide::help::shouldWeChain?]} {
          set path [::recall::main $::memorize::input $::decide::goal]
          set ::decide::path $path
        } else {
          set ::decide::path [::recall::guess   $::memorize::input $::decide::acts]
        }
        return [::decide::actions::do]
      }
    } elseif {$::decide::path eq "_"} { ;# we can't find a path try to intuit one.
      #####   NOT PROGRAMMED YET   #####
    } else { ;# follow it the path we're on.
      return [::decide::actions::do]
    }
  }
}


################################################################################################################################################################
# helpers #########################################################################################################################################################
################################################################################################################################################################


proc ::decide::help::shouldWeChain? {} {
  if {$::memorize::input  eq  $::decide::goal } { return no }
  if {$::memorize::input  eq  {}              } { return no }
  if {$::decide::goal     eq  {}              } { return no }
  if {[::decide::help::weHaveActions?]        } { return no }
  return yes
}

proc ::decide::help::weHaveActions? {} {
  if {[llength $::decide::path] < 1} { return no }
  return yes
}


################################################################################################################################################################
# ACTIONS ######################################################################################################################################################
################################################################################################################################################################


# pops the first action off the acionlist and returns it.
proc ::decide::actions::do {} {
  if {[lsearch $::decide::path "_"] ne "-1" || $::decide::path eq ""} {
    set ::decide::path [::recall::guess $::memorize::input $::decide::acts]
  }
  set ::decide::path [string map {\{ "" \} ""} $::decide::path ]
  set act [lindex $::decide::path 0]
  set ::memorize::act $act
  set ::decide::path [lrange $::decide::path 1 [expr [llength $::decide::path ]-1]]
  return $act
}
