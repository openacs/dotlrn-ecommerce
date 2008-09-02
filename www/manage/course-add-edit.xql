<?xml version="1.0"?>
<queryset>

<fullquery name="assessment">
      <querytext>
      	    select cr.title ,ci.item_id as assessment_id from 
            cr_items ci, cr_revisions cr, as_assessments a, cr_folders cf
            where cr.revision_id = ci.latest_revision and a.assessment_id = cr.revision_id and cf.folder_id = ci.parent_id and cf.package_id = :assessment_package_id
               order by lower(cr.title)
      </querytext>
</fullquery>

<fullquery name="get_course_info">      
      <querytext>
            select * from dotlrn_catalog where course_id = :course_id
      </querytext>
</fullquery>

<fullquery name="get_course_assessment">
      <querytext>
      	    select cr.title from 
            cr_folders cf, cr_items ci, cr_revisions cr, as_assessments a 
            where cr.revision_id = ci.latest_revision and a.assessment_id = cr.revision_id and 
            ci.parent_id = cf.folder_id and ci.item_id = :assessment_id order by cr.title
      </querytext>
</fullquery>

<fullquery name="get_revision_id">      
      <querytext>
            select revision_id from cr_revisions where item_id = :item_id
      </querytext>
</fullquery>


</queryset>
