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

ad_proc -private dotlrn_ecommerce::copy_course_default_email {
    -community_id
} {
    Copy default email templates into the template community
} {
    set var_list [list community_name [dotlrn_community::get_community_name $community_id]]
    db_transaction {
        foreach type [list "on join" "awaiting payment" "on approval"] {
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
    return [list "on join" "awaiting payment" "on approval"]
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
                     "awaiting payment" dotlrn-ecommerce.Application_submitted \
                     "on approval" dotlrn-ecommerce.Application_approved \
                     submit_app dotlrn-ecommerce.Application_submitted \
                     approve_app dotlrn-ecommerce.Application_approved \
                     "on join" dotlrn-ecommerce.Welcome_to_section \
		     "prereq approval" dotlrn-ecommerce.Application_prereq_approved \
		    "waitinglist approved" dotlrn-ecommerce.lt_A_space_has_opened_up \
		     "prereq reject" dotlrn-ecommerce.Application_prereq_rejected] \
                   $type]
    } elseif {[string equal "body" $key]} {
        return [string map \
                [list \
                     "awaiting payment" dotlrn-ecommerce.lt_Your_application_has_been_submitted \
                     "on approval" dotlrn-ecommerce.lt_Your_application_to_j \
                     submit_app dotlrn-ecommerce.lt_Your_application_has_been_submitted \
                     approve_app dotlrn-ecommerce.lt_Your_application_to_j \
                     "on join" dotlrn-ecommerce.lt_Welcome_to_section_1 \
                     "waitinglist approved" dotlrn-ecommerce.lt_A_space_has_opened_up_1 \
		     "prereq approval" dotlrn-ecommercel.lt_Your_prereq_approved \
		     "prereq reject" dotlrn-ecommerce.lt_Your_prereq_rejected] \
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
		     "awaiting payment" "Application Approved (awaiting payment)" \
		     "on approval" "Application Approved" \
		     "submit_app" "Application Submitted" \
		     "approve_app" "Application Approved" \
		     "on join" "Welcome message" \
		     "waitinglist approved" "Grant spot from waiting list" \
		     "prereq approval" "Approve waiver of prerequisites" \
		     "prereq reject" "Reject waiver of prerequitsites"] $type]
}