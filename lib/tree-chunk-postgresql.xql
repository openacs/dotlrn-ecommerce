<?xml version="1.0"?>

<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

	<fullquery name="get_tree_name">
	<querytext>
		select name
		from category_trees t, category_tree_translations tt
		where t.tree_id = tt.tree_id
		and t.tree_id = :tree_id
	</querytext>
	</fullquery>

	<fullquery name="get_courses">
	<querytext>
		select dc.course_id, dc.course_key, dc.course_name,
			dc.assessment_id, dec.section_id, dec.section_name,
			dec.product_id, dec.community_id, dc.course_info,
			ci.item_id, v.maxparticipants, dec.show_participants_p, dec.show_sessions_p
		from dotlrn_catalog dc,
		cr_items ci
		left join dotlrn_ecommerce_section dec
		on (ci.item_id = dec.course_id)
		left join ec_custom_product_field_values v
		on (dec.product_id = v.product_id)
			
		where dc.course_id = ci.live_revision
		and dc.display_p
		[template::list::filter_where_clauses -and -name course_list]
	
		order by lower(dc.course_name), lower(dec.section_name)
	</querytext>
	</fullquery>

	<fullquery name="member_price">
	<querytext>
		select sale_price as member_price
		from ec_sale_prices
		where product_id = :product_id
		limit 1
	</querytext>
	</fullquery>

	<fullquery name="attendees">
	<querytext>
	    select count(*) as attendees
	    from dotlrn_member_rels_approved
	    where community_id = :community_id
	    and (rel_type = 'dotlrn_member_rel' or rel_type = 'dc_student_rel')
	</querytext>
	</fullquery>

	<fullquery name="price">
	<querytext>
	    select price as prices
	    from ec_products
	    where product_id = :product_id
	</querytext>
	</fullquery>

</queryset>
