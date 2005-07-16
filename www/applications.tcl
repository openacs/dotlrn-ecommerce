# packages/dotlrn-ecommerce/www/admin/applications.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-23
    @arch-tag: 47e50b22-750a-4337-98ed-747058310624
    @cvs-id $Id$
} {
    {type "pending"}
} -properties {
} -validate {
} -errors {
}

set user_id [ad_conn user_id]

set cc_package_id [apm_package_id_from_key "dotlrn-catalog"]
set admin_p [permission::permission_p -object_id $cc_package_id -privilege "admin"]


if { $type == "pending" } {
    template::list::create \
	-name "applications" \
	-multirow "applications" \
	-no_data "No pending applications" \
	-page_flush_p 1 \
	-elements {
	    community_name {
		label "Section"
	    }
	    person_name {
		label "Participant"
	    }
	    member_state {
		label "Member Request"
		display_template {
		    User is in waiting list
		}
	    }
	    assessment_result {
		label "Application"
		display_template {
		    <if @applications.asm_url@ not nil>
		    <a href="@applications.asm_url;noquote@" class="button" target="_blank">View</a>
		    </if>
		    <else>
		    N/A
		    </else>
		}
		html { align center }
	    }
	    actions {
		label ""
		display_template {
		    <a href="@applications.approve_url;noquote@" class="button">Approve</a>
		    <a href="@applications.reject_url;noquote@" class="button">Reject</a>
		}
		html { align center }
	    }
	}
    
    db_multirow -extend { approve_url reject_url asm_url } applications applications {
	select pretty_name as community_name, person__name(user_id) as person_name, member_state, c.community_id, user_id as applicant_user_id
	from dotlrn_member_rels_full r, dotlrn_communities_all c
	where r.community_id = c.community_id
	and member_state = 'needs approval'
    } {
	set approve_url [export_vars -base application-approve { community_id {user_id $applicant_user_id} }]
	set reject_url [export_vars -base application-reject { community_id {user_id $applicant_user_id} }]
	
	# Get associated assessment
	if { [db_0or1row assessment {
	    select ss.session_id
	    
	    from dotlrn_ecommerce_section s,
	    (select c.*
	     from dotlrn_catalogi c,
	     cr_items i
	     where c.course_id = i.live_revision) c,
	    (select a.*
	     from as_assessmentsi a,
	     cr_items i
	     where a.assessment_id = i.latest_revision) a,
	    as_sessions ss
	    
	    where s.community_id = :community_id
	    and s.course_id = c.item_id
	    and c.assessment_id = a.item_id
	    and a.assessment_id = ss.assessment_id
	    and ss.subject_id = :user_id
	    
	    order by creation_datetime desc
	    
	    limit 1
	}] } {
	    set asm_url [export_vars -base /assessment/asm-admin/results-session { session_id }]
	}
    }

    template::list::create \
	-name "approved_applications" \
	-multirow "approved_applications" \
	-no_data "No approved applications" \
	-page_flush_p 1 \
	-elements {
	    community_name {
		label "Section"
	    }
	    person_name {
		label "Participant"
	    }
	    phone {
		label "Phone Number"
	    }
	    actions {
		label ""
		display_template {
		    <a href="@approved_applications.reject_url;noquote@" class="button">Cancel</a>
		}
		html { align center }
	    }
	}
    
    db_multirow -extend { approve_url reject_url asm_url } approved_applications approved_applications {
	select pretty_name as community_name, person__name(r.user_id) as person_name, c.community_id, r.user_id as applicant_user_id, e.phone
	from dotlrn_member_rels_full r
	left join (select *
		   from ec_addresses
		   where address_id in (select max(address_id)
					from ec_addresses
					group by user_id)) e
	on (r.user_id = e.user_id), dotlrn_communities_all c
	where r.community_id = c.community_id
	and member_state = 'waitinglist approved'
    } {
	set reject_url [export_vars -base application-reject { community_id {user_id $applicant_user_id} {send_email_p 0} }]
    }
}

template::list::create \
    -name "for_approval" \
    -multirow "for_approval" \
    -no_data "No requests for approval" \
    -page_flush_p 1 \
    -elements {
	community_name {
	    label "Section"
	}
	person_name {
	    label "Participant"
	}
	member_state {
	    label "Member Request"
	    display_template {
		User is holding a spot and waiting for approval
	    }
	}
	assessment_result {
	    label "Application"
	    display_template {
		<if @for_approval.asm_url@ not nil>
		<a href="@for_approval.asm_url;noquote@" class="button" target="_blank">View</a>
		</if>
		<else>
		N/A
		</else>
	    }
	    html { align center }
	}
	actions {
	    label ""
	    display_template {
		<a href="@for_approval.approve_url;noquote@" class="button">Approve</a>
		<a href="@for_approval.reject_url;noquote@" class="button">Reject</a>
	    }
	    html { align center }
	}
    }

if { $admin_p } {
    set user_clause ""
} else {
    set user_clause {
	and c.community_id in (select community_id
			       from dotlrn_member_rels_full
			       where user_id = :user_id
			       and rel_type = 'dotlrn_admin_rel')
    }
}

db_multirow -extend { approve_url reject_url asm_url } for_approval for_approval [subst {
    select pretty_name as community_name, 
    person__name(user_id) as person_name, 
    member_state, 
    c.community_id, 
    user_id,
    r.rel_id
    from dotlrn_member_rels_full r, dotlrn_communities_all c
    where r.community_id = c.community_id
    and member_state = 'request approval'

    $user_clause
}] {
    set approve_url [export_vars -base application-approve { community_id user_id {type prereq} }]
    set reject_url [export_vars -base application-reject { community_id user_id {type prereq} }]

    # Get associated assessment
    set assessment_id [parameter::get -parameter ApplicationAssessment -default ""]

    if { [db_0or1row assessment {
	select ss.session_id

	from
	(select a.*
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
	set asm_url [export_vars -base /assessment/asm-admin/results-session { session_id }]
    }
}

template::list::create \
    -name "approved_applications_prereq" \
    -multirow "approved_applications_prereq" \
    -no_data "No approved applications" \
    -page_flush_p 1 \
    -elements {
	community_name {
	    label "Section"
	}
	person_name {
	    label "Participant"
	}
	phone {
	    label "Phone Number"
	}
	actions {
	    label ""
	    display_template {
		<a href="@approved_applications_prereq.reject_url;noquote@" class="button">Cancel</a>
	    }
	    html { align center }
	}
    }

db_multirow -extend { approve_url reject_url asm_url } approved_applications_prereq approved_applications_prereq {
    select pretty_name as community_name, person__name(r.user_id) as person_name, c.community_id, r.user_id as applicant_user_id, e.phone, (current_timestamp - o.creation_date)::interval as elapsed_time
    from acs_objects o, dotlrn_member_rels_full r
    left join (select *
	       from ec_addresses
	       where address_id in (select max(address_id)
				    from ec_addresses
				    group by user_id)) e
    on (r.user_id = e.user_id), dotlrn_communities_all c
    where o.object_id = r.rel_id
    and r.community_id = c.community_id
    and member_state = 'request approved'
} {
    set reject_url [export_vars -base application-reject { community_id {user_id $applicant_user_id} {send_email_p 0} }]
}
