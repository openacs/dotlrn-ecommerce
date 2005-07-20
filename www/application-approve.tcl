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
} -properties {
} -validate {
} -errors {
}

### Check for security

if { $type == "full" } {
    set new_member_state "waitinglist approved"
    set old_member_state "needs approval"
} elseif { $type == "prereq" } {
    set new_member_state "request approved"
    set old_member_state "request approval"
} elseif { $type == "payment" } {
    set new_member_state "payment received"
    set old_member_state "awaiting payment"
}

db_dml approve_request {
    update membership_rels
    set member_state = :new_member_state
    where rel_id in (select r.rel_id
		     from acs_rels r,
		     membership_rels m
		     where r.rel_id = m.rel_id
		     and r.object_id_one = :community_id
		     and r.object_id_two = :user_id
		     and m.member_state = :old_member_state)
}

# Send email to applicant
set actor_id [ad_conn user_id]

if { $user_id != $actor_id } {
    set applicant_email [cc_email_from_party $user_id]
    set actor_email [cc_email_from_party $actor_id]
    set community_name [dotlrn_community::get_community_name $community_id]

#    set application_url [ad_url]/[apm_package_url_from_key dotlrn-ecommerce]ecommerce/prerequisite-confirm

    acs_mail_lite::send \
	-to_addr $applicant_email \
	-from_addr $actor_email \
	-subject [subst "[_ dotlrn-ecommerce.Application_approved]"] \
	-body [subst "[_ dotlrn-ecommerce.lt_Your_application_to_j]"]
}

# Send email to applicant
set actor_id [ad_conn user_id]

if { $user_id != $actor_id } {
    set applicant_email [cc_email_from_party $user_id]
    set actor_email [cc_email_from_party $actor_id]
    set community_name [dotlrn_community::get_community_name $community_id]

#    set application_url [ad_url]/[apm_package_url_from_key dotlrn-ecommerce]ecommerce/prerequisite-confirm

    acs_mail_lite::send \
	-to_addr $applicant_email \
	-from_addr $actor_email \
	-subject [subst "[_ dotlrn-ecommerce.Application_approved]"] \
	-body [subst "[_ dotlrn-ecommerce.lt_Your_application_to_j]"]
}

ad_returnredirect applications
