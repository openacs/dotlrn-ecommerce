ad_page_contract {

    @cvs-id $Id$
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} {

    refund_id:notnull,optional
    order_id:notnull,naturalnum
    {reason_for_return ""}
    all_items_p:optional
    item_id:optional,multiple
    received_back_date:date,array,optional
    received_back_time:time,array,optional
}

ad_require_permission [ad_conn package_id] admin

if { ! [info exists refund_id] } {
    set refund_id [db_nextval refund_id_sequence]
}

if { [array exists received_back_date] && [array exists received_back_time] } {
    set received_back_datetime $received_back_date(date)
    if { [exists_and_not_null received_back_time(time)] } {
	append received_back_datetime " [ec_timeentrywidget_time_check \"$received_back_time(time)\"]$received_back_time(ampm)"
    } else {
	append received_back_datetime " 12:00:00AM"
    }
} else {
    set received_back_datetime [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
}

# The customer service rep must be logged on

set customer_service_rep [ad_get_user_id]
if {$customer_service_rep == 0} {
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register?[export_url_vars return_url]"
    ad_script_abort
}

# Make sure they haven't already inserted this refund

if { [db_string get_refund_count "
    select count(*) 
    from ec_refunds 
    where refund_id=:refund_id"] > 0 } {
    ad_return_complaint 1 "
	<li>This refund has already been inserted into the database. Are you using an old form? <a href=\"one?[export_url_vars order_id]\">Return to the order.</a>"
    ad_script_abort
}

set exception_count 0
set exception_text ""

# They must have either checked "All items" and none of the rest, or
# at least one of the rest and not "All items". They also need to have
# shipment_date filled in

if { [info exists all_items_p] && [info exists item_id] } {
    incr exception_count
    append exception_text "<li>Please either check off \"All items\" or check off some of the items, but not both."
}
if { ![info exists all_items_p] && ![info exists item_id] } {
    incr exception_count
    append exception_text "<li>Please either check off \"All items\" or check off some of the items."
}

if { $exception_count > 0 } {
    ad_return_complaint 1 $exception_text
    ad_script_abort
}

set shipping_refund_percent [ad_parameter -package_id [ec_id] ShippingRefundPercent ecommerce]

if { ![info exists all_items_p] } {
    set item_id_list $item_id
    set sql [db_map all_items_select]
} else {
    set sql [db_map selected_items_select] 
}

# Generate a list of the items if they selected "All items" because,
# regardless of what happens elsewhere on the site (e.g. an item is
# added to the order, thereby causing the query for all items to
# return one more item), only the items that they confirm here should
# be recorded as part of this return.

if { [info exists all_items_p] } {
    set item_id_list [list]
}

# See if a credit card was used for this purchase
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

set items_to_print ""
db_foreach get_return_item_list $sql {
    
    if { [info exists all_items_p] } {
	lappend item_id_list $item_id
    }

    if { $method == "cc" } {
    append items_to_print "
	<tr>
	  <td>$product_name</td>
	   <td><input type=text name=\"price_to_refund.${item_id}\" value=\"[format "%0.2f" $price_charged]\" size=\"5\"> (<b>by credit card</b> out of [ec_pretty_price $price_charged]); <input type=text name=\"price_to_refund_manually.${item_id}\" value=\"0\" size=\"5\"> (<b>manually</b> out of [ec_pretty_price $price_charged])</td>
	</tr>
 	   <input type=hidden name=\"shipping_to_refund.${item_id}\" value=\"[format "%0.2f" [expr $shipping_charged * $shipping_refund_percent]]\" size=\"5\">"
    } else {
    append items_to_print "
	<tr>
	  <td>$product_name</td>
	   <td><input type=text name=\"price_to_refund_manually.${item_id}\" value=\"[format "%0.2f" $price_charged]\" size=\"5\"> (<b>manually</b> out of [ec_pretty_price $price_charged])</td>
	</tr>
 	   <input type=hidden name=\"shipping_to_refund.${item_id}\" value=\"[format "%0.2f" [expr $shipping_charged * $shipping_refund_percent]]\" size=\"5\">"
    }
}

append doc_body "
    <form method=post action=items-return-3>
      [export_form_vars refund_id order_id item_id_list received_back_datetime reason_for_return]
      <blockquote>
        <table border=0 cellspacing=0 cellpadding=10>
          <tr>
            <th>Item</th><th>Price to Refund</th>
         </tr>
         $items_to_print
       </table>"

# Although only one refund may be done on an item, multiple refunds
# may be done on the base shipping cost, so show shipping_charged -
# shipping_refunded.

set base_shipping [db_string base_shipping_select "
    select nvl(shipping_charged,0) - nvl(shipping_refunded,0) 
    from ec_orders 
    where order_id=:order_id"]

append doc_body "
      <input type=hidden name=base_shipping_to_refund value=\"[format "%0.2f" [expr $base_shipping * $shipping_refund_percent]]\" size=\"5\"> 
    </blockquote>

    <center><input type=submit value=\"Continue\"></center>"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "Refund"]
