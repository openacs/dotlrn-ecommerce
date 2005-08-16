# packages/dotlrn-ecommerce/www/applications2.tcl

ad_page_contract {
    
    List of pending and approved applications
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-07-23
    @arch-tag: 7d7789ef-523a-40dc-aa32-c650e19ece40
    @cvs-id $Id$
} {
    type:optional
    orderby:optional
    section_id:optional
    {csv_p 0}
} -properties {
} -validate {
} -errors {
}

### Add security checks

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]
set admin_p [permission::permission_p -object_id $package_id -privilege "admin"]
set return_url [ad_return_url]

set header_stuff {
    <script type="text/javascript" src="/resources/dotlrn-ecommerce/overlib/overlib.js">
    <!-- overLIB (c) Erik Bosrup (http://www.bosrup.com/web/overlib) -->
    </script>
}

set enable_applications_p [parameter::get -package_id [ad_conn package_id] -parameter EnableCourseApplicationsP -default 1]

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
	{"[_ dotlrn-ecommerce.Applications]" "awaiting payment"} \
	{"[_ dotlrn-ecommerce.lt_Approved_Applications]" "payment received"}
}

template::list::create \
    -name "applications" \
    -key rel_id \
    -multirow "applications" \
    -no_data "[_ dotlrn-ecommerce.No_applications]" \
    -pass_properties { return_url } \
    -page_flush_p 1 \
    -pass_properties { admin_p return_url _type } \
    -actions [list "[_ dotlrn-ecommerce.View_previously_email]" "sent-emails" "[_ dotlrn-ecommerce.View_previously_email]"] \
    -bulk_actions [list "[_ dotlrn-ecommerce.Email_applicants]" "email-applicants" "[_ dotlrn-ecommerce.Email_applicants]"] \
    -elements {
	section_name {
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
	    hide_p {[ad_decode $_type "waitinglist approved" 1 "request approved" 1 "payment received" 1 "all" 0 0]}
	    display_template {
		<if @applications.member_state@ in "needs approval" "request approval">
		@applications.number@
		</if>
		<elseif @applications.member_state@ eq "awaiting payment">
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
                <elseif @applications.member_state@ eq "payment received">
		[_ dotlrn-ecommerce.lt_User_application_appr]
                </elseif>
                <elseif @applications.member_state@ eq "waitinglist approved">
		[_ dotlrn-ecommerce.lt_User_approved_waiting]
                </elseif>
                <elseif @applications.member_state@ eq "request approved">
		[_ dotlrn-ecommerce.lt_User_has_approved_pre]
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
		<a href="@applications.asm_url;noquote@" class="button" target="_blank">[_ dotlrn-ecommerce.View]</a>
		</if>
		<else>
		N/A
		</else>
	    }
	    html { align center }
	}
	phone {
	    label "[_ dotlrn-ecommerce.Phone_Number]"
	    hide_p {[ad_decode $_type "waitinglist approved" 0 "request approved" 0 "payment received" 0 "all" 0 1]}
	}
	comments {
	    label "[_ dotlrn-ecommerce.Notes]"
	    display_template {
		@applications.comments_truncate;noquote@
		<if @applications.add_comment_url@ not nil>
		<a href="@applications.add_comment_url@" title="[_ dotlrn-ecommerce.Add_note]">[_ dotlrn-ecommerce.Add_note]</a>
		</if>
	    }
	}
	comments_text_plain {
	    label "[_ dotlrn-ecommerce.Notes]"
	    hide_p 1
	}
	actions {
	    label ""
	    display_template {
		<if @applications.member_state@ in "needs approval" "request approval" "awaiting payment">
		<a href="@applications.approve_url;noquote@" class="button">[_ dotlrn-ecommerce.Approve]</a>
		<a href="@applications.reject_url;noquote@" class="button">[_ dotlrn-ecommerce.Reject]</a>
		</if>
		<else>
		<a href="@applications.reject_url;noquote@" class="button">[_ dotlrn-ecommerce.Cancel]</a>
		<if @admin_p@>
		<a href="@applications.register_url;noquote@" class="button">[_ dotlrn-ecommerce.Register]</a>
		</if>
		</else>
	    }
	    html { width 125 align center nowrap }
	}
    } -filters [subst {
	type {
	    label "[_ dotlrn-ecommerce.Type_of_Request]"
	    values { $filters }
	    where_clause { member_state = :type }
	}
	section_id {}
	csv_p {
            label "[_ dotlrn-ecommerce.Export]"
            values {{"[_ dotlrn-ecommerce.CSV]" 1}}
	    has_default_p 1
        }
    }] -orderby {
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
			       and rel_type = 'dotlrn_admin_rel')
    }
}

if { [exists_and_not_null section_id] } {
    set section_clause {and s.section_id = :section_id}
} else {
    set section_clause ""
}

if { $enable_applications_p } {
    set member_state_clause { and member_state in ('needs approval', 'waitinglist approved', 'request approval', 'request approved', 'awaiting payment', 'payment received') }
} else {
    set member_state_clause { and member_state in ('needs approval', 'waitinglist approved', 'request approval', 'request approved') }
}

set general_comments_url [apm_package_url_from_key "general-comments"]

db_multirow -extend { approve_url reject_url asm_url section_edit_url person_url register_url comments comments_text_plain comments_truncate add_comment_url } applications applications [subst {
    select person__name(r.user_id) as person_name, member_state, r.community_id, r.user_id as applicant_user_id, s.section_name, t.course_name, s.section_id, r.rel_id, e.phone, o.creation_user as patron_id,
    (select count(*)
     from (select *
	   from dotlrn_member_rels_full rr,
	   acs_objects o
	   where rr.rel_id = o.object_id
	   and rr.rel_id <= r.rel_id
	   and rr.community_id = r.community_id
	   and rr.member_state = r.member_state
	   order by o.creation_date) r) as number
    from dotlrn_member_rels_full r
    left join (select *
	       from ec_addresses
	       where address_id in (select max(address_id)
				    from ec_addresses
				    group by user_id)) e
    on (r.user_id = e.user_id), dotlrn_ecommerce_section s, dotlrn_catalogi t, cr_items i, acs_objects o
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
    set list_type [ad_decode $member_state "needs approval" full "request approval" prereq "awaiting payment" payment full]

    set approve_url [export_vars -base application-approve { community_id {user_id $applicant_user_id} {type $list_type} return_url }]
    set reject_url [export_vars -base application-reject { community_id {user_id $applicant_user_id} {type $list_type} return_url }]
    
    if { $member_state == "needs approval" || 
	 $member_state == "awaiting payment" ||
	 $member_state == "waitinglist approved" ||
	 $member_state == "payment received"
     } {
	# Get associated assessment
	if { [db_0or1row assessment {
	    select ss.session_id 
	    from dotlrn_ecommerce_section des, 
	         dotlrn_catalog dc, 
	         cr_items i1, 
	         cr_items i2, 
	         cr_revisions r, 
	         as_sessions ss 
	    where des.community_id = :community_id 
	          and i1.item_id = des.course_id 
	          and i1.live_revision = dc.course_id 
	          and dc.assessment_id = i2.item_id 
	          and r.item_id = i2.item_id 
	          and r.revision_id = ss.assessment_id 
	          and ss.subject_id = :applicant_user_id
	    order by ss.creation_datetime desc
	    limit 1
	}] } {
	    set asm_url [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]asm-admin/results-session" { session_id }]
	}

    } elseif { $member_state == "request approval" ||
	       $member_state == "request approved" } {

	# Get associated assessment
	set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

	if { [db_0or1row assessment {
	    select ss.session_id

	    from (select a.*
		  from as_assessmentsi a,
		  cr_items i
		  where a.assessment_id = i.latest_revision) a,
	    as_sessions ss
	    
	    where a.assessment_id = ss.assessment_id
	    and a.item_id = :assessment_id
	    and ss.subject_id = (select creation_user from acs_objects where object_id = :rel_id)
	    
	    order by creation_datetime desc
	    
	    limit 1
	}] } {
	    set asm_url [export_vars -base "[apm_package_url_from_id [parameter::get -parameter AssessmentPackage]]asm-admin/results-session" { session_id }]
	}
    }

    set section_edit_url [export_vars -base admin/one-section { section_id return_url }]
    set person_url [export_vars -base /acs-admin/users/one { {user_id $applicant_user_id} }]
    set register_url [export_vars -base admin/process-purchase-course { section_id {user_id $patron_id} {participant_id $applicant_user_id} }]

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
            where g.object_id = :session_id
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
	    append comments_text_plain "${comments_text}\n"
	    append comments_truncate "<a href=\"javascript:void(0);\" onmouseover=\"return overlib('$comments');\" onmouseout=\"return nd();\" style=\"text-decoration: none;\">[ad_html_text_convert -from "text/plain" -to "text/html" -truncate_len 100 $comments_text]</a> \[<a href=\"$edit_comment_url\">edit</a>\]<br /><br />"
        }
	set add_comment_url [export_vars -base "${general_comments_url}comment-add" {{object_id $session_id} {object_name "Application"} return_url}]
    }

}

# if we are CSV we need to get the assessment items
# since template::list  has been prepared at this point we need
# to add columns to the multirow manually and output manually
# instead of template::list::write_csv

if {$csv_p == 1} {
    set csv_cols [list "section_name" "number" "person_name" "member_state" "phone" "comments_text_plain"]
    template::list::get_reference -name applications
    set __list_name applications
    foreach __element_name $csv_cols {
        template::list::element::get_reference  -list_name $__list_name  -element_name $__element_name  -local_name __element_properties
        set csv_cols_labels($__element_name) $__element_properties(label)
    }
    
    set csv_as_item_list [list]

    # first pass -- extend the multirow
    template::multirow foreach applications {
        if {![empty_string_p $session_id]} {
            db_foreach get_session_data {
                select a.as_item_id, 
                       case 
                          when o.object_type = 'as_item_type_mc' then cr.title 
                       else 
                          d.text_answer 
                       end as answer, 
                       cr2.title as question 
                from as_item_data d 
                         left join as_item_data_choices c on (d.item_data_id = c.item_data_id) 
                         left join cr_revisions cr on (c.choice_id = cr.revision_id), 
                     as_items a, 
                     acs_objects o, 
                     as_item_rels r, 
                     cr_revisions cr2,
                     as_session_item_map m 
                where d.as_item_id = a.as_item_id 
                      and a.as_item_id = r.item_rev_id 
                      and r.target_rev_id = o.object_id 
                      and r.rel_type = 'as_item_type_rel' 
                      and cr2.revision_id = a.as_item_id 
                      and m.session_id = :session_id
                      and d.item_data_id = m.item_data_id
            } {
                if {[lsearch $csv_as_item_list $as_item_id] == -1} {
                    lappend csv_as_item_list $as_item_id
                    template::multirow extend applications $as_item_id
                    set csv_cols_labels($as_item_id) $question
                    lappend csv_cols $as_item_id
                }
                set $as_item_id $answer
            }
        }
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
