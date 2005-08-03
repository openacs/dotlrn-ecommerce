# packages/dotlrn-ecommerce/www/ecommerce/checkout-scholarships-2.tcl

ad_page_contract {
    
    Process scholarships
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-02
    @arch-tag: f3382efc-34f6-4816-9fb6-3b9508b416df
    @cvs-id $Id$
} {
    {fund_id:integer,multiple {}}
    return_url:notnull
    user_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set form [rp_getform]

template::multirow create scholarships fund_id title description amount_left amount_granted valid_p message

set total_amount 0

foreach one_fund_id $fund_id {
    if { [db_0or1row scholarship {
	select sf.*
	from scholarship_fundi sf,
	cr_items ci
	where sf.revision_id = ci.live_revision
	and sf.fund_id = :one_fund_id
    }] } {

	if { [empty_string_p [set amount_to_grant [ns_set get $form "amount.${one_fund_id}"]]] } {
	    # Empty
	    template::multirow append scholarships $one_fund_id $title $description $amount 0 0 "Please enter an amount"
	} else {
	    if { ! [string is double $amount_to_grant] } {
		# Invalid value
		template::multirow append scholarships $one_fund_id $title $description $amount 0 0 "You entered an invalid amount"
	    } else {
		if { $amount < $amount_to_grant } {
		    template::multirow append scholarships $one_fund_id $title $description $amount 0 0 "You entered an amount greater than what the fund can accommodate"
		    
		} else {
		    # Valid
		    template::multirow append scholarships $one_fund_id $title $description [expr $amount - $amount_to_grant] $amount_to_grant 1 "Granted"
		    set total_amount [expr $total_amount + $amount_to_grant]
		}
	    }
	}

    }
}

template::list::create \
    -name scholarships \
    -multirow scholarships \
    -elements {
	title { label Title }
	description { label Description }
	amount_left { label "Amount in Fund" }
	amount_granted { label "Amount Granted" }
	message { label "Comments" }
    }

# Assume there's a valid order_id
set user_session_id [ec_get_user_session_id]
set order_id [db_string get_order_id "
    select order_id 
    from ec_orders 
    where user_session_id = :user_session_id 
    and order_state = 'in_basket'" -default ""]

set price_shipping_gift_certificate_and_tax [ec_price_shipping_gift_certificate_and_tax_in_an_order $order_id]
set order_total_price_pre_gift_certificate [expr [lindex $price_shipping_gift_certificate_and_tax 0] + [lindex $price_shipping_gift_certificate_and_tax 1]]

if { $total_amount >= $order_total_price_pre_gift_certificate } {
    # Scholarship covers order
    set next_url $return_url
} else {
    set next_url [export_vars -base checkout-one-form]
}

set back_url [export_vars -base checkout-scholarships { user_id return_url }]
set amountsub [expr $total_amount - $order_total_price_pre_gift_certificate]