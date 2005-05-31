<?xml version="1.0"?>
<queryset>

<fullquery name="get_course_info">      
      <querytext>
            select dc.course_info, dc.assessment_id, cr.item_id
	    from dotlrn_catalog dc, cr_revisions cr
 	    where cr.revision_id = :course_id and dc.course_id = :course_id
      </querytext>
</fullquery>

<fullquery name="get_asm_name">
      <querytext>
            select cr.title from
            cr_folders cf, cr_items ci, cr_revisions cr, as_assessments a
            where cr.revision_id = ci.latest_revision and a.assessment_id = cr.revision_id and
            ci.parent_id = cf.folder_id and ci.item_id = :assessment_id order by cr.title
      </querytext>
</fullquery>

	
<fullquery name="get_category">        
	<querytext>
	     select count(object_id) from category_object_map where object_id = :course_id
        </querytext>
</fullquery>

<fullquery name="get_tree_id">      
    <querytext>
    	 select tree_id from category_tree_map where object_id = :cc_package_id
     </querytext>
</fullquery>

<fullquery name="relation">
    <querytext>
            select object_id_two as object_id, rel_type as type from acs_rels
	    where object_id_one = :course_id  order by type 
     </querytext>
</fullquery>

<fullquery name="get_dotlrn_classes">
        <querytext>
            select class_instance_id as object_id, department_name, term_name, class_name, pretty_name, url
            from dotlrn_class_instances_full where class_instance_id in $dotlrn_class
            order by department_name, term_name, class_name, pretty_name
        </querytext>
</fullquery>

<fullquery name="get_dotlrn_communities">
        <querytext>
            select community_id as object_id, pretty_name, url from dotlrn_clubs_full 
	    where community_id in $dotlrn_com order by pretty_name
        </querytext>
</fullquery>

</queryset>