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

set title "Add/edit email template"
if {![exists_and_not_null community_id]} {
    set community_id [db_string get_community_id {
        select community_id
            from dotlrn_ecommerce_section
            where section_id = :section_id
        }]
}

switch -exact $action {
    "submit_app" {
        set type "application sent"
    }
    "approve_app" {
	set type "on approval"
    }
    "on join" -
    "application sent" -
    "on approval" -
    "waitinglist approved" -
    "prereq approval" -
    "prereq reject" {
        set type $action
    }
    default {
        set type ""
    }
}

if {![db_0or1row get_email "select * from dotlrn_member_emails where community_id=:community_id and type=:type" -column_array email]} {
    ad_returnredirect $return_url
    ad_script_abort
}

set info "Are you sure you want to delete '$email(subject)' for [dotlrn_ecommerce::email_type_pretty -type $type]?"
ad_form -name delete -export {section_id community_id action return_url type} -cancel_url $return_url -form {
    {info:text(inform) {label "$info"}}
    } -on_submit {
	db_dml delete_email "delete from dotlrn_member_emails where community_id=:community_id and type=:type"
	ad_returnredirect $return_url
	ad_script_abort
    }

set page_title "Delete email"
ad_return_template