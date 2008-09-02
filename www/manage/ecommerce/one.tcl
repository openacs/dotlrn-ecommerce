ad_page_contract {

    Display one order.

    @author Eve Andersson (eveander@arsdigita.com)
    @creation-date Summer 1999
    @author ported by Jerry Asher (jerry@theashergroup.com)
    @author revised by Bart Teeuwisse (bart.teeuwisse@thecodemill.biz)
    @revision-date April 2002

} {
    order_id:integer,notnull
}

ad_require_permission [ad_conn package_id] admin

db_1row order_select "
    select o.order_state, o.creditcard_id, o.confirmed_date, o.cs_comments,
        o.shipping_method, o.shipping_address, o.in_basket_date,
        o.authorized_date, o.shipping_charged, o.voided_by, o.voided_date,
        o.reason_for_void, u.user_id, u.first_names, u.last_name, c.billing_address
    from ec_orders o, cc_users u, ec_creditcards
    where order_id=:order_id
    and o.user_id = u.user_id(+)
    and o.creditcard_id = c.creditcard_id(+)"

set doc_body ""

append doc_body "
    [ec_decode $order_state "void" "<table>" "<table width=90%>"]
      <tr>
        <td align=right><b>Order ID</td>
        <td>$order_id</td>
        <td rowspan=4 align=right valign=top>[ec_decode $order_state "void" "" "<pre>[ec_formatted_price_shipping_gift_certificate_and_tax_in_an_order $order_id]</pre>"]</td>
      </tr>
      <tr>
        <td align=right><b>Ordered by</td>
        <td><a href=\"../one-user?user_id=$user_id\">$first_names $last_name</a></td>
      </tr>
      <tr>
        <td align=right><b>Confirmed date</td>
        <td>[ec_formatted_full_date $confirmed_date]</td>
      </tr>
      <tr>
        <td align=right><b>Order state</td>
        <td>[ec_decode $order_state "void" "<font color=red>void</font>" $order_state]</td>
      </tr>
    </table>"

if { $order_state == "void" } {
    append doc_body "
	<h3>Details of Void</h3>

	<blockquote>
	  Voided by: <a href=\"[ec_acs_admin_url]users/one?user_id=$voided_by\">[db_string voided_by_name_select "
	      select first_names || ' ' || last_name from cc_users where user_id = :voided_by" -default ""]</a><br>
	  Date: [ec_formatted_full_date $voided_date]<br>
	  [ec_decode $reason_for_void "" "" "Reason: [ec_display_as_html $reason_for_void]"]
	</blockquote>"
}

append doc_body "
    [ec_decode $cs_comments "" "" "<h3>Comments</h3>\n<blockquote>[ec_display_as_html $cs_comments]</blockquote>"]

    <ul>
      <li><a href=\"comments?[export_url_vars order_id]\">Add/Edit Comments</a></li>
    </ul>

    <h3>Items</h3>
    <ul>"

set items_ul ""

# We want to display these by item (with all order states in parentheses), like:
# Quantity 3: 2 Standard Pencils; Our Price: $0.99 (2 shipped, 1 to_be_shipped).
# This UI will break if the customer has more than one of the same product with
# different prices in the same order (the shipment summary is by product_id).

set old_product_color_size_style_price_price_name [list]
set item_quantity 0
set state_list [list]

db_foreach products_select "
    select p.product_name, p.product_id, i.price_name, i.price_charged, count(*) as quantity, i.item_state, i.color_choice, i.size_choice, i.style_choice
    from ec_items i, ec_products p
    where i.product_id=p.product_id
    and i.order_id=:order_id
    group by p.product_name, p.product_id, i.price_name, i.price_charged, i.item_state, i.color_choice, i.size_choice, i.style_choice" {

    set product_color_size_style_price_price_name [list $product_id $color_choice $size_choice $style_choice $price_charged $price_name]

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

    # It's OK to compare tcl lists with != because lists are really
    # strings in tcl
    
    if { $product_color_size_style_price_price_name != $old_product_color_size_style_price_price_name && [llength $old_product_color_size_style_price_price_name] != 0 } {
	append items_ul "
	    <li>
	      Quantity $item_quantity: $item_description ([join $item_state_list ", "])"
	if { [llength $item_state_list] != 1 || [lindex [split [lindex $item_state_list 0] " "] 1] != "void" } {

	    # i.e., if the items of this product_id are not all void
	    # (I know that "if" statement could be written more compactly,
	    # but I didn't want to offend Philip by relying on Tcl's internal
	    # representation of a list)

	    # EVE: have to make items-void.tcl take more than just product_id
	    

	}
	append items_ul "
	      <br>
	      [ec_shipment_summary_sub [lindex $old_product_color_size_style_price_price_name 0] [lindex $old_product_color_size_style_price_price_name 1] [lindex $old_product_color_size_style_price_price_name 2] [lindex $old_product_color_size_style_price_price_name 3] [lindex $old_product_color_size_style_price_price_name 4] [lindex $old_product_color_size_style_price_price_name 5] $order_id]
	    </li>"
	set item_state_list [list]
	set item_quantity 0
    }

    lappend item_state_list "$quantity $item_state"
    set item_quantity [expr $item_quantity + $quantity]
    set item_description "
	<a href=\"[ec_url_concat [ec_url] /admin]/products/one?product_id=$product_id\">$product_name</a>; 
	[ec_decode $options "" "" "$options; "]$price_name: [ec_pretty_price $price_charged]"
    set old_product_color_size_style_price_price_name [list $product_id $color_choice $size_choice $style_choice $price_charged $price_name]
}

if { [llength $old_product_color_size_style_price_price_name] != 0 } {

    # append the last line

    append items_ul "
	<li>
	  Quantity $item_quantity: $item_description ([join $item_state_list ", "])"
    if { [llength $item_state_list] != 1 || [lindex [split [lindex $item_state_list 0] " "] 1] != "void" } {

	# I.e., if the items of this product_id are not all void


    }
    append items_ul "
	  <br>
	  [ec_shipment_summary_sub [lindex $old_product_color_size_style_price_price_name 0] [lindex $old_product_color_size_style_price_price_name 1] [lindex $old_product_color_size_style_price_price_name 2] [lindex $old_product_color_size_style_price_price_name 3] [lindex $old_product_color_size_style_price_price_name 4] [lindex $old_product_color_size_style_price_price_name 5] $order_id]
	</li>"
}

append doc_body "$items_ul"

if { $order_state == "authorized" || $order_state == "partially_fulfilled" } {
    append doc_body "
	<li><a href=\"fulfill?[export_url_vars order_id]\">Record a Shipment</a></li>
	<li><a href=\"items-add?[export_url_vars order_id]\">Add Items</a></li>"
}
if { $order_state == "fulfilled" || $order_state == "partially_fulfilled" } {
    append doc_body "
	<li><a href=\"items-return?[export_url_vars order_id]\">Refund</a></li>"
}

append doc_body "
    </ul>
    <ul>
    <li><a href=\"financial-transactions?order_id=$order_id\">Financial Transactions</a>
    </ul>"

set refunds [template::adp_compile -string {<include src="/packages/dotlrn-ecommerce/lib/refunds" order_id="@order_id@" />}]
# Hack to not display ds stuff even if it's enabled, demo purposes
regsub -all {\[::ds_show_p\]} $refunds 0 refunds

append doc_body "[eval $refunds]"

set context [list [list index Orders] [list one?order_id=$order_id "One Order"] "One Order"]