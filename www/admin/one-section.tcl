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

set public_pages_url "../pages/${section_id}/"
set section_folder_id [dotlrn_ecommerce::section::get_public_folder_id $section_id]
set public_pages_admin_url [export_vars -base ${community_url}/file-storage/ {{folder_id $section_folder_id}}]
set num_attendees [db_string num_attendees { }]

set attendance_show_p [apm_package_installed_p "attendance"]
set expensetracking_show_p [apm_package_installed_p "expenses"]
set show_public_pages_p [parameter::get -parameter SupportPublicPagesP -default 0]

# Get application assessment
set assessment_id [db_string get_assessment {
    select c.assessment_id, c.auto_register_p
    
    from dotlrn_ecommerce_section s,
    dotlrn_catalogi c,
    cr_items i
    
    where s.course_id = c.item_id
    and c.item_id = i.item_id
    and i.live_revision = c.course_id
    and s.section_id = :section_id
    
    limit 1
} -default ""]

if { ! [empty_string_p $assessment_id] } {
    as::assessment::data -assessment_id $assessment_id
    set assessment_select_url [export_vars -base [apm_package_url_from_key dotlrn-ecommerce]admin/course-add-edit { course_id }]
    set assessment_view_url [export_vars -base ${community_url}assessment/assessment { assessment_id }]
    set assessment_edit_url [export_vars -base ${community_url}assessment/asm-admin/one-a { assessment_id }]
}

# Flush cache for this section
# Shouldn't have much effect on performance and will keep the data
# more up to date
dotlrn_ecommerce::section::flush_cache $section_id