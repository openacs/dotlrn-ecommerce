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
    item_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

# Add some security checks here

if { ! [dotlrn::user_p -user_id $user_id] } {
    dotlrn::user_add -user_id $user_id
}

db_dml update_participant {
    update dotlrn_ecommerce_orders
    set participant_id = :user_id
    where item_id = :item_id
}

set rel_id [relation::get_id -object_id_one $patron_id -object_id_two $user_id -rel_type "patron_rel"]
if { ![empty_string_p $rel_id] || $user_id == $patron_id } {
    ad_returnredirect [export_vars -base shopping-cart { {user_id $patron_id} }]
    ad_script_abort
} else {
    set participant_name [person::name -person_id $user_id]
    set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
    set tree_options [list {}]
    foreach tree [category_tree::get_tree $tree_id] {
	lappend tree_options [list [lindex $tree 1] [lindex $tree 0]]
    }

    ad_form -name relationship -export { user_id patron_id item_id } -form {
	{relationship:text(select) {label "[_ dotlrn-ecommerce.lt_How_are_you_related_t]"}
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

	ad_returnredirect [export_vars -base [ad_conn url] { user_id patron_id item_id}]
	ad_script_abort
    }
}
