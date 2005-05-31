# packages/dotlrn-ecommerce/www/admin/remove-membership.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: fe075f24-ed9a-4701-8a6d-1f90676ff5b1
    @cvs-id $Id$
} {
    {user_id:integer,multiple {}}
    community_id:integer,notnull
    return_url
} -properties {
} -validate {
} -errors {
}

foreach one_user_id $user_id {
    catch {dotlrn_community::remove_user $community_id $one_user_id}
}

ad_returnredirect $return_url