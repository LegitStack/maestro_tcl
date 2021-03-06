
namespace eval ::prepdata {}
namespace eval ::prepdata::helpers {}


proc ::prepdata::randompick list {
  lindex $list [expr {int(rand()*[llength $list])}]
}

# returns a list of the least common elements in a list that has multiple of
# the same elements, as long as each item in the list isn't duplicated the
# same number of times.
proc ::prepdata::leastcommon list {
  set counts  {}
  set low     {}
  set high    {}
  foreach element $list {
    if {![dict exists $counts $element]} {
      set count [llength [lsearch -all $list $element]]
      if {$count < $low  || $low  eq ""} { set low  $count }
      if {$count > $high || $high eq ""} { set high $count }
      dict set counts $element $count
    }
  }
  set list {}
  foreach key [dict keys $counts] {
    if {[dict get $counts $key] == $low} {
      lappend list $key
    }
  }
  if {$high != $low} { return $list } else { return "_"}
}

# combination of each item in a group.
# example: 1 {a b} 2 {c} 3 {d e}
# returns: {a c d} {a c e} {b c d} {b c e}
proc ::prepdata::getDictCombos dictionary {
  return [combineEachElement {*}[dict values $dictionary]]
}

proc ::prepdata::combineEachElement args {
  set xs {{}}
  foreach ys $args {
    set result {}
    foreach x $xs {
      foreach y $ys {
        lappend result [list {*}$x $y]
      }
    }
    set xs $result
  }
  return $xs
}


proc ::prepdata::lsum {list} {
  set total 0.0
  foreach nxt $list {
    set total [expr {$total + $nxt}]
  }
  return $total
}



## combinations input as word
#
# Given a word, it will return a list of words; each is a unique combination
# of the bits, not in order but either present or not present. removes Blank.
#
# example:  abc
# returns:  abc ab_ a_c a__ _bc _b_ __c
#
proc ::prepdata::combinations input {
  set input [split $input ""]
  set x 0
  set goodlist ""
  set len [llength $input]
  while {$x <= [expr 2**$len]} {
    set bin [::prepdata::helpers::addLeadingZeros [::prepdata::helpers::decimalToBin $x] $input]
    set n 0
    foreach a $input b [split $bin ""] {
      if {$b eq 0 } {
        set goodlist "$goodlist$a"
      } else {
        set goodlist "$goodlist\_"
      }
    }
    set goodlist "$goodlist "
    incr x
  }
  #remove duplicates:
  set goodlist [lsort -unique $goodlist]
  #remove all blanks - not necessary

  return [lrange [::prepdata::helpers::reorder [string trim $goodlist]] 0 [expr [llength $goodlist] - 2]]
}

## scoreByMatch original as word, goal as word
#
# counts up the number of matches in the thing and returns that number.
#
# example:  0j pj
# returns:  1
#
proc ::prepdata::scoreByMatch {original goal} {
  set myscore 0
  foreach a [split $goal ""] b [split $original ""] {
    if {$a eq $b} {
      incr myscore
    }
  }
  return $myscore
}



proc ::prepdata::substitute {original goal} {
  set c ""
  foreach a [split $original ""] b [split $goal ""] {
    if {$a eq "_"} {
      if {$b ne ""} {
        lappend c $b
      }
    } else {
      if {$a ne ""} {
        lappend c $a
      }
    }
  }
  return [string map {" " ""} $c]
}


proc ::prepdata::lsubstitute {originallist goal} {
  set fixedlist ""
  foreach original $originallist {
    lappend fixedlist [::prepdata::substitute $original $goal]
  }
  return $fixedlist
}



## decimalToBin x as decimal number
#
# returns x converted to a binary number
#
# example:  5
# returns:  101
#
proc ::prepdata::helpers::decimalToBin x {
  if {[string index $x 0] eq {-}} {
      set sign -
      set x [string range $x 1 end]
  } else {
      set sign {}
  }
  return $sign[string trimleft [string map {
  0 {000} 1 {001} 2 {010} 3 {011} 4 {100} 5 {101} 6 {110} 7 {111}
  } [format %o $x]] 0]
}

## addLeadingZeros bin as word, stuff as word
#
# gets bin and adds 0's to the front of it till it matches the length of
# stuff. returns the number
#
# example:  10 abcd
# returns:  0010
#
proc ::prepdata::helpers::addLeadingZeros {bin stuff} {
  set lz [expr [llength $stuff] - [string length $bin]]
  set x 0
  while {$x < $lz} {
    set bin "0$bin"
    incr x
  }
  return $bin
}

## reoder mylist as list
#
# gets list and reoders it putting all the
# returns a score depending on how well it matches up to the original.
#
# example:  000 111 09_ 10_
# returns:  47
#
proc ::prepdata::helpers::reorder glist {
  set i 0
  while {$i < [llength $glist]} {
    if {$i< [expr [llength $glist]-1]} {
      if {[scoreItem [lindex $glist $i]] < [scoreItem [lindex $glist [expr $i+1]]]} {
        #do nothing, they're in the right order.
      } elseif {[scoreItem [lindex $glist $i]] == [scoreItem [lindex $glist [expr $i+1]]]} {
        #randomly
        if {[expr round(rand() * (2-1))] == 1 } {
          #switch them so we don't always look for the same path
          #switch them, set back i to 0
          set glist [concat [lrange $glist 0 [expr $i-1]] \
                            [lindex $glist [expr $i+1]]   \
                            [lindex $glist $i]     \
                            [lrange $glist [expr $i+2] [expr [llength $glist]-1]]]
        }
      } elseif {[scoreItem [lindex $glist $i]] > [scoreItem [lindex $glist [expr $i+1]]]} {
        #switch them, set back i to 0
        set glist [concat [lrange $glist 0 [expr $i-1]] \
                          [lindex $glist [expr $i+1]]   \
                          [lindex $glist $i]     \
                          [lrange $glist [expr $i+2] [expr [llength $glist]-1]]]
        if {$i == 0} { set i -1 } else { set i [expr $i - 2] }
      }
    }
    incr i
  }
  return $glist
}



## reorderByUnderscore mylist as list
#
# example:  _00 111 ___ 09_ _1_
# returns:  111 _00 09_ _1_ ___
#
proc ::prepdata::helpers::reorderByUnderscore glist {
  set j 1
  while {$j < [llength $glist]} {
    set i 1
    set temp1 ""
    set temp2 ""
    set tempa ""
    set tempb ""
    while {$i < [llength $glist]} {
      set b [::prepdata::helpers::underscoreCount [lindex $glist $i]]
      set a [::prepdata::helpers::underscoreCount [lindex $glist [expr $i - 1]]]
      if {$b < $a } {
        set temp1 [lrange $glist 0 [expr $i - 2]]
        set temp2 [lrange $glist [expr $i + 1] end]
        set tempa [lindex $glist [expr $i - 1]]
        set tempb [lindex $glist $i]
        set glist [concat $temp1 $tempb $tempa $temp2]
      }
      incr i
    }
    incr j
  }
  return $glist
}

proc ::prepdata::helpers::underscoreCount s {
  return [expr {[llength [split $s "_"]] - 1}]
}


## reorderByMatch goals as list
#
# takes a list of potential goals and orders them based upon which goal is
# closest looking to our current input.
#
# example:  100 {925 310 101 020}
# returns:  {101 310 020 925}
#
proc ::prepdata::helpers::reorderByMatch {input goals} {
  set i 0
  while {$i < [llength $goals]} {
    if {$i< [expr [llength $goals]-1]} {
      if {[scoreByMatch $input [lindex $goals $i] ] < [scoreByMatch $input [lindex $goals [expr $i+1]]]} {
        #switch them, set back i to 0
        set goals [concat [lrange $goals 0 [expr $i-1]] \
                          [lindex $goals [expr $i+1]]   \
                          [lindex $goals $i]     \
                          [lrange $goals [expr $i+2] [expr [llength $goals]-1]]]
        if {$i == 0} { set i -1 } else { set i [expr $i - 2] }

      } elseif {[scoreByMatch $input [lindex $goals $i]] == [scoreByMatch $input [lindex $goals [expr $i+1]]]} {
        #randomly
        if {[expr round(rand() * (2-1))] == 1 } {
          #switch them so we don't always look for the same path
          #switch them, set back i to 0
          set goals [concat [lrange $goals 0 [expr $i-1]] \
                            [lindex $goals [expr $i+1]]   \
                            [lindex $goals $i]     \
                            [lrange $goals [expr $i+2] [expr [llength $goals]-1]]]
        }
      } elseif {[scoreByMatch $input [lindex $goals $i]] > [scoreByMatch $input [lindex $goals [expr $i+1]]]} {
        #do nothing, they're in the right order.
      }
    }
    incr i
  }
  return $goals
}

## scoreItem goal as word
#
# counts up the number of "_" in the thing and returns that number
#
# example:  0j_
# returns:  1
#
proc ::prepdata::helpers::scoreItem goal {
  set myscore 0
  foreach i [split $goal ""] {
    if {$i eq "_"} {
      incr myscore
    }
  }
  return $myscore
}


## scoreByMatch original as word, goal as word
#
# counts up the number of matches in the thing and returns that number.
#
# example:  0j pj
# returns:  1
#
proc ::prepdata::helpers::scoreByMatch {original goal} {
  set myscore 0
  foreach a [split $goal ""] b [split $original ""] {
    if {$a eq $b} {
      incr myscore
    }
  }
  return $myscore
}

#puts [::prepdata::helpers::reorderByMatch 100 {027 960 300 101 102 103}]
