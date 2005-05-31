# packages/dotlrn-ecommerce/www/admin/process-group-puchase.tcl

ad_page_contract {
    Process registration of a group

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2005-05-19
} -query {
    section_id:integer,notnull
} -properties {
    page_title
    context
}

set user_id [ad_conn user_id]

ad_form -name process-group \
    -export { section_id } \
    -form {
	group_id:key
	{name:text {label "Group Name"}}
	{num_members:integer(text) {label "Number of attendees"}}
    } -new_data {
	# FIXME do checking of max attendees etc here
# FIXME figure out why this doesn't work in a transaction
#	db_transaction {
	set unique_group_name "${name}_${group_id}"
	    group::new -group_id $group_id -group_name $unique_group_name
	    set section_community_id [db_string get_community_id "select community_id from dotlrn_ecommerce_section where section_id=:section_id" -default ""]
	    if {[string equal "" $section_community_id]} {
		# FIXME error, do something clever here
	    }
	    for { set i 1 } { $i <= $num_members } { incr i } {
		array set new_user [auth::create_user \
				     -username "${name} Attendee $i" \
					-email "[util_text_to_url -text ${name}-attendee-${i}]@example.com" \
				     -first_names "$name" \
				     -last_name "Attendee $i" \
				     -nologin]
#		ad_return_complaint 1 "new_user '[array get new_user]' section_community_id '${section_community_id}'"
#		if {[info exists new_user(user_id)]} {
#		    relation_add -member_state approved dotlrn_club_student_rel $section_community_id $new_user(user_id)
		    relation_add relationship $group_id $section_community_id	    
		package_exec_plsql -var_list [list [list community_id $section_community_id] [list rel_type "dotlrn_club_student_rel"] [list user_id $new_user(user_id)] [list member_state approved]] dotlrn_club_student_rel new
		relation_add -member_state approved membership_rel $group_id $new_user(user_id)

	#	}
	    }
#	}
    } -after_submit {
	set course_id [db_string get_course_id "    select c.course_id
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id" -default ""]
	ad_returnredirect -message "Added $num_members from $name" [export_vars -base course-info {course_id}]
    }

set page_title "Add Group"
set context [list $page_title]
ad_return_template