ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {return_url ""}
}

set service_name [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemName]