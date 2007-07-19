<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>
		<fullquery name="sections_select">
		<querytext>
		SELECT 
			dca.community_id, 
			dca.community_key as section_identifier,
			dca.community_key as section_key,
			dca.pretty_name,
			dc.course_name, 
			des.course_id, 
			des.section_id, 
			dca.active_start_date, 
			des.date_time_start, 
			dca.active_end_date, 
			des.date_time_end 
		FROM 	cr_items ci,
				dotlrn_catalog dc, 
				dotlrn_ecommerce_section des, 
				dotlrn_communities_all dca 
		WHERE 	ci.live_revision = dc.course_id 
			and des.course_id = ci.item_id 
			and dca.community_id = des.community_id    
	    [template::list::orderby_clause -name sections_list -orderby]    	
		</querytext>
		</fullquery>        
</queryset>