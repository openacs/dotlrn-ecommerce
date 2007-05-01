# packages/dotlrn-ecommerce/www/applications.tcl

ad_page_contract {
    
    List of pending and approved applications
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    @arch-tag: 7d7789ef-523a-40dc-aa32-c650e19ece40
    @cvs-id $Id$
} [concat \
       [list \
	    type:optional \
	    orderby:optional \
            groupby:optional \
	    section_id:optional \
	    {csv_p 0} \
	    {as_item_id ""} \
	    {as_search ""} \
	    {page 1} \
	    {all 0} \
	    date_after:optional \
	    date_before:optional \
	    ] \
       [as::list::params]]

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege "admin"
set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]
set return_url [ad_return_url]

set enable_applications_p [parameter::get -package_id [ad_conn package_id] -parameter EnableCourseApplicationsP -default 1]

if { $as_item_id eq "type" } {
    set as_item_type type
    set as_item_choices [subst {
	{"[_ dotlrn-ecommerce.In_Waiting_List]" "needs approval"}
	{"[_ dotlrn-ecommerce.lt_Approved_Waiting_List]" "waitinglist approved"}
	{"[_ dotlrn-ecommerce.For_PreReq_Approval]" "request approval"}
	{"[_ dotlrn-ecommerce.lt_Approved_PreReq_Appli]" "request approved"}
    }]
    
    if { $enable_applications_p } {
	lappend as_item_choices \
	    [list "[_ dotlrn-ecommerce.Applications]" "application sent"] \
	    [list "[_ dotlrn-ecommerce.lt_Approved_Applications]" "application approved"]
    }
    
    lappend as_item_choices [list "[_ dotlrn-ecommerce.Already_Registered]" "approved"]
} elseif { $as_item_id ne "" } {
    set as_item_type [db_string get_type {
	select oi.object_type
	from cr_items i, as_item_rels it, as_item_rels dt, acs_objects oi
	where dt.item_rev_id = it.item_rev_id
	and it.rel_type = 'as_item_type_rel'
	and dt.rel_type = 'as_item_display_rel'
	and oi.object_id = it.target_rev_id
	and i.latest_revision = it.item_rev_id
	and i.item_id = :as_item_id
    }]

    set as_revision_id [db_string get_item_revision {
	select latest_revision
	from cr_items
	where item_id = :as_item_id
    }]

    if { $as_item_type eq "as_item_type_mc" } {
	set as_item_choices [db_list_of_lists item_choices {
	    select r.title, c.choice_id
	    
	    from cr_revisions r, as_item_choices c
	    left outer join cr_revisions r2 on (c.content_value = r2.revision_id)
	    
	    where r.revision_id = c.choice_id
	    and c.mc_id = (select max(t.as_item_type_id)
			   from as_item_type_mc t, cr_revisions c, as_item_rels r
			   where t.as_item_type_id = r.target_rev_id
			   and r.item_rev_id = :as_revision_id
			   and r.rel_type = 'as_item_type_rel'
			   and c.revision_id = t.as_item_type_id
			   group by c.title, t.increasing_p, t.allow_negative_p,
			   t.num_correct_answers, t.num_answers)
	    
	    order by c.sort_order
	}]
    }
} else {
    set as_item_type ""
    set as_revision_id ""
}

set use_embedded_application_view_p [parameter::get -parameter UseEmbeddedApplicationViewP -default 0]

set header_stuff {
    <script type="text/javascript" src="/resources/dotlrn-ecommerce/overlib/overlib.js">
    <!-- overLIB (c) Erik Bosrup (http://www.bosrup.com/web/overlib) -->
    </script>
}

if { [exists_and_not_null type] } {
    set _type $type
} else {
    set _type all
}

set filters {
    {"[_ dotlrn-ecommerce.In_Waiting_List]" "needs approval"}
    {"[_ dotlrn-ecommerce.lt_Approved_Waiting_List]" "waitinglist approved"}
    {"[_ dotlrn-ecommerce.For_PreReq_Approval]" "request approval"}
    {"[_ dotlrn-ecommerce.lt_Approved_PreReq_Appli]" "request approved"}
}

if { $enable_applications_p } {
    lappend filters \
	{"[_ dotlrn-ecommerce.Applications]" "application sent"}
    
    if { ![exists_and_not_null section_id] || [dotlrn_ecommerce::section::price $section_id] > 0.01 } {
	lappend filters \
	    {"[_ dotlrn-ecommerce.lt_Approved_Applications]" "application approved"}
    }
}

lappend filters {"[_ dotlrn-ecommerce.Already_Registered]" "approved"}
set list_filters [subst {
    date_after {
	label "[_ dotlrn-ecommerce.Section_Starts_After]"
	values {}
	form_datatype {date}
	where_clause { active_start_date > :date_after }
    }
    date_before {
	label "[_ dotlrn-ecommerce.Section_Starts_Before]"
	values {}
	form_datatype {date}
	where_clause { active_start_date < :date_before }
    }
    type {
	label "[_ dotlrn-ecommerce.Type_of_Request]"
	values { $filters }
	where_clause { member_state = :type }
    }
}]

lappend list_filters  attendance_filter [list label "Attendance" where_clause { a.attendance >= coalesce(:attendance_filter,0) }]
set actions ""

set bulk_actions [list [_ dotlrn-ecommerce.Approve] application-bulk-approve [_ dotlrn-ecommerce.Approve] "[_ dotlrn-ecommerce.Reject] / [_ dotlrn-ecommerce.Cancel]" application-bulk-reject "[_ dotlrn-ecommerce.Reject] / [_ dotlrn-ecommerce.Cancel]"]

if {[parameter::get -parameter AllowApplicationBulkEmail -default 0]} {
    set actions [list "[_ dotlrn-ecommerce.View_previously_email]" "sent-emails" "[_ dotlrn-ecommerce.View_previously_email]"]
    lappend bulk_actions "[_ dotlrn-ecommerce.Email_applicants]" "email-applicants" "[_ dotlrn-ecommerce.Email_applicants]"
}

if { ![exists_and_not_null section_id] || [dotlrn_ecommerce::section::price $section_id] > 0.01 } {
    lappend bulk_actions "[_ dotlrn-ecommerce.Mark_as_Paid]" application-bulk-payments "[_ dotlrn-ecommerce.Mark_as_Paid]"
}

set elements [list section_name [list \
	    label "[_ dotlrn-ecommerce.Section]" \
	    display_template {
		<if @admin_p@>
		<a href="@applications.section_edit_url;noquote@">@applications.course_name@: @applications.section_name@</a>
		</if>
		<else>
		@applications.course_name@: @applications.section_name@
		</else>
	    } \
    hide_p [info exists groupby] \
                                 ] \
	number {
	    label "[_ dotlrn-ecommerce.lt_Number_in_Waiting_Lis]"
	    html { align center }
	    hide_p {[ad_decode $_type "waitinglist approved" 1 "request approved" 1 "application approved" 1 "all" 0 0]}
	    display_template {
		<if @applications.member_state@ in "needs approval" "request approval">
		@applications.number@
		</if>
		<elseif @applications.member_state@ eq "application sent">
                Awaiting approval
                </elseif>
		<else>
		Approved
		</else>
	    }
	} \
	person_name {
	    label "[_ dotlrn-ecommerce.Participant]"
	    display_template {
		<if @admin_p@>
		<a href="@applications.person_url;noquote@">@applications.person_name@</a>
		</if>
		<else>
		@applications.person_name@
		</else>
	    }
	} \
	member_state {
	    label "[_ dotlrn-ecommerce.Member_Request]"
	    display_template {
		<if @applications.member_state@ eq "needs approval">
		[_ dotlrn-ecommerce.lt_User_is_in_waiting_li]
		</if>
                <elseif @applications.member_state@ eq "application approved">
		[_ dotlrn-ecommerce.lt_User_application_appr]
                </elseif>
                <elseif @applications.member_state@ eq "waitinglist approved">
		[_ dotlrn-ecommerce.lt_User_approved_waiting]
                </elseif>
                <elseif @applications.member_state@ eq "request approved">
		[_ dotlrn-ecommerce.lt_User_has_approved_pre]
                </elseif>
		<elseif @applications.member_state@ eq "approved">
		[_ dotlrn-ecommerce.lt_User_is_already_regis_1]
		</elseif>
		<else>
		[_ dotlrn-ecommerce.lt_User_has_submitted_an]
		</else>
	    }
	} \
	assessment_result {
	    label "[_ dotlrn-ecommerce.Application]"
	    display_template {
		<if @applications.asm_url@ not nil>
		<a href="@applications.asm_url;noquote@" class="button" target="@applications.target@">[_ dotlrn-ecommerce.View]</a>
		<if @applications.completed_datetime@ nil>
		<br />
		[_ dotlrn-ecommerce.incomplete]
		</if>
		</if>
		<else>
		N/A
		</else>
	    }
	    html { align center }
	} \
	phone {
	    label "[_ dotlrn-ecommerce.Phone_Number]"
	    hide_p {[ad_decode $_type "waitinglist approved" 0 "request approved" 0 "application approved" 0 "all" 0 1]}
	} \
              ]

if {[parameter::get -parameter AllowApplicationNotes -default 1]} {
    lappend elements comments {
	    label "[_ dotlrn-ecommerce.Notes]"
	    display_template {
		@applications.comments_truncate;noquote@
		<if @applications.add_comment_url@ not nil>
		<a href="@applications.add_comment_url@" title="[_ dotlrn-ecommerce.Add_note]">[_ dotlrn-ecommerce.Add_note]</a>
		</if>
	    }
	} \
	comments_text_plain {
	    label "[_ dotlrn-ecommerce.Notes]"
	    hide_p {[ad_decode $csv_p 1 0 1]}
	} \
        attendance {label "Attendance"
            aggregate "count"
            aggregate_group_label "Num. Attendees"            
        }

}

lappend elements \
	actions {
	    label ""
	    display_template {
		<if @applications.member_state@ in "needs approval" "request approval" "application sent">
		<a href="@applications.approve_url;noquote@" class="button">[_ dotlrn-ecommerce.Approve]</a>
		<a href="@applications.reject_url;noquote@" class="button">[_ dotlrn-ecommerce.Reject]</a>
		</if>
		<elseif @applications.member_state@ ne "approved">
		<a href="@applications.reject_url;noquote@" class="button">[_ dotlrn-ecommerce.Cancel]</a>
		<if @admin_p@>
		<a href="@applications.register_url;noquote@" class="button">[_ dotlrn-ecommerce.Register]</a>
		</if>
		</elseif>
	    }
	}

if { [exists_and_not_null section_id] } {
    set section_clause {and s.section_id = :section_id}

    if { [db_0or1row assessment_revision { }] } {
		array set search_arr [as::list::filters -assessments [list [list $title $section_assessment_rev_id]]]
    } else {
		array set search_arr [list list_filters [list] assessment_search_options [list] search_js_array ""]
    }
    
} else {
    set section_clause ""
    # we want to get all the questions that are common to dotlrn-ecommerce 
    # applications
    set filter_assessments [db_list_of_lists get_filter_assessments {}]

    array set search_arr [as::list::filters -assessments $filter_assessments]
}

set search_options [concat [list [list [_ dotlrn-ecommerce.Type_of_Request] type]] $search_arr(assessment_search_options)]

if { [info exists type] } {
    set filters {
	{"[_ dotlrn-ecommerce.In_Waiting_List]" "needs approval"}
	{"[_ dotlrn-ecommerce.lt_Approved_Waiting_List]" "waitinglist approved"}
	{"[_ dotlrn-ecommerce.For_PreReq_Approval]" "request approval"}
	{"[_ dotlrn-ecommerce.lt_Approved_PreReq_Appli]" "request approved"}
    }
    
    if { $enable_applications_p } {
	lappend filters \
	    {"[_ dotlrn-ecommerce.Applications]" "application sent"} \
	    {"[_ dotlrn-ecommerce.lt_Approved_Applications]" "application approved"}
    }
    
    lappend filters {"[_ dotlrn-ecommerce.Already_Registered]" "approved"}

    set list_filters [subst {
	type {
	    label "[_ dotlrn-ecommerce.Type_of_Request]"
	    values { $filters }
	    where_clause { member_state = :type }
	}
    }]
}

append list_filters {
    section_id {}
    as_item_id {}
    as_search {}
}

set search_options [concat {{"" ""}} $search_options]
ad_form -name as_search -export [concat [list type orderby section_id cvs_p] [as::list::params]] -form {
    {as_item_id:text(select) {label Question} {options {$search_options}} {html {onchange "if (searchItems\[this.value\] != 'section' && searchItems\[this.value\] != 'assessment') { this.form.as_search.disabled = true; this.form.submit() } else { this.form.as_search.disabled = true; this.form.search.disabled = true }"}}}
}

if { $as_item_id ne "" && ($as_item_type eq "as_item_type_mc" || $as_item_type eq "type") } {
    ad_form -extend -name as_search -form {
	{as_search:text(select) {label Search} {options {$as_item_choices}}}
    }
} else {
    ad_form -extend -name as_search -form {
	{as_search:text {label Search}}
    }
}

ad_form -extend -name as_search -form {
    {search:text(submit) {label Search}}
    {clear:text(submit) {label Clear}}
} -on_request {
} -on_submit {
    if { $as_item_type eq "type" } {
	ad_returnredirect [export_vars -base applications [concat [list orderby section_id csv_p as_item_id as_search [list type $as_search]] [as::list::params]]]
    } else {
	ad_returnredirect [export_vars -base applications [concat [list type orderby section_id csv_p as_item_id as_search [list "as_item_id_$as_item_id" $as_search]] [as::list::params]]]
    }

    ad_script_abort
}

set list_filters [concat $list_filters $search_arr(list_filters)]

#lappend list_filters csv_p {
#    label "[_ dotlrn-ecommerce.Export]"
#    values {{"[_ dotlrn-ecommerce.CSV]" 1}}
#    has_default_p 1
#}


if {[info exists groupby]} {
    lappend actions "Ungroup" applications "Stop grouping applications by section name"
} else {
    lappend actions "Group by Section Name" [export_vars -base applications {{groupby section_name}}] "Group applications by section name"
}

# HAM :
# this exports the current page
lappend actions \
    "[_ dotlrn-ecommerce.Export] Page" \
    [export_vars -base [ad_return_url] { {csv_p 1} }] \
    "[_ dotlrn-ecommerce.Export] Page"
    
# this exports all data
lappend actions \
		"[_ dotlrn-ecommerce.Export] All" \
		[export_vars -base [ad_return_url] { {csv_p 1} {all 1} }] \
		"[_ dotlrn-ecommerce.Export] All"
		    
    
if { $admin_p } {
    set user_clause ""
} else {
    set user_clause {
	and r.community_id in (select community_id
			       from dotlrn_member_rels_full
			       where user_id = :user_id
			       and rel_type in ('dotlrn_admin_rel', 'dotlrn_ecom_instructor_rel'))
    }
}

if { $enable_applications_p } {
    set member_state_clause { and member_state in ('needs approval', 'waitinglist approved', 'request approval', 'request approved', 'application sent', 'application approved', 'approved') }
} else {
    set member_state_clause { and member_state in ('needs approval', 'waitinglist approved', 'request approval', 'request approved', 'approved') }
}

set general_comments_url [apm_package_url_from_key "general-comments"]

if { $all } {

	# HAM : use this template to export all to csv
    ns_log notice "exporting ALL to CSV, elements = [join $elements \n]"
	template::list::create \
	    -name "applications" \
	    -key rel_id \
	    -multirow "applications" \
	    -no_data "[_ dotlrn-ecommerce.No_applications]" \
	    -pass_properties { return_url } \
	    -pass_properties { admin_p return_url _type } \
	    -actions $actions \
	    -bulk_actions $bulk_actions \
	    -page_flush_p 1 \
	    -bulk_action_export_vars { return_url } \
	    -elements $elements \
	    -filters $list_filters \
	    -filter_form 1 \
	    -orderby {
			section_name {
			    label "[_ dotlrn-ecommerce.Section_1]"
			    orderby "lower(s.section_name)"
			}
			number {
			    label "[_ dotlrn-ecommerce.lt_Number_in_Waiting_Lis]"
			    orderby "lower(s.section_name), number"
			}
			person_name {
			    label "[_ dotlrn-ecommerce.Participant]"
			    orderby "lower(person__name(r.user_id))"
			}
			member_state {
			    label "[_ dotlrn-ecommerce.Member_Request]"
			}
	    }
	
	set page_clause ""
	
} else {
    ns_log notice "exporting PAGE to CSV, elements = [join $elements \n]"
	# HAM : use this list template to display rows
	#  has support for paging	
	template::list::create \
	    -name "applications" \
	    -key rel_id \
	    -multirow "applications" \
	    -no_data "[_ dotlrn-ecommerce.No_applications]" \
	    -pass_properties { return_url } \
	    -pass_properties { admin_p return_url _type } \
	    -actions $actions \
	    -bulk_actions $bulk_actions \
	    -page_size 25 \
	    -page_flush_p 1 \
	    -page_query_name "applications_pagination"  \
	    -bulk_action_export_vars { return_url } \
	    -elements $elements \
	    -filters $list_filters \
	    -filter_form 1 \
	    -orderby {
			section_name {
			    label "[_ dotlrn-ecommerce.Section_1]"
			    orderby "lower(s.section_name)"
			}
			number {
			    label "[_ dotlrn-ecommerce.lt_Number_in_Waiting_Lis]"
			    orderby "lower(s.section_name), number"
			}
			person_name {
			    label "[_ dotlrn-ecommerce.Participant]"
			    orderby "lower(person__name(r.user_id))"
			}
			member_state {
			    label "[_ dotlrn-ecommerce.Member_Request]"
			}
	    } -groupby {
                label "Group By"
                values {section_name {{groupby section_id } {orderby section_id}}}
            }
	
	set page_clause [template::list::page_where_clause -and -key r.rel_id -name applications]
}

set csv_session_ids [list]
    
db_multirow -extend { unique_id approve_url reject_url asm_url section_edit_url person_url register_url comments comments_text_plain comments_truncate add_comment_url target calendar_id item_type_id num_sessions attendance_rate} applications applications [subst { }] {
    set unique_id "${applicant_user_id}-${section_id}"
    set list_type [ad_decode $member_state "needs approval" full "request approval" prereq "application sent" payment full]

    set approve_url [export_vars -base application-approve { community_id {user_id $applicant_user_id} {type $list_type} return_url }]

    set reject_url [export_vars -base application-reject { community_id {user_id $applicant_user_id} {type $list_type} return_url }]

    if { ! [empty_string_p $session_id] } {
	if {$use_embedded_application_view_p ==1} {
	    set asm_url "admin/application-view?session_id=$session_id"
	    set target ""
	} else {
	    
	    set asm_url [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]asm-admin/results-session" { session_id }]
	    set target "_blank"
	}
    }	    

    set section_edit_url [export_vars -base admin/one-section { section_id return_url }]
    set person_url [export_vars -base /acs-admin/users/one { {user_id $applicant_user_id} }]

    set add_url [export_vars -base "[ad_conn package_url]ecommerce/shopping-cart-add" { product_id {user_id $patron_id} {participant_id $applicant_user_id} return_url }]
    set register_url [export_vars -base admin/participant-add { section_id {user_id $applicant_user_id} return_url add_url }]

    # get associated comment
    if {![empty_string_p $asm_url]} {
        db_foreach get_comments { } {
	    if {[string equal $gc_mime_type "text/plain"]} {
		set html_comment [dotlrn_ecommerce::util::text_to_html -text $gc_content]
	    } else {
		set html_comment $gc_content
	    }
	    set edit_comment_url [export_vars -base "${general_comments_url}comment-edit" {return_url comment_id}]
            set comments "<b>$gc_title</b><br />${html_comment}<br /><i>- $gc_author on $gc_creation_date_ansi</i><br /><br />"
	    set comments_text [ad_html_text_convert -from "text/html" -to "text/plain" $html_comment]
	    append comments_text_plain "${gc_title} - ${comments_text}\n"
	    append comments_truncate "<a href=\"javascript:void(0);\" onmouseover=\"return overlib('$comments');\" onmouseout=\"return nd();\" style=\"text-decoration: none;\">$gc_title</a> \[<a href=\"$edit_comment_url\">edit</a>\]<br /><br />"
        }
	set add_comment_url [export_vars -base "${general_comments_url}comment-add" {{object_id $session_id} {object_name "Application"} return_url}]
    }

    # prepare to add attendance data to application export DAVEB
    set calendar_id [dotlrn_calendar::get_group_calendar_id -community_id \
			 [db_string get_community_id "select community_id from dotlrn_ecommerce_section where section_id=:section_id" -default ""]]
    set item_type_id [db_string item_type_id "select item_type_id from cal_item_types where type='Session' and  calendar_id = :calendar_id"]
    set num_sessions [db_string num_sessions "select count(cal_item_id) from cal_items where on_which_calendar = :calendar_id and item_type_id = :item_type_id"]    
    if {$session_id ne ""} {
	lappend csv_session_ids $session_id
    }

	# attendance data
	if { $num_sessions == 0 } { set attendance_rate "0" } else  { set attendance_rate [format "% .0f" [expr (${attendance}.0/$num_sessions)*100]] }
       

}
# HAM :
# unset section id because it seems the last section_id
#  is being picked up by the paging links
if {[info exists section_id]} {
    unset section_id
}

# if we are CSV we need to get the assessment items
# since template::list  has been prepared at this point we need
# to add columns to the multirow manually and output manually
# instead of template::list::write_csv

if {$csv_p == 1} {
    set csv_cols {}
    lappend csv_cols unique_id applicant_user_id section_id completed_datetime
    set csv_cols_labels(completed_datetime) "Application Date"
    set csv_cols_labels(unique_id) "Unique_ID"

    set csv_cols_labels(applicant_user_id) "User_ID"
    set csv_cols_labels(section_id) "Section_ID"
    set all_cols [list "section_name" "number" "person_name" "member_state" "phone" "comments_text_plain"]
    template::list::get_reference -name applications
    set __list_name applications
    foreach __element_name $all_cols {
        template::list::element::get_reference  -list_name $__list_name  -element_name $__element_name  -local_name __element_properties
	if {!$__element_properties(hide_p)} {
	    lappend csv_cols $__element_name
	    set csv_cols_labels($__element_name) $__element_properties(label)
	}
    }

    lappend csv_cols "attendance" "num_sessions"
    set csv_cols_labels(attendance) attendance
    set csv_cols_labels(num_sessions) "number of sessions"
#    template::multirow extend applications attendance num_sessions
    set csv_as_item_list [list]
    set assessment_rev_id_list [list]
    set item_list [list]

    # first pass -- extend the multirow
    template::multirow foreach applications {
        if {![empty_string_p $session_id]} {
	    set assessment_rev_id [db_string get_latest_rev {
		select i.latest_revision
		from cr_revisions r,
		     cr_items i,
		     as_sessions s
		where s.session_id = :session_id
		      and r.revision_id = s.assessment_id
		      and i.item_id = r.item_id
	    }]
	    
	    if {[lsearch $assessment_rev_id_list $assessment_rev_id] == -1} {
		# get the questions for this assessment
		db_foreach get_items {
		    select cr.title, 
		           cr.description, 
		           o.object_type, 
		           i.data_type, 
		           i.field_name,
		           cr.item_id as as_item_item_id, 
		           rs.item_id as section_item_id
		    from as_assessment_section_map asm, 
		         as_item_section_map ism, 
		         cr_revisions cr,

		         as_items i, 
		         as_item_rels ir, 
		         acs_objects o, 
		         cr_revisions rs
		    where asm.assessment_id = :assessment_rev_id
		          and ism.section_id = asm.section_id
		          and cr.revision_id = ism.as_item_id
		          and i.as_item_id = ism.as_item_id
		          and ir.item_rev_id = i.as_item_id
		          and ir.rel_type = 'as_item_type_rel'
		          and o.object_id = ir.target_rev_id
		          and rs.revision_id = ism.section_id
		    order by asm.sort_order, 
		          ism.sort_order
		} {
		    if {[lsearch $csv_cols $as_item_item_id] == -1} {
			set csv_cols_labels($as_item_item_id) $title
			template::multirow extend applications $as_item_item_id
			lappend csv_cols $as_item_item_id
			lappend item_list [list $as_item_item_id $section_item_id [string range $object_type end-1 end] $data_type]
		    }
		}
		# add his assessment revision to the list 
		# so that we dont query it again
		lappend assessment_rev_id_list $assessment_rev_id
	    }

	    foreach one_item $item_list {
	       
		util_unlist $one_item as_item_item_id section_item_id item_type data_type
		if {![array exists results_${as_item_item_id}]} {
		    array set results_${as_item_item_id} [as::item_type_$item_type\::results -as_item_item_id $as_item_item_id -section_item_id $section_item_id -data_type $data_type -sessions $csv_session_ids]		    
		}
		if {[info exists results_${as_item_item_id}($session_id)]} {
		    set $as_item_item_id [set results_${as_item_item_id}($session_id)]
		} else {
		    set $as_item_item_id ""
		}
		
		array unset results
	    }
        }
	# attendance data
	if { $num_sessions == 0 } { set attendance_rate "0" } else  { set attendance_rate [format "% .0f" [expr (${attendance}.0/$num_sessions)*100]] }

    }
    
    
    set __output {}
    set __cols [list]

    # output the headers
    foreach __col_name $csv_cols {
        lappend __cols [template::list::csv_quote $csv_cols_labels($__col_name)]
    }
    append __output "\"[join $__cols "\",\""]\"\n"

    # second pass - write out the data
    template::multirow foreach applications {

        set __cols [list]

        foreach __col_name $csv_cols {
            lappend __cols [template::list::csv_quote [set $__col_name]]
        }
        append __output "\"[join $__cols "\",\""]\"\n"
    }

    # do not cache csv exports
    ns_set put [ns_conn outputheaders] "Cache-Control" "private"
    ns_set put [ns_conn outputheaders] "Expires" "Thu, 01 Jan 1998 07:00:00 GMT"

    # force to download and set type and filename
    set title "applications_[ns_fmttime [ns_time] "%Y%m%d_%H%M"].csv"
    ns_set put [ns_conn outputheaders] "Content-Disposition" "attachment; filename=$title"

    ns_return 200 "text/x-csv" $__output
    ad_script_abort
}

set applications_session_ids $csv_session_ids
set assessment_id_list [list]
if {[info exists filter_assessments]} {
    foreach elm $filter_assessments {
	lappend assessment_id_list [lindex $elm 1]
    }
}
set summary_url [export_vars -base /assessment/asm-admin/item-stats {{session_id_list $applications_session_ids} {return_url [ad_return_url]} assessment_id_list}]