ad_page_contract {
    Redirects to the calendar to add sessions
    @author          Caroline@meekshome.com
} {
    community_id
    {return_url "" }
}

#Expected usage. you have just created a dotlrn_community and now you want to add sessions.



set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id $community_id]

set url [calendar_portlet_display::get_url_stub $calendar_id]

set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type = 'Session' and calendar_id = :calendar_id"]

set num_sessions [db_string num_sessions "select count(cal_item_id) from cal_items where on_which_calendar = :calendar_id and item_type_id = :item_type_id"]

ns_write "<a href=\"$url/view?[export_vars -url {{view list}}]\" target=new>$num_sessions Sessions</a> Scheduled. <a href=\"$url/cal-item-new?[export_vars -url {calendar_id item_type_id {view day}}]\" target=new>Add Sessions</a>"
