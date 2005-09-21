# packages/dotlrn-ecommerce/tcl/implementation-procs.tcl

ad_library {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: 776140e1-a8e8-4d30-84a7-46d8bf054187
    @cvs-id $Id$
}

ad_proc -callback ecommerce::after-checkout -impl dotlrn-ecommerce {
    -user_id
    -order_id
    -patron_id
} {

} {
    # DEDS: for notifying when wait list notify reached
    set community_notify_waitlist_list [list]
    set checkout_user_id [ad_conn user_id]

    if { [exists_and_not_null patron_id] } {
	if { ! [dotlrn::user_p -user_id $patron_id] } {
	    dotlrn::user_add -user_id $patron_id
	}
    }

    db_foreach items_in_order {
	select i.product_id, o.patron_id as saved_patron_id, o.participant_id, t.method, v.maxparticipants, i.item_id
	from dotlrn_ecommerce_orders o, ec_items i left join dotlrn_ecommerce_transactions t
	on (i.order_id = t.order_id), ec_custom_product_field_values v
	where i.item_id = o.item_id
	and i.product_id = v.product_id
	and i.order_id = :order_id
	group by i.product_id, o.patron_id, o.participant_id, t.method, v.maxparticipants, i.item_id
    } {
	if { [empty_string_p $participant_id] } {
	    if { [exists_and_not_null user_id] } {
		set participant_id $user_id
	    } else {
		continue
	    }
	}

	# Check first if user_id is actually a group
	if { [acs_object_type $participant_id] == "group" } {
	    set user_ids [db_list group_members {
		select distinct object_id_two
		from acs_rels
		where object_id_one = :participant_id
		and rel_type = 'membership_rel'
	    }]
	    ns_log notice "dotlrn-ecommerce callback: Adding users ([join $user_ids ,]) in group $participant_id"
	} else {
	    set user_ids [list $participant_id]
	}

	if { [exists_and_not_null saved_patron_id] } {
	    if { ! [dotlrn::user_p -user_id $saved_patron_id] } {
		dotlrn::user_add -user_id $saved_patron_id
	    }
	}

	set membership_product_p 0
	set membership_category_id [parameter::get -parameter "MembershipECCategoryId" -default ""]
	if {![empty_string_p $membership_category_id]} {
	    set membership_product_p [db_string get_count {
		select count(*)
		from ec_category_product_map m
		where m.category_id = :membership_category_id
		      and m.product_id = :product_id
	    }]
	}

	foreach user_id $user_ids {
	    if { ! [dotlrn::user_p -user_id $user_id] } {
		dotlrn::user_add -user_id $user_id
	    }

	    if {$membership_product_p} {
		set membership_group_id [parameter::get -parameter MemberGroupId -package_id [apm_package_id_from_key "dotlrn-ecommerce"]]
		if {![empty_string_p $membership_group_id]} {
		    if {![group::member_p -user_id $user_id -group_id $membership_group_id]} {
			group::add_member -group_id $membership_group_id -user_id $user_id
		    }
		}
	    }

	    # Get community mapped to product
	    db_foreach communities {
		select section_id, community_id
		from dotlrn_ecommerce_section
		where product_id = :product_id
	    } {
		ns_log notice "dotlrn-ecommerce callback: Adding user $user_id to community $community_id"
		
		if { [catch {

		    dotlrn_community::add_user $community_id $user_id

		    if { ! [exists_and_not_null patron_id] } {
			set patron_id $saved_patron_id
		    }

		    if { [exists_and_not_null patron_id] } {

		    # See if we need to send the welcome email to the
		    # purchaser
		    if { [lsearch [parameter::get -parameter WelcomeEmailRecipients] purchaser] != -1 } {
			ns_log Notice "sending email to patron_id $patron_id for user_id $user_id"
			if {$patron_id != $participant_id} {
			    # if they are the participant, then
			    # they will get the welcome email for the community
			    dotlrn_community::send_member_email -community_id $community_id -to_user $user_id -type "on join" -email_send_to $patron_id   -override_enabled		
			}
		    }
		    # Keep track of patron relationships

			if { [db_0or1row member_rel {
			    select rel_id
			    from dotlrn_member_rels_full
			    where community_id = :community_id
			    and user_id = :user_id
			    limit 1
			}] } {
			    set patron_rel_id [db_exec_plsql relate_patron {
				select acs_rel__new (null,
						     'membership_patron_rel',
						     :rel_id,
						     :patron_id,
						     null,
						     null,
						     null)
			    }]
			}
		    }

		} errMsg] } {
		    # Fixes for possible double click
		    ns_log notice "dotlrn-ecommerce callback: Probably a double-click: $errMsg"
		}

		dotlrn_ecommerce::section::flush_cache $section_id
	    }
	}
    }

    # DEDS
    # loop for possible notifications on wait list triggered email
    set wait_list_notify_email [parameter::get -package_id [ad_acs_kernel_id] -parameter AdminOwner]
    set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
    foreach community_id_wait $community_notify_waitlist_list {
	ns_log notice "dotlrn-ecommerce wait list notify: potential community is $community_id"
	if {[db_0or1row get_nwn {
	    select s.notify_waiting_number,
                   s.section_name
	    from dotlrn_ecommerce_section s
	    where s.community_id = :community_id_wait
	}]} {
	    if {![empty_string_p $notify_waiting_number]} {
		set current_waitlisted [db_string get_cw {
		    select count(*)
		    from membership_rels m,
                         acs_rels r
		    where m.member_state = 'needs_approval'
		          and m.rel_id = r.rel_id
		          and r.rel_type = 'dotlrn_member_rel'
		          and r.object_id_one = :community_id_wait
		}]
		ns_log notice "dotlrn-ecommerce wait list notify: community $community_id wait number is $notify_waiting_number"
		ns_log notice "dotlrn-ecommerce wait list notify: community $community_id waitlisteed is $current_waitlisted"
		if {$current_waitlisted >= $notify_waiting_number} {
		    set subject "Waitlist notification for $section_name"
		    set body "$section_name is set to notify when the waitlist reaches ${notify_waiting_number}.
Total persons in the waiting list for ${section_name}: $current_waitlisted"
		    acs_mail_lite::send \
			-to_addr $wait_list_notify_email \
			-from_addr $mail_from \
			-subject $subject \
			-body $body
	    		ns_log notice "dotlrn-ecommerce wait list notify: community $community_id sending email"
		} else {
	    		ns_log notice "dotlrn-ecommerce wait list notify: community $community_id NOT sending email"
		}
	    }
	}
    }

    # Set checkout for order
    db_dml checkout_user {
	update dotlrn_ecommerce_orders
	set checked_out_by = :checkout_user_id
	where item_id in (select item_id
			  from ec_items
			  where order_id = :order_id)
    }
    
    ns_log notice "dotlrn-ecommerce callback: Run successfully"
}

namespace eval dotlrn_ecommerce::ec {}

ad_proc -public dotlrn_ecommerce::ec::toggle_offer_codes {
    {-order_id:required}
    {-offer_code "dotlrn-ecommerce"}
    {-insert:boolean}
} {
    toggles offer codes with respect to membership

    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-07-13
    @cvs-id $Id$
} {
    # only do this if we have param set
    if {[parameter::get -parameter MemberPriceP -default 0]} {
	# first see if this order is in_basket
	set in_basket_p [db_string get_in_basket {
	    select count(*)
	    from ec_orders
	    where order_id = :order_id
	    and order_state = 'in_basket'
	}]
	if {$in_basket_p} {
	    # first get the session
	    set user_session_id [db_string get_id {
		select user_session_id
		from ec_orders
		where order_id = :order_id
	    } -default 0]
	    if {$insert_p} {
		# we could either be inserting or updating
		# so handle that accordingly
		set product_id_list [db_list get_items {
		    select i.product_id
		    from ec_items i,
		         ec_sale_prices p
		    where i.order_id = :order_id
		    and i.item_state = 'in_basket'
		    and p.product_id = i.product_id
		    and p.offer_code = :offer_code
		    and p.sale_ends > current_timestamp
		}]
		foreach product_id $product_id_list {
		    set exists_p [db_string get_exists {
			select count(*)
			from ec_user_session_offer_codes
			where user_session_id = :user_session_id
			and offer_code = :offer_code
			and product_id = :product_id
		    }]
		    if {$exists_p} {
			db_dml update_oc {
			    update ec_user_session_offer_codes
			    set offer_code = :offer_code
			    where user_session_id = :user_session_id
			    and product_id = :product_id
			}
		    } else {
			db_dml update_oc {
			    insert into ec_user_session_offer_codes
			    (user_session_id, product_id, offer_code)
			    values
			    (:user_session_id, :product_id, :offer_code)
			}
		    }
		}
	    } else {
		# we are removing
		db_dml delete_offer_codes {
		    delete
		    from ec_user_session_offer_codes
		    where user_session_id = :user_session_id
		    and offer_code = :offer_code
		}
	    }
	}
    }
}

ad_proc -callback dotlrn::default_member_email -impl dotlrn-ecommerce {
} {
    Check course community_id and template community_id in section or
    course specific template does not exist
} {
    #fixme another callback or proc per type?
    set body_extra ""
    array set vars $var_list
    if {[string match "prereq*" $type]} {
	if {[info exists vars(reason)] && $vars(reason) ne ""} {
	    set body_extra "
	    [_ dotlrn-ecommerce.Reason]:
	    [string trim $vars(reason)]"
	}
    }
    set course_community_id [db_string get_ccid "select dc.community_id
    from dotlrn_catalog dc,
    cr_items cr,
    dotlrn_ecommerce_section ds
    where ds.community_id=:community_id
    and ds.course_id=cr.item_id
    and cr.live_revision=dc.course_id" -default ""]

    if {[string equal "" $course_community_id] && $community_id ne ""} {
	return -code continue	
    } elseif {[db_0or1row get_email "select from_addr,subject,email, community_id as email_community_id from dotlrn_member_emails where type=:type and community_id=coalesce(:course_community_id,:community_id)"]} {
	# course or section specific templat exists
	if {$course_community_id eq $email_community_id} {
	    set email_from "course"
	} else {
	    set email_from ""
	}
        return -code return [list $from_addr $subject "$email $body_extra" $email_from]
    } elseif {[db_0or1row get_email "select from_addr,subject,email, community_id as email_community_id from dotlrn_member_emails where type=:type and community_id is null"]} {
	# community_id is null is a customized site wide default exists
	set email_from ""
        return -code return [list $from_addr $subject "$email $body_extra" $email_from]
			    
    } else {
	# site wide default has not been edited
	set subject_key_trim [lindex [split [dotlrn_ecommerce::email_type_message_key -type $type -key subject] "."] 1]
	set email_key_trim [lindex [split [dotlrn_ecommerce::email_type_message_key -type $type -key body] "."] 1]
	set subject ""
	set email ""
	catch {set subject [lang::message::get_element -package_key dotlrn-ecommerce -message_key $subject_key_trim -locale [ad_conn locale] -element message]} errmsg
	catch {set email [lang::message::get_element -package_key dotlrn-ecommerce -message_key $email_key_trim -locale [ad_conn locale] -element message]}
        set from_addr [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
        # check to see if message keys exist
        return -code return [list $from_addr $subject "$email $body_extra" "dotlrn-ecommerce"]
    }
}

ad_proc -callback dotlrn::member_email_var_list -impl dotlrn-ecommerce {} {
    return list of variables for email templates
} {
    # check if this is a dotlrn-ecommerce community, if not, bail
    if {![db_string is_section "select 1 from dotlrn_ecommerce_section where community_id=:community_id" -default 0]} {
	# this return code tells the caller to ignore the results of this callback implementation
	ns_log debug  "DAVEB: email_var_list Skipping default email for dotlrn-ecommerce, not in a section community"
	return -code continue
    }
    #FIXME depend on email type??
    array set var_list [list first_name "" last_name "" full_name "" community_link "" community_name "" community_url "" course_name "" sessions "" instructor_names ""]
    # get user info
    if {![string equal "" $to_user]} {
	acs_user::get -user_id $to_user -array user
	set var_list(first_name) $user(first_names)
	set var_list(last_name) $user(last_name)
	set var_list(full_name) $user(name)
		      
    }
    if {![string equal "" $community_id]} {
	set community_url [dotlrn_community::get_community_url $community_id]
	set var_list(community_url) "[ad_url]$community_url"
	set course_name [db_string get_course_name "select dc.course_name from dotlrn_catalog dc, dotlrn_ecommerce_section ds, cr_items ci where ds.course_id=ci.item_id and ci.live_revision=dc.course_id and ds.community_id=:community_id" -default ""]
	if {$course_name ne ""} {
	    append course_name ":"
	}
	set var_list(community_name) "${course_name} [dotlrn_community::get_community_name $community_id]"
	set var_list(community_link) "<a href=\"${var_list(community_url)}\">${var_list(community_name)}</a>"
	set var_list(course_name) $var_list(community_name)
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	lappend calendar_id_list $calendar_id
	set var_list(sessions) [util_memoize [list dotlrn_ecommerce::section::sessions $calendar_id]]
	set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
	set _instructors [dotlrn_community::list_users $instructor_community_id]

set __instructors [list]
if { [llength $_instructors] == 0 } {
    set _instructors 0
    set instructors_filter ""
} else {
    foreach _instructor $_instructors {
	lappend __instructors [ns_set get $_instructor user_id]
	lappend instructors_filter [list "[ns_set get $_instructor first_names] [ns_set get $_instructor last_name]" [ns_set get $_instructor user_id]]
    }
}
	set instructors [util_memoize [list dotlrn_ecommerce::section::instructors $community_id $__instructors]]
	
	set instructor_names [list]
	set instructor_ids [list]
	foreach instructor $instructors {
	    lappend instructor_names [lindex $instructor 1]
	    lappend instructor_ids [lindex $instructor 0]
	}

	if { [llength $instructor_names] == 1 } {
	    set instructor_names "Instructor: [join $instructor_names ", "]"
	} elseif { [llength $instructor_names] > 1 } {
	    set instructor_names "Instructors: [join $instructor_names ", "]"
	} else {
	    set instructor_names ""
	}
      set var_list(instructor_names) $instructor_names
    }
    # get categories mapped to section


set course_id [db_string get_course_id "select course_id from dotlrn_ecommerce_section where community_id=:community_id" -default ""]
set package_id [db_string get_package_id "select package_id from acs_objects where object_id=:course_id" -default ""]
if {[string equal "" package_id]} {
	set package_id [lindex [site_node::get_children -node_id [site_node::get_node_id -url "/"] -package_key "dotlrn-ecommerce" -element package_id] 0]
}
if {![string equal "" $package_id]} {
    set trees [category_tree::get_mapped_trees $package_id]
    ns_log notice "DAVEB \n trees='${trees}'"
    foreach tree $trees {
	foreach {tree_id tree_name subtree_cat_id assign_single_p require_category_p} $tree break
	set mapped_cats [category::get_mapped_categories -tree_id $tree_id $community_id]
	set mapped_cat_names [category::get_names $mapped_cats]
	set tree_var_name [util_text_to_url -text ${tree_name}]
	set var_list($tree_var_name) [join $mapped_cat_names ","]
    }
}

ns_log notice "DAVEB  email var list '[array get var_list]'"
    return [array get var_list]
}

ad_proc -callback dotlrn::member_email_available_vars -impl dotlrn-ecommerce {} {
    List variables avaiable for this template
} {
    #FIXME depend on email type??
    # get categories mapped to section?
    
    set available_vars [list "%first_name%" "Participant's First Name" "%last_name%" "Participant's Last Name" "%full_name%" "Participant's Full Name" "%sessions%" "Dates and times of sessions" "%community_name%" "Name of section" "%community_url%" "URL of the section page in the form http://example.com/" "%community_link%" "HTML link to section, ie: &lt;a href=\"http://example.com\"&gt;%community_name%&lt;/a&gt;" "%instructor_names%" "List of instructors names"]

	set course_id [db_string get_course_id "select course_id from dotlrn_ecommerce_section where community_id=:community_id" -default ""]
	set package_id [db_string get_package_id "select package_id from acs_objects where object_id=:course_id" -default ""]
    if {[string equal "" $package_id]} {
	set package_id [lindex [site_node::get_children -node_id [site_node::get_node_id -url "/"] -package_key "dotlrn-ecommerce" -element package_id] 0]
    }

	if {![string equal "" $package_id]} {
	    set trees [category_tree::get_mapped_trees $package_id]

	    foreach tree $trees {
		foreach {tree_id tree_name subtree_cat_id assign_single_p require_category_p} $tree break
		lappend available_vars "%[util_text_to_url -text ${tree_name}]%" $tree_name
	    }
	}

    return $available_vars
}

