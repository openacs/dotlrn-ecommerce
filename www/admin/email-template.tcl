# packages/dotlrn-ecommerce/www/admin/email-template.tcl

ad_page_contract {
    
    add/edit an email template
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-07-20
    @arch-tag: cb528bf6-f4e5-4c87-bbe9-e987780a6709
    @cvs-id $Id$
} {
    {section_id ""}
    {community_id ""}
    {action ""}
    {return_url ""}
} -properties {
} -validate {
} -errors {
}

if {[empty_string_p $return_url]} {
    set return_url [export_vars -base "one-section" {section_id}]
}

switch -exact $action {
    "submit_app" {
        set type "awaiting payment"
    }
    "approve_app" {
	set type "on approval"
    }
    "on join" -
    "awaiting payment" -
    "on approval" -
    "waitinglist approved" -
    "prereq approval" -
    "needs approval" -
    "request approval" -
    "prereq reject" {
        set type $action
    }
    default {
        set type ""
    }
}

if {[empty_string_p $type]} {
    ad_returnredirect $return_url
}


set title "Add/edit default email template"
set section_id [db_string get_section_id {
    select section_id
    from dotlrn_ecommerce_section
    where community_id=:community_id
} -default ""]

if {$community_id ne ""} {
    set title "Add/edit Course default email template"
}
if {$section_id ne ""} {
    set title "Add/edit Section email template"
}

set extra_vars [list [list action $action] [list section_id $section_id]]