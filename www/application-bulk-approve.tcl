# packages/dotlrn-ecommerce/www/application-bulk-approve.tcl

ad_page_contract {
    
    Bulk approve applications
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-09-29
    @arch-tag: 6af8efc8-8de8-498b-950c-2cf207c24f5b
    @cvs-id $Id$
} {
    {rel_id:multiple {}}
    return_url
    __confirmed_p:optional
    {send_email_p 1}
    submit2:optional
    {filter_community_id ""}
    {filter_member_state:multiple {{needs approval} {application sent}}}
} -properties {
} -validate {
} -errors {
}

#If we come from a "Submit2" command, we must not send the emails.
if { [exists_and_equal submit2 "[_ dotlrn-ecommerce.Approve_no_email]"] } {
    set send_email_p 0
}



# Properly check for permissions as non-sw-admin instructors can
# access the applications list and perform operations on their
# specific classes
#permission::require_permission -object_id [ad_conn package_id] -privilege admin

set actor_id [ad_conn user_id]
set email_reg_info_to [parameter::get -parameter EmailRegInfoTo -default "patron"]
set allow_free_registration_p [parameter::get -parameter AllowFreeRegistration -default 0]

if { [info exists __confirmed_p] } {
    set rel_id [split [lindex $rel_id 0]]
    set filter_member_state [lindex $filter_member_state 0]
}

if { [llength $rel_id] == 0 } {
    ad_returnredirect $return_url
    ad_script_abort
}

# We need to do this coz there may be section specific email templates
db_multirow -extend { url type } todo todo [subst {
    select r.community_id, r.member_state, c.pretty_name as community_name

    from dotlrn_member_rels_full r, dotlrn_communities c

    where r.community_id = c.community_id
    and rel_id in ([join $rel_id ,])
    and r.member_state = 'request approval'
    and (case when :filter_community_id is null then true else not r.community_id = :filter_community_id end)

    group by r.community_id, r.member_state, c.pretty_name
}] {
    set url [export_vars -base application-bulk-approve { rel_id:multiple return_url {filter_community_id $community_id} {filter_member_state $member_state} }]

    set type [ad_decode $member_state \
		  "needs approval" "Waiting List" \
		  "request approval" "Prerequisite" \
		  "application sent" "Application" \
		  "Waiting List"]
}

# Create a list for the applications we can approve
db_multirow -extend { type } applications applications [subst {
    select rel_id as _rel_id, user_id, person__name(user_id), pretty_name as community_name, member_state
    from dotlrn_member_rels_full r, dotlrn_communities_full c
    where r.community_id = c.community_id
    and rel_id in ([join $rel_id ,])
    and member_state in ('[join $filter_member_state ',']')
    and (case when :filter_community_id is null then true else r.community_id = :filter_community_id end)
}] {
    set type [ad_decode $member_state \
		  "needs approval" "Waiting List" \
		  "request approval" "Prerequisite" \
		  "application sent" "Application" \
		  "Waiting List"]
}

if { [template::multirow size applications] > 0 } {
    ad_form -name confirm -export { rel_id return_url filter_member_state filter_community_id } -form {
    }
    
    if { ! [empty_string_p $filter_community_id] && [string equal "request approval" [lindex $filter_member_state 0]] } {
	ad_form -extend -name confirm -form {
	    {subject:text {html {size 60}}}
	    {reason:text(textarea),optional {label "[_ dotlrn-ecommerce.Reason]"} {html {rows 10 cols 60}}}
	} -on_request {
	    set reason_email [lindex [callback dotlrn::default_member_email -community_id $filter_community_id -to_user 0 -type "prereq approval"] 0]
	    set reason [lindex $reason_email 2]
	    set subject [lindex $reason_email 1]
	}
    }
    
    ad_form -extend -name confirm -form {
	{submit1:text(submit) {label "[_ dotlrn-ecommerce.Approve]"}}
	{submit2:text(submit) {label "[_ dotlrn-ecommerce.Approve_no_email]"}}
    } -on_submit {

	db_foreach applications_to_approve [subst {
	    select rel_id as _rel_id, user_id, r.community_id, member_state, s.section_id, o.creation_user as patron_id
	    from dotlrn_member_rels_full r, dotlrn_ecommerce_section s, acs_objects o
	    where r.community_id = s.community_id
	    and r.rel_id = o.object_id
	    and rel_id in ([join $rel_id ,])
	    and member_state in ('[join $filter_member_state ',']')
	    and (case when :filter_community_id is null then member_state != 'request approval' else r.community_id = :filter_community_id end)
	}] {

	    #Only send the emails if appropriate
	    if {$send_email_p == 1} {
		if {$email_reg_info_to == "participant"} {
			set email_user_id $user_id
		}  else {
			set email_user_id $patron_id
		}
		
		if { "request approval" == $member_state } {
			array set vars [lindex [callback dotlrn::member_email_var_list -community_id $filter_community_id -to_user $email_user_id -type prereq] 0]
			set email_vars [lang::message::get_embedded_vars $reason]
			foreach var [concat $email_vars] {
			if {![info exists vars($var)]} {
				set vars($var) ""
			}
			}
			set var_list [array get vars]
			set reason "[lang::message::format $reason $var_list]"
	
			dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type "prereq approval" -override_email $reason -override_subject $subject
		} else {
			set email_type [ad_decode $member_state "needs approval" "waitinglist approved" "application sent" "on approval" "waitinglist approved"]
	
			dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type $email_type
		}	    
	    }
	    set price [dotlrn_ecommerce::section::price $section_id]

	    # Approval on free registration gets the user registered immediately
	    if { ![empty_string_p $price] && $price < 0.01 && $allow_free_registration_p } {
		dotlrn_ecommerce::registration::new -user_id $user_id -patron_id $patron_id -community_id $community_id
	    } else {
		dotlrn_ecommerce::section::user_approve -rel_id $_rel_id -user_id $user_id -community_id $community_id
		dotlrn_ecommerce::section::flush_cache -user_id $user_id $section_id
	    }
	}
	    
	# Redirect to myself, if there's nothing left to do, we'll go
	# back to return_url
	ad_returnredirect [export_vars -base [ad_conn url] { rel_id:multiple return_url }]
	ad_script_abort
    }
}

# Create a list for applications that have already been approved
db_multirow approved approved [subst {
    select rel_id as _rel_id, user_id, person__name(user_id), pretty_name as community_name
    from dotlrn_member_rels_full r, dotlrn_communities_full c
    where r.community_id = c.community_id
    and rel_id in ([join $rel_id ,])
    and member_state in ('waitinglist approved', 'request approved', 'application approved')
    
    order by r.community_id
}]

set now_url [export_vars -base [ad_conn url] { rel_id:multiple return_url }]