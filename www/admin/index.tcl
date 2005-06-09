# packages/dotlrn-ecommerce/www/admin/index.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-18
    @arch-tag: 92819343-73fc-4fea-a823-3e62f6c145bc
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

set context ""
set page_title "Course/eCommerce Administration"

set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]

set instructor_community_url [dotlrn_community::get_community_url $instructor_community_id]

set assistant_community_id [parameter::get -package_id [ad_conn package_id] -parameter AssistantCommunityId -default 0 ]

set assistant_community_url [dotlrn_community::get_community_url $assistant_community_id]

# HAM : check if scholarship is installed
set scholarship_installed_p [apm_package_installed_p "scholarship-fund"]
# HAM : check if expenses is installed
set expenses_installed_p [apm_package_installed_p "expenses"]
