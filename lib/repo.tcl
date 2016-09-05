package provide repo 1.0

package require sqlite3

namespace eval ::repo {}
namespace eval ::repo::insert {}
namespace eval ::repo::update {}
namespace eval ::repo::delete {}
namespace eval ::repo::get {}
namespace eval ::repo::helpers {}


################################################################################################################################################################
# create #########################################################################################################################################################
################################################################################################################################################################


proc ::repo::create {id {datas ""} } {
	file mkdir brain
	sqlite3 brain "./brain/$id.sqlite" -create true
  brain eval { create table if not exists setup(
                                                      type char,
                                                      data char) }
  brain eval { create table if not exists main(
																											time char,
                                                      input char,
                                                      action char,
                                                      result char) }
	brain eval { create table if not exists chains(
																											time char,
                                                      input char,
                                                      action char,
                                                      result char,
																											last_used int,
																											times_used int) }
	brain eval { create table if not exists bad(
																											time char,
                                                      input char,
                                                      action char,
                                                      result char) }
	brain eval { create table if not exists rules(
																											rule char,
	                                                    type char,
																											mainids char) }
	brain eval { create table if not exists predictions(
																											input char,
	                                                    action char,
																											result char,
																											ruleid char) }
	brain eval { create table if not exists nodes(
																											node int,
																											input char,
																											ix char,
																											type char) }
	brain eval { create table if not exists connectom(
																											cellid char,
																											cell char) }
}

################################################################################################################################################################
# insert #########################################################################################################################################################
################################################################################################################################################################


#data is a dictionary - column, data
proc ::repo::insert {table datas} {
	if [dict exists $datas action] {
		set action [dict get $datas action]
		if {[llength $action] > 1 } {
			set action [lrange $action 0 [expr [llength $action]-1] ]
		}
	}
	if [dict exists $datas time				]	{ set time 				[dict get $datas time				] }
	if [dict exists $datas type				]	{ set type 				[dict get $datas type				]	}
	if [dict exists $datas data				] { set data 				[dict get $datas data				]	}
	if [dict exists $datas input			]	{ set input 			[dict get $datas input			]	}
	if [dict exists $datas result			]	{ set result 			[dict get $datas result			]	}
	if [dict exists $datas last_used	] {	set last_used 	[dict get $datas last_used	]	}
	if [dict exists $datas times_used	] { set times_used 	[dict get $datas times_used	]	}
	if [dict exists $datas rule				]	{ set rule 				[dict get $datas rule				]	}
	if [dict exists $datas ruleid			]	{	set ruleid 			[dict get $datas ruleid			] }
	if [dict exists $datas mainids		] {	set mainids 		[dict get $datas mainids		] }
	if [dict exists $datas node				]	{	set node 				[dict get $datas node				] }
	if [dict exists $datas ix					]	{	set ix 					[dict get $datas ix					] }
	if [dict exists $datas cellid			]	{	set cellid 			[dict get $datas cellid			] }
	if [dict exists $datas cell				]	{	set cell	 			[dict get $datas cell				] }
	switch $table {
		setup				{ brain eval {INSERT INTO setup 			VALUES ($type,$data)} }
		main 				{ brain eval {INSERT INTO main 				VALUES ($time,$input,$action,$result)} }
		uniq 				{ brain eval {INSERT INTO uniq 				VALUES ($time,$input,$action,$result)} }
		chains 			{ brain eval {INSERT INTO chains 			VALUES ($time,$input,$action,$result,$last_used,$times_used)} }
		bad 				{ brain eval {INSERT INTO bad 				VALUES ($time,$input,$action,$result)} }
		rules 			{ brain eval {INSERT INTO rules 			VALUES ($rule,$type,$mainids)} }
		predictions { brain eval {INSERT INTO predictions VALUES ($input,$action,$result,$ruleid)}	}
		nodes 				{ brain eval {INSERT INTO nodes	 		VALUES ($node,$input,$ix,$type)} }
		connectom		{ brain eval {INSERT INTO connectom 	VALUES ($cellid,$cell)} }
		default 		{ return "No data saved, please supply valid table name." }
	}
}


################################################################################################################################################################
# update #########################################################################################################################################################
################################################################################################################################################################


#generic update for updating anything (only 1 table. column is always 'perm')
proc ::repo::update::onId {table column data id} {
	brain eval "UPDATE '$table' SET '$column'='$data' WHERE rowid='$id'"
}

proc ::repo::update::cell {id cell} {
	brain eval "UPDATE connectom SET 'cell'='$cell' WHERE cellid='$id'"
}
proc ::repo::update::cellid {newid id} {
	brain eval "UPDATE connectom SET 'cellid'='$newid' WHERE cellid='$id'"
}
proc ::repo::update::node {table column data id} {
	brain eval "UPDATE node SET '$column'='$data' WHERE node='$id'"
}

################################################################################################################################################################
# Get #########################################################################################################################################################
################################################################################################################################################################

#can be used to get connections of cells or connections of bits and columns.
#table, one, two, perm are strings | columns, ones, twos are all lists.
#make perm = 0 to get all connections

proc ::repo::get::actions {} {
	return [brain eval "SELECT rule FROM rules WHERE type='available actions'"]
}

proc ::repo::get::tableColumns {table cols} {
	set csv ""
	foreach col $cols {
		if {$csv eq ""} {
			set csv "$col"
		} else {
			set csv "$csv,$col"
		}
	}
	return [brain eval "SELECT $csv FROM $table"]
}

proc ::repo::get::tableColumnsWhere {table cols where} {
	set csv ""
	foreach col $cols {
		if {$csv eq ""} {
			set csv "$col"
		} else {
			set csv "$csv,$col"
		}
	}
	set csv2 ""
	foreach key [dict keys $where] {
		if {$csv2 eq ""} {
			set csv2 "$key='[dict get $where $key]'"
		} else {
			set csv2 "$csv2 AND $key='[dict get $where $key]'"
		}
	}
	return [brain eval "SELECT $csv FROM $table WHERE $csv2"]
}

proc ::repo::get::allMatch {table input action result} {
	return [brain eval "SELECT input,action,result FROM $table WHERE input='$input' AND result='$result' AND action='$action'"]
}

proc ::repo::get::randomSet {} {
	return [brain eval "SELECT input,action,result FROM main ORDER BY RANDOM() LIMIT 1"]
}

proc ::repo::get::actMatch {table input result} {
	return [brain eval "SELECT action FROM $table WHERE input='$input' AND result='$result'"]
}

proc ::repo::get::chain {table column result} {
		return [brain eval "SELECT $column FROM $table WHERE result='$result'"]
}

proc ::repo::get::chainMatch {table mod thelist} {
	set newlist ""
	foreach item $thelist {
		if {$newlist ne ""} { set newlist "$newlist OR" }
		set newlist "$newlist $mod='$item'"
	}
	return [brain eval "SELECT input,action,result FROM $table WHERE $newlist"]
}

proc ::repo::get::chainActions {input result} {
	return [brain eval "SELECT action FROM chains WHERE input='$input' AND result='$result'"]
}

proc ::repo::get::actsDoneHere {input} {
	set a [brain eval "SELECT action FROM bad WHERE input='$input'"]
	set b [brain eval "SELECT action FROM main WHERE input='$input'"]
	return "$a $b"
}

proc ::repo::get::maxAction {} {
	return [brain eval "SELECT max(action) FROM main"]
}

proc ::repo::get::minAction {} {
	return [brain eval "SELECT min(action) FROM bad"]
}

proc ::repo::get::nodeMatch {input index type} {
	return [brain eval "SELECT node FROM nodes WHERE input='$input' AND ix='$index' AND type='$type'"]
}

proc ::repo::get::maxNode {} {
	return [brain eval "SELECT max(node) FROM nodes"]
}

proc ::repo::get::nodeTable {} {
	return [brain eval "SELECT node,input,ix,type FROM nodes"]
}

proc ::repo::get::connectom {} {
	return [brain eval "SELECT cellid,cell FROM connectom"]
}

proc ::repo::get::cell {cellid} {
	return [brain eval "SELECT cell FROM connectom WHERE cellid='$cellid'"]
}


################################################################################
# Like #########################################################################
################################################################################

#select * from uniq WHERE input like '_0_'
proc ::repo::get::byResultsLike {table result} {
	puts $table$result
	return [brain eval "SELECT DISTINCT result FROM $table WHERE result LIKE '$result'"]
}

################################################################################################################################################################
# Delete #########################################################################################################################################################
################################################################################################################################################################

proc ::repo::delete::rowsTableColumnValue {table col value} {
	return [brain eval "DELETE FROM $table WHERE $col='$value'"]
}

################################################################################################################################################################
# Help #########################################################################################################################################################
################################################################################################################################################################
