ad_page_contract {
    Course management section
} -query {
    keyword:optional
    {groupby "course_name"}
}

set user_id [ad_conn user_id]
set package_id [ad_conn package_id]

set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]
if {!$admin_p} {

    set admin_section_ids [dotlrn_ecommerce::section::admin_section_ids -user_id $user_id]
    if {![llength $admin_section_ids]} {
	ad_return_complaint 1 "You don't have permission to administer."
	ad_script_abort
    }
    set admin_section_id_clause "and s.section_id in ([template::util::tcl_to_sql_list $admin_section_ids])"
} else {
    set admin_section_id_clause ""
}

# show a list of courses/sections they can see

template::list::create \
    -name courses \
    -multirow courses \
    -key section_id \
    -elements {
	course_name {label "Course" link_url_col course_url hide_p 1}
	section_name {label "Section" link_url_col section_url}
	category_name {label "Categories"}
    } \
    -groupby { label "Group By" values {course_name} } \
    -filters { keyword { where_clause "lower(course_name) like '%' || lower(:keyword) || '%'" }}

db_multirow -extend {section_url course_url category_name} courses courses " select c.course_id, c.course_name, s.section_name, s.section_id
    from cr_items i, dotlrn_catalogi c
    left join ( select
    * from
    dotlrn_ecommerce_section des
    where exists (
                select 1 from acs_object_party_privilege_map m
                where m.party_id = :user_id
                and m.object_id = des.community_id
                and m.privilege = 'admin'
               )
    ) s on
    c.item_id = s.course_id
    where
    c.course_id = i.live_revision
    and exists  (
                select 1 from acs_object_party_privilege_map m
                where m.party_id = :user_id
                and m.object_id = c.course_id
                and m.privilege = 'admin'
               )
    [template::list::filter_where_clauses -name courses -and]
    order by lower(c.course_name), lower(s.section_name) " {
	set section_url [export_vars -base one-section {section_id}]
	set course_url [export_vars -base course-info {course_id}]

#	set asm_name [db_string get_asm_name { } -default "[_ dotlrn-catalog.not_associated]"]
	set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]
	set creation_user [dotlrn_catalog::get_creation_user -object_id $item_id]
	set rel [dotlrn_catalog::has_relation -course_id $course_id]
	set category_name ""
	set mapped [category::get_mapped_categories $course_id]
	foreach element $mapped {
	    append category_name "[category::get_name $element], "
	}
    set category_name [string range $category_name 0 [expr [string length $category_name] - 3]]

    }

set doc_title "[_ dotlrn-ecommerce.Course_Management]"
set context [list $doc_title]

if {![info exists keyword]} {
    set keyword_value [_ dotlrn-catalog.please_type]
} else {
    set keyword_value $keyword
}
ad_return_template
