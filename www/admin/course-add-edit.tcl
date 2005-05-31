ad_page_contract {
    Displays a form to add a course or add a new revision of a course (edit)

    @author          Miguel Marin (miguelmarin@viaro.net) 
    @author          Viaro Networks www.viaro.net
    @creation-date   27-01-2005

} {
    course_id:optional
    mode:optional
    { return_url "" }
    { index "" }
}

set page_title ""
set context ""

set user_id [ad_conn user_id]
set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
if {[info exists course_id]} {
    set revision_id $course_id
} else {
    set revision_id -1
}

# Check for create permissions over dotlrn-catalog package
permission::require_permission -party_id $user_id -object_id $cc_package_id -privilege "create"

if { [info exist mode] } {
    if { [string equal $mode 1] } {
	permission::require_permission -object_id $course_id -privilege "admin"
    } 
    set mode_p edit
} else {
    set mode_p edit
}

# Get assessments
set asm_list [list [list "[_ dotlrn-catalog.not_associate]" "-1"]]
db_foreach assessment { } {
    if { [permission::permission_p -object_id $assessment_id -privilege "admin"] == 1 } {
	lappend asm_list [list $title $assessment_id] 
    }
}

# Get a list of all the attributes asociated to dotlrn_catalog
set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]
set elements ""

# Creates the elements to show with ad_form
set count 1
foreach attribute $attribute_list {
    switch [lindex $attribute 2] {
	assessment_id { continue }
	community_id { continue }
    }
    set element_mode ""
    set aditional_type ""
    set aditional_elements ""
    switch [lindex $attribute 4] {
	string {
	    if { [string equal [lindex $attribute 2] "assessment_id"]} {
                set aditional_type "(select)"
                set aditional_elements [list options $asm_list]
            } else {
                if { [string equal [lindex $attribute 2] "course_key"]} {
                    set element_mode [list mode $mode_p]
                }
            }
	}
	text {
	    set aditional_type "(textarea)"
	    # html element needs to be a list not in curly braces
	    set aditional_elements [list html  {rows 10 cols 55}]
	}
	integer {
	    if { [string equal [lindex $attribute 2] "assessment_id"]} {
		set aditional_type "(select)"
		set aditional_elements [list options $asm_list]
	    }
	}
    }
    if { $count > 3 } {
	append aditional_type ",optional"
    }
    set element [list [lindex $attribute 2]:text${aditional_type} [list label [lindex $attribute 3]] $aditional_elements $element_mode]
    lappend elements $element

    incr count
}

# Create the form
ad_form -name add_course -export {mode $mode} -form {
    course_id:key
    {return_url:text(hidden),optional}
}


ad_form -extend -name add_course -form $elements



ad_form -extend -name add_course -form {
    {category_ids:text(category),multiple,optional
	{label "[_ dotlrn-catalog.categories]"}
	{html {size 4}}
	{value "$revision_id $cc_package_id"}
    }
}

ad_form -extend -name add_course -on_submit {
    if { $category_ids == [list [list $revision_id $cc_package_id]] } {
	set category_ids ""
    }
} -new_data {
    # New item and revision in the CR
    set folder_id [dotlrn_catalog::get_folder_id]
    set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]
    set form_attributes [list]

    # Create master community
    set community_id [dotlrn_club::new -pretty_name "$course_name Section Template"]
    # add the calendar item type "session"
    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
    set item_type_id [calendar::item_type_new -calendar_id $calendar_id -type "Session"]

    foreach attribute $attribute_list {
	set attr_name [lindex $attribute 2]
	if { [info exists $attr_name] } {
	    lappend form_attributes [list $attr_name [set $attr_name]]
	}
    }
    if { [dotlrn_catalog::check_name -name $course_key] } {
	set item_id [content::item::new -name $course_key -parent_id $folder_id \
			 -content_type "dotlrn_catalog" -creation_user $user_id \
			 -attributes $form_attributes -is_live t -title $course_key]
    } else {
	ad_return_complaint 1 "\#dotlrn-catalog.name_already\#"
	ad_script_abort
    }
    # Grant admin privileges to the user over the item in the CR
    permission::grant -party_id $user_id -object_id $item_id  -privilege "admin"
    
    set revision_id [db_string get_revision_id { } -default "-1"]
    if { ![string equal $category_ids "-1"] } {
	category::map_object -object_id $revision_id $category_ids
    }
} -edit_data {
    # New revision in the CR
    catch {
	db_1row template_community {
	    select community_id
	    from dotlrn_catalogi
	    where course_id = :course_id
	}
    }
	
    set folder_id [dotlrn_catalog::get_folder_id]
    set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]
    set attribute_list [package_object_attribute_list -start_with dotlrn_catalog dotlrn_catalog]
    set form_attributes [list]
    foreach attribute $attribute_list {
	set attr_name [lindex $attribute 2]
	if { [info exists $attr_name] } {
	    lappend form_attributes [list $attr_name [set $attr_name]]
	}
    }

    set revision_id [content::revision::new -item_id $item_id -attributes $form_attributes -content_type "dotlrn_catalog"]

    # Set the new revision live  
    dotlrn_catalog::set_live -revision_id $revision_id
    if { ![string equal $category_ids "-1"] } {
	category::map_object -object_id $revision_id $category_ids
    }

} -new_request {
    set context [list [list course-list "[_ dotlrn-catalog.course_list]"] "[_ dotlrn-catalog.new_course]"]
    set page_title "[_ dotlrn-catalog.new_course]"
    set revision_id "-1"
} -edit_request {
    set context [list [list course-list "[_ dotlrn-catalog.course_list]"] "[_ dotlrn-catalog.edit_course]"]
    set page_title "[_ dotlrn-catalog.edit_course]"
    db_1row get_course_info { }
    db_string get_course_assessment { } -default "[_ dotlrn-catalog.not_associated]"
} -after_submit {
    if { $return_url == "" } {
	# set return_url [export_vars -base course-info {course_id course_name course_key} ]
	set return_url "course-info?course_id=$revision_id&course_name=$course_name&course_key=$course_key"
    }
    ad_returnredirect "$return_url"
}