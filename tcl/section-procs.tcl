# packages/dotlrn-ecommerce/tcl/section-procs.tcl

ad_library {
    
    Library procs for sections
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-12
    @arch-tag: 049a1d42-ebfc-4c90-98ae-11381703dc6d
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce::section {}

ad_proc -public dotlrn_ecommerce::section::instructors {
    community_id
    instructors
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @param community_id

    @param instructors

    @return 
    
    @error 
} {
    set instructor_string [join $instructors ,]
    if { ![empty_string_p $instructor_string] } {
    	return [db_list instructors { }]
    } else {
	return ""
    }
}

ad_proc -public dotlrn_ecommerce::section::section_grades {
    community_id
    grade_tree_id
    {locale en_US}
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @return 
    
    @error 
} {
    return [db_list section_grades { }]
}

ad_proc -public dotlrn_ecommerce::section::course_grades {
    item_id
    grade_tree_id
    {locale en_US}
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @return 
    
    @error 
} {
    return [db_list course_grades { }]
}

ad_proc -public dotlrn_ecommerce::section::sessions {
    calendar_id
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @return 
    
    @error 
} {
    if { ! [db_0or1row session_type {  }] } {
	set item_type_id [calendar::item_type_new -calendar_id $calendar_id -type "Session"]
    }
    set text_sessions [list]
    array set arr_sessions [list]
    db_foreach sessions { } {
	lappend arr_sessions(${month}_${timestart}_${timeend}_${startampm}_${endampm}) $day
    }

    set days [list]
    foreach times [array names arr_sessions] {
	set times [split $times _]
	set month [lindex $times 0]
	set start [lindex $times 1]
	set end [lindex $times 2]
	set startampm [lindex $times 3]
	set endampm [lindex $times 4]

	set _sessions $arr_sessions(${month}_${start}_${end}_${startampm}_${endampm})

	set _days [list]
	foreach day $_sessions {
	    # if there's a better way to do this please tell me :)
	    lappend days_${start}_${end}_${startampm}_${endampm} [expr 1${day} - 100]
	    
	    if { [lsearch $_days ${start}_${end}_${startampm}_${endampm}] == -1 } {
		lappend _days ${start}_${end}_${startampm}_${endampm}
	    }
	}
	foreach times $_days {
	    set times [split $times _]
	    set start [lindex $times 0]
	    set end [lindex $times 1]
	    set startampm [lindex $times 2]
	    set endampm [lindex $times 3]

	    if { $startampm == $endampm } {
		set time "${start}-${end}${startampm}"
	    } else {
		set time "${start}${startampm}-${end}${endampm}"
	    }

	    lappend text_sessions "$month [join [lsort -integer [set days_${start}_${end}_${startampm}_${endampm}]] ,] $time"
	}
    }

    set sessions [join $text_sessions ",<br />"]

    return $sessions
}

ad_proc -public dotlrn_ecommerce::section::flush_cache {
    section_id
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @param section_id

    @return 
    
    @error 
} {
    db_1row section_info {
	select community_id, course_id as item_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }
    set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
    set _instructors [dotlrn_community::list_users $instructor_community_id]
    set __instructors [list]
    if { [llength $_instructors] == 0 } {
	set _instructors 0
    } else {
	foreach instructor $_instructors {
	    lappend __instructors [ns_set get $instructor user_id]
	}
    }
    set grade_tree_id [db_string grade_tree {
	select tree_id
	from category_tree_translations 
	where name = 'Grade'
    } -default 0]
    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]

    # Start flushing
    set section_grades [util_memoize_flush [list dotlrn_ecommerce::section::section_grades $community_id $grade_tree_id]]
    set course_grades [util_memoize_flush [list dotlrn_ecommerce::section::course_grades $item_id $grade_tree_id]]
    set sessions [util_memoize_flush [list dotlrn_ecommerce::section::sessions $calendar_id]]
    set instructors [util_memoize_flush [list dotlrn_ecommerce::section::instructors $community_id $__instructors]]
}
