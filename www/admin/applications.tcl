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
		&lt;link to asessment result&gt;
		<br />Open in new window
	    }
	}
	actions {
	    label ""
	    display_template {
		<a href="@applications.approve_url;noquote@" class="button">Approve</a>
	    }
	}
    }

db_multirow -extend { approve_url } applications applications {
    select pretty_name as community_name, person__name(user_id) as person_name, member_state, c.community_id, user_id
    from dotlrn_member_rels_full r, dotlrn_communities_all c
    where r.community_id = c.community_id
    and member_state = 'needs approval'
} {
    set approve_url [export_vars -base application-approve { community_id user_id }]
}