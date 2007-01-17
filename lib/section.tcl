# expected vars
# section_id, course_id

# optional 
# mode
# return_url
# has_edit

proc dotlrn_ecommerce_check_grade { section_id categories } {
    set grade_tree_id [parameter::get -parameter GradeCategoryTree -default 0]

    if { $grade_tree_id } {
	if { [db_0or1row community {
	    select community_id
	    from dotlrn_ecommerce_section
	    where section_id = :section_id
	}] } {
	    if { $categories == [list [list $community_id [ad_conn package_id]]] } {
		set categories ""
	    }
	}

	lappend categories 0
	
	return [db_string selected_grades [subst {
	    select count(*)
	    from categories
	    where tree_id = :grade_tree_id
	    and category_id in ([join $categories ,])
	}] -default 0]
    }

    return 1
}

if {![info exists has_edit]} {
    set has_edit 0
}

dotlrn_catalog::get_course_data -course_id $course_id
#set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]

set package_id [ad_conn package_id]
set validate [list]
set show_price_option_p [dotlrn_ecommerce::util::param::get -default 1 ShowPriceOptionP]

catch {
    db_1row template_community {
	select community_id as template_community_id
	from dotlrn_catalogi
	where course_id = :course_id
    }
    set template_calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $template_community_id]
    set template_item_type_id [db_string get_item_type_id_template { } -default 0]
}
	
if {![info exists mode]} {
    set mode edit
}


ad_form -name add_section -mode $mode  -has_edit $has_edit -form {
    section_id:key
    {product_id:integer(hidden)}
    {return_url:text(hidden) {value $return_url}}
    {course_id:text(hidden) {value $course_id}}
}

if { [ad_form_new_p -key section_id] } {
    ad_form -extend -name add_section -form {
	{section_key:text {label "Section Key"}
	    {help_text "Short name used in URL"}
	}
    }
    
    lappend validate {section_key
	{ [dotlrn_community::check_community_key_valid_p -community_key $section_key] }
	"The section '$section_key' key already exists"
    }

    if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
	# Try to default to Adult, this may not exist
	# Roel: Right now I'm doing this using javascript, doesn't seem to
	# be a way to set the value of a category widget
	set grade_tree_id [parameter::get -parameter GradeCategoryTree -default 0]
	
	if { $grade_tree_id } {
		set locale [ad_conn locale]
		db_0or1row default_grade {
			select c.category_id as adult_category_id
			from category_translations t, categories c
			where t.category_id = c.category_id 
			and t.name = 'Adult'
			and t.locale = :locale
			and c.tree_id = :grade_tree_id
		}
	}
     }

} else {
    ad_form -extend -name add_section -form {
	{section_key:text(inform) {label "Section Key"}}
    }
    
    # HAM :
    # Flush the section info from cache
    # we use to do it after edit, but 
    # i think we need to do this everytime we visit this page
    dotlrn_ecommerce::section::flush_cache $section_id
}

if { [parameter::get -parameter AllowFreeRegistration -default 0] } {
    ad_form -extend -name add_section -form {
	{section_name:text {label "Section Code"} {help_text {E.g. Section 01, W06}}}
	{price:currency,to_sql(sql_number) {label "Regular Price"} {html {size 6}}
	    {help_text {Enter any fees related to this course here. \$0 in this field means there is no related fee.}}
	}
    }
} else {
    ad_form -extend -name add_section -form {
	{section_name:text {label "Section Code"} {help_text {E.g. Section 01, W06}}}
	{price:currency,to_sql(sql_number) {label "Regular Price"} {html {size 6}}
	    {help_text "Enter any fees related to this course here."}
	}	
    }
}

if { $show_price_option_p } {
    ad_form -extend -name add_section -form {
	{show_price_p:text(radio) {label "Show Price Information"} {options {{Yes t} {No f}}}}
    }
}

# HAM : Let's check if we have MemberPriceP enabled and set
# if it is, let's add Member Price text
if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] &&
     ! [parameter::get -parameter AllowFreeRegistration -default 0]
 } {
	ad_form -extend -name add_section -form {
		{ member_price:currency,to_sql(sql_number) {label "Member Price"} {html {size 6}} }
	}

    lappend validate {member_price
	{ ![template::util::negative [template::util::currency::get_property whole_part $member_price]] }
	"Member price can not be negative"
    } {member_price 
	{ !"[template::util::currency::get_property whole_part $member_price].[template::util::currency::get_property fractional_part $member_price]" == "0.00" }
	"Member price can not be zero"
    }
}

# HAM : Let's get the community id's for both Instructors and Assistants

set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]
set assistant_community_id [parameter::get -package_id [ad_conn package_id] -parameter AssistantCommunityId -default 0 ]


# HAM : Let's check if we have InstructorCommunityId enabled and set
if { $instructor_community_id == 0 && ![db_0or1row "checkinstructorcommunity" "select community_id from dotlrn_communities where community_id = :instructor_community_id"] } {
	ad_return_complaint 1 "Parameter InstructorCommunityId is not set or Community Id does not exist."
} else {
	# community_id is valid
	# list users
	set _instructors [dotlrn_community::list_users  $instructor_community_id]
	set instructors_list [list]
	foreach instructor $_instructors {
	    set instructor_user_id [ns_set get $instructor user_id]
	    set instructor_name "[ns_set get $instructor first_names] [ns_set get $instructor last_name]"
	    lappend instructors_list [list $instructor_name $instructor_user_id ]
	}
	set instructors_list [lsort -index 0 -dictionary $instructors_list]

	ad_form -extend -name add_section -form {
		{ instructors:string(multiselect),multiple,optional {label "#dotlrn-ecommerce.Instructor#"} {options { $instructors_list } }	}
	}
}

# HAM : Let's check if we have AssistantCommunityId enabled and set
if { $assistant_community_id == 0 && ![db_0or1row "checkassistantcommunity" "select community_id from dotlrn_communities where community_id = :assistant_community_id"] } {
	ad_return_complaint 1 "Parameter AssistantCommunityId is not set or Community Id does not exist."
} else {
	# community_id is valid
	set _assistants [dotlrn_community::list_users  $assistant_community_id]
	set assistants_list [list]
	foreach assistant $_assistants {
		set assistant_user_id [ns_set get $assistant user_id]
		set assistant_name "[ns_set get $assistant first_names] [ns_set get $assistant last_name]"
		lappend assistants_list [list $assistant_name $assistant_user_id ]
	}
	set assistants_list [lsort -index 0 -dictionary $assistants_list]
	
	ad_form -extend -name add_section -form {
		{ assistants:string(multiselect),multiple,optional {label "#dotlrn-ecommerce.assistant_instructor#"} {options { $assistants_list } }	}
	}

}


if { ! [ad_form_new_p -key section_id] } {

	db_1row community {
		select community_id
		from dotlrn_ecommerce_section
		where section_id = :section_id
	}

	if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {	
		ad_form -extend -name add_section -form {
			{categories:text(category),multiple,optional
			{label "Categories"}
			{html {size 4}}
			{value "$community_id $package_id"}
			}
		}
	}

} else {
	if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
		ad_form -extend -name add_section -form {
			{categories:text(category),multiple,optional
			{label "Categories"}
			{html {size 4}}
			}
		}
	}
}


set tree_options [list]
if { [parameter::get -package_id [ad_conn package_id] -parameter GradePrerequisitesP -default 1 ] } {
	db_foreach prerequisites {
	select tree_id
	from dotlrn_ecommerce_prereq_map
	} {
	lappend tree_options [list [category_tree::get_name $tree_id] $tree_id]
	}
	
	if { [llength $tree_options] > 0 } {
	ad_form -extend -name add_section -form {
		{prerequisites:integer(checkbox),multiple,optional {label "Check Prerequisites"}
		{options {$tree_options}}
		}
	}
	}
}

# TICKET #159 section_description
ad_form -extend -name add_section -form {
	{description:text(textarea),optional
	    {label "Description"}
	    {html {cols 25 rows 10}}
	}
}

# ecommerce stuff

set exclude_list [list "'classid'"]

db_foreach custom_fields_select "
    select field_identifier,
           field_name,
           default_value,
           column_type
    from ec_custom_product_fields
    where active_p='t'
          and field_identifier not in ([join $exclude_list ", "])
    order by creation_date" {
    # date
    if {[string equal $column_type date] || [string equal $column_type timestamp]} {
        if {[string equal $field_identifier enddate]} {
            ad_form -extend -name add_section -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value} {help_text "Not required for Distance Learning Courses"}]]
	} else {
	    ad_form -extend -name add_section -form [list \
							 [list "${field_identifier}:date,optional" {label $field_name} {value $default_value}] \
							]
	}
    } elseif {[string equal $column_type integer] || [string equal $column_type number]} {
	if { $field_identifier == "maxparticipants" } {
		ad_form -extend -name add_section -form [list [list "${field_identifier}:float" {label $field_name} {value $default_value} {html {size 5}}] ]
	} else {
		ad_form -extend -name add_section -form [list [list "${field_identifier}:float,optional" {label $field_name} {value $default_value} {html {size 5}}] ]
	}
    } elseif {[string equal $column_type "varchar(200)"]} {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(text),optional" {label $field_name} {value $default_value} {html {size 50 maxlength 200}}] \
						    ]
    } elseif {[string equal $column_type "varchar(4000)"]} {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(textarea),optional" {label $field_name} {value $default_value} {html {rows 4 cols 60}}] \
						    ]
    } else {
	ad_form -extend -name add_section -form [list \
						     [list "${field_identifier}:text(radio),optional" {label $field_name} {value $default_value} {options {{Yes t} {No f}}}] \
						    ]
    }

    # maxparticipants is a special field, it is created on install
    # maxparticipants is a required field and can not be 0 or less than 0
    if { $field_identifier == "maxparticipants" } {
	lappend validate {maxparticipants
	    { $maxparticipants > 0 || [empty_string_p $maxparticipants] }
	    "Please enter a value greater than 0"
	}
    }
}

# DEDS: waiting list notify
ad_form -extend -name add_section -form {
    {notify_waiting_number:text,optional {label "Notify admin when waiting list reaches:"} {html {size 5 maxlength 3}}}
    {show_participants_p:text(radio) {label "Show Number of Participants"} {options {{Yes t} {No f}}}}
    {show_sessions_p:text(radio) {label "Show Sessions Information"} {options {{Yes t} {No f}}}}
}
lappend validate {notify_waiting_number
    { [empty_string_p $notify_waiting_number] || [regexp {^(0*)(([1-9][0-9]*))$} $notify_waiting_number match zeros value] }
    "Waiting list count should be blank or an integer greater than 0"
}


# Create the section for predefined sessions
if { [info exists template_calendar_id] } {
    set sessions_list [db_list_of_lists sessions { }]
} else {
    set sessions_list [list]
}

if { [llength $sessions_list] } {
    ad_form -extend -name add_section -form {
	{-section "Predefined Sessions"}
    }
}

if { ! [info exists sessions] || ![llength $sessions] } {
    set sessions [list]
    
    # allow setting start/end date if there aren't sessions predefined
    # DAVEB 20070112 Adding active_state_date and active_end_date 
    ad_form -extend -name add_section -form {
	{active_start_date:date(date),to_sql(ansi),from_sql(ansi),optional {label "[_ dotlrn.Start_Date]"}}
	{active_end_date:date(date),to_sql(ansi),from_sql(ansi),optional {label "[_ dotlrn.End_Date]"}}
    }
    
}
foreach s $sessions_list {
    array set session $s
    template::util::array_to_vars session

    # Roel: It might be better to create a widget for all these
    set checked " checked"
    if { [llength $sessions] } {
	if { [lsearch $sessions $cal_item_id] == -1 } {
	    set checked ""
	}
    }

    ad_form -extend -name add_section -form [subst -nobackslashes -nocommands {
	{$cal_item_id:text(text),optional
	    {label {$session_name}}
	    {html {id sel$cal_item_id}}
	    {before_html {<input type=checkbox name='sessions' value='$cal_item_id'$checked> Create this session<br />}}
	    {after_html {<input type='reset' value=' ... ' onclick=\"return showCalendar('sel$cal_item_id', 'y-m-d');\"> \[<b>y-m-d </b>\]}}
	}
	{${cal_item_id}_start_time:date,optional {label "From"} {format {[lc_get formbuilder_time_format]}}}
	{${cal_item_id}_end_time:date,optional {label "To"} {format {[lc_get formbuilder_time_format]}}}
    }]

    lappend validate [subst -nobackslashes -nocommands {$cal_item_id
	{ [lsearch {$sessions} $cal_item_id] == -1 || ! [empty_string_p "[set $cal_item_id]"] }
	"You must enter a date for \"$session_name\""
    }]
}

lappend validate {price
    { ![template::util::negative [template::util::currency::get_property whole_part $price]] }
    "Price can not be negative"
} 

if { ! [parameter::get -parameter AllowFreeRegistration -default 0] } {
    lappend validate {price 
	{ !"[template::util::currency::get_property whole_part $price].[template::util::currency::get_property fractional_part $price]" == "0.00" }
	"Price can not be zero"
    }
}

if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0] &&
     ! [parameter::get -parameter AllowFreeRegistration -default 0]
 } {
    lappend validate {member_price
	{ ![template::util::negative [template::util::currency::get_property whole_part $member_price]] }
	"Member Price can not be negative"
    }
}

if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
	lappend validate {categories
	{ [dotlrn_ecommerce_check_grade $section_id $categories] }
	"Please select one or more grades"
	}
}
set section_name_validate_message "Section code must be less than [expr {200 - [string length "$course_data(name): Section "]}] characters"
lappend validate {section_name 
    {([string length "$course_data(name): Section $section_name"] < 200)} 
    $section_name_validate_message
}

ad_form -extend -name add_section -validate $validate -on_request {
    # Set session times
    foreach s $sessions_list {
	array set session $s
	template::util::array_to_vars session

	set start_time [split $typical_start_time :]
	set ${cal_item_id}_start_time [list {} {} {} [lindex $start_time 0] [lindex $start_time 1] {} {HH24:MI}]
	set end_time [split $typical_end_time :]
	set ${cal_item_id}_end_time [list {} {} {} [lindex $end_time 0] [lindex $end_time 1] {} {HH24:MI}]
	
	set ${cal_item_id} $start_date
    }
    set show_participants_p t
    set show_sessions_p t
    if { $show_price_option_p } {
	set show_price_p t
    }
} -new_request {
    set product_id 0
    set price [template::util::currency::create "$" "0" "." "00" ]
    set member_price [template::util::currency::create "$" "0" "." "00" ]
} -edit_request {
    set course_item_id $course_id
    db_1row community {
	select des.*, p.price, c.community_key as section_key,
        c.active_start_date, c.active_end_date
	from dotlrn_ecommerce_section des, ec_products p, dotlrn_communities_all c
	where des.product_id = p.product_id
	and des.community_id = c.community_id
	and des.section_id = :section_id
    }
    set active_start_date [template::util::date::from_ansi $active_start_date]
    set active_end_date [template::util::date::from_ansi $active_end_date]

    set course_id $course_item_id

	# HAM
	# price is using currency_widget
	set price_split [split $price .]
	set price [template::util::currency::create "$" [lindex $price_split 0] "." [lindex $price_split 1] ]

    db_1row custom_fields {
	select * from ec_custom_product_field_values where product_id = :product_id
    }

    # Get instructors and assistants
    set instructors [db_list instructors {
	select user_id
	from dotlrn_member_rels_approved
	where community_id = :community_id
	and rel_type = 'dotlrn_ecom_instructor_rel'
	and user_id in (select user_id
			from dotlrn_member_rels_approved
			where community_id = :instructor_community_id)
    }]

    set assistants [db_list assistants {
	select user_id
	from dotlrn_member_rels_approved
	where community_id = :community_id
	and rel_type = 'dotlrn_ecom_ta_rel'
	and user_id in (select user_id
			from dotlrn_member_rels_approved
			where community_id = :assistant_community_id)
    }]

    if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] &&
	 ! [parameter::get -parameter AllowFreeRegistration -default 0]
     } {
	if { [db_0or1row member_price { }] } {
	    # HAM
	    # member_price is using currency_widget
	    set member_price_split [split $member_price .]
	    set member_price [template::util::currency::create "$" [lindex $member_price_split 0] [lindex $member_price_split 1] ]
	}
    }

    set prerequisites [db_list prerequisites {
	select tree_id
	from dotlrn_ecommerce_prereqs
	where section_id = :section_id
    }]
} -new_data {
    
    if { ! $show_price_option_p } {
	set show_price_p t
    }

    db_transaction {
        # create the class instance
	# See if we have a template community
	# If yes, clone it
	if { [exists_and_not_null template_community_id] } {
	    set community_id [dotlrn_community::clone \
				  -community_id $template_community_id \
				  -key $section_key \
				  -pretty_name "$course_data(name): Section $section_name"]

	    ns_log notice "DEBUG:: Cloned $community_id from $template_community_id"
	} else {
	    set community_id [dotlrn_community::new \
				  -community_type dotlrn_club \
				  -object_type dotlrn_club \
				  -community_key $section_key \
				  -pretty_name "$course_data(name): Section $section_name"]
	}

	# Set start and end date if they exist
	if {[info exists active_start_date] \
		&& [info exists active_end_date]} {
	    db_dml update_dates "update dotlrn_communities_all
                                 set active_start_date =:active_start_date,
                                     active_end_date = :active_end_date
                                 where community_id = :community_id"
	}

	# HAM : Let's add chosen instructors in the role of instructors 
	# and assistants in the role of assistants
	foreach instructor $instructors {
		# dotlrn_club::add_user -rel_type "dc_instructor_rel" -community_id $community_id -user_id $instructor -member_state "approved"
		dotlrn_club::add_user -rel_type "dotlrn_ecom_instructor_rel" -community_id $community_id -user_id $instructor -member_state "approved"
	}
	foreach assistant $assistants {
		# dotlrn_club::add_user -rel_type "dc_instructor_rel" -community_id $community_id -user_id $assistant -member_state "approved"
		dotlrn_club::add_user -rel_type "dotlrn_ecom_ta_rel" -community_id $community_id -user_id $assistant -member_state "approved"
	}
	
       
	# add the calendar item type "session"
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	if { ! [db_0or1row get_item_type_id {}] } {
	    set item_type_id [calendar::item_type_new -calendar_id $calendar_id -type "Session"]
	}


 	# create an ecommerce product
	set product_id [db_nextval acs_object_id_seq]

	set user_id [ad_conn user_id]
	set context_id [ad_conn package_id]
        set product_name "$section_name"
        set sku ""
        set one_line_description "$section_name"
        set detailed_description ""
        set search_keywords ""
        set present_p "t"
        set stock_status ""
        # let's have dirname be the first four letters (lowercase) of the product_name
        # followed by the product_id (for uniqueness)
	regsub -all {[^a-zA-Z]} $product_name "" letters_in_product_name
	set letters_in_product_name [string tolower $letters_in_product_name]
	if [catch {set dirname "[string range $letters_in_product_name 0 3]$product_id"}] {
            #maybe there aren't 4 letters in the product name
            set dirname "$letters_in_product_name$product_id"
        }

	set subdirectory "[ec_data_directory][ec_product_directory][ec_product_file_directory $product_id]"
	ec_assert_directory $subdirectory

	set full_dirname "$subdirectory/$dirname"
	ec_assert_directory $full_dirname

	set color_list ""
        set size_list ""
	set peeraddr [ad_conn peeraddr]
	set product_id [db_exec_plsql product_insert {	}]

	db_dml product_update {
	    update ec_products
	    set active_p = 't', no_shipping_avail_p = 't'
	    where product_id = :product_id
	}
	# take care of custom fields
        # we have to generate audit information
        # set audit_fields "last_modified, last_modifying_user, modified_ip_address"
        # set audit_info "now(), :user_id, :peeraddr"
	
        # things to insert into ec_custom_product_field_values if they exist
	set custom_columns_to_insert [list product_id]
	set custom_column_values_to_insert [list ":product_id"]
	set bind_set [ns_set create]
        ns_set put $bind_set product_id $product_id
        ns_set put $bind_set user_id $user_id
        ns_set put $bind_set peeraddr $peeraddr
	
	db_foreach custom_columns_select {
            select field_identifier, column_type
            from ec_custom_product_fields
            where active_p='t'
	} {
	    if {[info exists $field_identifier] } {
                lappend custom_columns_to_insert $field_identifier
                lappend custom_column_values_to_insert ":$field_identifier"
		if {[string equal $column_type date] || [string equal $column_type timestamp]} {
		    set one_date [template::util::date::get_property linear_date_no_time [subst $$field_identifier]]
                    ns_set put $bind_set $field_identifier $one_date
		} else {
		    ns_set put $bind_set $field_identifier [subst $$field_identifier]
		}
	    }
	}
	db_dml custom_fields_insert { } -bind $bind_set

	#HAM: create a sale item from the member price
	# do so only if member price is provided
	# and MemberPriceP is 1
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] && [exists_and_not_null member_price] && $member_price != 0.00 && ! [parameter::get -parameter AllowFreeRegistration -default 0] } {

		# HAM : FIXME

		# not sure if these values are correct
		# comment out when properly tested

		set sale_price_id [db_nextval ec_sale_price_id_sequence]
		set sale_price $member_price
		set offer_code "dotlrn-ecommerce"
	
		db_dml sale_insert { }
	}

	#CM: We should probably add ecomerce_product_id to ecommerce_Section and insert it here.

	# Use item_id as course_id coz course_id is the revision and
	# its easier to keep track of the item_id
	db_dml add_section {
	    insert into dotlrn_ecommerce_section(section_id, course_id, section_name, community_id,product_id, notify_waiting_number, show_participants_p, show_sessions_p, description, show_price_p) values
	    (:section_id, :item_id, :section_name, :community_id, :product_id, :notify_waiting_number, :show_participants_p, :show_sessions_p, :description, :show_price_p)
	}

	# for this to work, dotlrn_eccomerce_section must be an object 
	# just use community_id DAVEB
	# where do the terms options come from?! DAVEB
	
	if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
		category::map_object -object_id $community_id $categories
	}

	# Map patron relationships
	set tree_id [parameter::get -package_id [ad_conn package_id] -parameter PatronRelationshipCategoryTree -default 0]
        if {!$tree_id == 0} {
            category_tree::map -tree_id $tree_id -object_id $community_id
        }

	# Prerequisites
	if { [info exists prerequisites] } {
	    foreach prereq $prerequisites {
		db_dml insert_prereq {
		    insert into dotlrn_ecommerce_prereqs
		    (section_id, tree_id)
		    values
		    (:section_id, :prereq)
		}
	    }
	}
    }

    # HAM : let's now add a "Section Administration" portlet for this new section
    set admin_portal_id [dotlrn_community::get_admin_portal_id -community_id $community_id]
    set element_id [dotlrn_ecommerce_admin_portlet::add_self_to_page -portal_id $admin_portal_id -package_id $package_id]
    # ns_log Notice "DEBUG : Added Admin Portal $element_id"
    # we want the section admin portlet to be at the top
    db_dml "bring_portlet_to_top" "update portal_element_map set sort_key=0, region=1 where element_id=:element_id"


    if { [info exists calendar_id] } {
	# Set predefined categories
	# Unfortunately this seems to hang when inside the transaction
	foreach s $sessions_list {	
	    array set session $s
    	    template::util::array_to_vars session
					
	    if { [lsearch $sessions $cal_item_id] != -1 } {
		set date [set $cal_item_id]
		set date [split $date "-"]
		lappend date "" "" "" "YYYY MM DD"

		set start_time [set ${cal_item_id}_start_time]
		set end_time [set ${cal_item_id}_end_time]
		set start_date [calendar::to_sql_datetime -date $date -time $start_time -time_p 1]
		set end_date [calendar::to_sql_datetime -date $date -time $end_time -time_p 1]

		set cal_item_id [calendar::item::new \
				     -start_date $start_date \
				     -end_date $end_date \
				     -name $session_name \
				     -description "$session_description" \
				     -calendar_id $calendar_id \
				     -item_type_id $item_type_id]
	    }
	}
    }

} -edit_data {

    if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
	if { $categories == [list [list $community_id $package_id]] } {
		set categories ""
	}
    }

    if { ! $show_price_option_p } {
	set show_price_p t
    }

    db_transaction {
	db_dml update_section {
	    update dotlrn_ecommerce_section set
	    section_name = :section_name,
	    notify_waiting_number = :notify_waiting_number,
	    show_participants_p = :show_participants_p,
	    show_sessions_p = :show_sessions_p,
	    show_price_p = :show_price_p,
	    description = :description
	    where section_id = :section_id
	}

	# Change the community's name
	dotlrn_community::set_community_name \
	    -community_id $community_id \
	    -pretty_name $section_name

	# Set start and end date if they exist
	if {[info exists active_start_date] \
		&& [info exists active_end_date]} {
	    db_dml update_dates "update dotlrn_communities_all
                                 set active_start_date =:active_start_date,
                                     active_end_date = :active_end_date
                                 where community_id = :community_id"
	}

	# Update price
	db_dml update_price {
	    update ec_products set price = :price, product_name = :section_name where product_id = :product_id
	}

	# things to insert into ec_custom_product_field_values if they exist
	set user_id [ad_conn user_id]
	set peeraddr [ad_conn peeraddr]
	set custom_columns_to_insert [list product_id]
	set custom_column_values_to_insert [list ":product_id"]
	set bind_set [ns_set create]
	ns_set put $bind_set product_id $product_id
	ns_set put $bind_set user_id $user_id
	ns_set put $bind_set peeraddr $peeraddr

	db_foreach custom_columns_select {
	    select field_identifier, column_type
	    from ec_custom_product_fields
	    where active_p='t'
	} {
	    if {[info exists $field_identifier] } {
		lappend custom_columns_to_update "$field_identifier = :$field_identifier"
		if {[string equal $column_type date] || [string equal $column_type timestamp]} {
		    set one_date [template::util::date::get_property linear_date_no_time [subst $$field_identifier]]
		    ns_set put $bind_set $field_identifier $one_date
		} else {
		    ns_set put $bind_set $field_identifier [subst $$field_identifier]
		}
	    }
	}
	db_dml custom_fields_update { } -bind $bind_set

	if { [parameter::get -package_id [ad_conn package_id] -parameter ShowSectionCategoryFields -default 1 ] } {
			category::map_object -remove_old -object_id $community_id $categories
	}	
	
	# Set instructors
	set original_instructors [db_list instructors {
	    select user_id
	    from dotlrn_member_rels_approved
	    where community_id = :community_id
	    and rel_type = 'dotlrn_ecom_instructor_rel'
	    and user_id in (select user_id
			    from dotlrn_member_rels_approved
			    where community_id = :instructor_community_id)
	}]

	set original_assistants [db_list assistants {
	    select user_id
	    from dotlrn_member_rels_approved
	    where community_id = :community_id
	    and rel_type = 'dotlrn_ecom_ta_rel'
	    and user_id in (select user_id
			    from dotlrn_member_rels_approved
			    where community_id = :assistant_community_id)
	}]
	
	# Remove unwanted instructors and assistants from community
	foreach instructor $original_instructors {
	    if { [lsearch $instructors $instructor] == -1 } {
		catch {dotlrn_community::remove_user $community_id $instructor}
	    }
	}
	
	foreach assistant $original_assistants {
	    if { [lsearch $assistants $assistant] == -1 } {
		catch {dotlrn_community::remove_user $community_id $assistant}
	    }
	}

	# Add new instructors and assistants 
	foreach instructor $instructors {
	    if { [lsearch $original_instructors $instructor] == -1 } {
		catch {dotlrn_community::add_user -rel_type "dotlrn_ecom_instructor_rel" $community_id $instructor}
	    }
	}
	
	foreach assistant $assistants {
	    if { [lsearch $original_assistants $assistant] == -1 } {
		catch {dotlrn_community::add_user -rel_type "dotlrn_ecom_ta_rel" $community_id $assistant}
	    }
	}

	# Set member price, this can be 1 to n but ignore for now
	if { [parameter::get -package_id [ad_conn package_id] -parameter MemberPriceP -default 0 ] && [exists_and_not_null member_price] && ! [parameter::get -parameter AllowFreeRegistration -default 0] } {
	    if { [db_0or1row sale_price { }] } {
		db_dml set_member_price { }	
	    } else {
		set sale_price_id [db_nextval ec_sale_price_id_sequence]
		set sale_price $member_price
		set offer_code "dotlrn-ecommerce"
		
		db_dml sale_insert "
		insert into ec_sale_prices
		(sale_price_id, product_id, sale_price, sale_begins, sale_ends, sale_name, offer_code, last_modified, last_modifying_user, modified_ip_address)
		values
		(:sale_price_id, :product_id, :sale_price, to_date(now() - '1 day':: interval,'YYYY-MM-DD HH24:MI:SS'), to_date(now() + '99 years':: interval,'YYYY-MM-DD HH24:MI:SS'), 'MemberPrice', :offer_code, now(), :user_id, :peeraddr)"
	    }
	}

	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id"]

	foreach s $sessions_list {	
	    array set session $s
	    template::util::array_to_vars session
	    
	    if { [lsearch $sessions $cal_item_id] != -1 } {
		set date [set $cal_item_id]
		set date [split $date "-"]
		lappend date "" "" "" "YYYY MM DD"

		set start_time [set ${cal_item_id}_start_time]
		set end_time [set ${cal_item_id}_end_time]
		set start_date [calendar::to_sql_datetime -date $date -time $start_time -time_p 1]
		set end_date [calendar::to_sql_datetime -date $date -time $end_time -time_p 1]

		set cal_item_id [calendar::item::new \
				     -start_date $start_date \
				     -end_date $end_date \
				     -name $session_name \
				     -description "$session_description" \
				     -calendar_id $calendar_id \
				     -item_type_id $item_type_id]
	    }
	}
	
	# Prerequisites
	if { [info exists prerequisites] } {
	    db_dml delete_prereq {
		delete from dotlrn_ecommerce_prereqs
		where section_id = :section_id
	    }
	    foreach prereq $prerequisites {
		db_dml insert_prereq {
		    insert into dotlrn_ecommerce_prereqs
		    (section_id, tree_id)
		    values
		    (:section_id, :prereq)
		}
	    }
	}

	dotlrn_ecommerce::section::flush_cache $section_id
	dotlrn_ecommerce::section::approve_next_in_waiting_list $community_id
    }
} -after_submit {
    if {![info exists return_url] || [empty_string_p $return_url]} {
	set return_url "one-section?section_id=$section_id"
    }

	ad_returnredirect $return_url
}



# Used by en_US version of new_class_instance message
set class_instances_pretty_name [parameter::get -localize -parameter class_instances_pretty_name]
set f [rp_getform]
ns_set print $f
