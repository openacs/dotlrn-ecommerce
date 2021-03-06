if { ![exists_and_not_null user_type] } {
    set user_type participant
}

if { ! [empty_string_p $cancel] } {
    ad_returnredirect $return_url
    ad_script_abort
}

auth::require_login -account_status closed

if { ![exists_and_not_null user_id] } {
    set user_id [ad_conn untrusted_user_id]
} elseif { $user_id != [auth::get_user_id -account_status closed] } {
# Don't check for permissions since ordinary users can edit other
# people's profiles
#    permission::require_permission -object_id $user_id -privilege admin
}

if { ![exists_and_not_null return_url] } {
    set return_url [ad_conn url]
}


set action_url "[subsite::get_element -element url]user/basic-info-update"

acs_user::get -user_id $user_id -array user

set authority_name [auth::authority::get_element -authority_id $user(authority_id) -element pretty_name]

set form_elms { authority_id username first_names last_name email bio }
foreach elm $form_elms {
    set elm_mode($elm) {}
}
set read_only_elements [auth::sync::get_sync_elements -authority_id $user(authority_id)]
set read_only_notice_p [expr [llength $read_only_elements] > 0]
if { ![acs_user::site_wide_admin_p] } {
    lappend read_only_elements authority_id username
}
foreach elm $read_only_elements {
    set elm_mode($elm) {display}
}
set first_element {}
foreach elm $form_elms {
    if { [empty_string_p $elm_mode($elm)] && (![string equal $elm "username"] && [auth::UseEmailForLoginP]) } {
        set first_element $elm
        break
    }
}
set focus "user_info.$first_element"
set edit_mode_p [expr ![empty_string_p [form::get_action user_info]]]

set form_mode display
if {[info exists edit_p] && $edit_p == 1} {
    set form_mode edit
}

ad_form -name user_info -cancel_url $return_url -mode $form_mode -form {
    {user_id:integer(hidden),optional}
    {return_url:text(hidden),optional}
    {message:text(hidden),optional}
}

if { [llength [auth::authority::get_authority_options]] > 1 } {
    ad_form -extend -name user_info -form {
        {authority_id:text(select)
            {mode $elm_mode(authority_id)}
            {label "[_ acs-subsite.Authority]"}
            {options {[auth::authority::get_authority_options]}}
        }
    }
}
if { $user(authority_id) != [auth::authority::local] || ![auth::UseEmailForLoginP] || \
     ([acs_user::site_wide_admin_p] && [llength [auth::authority::get_authority_options]] > 1) } {
    ad_form -extend -name user_info -form {
        {username:text(text)
            {label "[_ acs-subsite.Username]"}
            {mode $elm_mode(username)}
        }
    }
}

# TODO: Use get_registration_form_elements, or auto-generate the form somehow? Deferred.


ad_form -extend -name user_info -form {
    {first_names:text
        {label "[_ acs-subsite.First_names]"}
        {html {size 50}}
        {mode $elm_mode(first_names)}
    }
    {last_name:text
        {label "[_ acs-subsite.Last_name]"}
        {html {size 50}}
        {mode $elm_mode(last_name)}
    }
    {email:text
        {label "[_ acs-subsite.Email]"}
        {html {size 50}}
        {mode $elm_mode(email)}
    }
}

if {[apm_package_enabled_p "categories"]} {
    set main_site_id [subsite::main_site_id]
    if {![empty_string_p [category_tree::get_mapped_trees $main_site_id]]} {
	category::ad_form::add_widgets -container_object_id $main_site_id -categorized_object_id $user_id -form_name user_info
    }
}

# if { ![string equal [acs_user::ScreenName] "none"] } {
#     ad_form -extend -name user_info -form \
#         [list \
#              [list screen_name:text[ad_decode [acs_user::ScreenName] "solicit" ",optional" ""] \
#                   {label "[_ acs-subsite.Screen_name]"} \
#                   {html {size 50}} \
#                   {mode $elm_mode(screen_name)} \
#                  ]]
# }

ad_form -extend -name user_info  -export { section_id add_url } -form {
    {bio:text(textarea),optional
        {label "[_ acs-subsite.About_You]"}
        {html {rows 8 cols 60}}
        {mode $elm_mode(bio)}
        {display_value {[ad_text_to_html -- $user(bio)]}}
    }
}

if { $user_type == "participant" } {
    set tree_id [parameter::get -package_id [ad_conn package_id] -parameter GradeCategoryTree -default 0]
    set custom_fields [parameter::get -package_id [ad_conn package_id] -parameter CustomParticipantFields -default ""]

    foreach field $custom_fields {

	switch [string tolower $field] {
	    grade {
		set grade_options [list {"--" ""}]
		foreach tree [category_tree::get_tree $tree_id] {
		    lappend grade_options [list [lindex $tree 1] [lindex $tree 0]]
		}
		
		ad_form -extend -name user_info -form {
		    {grade:text(select),optional
			{label "[_ dotlrn-ecommerce.Grade]"}
			{options {$grade_options} }
		    }
		}
	    }

	    allergies {
		ad_form -extend -name user_info -form {
		    {allergies:text,optional
			{label "[_ dotlrn-ecommerce.Medical_Issues]"}
			{html {size 60}}
		    }
		}
	    }

	    special_needs {
		ad_form -extend -name user_info -form {
		    {special_needs:text,optional
			{label "[_ dotlrn-ecommerce.Special_Needs]"}
			{html {size 60}}
		    }
		}
	    }
	}
    }
    
    foreach field {grade allergies special_needs} {
	if { [lsearch $custom_fields $field] == -1 } {
	    ad_form -extend -name user_info -form [subst {
		{$field:text(hidden) {value ""}}
	    }]
	}
    }

} else {
    ad_form -extend -name user_info -form {
	{grade:text(hidden) {value ""}}
	{allergies:text(hidden) {value ""}}
	{special_needs:text(hidden) {value ""}}
    }
}
    
if {[info exists edit_p] && $edit_p == 1} {
    ad_form -extend -name user_info -form {
	{add:text(submit) {label "[_ dotlrn-ecommerce.Proceed]"}}
	{cancel:text(submit) {label "[_ dotlrn-ecommerce.Cancel]"}}
    }
}

ad_form -extend -name user_info -form {} -on_request {
    foreach var { authority_id first_names last_name email username bio } {
        set $var $user($var)
    }
    db_0or1row person_info {
	select allergies, special_needs
	from person_info
	where person_id = :user_id
	limit 1
    }
    set grade [lindex [category::get_mapped_categories $user_id] 0]
} -on_submit {
    set user_info(authority_id) $user(authority_id)
    set user_info(username) $user(username)
    foreach elm $form_elms {
        if { [empty_string_p $elm_mode($elm)] && [info exists $elm] } {
            set user_info($elm) [string trim [set $elm]]
        }
    }

    array set result [auth::update_local_account \
                          -authority_id $user(authority_id) \
                          -username $user(username) \
                          -array user_info]


    # Handle authentication problems
    switch $result(update_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $result(element_messages)] == 0 } {
                form set_error user_info $first_element $result(update_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $result(element_messages) {
                form set_error user_info $elm_name $elm_error
            }
            break
        }
    }

    if {[apm_package_enabled_p "categories"]} {
	category::map_object -object_id $user_id [category::ad_form::get_categories -container_object_id $main_site_id]
    }

    # Roel: Extra info for students
    if { [db_0or1row person_info {
	select 1
	from person_info
	where person_id = :user_id
	limit 1
    }] } {
	db_dml update_extra_info {
	    update person_info
	    set allergies = :allergies,
	    special_needs = :special_needs
	    where person_id = :user_id
	}
    } else {
	db_dml insert_extra_info {
	    insert into person_info (person_id, allergies, special_needs)
	    values (:user_id, :allergies, :special_needs)
	}
    }
    category::map_object -remove_old -object_id $user_id [list $grade]

    dotlrn_ecommerce::check_user -user_id $user_id
} -after_submit {
    if { [string equal [ad_conn account_status] "closed"] } {
        auth::verify_account_status
    }
    
    ad_returnredirect $add_url
    ad_script_abort
}

# LARS HACK: Make the URL and email elements real links
if { ![form is_valid user_info] } {
    element set_properties user_info email -display_value "<a href=\"mailto:[element get_value user_info email]\">[element get_value user_info email]</a>"
#     if {![string match -nocase "http://*" [element get_value user_info url]]} {
# 	element set_properties user_info url -display_value \
# 		"<a href=\"http://[element get_value user_info url]\">[element get_value user_info url]</a>"
#     } else {
# 	element set_properties user_info url -display_value \
# 		"<a href=\"[element get_value user_info url]\">[element get_value user_info url]</a>"
#     }
}
