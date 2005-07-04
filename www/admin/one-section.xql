<?xml version="1.0"?>
<queryset>

	<fullquery name="get_section">      
	<querytext>
		select live_revision as course_id, community_id, product_id, section_name from cr_items, dotlrn_ecommerce_section where section_id = :section_id and cr_items.item_id = dotlrn_ecommerce_section.course_id
	</querytext>
	</fullquery>

	<fullquery name="num_attendees">      
	<querytext>
		select count(*) as attendees
		from dotlrn_member_rels_approved
		where community_id = :community_id
		and (rel_type = 'dotlrn_member_rel' or rel_type = 'dotlrn_club_student_rel')
	</querytext>
	</fullquery>

</queryset>