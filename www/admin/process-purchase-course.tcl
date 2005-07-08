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

    {page 1}

    {__refreshing_p 0}

    {related_user 0}
    {new_user_p 0}

    {waiting_list_p 0}
} -properties {
} -validate {
} -errors {
}

if { [info exists purchaser_id] } {
    set participant_id $user_id
    set user_id $purchaser_id
}

if { $related_user > 0 } {
    set participant_id $related_user
    set participant ""
    
    set rel_id [relation::get_id -object_id_one $user_id -object_id_two $participant_id -rel_type "patron_rel"]
}

acs_user::get -user_id $user_id -array user_info

set title "Purchase courses/sections for [person::name -person_id $user_id]"

set next_url [export_vars -base process-purchase-course { {purchaser_id $user_id} participant participant_id section section_id related_user {new_user_p 1} }]

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
set section_list [linsert [db_list_of_lists sections {
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
    and (case when :section is null then true
	 else
	 
	 case when s.section_name is null then 

	 (lower(c.course_name) like '%'||lower(:section)||'%' 
	  or exists (select 1
		     from dotlrn_ecommerce_section
		     where course_id = s.course_id
		     and lower(section_name) like '%'||lower(:section)||'%'
		     limit 1))
	 
	 else lower(c.course_name||' '||s.section_name) like '%'||lower(:section)||'%' end
	 
	 end)

    order by c.course_name, s.section_id
}] 0 {{} 0}]

ns_log notice "DEBUG:: $section - $section_list"

if { [llength $section_list] == 1 } {
    set form [rp_getform]
    ns_set delkey $form __refreshing_p
    ns_set put $form __refreshing_p 0
}

ad_form -name "participant" -form {
    {waiting_list_p:integer(hidden) {value $waiting_list_p}}
    {purchaser:text(inform) {label "Purchaser"} {value "[person::name -person_id $user_id]"}}
}

if { ( [empty_string_p $section] || [llength $section_list] == 1 ) && ! $section_id } {
    set show_all_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id -1} related_user new_user_p }]
    ad_form -extend -name "participant" -export { {section_id 0} } -form {
	{section:text,optional {label "Search Course/Section"} {html {onchange "if (this.value != '') { this.form.__refreshing_p.value = 1; } else { this.form.__refreshing_p.value = 0 ; }" size 30}}
	    {help_text "Enter a string to search course and section names"}
	    {after_html {<a href="$show_all_url" class="button">Show All</a>}}
	}
    }

    lappend validate {section
	{ ! [empty_string_p $section] }
	"[_ dotlrn-ecommerce.lt_Please_enter_a_search]"
    }
    lappend validate {section
	{ [llength $section_list] > 1 }
	"[_ dotlrn-ecommerce.lt_No_coursessections_fo]"
    }
} elseif { $section_id > 0 } {
    db_1row section {
	select c.course_name, s.section_name
	from dotlrn_ecommerce_section s, dotlrn_catalogi c
	where s.course_id = c.item_id
	and s.section_id = :section_id
	limit 1
    }

    set search_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id 0} related_user new_user_p }]
    ad_form -extend -name "participant" -export { section section_id } -form {
	{_section_name:text(inform) {label "Section"} {value "$course_name &raquo; $section_name"}
	    {after_html {<a href="$search_url" class="button">Search Section</a>}}
	}
    }

} else {
    set search_url [export_vars -base process-purchase-course { user_id participant participant_id {section ""} {section_id 0} related_user new_user_p }]
    ad_form -extend -name "participant" -export { section } -form {
	{section_id:integer(select),optional {label "Select Section"} {options {$section_list}}
	    {after_html {<a href="$search_url" class="button">Search Section</a>}}
	    {help_text {Select a section. Or, hit search again to change to a search box.}}
	}

    }

    lappend validate {section_id
	{ $section_id }
	"[_ dotlrn-ecommerce.lt_Please_select_a_secti]"
    }
    lappend validate {section_id
	{ $section_id > 0 }
	"[_ dotlrn-ecommerce.lt_Please_select_a_secti_1]"
    }
}

# Select a participant/participants
# set participant_list [linsert [db_list_of_lists participants [subst {
#     select first_names||' '||last_name||' ('||email||')', u.user_id
#     from dotlrn_users u
#     left join ec_addresses a
#     on (u.user_id = a.user_id)
#     where u.user_id != :user_id
#     and (case when :participant is null
# 	 then true
# 	 else $participant_search_clause end)
# }]] 0 {{} 0}]

# if { [llength $participant_list] == 1 } {
#     set form [rp_getform]
#     ns_set delkey $form __refreshing_p
#     ns_set put $form __refreshing_p 0
# } else

if { ! [empty_string_p $participant] } {
    # Search found users, show a more detailed list
    template::list::create \
	-name participants \
	-multirow participants \
	-key user_id \
	-page_size 50 \
	-page_flush_p 1 \
	-no_data "No users found" \
	-page_query [subst {
	    select u.user_id, u.first_names, u.last_name, u.email, a.phone, a.line1, a.line2
	    from dotlrn_users u
	    left join (select *
		       from ec_addresses
		       where address_id
		       in (select max(address_id)
			   from ec_addresses
			   group by user_id)) a
	    on (u.user_id = a.user_id)
	    where u.user_id != :user_id
	    and u.user_id != :user_id
	    and (case when :participant is null
		 then true
		 else (lower(first_names) like lower(:participant)||'%' or
		       lower(last_name) like lower(:participant)||'%' or
		       lower(email) like lower(:participant)||'%' or
		       lower(phone) like '%'||lower(:participant)||'%') end)
	}] -elements {
	    _participant_id {
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
		    @participants.line1@
		    <if @participants.line2@ not nil>
		    <br />@participants.line2@
		    </if>
		}
	    }
	    action {
		display_template {
		    <a href="@participants.add_participant_url;noquote@" class="button">Choose Participant</a>
		}
	    }
	} -filters {
	    user_id {}
	    participant {}
	    participant_id {}
	    section {}
	    section_id {}
	    purchaser_id {}
	}
    
    db_multirow -extend { add_participant_url } participants participants [subst {
	select u.user_id as _participant_id, u.first_names, u.last_name, u.email, a.phone, a.line1, a.line2
	from dotlrn_users u
	left join (select *
		   from ec_addresses
		   where address_id
		   in (select max(address_id)
		       from ec_addresses
		       group by user_id)) a
	on (u.user_id = a.user_id)
	where u.user_id != :user_id
	and (case when :participant is null
	     then true
	     else (lower(first_names) like lower(:participant)||'%' or
		   lower(last_name) like lower(:participant)||'%' or
		   lower(email) like lower(:participant)||'%' or
		   lower(phone) like '%'||lower(:participant)||'%') end)
	[template::list::page_where_clause -and -name participants -key u.user_id]
    }] {
	set add_participant_url [export_vars -base process-purchase-course { user_id { participant "" } { participant_id $_participant_id } section section_id purchaser_id page related_user new_user_p }]
    }
}

set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
set tree_options [list {}]
foreach tree [category_tree::get_tree $tree_id] {
    lappend tree_options [list [lindex $tree 1] [lindex $tree 0]]
}

if { ! $participant_id } {
#	{participant_pays_p:boolean(checkbox),optional {label ""} {options {{"Check here if $user_info(first_names) $user_info(last_name) is both purchasing and attending the course" t}}}
#	    {help_text "If you select this option, there's no need to select a user below.<br />Leave this unchecked for group purchases"}
#	}

    set locale [ad_conn locale]
    set related_user_options [linsert [db_list_of_lists related_users {
	select *
	from (
	select u.first_names||' '||u.last_name||' (participant is '||(select c.name
						      from category_object_map m, category_translations c
						      where m.category_id = c.category_id
						      and m.object_id = r.rel_id
						      and c.locale = :locale
						      limit 1)||')' as ruser, u.user_id
	from acs_rels r, dotlrn_users u
	where r.object_id_two = u.user_id
	and r.rel_type = 'patron_rel'
	and r.object_id_one = :user_id

	union

	select u.first_names||' '||u.last_name||' (purchaser is '||(select c.name
						      from category_object_map m, category_translations c
						      where m.category_id = c.category_id
						      and m.object_id = r.rel_id
						      and c.locale = :locale
						      limit 1)||')' as ruser, u.user_id
	from acs_rels r, dotlrn_users u
	where r.object_id_one = u.user_id
	and r.rel_type = 'patron_rel'
	and r.object_id_two = :user_id
	and not r.object_id_one in (select object_id_two
				    from acs_rels r
				    where rel_type = 'patron_rel'
				    and object_id_one = :user_id)
	) r
	where not ruser is null
    }] 0 [list "$user_info(first_names) $user_info(last_name) is both purchasing and attending the course" "0"]]
    lappend related_user_options [list "Purchase for GROUP of participants" -1]

    ad_form -extend -name "participant" -export { {participant_id 0} } -form {
	{-section "Individual Purchase"}
	{related_user:integer(radio),optional {label "Related Users"} {options {$related_user_options}}}
	{participant:text,optional {label "Search Participant"} {html {onchange "if (this.value != '') { this.form.__refreshing_p.value = 1; } else { this.form.__refreshing_p.value = 0 ; }" size 30}}
	    {help_text "Enter a string to search names and email addresses. <br />Or <a href=\"[export_vars -base participant-create { next_url }]\">Create an account</a> and return to this form"}
	}
	{relationship:text(select),optional {label "Relationship"}
	    {help_text "How is the purchaser related to the participant?"}
	    {options {$tree_options}}
	}
	{isubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
	{-section "Group Purchase"}
	{name:text,optional {label "Group Name"} {html {size 30}}}
	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
	{gsubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
    }

    lappend validate {name
	{ ! [empty_string_p $name] || [template::element::get_value participant related_user] != -1 }
	"[_ dotlrn-ecommerce.lt_Please_enter_a_name_f]"
    } {num_members
	{ ! [empty_string_p $num_members] || [template::element::get_value participant related_user] != -1 }
	"[_ dotlrn-ecommerce.lt_Please_enter_the_numb]"
    }

#     lappend validate {participant
# 	{ ! [empty_string_p $participant] || [template::element::get_value participant related_user] != -1 ||
# 	    (![empty_string_p [template::element::get_value participant name]] && 
# 	     ![empty_string_p [template::element::get_value participant num_members]]) }
# 	"Please enter a search string"
#     }
#     lappend validate {participant
# 	{ [llength $participant_list] > 1 || [template::element::get_value participant participant_pays_p] == "t" ||
# 	    (![empty_string_p [template::element::get_value participant name]] && 
# 	     ![empty_string_p [template::element::get_value participant num_members]]) }
# 	"No users found. Please try again"
#     }
} elseif { $participant_id } {
    acs_user::get -user_id $participant_id -array participant_user

    set search_url [export_vars -base process-purchase-course { user_id {participant ""} {participant_id 0} section section_id { related_user 0 } new_user_p }]
#	{participant_pays_p:boolean(checkbox),optional {label ""} {options {{"Check here if $user_info(first_names) $user_info(last_name) is both purchasing and attending the course" t}}}}
    ad_form -extend -name "participant" -export { participant participant_id { related_user $participant_id } } -form {
	{-section "Individual Purchase"}
	{participant_name:text(inform) {label "Participant"} {value "$participant_user(first_names) $participant_user(last_name) ($participant_user(email))"}
	    {after_html {<a href="$search_url" class="button">Search Participant</a>}}
	}
	{relationship:text(select),optional {label "Relationship"}
	    {help_text "How is the purchaser related to the participant?"}
	    {options {$tree_options}}
	}
	{isubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
	{-section "Group Purchase"}
	{name:text,optional {label "Group Name"} {html {size 30}}}
	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
	{gsubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
    }

}
#  else {
#     set search_url [export_vars -base process-purchase-course { user_id {participant ""} {participant_id 0} section section_id }]
#     ad_form -extend -name "participant" -export { participant } -form {
# 	{-section "Individual Purchase"}
# 	{participant_pays_p:boolean(checkbox),optional {label ""} {options {{"Check here if $user_info(first_names) $user_info(last_name) is both purchasing and attending the course" t}}}}
# 	{participant_id:integer(select),optional {label "Select Participant"} {options {$participant_list}}
# 	    {help_text "Select a participant from the list. Can't find the participant?<br /><a href=\"[export_vars -base participant-create { next_url }]\">Create an account</a> and return to this form"}
# 	    {after_html {<a href="$search_url" class="button">Search Participant</a>}}
# 	}
# 	{relationship:text(select),optional {label "Relationship"}
# 	    {help_text "How is the purchaser related to the participant?"}
# 	    {options {$tree_options}}
# 	}
# 	{-section "Group Purchase"}
# 	{name:text,optional {label "Group Name"} {html {size 30}}}
# 	{num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
#     }

#     lappend validate {participant_id
# 	{ $participant_id || [template::element::get_value participant participant_pays_p] == "t" }
# 	"Please select a participant from the list"
#     }
# }

set maxparticipants [dotlrn_ecommerce::section::maxparticipants $section_id]
set available_slots [dotlrn_ecommerce::section::available_slots $section_id]

if { [empty_string_p $maxparticipants] } {
    lappend validate \
	{num_members
	    {$num_members > 1 || [empty_string_p $num_members] || [template::element::get_value participant related_user] != -1}
	    "[_ dotlrn-ecommerce.lt_Please_enter_a_value_]"
	}
} else {
    # it is now allowed to register users even if the course is full,
    # they just go to the waiting list

    # for groups, just inform the user that the group members will go
    # to the waiting list
    # DISABLED FOR NOW - groups can't go to the waiting list
#    if { ! $waiting_list_p } {
	lappend validate \
	    {num_members
		{ $num_members > 1 || [template::element::get_value participant related_user] != -1 }
		"[_ dotlrn-ecommerce.lt_Please_enter_a_value_]"
	    } {num_members
		{ $num_members <= $available_slots || [empty_string_p $num_members] || [template::element::get_value participant related_user] != -1}
		"[subst [_ dotlrn-ecommerce.lt_The_course_only_has_a]]"
	    }
#	if { [template::element::get_value participant related_user] == -1 && [string is integer [template::element::get_value participant num_members]] && [template::element::get_value participant num_members] > 1 && [template::element::get_value participant num_members] > $available_slots } {
#	    template::element::set_value participant waiting_list_p 1
#	} else {
#	    template::element::set_value participant waiting_list_p 0
#	}
#    } elseif { [template::element::get_value participant related_user] != -1 } {
#	template::element::set_value participant waiting_list_p 0
#    }
}

set return_url [ad_return_url]
ad_form -extend -name "participant" -export { user_id return_url new_user_p } -validate $validate -form {
} -on_request {
    set related_user 0
} -on_submit {
    if { $related_user > 0 } {
	set participant_id $related_user
    }

    if { ! [empty_string_p $relationship] && $related_user != 0 && ([empty_string_p $name] || [empty_string_p $num_members]) } {
	set rel_id [relation::get_id -object_id_one $user_id -object_id_two $participant_id -rel_type "patron_rel"]
	
	if { [empty_string_p $rel_id] } {
	    # Create patron relationship
	    # Roel 06/15: Reversed users since we select purchasers
	    # first now
	    set rel_id [db_exec_plsql relate_patron {
		select acs_rel__new (null,
				     'patron_rel',
				     :user_id,
				     :participant_id,
				     null,
				     null,
				     null)
	    }]
	}

	category::map_object -remove_old -object_id $rel_id [list $relationship]
    }

    db_1row product {
	select product_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    set item_count 1
    if { $related_user == -1 && ! [empty_string_p $name] && ! [empty_string_p $num_members] } {
	set group_id [db_nextval acs_object_id_seq]
	set unique_group_name "${name}_${group_id}"

	# Test once then give up
	if { [db_string group {select 1 from groups where group_name = :unique_group_name} -default 0] } {
	    set group_id [db_nextval acs_object_id_seq]
	    set unique_group_name "${name}_${group_id}"
	}

	group::new -group_id $group_id -group_name $unique_group_name
	set section_community_id [db_string get_community_id "select community_id from dotlrn_ecommerce_section where section_id=:section_id" -default ""]
	if {[string equal "" $section_community_id]} {
	    # FIXME error, do something clever here
	}
	for { set i 1 } { $i <= $num_members } { incr i } {
	    array set new_user [auth::create_user \
				    -username "${name} ${group_id} Attendee $i" \
				    -email "[util_text_to_url -text ${name}-${group_id}-attendee-${i}]@mos.zill.net" \
				    -first_names "$name" \
				    -last_name "Attendee $i" \
				    -nologin]
	    
	    if { [info exists new_user(user_id)] } {
		relation_add -member_state approved membership_rel $group_id $new_user(user_id)
	    } else {
		ad_return_complaint 1 "There was a problem creating the account \"$name $group_id Attendee $i\"."
		ad_script_abort
	    }
	}
	relation_add relationship $group_id $section_community_id

	set participant_id $group_id
	set item_count $num_members

	ad_returnredirect [export_vars -base "../ecommerce/prerequisite-confirm" { product_id user_id participant_id item_count return_url }]
	ad_script_abort
    }
    
    set add_url [export_vars -base "../ecommerce/prerequisite-confirm" { product_id user_id participant_id item_count return_url }]
    set participant_id [ad_decode $participant_id 0 $user_id $participant_id]

    if { $new_user_p } {
	ad_returnredirect $add_url
    } else {
	ad_returnredirect [export_vars -base "participant-add" { {user_id $participant_id} section_id return_url add_url }]
    }

    ad_script_abort
}

if { ! [empty_string_p $participant] } {
    template::element::set_value participant related_user -1
}

# Set relationship if appropriate
if { [exists_and_not_null rel_id] } {
    # This can be a bit tricky since we handle reverse relationships
    # poorly, for now, assume that the admin chooses the proper
    # relationships for both participant and purchaser, e.g. When A is
    # purchaser and B is participant, admin chooses 'Mother'; when B
    # is purchaser and A is participant, admin chooses 'Daughter'
    set relationship [db_string relationship {
	select category_id
	from category_object_map
	where object_id = :rel_id
	limit 1
    } -default 0]

    template::element::set_value participant relationship $relationship
}
