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

    if { [exists_and_not_null patron_id] } {
	if { ! [dotlrn::user_p -user_id $patron_id] } {
	    dotlrn::user_add -user_id $patron_id
	}
    }

    db_foreach items_in_order {
	select i.product_id, o.patron_id as saved_patron_id, o.participant_id, t.method, v.maxparticipants
	from dotlrn_ecommerce_orders o, ec_items i left join dotlrn_ecommerce_transactions t
	on (i.order_id = t.order_id), ec_custom_product_field_values v
	where i.item_id = o.item_id
	and i.product_id = v.product_id
	and i.order_id = :order_id
	group by i.product_id, o.patron_id, o.participant_id, t.method, v.maxparticipants
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

#		    set waiting_list_p 0
# 		    if { ! [empty_string_p $maxparticipants] } {
# 			db_1row attendees {
# 			    select count(*) as attendees
# 			    from dotlrn_member_rels_approved
# 			    where community_id = :community_id
# 			    and (rel_type = 'dotlrn_member_rel'
# 				 or rel_type = 'dc_student_rel')
# 			}

# 			# If the group members will exceed the maximum
# 			# participants, the entire group goes to the
# 			# waiting list
# 			if { [acs_object_type $participant_id] == "group" } {
# 			    if { ($attendees + [llength $user_ids]) > $maxparticipants } {
# 				set waiting_list_p 1
# 			    }
# 			} else {
# 			    if { $attendees >= $maxparticipants } {
# 				set waiting_list_p 1
# 			    }
# 			}
# 		    }

#		    if { ! [empty_string_p $method] && $method != "cc" } {
#			set waiting_list_p 1
#		    }

#		    if { ! $waiting_list_p } {
		    dotlrn_community::add_user $community_id $user_id
#		    } else {
#			dotlrn_community::add_user -member_state "needs approval" $community_id $user_id
			# DEDS
			# we hit a waitlist
			# we need to check if we possibly notify for this community
			# we do the actual check if we reached the number at the end
			# of the proc so that we save on execution time
#			ns_log notice "dotlrn-ecommerce wait list notify: hit wait list on $community_id"
#			if {[lsearch $community_notify_waitlist_list $community_id] == -1} {
#			    lappend community_notify_waitlist_list $community_id
#			}
#			ns_log notice "dotlrn-ecommerce wait list notify: list is now $community_notify_waitlist_list"
#		    }

		    if { ! [exists_and_not_null patron_id] } {
			set patron_id $saved_patron_id
		    }

		    # Keep track of patron relationships
		    if { [exists_and_not_null patron_id] } {
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
    set course_community_id [db_string get_ccid "select dc.community_id
    from dotlrn_catalog dc,
    dotlrn_ecommerce_section ds
    where ds.community_id=:community_id
    and ds.course_id=dc.course_id" -default ""]
    set template_community_id ""
    #    set template_community_id [parameter::get -package_id [apm_package_id_from_key dotlrn-ecommerce] -parameter TemplateCommunityId -default ""]
    if {[db_0or1row get_email "select * from dotlrn_member_emails where type=:type and community_id=coalesce(:course_community_id,:template_community_id,:community_id)"]} {
        return -code return [list $from_addr $subject $email]
    } else {
        set subject [lang::message::lookup "" [dotlrn_ecommerce::email_type_message_key -type $type -key subject]]
        set email [lang::message::lookup "" [dotlrn_ecommerce::email_type_message_key -type $type -key body]]
        set from_addr [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
        # check to see if message keys exist
        return -code return [list $from_addr $subject $email]
    }
    else return -code continue
}
