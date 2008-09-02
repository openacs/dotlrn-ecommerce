ad_page_contract {
    Manage who can administer this course
} {
    object_id:integer,notnull
}

permission::require_permission \
    -party_id [ad_conn user_id] \
    -object_id $object_id \
    -privilege "admin"

set page_title "Course Administrators"
set context [list $page_title]

set return_url [ad_return_url]

set course_id $object_id
template::list::create \
    -name admins \
    -multirow admins \
    -key user_id \
    -bulk_action_export_vars {return_url course_id} \
    -filters {return_url {}} \
    -elements {
	first_names {}
	last_name {}
	username {}
	email {}
    } -bulk_actions {Remove remove-admin "Remove Admin"}

db_multirow admins admins "select first_names,last_name,username,email,user_id from acs_users_all u, acs_permissions p where object_id = :object_id and p.grantee_id = u.user_id and p.privilege = 'admin'"