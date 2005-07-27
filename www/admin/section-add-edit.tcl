ad_page_contract {

    @author Deds Castillo
    @creation-date 2004-05-01
    @version $Id$
} {
    course_id:notnull
    {section_id:optional ""}
    {return_url "" }

    {sessions:integer,multiple {}}
    section_name:optional
}

dotlrn_catalog::get_course_data -course_id $course_id
set item_id [dotlrn_catalog::get_item_id -revision_id $course_id]

if { [ad_form_new_p -key section_id] } {
    set page_title "Add Section"
} else {
    set page_title "Edit Section"
}

set context [list $page_title]

if { [info exists section_name] } {
    set submitted_p 1
} else {
    set submitted_p 0
}