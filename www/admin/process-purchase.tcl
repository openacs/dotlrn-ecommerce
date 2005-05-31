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
    section_id:integer,optional
    {return_url ""}
} -properties {
} -validate {
} -errors {
}

if { [exists_and_not_null section_id] } {

    db_1row get_section_info "select c.course_id, s.section_name
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

    set context [list [list [export_vars -base course-info { course_id }] $section_name] "Process Purchase"]

    db_1row get_community {
	select community_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    set return_url [export_vars -base [ad_conn package_url]admin/course-info {course_id}]

    ad_form -name "search" -export { section_id patron return_url } -form {
	{search:text {label "Search existing users"}}
    }

    set add_action "Choose Participant"

    if { ! [empty_string_p $search] } {

	set page_query {
	    select user_id, email, first_names, last_name
	    from dotlrn_users
	    where lower(first_names||' '||last_name||' '||email) like '%'||lower(:search)||'%'

	    and not user_id
	    in (select user_id
		from dotlrn_member_rels_full
		where community_id = :community_id)}
	

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
	    }

	db_multirow -extend { add_member_url } users users [subst {
	    $page_query
	    [template::list::page_where_clause -name users -key user_id -and]
	}] {
	    set add_member_url [export_vars -base membership-add { user_id {referer $return_url} section_id community_id }]
	}
    }

    template::list::create \
	-name members \
	-multirow members \
	-no_data "No users has purchased this section" \
	-page_flush_p 1 \
	-key user_id \
	-bulk_actions { "Remove Membership" membership-remove "Remove Membership" } \
	-bulk_action_export_vars { community_id return_url patron } \
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
	} \
	-filters {
	    search {}
	    section_id {}
	}

    db_multirow members members {
	select r.user_id, r.rel_id, r.role, u.first_names, u.last_name, u.email
	from dotlrn_member_rels_full r, dotlrn_users u
	where r.member_state = 'approved'
	and r.rel_type = 'dotlrn_member_rel'
	and r.user_id = u.user_id
	and r.community_id = :community_id
    }

}

set next_url [export_vars -base membership-add { section_id community_id { referer $return_url} }]