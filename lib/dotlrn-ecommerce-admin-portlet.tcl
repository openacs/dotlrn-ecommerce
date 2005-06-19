
# where are we

# get the package_id
set package_id [ad_conn package_id]

# get community_id
set community_id [dotlrn_community::get_community_id]

# where is dotlrn-ecommerce mounted
set dotlrn_ecommerce_url [apm_package_url_from_key "dotlrn-ecommerce"]

# show admin links
# we test to see if there is section info
# if not then show_admin is set to 0
# this happens in template sections
set show_admin 1

# retrieve section _info
if { [db_0or1row "get_section_info" "select section_id, product_id from dotlrn_ecommerce_section where community_id = :community_id"] } {

	set community_url [dotlrn_community::get_community_url $community_id]
	
	db_1row attendees {
		select count(*) as attendees
		from dotlrn_member_rels_approved
		where community_id = :community_id
		and (rel_type = 'dotlrn_member_rel'
		or rel_type = 'dotlrn_club_student_rel')
	}
	
	set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]
	
	set calendar_url [calendar_portlet_display::get_url_stub $calendar_id]
	
	set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1" -default 0]
	
	set num_sessions [db_string num_sessions "select count(cal_item_id) from cal_items where on_which_calendar = :calendar_id and item_type_id = :item_type_id"]

} else {
	set show_admin 0
}