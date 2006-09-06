ad_page_contract {
    User Index for courses
} {
    {view "list"}
}
set page_title "Course Catalog "
set context ""

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]

set user_id [ad_conn user_id]

if { $user_id } {
    dotlrn_ecommerce::check_user -user_id $user_id
}

if {[permission::permission_p -party_id $user_id -object_id $cc_package_id -privilege "create"]} {
    set create_p 1
} else {
    set create_p 0
}

set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]

set item_template "one-course?cal_item_id=\$item_id"
