ad_page_contract {

    This script will:

    (1) put this order into the 'confirmed' state
    (2) try to authorize the user's credit card info and either
    (a) redirect them to a thank you page, or
    (b) redirect them to a "please fix your credit card info" 
    page

    @author
    @creation-date
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author and Walter McGinnis (wtem@olywa.net)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} {
    user_id:integer,notnull,optional
    participant_id:integer,optional
}

set user_session_id [ec_get_user_session_id]

# Require user to be logged in at this point
source [acs_root_dir]/packages/dotlrn-ecommerce/www/ecommerce/check-shopping-cart.tcl

# If they reload, we don't have to worry about the credit card
# authorization code being executed twice because the order has
# already been moved to the 'confirmed' state, which means that they
# will be redirected out of this page.  We will redirect them to the
# thank you page which displays the order with the most recent
# confirmation date.  The only potential problem is that maybe the
# first time the order got to this page it was confirmed but then
# execution of the page stopped before authorization of the order
# could occur.  This problem is solved by the scheduled procedure,
# ec_query_for_payment_zombies, which will try to authorize any
# 'confirmed' orders over half an hour old.

ec_redirect_to_https_if_possible_and_necessary

set return_url [export_vars -base thank-you { user_id }]

# first do all the normal checks to make sure nobody is doing url
# or cookie surgery to get here

# we need them to be logged in
#set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]"

    ad_returnredirect "[ad_conn package_url]login?[export_url_vars return_url]"
    ad_script_abort
}

# make sure they have an in_basket order
# unlike previous pages, if they don't have an in_basket order
# it may be because they tried to execute this code twice and
# the order is already in the confirmed state
# In this case, they should be redirected to the thank you
# page for the most recently confirmed order, if one exists,
# otherwise redirect them to index.tcl

# user session tracking

ec_log_user_as_user_id_for_this_session

set order_id [db_string  get_order_id "
    select order_id 
    from ec_orders
    where user_session_id = :user_session_id
    and order_state = 'in_basket'"  -default ""]

if { [empty_string_p $order_id] } {

    # Find their most recently confirmed order

    set most_recently_confirmed_order [db_string get_mrc_order "
	select order_id 
        from ec_orders
	where user_id=:user_id
	and confirmed_date is not null
	and order_id = (select max(o2.order_id)
			from ec_orders o2
                        where o2.user_id=:user_id
			and o2.confirmed_date is not null)" -default ""]

    if { [empty_string_p $most_recently_confirmed_order] } {
        ns_log Notice "finalize-order.tcl ref(84): no confirmed order for user $user_id. Redirecting user."
    }
    ad_returnredirect ..
    ad_script_abort
}

# Make sure there's something in their shopping cart, otherwise
# redirect them to their shopping cart which will tell them that it's
# empty.

# We may want to make this a redirect to insecure location

if { [db_string get_in_basket_count "
    select count(*) 
    from ec_items 
    where order_id = :order_id"] == 0 } {
    ad_returnredirect [export_vars -base shopping-cart { user_id }]
    ad_script_abort
}

# Make sure the order belongs to this user_id, otherwise they managed
# to skip past checkout.tcl, or they messed w/their user_session_id
# cookie

set order_owner [db_string get_order_owner "
    select user_id 
    from ec_orders 
    where order_id = :order_id"]
if { $order_owner != $user_id } {
    ad_returnredirect [export_vars -base checkout-one-form { user_id }]
    ad_script_abort
}

# Make sure there is an address for this order, otherwise they've
# probably gotten here via url surgery, so redirect them to
# checkout.tcl

set address_id [db_string get_a_shipping_address "
    select shipping_address 
    from ec_orders 
    where order_id=:order_id" -default ""]
if { [empty_string_p $address_id] } {

    # No shipping address is needed if the order only consists of soft
    # goods not requiring shipping.

    if {[db_0or1row shipping_avail "
	select p.no_shipping_avail_p, count (*)
	from ec_items i, ec_products p
	where i.product_id = p.product_id
	and p.no_shipping_avail_p = 'f' 
	and i.order_id = :order_id
	group by no_shipping_avail_p"]} {
	ad_returnredirect [export_vars -base checkout-one-form { user_id }]
        ad_script_abort
    }
}

# Make sure there is a credit card (or that the
# gift_certificate_balance covers the cost) and a shipping method for
# this order, otherwise they've probably gotten here via url surgery,
# so redirect them to checkout-2.tcl

set creditcard_id [db_string get_creditcard_id "
    select creditcard_id 
    from ec_orders 
    where order_id=:order_id" -default ""]

if { [empty_string_p $creditcard_id] } {

    # We only want price and shipping from this (to determine whether
    # gift_certificate covers cost)

    set price_shipping_gift_certificate_and_tax [ec_price_shipping_gift_certificate_and_tax_in_an_order $order_id]
    set order_total_price_pre_gift_certificate [expr [lindex $price_shipping_gift_certificate_and_tax 0] + [lindex $price_shipping_gift_certificate_and_tax 1]]
    set gift_certificate_balance [db_string get_gc_balance "
	select ec_gift_certificate_balance(:user_id) 
	from dual"]
    if { $gift_certificate_balance < $order_total_price_pre_gift_certificate } {
	set gift_certificate_covers_cost_p "f"
    } else {
	set gift_certificate_covers_cost_p "t"
    }
}

# set shipping_method [db_string get_shipping_method "
#     select shipping_method 
#     from ec_orders
#     where order_id=:order_id" -default ""]
# if { [empty_string_p $shipping_method] || ([empty_string_p $creditcard_id] && (![info exists gift_certificate_covers_cost_p] || $gift_certificate_covers_cost_p == "f")) } {
#     rp_internal_redirect checkout-2
#     ad_script_abort
# }

# Done with all the checks!

# (1) put this order into the 'confirmed' state

db_transaction {
    ec_update_state_to_confirmed $order_id
}

set method [db_string payment_method {
    select method
    from dotlrn_ecommerce_transactions
    where order_id = :order_id
} -default "cc"]

if { ! [empty_string_p $method] && $method != "cc" } {
    # Authorize this transaction without credit card
    dotlrn_ecommerce_email_new_order $order_id
    ec_update_state_to_authorized $order_id 

    # Call after-checkout callback
    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

    ad_returnredirect $return_url
    ad_script_abort
}

# (2) Try to authorize the user's credit card info and either
#     (a) send them email & redirect them to a thank you page, or
#     (b) redirect them to a "please fix your credit card info" page

set applied_certificate_amount [db_string get_applied_certificate_amount "
    select ec_order_gift_cert_amount(:order_id)"]
db_1row get_soft_goods_costs "
    select coalesce(sum(i.price_charged),0) - coalesce(sum(i.price_refunded),0) as soft_goods_cost,
        coalesce(sum(i.price_tax_charged),0) - coalesce(sum(i.price_tax_refunded),0) as soft_goods_tax
    from ec_items i, ec_products p
    where i.order_id = :order_id
    and i.item_state <> 'void'
    and i.product_id = p.product_id
    and p.no_shipping_avail_p = 't'"
db_1row get_hard_goods_costs "
    select coalesce(sum(i.price_charged),0) - coalesce(sum(i.price_refunded),0) as hard_goods_cost,
        coalesce(sum(i.price_tax_charged),0) - coalesce(sum(i.shipping_refunded),0) as hard_goods_tax,
        coalesce(sum(i.shipping_charged),0) - coalesce(sum(i.shipping_refunded),0) as hard_goods_shipping,
        coalesce(sum(i.shipping_tax_charged),0) - coalesce(sum(i.shipping_tax_refunded),0) as hard_goods_shipping_tax
    from ec_items i, ec_products p
    where i.order_id = :order_id
    and i.item_state <> 'void'
    and i.product_id = p.product_id
    and p.no_shipping_avail_p = 'f'"
set order_shipping [db_string get_order_shipping "
    select coalesce(shipping_charged, 0)
    from ec_orders
    where order_id = :order_id"]
set order_shipping_tax [db_string get_order_shipping_tax "
    select ec_tax(0, :order_shipping, :order_id)"]

# Charge soft goods separately from hard goods as the hard goods
# transaction will not settled until the goods are shipped while soft
# goods can be settled right away.

if {$hard_goods_cost > 0} {

    # The order contains hard goods that come at a cost.

    if {$soft_goods_cost > 0} {
	
	# The order contains both hard and soft goods that come at a
	# cost.

	if {$applied_certificate_amount >= [expr $soft_goods_cost + $soft_goods_tax]} {
	    
	    # The applied certificates cover the cost of the soft
	    # goods. 

	    if {[expr $applied_certificate_amount - $soft_goods_cost - $soft_goods_tax] >= [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping + $hard_goods_shipping_tax + \
												$order_shipping + $order_shipping_tax]} {

		# The applied certificates cover the cost of the soft
		# goods as well as the hard goods. No financial
		# transactions required. Mail the confirmation e-mail
		# to the user.
		
		# FIXME DAVEB this sends email not controlled directly by dotlrn-ecommerce
		# this sends the ecommerce email template 1
		dotlrn_ecommerce_email_new_order $order_id

		# Change the order state from 'confirmed' to
		# 'authorized'.

		ec_update_state_to_authorized $order_id 

		# Call after-checkout callback
		callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		ad_returnredirect $return_url

	    } else {

		# The applied certificates cover the cost of the soft
		# goods but not of the hard goods. Create a new
		# financial transaction

		set transaction_id [db_nextval ec_transaction_id_sequence]
		set transaction_amount [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping + $hard_goods_shipping_tax + $order_shipping + $order_shipping_tax - \
					    [expr $applied_certificate_amount - $soft_goods_cost - $soft_goods_tax]]
		if { ![empty_string_p $creditcard_id] } {
		    db_dml insert_financial_transaction "
		    insert into ec_financial_transactions
		    (creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		    values
		    (:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"
		}

		array set response [ec_creditcard_authorization $order_id $transaction_id]
		set result $response(response_code)
		set transaction_id $response(transaction_id)
		if { [string equal $result "authorized"] } {
		    dotlrn_ecommerce_email_new_order $order_id

		    # Change the order state from 'confirmed' to
		    # 'authorized'.

		    ec_update_state_to_authorized $order_id 

		    # Call after-checkout callback
		    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		    # Record the date & time of the authorization.

		    db_dml update_authorized_date "
			update ec_financial_transactions 
			set authorized_date = sysdate
			where transaction_id = :transaction_id"
		}

		if { [string equal $result "authorized"] || [string equal $result "no_recommendation"] } {
		    ad_returnredirect $return_url
                    ad_script_abort
		} elseif { [string equal $result "failed_authorization"] } {

		    # Updates everything that needs to be updated if a
		    # confirmed order fails

		    ec_update_state_to_in_basket $order_id

                    # authorization error is not necessarily the fault of the user's card, so log it for identifying pattern for diagnostics
                    ns_log Notice "finalize-order.tcl ref(295): failed_authorization for order_id: $order_id. Redirecting user to credit-card-correction."
		    
		    ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
                    ad_script_abort
		} else {

		    # Then result is probably "invalid_input".  This should never
		    # occur

		    ns_log Notice "Order $order_id received a result of $result"
		    ad_return_error "Sorry" "
			<p>There has been an error in the processing of your credit card information.
			   Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
                    ad_script_abort
		}
	    }
	} else {

	    # The applied certificates do no cover the cost of the
	    # soft goods.

	    if {$applied_certificate_amount >= [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping + $hard_goods_shipping_tax + \
						    $order_shipping + $order_shipping_tax]} {

		# The applied certificates cover the cost of the hard
		# goods but not the soft goods. Create a new financial
		# transaction.

		set transaction_id [db_nextval ec_transaction_id_sequence]
		set transaction_amount [expr $soft_goods_cost + $soft_goods_tax - \
					    [expr $applied_certificate_amount - [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping + $hard_goods_shipping_tax + \
										     $order_shipping + $order_shipping_tax]]] 
		if { ![empty_string_p $creditcard_id] } {
		    db_dml insert_financial_transaction "
		    insert into ec_financial_transactions
		    (creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		    values
		    (:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"
		}

		array set response [ec_creditcard_authorization $order_id $transaction_id]
		set result $response(response_code)
		set transaction_id $response(transaction_id)
		if { [string equal $result "authorized"] } {
		    dotlrn_ecommerce_email_new_order $order_id

		    # Change the order state from 'confirmed' to
		    # 'authorized'.

		    ec_update_state_to_authorized $order_id 
		    
		    # Call after-checkout callback
		    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		    # Record the date & time of the authorization and
		    # schedule the transaction for settlement.

		    db_dml schedule_settlement "
			update ec_financial_transactions 
			set authorized_date = sysdate, to_be_captured_p = 't', to_be_captured_date = sysdate
			where transaction_id = :transaction_id"

		    # Mark the transaction now, rather than waiting
		    # for the scheduled procedures to mark the
		    # transaction.

		    array set response [ec_creditcard_marking $transaction_id]
		    set mark_result $response(response_code)
		    set pgw_transaction_id $response(transaction_id)
		    if { [string equal $mark_result "invalid_input"]} {
			set problem_details "
			    When trying to mark the transaction for the items that don't require shipment (transaction $transaction_id) at [ad_conn url], the following result occurred: $mark_result"
			db_dml record_marking_problem "
			    insert into ec_problems_log
			    (problem_id, problem_date, problem_details, order_id)
			    values
			    (ec_problem_id_sequence.nextval, sysdate, :problem_details, :order_id)"
		    } elseif {[string equal $mark_result "success"]} {
			db_dml update_marked_date "
			    update ec_financial_transactions 
			    set marked_date = sysdate
			    where transaction_id = :pgw_transaction_id"
		    }

 		    ad_returnredirect $return_url

		} elseif { [string equal $result "failed_authorization"] || [string equal $result "no_recommendation"] } {

		    # If the gateway returns no recommendation then
		    # possibility remains that the card is invalid and
		    # that soft goods have been 'shipped' because the
		    # gateway was down and could not verify the soft
		    # goods transaction. The store owner then depends
		    # on the honesty of visitor to obtain a new valid
		    # credit card for the 'shipped' products.

		    if {[string equal $result "no_recommendation"] } {

			# Therefor reject the transaction and ask for
			# (a new credit card and ask) the visitor to
			# retry. Most credit card gateways have
			# uptimes close to 99% so this scenario should
			# not happen often. Another reason for
			# rejecting transactions without
			# recommendation is that the scheduled
			# procedures can't authorize soft goods
			# transactions properly.

			db_dml set_transaction_failed "
			    update ec_financial_transactions
			    set failed_p = 't'
			    where transaction_id = :transaction_id"

		    }

		    # Updates everything that needs to be updated if a
		    # confirmed order fails

		    ec_update_state_to_in_basket $order_id
                    ns_log Notice "finalize-order.tcl ref(411): updated creditcard check failed for order_id $order_id. Redirecting to credit-card-correction"
		    ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
                    ad_script_abort
		} else {

		    # Then result is probably "invalid_input".  This should never
		    # occur

		    ns_log Notice "Order $order_id received a result of $result"
		    ad_return_error "Sorry" "
			<p>There has been an error in the processing of your credit card information.
			   Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
		    ad_script_abort
		}
	    } else {

		# The applied certificates cover neither the cost of
		# the hard goods nor the soft goods. Create separate
		# transactions for the soft goods and the hard goods.

		set transaction_id [db_nextval ec_transaction_id_sequence]
		set transaction_amount [expr $soft_goods_cost + $soft_goods_tax - $applied_certificate_amount]
		if { ![empty_string_p $creditcard_id] } {
		    db_dml insert_financial_transaction "
		    insert into ec_financial_transactions
		    (creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		    values
		    (:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"
		}

		array set response [ec_creditcard_authorization $order_id $transaction_id]
		set result $response(response_code)
		set soft_goods_transaction_id $response(transaction_id)
		if { [string equal $result "authorized"] } {
		    dotlrn_ecommerce_email_new_order $order_id

		    # Record the date & time of the soft goods
		    # authorization.

		    set transaction_id $soft_goods_transaction_id
		    db_dml update_authorized_date "
			update ec_financial_transactions 
			set authorized_date = sysdate
			where transaction_id = :transaction_id"
		    
		    # Calculate the transaction amount for the hard
		    # goods.

		    set transaction_amount [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping + $hard_goods_shipping_tax + $order_shipping + $order_shipping_tax + \
						$soft_goods_cost + $soft_goods_tax - $transaction_amount]
		    set transaction_id [db_nextval ec_transaction_id_sequence]
		    if { ![empty_string_p $creditcard_id] } {
			db_dml insert_financial_transaction "
			insert into ec_financial_transactions
			(creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
			values
			(:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"
		    }

		    array set response [ec_creditcard_authorization $order_id $transaction_id]
		    set result $response(response_code)
		    set hard_goods_transaction_id $response(transaction_id)
		    if { [string equal $result "authorized"] } {

			# Both transactions are approved. Change the
			# order state from 'confirmed' to
			# 'authorized'.

			ec_update_state_to_authorized $order_id 

			# Call after-checkout callback
			callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

			# Schedule the soft goods transaction for
			# settlement.

			set transaction_id $soft_goods_transaction_id
			db_dml schedule_settlement_soft_goods "
			    update ec_financial_transactions 
			    set to_be_captured_p = 't', to_be_captured_date = sysdate
			    where transaction_id = :transaction_id"

			# Mark the transaction now, rather than
			# waiting for the scheduled procedures to mark
			# the transaction.

			array set response [ec_creditcard_marking $transaction_id]
			set mark_result $response(response_code)
			set pgw_transaction_id $response(transaction_id)
			if { [string equal $mark_result "invalid_input"]} {
			    set problem_details "
				When trying to mark the transaction for the items that don't require shipment (transaction $transaction_id) at [ad_conn url], the following result occurred: $mark_result"
			    db_dml record_marking_problem "
				insert into ec_problems_log
				(problem_id, problem_date, problem_details, order_id)
				values
				(ec_problem_id_sequence.nextval, sysdate, :problem_details, :order_id)"
			} elseif {[string equal $mark_result "success"]} {
			    db_dml update_marked_date "
				update ec_financial_transactions 
				set marked_date = sysdate
				where transaction_id = :pgw_transaction_id"
			}

			# Record the date & time of the hard goods
			# authorization.
			
			set transaction_id $hard_goods_transaction_id
			db_dml update_authorized_date "
			    update ec_financial_transactions 
			    set authorized_date = sysdate
			    where transaction_id = :transaction_id"
			
			ad_returnredirect $return_url
			
		    } elseif {[string equal $result "failed_authorization"] || [string equal $result "no_recommendation"] } {

			# Record both transactions as failed and ask
			# for a new credit card number. The second
			# transaction could have failed because it
			# maxed out the card. Both transactions need
			# to failed as the user might choose to use a
			# different card and this procedure doesn't
			# check for prior authorized transactions.

			set transaction_id $soft_goods_transaction_id
			db_dml set_transaction_failed "
			    update ec_financial_transactions
			    set failed_p = 't'
			    where transaction_id = :transaction_id"

			set transaction_id $hard_goods_transaction_id
			db_dml set_transaction_failed "
			    update ec_financial_transactions
			    set failed_p = 't'
			    where transaction_id = :transaction_id"

			# Updates everything that needs to be updated if a
			# confirmed order fails

			ec_update_state_to_in_basket $order_id
                        ns_log Notice "finalize-order.tcl ref(544): creditcard check failed. Redirecting user to credit-card-correction."
			ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
			ad_script_abort
		    } else {

			# Then result is probably
			# "invalid_input". This should never occur

			ns_log Notice "Order $order_id received a result of $result"
			ad_return_error "Sorry" "
			    <p>There has been an error in the processing of your credit card information.
			       Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
			ad_script_abort
		    }
		} elseif { [string equal $result "failed_authorization"] || [string equal $result "no_recommendation"] } {
		    
		    set transaction_id $soft_goods_transaction_id
		    db_dml set_transaction_failed "
			update ec_financial_transactions
			set failed_p = 't'
			where transaction_id = :transaction_id"

		    # Updates everything that needs to be updated if a
		    # confirmed order fails

		    ec_update_state_to_in_basket $order_id

		    ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
		    ad_script_abort
		} else {

		    # Then result is probably "invalid_input".  This should never
		    # occur

		    ns_log Notice "Order $order_id received a result of $result"
		    ad_return_error "Sorry" "
			<p>There has been an error in the processing of your credit card information.
			   Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
		    ad_script_abort
		}
	    }
	}
    } else {

	# The order contains only hard goods that come at a cost.

	if {$applied_certificate_amount >= [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping  + $hard_goods_shipping_tax + $order_shipping + $order_shipping_tax]} {

	    # The applied certificates cover the cost of the hard
	    # goods. No financial transaction required.

	    # Mail the confirmation e-mail to the user.

	    dotlrn_ecommerce_email_new_order $order_id

	    # Change the order state from 'confirmed' to
	    # 'authorized'.

	    ec_update_state_to_authorized $order_id 

	    # Call after-checkout callback
	    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

	    ad_returnredirect $return_url

	} else {

	    # The applied certificates only partially covered the cost
	    # of the hard goods. Create a new financial transaction.

	    set transaction_id [db_nextval ec_transaction_id_sequence]
	    set transaction_amount [expr $hard_goods_cost + $hard_goods_tax + $hard_goods_shipping  + $hard_goods_shipping_tax + $order_shipping + $order_shipping_tax - \
					[expr $applied_certificate_amount - $soft_goods_cost - $soft_goods_tax]]
	    if { ![empty_string_p $creditcard_id] } {
		db_dml insert_financial_transaction "
		insert into ec_financial_transactions
		(creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		values
		(:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"
	    }

	    array set response [ec_creditcard_authorization $order_id $transaction_id]
	    set result $response(response_code)
	    set transaction_id $response(transaction_id)
	    if { [string equal $result "authorized"] } {
		dotlrn_ecommerce_email_new_order $order_id

		# Change the order state from 'confirmed' to
		# 'authorized'.

		ec_update_state_to_authorized $order_id 

		# Call after-checkout callback
		callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		# Record the date & time of the authorization.

		db_dml update_authorized_date "
		    update ec_financial_transactions 
		    set authorized_date = sysdate
		    where transaction_id = :transaction_id"
	    }

	    if { [string equal $result "authorized"] || [string equal $result "no_recommendation"] } {
		ad_returnredirect $return_url
                ad_script_abort
	    } elseif { [string equal $result "failed_authorization"] } {

		# If the gateway returns no recommendation then
		# possibility remains that the card is invalid and
		# that soft goods have been 'shipped' because the
		# gateway was down and could not verify the soft goods
		# transaction. The store owner then depends on the
		# honesty of visitor to obtain a new valid credit card
		# for the 'shipped' products.

		if {[string equal $result "no_recommendation"] } {

		    # Therefor reject the transaction and ask for (a
		    # new credit card and ask) the visitor to
		    # retry. Most credit card gateways have uptimes
		    # close to 99% so this scenario should not happen
		    # often. Another reason for rejecting transactions
		    # without recommendation is that the scheduled
		    # procedures can't authorize soft goods
		    # transactions properly.

		    db_dml set_transaction_failed "
			update ec_financial_transactions
			set failed_p = 't'
			where transaction_id = :transaction_id"

		}

		# Updates everything that needs to be updated if a
		# confirmed order fails

		ec_update_state_to_in_basket $order_id

                # log this just in case this is a symptom of an extended gateway downtime
                ns_log Notice "finalize-order.tcl, ref(671): creditcard check failed for order_id $order_id. Redirecting to credit-card-correction"

		ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
                ad_script_abort
	    } else {

		# Then result is probably "invalid_input".  This should never
		# occur

		ns_log Notice "Order $order_id received a result of $result"
		ad_return_error "Sorry" "
		    <p>There has been an error in the processing of your credit card information.
		    Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
		ad_script_abort
	    }
	}
    }
} else {
    
    # The order does not contain any hard goods that come at a cost.
    
    if {$soft_goods_cost > 0} {
	
	# The order contains only soft goods that come at a cost.

	if {$applied_certificate_amount >= [expr $soft_goods_cost + $soft_goods_tax]} {

	    # The gift certificates cover the cost of the soft
	    # goods. No financial transaction required. Mail a
	    # confirmation e-mail to the user.

	    dotlrn_ecommerce_email_new_order $order_id

	    # Change the order state from 'confirmed' to
	    # 'authorized'.

	    ec_update_state_to_authorized $order_id 

	    # Call after-checkout callback
	    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id
	    
	    ad_returnredirect $return_url
	    ad_script_abort
	} else {

	    # The certificates only partially cover the cost of the
	    # soft goods. Create a new financial transaction

	    set transaction_id [db_nextval ec_transaction_id_sequence]
	    set transaction_amount [expr $soft_goods_cost + $soft_goods_tax - $applied_certificate_amount]

	    if { ![empty_string_p $creditcard_id] } {
		db_dml insert_financial_transaction "
		insert into ec_financial_transactions
		(creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		values
		(:creditcard_id, :transaction_id, :order_id, :transaction_amount, 'charge', sysdate)"

		array set response [ec_creditcard_authorization $order_id $transaction_id]

		set result $response(response_code)
		set transaction_id $response(transaction_id)
		if { [string equal $result "authorized"] } {
		    dotlrn_ecommerce_email_new_order $order_id
		    
		    # Change the order state from 'confirmed' to
		    # 'authorized'.

		    ec_update_state_to_authorized $order_id 

		    # Call after-checkout callback
		    callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		    # Record the date & time of the authorization and
		    # schedule the transaction for settlement.

		    db_dml schedule_settlement "
			update ec_financial_transactions 
			set authorized_date = sysdate, to_be_captured_p = 't', to_be_captured_date = sysdate
			where transaction_id = :transaction_id"

		    # Mark the transaction now, rather than waiting for
		    # the scheduled procedures to mark the transaction.

		    array set response [ec_creditcard_marking $transaction_id]
		    set mark_result $response(response_code)
		    set pgw_transaction_id $response(transaction_id)
		    if { [string equal $mark_result "invalid_input"]} {
			set problem_details "
			When trying to mark the transaction for the items that don't require shipment (transaction $transaction_id) at [ad_conn url], the following result occurred: $mark_result"
			db_dml record_marking_problem "
			insert into ec_problems_log
			(problem_id, problem_date, problem_details, order_id)
			values
			(ec_problem_id_sequence.nextval, sysdate, :problem_details, :order_id)"
		    } elseif {[string equal $mark_result "success"]} {
			db_dml update_marked_date "
			update ec_financial_transactions 
			set marked_date = sysdate
			where transaction_id = :pgw_transaction_id"
		    }
		    ad_returnredirect $return_url
		    ad_script_abort
		}
	    } else {
		# Gift cert covers cost, no cc transaction needed,
		# authorize immediately
		ec_update_state_to_authorized $order_id

		# Call after-checkout callback
		callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

		ad_returnredirect $return_url
		ad_script_abort
	    }

	    if {[string equal $result "failed_authorization"] || [string equal $result "no_recommendation"] } {

		# If the gateway returns no recommendation then the
		# possibility remains that the card is invalid and
		# that soft goods have been 'shipped' because the
		# gateway was down and could not verify the soft goods
		# transaction. The store owner then depends on the
		# honesty of visitor to obtain a new valid credit card
		# for the 'shipped' products.

		if {[string equal $result "no_recommendation"] } {

		    # Therefor reject the transaction and ask for (a
		    # new credit card and ask) the visitor to
		    # retry. Most credit card gateways have uptimes
		    # close to 99% so this scenario should not happen
		    # often. Another reason for rejecting transactions
		    # without recommendation is that the scheduled
		    # procedures can't authorize soft goods
		    # transactions properly.

		    db_dml set_transaction_failed "
			update ec_financial_transactions
			set failed_p = 't'
			where transaction_id = :transaction_id"

		}
		
		# Updates everything that needs to be updated if a
		# confirmed order fails
		
		ec_update_state_to_in_basket $order_id
                ns_log Notice "finalize-order.tcl ref(789): creditcard check failed. Redirecting to credit-card-correction"		
		ad_returnredirect [export_vars -base checkout-one-form { user_id {invalid_cc_p 1} }]
                ad_script_abort

	    } else {
		
		# Then result is probably "invalid_input".  This should never
		# occur

		ns_log Notice "Order $order_id received a result of $result"
		ad_return_error "Sorry" "
			<p>There has been an error in the processing of your credit card information.
			   Please contact <a href=\"mailto:[ec_system_owner]\">[ec_system_owner]</a> to report the error.</p>"
		ad_script_abort
	    }
	}
    } else {

	# The order contains neither hard nor soft goods that come at
	# a cost. No financial transactions required. Mail the
	# confirmation e-mail to the user.

	dotlrn_ecommerce_email_new_order $order_id

	# Change the order state from 'confirmed' to
	# 'authorized'.

	ec_update_state_to_authorized $order_id 

	# Call after-checkout callback
	callback -- ecommerce::after-checkout -patron_id $user_id -order_id $order_id

	ad_returnredirect $return_url
    }
}
