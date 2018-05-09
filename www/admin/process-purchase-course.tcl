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
    {section_id "-1"}

    {page 1}

    {__refreshing_p 0}

    {related_user 0}
    {new_user_p 0}

    {waiting_list_p 0}
} -properties {
} -validate {
} -errors {
}



# Proc to be used in form validation
proc already_registered_p { section_id purchaser_id participant_id } {
    if { [empty_string_p $section_id] } {
	return 0
    }
    
    if { [db_0or1row community {
	select community_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }] } {

	set user_id [ad_decode $participant_id 0 $purchaser_id $participant_id]
	
	# if they are in approved state, then let the registration pass 
	return [db_string registered {
	    select count(*)
	    from dotlrn_member_rels_full
	    where community_id = :community_id
	    and user_id = :user_id
	    and member_state not in ('request approved', 'waitinglist approved')
	}]
    }

    return 0
}

if { $related_user > 0 } {
    set participant_id $related_user
    set participant ""
    
    set rel_id [relation::get_id -object_id_one $user_id -object_id_two $participant_id -rel_type "patron_rel"]
}

acs_user::get -user_id $user_id -array user_info

set title "Choose Participant"

set next_url [export_vars -base process-purchase-course { {purchaser_id $user_id} participant participant_id section section_id related_user {new_user_p 1} }]

dotlrn_ecommerce::check_user -user_id $user_id

if { $participant_id } {
    dotlrn_ecommerce::check_user -user_id $participant_id
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
	    {after_html {<!-- <a href="$search_url" class="button">Search Section</a> -->}}
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

set locale [ad_conn locale]
set related_user_options [linsert [db_list_of_lists related_users {
    select *
    from (
	  select u.first_names||' '||u.last_name||' (purchaser is '||(select c.name
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

	  select u.first_names||' '||u.last_name||' (participant is '||(select c.name
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
lappend related_user_options [list "Another Participant" -2]

ad_form -extend -name "participant" -export { {participant_id 0} } -form {
    {-section "Choose Participant"}
    {related_user:integer(radio),optional {label "Related Users"} {options {$related_user_options}}}
    {isubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
}

set return_url [ad_return_url]

# Don't allow duplicate registration
lappend validate {related_user
    { ! [already_registered_p [template::element::get_value participant section_id] $user_id $related_user] || $related_user < 0 }
    "[_ dotlrn-ecommerce.lt_User_is_already_regis]"
}

ad_form -extend -name "participant" -export { user_id return_url new_user_p } -validate $validate -form {
} -on_request {
    set related_user 0
} -on_submit {
    if { $related_user > 0 } {
	set participant_id $related_user
    }

    db_1row product {
	select product_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    if { $related_user == -1 } {
	ad_returnredirect [export_vars -base "process-purchase-group" { section_id user_id return_url return_url }]
	ad_script_abort
    } elseif { $related_user == -2 } {
	ad_returnredirect [export_vars -base "process-purchase" { section_id user_id return_url return_url }]
	ad_script_abort	
    }
    
    set add_url [export_vars -base "../ecommerce/shopping-cart-add" { product_id user_id participant_id return_url }]
    set participant_id [ad_decode $participant_id 0 $user_id $participant_id]

    if { $new_user_p } {
	ad_returnredirect $add_url
    } else {
	ad_returnredirect [export_vars -base "../ecommerce/participant-add" { {user_id $participant_id} section_id return_url add_url }]
    }

    ad_script_abort
}
