<?xml version="1.0"?>
<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

	<fullquery name="dotlrn_ecommerce::section::section_grades.section_grades">
	<querytext>
		select t.name
		from category_object_map_tree m, category_translations t
		where t.category_id = m.category_id
		and t.locale = coalesce(:locale, 'en_US')
		and m.object_id = :community_id
		and m.tree_id = :grade_tree_id
	</querytext>
	</fullquery>

	<fullquery name="dotlrn_ecommerce::section::course_grades.course_grades">
	<querytext>
		select distinct t.name
		from category_object_map_tree m, category_translations t
		where t.category_id = m.category_id
		and t.locale = coalesce(:locale, 'en_US')
		and m.object_id in (select community_id
				from dotlrn_ecommerce_section
				where course_id = :item_id)
		and m.tree_id = :grade_tree_id
	</querytext>
	</fullquery>

	<fullquery name="dotlrn_ecommerce::section::sessions.session_type">
	<querytext>
		select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id limit 1
	</querytext>
	</fullquery>

	<fullquery name="dotlrn_ecommerce::section::sessions.sessions">
	<querytext>
		select distinct to_char(start_date, 'Mon') as month, to_char(start_date, 'dd') as day, to_char(start_date, 'hh:mi') as timestart, to_char(end_date, 'hh:mi') as timeend, to_char(start_date, 'am') as startampm, to_char(end_date, 'am') as endampm
		from cal_items ci, acs_events e, acs_activities a, timespans s, time_intervals t
		where e.timespan_id = s.timespan_id
		and s.interval_id = t.interval_id
		and e.activity_id = a.activity_id
		and e.event_id = ci.cal_item_id
		and start_date >= current_date
		and ci.on_which_calendar = :calendar_id
		and ci.item_type_id = :item_type_id
	</querytext>
	</fullquery>

	<fullquery name="dotlrn_ecommerce::section::instructors.instructors">
	<querytext>
		select u.user_id, u.first_names||' '||u.last_name
		from dotlrn_users u, dotlrn_member_rels_approved r
		where u.user_id = r.user_id
		and r.community_id = :community_id
		and r.rel_type = 'dotlrn_ecom_instructor_rel'
		and r.user_id in ($instructor_string)
	</querytext>
	</fullquery>

	<fullquery name="dotlrn_ecommerce::section::section_zones.section_zones">
	<querytext>
		select t.name
		from category_object_map_tree m, category_translations t
		where t.category_id = m.category_id
		and t.locale = coalesce(:locale, 'en_US')
		and m.object_id = :community_id
		and m.tree_id = :zone_tree_id
	</querytext>
	</fullquery>
</queryset>
