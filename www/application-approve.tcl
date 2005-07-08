# packages/dotlrn-ecommerce/www/admin/application-approve.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-23
    @arch-tag: 93f47ba6-c04e-419a-bcd6-60bb95553236
    @cvs-id $Id$
} {
    community_id:integer,notnull
    user_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

# Check for security
db_dml approve_request {
    update membership_rels
    set member_state = 'request approved'
    where rel_id in (select r.rel_id
		     from acs_rels r,
		     membership_rels m
		     where r.rel_id = m.rel_id
		     and r.object_id_one = :community_id
		     and r.object_id_two = :user_id
		     and m.member_state = 'request approval')
}

ad_returnredirect applications
