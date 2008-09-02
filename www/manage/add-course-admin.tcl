ad_page_contract {
    Add a user to the admin relational segement
} {
    object_id
    userkey:multiple
    authority_id
    return_url
}

set course_id $object_id
set userkey_list $userkey
unset userkey
foreach userkey $userkey_list {

    set username [lindex $userkey 0]
    set authority_id [lindex $userkey 1]
    set user_id [db_string get_user_id "select user_id from cc_users where authority_id = :authority_id and username = :username"]

    permission::grant \
	-object_id $course_id \
	-privilege "admin" \
	-party_id $user_id
    db_1row get_course_community "select dc.community_id, dca.package_id from dotlrn_catalog dc, dotlrn_communities_all dca where course_id = (select latest_revision from cr_items where item_id = :course_id) and dc.community_id = dca.community_id"
    set extra_vars [ns_set create]
    ns_set put $extra_vars user_id $user_id
    ns_set put $extra_vars community_id $community_id
    relation_add -member_state "approved" -extra_vars $extra_vars  dotlrn_admin_rel  $community_id  $user_id

    permission::grant \
	-object_id $community_id \
	-privilege "admin" \
	-party_id $user_id
    set calendar_package_id [dotlrn_ecommerce::community_calendar_package_id -community_id $community_id]
    permission::grant \
	-object_id $calendar_package_id \
	-party_id $user_id \
	-privilege "admin"
    #permission::grant \
	-party_id $user_id \
	-privilege "admin" \
	-object_id $package_id

    db_foreach get_communities "select c.community_id, c.package_id from dotlrn_ecommerce_section s, dotlrn_communities_all c where s.course_id = :course_id and s.community_id = c.community_id" {
	set extra_vars [ns_set create]
	ns_set put $extra_vars user_id $user_id
	ns_set put $extra_vars community_id $community_id
	relation_add -member_state "approved" -extra_vars $extra_vars  dotlrn_admin_rel  $community_id  $user_id

	permission::grant \
	    -party_id $user_id \
	    -privilege "admin" \
	    -object_id $community_id
	set calendar_package_id [dotlrn_ecommerce::community_calendar_package_id -community_id $community_id]
	permission::grant \
	    -object_id $calendar_package_id \
	    -party_id $user_id \
	    -privilege "admin"

	#    permission::grant \
	    -party_id $user_id \
	    -privilege "admin" \
	    -object_id $package_id
	
    }
}
ad_returnredirect -message "Administrator Added" $return_url