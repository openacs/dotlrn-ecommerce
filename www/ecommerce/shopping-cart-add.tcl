ad_page_contract {

    This adds an item to an 'in_basket' order, although if there
    exists a 'confirmed' order for this user_session_id, the user is
    told they have to wait because 'confirmed' orders can potentially
    become 'in_basket' orders (if authorization fails), and we can
    only have one 'in_basket' order for this user_session_id at a
    time.  Most orders are only in the 'confirmed' state for a few
    seconds, except for those whose credit card authorizations are
    inconclusive.  Furthermore, it is unlikely for a user to start
    adding things to their shopping cart right after they've made an
    order.  So this case is unlikely to occur often.  I will include a
    ns_log Notice so that any occurrences will be logged.

    @param product_id:integer
    @param size_choice
    @param color_choice
    @param style_choice
    @param usca_p:optional

    @author
    @creation-date
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} { 
    product_id:integer
    {item_count 1}
    {size_choice ""}
    {color_choice ""}
    {style_choice ""}
    usca_p:optional

    user_id:integer,notnull
    {participant_id:integer 0}
    
    {override_p 0}
}

# avoid anonymous participants
if {$user_id == 0} {
    set user_id [auth::require_login]
}

# Roel: Participant also pays
if { $participant_id == 0 } {
    set participant_id $user_id
}

db_0or1row section_info {
    select section_id, community_id
    from dotlrn_ecommerce_section
    where product_id = :product_id
}

if { [acs_object_type $participant_id] != "group" } {
    ns_log notice "DEBUG:: checking if this should go to the waiting list"

    set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin]

    if { [exists_and_not_null community_id] } {
	ns_log notice "DEBUG:: checking available slots"
	set member_state [db_string awaiting_approval {
	    select m.member_state
	    from acs_rels r,
	    membership_rels m
	    where r.rel_id = m.rel_id
	    and r.object_id_one = :community_id
	    and r.object_id_two = :participant_id
	    limit 1
	} -default ""]

	if { $member_state != "approved" &&
	     $member_state != "waitinglist approved" &&
	     $member_state != "request approved" &&
	     $member_state != "payment received" &&
	     ($override_p == 0 || $admin_p == 0)
	 } {

	    # Check application assessment
	    if { [db_0or1row get_assessment {
		select c.assessment_id

		from dotlrn_ecommerce_section s,
		dotlrn_catalogi c,
		cr_items i

		where s.course_id = c.item_id
		and c.item_id = i.item_id
		and i.live_revision = c.course_id
		and s.product_id = :product_id

		limit 1
	    }] } {
		if { ! [empty_string_p $assessment_id] && $assessment_id != -1 } {
		    set return_url [export_vars -base "[ad_conn package_url]application-confirm" { product_id {member_state "awaiting payment"} }]
		    ad_returnredirect [export_vars -base application-request { participant_id community_id {next_url $return_url} { type payment } }]
		    ad_script_abort
		    
		}
	    }

	    # Check if the section is full
	    # and if prerequisites are met
	    
	    # Is section full?
	    set available_slots [dotlrn_ecommerce::section::available_slots $section_id]

	    if { $available_slots == 0 } {
		# No more slots left, ask user if he wants to go to
		# waiting list
		
		if { $admin_p && $user_id != [ad_conn user_id] } {
		    set cancel_url [set return_url [export_vars -base [ad_conn package_url]admin/process-purchase-course { user_id }]]
		} else {
		    set return_url [export_vars -base [ad_conn package_url]application-confirm { product_id {member_state "needs approval"} }]
		    set cancel_url ..
		}
		ad_returnredirect [export_vars -base waiting-list-confirm { product_id user_id participant_id return_url cancel_url }]
		ad_script_abort
	    }

	    # Are prerequisites met?
	    ns_log notice "DEBUG:: checking prerequisites"
	    set prereq_not_met 0
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
			    incr prereq_not_met
			}
		    }
		} else {
		    incr prereq_not_met
		}
	    }

	    if { $prereq_not_met > 0 } {
		ns_log notice "DEBUG:: prerequisites not met"
		if { $admin_p && $user_id != [ad_conn user_id] } {
		    set cancel_url [set return_url [export_vars -base [ad_conn package_url]admin/process-purchase-course { user_id }]]
		} else {
		    set return_url [export_vars -base [ad_conn package_url]ecommerce/application-confirm { product_id {member_state "request approval"} }]
		    set cancel_url [ad_conn package_url]
		}
		ad_returnredirect [export_vars -base prerequisite-confirm { product_id user_id participant_id return_url cancel_url }]
		ad_script_abort
	    }
	}
    }

}

# added default values to above params so that this page works
# when a post from a form to shopping-cart-add originates from another domain.

# 1. get user_session_id
# 1.5 see if there exists a 'confirmed' order for this user_session_id
# 2. get order_id
# 3. get item_id
# 4. put item into ec_items, unless there is already an item with that product_id
#    in that order (this is double click protection -- the only way they can increase
#    the quantity of a product in their order is to click on "update quantities" on
#    the shopping cart page (shopping-cart.tcl)
# 5. ad_returnredirect them to their shopping cart

set user_session_id [ec_get_user_session_id]
ec_create_new_session_if_necessary [export_url_vars product_id user_id participant_id item_count]
set n_confirmed_orders [db_string get_n_confirmed_orders "
    select count(*) 
    from ec_orders 
    where user_session_id = :user_session_id
    and order_state = 'confirmed'"]
if { $n_confirmed_orders > 0 } {
    ad_return_complaint 1 "
	<p>Sorry, you have an order for which credit card authorization has not yet taken place. 
	Please wait for the authorization to complete before adding new items to your shopping cart.</p>
	<p>Thank you.</p>"
    ns_log Warning "shopping-cart-add.tcl,line59: User tried to add an item to the shopping cart after making a purchase, but was rejected!"
    ad_script_abort
}

set order_id [db_string get_order_id "
    select order_id
    from ec_orders
    where user_session_id = :user_session_id
    and order_state = 'in_basket'"  -default ""]

# Here's the airtight way to do it: do the check on order_id, then
# insert a new order where there doesn't exist an old one, then set
# order_id again (because the correct order_id might not be the one
# set inside the if statement).  It should now be impossible for
# order_id to be the empty string (if it is, log the error and
# redirect them to product.tcl).

if { [value_if_exists order_id] < 1 || [ad_var_type_check_number_p $order_id] == 0 } {
    set order_id [db_nextval ec_order_id_sequence]
  
    # Create the order (if an in_basket order *still* doesn't exist)

    db_dml insert_new_ec_order "
	insert into ec_orders
	(order_id, user_session_id, order_state, in_basket_date)
	select :order_id, :user_session_id, 'in_basket', sysdate from dual
	where not exists (select 1 from ec_orders where user_session_id = :user_session_id and order_state = 'in_basket')"

    # Now either an in_basket order should have been inserted by the
    # above statement or it was inserted by a different thread
    # milliseconds ago

    set order_id [db_string  get_order_id "
	select order_id
	from ec_orders
	where user_session_id = :user_session_id
	and order_state = 'in_basket'" -default ""]
    if { [empty_string_p $order_id] } {

	# I don't expect this to ever happen, but just in case, I'll
	# log the problem and redirect them to product.tcl

	set errormsg "Null order_id on shopping-cart-add.tcl for user_session_id :user_session_id.  Please report this problem to [ec_package_maintainer]."
	db_dml insert_problem_into_log "
	    insert into ec_problems_log
	    (problem_id, problem_date, problem_details)
	    values
	    (ec_problem_id_sequence.nextval, sysdate,:errormsg)"
	ad_returnredirect "product?[export_url_vars product_id]"
        ad_script_abort
    }
}

# Insert an item into that order if an identical item doesn't exist
# (this is double click protection).  If they want to update
# quantities, they can do so from the shopping cart page.  

# Bart Teeuwisse: Fine tuned the postgresql version to only reject
# items that were added to the shopping cart in the last 5 seconds.
# That should be enough to protect from double clicks yet provides a
# more intuitive user experience.

# DEDS: do we use the member price
set use_member_price_p 0
if {[parameter::get -parameter MemberPriceP -default 0]} {
    set ec_category_id [parameter::get -parameter "MembershipECCategoryId" -default ""]
    set group_id [parameter::get -parameter MemberGroupId -default 0]
    if {$group_id} {
	set use_member_price_p [group::member_p -group_id $group_id -user_id $user_id]
    }
    if {!$use_member_price_p} {
	if {![empty_string_p $ec_category_id]} {
	    set use_member_price_p [db_string get_in_basket {
		select count(*)
		from ec_orders o,
		ec_items i,
		ec_category_product_map m
		where o.user_session_id = :user_session_id
		and o.order_id = i.order_id
		and i.product_id = m.product_id
		and m.category_id = :ec_category_id
	    }]
	}
    }
}

for {set i 0} {$i < $item_count} {incr i} {
    db_transaction {
	set item_id [db_nextval ec_item_id_sequence]

	if { ( [exists_and_not_null participant_id] ) && [acs_object_type $participant_id] != "group" } {
	    set limit_order_p [expr ! [db_string order_exists {
		select count(*)
		from ec_items i, dotlrn_ecommerce_orders o, ec_orders eo
		where i.item_id = o.item_id
		and i.order_id = eo.order_id
		and i.product_id = :product_id
		and o.participant_id = :participant_id
		and eo.order_state = 'in_basket'
		and eo.user_session_id = :user_session_id
	    } -default 0]]
	} else {
	    set limit_order_p 1
	}
	    
	if { $limit_order_p } {
	    db_dml insert_new_item_in_order {}
	    
	    db_dml insert_new_item_order_dotlrn_ecommerce {
		insert into dotlrn_ecommerce_orders (item_id, patron_id, participant_id)
		values (:item_id, :user_id, :participant_id)
	    }
	} else {
	    # Update the order
	    db_dml update_item_order_dotlrn_ecommerce {
		update dotlrn_ecommerce_orders
		set patron_id = :user_id,
		participant_id = :participant_id
		where item_id = :item_id
	    }
	}
	if {$use_member_price_p} {
	    set offer_code [db_string get_offer_code {
                select offer_code
                from ec_sale_prices
                where product_id = :product_id
                      and offer_code = 'dotlrn-ecommerce'
	    } -default ""]
	    if {![empty_string_p $offer_code]} {
		# DEDS: at this point we need to insert or update an offer
		set offer_code_exists_p [db_string get_offer_code_p {
		    select count(*) 
		    from ec_user_session_offer_codes 
		    where user_session_id=:user_session_id
		    and product_id=:product_id
		}]
		if {$offer_code_exists_p} {
		    db_dml update_ec_us_offers {
			update ec_user_session_offer_codes 
			set offer_code = :offer_code
			where user_session_id = :user_session_id
			and product_id = :product_id
		    }
		} else {
		    db_dml inert_uc_offer_code {
			insert into ec_user_session_offer_codes
			(user_session_id, product_id, offer_code) 
			values 
			(:user_session_id, :product_id, :offer_code)
		    }
		}
	    }
	}
	# DEDS
	# at this point if user is purchasing
	# a member product then we probably need to adjust
	# any other products in basket
	if {[parameter::get -parameter MemberPriceP -default 0]} {
	    if {![empty_string_p $ec_category_id]} {
		if {[db_string membership_product_p {
		    select count(*)
		    from ec_category_product_map
		    where category_id = :ec_category_id
		    and product_id = :product_id
		}]} {
		    dotlrn_ecommerce::ec::toggle_offer_codes -order_id $order_id -insert
		}
	    }
	}
    }
}

# The order goes to the shopping cart, flush the cache
if { [info exists section_id] } {
    dotlrn_ecommerce::section::flush_cache -user_id $user_id $section_id
}

db_release_unused_handles
ad_returnredirect [export_vars -base shopping-cart { user_id product_id }]
