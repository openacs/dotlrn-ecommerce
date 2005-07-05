# packages/dotlrn-ecommerce/www/ecommerce/check-shopping-cart.tcl

# WARNING: only meant to be sourced from ecommerce pages in the same directory

if { ! [info exists user_id] } {
    set user_id [ad_verify_and_get_user_id]
} elseif { $user_id == 0 } {
    set user_id [ad_verify_and_get_user_id]
}
if {$user_id == 0} {
    set form [rp_getform]
    ns_set delkey $form user_id
    set return_url [ad_return_url]
    ad_returnredirect [export_vars -base login {return_url}]
    ad_script_abort
} else {
    # Make sure all orders are owned by the user
    db_transaction {
	db_foreach orders {
	    select order_id as in_basket_order_id
	    from ec_orders
	    where order_state = 'in_basket'
	    and user_session_id = :user_session_id
	} {
	    db_dml set_session_orders {
		update ec_orders
		set user_id = :user_id
		where order_id = :in_basket_order_id
		and user_id = 0
	    }
	    
	    db_foreach items { 
		select item_id as in_basket_item_id
		from ec_items
		where order_id = :in_basket_order_id
	    } {
		db_dml set_dotlrn_ecommerce_orders {
		    update dotlrn_ecommerce_orders
		    set patron_id = :user_id
		    where item_id = :in_basket_item_id
		    and patron_id = 0
		}
		db_dml set_dotlrn_ecommerce_orders_2 {
		    update dotlrn_ecommerce_orders
		    set participant_id = :user_id
		    where item_id = :in_basket_item_id
		    and participant_id = 0
		}
	    }
	}
    }
}
