# packages/dotlrn-ecommerce/www/admin/application-reject.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-01
    @arch-tag: 93f47ba6-c04e-419a-bcd6-60bb95553236
    @cvs-id $Id$
} {
    community_id:integer,notnull
    user_id:integer,notnull
    {type waiting_list}
    {send_email_p 1}
} -properties {
} -validate {
} -errors {
}

dotlrn_community::membership_reject -community_id $community_id -user_id $user_id

# Send email to applicant
set actor_id [ad_conn user_id]

if { $user_id != $actor_id && $send_email_p } {
    set applicant_email [cc_email_from_party $user_id]
    set actor_email [cc_email_from_party $actor_id]
    set community_name [dotlrn_community::get_community_name $community_id]
    acs_mail_lite::send \
	-to_addr $applicant_email \
	-from_addr $actor_email \
	-subject [subst "[_ dotlrn-ecommerce.Application_rejected]"] \
	-body [subst "[_ dotlrn-ecommerce.lt_Your_application_to_j_1]"]
}

ad_returnredirect applications
