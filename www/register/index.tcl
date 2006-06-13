# packages/dotlrn-ecommerce/register/index.tcl

ad_page_contract {

    This is where users should register for a course
	only IF the dotlrn-ecommerce parameter NoPayment
	is set to "1" which means the site 
	does not ask for payment when users register for a course
	thus totally bypassing shopping cart and the checkout process.

    @author Hamilton Chua (hamilton.chua@gmail.com)
    @creation-date 2005-05-19
} {
	community_id
	product_id
}

set title "Course Registration"

# verify that NoPayment is set to "1"
# if it's not set to "1", redirect to shopping cart
if { ![parameter::get -package_id [ad_conn package_id] -parameter NoPayment -default 0] } {
	ad_returnredirect "/dotlrn-ecommerce/ecommerce/shopping-cart"
}

# put other checks here
# e.g check for Max Participants etc.

# make sure user is logged in and registered
set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	set register_url "../ecommerce/login?return_url=[ns_urlencode [ad_conn url]?community_id=$community_id&product_id=$product_id]"
	ad_returnredirect $register_url
	ad_script_abort
} else {
    if { [exists_and_not_null community_id] } {
	dotlrn_ecommerce::check_user -user_id $user_id
	
	# register the user		
	dotlrn_community::add_user $community_id $user_id
	set reg_message "Thank you for registering.... <br /> <i>Placeholder for complete message</i>"
    } else {
	set reg_message "Invalid community id"
    }
}
