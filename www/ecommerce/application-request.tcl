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
} -properties {
} -validate {
} -errors {
}

set extra_vars [ns_set create]
ns_set put $extra_vars user_id $participant_id
ns_set put $extra_vars community_id $community_id
if {[catch {set rel_id [relation_add \
			    -member_state "request approval" \
			    -extra_vars $extra_vars \
			    dotlrn_member_rel \
			    $community_id \
			    $participant_id \
			   ]} errmsg]} {
    ad_return_complaint "There was a problem with your request" $errmsg
} else {
    ns_log notice "DEBUG:: RELATION $participant_id, $community_id, $rel_id"
}

ad_returnredirect ".."
