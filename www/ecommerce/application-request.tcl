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

    return_url:optional
} -properties {
} -validate {
} -errors {
}

if { ! [dotlrn::user_p -user_id $participant_id] } {
    dotlrn::user_add -user_id $participant_id
    dotlrn_privacy::set_user_guest_p -user_id $participant_id -value f	
}

set extra_vars [ns_set create]
ns_set put $extra_vars user_id $participant_id
ns_set put $extra_vars community_id $community_id

db_1row section {
    select section_id, product_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}

switch $type {
    full {
	set member_state "needs approval"
	set assessment_id ""
    }
    prereq {
	set member_state "request approval"
	set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

    }
    payment {
	set member_state "awaiting payment"
	set assessment_id [dotlrn_ecommerce::section::application_assessment $section_id]
    }
}

set email_reg_info_to [parameter::get -parameter EmailRegInfoTo -default "patron"]	   
if {$email_reg_info_to == "participant"} {
    set email_user_id $participant_id
}  else {
    set email_user_id $user_id
}

if {[catch {set rel_id [relation_add \
			    -member_state $member_state \
			    -extra_vars $extra_vars \
			    dotlrn_member_rel \
			    $community_id \
			    $participant_id \
			   ]} errmsg]} {
    ad_return_complaint "There was a problem with your request" $errmsg
    ad_script_abort
}

switch -- $member_state {
    "awaiting payment" {
	dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type "awaiting payment"
    }
    "needs approval" -
    "request approval" {
	set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
	set community_name [dotlrn_community::get_community_name $community_id]

	if { [parameter::get -package_id [ad_conn package_id] -parameter NotifyApplicantOnRequest] } {
	    dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type $member_state

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

dotlrn_ecommerce::section::flush_cache -user_id $participant_id $section_id

if { [empty_string_p $assessment_id] || $assessment_id == -1 || $type == "full" } {
    ad_returnredirect $next_url
} else {
    db_transaction {
	# Start a new session
	as::assessment::data -assessment_id $assessment_id
	
	# This shouldn't fail and the assessment must exist, if for some
	# reason it doesn't, the redirects bellow shall not include the
	# session_id and not error out, a new session will be created by
	# the assessment code
	if { [info exists assessment_data(assessment_id)] } {
	    set assessment_rev_id $assessment_data(assessment_rev_id)

	    set package_id [parameter::get -parameter AssessmentPackage]
	    set folder_id [db_string get_folder_id "select folder_id from cr_folders where package_id=:package_id"]
	    
	    set session_item_id [content::item::new -parent_id $folder_id -content_type {as_sessions} -name "$user_id-$assessment_rev_id-[as::item::generate_unique_name]" -title "$user_id-$assessment_rev_id-[as::item::generate_unique_name]" ]
	    set session_id [content::revision::new  -item_id $session_item_id  -content_type {as_sessions}  -title "$user_id-$assessment_rev_id-[as::item::generate_unique_name]"  -attributes [list [list assessment_id $assessment_rev_id]  [list subject_id $user_id]  [list staff_id ""]  [list target_datetime ""]  [list creation_datetime ""]  [list first_mod_datetime ""]  [list last_mod_datetime ""]  [list completed_datetime ""]  [list percent_score ""]  [list consent_timestamp ""] ] ]
	}

	# If a course or prerequisite assessment exists, it should be
	# mapped now to the rel_id, even if the assessment isn't complete,
	# it will show in the assessment list
	db_dml map_application_to_assessment {
	insert into dotlrn_ecommerce_application_assessment_map
	values (:rel_id, :session_id)
	}

	if { [exists_and_not_null return_url] } {
	    set next_url [export_vars -base $next_url { return_url }]
	}
    
	set return_url [export_vars -base "[ad_conn package_url]ecommerce/application-request-2" { user_id {return_url $next_url} }]
	ad_returnredirect [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]assessment" { assessment_id return_url session_id }]

    } on_error {

	set return_url [ad_return_url]
	ad_return_complaint 1 "There was an error processing your application. Please <a href=\"$return_url\">try again</a>."
	
    }
}

ad_script_abort
