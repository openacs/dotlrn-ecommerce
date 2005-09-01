# packages/dotlrn-ecommerce/tcl/dotlrn-ecommerce-init.tcl

ad_library {
    
    Procs to run at startup
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-14
    @arch-tag: 40963a7c-970b-41d0-a3da-355d187e42eb
    @cvs-id $Id$
}

ad_schedule_proc -thread t 300 dotlrn_ecommerce::section::check_elapsed_registrations
ad_schedule_proc -thread t 600 dotlrn_ecommerce::section::check_and_approve_sections_for_slots
ad_schedule_proc -thread t -schedule_proc ns_schedule_daily [list 23 50] dotlrn_ecommerce::notify_admins_of_waitlist
ad_schedule_proc -thread t -once t 660 dotlrn_ecommerce::check_expired_orders_once

# Check if we're allowing access to dotLRN community for approved users, 
# this should be done every restart
if { [parameter::get -parameter AllowAheadAccess -package_id [apm_package_id_from_key dotlrn-ecommerce] -default 0] } {
    ns_log notice "dotlrn-ecommerce-init.tcl: Allowing community access to approved member states, this modifies dotlrn_member_rels_approved and the membership_rels_up_tr function"
    dotlrn_ecommerce::allow_access_to_approved_users
} else {
    ns_log notice "dotlrn-ecommerce-init.tcl: Disallowing community access to approved member states, this simply restores dotlrn_member_rels_approved and membership_rels_up_tr"
    dotlrn_ecommerce::disallow_access_to_approved_users
}