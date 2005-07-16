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
