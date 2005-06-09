# packages/dotlrn-ecommerce/tcl/implementation-procs.tcl

ad_library {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: 776140e1-a8e8-4d30-84a7-46d8bf054187
    @cvs-id $Id$
}

ad_proc -callback ecommerce::after-checkout -impl dotlrn-ecommerce {
    -user_id
    -order_id
    -patron_id
} {

} {
    if { [exists_and_not_null patron_id] } {
	if { ! [dotlrn::user_p -user_id $patron_id] } {
	    dotlrn::user_add -user_id $patron_id
	}
    }

    db_foreach items_in_order {
	select i.product_id, o.patron_id as saved_patron_id, o.participant_id
	from ec_items i, dotlrn_ecommerce_orders o
	where i.item_id = o.item_id
	and i.order_id = :order_id
	group by i.product_id, o.patron_id, o.participant_id
    } {
	if { [empty_string_p $participant_id] } {
	    if { [exists_and_not_null user_id] } {
		set participant_id $user_id
	    } else {
		continue
	    }
	}

	# Check first if user_id is actually a group
	if { [acs_object_type $participant_id] == "group" } {
	    set user_ids [db_list group_members {
		select distinct object_id_two
		from acs_rels
		where object_id_one = :participant_id
		and rel_type = 'membership_rel'
	    }]
	    ns_log notice "dotlrn-ecommerce callback: Adding users ([join $user_ids ,]) in group $participant_id"
	} else {
	    set user_ids [list $participant_id]
	}

	if { [exists_and_not_null saved_patron_id] } {
	    if { ! [dotlrn::user_p -user_id $saved_patron_id] } {
		dotlrn::user_add -user_id $saved_patron_id
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

		    if { ! [exists_and_not_null patron_id] } {
			set patron_id $saved_patron_id
		    }

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
}