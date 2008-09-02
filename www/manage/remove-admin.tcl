ad_page_contract {
    Remove course administrator
} {
    course_id:integer,notnull
    user_id:integer,notnull,multiple
    return_url
}

permission::require_permission \
    -object_id $course_id \
    -party_id [ad_conn user_id] \
    -privilege "admin"

  

db_1row get_course_community "select dc.community_id, dca.package_id from dotlrn_catalog dc, dotlrn_communities_all dca where course_id = (select latest_revision from cr_items where item_id = :course_id) and dc.community_id = dca.community_id"

set user_id_list $user_id
unset user_id 

foreach user_id $user_id_list {
    group::remove_member -group_id $community_id -user_id $user_id
    permission::revoke \
	-object_id $course_id \
	-privilege "admin" \
	-party_id $user_id
    permission::revoke \
	-object_id $community_id \
	-privilege "admin" \
	-party_id $user_id
    permission::revoke \
	-party_id $user_id \
	-privilege "admin" \
	-object_id $package_id
    
    db_foreach get_communities "select c.community_id, c.package_id from dotlrn_ecommerce_section s, dotlrn_communities_all c where s.course_id = :course_id and s.community_id = c.community_id" {
	group::remove_member -group_id $community_id -user_id $user_id
	
	permission::revoke \
	    -party_id $user_id \
	    -privilege "admin" \
	    -object_id $community_id
	permission::revoke \
	    -party_id $user_id \
	    -privilege "admin" \
	    -object_id $package_id
    }
    
}
ad_returnredirect -message "Administrator Removed" $return_url