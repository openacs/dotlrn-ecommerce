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
} -properties {
} -validate {
} -errors {
}

ad_form -name "search" -export { return_url section_id } -form {
    {search:text {label "Search existing users"}}
}

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
		    <a href="@users.add_member_url;noquote@" class="button">[_ dotlrn-ecommerce.User_Info]</a>
		    <a href="ecommerce/index?user_id=@users.user_id@" class="button">[_ dotlrn-ecommerce.Order_Details]</a>
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
	set add_member_url [export_vars -base one-user { user_id }]
    }
}