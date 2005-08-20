#  www/ecommerce/shopping-cart-delete-from.tcl
ad_page_contract {
    @param product_id
    @param color_choice
    @param size_choice
    @param style_choice
  @author
  @creation-date
  @cvs-id $Id$
  @author ported by Jerry Asher (jerry@theashergroup.com)
} {
    product_id:integer

    color_choice:optional
    size_choice:optional
    style_choice:optional

    user_id:integer,notnull
    patron_id:integer,notnull,optional
    participant_id:integer,notnull,optional
}


set user_session_id [ec_get_user_session_id]




set order_id [db_string get_order_id "select order_id from ec_orders where user_session_id=:user_session_id and order_state='in_basket'" -default ""]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # into their empty shopping cart
    rp_internal_redirect shopping-cart
    ad_script_abort
}

if { [exists_and_not_null patron_id] && [exists_and_not_null participant_id] } {
    if { [acs_object_type $participant_id] == "group" } {
	set process_purchase_clause [db_map delete_item_from_cart_purchase_process_group]
    } else {
	set process_purchase_clause [db_map delete_item_from_cart_purchase_process]
    }
} else {
    set process_purchase_clause ""
}

db_dml delete_item_from_cart "delete from ec_items where order_id=:order_id and product_id=:product_id and color_choice [ec_decode $color_choice "" "is null" "= :color_choice"] and size_choice [ec_decode $size_choice "" "is null" "= :size_choice"] and style_choice [ec_decode $style_choice "" "is null" "= :style_choice"]"
db_release_unused_handles

if { [acs_object_type $participant_id] == "group" } {
    # we also remove the last member from the group
    set user_id_to_remove [db_string get_uid_to_remove {
	select max(member_id)
	from group_member_map
	where group_id = :participant_id
    } -default 0]
    if {$user_id_to_remove} {
	group::remove_member -group_id $participant_id -user_id $user_id_to_remove
    }
}

# DEDS
# at this point if user is deleting
# a member product then we probably need to adjust
# any other products in basket
if {[parameter::get -parameter MemberPriceP -default 0]} {
    set ec_category_id [parameter::get -parameter "MembershipECCategoryId" -default ""]
    if {![empty_string_p $ec_category_id]} {
	if {[db_string membership_product_p {
	    select count(*)
	    from ec_category_product_map
	    where category_id = :ec_category_id
	    and product_id = :product_id
	}]} {
	    dotlrn_ecommerce::ec::toggle_offer_codes -order_id $order_id
	}
    }
}

# Flush cache
if { [db_0or1row section_from_product {
    select section_id
    from dotlrn_ecommerce_section
    where product_id = :product_id
}] } {
    dotlrn_ecommerce::section::flush_cache $section_id
}

rp_internal_redirect shopping-cart
