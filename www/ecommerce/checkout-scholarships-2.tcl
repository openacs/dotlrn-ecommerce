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

# Assume there's a valid order_id
set user_session_id [ec_get_user_session_id]
set order_id [db_string get_order_id "
    select order_id 
    from ec_orders 
    where user_session_id = :user_session_id 
    and order_state = 'in_basket'" -default ""]

set order_total 0
set last_product_id 0

db_foreach order_details_select {
    select i.price_charged, p.product_id, count(*) as quantity, c.offer_code
    from ec_items i, ec_products p
    left join ec_user_session_offer_codes c on (c.product_id = p.product_id and c.user_session_id = :user_session_id)
    where i.order_id = :order_id
    and i.product_id = p.product_id
    group by p.product_name, p.one_line_description, p.product_id, i.price_name, i.price_charged, i.color_choice, i.size_choice, i.style_choice, c.offer_code
} {
    if {$product_id != $last_product_id} {
	set lowest_price [lindex [ec_lowest_price_and_price_name_for_an_item $product_id $user_id $offer_code] 0]
    }

    set order_total [expr $order_total + $quantity * $lowest_price]    
}
set order_total_price_pre_gift_certificate $order_total    


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
		# 		if { $amount < $amount_to_grant } {
		# 		    template::multirow append scholarships $one_fund_id $title $description $amount 0 0 "You entered an amount greater than what the fund can accommodate"
		
		# 		} else {
		# Valid
		db_transaction {

		    set gift_certificate_id [db_nextval ec_gift_cert_id_sequence]
		    set random_string [ec_generate_random_string 10]
		    set claim_check "scholarship-$random_string-$gift_certificate_id"
		    set peeraddr [ns_conn peeraddr]
		    set gc_months [ad_parameter -package_id [ec_id] GiftCertificateMonths ecommerce]
		    
		    set viewing_user_id [ad_conn user_id]

		    db_dml insert_new_gc_into_db [subst {
			insert into ec_gift_certificates
			(gift_certificate_id, gift_certificate_state, amount, issue_date, purchased_by, expires, last_modified, last_modifying_user, modified_ip_address, user_id)
			values
			(:gift_certificate_id, 'authorized', :amount_to_grant, current_timestamp, :viewing_user_id, current_timestamp + '$gc_months months'::interval, current_timestamp, :viewing_user_id, :peeraddr, :user_id)
		    }]
		    
		    db_dml insert_scholarship_grant {
			insert into scholarship_fund_grants
			(fund_id, user_id, gift_certificate_id, grant_amount)
			values
			(:one_fund_id, :user_id, :gift_certificate_id, :amount_to_grant)
		    }
		    
		}

		template::multirow append scholarships $one_fund_id $title $description [ec_pretty_price [expr $amount - $amount_to_grant]] [ec_pretty_price $amount_to_grant] 1 "Granted"
		set total_amount [expr $total_amount + $amount_to_grant]
		#		}
	    }
	}
    }
}

template::list::create \
    -name scholarships \
    -multirow scholarships \
    -no_data "No scholarship granted" \
    -elements {
	title { label Title }
	description { label Description }
	amount_granted { label "Amount Granted" }
	message { label "Comments" }
    }

if { $total_amount >= $order_total_price_pre_gift_certificate } {
    # Scholarship covers order
    set next_url [export_vars -base $return_url { {scholarship_covers_order_p 1} }]
} else {
    set next_url [export_vars -base checkout-one-form { user_id }]
}

set back_url [export_vars -base checkout-scholarships { user_id return_url }]
set amountsub [expr $total_amount - $order_total_price_pre_gift_certificate]

set pretty_total_price [ec_pretty_price $order_total_price_pre_gift_certificate]
