# packages/dotlrn-ecommerce/www/admin/ecommerce/index.tcl

ad_page_contract {
    
    Pretty list of orders
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-04
    @arch-tag: 275de49f-3457-4b4a-bef3-b86b79964217
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

template::list::create \
    -name "orders" \
    -multirow "orders" \
    -elements {
	order_id {
	    label "Order ID"
	    link_url_col order_url
	    html { align center }
	}
	order_state {
	    label "Order State"
	}
	price_to_display {
	    label "Total Amount"
	    html { align right }
	}
	person__name {
	    label "Purchaser"
	}
	method {
	    label "Payment Method"
	}
	balance {
	    label "Balance"
	    html { align right }
	}
    }

db_multirow -extend { balance order_url } orders orders {
    select o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id) as price_to_display, o.user_id, u.first_names, u.last_name, count(*) as n_items, person__name(o.user_id), t.method
    from ec_orders o
    join ec_items i using (order_id)
    left join cc_users u on (o.user_id=u.user_id)
    join dotlrn_ecommerce_transactions t using (order_id)
    group by o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id), o.user_id, u.first_names, u.last_name, o.in_basket_date, t.method
    order by o.in_basket_date desc
} {
    if { $method == "invoice" } {
	set balance [ec_pretty_price [expr $price_to_display - [db_string invoice_payments_sum {
	    select coalesce(sum(amount), 0)
	    from dotlrn_ecommerce_transaction_invoice_payments
	    where order_id = :order_id
	} -default 0]]]
    } else {
	set balance "Paid in full"
    }

    set order_url [export_vars -base one { order_id }]
    set price_to_display [ec_pretty_price $price_to_display]
    set method [string totitle $method]
    set order_state [string totitle $order_state]
}