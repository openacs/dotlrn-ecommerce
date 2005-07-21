# packages/dotlrn-ecommerce/www/admin/email-template.tcl

ad_page_contract {
    
    add/edit an email template
    
    @author Deds Castillo (deds@i-manila.com.ph)
    @creation-date 2005-07-20
    @arch-tag: cb528bf6-f4e5-4c87-bbe9-e987780a6709
    @cvs-id $Id$
} {
    section_id:notnull
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
    default {
        set type ""
    }
}

if {[empty_string_p $type]} {
    ad_returnredirect $return_url
}


set title "Add/edit email template"
set community_id [db_string get_community_id {
    select community_id
    from dotlrn_ecommerce_section
    where section_id = :section_id
}]

set extra_vars [list [list action $action] [list section_id $section_id]]