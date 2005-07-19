# packages/dotlrn-ecommerce/www/ecommerce/application-request.tcl

ad_page_contract {
    
    Hold slot and request for approval
    
    @author  (mgh@localhost.localdomain)
    @creation-date 2005-07-08
    @arch-tag: 5e4b382d-9d71-4e7a-90e2-47948170d6a7
    @cvs-id $Id$
} {
    participant_id:integer,notnull
    community_id:integer,notnull
    {type full}
    next_url:notnull
} -properties {
} -validate {
} -errors {
}

set extra_vars [ns_set create]
ns_set put $extra_vars user_id $participant_id
ns_set put $extra_vars community_id $community_id

switch $type {
    full {
	set member_state "needs approval"
    }
    prereq {
	set member_state "request approval"
    }
    payment {
	set member_state "awaiting payment"
    }
}

if {[catch {set rel_id [relation_add \
			    -member_state $member_state \
			    -extra_vars $extra_vars \
			    dotlrn_member_rel \
			    $community_id \
			    $participant_id \
			   ]} errmsg]} {
    ad_return_complaint "There was a problem with your request" $errmsg
} else {
    ns_log notice "DEBUG:: RELATION $participant_id, $community_id, $rel_id"
    set wait_list_notify_email [parameter::get -package_id [ad_acs_kernel_id] -parameter AdminOwner]
    set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
    ns_log notice "application-request: wait list notify: potential community is $community_id"
    if {[db_0or1row get_nwn {
	select s.notify_waiting_number,
	       s.section_name
	from dotlrn_ecommerce_section s
	where s.community_id = :community_id
    }]} {
	if {![empty_string_p $notify_waiting_number]} {
	    set current_waitlisted [db_string get_cw {
		select count(*)
		from membership_rels m,
		acs_rels r
		where m.member_state = 'needs approval'
		      and m.rel_id = r.rel_id
		      and r.rel_type = 'dotlrn_member_rel'
		      and r.object_id_one = :community_id
	    }]
	    ns_log notice "application-request: wait list notify: community $community_id wait number is $notify_waiting_number"
	    ns_log notice "application-request: wait list notify: community $community_id waitlisteed is $current_waitlisted"
	    if {$current_waitlisted >= $notify_waiting_number} {
		set subject "Waitlist notification for $section_name"
		set body "$section_name is set to notify when the waitlist reaches ${notify_waiting_number}.
Total persons in the waiting list for ${section_name}: $current_waitlisted"
		acs_mail_lite::send \
		    -to_addr $wait_list_notify_email \
		    -from_addr $mail_from \
		    -subject $subject \
		    -body $body
		ns_log notice "application-request: wait list notify: community $community_id sending email"
	    } else {
		ns_log notice "application-request: wait list notify: community $community_id NOT sending email"
	    }
	}
    }
}

db_1row section {
    select section_id, product_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}

dotlrn_ecommerce::section::flush_cache $section_id

if { [db_0or1row get_assessment {
    select c.assessment_id

    from dotlrn_ecommerce_section s,
    dotlrn_catalogi c,
    cr_items i

    where s.course_id = c.item_id
    and c.item_id = i.item_id
    and i.live_revision = c.course_id
    and s.product_id = :product_id

    limit 1
}] } {
    if { ! [empty_string_p $assessment_id] && $assessment_id != -1 } {
	ad_returnredirect [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment" { assessment_id { return_url $next_url } }]
	ad_script_abort
	
    }
}

# Redirect to application assessment if exists
set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

if { [empty_string_p $assessment_id] || $type == "full" } {
    ad_returnredirect $next_url
} else {
    ad_returnredirect [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment" { assessment_id  {return_url $next_url} }]
}
