# packages/dotlrn-ecommerce/www/admin/membership-add.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-19
    @arch-tag: 147cb277-9537-4e94-aac5-c2c2e8c26adf
    @cvs-id $Id$
} {
    user_id:integer,notnull
    {confirmed_p:integer,notnull 0}
    community_id:integer,notnull
    section_id:integer,notnull

    {patron ""}
    {patron_id 0}

    referer:notnull

    participant_id:optional
} -properties {
} -validate {
} -errors {
}

if { ! [dotlrn::user_p -user_id $user_id] } {
    dotlrn::user_add -user_id $user_id
}
    
if { [info exists participant_id] } {
    set patron_id $user_id
    set user_id $participant_id
}

set next_url [export_vars -base membership-add { section_id community_id referer patron patron_id {participant_id $user_id} }]
db_1row get_section_info "select c.course_id, s.section_name
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

set context [list [list [export_vars -base course-info { course_id }] $section_name] "Process Purchase"]

if { $confirmed_p } {
    set community_url [dotlrn_community::get_community_url $community_id]
    set add_member_url [export_vars -base ${community_url}member-add-3 { user_id { rel_type dotlrn_member_rel } referer }]

    ad_returnredirect $add_member_url
    ad_script_abort
} else {
    set title "Confirm Purchase"
    db_1row section_name {
	select section_name
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    acs_user::get -user_id $user_id -array user

    set confirm_url [export_vars -base membership-add { user_id {confirmed_p 1} community_id section_id referer }]

    set patron_list [linsert [db_list_of_lists patrons {
	select first_names||' '||last_name||' ('||email||')', user_id
	from dotlrn_users
	where user_id != :user_id
	and (case when :patron = ''
	     then true
	     else lower(first_names||' '||last_name||' '||email) like '%'||lower(:patron)||'%' end)
    }] 0 {{} 0}]

    if { [llength $patron_list] == 1 } {
	set form [rp_getform]
	ns_set delkey $form __refreshing_p
	ns_set put $form __refreshing_p 0
    }
    
    set validate [list]

    if { ( [empty_string_p $patron] || [llength $patron_list] == 1 ) && ! $patron_id } {
	ad_form -name "patron" -export { {patron_id 0} } -form {
	    {patron:text,optional {label "Search Patron"} {html {onchange "if (this.value != '') { this.form.__refreshing_p.value = 1; } else { this.form.__refreshing_p.value = 0 ; }"}}
		{help_text "Enter a string to search names and email addresses. <br />Or <a href=\"[export_vars -base patron-create { next_url }]\">Create an account</a> and return to this form"}
	    }
	}

	lappend validate {patron
	    { ! [empty_string_p $patron] }
	    "Please enter a search string"
	}
	lappend validate {patron
	    { [llength $patron_list] > 1 }
	    "No users found. Please try again"
	}
    } elseif { $patron_id } {
	acs_user::get -user_id $patron_id -array patron_user

	ad_form -name "patron" -export { patron patron_id } -form {
	    {patron_name:text(inform) {label "Patron"} {value "$patron_user(first_names) $patron_user(last_name) ($patron_user(email))"}}
	}

	lappend validate {relationship
	    { $relationship != [list [list 0 $community_id]] || ![empty_string_p [template::element::get_value patron relationship_new]] }
	    "Please select a relationship or enter a new one"
	}
    } else {
	ad_form -name "patron" -export { patron } -form {
	    {patron_id:integer(select),optional {label "Patron"} {options {$patron_list}}
		{help_text "Select a patron from the list. Can't find the patron?<br /><a href=\"[export_vars -base patron-create { next_url }]]\">Create an account</a> and return to this form"}
	    }
	}

	lappend validate {patron_id
	    { $patron_id }
	    "Please select a patron from the list"
	}

	lappend validate {relationship
	    { $relationship != [list [list 0 $community_id]] || ![empty_string_p [template::element::get_value patron relationship_new]] }
	    "Please select a relationship or enter a new one"
	}
    }

    ad_form -extend -name "patron" -export { user_id {confirmed_p 0} community_id section_id referer } \
	-validate $validate \
	-form {
	    {relationship:text(category),optional,multiple {label "Relationship"} {value {0 $community_id}} {html {size 4}}
		{help_text "Please select one or enter one below if not in the list"}
		{assign_single_p t}
	    }
	    {relationship_new:text,optional {label "Other Relationship"}
		{help_text "This field is ignored if a relationship is selected from the list above"}
	    }
	    {proceed:text(submit) {label "Add Participant with Patron"}}
	} -on_submit {
	    set rel_id [relation::get_id -object_id_one $user_id -object_id_two $patron_id -rel_type "patron_rel"]

	    if { [empty_string_p $rel_id] } {
		# Create patron relationship
		set rel_id [db_exec_plsql relate_patron {
		    select acs_rel__new (null,
			     'patron_rel',
			     :user_id,
			     :patron_id,
			     null,
			     null,
			     null)
		}]
		ns_log notice "DEBUG:: Created relationship $rel_id: $user_id - $patron_id"
	    } else {
		ns_log notice "DEBUG:: Existing relationship $rel_id: $user_id - $patron_id"
	    }

	    # Check if no categories were selected
	    if { $relationship == [list [list 0 $community_id]] } {
		set relationship ""

		# See if user entered a new relationship and add that
		if { ! [empty_string_p $relationship_new] } {
		    set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
		    set relationship [list [category::add -name $relationship_new -tree_id $tree_id -parent_id ""]]
		}
	    }

	    # Set relationships from categories
	    ns_log notice "DEBUG:: Categories $relationship rel_id $rel_id"
	    category::map_object -remove_old -object_id $rel_id $relationship

	    ad_returnredirect [export_vars -base membership-add { user_id { confirmed_p 1 } community_id section_id referer }]
	    ad_script_abort
	}
}