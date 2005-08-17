# packages/dotlrn-ecommerce/lib/financial-transactions.tcl
#
# Financial transactions chunk
#
# @author Roel Canicula (roelmc@pldtdsl.net)
# @creation-date 2005-08-14
# @arch-tag: f154b8f3-d746-4d57-9ab5-49ca9d5d9a95
# @cvs-id $Id$

foreach required_param {order_id} {
    if {![info exists $required_param]} {
	return -code error "$required_param is a required parameter."
    }
}
foreach optional_param {} {
    if {![info exists $optional_param]} {
	set $optional_param {}
    }
}

set transaction_counter 0

# Check for payment methods
set method [db_string method {
    select method, internal_account
    from dotlrn_ecommerce_transactions
    where order_id = :order_id
} -default cc]

set scholarship_p [db_0or1row scholarship {
    select 1
    where exists (select *
		  from ec_gift_certificate_usage
		  where order_id = :order_id
		  and exists (select *
			      from scholarship_fund_grants
			      where ec_gift_certificate_usage.gift_certificate_id = gift_certificate_id))
}]

set total_price [db_string total_price {select ec_total_price(:order_id)} -default 0]
set total_refunds [db_string total_refunds {select ec_total_refund(:order_id)} -default 0]

if { $method == "invoice" } {
    # List invoice payments
    set invoice_payment_sum 0
    db_multirow invoice_payments invoice_payments {
	select amount, to_char(payment_date, 'Month dd, yyyy hh:miam') as pretty_payment_date, method as invoice_method
	from dotlrn_ecommerce_transaction_invoice_payments
	where order_id = :order_id
	order by payment_date
    } {
	set invoice_payment_sum [expr $invoice_payment_sum + $amount]
	set amount [ec_pretty_price $amount]
	set invoice_method [ad_decode $invoice_method cc "Credit Card" internal_account "Internal Account" check "Check" cash "Cash" lockbox "Lock Box" "Credit Card"]
    }

}

if { $scholarship_p } {
    set gc_amount [db_string gc_amount {select ec_order_gift_cert_amount(:order_id)} -default 0]
    
    db_multirow funds funds {
	select f.title, u.amount_used, g.grant_amount, to_char(g.grant_date, 'Month dd, yyyy hh:miam') as grant_date
	from ec_gift_certificate_usage u, scholarship_fund_grants g, scholarship_fundi f
	where u.gift_certificate_id = g.gift_certificate_id
	and g.fund_id = f.fund_id
	and u.order_id = :order_id
	and not u.amount_used is null
	
	order by g.grant_date
    } {
	set grant_amount [ec_pretty_price $grant_amount]
	set amount_used [ec_pretty_price $amount_used]
	
    }
}

db_multirow financial_transactions financial_transactions_select "
    select t.transaction_id, t.inserted_date, t.transaction_amount, t.transaction_type, t.to_be_captured_p, t.authorized_date, 
        t.marked_date, t.refunded_date, t.failed_p, c.creditcard_last_four
    from ec_financial_transactions t, ec_creditcards c
    where t.creditcard_id=c.creditcard_id
    and t.order_id=:order_id
    order by transaction_id" {
	
    incr transaction_counter
    set inserted_date [ec_nbsp_if_null [ec_formatted_full_date $inserted_date]]
    set transaction_amount [ec_pretty_price $transaction_amount]
    set transaction_type [ec_decode $transaction_type "charge" "authorization to charge" "intent to refund"]
    set to_be_captured_p [ec_nbsp_if_null [ec_decode $transaction_type "refund" "Yes" [ec_decode $to_be_captured_p "t" "Yes" "f" "No" ""]]]

    set authorized_date [ec_nbsp_if_null [ec_formatted_full_date $authorized_date]]
    set marked_date [ec_nbsp_if_null [ec_formatted_full_date $marked_date]]
    set refunded_date [ec_nbsp_if_null [ec_formatted_full_date $refunded_date]]
    set failed_p [ec_nbsp_if_null [ec_decode $failed_p "t" "Yes" "f" "No" ""]]
}
