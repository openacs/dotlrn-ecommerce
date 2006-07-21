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
	    section_id:optional \
	    {csv_p 0} \
	    {as_item_id ""} \
	    {as_search ""} \
	    ] \
       [as::list::params]]

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]
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
    type {
	label "[_ dotlrn-ecommerce.Type_of_Request]"
	values { $filters }
	where_clause { member_state = :type }
    }
}]

set actions ""
set bulk_actions [list [_ dotlrn-ecommerce.Approve] application-bulk-approve [_ dotlrn-ecommerce.Approve] "[_ dotlrn-ecommerce.Reject] / [_ dotlrn-ecommerce.Cancel]" application-bulk-reject "[_ dotlrn-ecommerce.Reject] / [_ dotlrn-ecommerce.Cancel]"]

if {[parameter::get -parameter AllowApplicationBulkEmail -default 0]} {
    set actions [list "[_ dotlrn-ecommerce.View_previously_email]" "sent-emails" "[_ dotlrn-ecommerce.View_previously_email]"]
    lappend bulk_actions "[_ dotlrn-ecommerce.Email_applicants]" "email-applicants" "[_ dotlrn-ecommerce.Email_applicants]"
}

if { ![exists_and_not_null section_id] || [dotlrn_ecommerce::section::price $section_id] > 0.01 } {
    lappend bulk_actions "[_ dotlrn-ecommerce.Mark_as_Paid]" application-bulk-payments "[_ dotlrn-ecommerce.Mark_as_Paid]"
}

set elements {section_name {
	    label "[_ dotlrn-ecommerce.Section]"
	    display_template {
		<if @admin_p@>
		<a href="@applications.section_edit_url;noquote@">@applications.course_name@: @applications.section_name@</a>
		</if>
		<else>
		@applications.course_name@: @applications.section_name@
		</else>
	    }
	}
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
	}
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
	}
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
	}
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
	}
	phone {
	    label "[_ dotlrn-ecommerce.Phone_Number]"
	    hide_p {[ad_decode $_type "waitinglist approved" 0 "request approved" 0 "application approved" 0 "all" 0 1]}
	}
}

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
	    html { width 125 align center nowrap }
	}

if { [exists_and_not_null section_id] } {
    set section_clause {and s.section_id = :section_id}

    if { [db_0or1row assessment_revision {
	select a.title, a.assessment_id as section_assessment_rev_id
	from dotlrn_ecommerce_section s, dotlrn_catalogi c, as_assessmentsi a, cr_items ci, cr_items ai
	where s.course_id = c.item_id
	and c.assessment_id = a.item_id
	and c.course_id = ci.latest_revision
	and a.assessment_id = ai.latest_revision
	and s.section_id = :section_id
    }] } {
	array set search_arr [as::list::filters -assessments [list [list $title $section_assessment_rev_id]]]
    } else {
	array set search_arr [list list_filters [list] assessment_search_options [list] search_js_array ""]
    }
} else {
    set section_clause ""
    # we want to get all the questions that are common to dotlrn-ecommerce 
    # applications
    set filter_assessments [db_list_of_lists get_filter_assessments "
select distinct a.title, a.revision_id as assessment_id from dotlrn_catalog c, cr_items i, as_assessmentsx a where i.item_id=c.assessment_id and i.latest_revision=a.revision_id"]

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

lappend actions \
    [_ dotlrn-ecommerce.Export] \
    [export_vars -base [ad_return_url] { {csv_p 1} }] \
    [_ dotlrn-ecommerce.Export]
    

template::list::create \
    -name "applications" \
    -key rel_id \
    -multirow "applications" \
    -no_data "[_ dotlrn-ecommerce.No_applications]" \
    -pass_properties { return_url } \
    -page_flush_p 1 \
    -pass_properties { admin_p return_url _type } \
    -actions $actions \
    -bulk_actions $bulk_actions \
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

db_multirow -extend { approve_url reject_url asm_url section_edit_url person_url register_url comments comments_text_plain comments_truncate add_comment_url target calendar_id item_type_id num_sessions } applications applications [subst {
    select person__name(r.user_id) as person_name, member_state, r.community_id, r.user_id as applicant_user_id, s.section_name, t.course_name, s.section_id, r.rel_id, e.phone, o.creation_user as patron_id,
    (select count(*)
     from (select *
	   from dotlrn_member_rels_full rr,
	   acs_objects o
	   where rr.rel_id = o.object_id
	   and rr.rel_id <= r.rel_id
	   and rr.community_id = r.community_id
	   and rr.member_state = r.member_state
	   order by o.creation_date) r) as number, s.product_id, m.session_id, m.completed_datetime

    from dotlrn_member_rels_full r
    left join (select *
	       from ec_addresses
	       where address_id in (select max(address_id)
				    from ec_addresses
				    group by user_id)) e
    on (r.user_id = e.user_id)
    left join (select m.*, s.completed_datetime
	       from dotlrn_ecommerce_application_assessment_map m, as_sessions s
	       where m.session_id = s.session_id
	       and m.session_id in (select max(session_id)
				    from dotlrn_ecommerce_application_assessment_map
				    group by rel_id)) m
    on (r.rel_id = m.rel_id), 
    dotlrn_ecommerce_section s
    left join ec_products p
    on (s.product_id = p.product_id),
    dotlrn_catalogi t,
    cr_items i,
    acs_objects o

    where r.community_id = s.community_id
    and s.course_id = t.item_id
    and t.course_id = i.live_revision
    and r.rel_id = o.object_id

    $member_state_clause
    $user_clause
    $section_clause

    [template::list::filter_where_clauses -and -name applications]
    [template::list::orderby_clause -name applications -orderby]         
}] {
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
        db_foreach get_comments {
            select g.comment_id,
                   r.content as gc_content,
                   r.title as gc_title,
	           r.mime_type as gc_mime_type,
                   acs_object__name(o.creation_user) as gc_author,
                   to_char(o.creation_date, 'YYYY-MM-DD HH24:MI:SS') as gc_creation_date_ansi
            from general_comments g,
                 cr_revisions r,
                 cr_items ci,
                 acs_objects o
            where g.object_id in (select session_id
                                  from as_sessions
                                  where assessment_id = (select assessment_id 
							 from as_sessions 
							 where session_id =  :session_id)
				        and subject_id = :applicant_user_id)
                  and r.revision_id = ci.live_revision
                  and ci.item_id = g.comment_id 
                  and o.object_id = g.comment_id
            order by o.creation_date
        } {
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
}

# if we are CSV we need to get the assessment items
# since template::list  has been prepared at this point we need
# to add columns to the multirow manually and output manually
# instead of template::list::write_csv

if {$csv_p == 1} {
    set csv_cols {}
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

    lappend csv_cols "attendance" "attendance_rate"
    set csv_cols_labels(attendance) attendance
    set csv_cols_labels(attendance_rate) "attendance rate"
    template::multirow extend applications attendance attendance_rate
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
                    set csv_cols_labels($as_item_item_id) $title
                    template::multirow extend applications $as_item_item_id
                    lappend csv_cols $as_item_item_id
		    lappend item_list [list $as_item_item_id $section_item_id [string range $object_type end-1 end] $data_type]
		}
		# add his assessment revision to the list 
		# so that we dont query it again
		lappend assessment_rev_id_list $assessment_rev_id
	    }

	    foreach one_item $item_list {
		util_unlist $one_item as_item_item_id section_item_id item_type data_type
		array set results [as::item_type_$item_type\::results -as_item_item_id $as_item_item_id -section_item_id $section_item_id -data_type $data_type -sessions [list $session_id]]
	    
		if {[info exists results($session_id)]} {
		    set $as_item_item_id $results($session_id)
		} else {
		    set $as_item_item_id ""
		}
		
		array unset results
	    }
        }
	# attendance data
	set attendance [db_string "count" "select count(user_id) from attendance_cal_item_map where user_id = :applicant_user_id and cal_item_id in (select cal_item_id from cal_items where on_which_calendar = :calendar_id and item_type_id = :item_type_id )" ]
	if { $num_sessions == 0 } { set attendance_rate "0" } else  { set attendance_rate [format "% .0f" [expr (${attendance}.0/$num_sessions)*100]] }
	set attendance "${attendance}/${num_sessions}"

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