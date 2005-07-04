# packages/dotlrn-ecommerce/www/admin/one-section

ad_page_contract {
    
    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 2005-06-14
    @arch-tag: 
    @cvs-id $Id$
} {
    section_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

set return_url "section?section_id=$section_id"

# course id is the revision_id
db_1row get_section { }

set community_url [dotlrn_community::get_community_url $community_id]
dotlrn_catalog::get_course_data -course_id $course_id
set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]

template::util::array_to_vars course_data
set course_name "$name"

set title "$course_name: Section $section_name"

set community_package_id [dotlrn_community::get_package_id $community_id]

set context [list [list "course-list" "Course List"] [list "course-info?course_id=$course_id" "$course_name"] $section_name ]


set num_attendees [db_string num_attendees { }]

set attendance_show_p [apm_package_installed_p "attendance"]
set expensetracking_show_p [apm_package_installed_p "expenses"]
