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

ad_proc -public dotlrn_ecommerce::course::get_course_id_from_key {
    course_key
} {
    Get the course_id from they course key

    @param course_key course_key to look for
    @return course_id id of the course, empty string if no course is found

    @creation-date 2007-01-24
    @author Dave Bauer (dave@solutiongrove.com)

} {
    return [db_string get_id "
select distinct ds.course_id
from dotlrn_ecommerce_section ds,
dotlrn_catalog dc,
cr_revisions cr
where 
dc.course_key=:course_key
and dc.course_id = cr.revision_id
and ds.course_id=cr.item_id
" -default ""]
}
ad_proc -private dotlrn_ecommerce::copy_course_default_email {
    -community_id
} {
    Copy default email templates into the template community
} {
    set var_list [list community_name [dotlrn_community::get_community_name $community_id]]
    db_transaction {
        foreach type [list "on join" "application sent" "on approval"] {
            set from_addr ""
            set email [_ [email_type_message_key -type $type -key body] $var_list]
            set subject [_ [email_type_message_key -type $type -key subject] $var_list]
            db_dml add_email "insert into dotlrn_member_emails
                          (community_id,subject,from_addr,email,type)
                          values
                          (:community_id,:subject,:from_addr,:email,:type)"
        }
    }
}

ad_proc -private dotlrn_ecommerce::active_email_types {
    {-package_id ""}
} {
    list of valid email types for this dotlrn_ecommerce
} {
    return [list "on join" "application sent" "on approval"]
}

ad_proc -private dotlrn_ecommerce::email_type_message_key {
    -type
    -key
} {
    Get the message key for an email type

    @param type email type
    @param key message key, can by subject or body
} {
    if {[string equal "subject" $key]} {
        return [string map \
                [list \
                     "application sent" dotlrn-ecommerce.Application_submitted \
                     "on approval" dotlrn-ecommerce.Application_approved \
                     submit_app dotlrn-ecommerce.Application_submitted \
                     approve_app dotlrn-ecommerce.Application_approved \
                     "on join" dotlrn-ecommerce.Welcome_to_section \
		     "prereq approval" dotlrn-ecommerce.Application_prereq_approved \
		    "waitinglist approved" dotlrn-ecommerce.lt_A_space_has_opened_up \
		     "prereq reject" dotlrn-ecommerce.Application_prereq_rejected \
		     "application reject" dotlrn-ecommerce.Application_rejected \
                     "needs approval" dotlrn-ecommerce.lt_Added_to_waiting_list \
                     "request approval" dotlrn-ecommerce.lt_Requested_waiver_of_prereq] \
                   $type]
    } elseif {[string equal "body" $key]} {
        return [string map \
                [list \
                     "application sent" dotlrn-ecommerce.lt_Your_application_has_been_submitted \
                     "on approval" dotlrn-ecommerce.lt_Your_application_to_j \
                     submit_app dotlrn-ecommerce.lt_Your_application_has_been_submitted \
                     approve_app dotlrn-ecommerce.lt_Your_application_to_j \
                     "on join" dotlrn-ecommerce.lt_Welcome_to_section_1 \
                     "waitinglist approved" dotlrn-ecommerce.lt_A_space_has_opened_up_1 \
		     "prereq approval" dotlrn-ecommercel.lt_Your_prereq_approved \
		     "prereq reject" dotlrn-ecommerce.lt_Your_prereq_rejected \
		     "application reject" dotlrn-ecommerce.lt_Your_application_to_j_1 \
                     "needs approval" dotlrn-ecommerce.lt_Added_to_waiting_list_1 \
                     "request approval" dotlrn-ecommerce.lt_Requested_waiver_of_prereq_1] \
                   $type]
    } else {
        error "Key must be 'subject' or 'body'"
    }
     
}

ad_proc -private dotlrn_ecommerce::email_type_pretty {
    -type
} {
    Pretty email type for display
} {
    return [string map \
		[list \
		     "application sent" "[_ dotlrn-ecommerce.Application_1]" \
		     "on approval" "[_ dotlrn-ecommerce.Application_2]" \
		     "submit_app" "[_ dotlrn-ecommerce.Application_3]" \
		     "approve_app" "[_ dotlrn-ecommerce.Application_2]" \
		     "on join" "[_ dotlrn-ecommerce.Welcome]" \
		     "waitinglist approved" "[_ dotlrn-ecommerce.Grant]" \
		     "prereq approval" "[_ dotlrn-ecommerce.Approve_1]" \
		     "prereq reject" "[_ dotlrn-ecommerce.Reject_1]" \
		     "application reject" "[_ dotlrn-ecommerce.Reject_2]" \
                     "needs approval" "[_ dotlrn-ecommerce.Added]" \
                     "request approval" "[_ dotlrn-ecommerce.Application_4]"] $type]
}

ad_proc -private dotlrn_ecommerce::email_type_sent_when {
    -type
} {
    Pretty email type for display
} {
    return [string map \
		[list \
		     "application sent" "[_ dotlrn-ecommerce.sent]" \
		     "on approval" "[_ dotlrn-ecommerce.sent_1]" \
		     "submit_app" "[_ dotlrn-ecommerce.sent_2]" \
		     "approve_app" "[_ dotlrn-ecommerce.sent_1]" \
		     "on join" "[_ dotlrn-ecommerce.sent_3]" \
		     "waitinglist approved" "[_ dotlrn-ecommerce.sent_4]" \
		     "prereq approval" "[_ dotlrn-ecommerce.sent_5]" \
		     "prereq reject" "[_ dotlrn-ecommerce.sent_6]" \
		     "application reject" "[_ dotlrn-ecommerce.sent_7]" \
                     "needs approval" "[_ dotlrn-ecommerce.sent_8]" \
                     "request approval" "[_ dotlrn-ecommerce.sent_9]"] $type]
}

