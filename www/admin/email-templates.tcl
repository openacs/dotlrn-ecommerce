ad_page_contract {
    Show email templates list
} {
    {community_id:integer ""}
}
if {$community_id ne ""} {
    if {[db_0or1row get_section_info "select ds.section_id, ('Section:' || ds.section_name || case when ds.section_name = dc.course_name then '' else '(' || dc.course_name || ')' end ) as course_name from dotlrn_ecommerce_section ds, dotlrn_catalogx dc where ds.community_id=:community_id and ds.course_id=dc.item_id limit 1"]} {
	set community_url [export_vars -base one-section {section_id}]
    } elseif {[db_0or1row get_course_info "select course_id, 'Course:' || course_name as course_name from dotlrn_catalogx, cr_items where live_revision=revision_id and community_id=:community_id"]} {
	set community_url [export_vars -base course-info {course_id}]
    } else {
	ns_returnnotfound
    }
    
} else {
    set course_name ""
}

set return_url [ad_return_url]
set title "Email Templates"
if {[info exists community_url]} {
    set context [list [list $community_url $course_name] $title]
} else {
    set context [list $title]
}
ad_return_template
