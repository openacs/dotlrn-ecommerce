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

dotlrn_community::membership_approve -community_id $community_id -user_id $user_id

ad_returnredirect applications
