# packages/dotlrn-ecommerce/www/ecommerce/prerequisite-confirm.tcl

ad_page_contract {
    
    Check if prerequisites are met
    
    @author  (mgh@localhost.localdomain)
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

if { $admin_p } {
	set return_url "/dotlrn-ecommerce/admin/"
}


db_1row section {
    select section_id, community_id
    from dotlrn_ecommerce_section
    where product_id = :product_id
}

if { $participant_id == 0 } {
    set participant_id $user_id
}

# See if we need to check for prerequisites
set shopping_cart_add_url [export_vars -base shopping-cart-add { user_id participant_id product_id item_count {override_p 1} }]

set approved_p [db_string approved {
    select 1
    where exists (select *
		  from acs_rels r,
		  membership_rels m
		  where r.rel_id = m.rel_id
		  and r.object_id_one = :community_id
		  and r.object_id_two = :participant_id
		  and m.member_state = 'request approved')
} -default 0]

if { ! $approved_p } {
    
    template::multirow create prereqs field section user
    db_foreach prereqs {
	select m.tree_id, m.user_field, s.community_id
	from dotlrn_ecommerce_prereqs p,
	dotlrn_ecommerce_prereq_map m,
	dotlrn_ecommerce_section s
	where p.tree_id = m.tree_id
	and p.section_id = s.section_id
	and s.section_id = :section_id
    } {
	set section_prereqs [db_list section_prereqs {
	    select category_id
	    from category_object_map_tree
	    where tree_id = :tree_id
	    and object_id = :community_id
	}]

	set user_prereqs [db_list participant_prereqs {
	    select category_id
	    from category_object_map_tree
	    where tree_id = :tree_id
	    and object_id = :participant_id
	}]

	# Check if prereq is met
	if { [llength $user_prereqs] > 0 } {
	    foreach user_prereq $user_prereqs {
		if { [llength $section_prereqs] > 0 && [lsearch $section_prereqs $user_prereq] == -1 } {
		    # Prereq not met
		    template::multirow append prereqs [category_tree::get_name $tree_id]
		}
	    }
	} else {
	    template::multirow append prereqs [category_tree::get_name $tree_id] [join $section_prereqs ", "] [join $user_prereqs ", "]
	}
    }

}

if { [template::multirow size prereqs] == 0 } {
    ad_returnredirect $shopping_cart_add_url
    ad_script_abort
}

set request_url [export_vars -base application-request { user_id participant_id community_id {type prereq} {next_url $return_url} }]
