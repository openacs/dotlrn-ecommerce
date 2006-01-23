# packages/dotlrn-ecommerce/www/application-bulk-reject.tcl

ad_page_contract {
    
    Bulk reject applications
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-09-30
    @arch-tag: 35bc095d-0e16-4896-9545-0c8bffb03806
    @cvs-id $Id$
} {
    {rel_id:multiple {}}
    return_url
    __confirmed_p:optional

    {filter_community_id ""}
    {filter_member_state ""}
} -properties {
} -validate {
} -errors {
}

# Properly check for permissions as non-sw-admin instructors can
# access the applications list and perform operations on their
# specific classes
#permission::require_permission -object_id [ad_conn package_id] -privilege admin

set actor_id [ad_conn user_id]
set email_reg_info_to [parameter::get -parameter EmailRegInfoTo -default "patron"]

if { [info exists __confirmed_p] } {
    set rel_id [split [lindex $rel_id 0]]

}

if { [llength $rel_id] == 0 } {
    ad_returnredirect $return_url
    ad_script_abort
}

# Build todo list, we need to do this because each section can have
# its specific email template
db_multirow -extend { url type } todo todo [subst {
    select r.community_id, r.member_state, c.pretty_name as community_name, max(r.user_id) as any_user_id

    from dotlrn_member_rels_full r, dotlrn_communities c

    where r.community_id = c.community_id
    and rel_id in ([join $rel_id ,])
    and r.member_state in ('needs approval', 'request approval', 'application sent', 'waitinglist approved', 'request approved', 'application approved')

    group by r.community_id, r.member_state, c.pretty_name
}] {
    set url [export_vars -base application-bulk-reject { rel_id:multiple return_url {filter_community_id $community_id} {filter_member_state $member_state} }]

    set type [ad_decode $member_state \
		  "needs approval" "Waiting List" \
		  "request approval" "Prerequisite" \
		  "application sent" "Application" \
		  "waitinglist approved" "Waiting List" \
		  "request approved" "Prerequisite" \
		  "application approved" "Application" \
		  "Waiting List"]
}

# Create a list for the applications we can approve
db_multirow -extend { type } applications applications [subst {
    select rel_id as _rel_id, user_id, person__name(user_id), pretty_name as community_name, member_state
    from dotlrn_member_rels_full r, dotlrn_communities_full c
    where r.community_id = c.community_id
    and rel_id in ([join $rel_id ,])
    and member_state = :filter_member_state
    and (case when :filter_community_id is null then true else r.community_id = :filter_community_id end)
}] {
    set type [ad_decode $member_state \
		  "needs approval" "Waiting List" \
		  "request approval" "Prerequisite" \
		  "application sent" "Application" \
		  "waitinglist approved" "Waiting List" \
		  "request approved" "Prerequisite" \
		  "application approved" "Application" \
		  "Waiting List"]
}

if { [template::multirow size applications] > 0 } {
    ad_form -name confirm -export { rel_id return_url filter_member_state filter_community_id } -form {
    }
    
    if { ! [empty_string_p $filter_community_id] && ! [empty_string_p $filter_member_state] } {
	ad_form -extend -name confirm -form {
	    {subject:text {html {size 60}}}
	    {reason:text(textarea),optional {label "[_ dotlrn-ecommerce.Reason]"} {html {rows 10 cols 60}}}
	} -on_request {
	    switch $filter_member_state {
		"request approval" -
		"request approved" {
		    set email_type "prereq reject"
		}
		default {
		    set email_type "application reject"
		}
	    }

	    set reason_email [lindex [callback dotlrn::default_member_email -community_id $filter_community_id -to_user 0 -type $email_type] 0]
	    set reason [lindex $reason_email 2]
	    set subject [lindex $reason_email 1]
	}
    }
    
    if { [parameter::get -parameter AllowRejectWithoutEmail -default 0] } {
	ad_form \
	    -extend \
	    -name confirm \
	    -form {
		{submit1:text(submit) {label "[_ dotlrn-ecommerce.lt_Reject_and_Send_Email]"}}
		{submit2:text(submit) {label "[_ dotlrn-ecommerce.Reject_Only]"}}
	    }
    } else {
	ad_form -extend -name confirm -form {
	    {reject:text(submit) {label "[_ dotlrn-ecommerce.Reject]"}}
	}
    }

    ad_form -extend -name confirm -form {
    } -on_submit {

	db_foreach applications_to_approve [subst {
	    select rel_id as _rel_id, user_id, r.community_id, member_state, s.section_id, o.creation_user as patron_id
	    from dotlrn_member_rels_full r, dotlrn_ecommerce_section s, acs_objects o
	    where r.community_id = s.community_id
	    and r.rel_id = o.object_id
	    and rel_id in ([join $rel_id ,])
	    and r.member_state = :filter_member_state
	    and r.community_id = :filter_community_id
	}] {

            dotlrn_community::membership_reject -community_id $community_id -user_id $user_id

	    if {$email_reg_info_to == "participant"} {
		set email_user_id $user_id
	    }  else {
		set email_user_id $patron_id
	    }
	    
	    if { ! [exists_and_equal submit2 "[_ dotlrn-ecommerce.Reject_Only]"] } {
		
		set to_email [cc_email_from_party $email_user_id]
		set actor_email [cc_email_from_party $actor_id]
		set community_name [dotlrn_community::get_community_name $community_id]
		
		switch $filter_member_state {
		    "request approval" -
		    "request approved" {
			set email_type "prereq reject"
			set type prereq
		    }
		    "needs approval" -
		    "waitinglist approved" {
			set email_type "application reject"
			set type full
		    }
		    default {
			set email_type "application reject"
			set type payment
		    }
		}
		
		array set vars [lindex [callback dotlrn::member_email_var_list -community_id $filter_community_id -to_user $email_user_id -type $type] 0]
		set email_vars [lang::message::get_embedded_vars $reason]
		foreach var [concat $email_vars] {
		    if {![info exists vars($var)]} {
			set vars($var) ""
		    }
		}
		set var_list [array get vars]
		set reason "[lang::message::format $reason $var_list]"

		dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type $email_type -override_email $reason -override_subject $subject
	    }

	    dotlrn_ecommerce::section::flush_cache -user_id $user_id $section_id
	}

	# Redirect to myself, if there's nothing left to do, we'll go
	# back to return_url
	ad_returnredirect [export_vars -base [ad_conn url] { rel_id:multiple return_url }]
	ad_script_abort
    }
}