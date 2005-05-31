# packages/dotlrn-ecommerce/tcl/course-procs.tcl

ad_library {
    
    Library procs for courses
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-12
    @arch-tag: 5389d524-92b4-4b90-a6f9-f9585134a8d0
    @cvs-id $Id$
}

namespace eval dotlrn_ecommerce::course {}

ad_proc -public dotlrn_ecommerce::course::new {
    -name
    {-description ""}
} {
    Create a dotlrn-catalog course
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-12
    
    @param user_id

    @param name

    @param description

    @return 
    
    @error 
} {
    set folder_id [dotlrn_catalog::get_folder_id]
    set course_key [dotlrn_community::generate_key -name $name]

    set assessment_id [dotlrn_ecommerce::section::get_assessment]

    lappend attributes [list course_key $course_key]
    lappend attributes [list course_name $name]
    lappend attributes [list course_info $description]
    lappend attributes [list assessment_id $assessment_id]
    
    set item_id [content::item::new \
		     -name $course_key \
		     -parent_id $folder_id \
		     -content_type "dotlrn_catalog" \
		     -attributes $attributes \
		     -is_live t \
		     -title $name]

    return [content::item::get_live_revision -item_id $item_id]
}