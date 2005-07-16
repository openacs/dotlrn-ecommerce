# packages/dotlrn-ecommerce/www/ecommerce/participant-change-2.tcl

ad_page_contract {
    
    Set participant
    
    @author  (mgh@localhost.localdomain)
    @creation-date 2005-07-08
    @arch-tag: f8ed6d0a-9e08-4afa-bef7-7202518b36f2
    @cvs-id $Id$
} {
    user_id:integer,notnull
    patron_id:integer,notnull
    product_id:integer,notnull
    {new_user_p 0}
    return_url:notnull
} -properties {
} -validate {
} -errors {
}

# Add some security checks here

if { ! [dotlrn::user_p -user_id $user_id] } {
    dotlrn::user_add -user_id $user_id
}

# Get section
db_1row section {
    select section_id, community_id
    from dotlrn_ecommerce_section
    where product_id = :product_id
}

# set member_state [db_string awaiting_approval {
#     select m.member_state
#     from acs_rels r,
#     membership_rels m
#     where r.rel_id = m.rel_id
#     and r.object_id_one = :community_id
#     and r.object_id_two = :user_id
#     limit 1
# } -default ""]

set rel_id [relation::get_id -object_id_one $patron_id -object_id_two $user_id -rel_type "patron_rel"]
set add_url [export_vars -base "shopping-cart-add" { product_id {user_id $patron_id} {participant_id $user_id} return_url }]
if { ![empty_string_p $rel_id] || $user_id == $patron_id } {
    if { $new_user_p } {
	ad_returnredirect $add_url
    } else {
	ad_returnredirect [export_vars -base "participant-add" { section_id user_id return_url add_url }]
    }
    ad_script_abort
} else {
    set participant_name [person::name -person_id $user_id]
    set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
    set tree_options [list {}]
    foreach tree [category_tree::get_tree $tree_id] {
	lappend tree_options [list [lindex $tree 1] [lindex $tree 0]]
    }

    ad_form -name relationship -export { user_id patron_id product_id new_user_p return_url member_state } -form {
	{relationship:text(select) {label "[subst [_ dotlrn-ecommerce.lt_How_are_you_related_t]]"}
	    {options {$tree_options}}}
    } -on_submit {
	set rel_id [db_exec_plsql relate_patron {
	    select acs_rel__new (null,
				 'patron_rel',
				 :patron_id,
				 :user_id,
				 null,
				 null,
				 null)
	}]
	category::map_object -remove_old -object_id $rel_id [list $relationship]

# 	if { $member_state != "waitinglist approved" } {
# 	    set available_slots [dotlrn_ecommerce::section::available_slots $section_id]
	    
# 	    if { $available_slots == 0 } {
# 		# No more slots left, ask user if he wants to go to
# 		# waiting list
# 		ad_returnredirect [export_vars -base waiting-list-confirm { product_id user_id return_url }]
# 		ad_script_abort
# 	    }
# 	}

	ad_returnredirect [export_vars -base [ad_conn url] { user_id patron_id product_id new_user_p return_url }]
	ad_script_abort
    }
}
