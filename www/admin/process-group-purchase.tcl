# packages/dotlrn-ecommerce/www/admin/process-group-puchase.tcl

ad_page_contract {
    Process registration of a group

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2005-05-19
} -query {
    section_id:integer,notnull

    {patron ""}
    {patron_id 0}

    user_id:integer,optional,notnull
} -properties {
    page_title
    context
}

if { [info exists user_id] } {
    set patron_id $user_id
}

set patron_list [linsert [db_list_of_lists patrons {
    select first_names||' '||last_name||' ('||email||')', user_id
    from dotlrn_users
    where (case when :patron = ''
	   then true
	   else lower(first_names||' '||last_name||' '||email) like '%'||lower(:patron)||'%' end)
}] 0 {{} 0}]

if { [llength $patron_list] == 1 } {
    set form [rp_getform]
    ns_set delkey $form __refreshing_p
    ns_set put $form __refreshing_p 0
}

set maxparticipants ""
set available_slots 0
db_0or1row participants {
    select v.maxparticipants, s.community_id, s.section_name, c.course_name
    from dotlrn_ecommerce_section s, ec_custom_product_field_values v, dotlrn_catalogi c, cr_items ci
    where s.product_id = v.product_id
    and s.section_id = :section_id
    and s.course_id = c.item_id
    and ci.live_revision = c.revision_id
}

if { ![empty_string_p $maxparticipants] } {
    db_1row attendees {
	select count(*) as attendees
	from dotlrn_member_rels_approved
	where community_id = :community_id
	and (rel_type = 'dotlrn_member_rel'
	     or rel_type = 'dc_student_rel')
    }

    set available_slots [expr $maxparticipants - $attendees]
}

if { [empty_string_p $maxparticipants] } {
    set validate {
	{num_members
	    {$num_members > 1 }
	    "Please enter a value greater than 1"
	}
    }
} else {
    set validate {
	{num_members
	    {$num_members > 1 && $num_members <= $available_slots }
	    "Please enter a value from 2 to $available_slots"
	}
    }
}

set next_url [export_vars -base process-group-purchase { section_id patron patron_id }]

if { ( [empty_string_p $patron] || [llength $patron_list] == 1 ) && ! $patron_id } {
    ad_form -name "process-group" -export { {patron_id 0} } -form {
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

    ad_form -name "process-group" -export { patron patron_id } -form {
	{patron_name:text(inform) {label "Patron"} {value "$patron_user(first_names) $patron_user(last_name) ($patron_user(email))"}}
    }

} else {
    ad_form -name "process-group" -export { patron } -form {
	{patron_id:integer(select),optional {label "Patron"} {options {$patron_list}}
	    {help_text "Select a patron from the list. Can't find the patron?<br /><a href=\"[export_vars -base patron-create { next_url }]\">Create an account</a> and return to this form"}
	}
    }

    lappend validate {patron_id
	{ $patron_id }
	"Please select a patron from the list"
    }
}

ad_form -extend -name process-group \
    -export { section_id } \
    -validate $validate \
    -confirm_template "process-group-purchase-confirm" \
    -form {
	group_id:key
	{name:text {label "Group Name"}}
	{num_members:integer(text) {label "Number of attendees"}}
    } -new_data {
	# FIXME do checking of max attendees etc here
	# FIXME figure out why this doesn't work in a transaction
	#	db_transaction {
	set unique_group_name "${name}_${group_id}"
	group::new -group_id $group_id -group_name $unique_group_name
	set section_community_id [db_string get_community_id "select community_id from dotlrn_ecommerce_section where section_id=:section_id" -default ""]
	if {[string equal "" $section_community_id]} {
	    # FIXME error, do something clever here
	}
	for { set i 1 } { $i <= $num_members } { incr i } {
	    array set new_user [auth::create_user \
				    -username "${name} Attendee $i" \
				    -email "[util_text_to_url -text ${name}-attendee-${i}]@example.com" \
				    -first_names "$name" \
				    -last_name "Attendee $i" \
				    -nologin]
	    #		ad_return_complaint 1 "new_user '[array get new_user]' section_community_id '${section_community_id}'"
	    #		if {[info exists new_user(user_id)]} {
	    #		    relation_add -member_state approved dc_student_rel $section_community_id $new_user(user_id)
#	    package_exec_plsql -var_list [list [list community_id $section_community_id] [list rel_type "dc_student_rel"] [list user_id $new_user(user_id)] [list member_state approved]] dc_student_rel new
	    relation_add -member_state approved membership_rel $group_id $new_user(user_id)

	    #	}
	    lappend new_users $new_user(user_id)
	}
	#	}
	relation_add relationship $group_id $section_community_id	    
    } -after_submit {
	set product_id [db_string get_course_id "select product_id from dotlrn_ecommerce_section where section_id = :section_id" -default ""]
#	set referer [export_vars -base [ad_conn package_url]admin/course-info {course_id}]

	ad_returnredirect -message "Added $num_members from $name" [export_vars -base "ecommerce/shopping-cart-add" { product_id { user_id $patron_id } { participant_id $group_id } { item_count $num_members } }]
#	ad_returnredirect -message "Added $num_members from $name" [export_vars -base membership-add { user_id {user_ids:multiple $new_users} section_id {community_id $section_community_id} referer }]
    }

set page_title "Add Group to $course_name: $section_name"
set context [list $page_title]
ad_return_template