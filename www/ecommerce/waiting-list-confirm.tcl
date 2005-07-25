# packages/dotlrn-ecommerce/www/ecommerce/prerequisite-confirm.tcl

ad_page_contract {
    
    Check if prerequisites are met
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-07
    @arch-tag: 4ad97aab-c572-4c9f-b359-4ee60c18872d
    @cvs-id $Id$
} {
    product_id:integer
    {item_count 1}
    user_id:integer,notnull
    {participant_id:integer 0}
    return_url:notnull
    cancel_url:notnull
} -properties {
} -validate {
} -errors {
}

set package_id [ad_conn package_id]
set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]

db_1row section {
    select section_id, community_id, section_name
    from dotlrn_ecommerce_section
    where product_id = :product_id
}

if { $participant_id == 0 } {
    set participant_id $user_id
}

# See if we need to check for prerequisites
set shopping_cart_add_url [export_vars -base shopping-cart-add { user_id participant_id product_id item_count {override_p 1} }]

set request_url [export_vars -base application-request { participant_id community_id {next_url $return_url} }]
