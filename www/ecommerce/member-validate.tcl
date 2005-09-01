# packages/mos-integration/www/admin/member-validate.tcl

ad_page_contract {
    
    test page for validating members
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-07-11
    @arch-tag: 752d975b-1f3d-4256-8d17-9da5e243c25e
    @cvs-id $Id$
} {
    {user_id:optional}
} -properties {
} -validate {
} -errors {
}

if {![exists_and_not_null user_id]} {
    set user_id [auth::require_login]
}

set title "Member validation"
set context [list $title]

set group_id [parameter::get -parameter MemberGroupId]

set result_stub ""
set validate_result ""

ad_form \
    -name member_validate \
    -form {
        {group_id:text(hidden) {value $group_id}}
        {user_id:text(hidden) {value $user_id}}
        {memberid:text {label "Member ID"}}
        {zipcode:integer {label "Zip code"}}
        {lastname:text {label "Last Name"}}
    } \
    -after_submit {
        set validate_result [mos_integration::member_validate -user_id $user_id -group_id $group_id -memberid $memberid -zipcode $zipcode -lastname $lastname]
	if {[string equal $validate_result 1]} {
	    set user_session_id [ec_get_user_session_id]
	    set order_id [db_string get_order_id {
		select order_id
		from ec_orders
		where user_session_id = :user_session_id
		and order_state = 'in_basket'
	    }  -default ""]
	    dotlrn_ecommerce::ec::toggle_offer_codes -order_id $order_id -insert
	    ad_returnredirect [export_vars -base "shopping-cart" {user_id}]
	} elseif {[string equal $validate_result "EXPIRED"]} {
	    append result_stub "Your membership has expired. <a href=\"memberships?user_id=$user_id\">You can buy one now</a>"
	} else {
	    append result_stub "The information you provided did not validate.<br /><a href=\"shopping-cart?user_id=$user_id\">Continue shopping without validating your membership</a> or <br /><a href=\"memberships?user_id=$user_id\">Buy one now</a>"
	}
    }

