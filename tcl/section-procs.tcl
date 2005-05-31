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
    return [db_list instructors [subst {
	select u.first_names||' '||u.last_name
	from dotlrn_users u, dotlrn_member_rels_approved r
	where u.user_id = r.user_id
	and r.community_id = :community_id
	and r.rel_type = 'dotlrn_admin_rel'
	and r.user_id in ([join $instructors ,])
    }]]
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
    return [db_list section_grades {
	select t.name
	from category_object_map_tree m, category_translations t
	where t.category_id = m.category_id
	and t.locale = coalesce(:locale, 'en_US')
	and m.object_id = :community_id
	and m.tree_id = :grade_tree_id
    }]
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
    return [db_list course_grades {
	select distinct t.name
	from category_object_map_tree m, category_translations t
	where t.category_id = m.category_id
	and t.locale = coalesce(:locale, 'en_US')
	and m.object_id in (select community_id
			    from dotlrn_ecommerce_section
			    where course_id = :item_id)
	and m.tree_id = :grade_tree_id
    }]
}

ad_proc -public dotlrn_ecommerce::section::sessions {
    calendar_id
} {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @return 
    
    @error 
} {
    if { ! [db_0or1row session_type {
	select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1
    }] } {
	set item_type_id [calendar::item_type_new -calendar_id $calendar_id -type "Session"]
    }
    set text_sessions [list]
    array set arr_sessions [list]
    db_foreach sessions {
	select distinct to_char(start_date, 'Mon') as month, to_char(start_date, 'dd') as day, to_char(start_date, 'hh:mi') as start, to_char(end_date, 'hh:mi') as end, to_char(start_date, 'am') as startampm, to_char(end_date, 'am') as endampm
	from cal_items ci, acs_events e, acs_activities a, timespans s, time_intervals t
	where e.timespan_id = s.timespan_id
	and s.interval_id = t.interval_id
	and e.activity_id = a.activity_id
	and e.event_id = ci.cal_item_id
	and start_date >= current_date

	and ci.on_which_calendar = :calendar_id
	and ci.item_type_id = :item_type_id
    } {
	lappend arr_sessions($month) [list $day $start $end $startampm $endampm]
    }

    set days [list]
    foreach month [array names arr_sessions] {
	set _sessions $arr_sessions($month)

	foreach day $_sessions {
	    # if there's a better way to do this please tell me :)
	    lappend days [expr 1[lindex $day 0] - 100]
	}
	if { [lindex $day 3] == [lindex $day 4] } {
	    set time "[lindex $day 1]-[lindex $day 2][lindex $day 3]"
	} else {
	    set time "[lindex $day 1][lindex $day 3]-[lindex $day 2][lindex $day 4]"
	}
	lappend text_sessions "$month [join [lsort -integer $days] ,] $time"
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
