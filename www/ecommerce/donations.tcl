# packages/dotlrn-ecommerce/www/ecommerce/donations.tcl

ad_page_contract {
    
    displays donations product chunks
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-08-11
    @cvs-id $Id$
} {
    user_id:integer,notnull,optional
} -properties {
} -validate {
} -errors {
}

if {![exists_and_not_null user_id]} {
    set user_id [auth::require_login]
}

set title "[_ dotlrn-ecommerce.Make_a_donation ]"
set context {}

set donation_category_id [parameter::get -parameter DonationECCategoryId -default ""]
