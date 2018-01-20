ad_page_contract {

    @param refund_id
    @param order_id
    @param received_back_date
    @param reason_for_return
    @param item_id_list 
    @param price_to_refund(item_id) for each item_id,
    @param shipping_to_refund(item_id) for each item_id, 
    @param base_shipping_to_refund

    @author
    @creation-date
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} {
    refund_id:notnull,naturalnum
    order_id:notnull,naturalnum
    received_back_datetime
    reason_for_return
    item_id_list
    price_to_refund:array,optional
    price_to_refund_manually:array
    shipping_to_refund:array
    base_shipping_to_refund
}

# The customer service rep must be logged on

ad_require_permission [ad_conn package_id] admin
set customer_service_rep [ad_get_user_id]

# Error checking: Make sure price_to_refund($item_id) is <=
# price_charged for that item same with shipping. Make sure
# base_shipping_to_refund is <= base shipping charged - refunded
# Make sure they haven't already inserted this refund

if { [db_string get_count_refunds "
	select count(*) 
	from ec_refunds 
	where refund_id=:refund_id"] > 0 } {
    ad_return_complaint 1 "
	<li>This refund has already been inserted into the database.Are you using an old form?  <a href=\"one?[export_url_vars order_id]\">Return to the order.</a>"
    return
}

set exception_count 0
set exception_text ""

# Add up the items' price/shipping/tax to refund as we go

set total_price_to_refund 0
set total_price_to_refund_manually 0
set total_shipping_to_refund 0
set total_price_tax_to_refund 0
set total_shipping_tax_to_refund 0

db_foreach get_items_for_return "
    select i.item_id, p.product_name, nvl(i.price_charged,0) as price_charged, nvl(i.shipping_charged,0) as shipping_charged, 
        nvl(i.price_tax_charged,0) as price_tax_charged, nvl(i.shipping_tax_charged,0) as shipping_tax_charged
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.item_id in ([join $item_id_list ", "])" {
    
 	if { ! [array exists price_to_refund] } {
	    foreach _item [array names price_to_refund_manually] {
		set price_to_refund($_item) 0
	    }
	}

    if { [empty_string_p price_to_refund($item_id)] || [empty_string_p price_to_refund_manually($item_id)] } {
	incr exception_count
	append exception_text "<li>Please enter a price to refund for $product_name."
    } elseif {[regexp {[^0-9\.]} $price_to_refund($item_id)] || [regexp {[^0-9\.]} $price_to_refund_manually($item_id)]} {
	incr exception_count
	append exception_text "<li>Please enter a purely numeric price to refund for $product_name (no letters or special characters)."
    } elseif { ($price_to_refund($item_id) + $price_to_refund_manually($item_id)) > $price_charged } {
	incr exception_count
	append exception_text "<li>Please enter a price to refund for $product_name that is less than or equal to [ec_pretty_price $price_charged]."
    } else {
	set total_price_to_refund [expr $total_price_to_refund + $price_to_refund($item_id)]
	set total_price_to_refund_manually [expr $total_price_to_refund_manually + $price_to_refund_manually($item_id)]

	# Tax will be the minimum of the tax actually charged and the
	# tax that would have been charged on the price to refund (tax
	# rates may have changed in the meantime and we don't want to
	# refund more than they paid)

	set tax_price_to_refund $price_to_refund($item_id)
	set iteration_price_tax_to_refund [ec_min $price_tax_charged [db_string get_ec_tax "
	    select coalesce(ec_tax(:tax_price_to_refund,0,:order_id),0) 
	    from dual"]]
	set total_price_tax_to_refund [expr $total_price_tax_to_refund + $iteration_price_tax_to_refund]
    }

    if { [empty_string_p $shipping_to_refund($item_id)] } {
	incr exception_count
	append exception_text "<li>Please enter a shipping amount to refund for $product_name."
    } elseif {[regexp {[^0-9\.]} $shipping_to_refund($item_id)]} {
	incr exception_count
	append exception_text "<li>Please enter a purely numeric shipping amount to refund for $product_name (no letters or special characters)."
    } elseif { $shipping_to_refund($item_id) > $shipping_charged } {
	incr exception_count
	append exception_text "<li>Please enter a shipping amount to refund for $product_name that is less than or equal to [ec_pretty_price $shipping_charged]."
    } else {
	set total_shipping_to_refund [expr $total_shipping_to_refund + $shipping_to_refund($item_id)]

	set iteration_shipping_tax_to_refund [ec_min $shipping_tax_charged [db_string get_it_shipping_tax_refund "
	    select coalesce(ec_tax(0,$shipping_to_refund($item_id), $order_id),0) 
	    from dual"]]
	set total_shipping_tax_to_refund [expr $total_shipping_tax_to_refund + $iteration_shipping_tax_to_refund]
    }
}

db_1row get_shipping_charged_values "
    select nvl(shipping_charged,0) - nvl(shipping_refunded,0) as base_shipping, 
	nvl(shipping_tax_charged,0) - nvl(shipping_tax_refunded,0) as base_shipping_tax 
    from ec_orders 
    where order_id=:order_id"

if { [empty_string_p $base_shipping_to_refund] } {
    incr exception_count
    append exception_text "<li>Please enter a base shipping amount to refund."
} elseif {[regexp {[^0-9\.]} $base_shipping_to_refund]} {
    incr exception_count
    append exception_text "<li>Please enter a purely numeric base shipping amount to refund (no letters or special characters)."
} elseif { $base_shipping_to_refund > $base_shipping } {
    incr exception_count
    append exception_text "<li>Please enter a base shipping amount to refund that is less than or equal to [ec_pretty_price $base_shipping]."
} else {
    set total_shipping_to_refund [expr $total_shipping_to_refund + $base_shipping_to_refund]
    set iteration_shipping_tax_to_refund [ec_min $base_shipping_tax [db_string get_base_shipping_it_refund "
	select coalesce(ec_tax(0,:base_shipping,:order_id),0) 
	from dual"]]
    set total_shipping_tax_to_refund [expr $total_shipping_tax_to_refund + $iteration_shipping_tax_to_refund]
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set total_tax_to_refund [expr $total_price_tax_to_refund + $total_shipping_tax_to_refund]
set total_amount_to_refund [expr $total_price_to_refund + $total_shipping_to_refund + $total_tax_to_refund]
set total_amount_to_refund_manually [expr $total_price_to_refund_manually + $total_shipping_to_refund + $total_tax_to_refund]

# Determine how much of this will be refunded in cash

set cash_amount_to_refund [db_string get_cash_refunded "
    select nvl(ec_cash_amount_to_refund(:total_amount_to_refund,:order_id),0) 
    from dual"]

# Calculate how much to refund to the credit card and how much to
# refund manually
if { $total_amount_to_refund >= $cash_amount_to_refund } {
    # Requested amount to refund to credit card is greater than what
    # is available for refund (the rest probably paid via gift
    # certs/scholarship), give priority to credit card refunds than
    # manual refunds
    set cash_amount_to_refund_cc $cash_amount_to_refund
    set cash_amount_to_refund_manually 0
} else {
    # Give priority to credit card refunds, the rest refund manually
    set cash_amount_to_refund_cc $total_amount_to_refund
    set cash_amount_to_refund_manually [expr $cash_amount_to_refund - $total_amount_to_refund]
}

# Calculate gift certificate amount and tax to refund

set certificate_amount_to_reinstate [expr ($total_amount_to_refund + $total_amount_to_refund_manually) - $cash_amount_to_refund]
if { $certificate_amount_to_reinstate < 0.01 } {

    # Because of rounding

    set certificate_amount_to_reinstate 0
}

# See if the credit card data is still in the database. If not the
# credit card number has to be re-entered.

if {![db_0or1row get_billing_info "
    select c.creditcard_id, c.creditcard_type, c.creditcard_last_four,
	substring(creditcard_expire for 2) as card_exp_month, substring(creditcard_expire from 4 for 2) as card_exp_year, 
	p.first_names || ' ' || p.last_name as card_name,
	a.line1 as billing_street, a.city as billing_city, a.usps_abbrev as billing_state, a.zip_code as billing_zip, a.country_code as billing_country
    from ec_orders o, ec_creditcards c, persons p, ec_addresses a 
    where o.creditcard_id = c.creditcard_id
    and c.billing_address = a.address_id 
    and c.user_id = p.person_id
    and o.order_id=:order_id"]} {
    
    set creditcard_number ""
    set creditcard_id ""
    set creditcard_type ""
    set creditcard_last_four ""
    set card_expiration ""
    set card_name ""
    set billing_street ""
    set billing_state ""
    set billing_zip ""
    set billing_country ""
    set billing_city ""
}

set method [db_string method {
    select method
    from dotlrn_ecommerce_transactions
    where order_id = :order_id
} -default cc]

if { $method == "invoice" } {
    if { [db_0or1row cc_transaction_in_invoice {
	select 1
	where exists (select *
		      from dotlrn_ecommerce_transaction_invoice_payments
		      where order_id = :order_id
		      and method = 'cc')
    }] } {
	set method cc
    }
}

append doc_body "
    <form method=post action=items-return-4>
     [export_entire_form]
     [export_form_vars cash_amount_to_refund certificate_amount_to_reinstate cash_amount_to_refund_cc cash_amount_to_refund_manually]
     <blockquote>
       <p>Total refund amount: [ec_pretty_price [expr $total_amount_to_refund + $total_amount_to_refund_manually]] (price: [ec_pretty_price [expr $total_price_to_refund + $total_price_to_refund_manually]], shipping: [ec_pretty_price $total_shipping_to_refund], tax: [ec_pretty_price $total_tax_to_refund])</p>
       <ul>"

if { $certificate_amount_to_reinstate > 0 } {
    if { $method == "scholarship" } {
	append doc_body "<li>[ec_pretty_price $certificate_amount_to_reinstate] will be reinstated in the scholarship fund.<br>"
    } else {
	append doc_body "<li>[ec_pretty_price $certificate_amount_to_reinstate] will be reinstated in gift certificates.<br>"
    }
}

if { $method == "cc" } {
    append doc_body "        
        <li>[ec_pretty_price $cash_amount_to_refund_cc] will be refunded to the customer's credit card.<br>"
}

append doc_body "        
        <li>[ec_pretty_price $cash_amount_to_refund_manually] will be refunded to the customer manually.<br>"

append doc_body "
      </ul>"

# Request the credit card number to be re-entered if it is no longer
# on file, yet there is money to refund.

# Only ask for credit card info if credit card was used in purchase

if { [empty_string_p $creditcard_number] && $cash_amount_to_refund > 0 && $method == "cc" } {
    append doc_body "
    <p>Please re-enter the credit card number of the card used for this order:</p>
    <table border=0 cellspacing=0 cellpadding=10>
    <tr>
      <td>
       <table>
       <tr>
         <td><input type=\"hidden\" name=\"creditcard_id\" value=\"$creditcard_id\">
	     [ec_creditcard_widget $creditcard_type disabled]</td>
         <td><input type=\"text\" name=\"creditcard_number\" size=\"21\" maxlength=\"17\"></td>
       </tr>
	<tr>
	  <td>Ending in:</td>
	  <td>xxxxxxxxxxxx$creditcard_last_four</td>
       <tr>
         <td>Expires:</td>
         <td>$card_expiration</td>
       <tr>
         <td valign=\"top\">Billing address:</td>
         <td>$billing_street<br>
	     $billing_city, $billing_state $billing_zip<br>
	     $billing_country</td>
       </tr>
       </table>
      </td>
    </tr>
    </table>"
} else {
    append doc_body "
      	[export_form_vars creditcard_id creditcard_number]"
}
append doc_body "
      	[export_form_vars creditcard_type]"

append doc_body "
    <br>
  </blockquote>
  [export_form_vars creditcard_last_four]
  <center>
    <input type=submit value=\"Complete the Refund\">
  </center>
</form>"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Refund"]
