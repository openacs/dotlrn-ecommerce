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
    	return [db_list_of_lists instructors { }]
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
	    lappend days_${month}_${start}_${end}_${startampm}_${endampm} [expr 1${day} - 100]
	    
	    if { [lsearch $_days ${month}_${start}_${end}_${startampm}_${endampm}] == -1 } {
		lappend _days ${month}_${start}_${end}_${startampm}_${endampm}
	    }
	}
	foreach times $_days {
	    set times [split $times _]
	    set month [lindex $times 0]
	    set start [lindex $times 1]
	    set end [lindex $times 2]
	    set startampm [lindex $times 3]
	    set endampm [lindex $times 4]

	    if { $startampm == $endampm } {
		set time "${start}-${end}${startampm}"
	    } else {
		set time "${start}${startampm}-${end}${endampm}"
	    }

	    lappend text_sessions "$month [join [lsort -integer [set days_${month}_${start}_${end}_${startampm}_${endampm}]] ,] $time"
	}
    }

    set sessions [join $text_sessions ",<br />"]

    return $sessions
}

ad_proc -public dotlrn_ecommerce::section::flush_cache {
    -user_id 
    section_id
} {
    Flush cached procs
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-20
    
    @param section_id

    @return 
    
    @error 
} {
    db_1row section_info {
	select community_id, course_id as item_id, product_id
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
    set grade_tree_id [parameter::get -package_id [ad_conn package_id] -parameter GradeCategoryTree -default 0]
    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]

    # Start flushing
    util_memoize_flush [list dotlrn_ecommerce::section::section_grades $community_id $grade_tree_id]
    util_memoize_flush [list dotlrn_ecommerce::section::course_grades $item_id $grade_tree_id]
    util_memoize_flush [list dotlrn_ecommerce::section::sessions $calendar_id]
    util_memoize_flush [list dotlrn_ecommerce::section::instructors $community_id $__instructors]
    util_memoize_flush [list dotlrn_ecommerce::section::attendees $section_id]
    util_memoize_flush [list dotlrn_ecommerce::section::price $section_id]
    util_memoize_flush [list dotlrn_ecommerce::section::member_price $section_id]
    util_memoize_flush [list dotlrn_ecommerce::section::application_assessment $section_id]
    util_memoize_flush [list dotlrn_ecommerce::section::section_zones $community_id]
    util_memoize_flush [list dotlrn_ecommerce::section::has_discount_p $product_id]
    if { [exists_and_not_null user_id] } {
	util_memoize_flush [list dotlrn_ecommerce::section::member_state $user_id $community_id]
	util_memoize_flush [list dotlrn_ecommerce::section::waiting_list_number $user_id $community_id]
    }
}

ad_proc -public dotlrn_ecommerce::section::maxparticipants {
    section_id
} {
    Return maximum section participants
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-06
    
    @param section_id

    @return 
    
    @error 
} {
    return [db_string maxparticipants {
	select v.maxparticipants
	from dotlrn_ecommerce_section s, ec_custom_product_field_values v, dotlrn_catalogi c, cr_items ci
	where s.product_id = v.product_id
	and s.section_id = :section_id
	and s.course_id = c.item_id
	and ci.live_revision = c.revision_id
    } -default ""]
}

ad_proc -public dotlrn_ecommerce::section::available_slots {
    -actual:boolean
    section_id
} {
    Return available slots
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-06
    
    @param section_id

    @param section_id

    @return 
    
    @error 
} {
    set maxparticipants ""
    set available_slots 0
    db_0or1row participants {
	select v.maxparticipants, s.community_id, s.section_name, c.course_name
	from dotlrn_ecommerce_section s, ec_custom_product_field_values v, dotlrn_catalogi c, cr_items ci
	where s.product_id = v.product_id
	and s.section_id = :section_id
	and s.course_id = c.item_id
	and ci.live_revision = c.revision_id
    }

    if { ![empty_string_p $maxparticipants] } {
	if { $actual_p } {
	    set attendees [dotlrn_ecommerce::section::attendees -actual $section_id]
	} else {
	    set attendees [dotlrn_ecommerce::section::attendees $section_id]
	}
	set available_slots [expr $maxparticipants - $attendees]
	if { $available_slots < 0 } {
	    return 0
	} else {
	    return $available_slots
	}
    }

    return ""
}

ad_proc -public dotlrn_ecommerce::section::attendees {
    -actual:boolean
    section_id
} {
    Return number of attendees
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-14
    
    @param section_id

    @return 
    
    @error 
} {
    # Count items in shopping cart
    set registered_attendees [db_string attendees [subst {
	select (select count(*)
	from dotlrn_member_rels_full
	where community_id = (select community_id
			      from dotlrn_ecommerce_section
			      where section_id = :section_id)
	and (rel_type = 'dotlrn_member_rel' or rel_type = 'dc_student_rel')
	and member_state in ('approved', 'request approval', 'request approved', 'waitinglist approved', 'payment received')) 

	+ 

	(select count(*)
	 from ec_orders o, ec_items i, dotlrn_ecommerce_section s
	 where o.order_id = i.order_id
	 and i.product_id = s.product_id
	 and s.section_id = :section_id
	 and o.order_state = 'in_basket')
    }]]

    if { $actual_p } {
	return $registered_attendees
    }

    set maxparticipants [dotlrn_ecommerce::section::maxparticipants $section_id]
    if { ! [empty_string_p $maxparticipants] } {
	set actual_open_slots [expr $maxparticipants - $registered_attendees]
	
	if { $actual_open_slots > 0 } {
	    incr registered_attendees [db_string in_waiting_list [subst {
		select count(*) 
		from (select *
		      from dotlrn_member_rels_full
		      where community_id = (select community_id
					    from dotlrn_ecommerce_section
					    where section_id = :section_id)
		      and (rel_type = 'dotlrn_member_rel' or rel_type = 'dc_student_rel')
		      and member_state = 'needs approval'
		      limit $actual_open_slots) u
	    }] -default 0]
	}

	return $registered_attendees
    } else {
	return $registered_attendees
    }
}

ad_proc -public dotlrn_ecommerce::section::check_elapsed_registrations {
} {
    Check registrations

    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-14
    
    @return 
    
    @error 
} {
    set time_period [parameter::get -package_id [apm_package_id_from_key dotlrn-ecommerce] -parameter ApprovedRegistrationTimePeriod -default 86400]

    db_foreach check_applications {
	select community_id, user_id
	from acs_objects o, dotlrn_member_rels_full r
	where o.object_id = r.rel_id
	and (current_timestamp - o.last_modified)::interval >= (:time_period||' seconds')::interval
	and r.member_state in ('request approved', 'waitinglist approved', 'payment received')
    } {
	dotlrn_community::membership_reject -community_id $community_id -user_id $user_id
    }
}

ad_proc -public dotlrn_ecommerce::section::approve_next_in_waiting_list {
    community_id
} {
    Approve people in waiting list if slot becomes available
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-14
    
    @return 
    
    @error 
} {
    set section_id [db_string section {
	select section_id
	from dotlrn_ecommerce_section
	where community_id = :community_id
    }]
    set available_slots [dotlrn_ecommerce::section::available_slots -actual $section_id]

    if { $available_slots > 0 } {
	db_foreach next_in_waiting_list [subst {
	    select pretty_name as community_name, person__name(r.user_id) as person_name, r.user_id, p.email
	    from acs_objects o, dotlrn_member_rels_full r, dotlrn_communities_all c, parties p
	    where o.object_id = r.rel_id
	    and r.community_id = c.community_id
	    and r.user_id = p.party_id
	    and member_state = 'needs approval'
	    and r.community_id = :community_id

	    order by o.creation_date
	    limit $available_slots
	}] {
	    set admin_email [parameter::get -package_id [ad_acs_kernel_id] -parameter AdminOwner]

	    db_dml approve_request {
		update membership_rels
		set member_state = 'waitinglist approved'
		where rel_id in (select r.rel_id
				 from acs_rels r,
				 membership_rels m
				 where r.rel_id = m.rel_id
				 and r.object_id_one = :community_id
				 and r.object_id_two = :user_id
				 and m.member_state = 'needs approval')
	    }

	    acs_mail_lite::send \
		-to_addr $email \
		-from_addr $admin_email \
		-subject "[subst [_ dotlrn-ecommerce.lt_A_space_has_opened_up]]" \
		-body "[subst [_ dotlrn-ecommerce.lt_A_space_has_opened_up_1]]"
	}
    }
}

ad_proc -public dotlrn_ecommerce::section::check_and_approve_sections_for_slots {
} {
    Check all sections for opened slots
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-14
    
    @return 
    
    @error 
} {
    db_foreach sections {
	select community_id
	from dotlrn_ecommerce_section
    } {
	ns_log notice "DEBUG:: Checking community $community_id for open slots"
	dotlrn_ecommerce::section::approve_next_in_waiting_list $community_id
	ns_log notice "DEBUG:: Done check"
    }
}

ad_proc -public dotlrn_ecommerce::section::application_assessment {
    section_id
} {
    Return application assessment
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-20
    
    @param community_id

    @return 
    
    @error 
} {
    return [db_string get_assessment {
	select c.assessment_id

	from dotlrn_ecommerce_section s,
	dotlrn_catalogi c,
	cr_items i

	where s.course_id = c.item_id
	and c.item_id = i.item_id
	and i.live_revision = c.course_id
	and s.section_id = :section_id

	limit 1
    } -default ""]
}

ad_proc -public dotlrn_ecommerce::section::get_public_folder_id {
    section_id
} {
    @param section_id 
    @return the file storage folder for the section's Public Files
} {
    return [util_memoize [list dotlrn_ecommerce::section::get_public_folder_id_not_cached $section_id]]
}

ad_proc -private dotlrn_ecommerce::section::get_public_folder_id_not_cached {
    section_id
} {
    @param section_id 
    @return the file storage folder for the section's Public Files
} {
    set section_package_id [db_string get_package_id "select package_id from dotlrn_communities_all dc, dotlrn_ecommerce_section ds where ds.community_id=dc.community_id and ds.section_id=:section_id" -default 0]    
    set section_community_node_id [site_node::get_node_id_from_object_id -object_id $section_package_id]
    set fs_package_id [site_node::get_children -node_id $section_community_node_id -package_key file-storage -element package_id]
    set fs_root_folder [fs::get_root_folder -package_id $fs_package_id]
    set section_folder_id [content::item::get_id -root_folder_id $fs_root_folder -item_path "public"]
    return $section_folder_id
}

ad_proc -public dotlrn_ecommerce::section::price {
    section_id
} {
    Return Section's price
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    
    @param section_id

    @return 
    
    @error 
} {
    return [db_string price {
	select price as prices
	from ec_products
	where product_id = (select product_id
			    from dotlrn_ecommerce_section
			    where section_id = :section_id)
    } -default 0]

}

ad_proc -public dotlrn_ecommerce::section::member_price {
    section_id
} {
    Return Section's member price
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    
    @param section_id

    @return 
    
    @error 
} {
    return [db_string member_price {
	select sale_price as member_price
	from ec_sale_prices
	where product_id = (select product_id
			    from dotlrn_ecommerce_section
			    where section_id = :section_id)
	limit 1
    } -default 0]
}

ad_proc -public dotlrn_ecommerce::section::member_state {
    user_id
    community_id
} {
    Return member state
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    
    @param user_id

    @param community_id

    @return 
    
    @error 
} {
    return [db_string member_state {
	select m.member_state
	from acs_rels r,
	membership_rels m
	where r.rel_id = m.rel_id
	and r.object_id_one = :community_id
	and r.object_id_two = :user_id
	limit 1
    } -default ""]
}

ad_proc -public dotlrn_ecommerce::section::fs_chunk {
    section_id
} {
    File storage includelet for caching
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    
    @param section_id

    @return 
    
    @error 
} {
    set section_folder_id [dotlrn_ecommerce::section::get_public_folder_id $section_id]
    set section_pages_url "pages/${section_id}/"
    set __adp_stub ""
    
    return [eval [template::adp_compile -string [subst {
	<include-optional src="/packages/file-storage/lib/folder-links" folder_id="$section_folder_id" base_url="$section_pages_url">
	<strong>\#dotlrn-ecommerce.More_Information\#</strong><br />
	<include-output>
	</include-optional>
    }]]]
}

ad_proc -public dotlrn_ecommerce::section::waiting_list_number {
    user_id
    community_id
} {
    Return number in waiting list
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-25
    
    @param user_id

    @param community_id

    @return 
    
    @error 
} {
    return [db_string waitin_list_number {
	select count(*)
	from (select *
	      from dotlrn_member_rels_full rr,
		      acs_objects o
	      where rr.rel_id = o.object_id
	      and rr.rel_id <= (select rel_id
				from dotlrn_member_rels_full
				where community_id = :community_id
				and user_id = :user_id)
	      and rr.community_id = :community_id
	      and rr.member_state = 'needs approval'
	      order by o.creation_date) r
    } -default ""]
}

ad_proc -public dotlrn_ecommerce::section::section_zones {
    community_id
} {
    Return zones
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-05
    
    @param section_id

    @return 
    
    @error 
} {
    set locale [ad_conn locale]

    if { [db_0or1row zone {
	select tree_id as zone_tree_id
	from category_tree_translations
	where name = 'Location'
	and locale = :locale
	limit 1
    }] } {
	return [db_list section_zones { }]    
    }

    return [list]
}

ad_proc -public dotlrn_ecommerce::section::check_expired_orders {
} {
    Check recently expired orders in shopping cart and flush the cache
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-18
    
    @return 
    
    @error 
} {
    # Loop thru recently expired orders
    db_foreach expired_orders {
	select order_id
	from ec_orders
	where order_state = 'expired'
	and expired_date > (current_timestamp - '10 minutes'::interval)
    } {
	# Loop thru recently expired items, and flush the cached section
	db_foreach expired_items {
	    select s.section_id
	    from ec_items i, dotlrn_ecommerce_section s
	    where i.product_id = s.product_id
	    and order_state = 'expired'
	    and expired_date > (current_timestamp - '10 minutes'::interval)
	} {
	    util_memoize_flush [list dotlrn_ecommerce::section::attendees $section_id]	    
	}
    }
}

ad_proc -public dotlrn_ecommerce::section::check_expired_orders_once {
} {
    Reschedule checking of expired orders
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-18
    
    @return 
    
    @error 
} {
    dotlrn_ecommerce::section::check_expired_orders

    ad_schedule_proc -thread t 600 dotlrn_ecommerce::section::check_expired_orders
}

ad_proc -public dotlrn_ecommerce::section::has_discount_p {
    product_id
} {
    Check if there's a current promotion for the product
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-20
    
    @return 
    
    @error 
} {
    return [db_string discount_codes {
	select count(*)
	from ec_sale_prices_current
	where product_id=:product_id
    } -default 0]
}
