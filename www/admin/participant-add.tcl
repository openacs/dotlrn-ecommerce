# packages/dotlrn-ecommerce/www/admin/participant-add.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-01
    @arch-tag: 0ee8915f-9e76-4a92-9d43-89c2c757276d
    @cvs-id $Id$
} {
    user_id:integer
    {return_url ""}
    section_id:integer
    community_id:integer
    {cancel ""}
} -properties {
} -validate {
} -errors {
}

set title ""
set context ""

db_1row get_section_info "select c.course_id, c.course_name, s.section_name, s.product_id
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

set title "Partipant Info for $course_name: $section_name"
set context [list [list [export_vars -base course-info { course_id }] $section_name] "Participants and Patrons"]
set add_url [export_vars -base "ecommerce/shopping-cart-add" { product_id user_id }]
set addpatron_url [export_vars -base "[apm_package_url_from_key dotlrn-ecommerce]admin/membership-add" { user_id section_id community_id {referer $return_url} }]
