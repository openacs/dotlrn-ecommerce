# packages/dotlrn-ecommerce/www/ecommerce/participant-change-2.tcl

ad_page_contract {
    
    Set participant
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-08
    @arch-tag: f8ed6d0a-9e08-4afa-bef7-7202518b36f2
    @cvs-id $Id$
} {
    user_id:integer,notnull
    patron_id:integer,notnull
    section_id:integer,notnull
    return_url:notnull
    skip:optional
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
    select product_id, community_id
    from dotlrn_ecommerce_section
    where section_id = :section_id
}

set rel_id [relation::get_id -object_id_one $patron_id -object_id_two $user_id -rel_type "patron_rel"]

set add_url [export_vars -base "../ecommerce/shopping-cart-add" { product_id {user_id $patron_id} {participant_id $user_id} return_url }]

if { ![empty_string_p $rel_id] || $user_id == $patron_id || [exists_and_not_null skip] } {
    ad_returnredirect $add_url
    ad_script_abort
} else {
    set participant_name [person::name -person_id $user_id]
    set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
    set tree_options [list {}]
    foreach tree [category_tree::get_tree $tree_id] {
	lappend tree_options [list [lindex $tree 1] [lindex $tree 0]]
    }

    ad_form -name relationship -export { user_id patron_id section_id return_url member_state } -form {
	{relationship:text(select) {label "[_ dotlrn-ecommerce.Purchaser_is]"}
	    {options {$tree_options}}}
	{_submit:text(submit) {label "[_ dotlrn-ecommerce.Set_Relationship]"}}
	{skip:text(submit) {label "[_ dotlrn-ecommerce.Skip]"}}
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

	ad_returnredirect [export_vars -base [ad_conn url] { user_id patron_id section_id return_url }]
	ad_script_abort
    }
}
