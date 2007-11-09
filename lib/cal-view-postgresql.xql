<?xml version="1.0"?>
<queryset>
  <rdbms>
    <type>postgresql</type>
    <version>7.1</version>
  </rdbms>

<fullquery name="get_courses">
      <querytext>
            select dc.course_id, dc.course_key, dc.course_name,
	      	   dc.assessment_id, dec.section_id, dec.section_name,
		   dec.product_id, dec.community_id, dc.course_info,
      		   ci.item_id
            from dotlrn_catalog dc,
	    cr_items ci,
	    dotlrn_ecommerce_section dec
            where dc.course_id = ci.live_revision
	    and ci.item_id = dec.course_id
            and dc.display_p
            [template::list::filter_where_clauses -and -name course_list]

	    order by lower(dc.course_name), lower(dec.section_name)
        </querytext>
</fullquery>

</queryset>
