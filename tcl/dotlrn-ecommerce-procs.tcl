# packages/dotlrn-ecommerce/tcl/dotlrn-ecommerce-procs.tcl

ad_library {
    
    dotlrn-ecommerce library
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
    @arch-tag: 83f2c08e-8bad-4fb8-8daf-73403e04c99d
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce {}
namespace eval dotlrn_ecommerce::util {}

ad_proc -public dotlrn_ecommerce::notify_admins_of_waitlist {
} {
    notifies admins of what sections have reached
    the waitlist threshold
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
    
    @return 
    
    @error 
} {
    if {[parameter::get -parameter NotifyAdminsOfWaitlistDaily -default 0]} {
        set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
        set subject "Notification of waiting list size"
        set message ""
        
        db_foreach get_sections_with_waitlist {
            select t.* 
            from (select dc.course_name, 
                         des.section_name, 
                         des.notify_waiting_number, 
                         (select count(*) 
                          from membership_rels mr, 
                               acs_rels ar 
                          where ar.rel_id = mr.rel_id 
                                and ar.object_id_one = des.community_id 
                                and mr.member_state = 'needs approval') as waitlist_n,
			 des.community_id
                  from dotlrn_catalog dc, 
                       cr_items i, 
                       dotlrn_ecommerce_section des 
                  where dc.course_id = i.live_revision 
                        and i.item_id = des.course_id 
                        and des.notify_waiting_number is not null) t 
            where waitlist_n >= notify_waiting_number
	
	    and community_id in (select (select d.community_id
					 from site_nodes c, site_nodes p, dotlrn_communities_all d
					 where c.parent_id = p.node_id
					 and p.object_id = d.package_id
					 and c.object_id = cal.package_id) as community_id
				 from cal_items i
				 join calendars cal on (i.on_which_calendar = cal.calendar_id)
				 where i.item_type_id in (select item_type_id
							  from cal_item_types
							  where type = 'Session'))

	    and community_id in (select (select d.community_id
					 from site_nodes c, site_nodes p, dotlrn_communities_all d
					 where c.parent_id = p.node_id
					 and p.object_id = d.package_id
					 and c.object_id = cal.package_id) as community_id
				 
				 from cal_items i, acs_events e, acs_activities a, timespans s, time_intervals t, calendars cal
				 where i.item_type_id in (select item_type_id
							  from cal_item_types
							  where type = 'Session')
				 and i.on_which_calendar = cal.calendar_id
				 and e.timespan_id = s.timespan_id
				 and s.interval_id = t.interval_id
				 and e.activity_id = a.activity_id
				 and e.event_id = i.cal_item_id
				 and start_date >= current_date)
	} {
            append message "Section: $course_name - $section_name
Applicants in notify list: $waitlist_n 
"
ns_write $message
        }

        if {![empty_string_p $message]} {
            set object_id [acs_lookup_magic_object security_context_root]
            set privilege "admin"
            db_foreach get_swas {
                select p.email as email_to
                from parties p, 
                     users u, 
                     acs_permissions ap 
                where u.user_id = p.party_id 
                      and u.user_id = ap.grantee_id 
                      and ap.object_id = :object_id
                      and ap.privilege = :privilege
            } {
	      
                acs_mail_lite::send \
                    -to_addr $email_to \
                    -from_addr $mail_from \
                    -subject $subject \
                    -body $message
            }
        }
    }
}

ad_proc -public dotlrn_ecommerce::check_expired_orders {
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
	    and item_state = 'expired'
	    and expired_date > (current_timestamp - '10 minutes'::interval)
	} {
	    util_memoize_flush [list dotlrn_ecommerce::section::attendees $section_id]	    
	}
    }
}

ad_proc -public dotlrn_ecommerce::check_expired_orders_once {
} {
    Reschedule checking of expired orders
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-18
    
    @return 
    
    @error 
} {
    dotlrn_ecommerce::check_expired_orders

    ad_schedule_proc -thread t 600 dotlrn_ecommerce::check_expired_orders
}

ad_proc -public dotlrn_ecommerce::util::text_to_html {
    {-text:required}
} {
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
} {
    set html_comment [ad_text_to_html -no_lines $text]
    regsub -all {\r\n} $html_comment "\n" html_comment
    regsub -all {\r} $html_comment "\n" html_comment
    regsub -all {([^\n\s])\n\n([^\n\s])} $html_comment {\1</p><p>\2} html_comment
    regsub -all {\n} $html_comment "<br />\n" html_comment
    return $html_comment
}
