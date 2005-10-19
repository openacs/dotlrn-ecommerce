# packages/dotlrn-ecommerce/www/admin/application-reject.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-01
    @arch-tag: 93f47ba6-c04e-419a-bcd6-60bb95553236
    @cvs-id $Id$
} {
    community_id:integer,notnull
    user_id:integer,notnull
    {type full}
    {send_email_p 1}
    {return_url "applications"}
    submit2:optional
} -properties {
} -validate {
} -errors {
}

if { [exists_and_equal submit2 "Reject Only"] } {
    ad_returnredirect [export_vars -base application-reject { community_id user_id type return_url {send_email_p 0} }]
    ad_script_abort
}

set actor_id [ad_conn user_id]

set section_id [db_string section {
    select section_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}]


# get the patron info

set patron_id [db_string get_patron {
    select o.creation_user as patron_id from
    acs_rels r, acs_objects o
    where r.rel_id = o.object_id
    and r.object_id_one = :community_id
    and r.object_id_two= :user_id
} -default ""]

set email_reg_info_to [parameter::get -parameter EmailRegInfoTo -default "patron"]	   

if {$email_reg_info_to == "participant"} {
    set email_user_id $user_id
}  else {
    set email_user_id $patron_id
}


# send email if the logged in user is not the person 
# getting the email
 
if { !$send_email_p || $actor_id == $email_user_id } {
    if { [parameter::get -parameter AllowAheadAccess -default 0] } {
	set member_state [db_string member_state {
	    select member_state
	    from dotlrn_member_rels_full
	    where user_id = :user_id
	    and community_id = :community_id
	}]

	if { [lsearch $member_state {"waitinglist approved" "request approved" "payment received"}] != -1 } {
	    # Dispatch dotlrn applet callbacks
	    dotlrn_community::applets_dispatch \
		-community_id $community_id \
		-op RemoveUserFromCommunity \
		-list_args [list $community_id $user_id]
	}
    }

    dotlrn_community::membership_reject -community_id $community_id -user_id $user_id

    ad_returnredirect $return_url
    ad_script_abort
} else {

    # Send email to applicant
    switch $type {
        prereq {
            set title "[_ dotlrn-ecommerce.Reject_prereq]"
	    set email_type "prereq reject"
        }
        default {
            set title "[_ dotlrn-ecommerce.Reject_application]"
	    set email_type "application reject"
        }
    }
    set context [list [list applications "Pending applications"] $title]
    ad_form \
        -name email_form \
        -form {
            {user_id:text(hidden)}
            {community_id:text(hidden)}
            {type:text(hidden)}
	    {subject:text {html {size 60}}}
            {reason:text(textarea),optional {label "[_ dotlrn-ecommerce.Reason]"} {html {rows 10 cols 60}}}
	}

    if { [parameter::get -parameter AllowRejectWithoutEmail -default 0] } {
	ad_form \
	    -extend \
	    -name email_form \
	    -form {
		{submit1:text(submit) {label "Reject and Send Email"}}
		{submit2:text(submit) {label "Reject Only"}}
	    }
    }

    ad_form \
	-extend \
	-name email_form \
	-form {
        } \
        -on_request {
	    set reason_email [lindex [callback dotlrn::default_member_email -community_id $community_id -to_user $user_id -type "prereq reject"] 0]
	    set reason [lindex $reason_email 2]
	    set subject [lindex $reason_email 1]
	    array set vars [lindex [callback dotlrn::member_email_var_list -community_id $community_id -to_user $user_id -type $type] 0]
	    set email_vars [lang::message::get_embedded_vars $reason]
	    foreach var $email_vars {
		if {![info exists vars($var)]} {
		    set vars($var) ""
		}
	    }
	    set var_list [array get vars]
	    set reason "[lang::message::format $reason $var_list]"
        } \
        -on_submit {
	    if { [parameter::get -parameter AllowAheadAccess -default 0] } {
		set member_state [db_string member_state {
		    select member_state
		    from dotlrn_member_rels_full
		    where user_id = :user_id
		    and community_id = :community_id
		}]

		if { [lsearch $member_state {"waitinglist approved" "request approved" "payment received"}] != -1 } {
		    # Dispatch dotlrn applet callbacks
		    dotlrn_community::applets_dispatch \
			-community_id $community_id \
			-op RemoveUserFromCommunity \
			-list_args [list $community_id $user_id]
		}
	    }

            dotlrn_community::membership_reject -community_id $community_id -user_id $user_id

            set to_email [cc_email_from_party $email_user_id]
            set actor_email [cc_email_from_party $actor_id]
            set community_name [dotlrn_community::get_community_name $community_id]
	    dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type $email_type -override_email $reason -override_subject $subject

        } \
        -after_submit {
	    dotlrn_ecommerce::section::flush_cache $section_id
	    dotlrn_ecommerce::section::approve_next_in_waiting_list $community_id
            ad_returnredirect $return_url
	    ad_script_abort
        }
}


