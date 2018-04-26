# Expects parameters:
#
# self_register_p - Is the form for users who self register (1) or
#                   for administrators who create other users (0)?
# next_url        - Any url to redirect to after the form has been submitted. The
#                   variables user_id, password, and account_messages will be added to the URL. Optional.
# email           - Prepopulate the register form with given email. Optional.
# return_url      - URL to redirect to after creation, will not get any query vars added
# rel_group_id    - The name of a group which you want to relate this user to after creating the user.
#                   Will add an element to the form where the user can pick a relation among the permissible 
#                   rel-types for the group.

# Check if user can self register
auth::self_registration

# Set default parameter values
# user_type - participant or purchaser for now
array set parameter_defaults {
    self_register_p 1
    next_url {}
    return_url {}
    user_type participant
}
foreach parameter [array names parameter_defaults] { 
    if { ![exists_and_not_null $parameter] } { 
        set $parameter $parameter_defaults($parameter)
    }
}

# Redirect to HTTPS if so configured
if { [security::RestrictLoginToSSLP] } {
    security::require_secure_conn
}

# Log user out if currently logged in, if specified in the includeable chunk's parameters, 
# e.g. not when creating accounts for other users
if { $self_register_p } {
    ad_user_logout 
}

set implName [parameter::get -parameter "RegistrationImplName" -package_id [subsite::main_site_id]]

set url [callback -catch -impl "$implName" user::registration]

if { ![empty_string_p $url] } {
    ad_returnredirect [export_vars -base $url { return_url }]
    ad_script_abort
}

# Pre-generate user_id for double-click protection
set user_id [db_nextval acs_object_id_seq]

set form [auth::get_registration_form_elements]
# Roel - remove password, url fields improve this
set form [lrange $form 0 3]
set formlen [llength $form]

set allow_no_email_p [parameter::get -parameter AllowNoEmailForPurchaser]
set validate {}

# if { $user_type == "purchaser" && $allow_no_email_p } { }
if { $allow_no_email_p } {
    for { set i 0 } { $i < $formlen } { incr i } {
	set field [lindex $form $i]
	if { [lindex $field 0] == "email:text(text)" } {
	    set field [lreplace $field 0 0 "email:text(text),optional"]
	    set form [lreplace $form $i $i $field]
	}
    }

    set form [linsert $form 1 {no_email_p:integer(checkbox),optional
	{label ""}
	{options {{"[_ dotlrn-ecommerce.User_has_no_email]" 1}}}
	{html {onchange "this.form.email.disabled = ! this.form.email.disabled;"}}
    }]
    
    lappend validate {email
	{ ![empty_string_p $email] || [template::element::get_value register no_email_p] == 1 }
	"[_ dotlrn-ecommerce.Email_is_required]"
    }
}

ad_form -name register -export {next_url user_id return_url {password ""} {password_confirm ""} {screen_name ""} {url ""} {secret_question ""} {secret_answer ""} } -form $form

if { [exists_and_not_null rel_group_id] } {
    ad_form -extend -name register -form {
        {rel_group_id:integer(hidden),optional}
    }

    if { [permission::permission_p -object_id $rel_group_id -privilege "admin"] } {
        ad_form -extend -name register -form {
            {rel_type:text(select)
                {label "[_ dotlrn-ecommerce.Role]"}
                {options {[group::get_rel_types_options -group_id $rel_group_id]}}
            }
        }
    } else {
        ad_form -extend -name register -form {
            {rel_type:text(hidden)
                {value "membership_rel"}
            }
        }
    }
}

# Roel: Extra info for students
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
		
		ad_form -extend -name register -form {
		    {grade:text(select),optional
			{label "[_ dotlrn-ecommerce.Grade]"}
			{options {$grade_options} }
		    }
		}
	    }

	    allergies {
		ad_form -extend -name register -form {
		    {allergies:text,optional
			{label "[_ dotlrn-ecommerce.Medical_Issues]"}
			{html {size 60}}
		    }
		}
	    }

	    special_needs {
		ad_form -extend -name register -form {
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
	    ad_form -extend -name register -form [subst {
		{$field:text(hidden) {value ""}}
	    }]
	}
    }

} else {
    ad_form -extend -name register -form {
	{grade:text(hidden) {value ""}}
	{allergies:text(hidden) {value ""}}
	{special_needs:text(hidden) {value ""}}
    }
}

switch $user_type {
    participant {
	ad_form -extend -name register -form {
	    {add:text(submit) {label "[_ dotlrn-ecommerce.Add_Participant]"}}
	}
    }
    purchaser {
	ad_form -extend -name register -form {
	    {add:text(submit) {label "[_ dotlrn-ecommerce.Add_Purchaser]"}}
	}
    }
}

ad_form -extend -name register -validate $validate -on_request {
    # Populate elements from local variables

    if { $user_type == "participant" } {
	# Try to default to Adult, this may not exist
	set locale [ad_conn locale]
	db_0or1row default_grade {		
	    select c.category_id as grade	
	    from category_translations t, categories c
	    where t.category_id = c.category_id 
	    and t.name = 'Adult'
	    and t.locale = :locale
	    and c.tree_id = :tree_id
	}
    }
} -on_submit {

    db_transaction {
	if { [empty_string_p $email] } {
	    # Generate an email address
	    set domain [parameter::get -parameter DefaultEmailDomain]
	    set email "noemail-[util_text_to_url "$first_names $last_name"]-$user_id@$domain"
	}

        array set creation_info [auth::create_user \
                                     -user_id $user_id \
                                     -verify_password_confirm \
                                     -username $username \
                                     -email $email \
                                     -first_names $first_names \
                                     -last_name $last_name \
                                     -screen_name $screen_name \
                                     -password $password \
                                     -password_confirm $password_confirm \
                                     -url $url \
                                     -secret_question $secret_question \
                                     -secret_answer $secret_answer]
     
        if { [string equal $creation_info(creation_status) "ok"] } {
	    if { [exists_and_not_null rel_group_id] } {
		group::add_member \
		    -group_id $rel_group_id \
		    -user_id $user_id \
		    -rel_type $rel_type
	    }

	    set created_user_id $creation_info(user_id)
	    db_dml insert_extra_info {
		insert into person_info (person_id, allergies, special_needs)
		values (:created_user_id, :allergies, :special_needs)
	    }

	    category::map_object -remove_old -object_id $user_id [list $grade]
        }
    }

    # Handle registration problems
    
    switch $creation_info(creation_status) {
        ok {
            # Continue below
        }
        default {
            # Adding the error to the first element, but only if there are no element messages
            if { [llength $creation_info(element_messages)] == 0 } {
                array set reg_elms [auth::get_registration_elements]
                set first_elm [lindex [concat $reg_elms(required) $reg_elms(optional)] 0]
                form set_error register $first_elm $creation_info(creation_message)
            }
                
            # Element messages
            foreach { elm_name elm_error } $creation_info(element_messages) {
                form set_error register $elm_name $elm_error
            }
            break
        }
    }

    switch $creation_info(account_status) {
        ok {
            # Continue below
        }
        default {
            # Display the message on a separate page
            ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-closed" { { message $creation_info(account_message) } }]
            ad_script_abort
        }
    }

    dotlrn_ecommerce::check_user -user_id $user_id

} -after_submit {

    if { ![empty_string_p $next_url] } {
        # Add user_id and account_message to the URL
	ad_returnredirect [export_vars -base $next_url {user_id password {account_message $creation_info(account_message)}}]
        ad_script_abort
    } 


    # User is registered and logged in
    if { ![exists_and_not_null return_url] } {
        # Redirect to subsite home page.
        set return_url [subsite::get_element -element url]
    }

    # If the user is self registering, then try to set the preferred
    # locale (assuming the user has set it as a anonymous visitor
    # before registering).
    if { $self_register_p } {
	# We need to explicitly get the cookie and not use
	# lang::user::locale, as we are now a registered user,
	# but one without a valid locale setting.
	set locale [ad_get_cookie "ad_locale"]
	if { ![empty_string_p $locale] } {
	    lang::user::set_locale $locale
	    ad_set_cookie -replace t -max_age 0 "ad_locale" ""
	}
    }

    # Handle account_message
    if { ![empty_string_p $creation_info(account_message)] && $self_register_p } {
        # Only do this if user is self-registering
        # as opposed to creating an account for someone else
        ad_returnredirect [export_vars -base "[subsite::get_element -element url]register/account-message" { { message $creation_info(account_message) } return_url }]
        ad_script_abort
    } else {
        # No messages
        ad_returnredirect $return_url
        ad_script_abort
    }
}
