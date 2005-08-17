# packages/dotlrn-ecommerce/www/admin/process-purchase.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: d78f1eb7-313d-4c1a-8f1c-6be5c4f0765a
    @cvs-id $Id$
} {
    user_id:integer,notnull
    {orderby email_address}
    {page 1}    
    {search:trim ""}
    section_id:integer,optional
    return_url
    next_url:optional
} -properties {
} -validate {
} -errors {
}

set title ""

if { [exists_and_not_null section_id] } {

    db_1row get_section_info "select c.course_id, c.course_name,
    s.section_name, s.community_id, s.product_id
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

    set context [list [list [export_vars -base course-info { course_id }] $section_name] "Process Purchase"]
    
    set title "Select Participant for $course_name: $section_name"

    if { [empty_string_p $return_url] } {
	set return_url [export_vars -base [ad_conn package_url]admin/course-info {course_id}]
    }

    ad_form -name "search" -export { user_id section_id return_url } -form {
	{search:text {label "Search existing users"}}
    }

    set add_action "Choose Participant"

    if { ! [empty_string_p $search] } {

    set page_query [subst {
	select u.user_id as participant_id, u.email, u.first_names, u.last_name, a.phone, a.line1, a.line2
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
	and not u.user_id
	in (select user_id
	    from dotlrn_member_rels_full
	    where community_id = :community_id)
    }]

# 	set page_query {
# 	    select user_id as participant_id, email, first_names, last_name
# 	    from dotlrn_users
# 	    where lower(first_names||' '||last_name||' '||email) like '%'||lower(:search)||'%'

# 	    and user_id != :user_id
# 	    and not user_id
# 	    in (select user_id
# 		from dotlrn_member_rels_full
# 		where community_id = :community_id)}
	

	template::list::create \
	    -name "users" \
	    -multirow "users" \
	    -no_data "No users found" \
	    -key participant_id \
	    -page_query $page_query \
	    -page_size 50 \
	    -page_flush_p 1 \
	    -elements {
		participant_id {
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
		section_id {}
		user_id {}
	    }

	db_multirow -extend { add_member_url } users users [subst {
	    $page_query
	    [template::list::page_where_clause -name users -key u.user_id -and]
	}] {
	    set add_url [export_vars -base "../ecommerce/shopping-cart-add" { product_id user_id participant_id return_url }]
	    set add_member_url [export_vars -base "../ecommerce/participant-add" { {user_id $participant_id} section_id return_url add_url }]

	}
    }

    set add_url [export_vars -base "ecommerce/shopping-cart-add" { product_id }]
    set addpatron_url [export_vars -base "membership-add" { user_id section_id community_id {referer $return_url} }]
    set next_url [export_vars -base process-purchase-2 { {patron_id $user_id} section_id community_id return_url }]
}