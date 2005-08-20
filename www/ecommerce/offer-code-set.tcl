# packages/dotlrn-ecommerce/www/ecommerce/offer-code-set.tcl

ad_page_contract {
    
    Set offer code
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-20
    @arch-tag: eaad10fa-7003-47e9-b633-f9d45587751b
    @cvs-id $Id$
} {
    user_id:integer,notnull,optional
    product_id:integer,notnull
    offer_code
    return_url:notnull
} -properties {
} -validate {
} -errors {
}

if { ![exists_and_not_null user_id] } {
    set user_id [ad_verify_and_get_user_id]
}

set user_session_id [ec_get_user_session_id]
ec_create_new_session_if_necessary [export_url_vars product_id offer_code return_url]

if { ! [empty_string_p $offer_code] } {
    if { [db_string get_offer_code_p "
	select count(*) 
	from ec_user_session_offer_codes 
	where user_session_id=:user_session_id
	and product_id=:product_id"] == 0 } {
	db_dml inert_uc_offer_code "
	    insert into ec_user_session_offer_codes
	    (user_session_id, product_id, offer_code) 
	    values 
	    (:user_session_id, :product_id, :offer_code)"
    } else {
	db_dml update_ec_us_offers "
	    update ec_user_session_offer_codes 
	    set offer_code = :offer_code
	    where user_session_id = :user_session_id
	    and product_id = :product_id"
    }

    set original_price [lindex [ec_lowest_price_and_price_name_for_an_item $product_id $user_id] 0]
    set discounted_price [lindex [ec_lowest_price_and_price_name_for_an_item $product_id $user_id $offer_code] 0]
    if { ($original_price - $discounted_price) != 0 } {
	set savings [ec_pretty_price [expr $original_price - $discounted_price]]
	set message "[_ dotlrn-ecommerce.lt_The_offer_code_was_ac]"
    } else {
	set message "[_ dotlrn-ecommerce.lt_Sorry_the_offer_code_]"
    }

    ad_returnredirect -message $message $return_url
} else {
    ad_returnredirect $return_url
}
