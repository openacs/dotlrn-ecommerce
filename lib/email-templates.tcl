# @param community_id
# @param course_name
# @param return_url (optional)


if {![exists_and_not_null return_url]} {
    set return_url [ad_return_url]
}

if {![exists_and_not_null scope]} {
    set scope course
}
set email_types [list "on join" "waitinglist approved" "prereq approval" "prereq reject"]
if {[parameter::get -package_id [ad_conn package_id] -parameter EnableCourseApplicationsP -default 1]} {
    lappend email_types "on approval" "application sent" "application reject" 
}
if {[parameter::get -package_id [ad_conn package_id] -parameter NotifyApplicantOnRequest]} {
    lappend email_types "needs approval" "request approval"
}

db_multirow -extend {type_pretty action_url action from revert revert_url sent_when test_url} email_templates get_email_templates "select subject,type from dotlrn_member_emails where community_id=:community_id" {
    set revert_url [export_vars -base email-template-delete {{community_id $community_id} {action $type} return_url}]
    set revert "[_ dotlrn-ecommerce.Revert]"

    set action_url [export_vars -base email-template {{community_id $community_id} {action $type} return_url}]
    set action "#acs-kernel.common_Edit#"

    if {[set index [lsearch $email_types $type]] > -1} {
	set email_types [lreplace $email_types $index $index]
    }
    set type_pretty [dotlrn_ecommerce::email_type_pretty -type $type]
    set from "using section specific template"
    set sent_when [dotlrn_ecommerce::email_type_sent_when -type $type] 
    set test_url [export_vars -base email-test {community_id return_url type}]
}

foreach type $email_types {
    set action_url [export_vars -base email-template {{community_id $community_id} {action $type} return_url}]
    set action "Edit"
    
    set email [lindex [callback dotlrn::default_member_email -community_id $community_id -type $type -var_list [list course_name $course_name]] 0]
    if {[llength $email]} {
	set subject "[lindex $email 1]"
	set from "[_ dotlrn-ecommerce.site-wide]"
	switch [lindex $email 3] {
	    dotlrn-ecommerce {
		set from "[_ dotlrn-ecommerce.site-wide]"
	    }
	    course {
	        set from  "[_ dotlrn-ecommerce.course]"
	    }
	}
    set test_url [export_vars -base email-test {community_id return_url type}]
	template::multirow append email_templates $subject $type [dotlrn_ecommerce::email_type_pretty -type $type] $action_url $action $from "" "" [dotlrn_ecommerce::email_type_sent_when -type $type] $test_url
    }
}

template::list::create \
    -name email_templates \
    -multirow email_templates \
    -elements {
        subject {label "Email subject"}
	from {label "Template Used"}
        type_pretty {label "Type"}
	sent_when {label "Sent after"}
	action {label "" link_url_col action_url}
	revert {label "" link_url_col revert_url}
	test {label "" link_url_col test_url display_eval {[_ dotlrn-ecommerce.Send]}}
    }