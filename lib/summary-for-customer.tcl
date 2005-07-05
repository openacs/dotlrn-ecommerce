# packages/dotlrn-ecommerce/lib/summary-for-customer.tcl
#
# Order summary
#
# @author  (mgh@localhost.localdomain)
# @creation-date 2005-07-06
# @arch-tag: d3b67a51-7e53-447e-94ca-29a22f8cb3b9
# @cvs-id $Id$

foreach required_param {order_id user_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}

set show_item_detail_p f

set correct_user_id [db_string correct_user_id "
	select user_id as correct_user_id 
	from ec_orders 
	where order_id = :order_id"]
if { [string compare $user_id $correct_user_id] != 0 } {
    return "Invalid Order ID"
}

db_1row order_info_select "
      select o.confirmed_date, o.creditcard_id, o.shipping_method,
      u.email, o.shipping_address as shipping_address_id, c.billing_address as billing_address_id
      from ec_orders o
      left join cc_users u on (o.user_id = u.user_id)
      left join ec_creditcards c on (o.creditcard_id = c.creditcard_id)
      where o.order_id = :order_id"

set shipping_address [ec_pretty_mailing_address_from_ec_addresses $shipping_address_id]

if { ![empty_string_p $creditcard_id] } {
    set creditcard_summary [ad_text_to_html [ec_creditcard_summary $creditcard_id]]
} else {
    set creditcard_summary ""
}

if { [empty_string_p $billing_address_id] } {
    db_1row billing_address {
	select address_id as billing_address_id
	from ec_addresses
	where user_id = :user_id
	limit 1
    }
}

set billing_address [ad_text_to_html [ec_pretty_mailing_address_from_ec_addresses $billing_address_id]]

template::multirow create items quantity product_name options price_name price_charged

db_foreach order_details_select "
	select i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice,
	    p.product_name, p.one_line_description, p.product_id, count(*) as quantity 
	from ec_items i, ec_products p
	where i.order_id = :order_id
	and i.product_id = p.product_id
	group by p.product_name, p.one_line_description, p.product_id, i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice" {

	    set option_list [list]
	    if { ![empty_string_p $color_choice] } {
		lappend option_list "Color: $color_choice"
	    }
	    if { ![empty_string_p $size_choice] } {
		lappend option_list "Size: $size_choice"
	    }
	    if { ![empty_string_p $style_choice] } {
		lappend option_list "Style: $style_choice"
	    }
	    set options [join $option_list ", "]
	    if { ![empty_string_p $options] } {
		set options "$options; "
	    }

	    template::multirow append items $quantity $product_name $options $price_name [ec_pretty_price $price_charged [ad_parameter -package_id [ec_id] Currency ecommerce]]
	}

if { ![empty_string_p $confirmed_date] } {
    set confirmed_date [util_AnsiDatetoPrettyDate $confirmed_date]
}

set currency [ad_parameter -package_id [ec_id] Currency ecommerce]

set price_shipping_gift_certificate_and_tax [ec_price_shipping_gift_certificate_and_tax_in_an_order $order_id]

set price [lindex $price_shipping_gift_certificate_and_tax 0]
set shipping [lindex $price_shipping_gift_certificate_and_tax 1]
set gift_certificate [lindex $price_shipping_gift_certificate_and_tax 2]
set tax [lindex $price_shipping_gift_certificate_and_tax 3]

set subtotal [expr $price + $shipping]
set total [expr $price + $shipping + $tax]
set balance [expr $price + $shipping + $tax - $gift_certificate]

foreach i {price shipping gift_certificate tax subtotal total balance} {
    set $i [ec_pretty_price [set $i] $currency]
}
