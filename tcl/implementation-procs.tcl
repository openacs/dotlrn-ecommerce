# packages/dotlrn-ecommerce/tcl/implementation-procs.tcl

ad_library {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: 776140e1-a8e8-4d30-84a7-46d8bf054187
    @cvs-id $Id$
}

ad_proc -callback ecommerce::after-checkout -impl dotlrn-ecommerce {
    -user_id
    -product_id
    -price
} {
    Add user to community
} {
    # Get community mapped to product
    db_foreach communities {
	select community_id
	from dotlrn_ecommerce_section
	where product_id = :product_id
    } {
	ns_log notice "dotlrn-ecommerce callback: Adding user $user_id to community $community_id"

	dotlrn_community::add_user $community_id $user_id
    }
}