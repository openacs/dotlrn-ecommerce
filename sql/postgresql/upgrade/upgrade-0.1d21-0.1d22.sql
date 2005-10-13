-- adding some more views 
-- for the report tool (sessions and section start)


create or replace view dlec_view_calendars as (
	select section_id, calendars.calendar_id 
	from acs_objects, calendars, apm_packages, dotlrn_ecommerce_section, 
	dotlrn_communities 
	where dotlrn_ecommerce_section.community_id = dotlrn_communities.community_id 
	and  acs_objects.context_id = dotlrn_communities.package_id 
	and acs_objects.object_id = apm_packages.package_id 
	and apm_packages.package_key='calendar' 
	and calendars.package_id = apm_packages.package_id
);

create or replace view dlec_view_cal_session_item_types as (
	select section_id, cal_item_types.calendar_id, item_type_id
	from cal_item_types, dlec_view_calendars
	where cal_item_types.calendar_id = dlec_view_calendars.calendar_id	
	and type = 'Session'
);

create or replace view dlec_view_sessions as (
	select section_id, dlec_view_cal_session_item_types.calendar_id, 
	acs_events.event_id, 
	start_date,
	end_date from dlec_view_cal_session_item_types, 
     	acs_events, cal_items, timespans, time_intervals
	where cal_items.cal_item_id = acs_events.event_id
	and cal_items.on_which_calendar = dlec_view_cal_session_item_types.calendar_id
	and acs_events.timespan_id = timespans.timespan_id
	and timespans.interval_id = time_intervals.interval_id	
);

create or replace view dlec_view_sessions_first as (
	select min(start_date), to_date(min(start_date), 'YYYY-MM-DD') as start_date,
	to_char(min(start_date), 'HH24:MI') as start_time,section_id
	from dlec_view_sessions group by section_id
);


create or replace view dlec_view_sections_with_start as (
	select dlec_view_sections.*,  start_date, start_time
	from dlec_view_sections, dlec_view_sessions_first
	where dlec_view_sections.section_id = dlec_view_sessions_first.section_id
);
