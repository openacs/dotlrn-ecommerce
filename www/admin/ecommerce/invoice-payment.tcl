# packages/dotlr-ecommerce/www/admin/ecommerce/invoice-payment.tcl

ad_page_contract {
    
    Invoice payment
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-04
    @arch-tag: fe435374-28f2-43a5-ba91-dce6b868304f
    @cvs-id $Id$
} {
    order_id:integer,notnull

    {creditcard_expire_1 ""}
    {creditcard_expire_2 ""}
} -properties {
} -validate {
} -errors {
}

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]
set user_id [db_string order_owner {
    select user_id
    from ec_orders
    where order_id = :order_id
}]

set form [rp_getform]
ns_set delkey $form creditcard_expires

set validate {}

set billing_address_id [db_list get_billing_address_id "
        select address_id
        from ec_addresses
        where user_id=:user_id
        and address_type = 'billing'
        order by address_id limit 1"]

if { [info exists billing_address_id] } {
    set billing_address_exists [db_0or1row select_address "
    	select attn, line1, line2, city, usps_abbrev, zip_code, phone, country_code, full_state_name, phone_time 
    	from ec_addresses 
    	where address_id=:billing_address_id"]
}	

set ec_expires_widget "[ec_creditcard_expire_1_widget $creditcard_expire_1] [ec_creditcard_expire_2_widget $creditcard_expire_2]"

if { [empty_string_p [set payment_methods [parameter::get -parameter PaymentMethods]]] } {
    lappend payment_methods cc
}

set method_count 0
set new_payment_methods {}
foreach payment_method [split $payment_methods] {
    set _payment_method [split $payment_method :]
    if { [llength $_payment_method] == 2 } {
	lappend new_payment_methods [set payment_method [lindex $_payment_method 0]]

	switch [lindex $_payment_method 1] {
	    admin {
		if { $admin_p } {
		    set ${payment_method}_p 1
		} else {
		    continue
		}
	    }
	}
    } else {
	set ${payment_method}_p 1
	lappend new_payment_methods $payment_method
    }
    
    switch $payment_method {
	internal_account {
	    lappend method_options [list "[_ dotlrn-ecommerce.lt_Internal_account_numb]" internal_account]
	    lappend validate {internal_account
		{ [exists_and_not_null internal_account] || [template::element::get_value checkout method] != "internal_account" }
		"[_ dotlrn-ecommerce.lt_Please_enter_an_inter]"
	    }
	}
	check {
	    lappend method_options [list "[_ dotlrn-ecommerce.Check]" check]
	}
	cc {
	    lappend method_options [list "[_ dotlrn-ecommerce.Credit_Card]" cc]
	    lappend validate {creditcard_number
		{ [template::element::get_value checkout method] != "cc" || [exists_and_not_null creditcard_number] }
		"[_ dotlrn-ecommerce.lt_Please_enter_a_credit]"
	    }
	    lappend validate {creditcard_type
		{ [template::element::get_value checkout method] != "cc" || [exists_and_not_null creditcard_type] }
		"[_ dotlrn-ecommerce.lt_Please_select_a_credi]"
	    }
	    lappend validate {creditcard_expires
		{ [template::element::get_value checkout method] != "cc" || ([exists_and_not_null creditcard_expire_1] && [exists_and_not_null creditcard_expire_2]) }
		"[_ dotlrn-ecommerce.lt_A_full_credit_card_ex]"
	    }
	}
	cash {
	    lappend method_options [list "[_ dotlrn-ecommerce.Cash]" cash]
	}
	lockbox {
	    lappend method_options [list "[_ dotlrn-ecommerce.Lock_Box]" lockbox]
	}
    }
    incr method_count
}
set payment_methods $new_payment_methods

# Build the form 
ad_form -name checkout -export { order_id } -form {
    {-section "[_ dotlrn-ecommerce.Amount_to_be_Paid]"}
    {amount:float {label "[_ dotlrn-ecommerce.Amount_to_be_Paid]"} {html {size 10}}}
}

if { $method_count > 1 } {
    ad_form -extend -name checkout -form {
	{-section "[_ dotlrn-ecommerce.Payment_Information]"}
	{method:text(radio) {label "[_ dotlrn-ecommerce.lt_Select_a_payment_meth]"} {options {$method_options}}}
    }

    if { [exists_and_equal internal_account_p 1] } {
	ad_form -extend -name checkout -form {
	    {internal_account:text,optional {label "[_ dotlrn-ecommerce.Internal_Account]"}}
	}
    }
} elseif { $method_count == 1 } {
    ad_form -extend -name checkout -export { {method "[lindex [split $payment_methods] 0]"} } -form {}
} else {
    ad_form -extend -name checkout -export { {method cc} } -form {}
}

if { [info exists cc_p] } {
    set country_options [linsert [db_list_of_lists countries {
	select default_name, iso from countries order by default_name
    }] 0 {"Select a country" ""}]

    set state_options [linsert [db_list_of_lists states {
	select state_name, abbrev from us_states order by state_name
    }] 0 {"Select a state" ""}]
    
    ad_form -extend -name checkout -form {
	{-section "Billing Information"}
	{bill_to_first_names:text {label "First name(s)"} {html {size 40}}}
	{bill_to_last_name:text {label "Last Name"} {html {size 40}}}
	{bill_to_phone:text {label "Telephone"} {html {size 40}}}
	{bill_to_phone_time:text(radio) {label "Best time to call"} {options {{day d} {evening e}}}}
	{bill_to_line1:text {label Address} {html {size 40}}}
	{bill_to_line2:text,optional {label "Address line 2"} {html {size 40}}}
	{bill_to_city:text {label City} {html {size 40}}}
	{bill_to_usps_abbrev:text(select) {label "State/Province"} {options {$state_options}}}
	{bill_to_zip_code:text {label "ZIP/Postal code"}}
	{bill_to_country_code:text(select) {label "Country"} {options {$country_options}}}
	{bill_to_full_state_name:text(hidden),optional}
    }	    

    if { $method_count == 1 } {
	# The creditcard_expires field is a hack, improve it
	# retrieve a saved address
	ad_form -extend -name checkout -form {
	    {-section "[_ dotlrn-ecommerce.lt_Credit_card_informati]"}
	    {creditcard_number:text {label "[_ dotlrn-ecommerce.Credit_card_number]"}}
	    {creditcard_type:text(select) {label Type} {options {{"[_ dotlrn-ecommerce.Please_select_one]" ""} {VISA v} {MasterCard m} {"American Express" a}}}}
	    {creditcard_expires:text(inform) {label "[_ dotlrn-ecommerce.Expires] <span class=\"form-required-mark\">*</span>"} {value $ec_expires_widget}}
	}
    } else {
	ad_form -extend -name checkout -form {
	    {-section "[_ dotlrn-ecommerce.lt_Credit_card_informati]"}
	    {creditcard_number:text,optional {label "[_ dotlrn-ecommerce.Credit_card_number]"}}
	    {creditcard_type:text(select),optional {label Type} {options {{"[_ dotlrn-ecommerce.Please_select_one]" ""} {VISA v} {MasterCard m} {"American Express" a}}}}
	    {creditcard_expires:text(inform),optional {label "[_ dotlrn-ecommerce.Expires]"} {value $ec_expires_widget}}
	}
    }
}

set price [ec_price_shipping_gift_certificate_and_tax_in_an_order $order_id]
set total_price [expr [lindex $price 0]-[lindex $price 1]-[lindex $price 2]-[lindex $price 3]]

set invoice_payments_sum [db_string invoice_payments_sum {
    select coalesce(sum(amount), 0)
    from dotlrn_ecommerce_transaction_invoice_payments
    where order_id = :order_id
} -default 0]

lappend validate {amount
    { $amount > 0 && $amount <= ($total_price - $invoice_payments_sum) }
    "[_ dotlrn-ecommerce.lt_You_may_only_enter_up] [ec_pretty_price [expr $total_price - $invoice_payments_sum]]"
}

ad_form -extend -name checkout -validate $validate  -form {} -on_request {
    set amount [expr $total_price - $invoice_payments_sum]
    set method cc

    if {$billing_address_exists == 1} {
	set bill_to_attn $attn
	# split attn for separate first_names, last_name processing, delimiter is triple space
	# separate first_names, last_name is required for some payment gateway validation systems (such as EZIC)
	set name_delim [string first "   " $attn]
	if {$name_delim < 0 } {
	    set name_delim 0
	}
	set bill_to_first_names [string trim [string range $attn 0 $name_delim]]
	set bill_to_last_name [string range $attn [expr $name_delim + 3 ] end]

	set bill_to_line1 $line1
	set bill_to_line2 $line2
	set bill_to_city $city
	set bill_to_usps_abbrev $usps_abbrev
	set bill_to_zip_code $zip_code
	set bill_to_phone $phone
	set bill_to_country_code $country_code
	set bill_to_full_state_name $full_state_name
	set bill_to_phone_time $phone_time
	set bill_to_state_widget $usps_abbrev
    } else {
	set billing_address_id 0 
	# no previous billing address, set defaults
	set bill_to_first_names [value_if_exists first_names]
	set bill_to_last_name [value_if_exists last_name]

	set bill_to_line1 ""
	set bill_to_line2 ""
	set bill_to_city ""
	set bill_to_usps_abbrev ""
	set bill_to_zip_code ""
	set bill_to_phone ""
	set bill_to_country_code US
	set bill_to_full_state_name ""
	set bill_to_phone_time "d"
	set bill_to_state_widget ""
    }

} -on_submit {
#    db_transaction {
	if { $method != "internal_account" } {
	    set internal_account ""
	}

	# Record payment
	db_dml insert_invoice_payment {
	    insert into dotlrn_ecommerce_transaction_invoice_payments
	    (order_id, method, internal_account, amount)
	    values
	    (:order_id, :method, :internal_account, :amount)
	}

	if { $method == "cc" } {
	    # If paid via credit card, initiate a cc transaction
	    set creditcard_id [db_nextval ec_creditcard_id_sequence]
	    set cc_no [string range $creditcard_number [expr [string length $creditcard_number] -4] [expr [string length $creditcard_number] -1]]
	    set expiry "$creditcard_expire_1/$creditcard_expire_2"
	    db_dml insert_new_cc "
	    	insert into ec_creditcards
	    	(creditcard_id, user_id, creditcard_number, creditcard_last_four, creditcard_type, creditcard_expire, billing_address)
	    	values
	    	(:creditcard_id, :user_id, :creditcard_number, :cc_no , :creditcard_type, :expiry, :billing_address_id)"
	    db_dml update_order_set_cc "
	    	update ec_orders 
            	set creditcard_id=:creditcard_id 
            	where order_id=:order_id"

	    set transaction_id [db_nextval ec_transaction_id_sequence]

	    if { ![empty_string_p $creditcard_id] } {
		db_dml insert_financial_transaction "
		insert into ec_financial_transactions
		(creditcard_id, transaction_id, order_id, transaction_amount, transaction_type, inserted_date)
		values
		(:creditcard_id, :transaction_id, :order_id, :amount, 'charge', current_timestamp)"

		ec_update_state_to_confirmed $order_id 
		array set response [ec_creditcard_authorization $order_id $transaction_id]
		set result $response(response_code)
		set transaction_id $response(transaction_id)
		if { [string equal $result "authorized"] } {
		    ec_email_new_order $order_id

		    # Change the order state from 'confirmed' to
		    # 'authorized'.

		    ec_update_state_to_authorized $order_id 

		    # Record the date & time of the authorization.

		    db_dml update_authorized_date "
		    update ec_financial_transactions 
		    set authorized_date = current_timestamp,
                    to_be_captured_p = 't',
                    to_be_captured_date = current_timestamp
 	            where transaction_id = :transaction_id"
		}

		if { [string equal $result "authorized"] || [string equal $result "no_recommendation"] } {
		    ad_returnredirect [export_vars -base one { order_id }]
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
		    ns_log Notice "invoice-payment.tcl, ref(671): creditcard check failed for order_id $order_id. Redirecting to credit-card-correction"

		}
	    }
	}
#    }
	ad_returnredirect [export_vars -base financial-transactions { order_id }]
    ad_script_abort
}

# doc_body_append "
# [ad_admin_header "Invoice Payment"]

# <h2>Invoice Payment</h2>

# [ad_context_bar [list "../" "Ecommerce([ec_system_name])"] [list "index" "Orders"] "One Order"]

# <hr>

# <h3>Invoice Payment</h3>

# [eval [template::adp_compile -string [subst {
#     <formtemplate id=\"checkout\"></formtemplate>
# }]]]
# [ad_admin_footer]"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Invoice Payment"]