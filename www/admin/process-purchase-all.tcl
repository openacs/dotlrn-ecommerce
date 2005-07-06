# packages/dotlrn-ecommerce/www/admin/process-purchase.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: d78f1eb7-313d-4c1a-8f1c-6be5c4f0765a
    @cvs-id $Id$
} {
    {orderby email_address}
    {page 1}    
    {search:trim ""}
    {return_url ""}
    section_id:integer,optional
} -properties {
} -validate {
} -errors {
}

set title "Who is paying for the course?"
set context [list {Process Purchase}]

if { [empty_string_p $search] } {
    # Clear shopping cart
    set user_session_id [ec_get_user_session_id]

    set order_id [db_string get_order_id "select order_id from ec_orders where user_session_id=:user_session_id and order_state='in_basket'" -default ""]

    if { ! [empty_string_p $order_id] } {
	db_dml delete_item_from_cart "delete from ec_items where order_id=:order_id"
    }
}

if { [empty_string_p $return_url] } {
    set return_url [export_vars -base [ad_conn package_url]admin/course-info {course_id}]
}

ad_form -name "search" -export { return_url section_id } -form {
    {search:text {label "Search existing users"}}
}

set add_action "Choose Purchaser"

if { ! [empty_string_p $search] } {

    set page_query [subst {
	select u.user_id, u.email, u.first_names, u.last_name, a.phone, a.line1, a.line2
	from dotlrn_users u
	left join (select *
		   from ec_addresses
		   where address_id
		   in (select max(address_id)
		       from ec_addresses
		       group by user_id)) a
	on (u.user_id = a.user_id)
	where (lower(first_names) like lower(:search)||'%' or
	       lower(last_name) like lower(:search)||'%' or
	       lower(email) like lower(:search)||'%' or
	       lower(phone) like '%'||lower(:search)||'%')
    }]
    
    template::list::create \
	-name "users" \
	-multirow "users" \
	-no_data "No users found" \
	-key user_id \
	-page_query $page_query \
	-page_size 50 \
	-page_flush_p 1 \
	-elements {
	    user_id {
		label "User ID"
	    }
	    email {
		label "Email Address"
	    }
	    first_names {
		label "First Name"
	    }
	    last_name {
		label "Last Name"
	    }
	    phone {
		label "Phone Number"
	    }
	    address {
		label "Address"
		display_template {
		    @users.line1@
		    <if @users.line2@ not nil>
		    <br />@users.line2@
		    </if>
		}
	    }
	    action {
		html { nowrap }
		display_template {
		    <a href="@users.add_member_url;noquote@" class="button">$add_action</a>
		}
	    }
	} \
	-filters {
	    search {}
	    return_url {}
	}

    db_multirow -extend { add_member_url } users users [subst {
	$page_query
	[template::list::page_where_clause -name users -key u.user_id -and]
    }] {
	set add_member_url [export_vars -base process-purchase-course { user_id return_url section_id }]
    }
}

set next_url [export_vars -base process-purchase-course { { referer $return_url } section_id }]
