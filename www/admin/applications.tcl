# packages/dotlrn-ecommerce/www/admin/applications.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-23
    @arch-tag: 47e50b22-750a-4337-98ed-747058310624
    @cvs-id $Id$
} {

} -properties {
} -validate {
} -errors {
}

template::list::create \
    -name "applications" \
    -multirow "applications" \
    -no_data "No pending applications" \
    -elements {
	community_name {
	    label "Section"
	}
	person_name {
	    label "Participant"
	}
	member_state {
	    label "Member State"
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
	    }
	    html { align center }
	}
    }

db_multirow -extend { approve_url asm_url } applications applications {
    select pretty_name as community_name, person__name(user_id) as person_name, member_state, c.community_id, user_id
    from dotlrn_member_rels_full r, dotlrn_communities_all c
    where r.community_id = c.community_id
    and member_state = 'needs approval'
} {
    set approve_url [export_vars -base application-approve { community_id user_id }]

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