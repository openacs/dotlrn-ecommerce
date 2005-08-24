# packages/dotlrn-ecommerce/www/ecommerce/application-request.tcl

ad_page_contract {
    
    Hold slot and request for approval
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-08
    @arch-tag: 5e4b382d-9d71-4e7a-90e2-47948170d6a7
    @cvs-id $Id$
} {
    user_id:integer,notnull,optional
    participant_id:integer,notnull
    community_id:integer,notnull
    {type full}
    next_url:notnull
    {as_done_p 0}
} -properties {
} -validate {
} -errors {
}

set extra_vars [ns_set create]
ns_set put $extra_vars user_id $participant_id
ns_set put $extra_vars community_id $community_id

db_1row section {
    select section_id, product_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}

set assessment_id [dotlrn_ecommerce::section::application_assessment $section_id]
if { ! [empty_string_p $assessment_id] && $assessment_id != -1 && !$as_done_p} {
    set return_url "[ad_return_url]&as_done_p=1"
    ad_returnredirect [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment" { assessment_id return_url }]
    ad_script_abort    
}

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
    switch -- $member_state {
	"awaiting payment" {
	    dotlrn_community::send_member_email -community_id $community_id -to_user $participant_id -type "awaiting payment"
	}
        "needs approval" -
        "request approval" {
            set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
	    set community_name [dotlrn_community::get_community_name $community_id]
	    #FIXME add email templates for these??
            if {$member_state eq "needs approval"} {
                set subject [_ dotlrn-ecommerce.lt_Added_to_waiting_list]
                set body [_ dotlrn-ecommerce.lt_Added_to_waiting_list_1]
            } else {
                set subject [_ dotlrn-ecommerce.lt_Requested_waiver_of_prereq]
                set body [_ dotlrn-ecommerce.lt_Requested_waiver_of_prereq_1]
            }

  	    if { [parameter::get -package_id [ad_conn package_id] -parameter NotifyApplicantOnRequest] } {
		ns_log notice "DEBUG:: SENDING APPLICATION NOTIFICATION"
		acs_mail_lite::send \
			-to_addr [cc_email_from_party $participant_id] \
			-from_addr $mail_from \
			-subject $subject \
			-body $body
	   }
        }
    }
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
		where m.member_state in ('needs approval', 'awaiting payment')
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

    # Set the rel_id's creation user to the purchaser
    if { [info exists user_id] && $user_id != [ad_conn user_id] } {
	db_dml set_purchaser {
	    update acs_objects
	    set creation_user = :user_id
	    where object_id = :rel_id
	}
    }
}

dotlrn_ecommerce::section::flush_cache -user_id $participant_id $section_id

# Redirect to application assessment if exists
set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

if { [empty_string_p $assessment_id] || $type == "full" } {
    ad_returnredirect $next_url
} else {
    set return_url [export_vars -base "[ad_conn package_url]ecommerce/application-request-2" { user_id {return_url $next_url} }]
    ad_returnredirect [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment" { assessment_id return_url }]
}
