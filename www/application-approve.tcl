# packages/dotlrn-ecommerce/www/admin/application-approve.tcl

ad_page_contract {
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-23
    @arch-tag: 93f47ba6-c04e-419a-bcd6-60bb95553236
    @cvs-id $Id$
} {
    community_id:integer,notnull
    user_id:integer,notnull
    {type full}
    {return_url "applications"}
    {send_email_p 0}
    submit1:optional
} -properties {
} -validate {
} -errors {
}


if { [info exists submit1] && $submit1 eq "[_ dotlrn-ecommerce.Approve]" } {
    set send_email_p 1
}

## who should get the email?

set email_reg_info_to [parameter::get -parameter EmailRegInfoTo -default "patron"]

### Check for security

switch $type {
    full {
	set new_member_state "waitinglist approved"
	set old_member_state "needs approval"
	set email_type "waitinglist approved"
    }
    prereq {
	set new_member_state "request approved"
	set old_member_state "request approval"
	set email_type "prereq approval"
    }
    payment {
	set new_member_state "application approved"
	set old_member_state "application sent"
	set email_type "on approval"
    }
}


set actor_id [ad_conn user_id]
db_1row section {
    select section_id, product_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}

dotlrn_ecommerce::section::flush_cache -user_id $user_id $section_id

set allow_free_registration_p [parameter::get -parameter AllowFreeRegistration -default 0]
set price [dotlrn_ecommerce::section::price $section_id]

ad_form \
    -name email_form \
    -export { application_type return_url } \
    -form {
	{user_id:text(hidden)}
	{community_id:text(hidden)}
	{type:text(hidden)}
	{subject:text {html {size 60}}}
	{reason:text(textarea),optional {label "[_ dotlrn-ecommerce.Reason]"} {html {rows 10 cols 60}}}
	{submit1:text(submit) {label "[_ dotlrn-ecommerce.Approve]"}}
	{submit2:text(submit) {label "[_ dotlrn-ecommerce.Approve_no_email]"}}
    } \
    -on_request {
	set reason_email [lindex [callback dotlrn::default_member_email -community_id $community_id -to_user $user_id -type $email_type] 0]
	set reason [lindex $reason_email 2]
	set subject [lindex $reason_email 1]
	array set vars [lindex [callback dotlrn::member_email_var_list -community_id $community_id -to_user $user_id -type $type] 0]
	set email_vars [lang::message::get_embedded_vars $reason]
	foreach var [concat $email_vars] {
	    if {![info exists vars($var)]} {
		set vars($var) ""
	    }
	}
	set var_list [array get vars]
	set reason "[lang::message::format $reason $var_list]"
    } \
    -on_submit {
	
	if { [db_0or1row rels {
	    select r.rel_id, o.creation_user as patron_id
	    from dotlrn_member_rels_full r, acs_objects o
	    where r.rel_id = o.object_id
	    and r.community_id = :community_id
	    and r.user_id = :user_id
	    and r.member_state = :old_member_state
	}] } {
	    if {$send_email_p} {
		if {$email_reg_info_to == "participant"} {
		    set email_user_id $user_id
		}  else {
		    set email_user_id $patron_id
		}
		
		dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type $email_type -override_email $reason -override_subject $subject
	    }
	    
	    if { ![empty_string_p $price] && $price < 0.01 && $allow_free_registration_p } {
		dotlrn_ecommerce::registration::new -user_id $user_id -patron_id $patron_id -community_id $community_id
	    } else {
		dotlrn_ecommerce::section::user_approve -rel_id $rel_id -user_id $user_id -community_id $community_id
	    }
	}
	
    } \
    -after_submit {
	dotlrn_ecommerce::section::flush_cache -user_id $user_id $section_id
	ad_returnredirect $return_url
	ad_script_abort
    }
