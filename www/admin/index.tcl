# packages/dotlrn-ecommerce/www/admin/index.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-18
    @arch-tag: 92819343-73fc-4fea-a823-3e62f6c145bc
    @cvs-id $Id$
} {
    
} -properties {
} -validate {
} -errors {
}

set context ""
set page_title "Course/eCommerce Administration"

set instructor_community_id [parameter::get -package_id [ad_conn package_id] -parameter InstructorCommunityId -default 0 ]

set instructor_community_url [dotlrn_community::get_community_url $instructor_community_id]

set assistant_community_id [parameter::get -package_id [ad_conn package_id] -parameter AssistantCommunityId -default 0 ]

set assistant_community_url [dotlrn_community::get_community_url $assistant_community_id]

set return_url [ad_return_url]

# HAM : check if scholarship is installed
set scholarship_installed_p [apm_package_installed_p "scholarship-fund"]

# HAM : check if expenses is installed
set expenses_installed_p [apm_package_installed_p "expenses"]

# HAM : count number of pending applications and user requests
set pending_count [db_string "count_pending" "select count(user_id)
	from dotlrn_member_rels_full r, dotlrn_communities_all c
	where r.community_id = c.community_id
	and member_state = 'needs approval'"]

set request_count [db_string "count_requests" "select count(user_id)
	from dotlrn_member_rels_full r, dotlrn_communities_all c
	where r.community_id = c.community_id
	and member_state = 'request approval'"]

set course_options [db_list_of_lists courses {
    select course_name, course_id
    from dotlrn_catalog c, cr_items i
    where c.course_id = i.live_revision
    order by lower(course_name)
}]

set section_options [db_list_of_lists sections {
    select c.course_name||': '||s.section_name, s.section_id
    from dotlrn_catalogi c, dotlrn_ecommerce_section s, cr_items i
    where c.item_id = s.course_id
    and c.course_id = i.live_revision
    order by lower(c.course_name||': '||s.section_name)
}]

ad_form -name courses -form {
    {course_id:integer(select) {label ""} {options {$course_options}}}
    {view:text(submit) {label "View Course"}}
} -on_submit {
    if { ! [empty_string_p $course_id] } {
	ad_returnredirect [export_vars -base course-info { course_id }]
	ad_script_abort
    }
}

ad_form -name sections -form {
    {section_id:integer(select) {label ""} {options {$section_options}}}
    {purchase:text(submit) {label "Purchase"}}
    {admin:text(submit) {label "Section Admin"}}
} -on_submit {
    if { ! [empty_string_p $section_id] } {
	if { ! [empty_string_p $purchase] } {
	    ad_returnredirect [export_vars -base "process-purchase-all" { section_id }]
	    ad_script_abort
	}
	if { ! [empty_string_p $admin] } {
	    set course_id [db_string course_id {
		select i.live_revision
		from dotlrn_ecommerce_section s, cr_items i
		where s.course_id = i.item_id
		and s.section_id = :section_id
	    } -default 0]
	    
	    ad_returnredirect [export_vars -base "one-section" { course_id section_id }]
	    ad_script_abort	
	}
    }
}

set registration_assessment_id [parameter::get -parameter RegistrationId -package_id [subsite::main_site_id]]
if { ! [empty_string_p $registration_assessment_id] } {
    set registration_assessment_url [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]asm-admin/one-a" { {assessment_id $registration_assessment_id} return_url }]
}