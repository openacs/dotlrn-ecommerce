ad_page_contract {
    Displays a delete confirmation message and deletes the course
    @author          Miguel Marin (miguelmarin@viaro.net) 
    @author          Viaro Networks www.viaro.net
    @creation-date   09-02-2005
} {
    object_id:notnull
    course_key:notnull
    creation_user:notnull
}

set page_title "[_ dotlrn-catalog.confirm_delete] $course_key"
set context [list [list course-list "[_ dotlrn-catalog.course_list]"] "[_ dotlrn-catalog.delete_course]"]
set course_id [db_string "live_rev" "select latest_revision from cr_items where item_id=:object_id"]

# Check for create permissions over dotlrn-catalog
set user_id [ad_conn user_id]
set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
permission::require_permission -party_id $user_id -object_id $object_id -privilege "delete"


set rev_assoc [dotlrn_catalog::check_rev_assoc -item_id $object_id]
set rev_num [lindex $rev_assoc 0]
set assoc_num [lindex $rev_assoc 1]

db_1row sections {
    select count(*) as sections
    from dotlrn_ecommerce_section
    where course_id = :object_id
}

if { ! $sections } {

    ad_form -name delete_course -export {course_key $course_key creation_user $creation_user } -cancel_url "course-info?course_id=$course_id" -form {
	{object_id:text(hidden) 
	    { value $object_id }
	}
    } -on_submit {
	dotlrn_catalog::course_delete -item_id $object_id
    } -after_submit {
	ad_returnredirect "course-list"
	ad_script_abort
    }

}
