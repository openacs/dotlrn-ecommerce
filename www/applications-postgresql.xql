<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

        <fullquery name="assessment_revision">
        <querytext>    
			select a.title, a.assessment_id as section_assessment_rev_id
			from dotlrn_ecommerce_section s, dotlrn_catalogi c, as_assessmentsi a, cr_items ci, cr_items ai
			where s.course_id = c.item_id
			and c.assessment_id = a.item_id
			and c.course_id = ci.latest_revision
			and a.assessment_id = ai.latest_revision
			and s.section_id = :section_id    
    	</querytext>
		</fullquery>
		
        <fullquery name="get_filter_assessments">
        <querytext>    	
			select distinct a.title, a.revision_id as assessment_id from dotlrn_catalog c, cr_items i, as_assessmentsx a where i.item_id=c.assessment_id and i.latest_revision=a.revision_id
    	</querytext>
		</fullquery>
    
        <fullquery name="applications_pagination">
        <querytext>    
		    select r.rel_id
		    from dotlrn_member_rels_full r
		    left join (select *
			       from ec_addresses
			       where address_id in (select max(address_id)
						    from ec_addresses
						    group by user_id)) e
		    on (r.user_id = e.user_id)
		    left join (select m.*, s.completed_datetime
			       from dotlrn_ecommerce_application_assessment_map m, as_sessions s
			       where m.session_id = s.session_id
			       and m.session_id in (select max(session_id)
						    from dotlrn_ecommerce_application_assessment_map
						    group by rel_id)) m
		    on (r.rel_id = m.rel_id)
                    left join 
         
        (select count(*) as attendance, dca.community_id, a.user_id, dca.community_key as section_key
         from
         calendars c,
         cal_items ci,
         cal_item_types cit,
         attendance_cal_item_map a,
         dotlrn_communities_all dca,
         portal_pages pp,
         portal_element_map pem,
         portal_element_parameters pep,
         portal_datasources pd
         where
         a.cal_item_id = ci.cal_item_id
         and cit.calendar_id = c.calendar_id
         and cit.type='Session'
         and ci.on_which_calendar= c.calendar_id
         and pem.datasource_id = pd.datasource_id
         and pep.key = 'calendar_id'
         and pp.page_id = pem.page_id
         and pep.element_id = pem.element_id
         and pd.name='calendar_portlet'
         and pp.portal_id = dca.portal_id
         and pep.value = c.calendar_id
         group by a.user_id, dca.community_id, dca.community_key 
         ) a on (a.user_id = r.user_id and r.community_id = a.community_id),

		    dotlrn_ecommerce_section s
		    left join ec_products p
		    on (s.product_id = p.product_id),
		    dotlrn_catalog t,
		    cr_items i,
		    acs_objects o,
                    dotlrn_communities_all dca
		
		    where r.community_id = s.community_id
		    and s.course_id = i.item_id
		    and t.course_id = i.live_revision
		    and r.rel_id = o.object_id
		    and r.community_id = dca.community_id
		    $member_state_clause
		    $user_clause
		    $section_clause
		    [template::list::filter_where_clauses -and -name applications]
		    [template::list::orderby_clause -name applications -orderby]    
    	</querytext>
    </fullquery>
            
    <fullquery name="applications">
        <querytext>    
		    select $select_columns 		
		    from  dotlrn_member_rels_full r
		    left join (select *
			       from ec_addresses
			       where address_id in (select max(address_id)
						    from ec_addresses
						    group by user_id)) e
		    on (r.user_id = e.user_id)
		    left join (select m.*, s.completed_datetime
			       from dotlrn_ecommerce_application_assessment_map m, as_sessions s
			       where m.session_id = s.session_id
			       and m.session_id in (select max(session_id)
						    from dotlrn_ecommerce_application_assessment_map
						    group by rel_id)) m
		    on (r.rel_id = m.rel_id)
left join
        (select count(*) as attendance, dca.community_id, a.user_id, c.calendar_id, dca.community_key as section_key
         from
         attendance_cal_item_map a,
         calendars c,
         cal_items ci,
         cal_item_types cit,
         dotlrn_communities_all dca,
         portal_pages pp,
         portal_element_map pem,
         portal_element_parameters pep,
         portal_datasources pd
         where
         a.cal_item_id = ci.cal_item_id
         and cit.calendar_id = c.calendar_id
         and cit.type='Session'
         and ci.on_which_calendar= c.calendar_id
         and pem.datasource_id = pd.datasource_id
         and pep.key = 'calendar_id'
         and pp.page_id = pem.page_id
         and pep.element_id = pem.element_id
         and pp.portal_id = dca.portal_id
         and pd.name='calendar_portlet'
         and pep.value = c.calendar_id
         group by a.user_id, dca.community_id, c.calendar_id, dca.community_key
         ) a
		
 on (a.user_id = r.user_id and a.community_id  = r.community_id),
		    dotlrn_ecommerce_section s
		    left join ec_products p
		    on (s.product_id = p.product_id),
		    dotlrn_catalogi t,
		    cr_items i,
		    acs_objects o,
                    dotlrn_communities_all dca
		    where r.community_id = s.community_id
		    and s.course_id = i.item_id
		    and t.course_id = i.live_revision
		    and r.rel_id = o.object_id
		    and r.community_id = dca.community_id
		    $member_state_clause
		    $user_clause
		    $section_clause
			$page_clause
		    [template::list::filter_where_clauses -and -name applications]
		    [template::list::orderby_clause -name applications -orderby]    
	$groupby_clause
    	</querytext>
    </fullquery>
    
    <fullquery name="get_comments">
        <querytext>    
            select g.comment_id,
                   r.content as gc_content,
                   r.title as gc_title,
	           r.mime_type as gc_mime_type,
                   acs_object__name(o.creation_user) as gc_author,
                   to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as gc_creation_date_ansi
            from general_comments g,
                 cr_revisions r,
                 cr_items ci,
                 acs_objects o
            where g.object_id in (select session_id
                                  from as_sessions
                                  where assessment_id = (select assessment_id 
							 from as_sessions 
							 where session_id =  :session_id)
				        and subject_id = :applicant_user_id)
                  and r.revision_id = ci.live_revision
                  and ci.item_id = g.comment_id 
                  and o.object_id = g.comment_id
            order by o.creation_date
    	</querytext>
    </fullquery>
           
<fullquery name="applications_session_ids">
<querytext>
		    select m.session_id
		
		    from dotlrn_member_rels_full r
		    left join (select *
			       from ec_addresses
			       where address_id in (select max(address_id)
						    from ec_addresses
						    group by user_id)) e
		    on (r.user_id = e.user_id)
		    left join (select m.*, s.completed_datetime
			       from dotlrn_ecommerce_application_assessment_map m, as_sessions s
			       where m.session_id = s.session_id
			       and m.session_id in (select max(session_id)
						    from dotlrn_ecommerce_application_assessment_map
						    group by rel_id)) m
		    on (r.rel_id = m.rel_id), 
		    dotlrn_ecommerce_section s
		    left join ec_products p
		    on (s.product_id = p.product_id),
		    dotlrn_catalogi t,
		    cr_items i,
		    acs_objects o,
                    dotlrn_communities_all dca
		
		    where r.community_id = s.community_id
		    and s.course_id = i.item_id
		    and t.course_id = i.live_revision
		    and r.rel_id = o.object_id
		    and r.community_id = dca.community_id
	            and m.session_id is not null
--		    $member_state_clause
		    $user_clause
		    $section_clause
		    [template::list::filter_where_clauses -and -name applications]
		    [template::list::orderby_clause -name applications -orderby]    

</querytext>
</fullquery> 
</queryset>