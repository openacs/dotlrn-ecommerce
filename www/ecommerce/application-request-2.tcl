# packages/dotlrn-ecommerce/www/ecommerce/application-request-2.tcl

ad_page_contract {
    
    Try to set the assessment subject to the purchaser
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-24
    @arch-tag: 1a9bde71-7fff-41f1-a351-c8578bb46173
    @cvs-id $Id$
} {
    user_id:integer,notnull
    session_id:integer,notnull
    return_url:notnull

    type:notnull
    community_id:integer,notnull
    email_user_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]
set viewing_user_id [ad_conn user_id]

db_dml set_assessment_subject {	
    update as_sessions	
    set subject_id = :user_id
    where session_id = :session_id
}

# Send emails
switch -- $type {
    "payment" {
	dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type "application sent"
    }
    "prereq" {
	set mail_from [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
	set community_name [dotlrn_community::get_community_name $community_id]

	if { [parameter::get -package_id [ad_conn package_id] -parameter NotifyApplicantOnRequest] } {
	    dotlrn_community::send_member_email -community_id $community_id -to_user $email_user_id -type "request approval"

	}
    }
}

ad_returnredirect $return_url