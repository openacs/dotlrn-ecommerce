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
    orderby:optional
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
				      lockbox "[_ dotlrn-ecommerce.Lock_Box]" \
				      "[_ dotlrn-ecommerce.Credit_Card]"
				 ] \
				$_payment_method]
}

template::list::create \
    -name "orders" \
    -multirow "orders" \
    -page_flush_p 1 \
    -no_data "[_ dotlrn-ecommerce.No_orders]" \
    -elements {
	order_id {
	    label "[_ dotlrn-ecommerce.Order_ID]"
	    link_url_col order_url
	    html { align center }
	}
	confirmed_date {
	    label "[_ dotlrn-ecommerce.Date]"
	}
	_section_name {
	    label "[_ dotlrn-ecommerce.Item]"
	    link_url_col section_url
	}
	purchaser {
	    label "[_ dotlrn-ecommerce.Purchaser]"
	    link_url_col person_url
	}
	participant_name {
	    label "[_ dotlrn-ecommerce.Participant]"
	    display_template {
		<if @orders.participant_type@ eq "group">
		@orders.participant_name@
		</if>
		<else>
		<a href="@orders.participant_url;noquote@">@orders.participant_name@</a>
		</else>
	    }
	}
	method {
	    label "[_ dotlrn-ecommerce.Payment_Method]"
	    display_template {
		<if @orders.has_scholarship_p@ eq "t" and @orders.method@ ne "#dotlrn-ecommerce.Scholarship#">
		@orders.method@, #dotlrn-ecommerce.Scholarship#
		</if>
		<else>
		@orders.method@
		</else>
	    }
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
	    label "[_ dotlrn-ecommerce.Fully_Paid]"
	    html { align right }
	    display_template {
		<if @orders.balance@ gt 0>
		[_ dotlrn-ecommerce.No]
		</if>
		<else>
		[_ dotlrn-ecommerce.Yes]
		</else>
	    }
	}
	checked_out_by {
	    label "[_ dotlrn-ecommerce.Registered_By_Admin]"
	    display_template {
		<if @orders.checked_out_by@ eq @orders.purchaser_id@ or @orders.checked_out_by@ nil>
		[_ dotlrn-ecommerce.No]
		</if>
		<else>
		[_ dotlrn-ecommerce.Yes]
		</else>
	    }
	    html { align center }
	}
	refund {
	    display_template {
		<if @orders.refund_price@ lt 0.01>
		<a href="@orders.refund_url;noquote@" class="button">Refund</a>
		</if>
	    }
	}
	transactions {
	    display_template {
		<a href="financial-transactions?order_id=@orders.order_id@" class="button">Transactions</a>
	    }
	}
    } -filters {
	section_id {
	    where_clause { _section_id = :section_id }
	}
	user_id {
	    where_clause { purchasing_user_id = :user_id }
	}
	start {
	    label "[_ dotlrn-ecommerce.In_the_last]"
	    values {
		{"24 hours" "24 hours"}
		{"7 days" "7 days"}
		{"Month" "1 month"}
	    }
	    where_clause { authorized_date >= current_timestamp - :start::interval }
	}
	type {
	    label "[_ dotlrn-ecommerce.Orders_with]"
	    values {
		{"[_ dotlrn-ecommerce.Outstanding_blance]" balance}
	    }
	    where_clause {
		(case when method = 'invoice' then
		 ec_total_price(order_id) - ec_order_gift_cert_amount(order_id) - 
		 (select coalesce(sum(amount), 0)
		  from dotlrn_ecommerce_transaction_invoice_payments
		  where order_id = order_id)
		 else 0 end) > 0
	    }
	}
	payment_method {
	    label "[_ dotlrn-ecommerce.Payment_method]"
	    values { $method_filters }
	    where_clause { 
		(method = :payment_method or
		 (:payment_method = 'scholarship' and
		  coalesce((select true
			    where exists (select *
					  from ec_gift_certificate_usage
					  where order_id = order_id
					  and exists (select *
						      from scholarship_fund_grants
						      where ec_gift_certificate_usage.gift_certificate_id = gift_certificate_id))), false)))
	    }
	}
    } -orderby {
	order_id {
	    label "[_ dotlrn-ecommerce.Order_ID]"
	    orderby order_id
	}
	confirmed_date {
	    label "[_ dotlrn-ecommerce.Date]"
	    orderby confirmed_date_date_column
	}
	_section_name {
	    label "[_ dotlrn-ecommerce.Section_Name]"
	    orderby _section_name
	}
	purchaser {
	    label "[_ dotlrn-ecommerce.Purchaser]"
	    orderby "lower(first_names||' '||last_name)"
	}
	participant_name {
	    label "[_ dotlrn-ecommerce.Participant]"
	    orderby "lower(case when object_type = 'group' then acs_group__name(participant_id) else person__name(participant_id) end)"
	}
	method {
	    label "[_ dotlrn-ecommerce.Payment_Method]"
	    orderby method
	}
	total_price {
	    label "[_ dotlrn-ecommerce.Total_Amount]"
	    orderby total_price
	}
	refund_price {
	    label "[_ dotlrn-ecommerce.Total_Refunds]"
	    orderby refund_price
	}
	price_to_display {
	    label "[_ dotlrn-ecommerce.lt_Total_Amount_Received]"
	    orderby price_to_display
	}
	balance {
	    label "[_ dotlrn-ecommerce.Balance]"
	    orderby balance
	}
	checked_out_by {
	    label "[_ dotlrn-ecommerce.Regsitered_By_Admin]"
	    orderby checked_out_by_admin_p
	}
    }

db_multirow -extend { order_url section_url pretty_total pretty_balance person_url pretty_refund pretty_actual_total refund_url participant_url participant_type } orders orders [subst {
        
    select * from dlec_view_orders
    where 1=1
    [template::list::filter_where_clauses -and -name orders]
    
--    group by o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id), o.user_id, u.first_names, u.last_name, o.in_basket_date, t.method, section_name, s.section_id, s.course_id, o.authorized_date, balance, refund_price, refund_date, purchaser
     
    [template::list::orderby_clause -name orders -orderby]         
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
		    lockbox "[_ dotlrn-ecommerce.Lock_Box]" \
		    "[_ dotlrn-ecommerce.Credit_Card]"
	       ]
    set order_state [string totitle $order_state]
    set section_url [export_vars -base ../one-section { {section_id $_section_id} }]
    set person_url [export_vars -base ../one-user { {user_id $purchasing_user_id} }]
    set participant_url [export_vars -base ../one-user { {user_id $participant_id} }]
    set pretty_refund [ec_pretty_price $refund_price]
    set pretty_actual_total [ec_pretty_price $total_price]

    set refund_url [export_vars -base "items-return-2" { order_id item_id }]

    set participant_type [acs_object_type $participant_id]
}

if { [info exists section_id] } {
    set context [list [list [export_vars -base ../one-section { section_id }] [db_string section_name { select section_name from dotlrn_ecommerce_section where section_id = :section_id }]] "[_ dotlrn-ecommerce.Order_Summary]"]
} else {
    set context [list "[_ dotlrn-ecommerce.Order_Summary]"]
}