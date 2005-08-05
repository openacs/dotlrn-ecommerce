# packages/dotlrn-ecommerce/www/admin/ecommerce/index.tcl

ad_page_contract {
    
    Pretty list of orders
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-04
    @arch-tag: 275de49f-3457-4b4a-bef3-b86b79964217
    @cvs-id $Id$
} {
    section_id:integer,optional
    user_id:integer,optional
    start:optional
    type:optional
    payment_method:optional
} -properties {
} -validate {
} -errors {
}

if { [empty_string_p [set available_payment_methods [parameter::get -parameter PaymentMethods]]] } {
    lappend available_payment_methods cc
}

set method_filters [list]

foreach available_payment_method [split $available_payment_methods] {
    set _payment_method [split $available_payment_method :]
    if { [llength $_payment_method] == 2 } {
	set _payment_method [lindex $_payment_method 0]
    }

    lappend method_filters [list [ad_decode $_payment_method \
				      cc "[_ dotlrn-ecommerce.Credit_Card]" \
				      check "[_ dotlrn-ecommerce.Check]" \
				      internal_account "[_ dotlrn-ecommerce.Internal_Account]" \
				      cash "[_ dotlrn-ecommerce.Cash]" \
				      invoice "[_ dotlrn-ecommerce.Invoice]" \
				      scholarship "[_ dotlrn-ecommerce.Scholarship]" \
				      "[_ dotlrn-ecommerce.Credit_Card]"
				 ] \
				$_payment_method]
}

template::list::create \
    -name "orders" \
    -multirow "orders" \
    -page_flush_p 1 \
    -no_data "[_ dotlrn-ecommerce.lt_No_orders_for_this_se]" \
    -elements {
	order_id {
	    label "[_ dotlrn-ecommerce.Order_ID]"
	    link_url_col order_url
	    html { align center }
	}
	section_name {
	    label "[_ dotlrn-ecommerce.Section_Name]"
	    link_url_col section_url
	}
	person__name {
	    label "[_ dotlrn-ecommerce.Purchaser]"
	    link_url_col person_url
	}
	method {
	    label "[_ dotlrn-ecommerce.Payment_Method]"
	}
	total_price {
	    label "[_ dotlrn-ecommerce.Total_Amount]"
	    html { align right }
	    display_template {
		@orders.pretty_actual_total@
	    }
	    aggregate sum
	    aggregate_label "[_ dotlrn-ecommerce.Total_1]:"
	}
	refund_price {
	    label "[_ dotlrn-ecommerce.Total_Refunds]"
	    html { align right }
	    display_template {
		@orders.pretty_refund@
	    }
	    aggregate sum
	    aggregate_label "[_ dotlrn-ecommerce.Total_1]:"
	}
	price_to_display {
	    label "[_ dotlrn-ecommerce.lt_Total_Amount_Received]"
	    html { align right }
	    display_template {
		@orders.pretty_total@
	    }
	    aggregate sum
	    aggregate_label "[_ dotlrn-ecommerce.Total_1]:"
	}
	balance {
	    label "[_ dotlrn-ecommerce.Balance]"
	    html { align right }
	    display_template {
		<if @orders.balance@ eq 0>
		Fully Paid
		</if>
		<else>
		@orders.pretty_balance@
		</else>
	    }
	    aggregate sum
	    aggregate_label "[_ dotlrn-ecommerce.Total_1]:"
	}
    } -filters {
	section_id {
	    where_clause { s.section_id = :section_id }
	}
	user_id {
	    where_clause { o.user_id = :user_id }
	}
	start {
	    label "[_ dotlrn-ecommerce.In_the_last]"
	    values {
		{"24 hours" "24 hours"}
		{"7 days" "7 days"}
		{"Month" "1 month"}
	    }
	    where_clause { o.authorized_date >= current_timestamp - :start::interval }
	}
	type {
	    label "[_ dotlrn-ecommerce.Orders_with]"
	    values {
		{"[_ dotlrn-ecommerce.Outstanding_blance]" balance}
	    }
	    where_clause {
		(case when t.method = 'invoice' then
		 ec_total_price(o.order_id) - ec_order_gift_cert_amount(o.order_id) - 
		 (select coalesce(sum(amount), 0)
		  from dotlrn_ecommerce_transaction_invoice_payments
		  where order_id = o.order_id)
		 else 0 end) > 0
	    }
	}
	payment_method {
	    label "[_ dotlrn-ecommerce.Payment_method]"
	    values { $method_filters }
	    where_clause { t.method = :payment_method }
	}
    }

db_multirow -extend { order_url section_url pretty_total pretty_balance person_url pretty_refund pretty_actual_total } orders orders [subst {
    select o.order_id, o.confirmed_date, o.order_state, 

    ec_total_price(o.order_id) - (case when t.method = 'invoice' 
				  then ec_total_price(o.order_id) - 
				  (select coalesce(sum(amount), 0)
				   from dotlrn_ecommerce_transaction_invoice_payments
				   where order_id = o.order_id) + ec_total_refund(o.order_id)
				  else 0 end) as price_to_display,

    o.user_id as purchasing_user_id, u.first_names, u.last_name, count(*) as n_items, person__name(o.user_id), t.method, s.section_id as _section_id, s.section_name, s.course_id, 

    case when t.method = 'invoice' then
    ec_total_price(o.order_id) - ec_order_gift_cert_amount(o.order_id) - 
    (select coalesce(sum(amount), 0)
     from dotlrn_ecommerce_transaction_invoice_payments
     where order_id = o.order_id) + ec_total_refund(o.order_id)
    else 0 end as balance, ec_total_refund(o.order_id) as refund_price, ec_total_price(o.order_id) + ec_total_refund(o.order_id) as total_price, 
    (select to_char(refund_date, 'Mon dd, yyyy')
     from ec_refunds
     where order_id = o.order_id
     order by refund_date desc
     limit 1) as refund_date

    from ec_orders o
    join ec_items i using (order_id)
    join dotlrn_ecommerce_transactions t using (order_id)
    join dotlrn_ecommerce_section s on (i.product_id = s.product_id)
    left join cc_users u on (o.user_id=u.user_id)
    
    where true
    
    [template::list::filter_where_clauses -and -name orders]
    
    group by o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id), o.user_id, u.first_names, u.last_name, o.in_basket_date, t.method, s.section_name, s.section_id, s.course_id, o.authorized_date, balance, refund_price, refund_date

    order by o.in_basket_date desc
}] {
    set order_url [export_vars -base one { order_id }]
    set pretty_total [ec_pretty_price $price_to_display]
    set pretty_balance [ec_pretty_price $balance]
    set method [ad_decode $method \
		    cc "[_ dotlrn-ecommerce.Credit_Card]" \
		    check "[_ dotlrn-ecommerce.Check]" \
		    internal_account "[_ dotlrn-ecommerce.Internal_Account]" \
		    cash "[_ dotlrn-ecommerce.Cash]" \
		    invoice "[_ dotlrn-ecommerce.Invoice]" \
		    scholarship "[_ dotlrn-ecommerce.Scholarship]" \
		    "[_ dotlrn-ecommerce.Credit_Card]"
	       ]
    set order_state [string totitle $order_state]
    set section_url [export_vars -base ../one-section { {section_id $_section_id} }]
    set person_url [export_vars -base ../one-user { {user_id $purchasing_user_id} }]
    set pretty_refund [ec_pretty_price $refund_price]
    set pretty_actual_total [ec_pretty_price $total_price]
}

if { [info exists section_id] } {
    set context [list [list [export_vars -base ../one-section { section_id }] [db_string section_name { select section_name from dotlrn_ecommerce_section where section_id = :section_id }]] "[_ dotlrn-ecommerce.Order_Summary]"]
} else {
    set context [list "[_ dotlrn-ecommerce.Order_Summary]"]
}