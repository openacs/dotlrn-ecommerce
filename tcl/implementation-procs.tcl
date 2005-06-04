# packages/dotlrn-ecommerce/tcl/implementation-procs.tcl

ad_library {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: 776140e1-a8e8-4d30-84a7-46d8bf054187
    @cvs-id $Id$
}

ad_proc -callback ecommerce::after-checkout -impl dotlrn-ecommerce {
    -user_id:required
    -product_id:required
    -patron_id
    -price
} {
    Add users to community
} {
    # Check first if user_id is actually a group
    if { [acs_object_type $user_id] == "group" } {
	set user_ids [db_list group_members {
	    select distinct object_id_two
	    from acs_rels
	    where object_id_one = :user_id
	    and rel_type = 'membership_rel'
	}]
	ns_log notice "dotlrn-ecommerce callback: Adding users ([join $user_ids ,]) in group $user_id"
    } else {
	set user_ids [list $user_id]
    }

    if { [exists_and_not_null patron_id] } {
	if { ! [dotlrn::user_p -user_id $patron_id] } {
	    dotlrn::user_add -user_id $patron_id
	}
    }

    foreach user_id $user_ids {
	if { ! [dotlrn::user_p -user_id $user_id] } {
	    dotlrn::user_add -user_id $user_id
	}

	# Get community mapped to product
	db_foreach communities {
	    select community_id
	    from dotlrn_ecommerce_section
	    where product_id = :product_id
	} {
	    ns_log notice "dotlrn-ecommerce callback: Adding user $user_id to community $community_id"
	    
	    if { [catch {

		dotlrn_community::add_user $community_id $user_id

		# Keep track of patron relationships
		if { [exists_and_not_null patron_id] } {
		    if { [db_0or1row member_rel {
			select rel_id
			from dotlrn_member_rels_full
			where community_id = :community_id
			and user_id = :user_id
			limit 1
		    }] } {
			set patron_rel_id [db_exec_plsql relate_patron {
			    select acs_rel__new (null,
						 'membership_patron_rel',
						 :rel_id,
						 :patron_id,
						 null,
						 null,
						 null)
			}]
		    }
		}

	    } errMsg] } {
		# Fixes for possible double click
		ns_log notice "dotlrn-ecommerce callback: Probably a double-click: $errMsg"
	    }
	}
    }
}