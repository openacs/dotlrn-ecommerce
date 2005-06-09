ad_page_contract {
    Index for course administration
    @author          Miguel Marin (miguelmarin@viaro.net) 
    @author          Viaro Networks www.viaro.net
    @creation-date   31-01-2005

} {
    {view "list"}
}
set page_title "[_ dotlrn-catalog.course_catalog]"
set context ""

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]

set user_id [ad_conn user_id]

if {[permission::permission_p -party_id $user_id -object_id $cc_package_id -privilege "create"]} {
    set create_p 1
} else {
    set create_p 0
}

set tree_id [db_string get_tree_id { } -default "-1"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]

set item_template "one-course?cal_item_id=\$item_id"