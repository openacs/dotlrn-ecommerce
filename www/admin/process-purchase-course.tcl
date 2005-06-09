# packages/dotlrn-ecommerce/www/admin/process-purchase-course.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-06
    @arch-tag: 8dc760f9-5c1e-4de6-bdb7-382d2eca096d
    @cvs-id $Id$
} {
    user_id:integer,notnull

    {participant ""}
    {participant_id 0}

    {section ""}
    {section_id 0}

    purchaser_id:integer,optional,notnull
} -properties {
} -validate {
} -errors {
}

if { [info exists purchaser_id] } {
    set participant_id $user_id
    set user_id $purchaser_id

    # We already have everything we need, add to shopping cart
#     if { $section_id > 0 } {
# 	db_1row product {
# 	    select product_id
# 	    from dotlrn_ecommerce_section
# 	    where section_id = :section_id
# 	}
# 	ad_returnredirect [export_vars -base "ecommerce/shopping-cart-add" { product_id user_id participant_id {item_count 1} }]
# 	ad_script_abort
#     }
}

set title "Purchase courses/sections for [person::name -person_id $user_id]"

set next_url [export_vars -base process-purchase-course { {purchaser_id $user_id} participant participant_id section section_id }]

if { ! [dotlrn::user_p -user_id $user_id] } {
    dotlrn::user_add -user_id $user_id
}

if { $participant_id } {
    if { ! [dotlrn::user_p -user_id $participant_id] } {
	dotlrn::user_add -user_id $participant_id
    }
}

set validate [list]

# Search course or section
set section_list [linsert [db_list_of_lists patrons {
    select case when s.section_name is null
    then c.course_name
    else '... '||s.section_name
    end, s.section_id
    from dotlrn_catalogi c, (select -course_id as section_id, c.item_id as course_id, course_name, null as section_name
			     from dotlrn_catalogi c, cr_items i
			     where c.item_id = i.item_id
			     and c.course_id = i.live_revision

			     union 			
			     
			     select section_id, course_id, null as course_name, section_name 			
			     from dotlrn_ecommerce_section  			
			     order by course_id, section_name) s, cr_items i
    where c.item_id = s.course_id
    and c.course_id = i.live_revision
    and c.item_id = i.item_id
    and 
    case when :section is null then true
    else
    case when s.section_name is null then lower(c.course_name) like '%'||lower(:section)||'%' 
    else lower(c.course_name||' '||s.section_name) like '%'||lower(:section)||'%' end
    end

    order by c.course_name, s.section_id
}] 0 {{} 0}]

ns_log notice "DEBUG:: $section - $section_list"

if { [llength $section_list] == 1 } {
    set form [rp_getform]
    ns_set delkey $form __refreshing_p
    ns_set put $form __refreshing_p 0
}

ad_form -name "participant" -form {
    {purchaser:text(inform) {label "Purchaser"} {value "[person::name -person_id $user_id]"}}
}

if { ( [empty_string_p $section] || [llength $section_list] == 1 ) && ! $section_id } {
    set show_all_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id -1} }]
    ad_form -extend -name "participant" -export { {section_id 0} } -form {
	{section:text,optional {label "Search Course/Section"} {html {onchange "if (this.value != '') { this.form.__refreshing_p.value = 1; } else { this.form.__refreshing_p.value = 0 ; }" size 30}}
	    {help_text "Enter a string to search course and section names"}
	    {after_html {<a href="$show_all_url" class="button">Show All</a>}}
	}
    }

    lappend validate {section
	{ ! [empty_string_p $section] }
	"Please enter a search string"
    }
    lappend validate {section
	{ [llength $section_list] > 1 }
	"No courses/sections found. Please try again"
    }
} elseif { $section_id > 0 } {
    db_1row section {
	select c.course_name, s.section_name
	from dotlrn_ecommerce_section s, dotlrn_catalogi c
	where s.course_id = c.item_id
	and s.section_id = :section_id
	limit 1
    }

    set search_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id 0} }]
    ad_form -extend -name "participant" -export { section section_id } -form {
	{section_name:text(inform) {label "Section"} {value "$course_name &raquo; $section_name"}
	    {after_html {<a href="$search_url" class="button">Search Again</a>}}
	}
    }

} else {
    set search_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id 0} }]
    ad_form -extend -name "participant" -export { section } -form {
	{section_id:integer(select),optional {label "Select Section"} {options {$section_list}}
	    {after_html {<a href="$search_url" class="button">Search Again</a>}}
	}

    }

    lappend validate {section_id
	{ $section_id }
	"Please select a section from the list"
    }
    lappend validate {section_id
	{ $section_id > 0 }
	"Please select a section under this course"
    }
}

# Select a participant/participants
set participant_list [linsert [db_list_of_lists participants {
    select first_names||' '||last_name||' ('||email||')', user_id
    from dotlrn_users
    where user_id != :user_id
    and (case when :participant is null
	 then true
	 else lower(first_names||' '||last_name||' '||email) like '%'||lower(:participant)||'%' end)
}] 0 {{} 0}]

if { [llength $participant_list] == 1 } {
    set form [rp_getform]
    ns_set delkey $form __refreshing_p
    ns_set put $form __refreshing_p 0
}

if { ( [empty_string_p $participant] || [llength $participant_list] == 1 ) && ! $participant_id } {
    ad_form -extend -name "participant" -export { {participant_id 0} } -form {
	{-section "Individual Purchase"}
	{participant_pays_p:boolean(checkbox),optional {label "Search Participant"} {options {{"Participant also pays for the course" t}}}
	    {help_text "If you select this option, there's no need to select a user below.<br />Leave this unchecked for group purchases"}
	}
	{participant:text,optional {label ""} {html {onchange "if (this.value != '') { this.form.__refreshing_p.value = 1; } else { this.form.__refreshing_p.value = 0 ; }" size 30}}
	    {help_text "Enter a string to search names and email addresses. <br />Or <a href=\"[export_vars -base participant-create { next_url }]\">Create an account</a> and return to this form"}
	}
	{-section "Group Purchase"}
	{name:text,optional {label "Group Name"} {html {size 30}}}
	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
    }

    lappend validate {participant
	{ ! [empty_string_p $participant] || [template::element::get_value participant participant_pays_p] == "t" ||
	    (![empty_string_p [template::element::get_value participant name]] && 
	     ![empty_string_p [template::element::get_value participant num_members]]) }
	"Please enter a search string"
    }
    lappend validate {participant
	{ [llength $participant_list] > 1 || [template::element::get_value participant participant_pays_p] == "t" ||
	    (![empty_string_p [template::element::get_value participant name]] && 
	     ![empty_string_p [template::element::get_value participant num_members]]) }
	"No users found. Please try again"
    }
} elseif { $participant_id } {
    acs_user::get -user_id $participant_id -array participant_user

    set search_url [export_vars -base process-purchase-course { user_id {participant ""} {participant_id 0} section section_id }]
    ad_form -extend -name "participant" -export { participant participant_id } -form {
	{-section "Individual Purchase"}
	{participant_pays_p:boolean(checkbox),optional {label "Participant"} {options {{"Participant also pays for the course" t}}}}
	{participant_name:text(inform) {label ""} {value "$participant_user(first_names) $participant_user(last_name) ($participant_user(email))"}
	    {after_html {<a href="$search_url" class="button">Search Again</a>}}
	}
	{-section "Group Purchase"}
	{name:text,optional {label "Group Name"} {html {size 30}}}
	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
    }

} else {
    set search_url [export_vars -base process-purchase-course { user_id {participant ""} {participant_id 0} section section_id }]
    ad_form -extend -name "participant" -export { participant } -form {
	{-section "Individual Purchase"}
	{participant_pays_p:boolean(checkbox),optional {label "Select Participant"} {options {{"Participant also pays for the course" t}}}}
	{participant_id:integer(select),optional {label ""} {options {$participant_list}}
	    {help_text "Select a participant from the list. Can't find the participant?<br /><a href=\"[export_vars -base participant-create { next_url }]\">Create an account</a> and return to this form"}
	    {after_html {<a href="$search_url" class="button">Search Again</a>}}
	}
	{-section "Group Purchase"}
	{name:text,optional {label "Group Name"} {html {size 30}}}
	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
    }

    lappend validate {participant_id
	{ $participant_id || [template::element::get_value participant participant_pays_p] == "t" }
	"Please select a participant from the list"
    }
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
	     or rel_type = 'dotlrn_club_student_rel')
    }

    set available_slots [expr $maxparticipants - $attendees]
}

if { [empty_string_p $maxparticipants] } {
    lappend validate \
	{num_members
	    {$num_members > 1 || [empty_string_p $num_members] }
	    "Please enter a value greater than 1"
	}
} else {
    lappend validate \
	{num_members
	    { ($num_members > 1 && $num_members <= $available_slots) || [empty_string_p $num_members] }
	    "Please enter a value from 2 to $available_slots"
	}
}

ad_form -extend -name "participant" -export { user_id referer } -validate $validate -form {
} -on_submit {
    db_1row product {
	select product_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    set item_count 1
    if { $participant_pays_p != "t" && ! [empty_string_p $name] && ! [empty_string_p $num_members] } {
	set group_id [db_nextval acs_object_id_seq]

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
	    
	    relation_add -member_state approved membership_rel $group_id $new_user(user_id)
	}
	relation_add relationship $group_id $section_community_id

	set participant_id $group_id
	set item_count $num_members
    }
    
    ad_returnredirect [export_vars -base "ecommerce/shopping-cart-add" { product_id user_id participant_id item_count }]
    ad_script_abort
}