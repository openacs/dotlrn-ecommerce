# packages/dotlrn-ecommerce/www/admin/patrons.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-05-28
    @arch-tag: cfc996c0-7de4-40d1-88a3-f0eadf2a3fdc
    @cvs-id $Id$
} {
    section_id:integer,notnull
} -properties {
} -validate {
} -errors {
}

template::list::create \
    -name "patrons" \
    -multirow "patrons" \
    -elements {
	participant {
	    label Participant
	}
	patron {
	    label Patron
	}
	relationship {
	    label Relationship
	}
    }

db_multirow -extend { relationship } patrons patrons {
    select r.rel_id, person__name(d.user_id) as participant, person__name(r.object_id_two) as patron
    from acs_rels r, dotlrn_member_rels_full d
    where r.object_id_one = d.user_id
    and r.rel_type = 'patron_rel'
    and d.community_id = (select community_id
			  from dotlrn_ecommerce_section
			  where section_id = :section_id)
} {
    foreach category [category::get_mapped_categories $rel_id] {
	lappend relationship [category::get_name $category]
    }

    set relationship [join $relationship ", "]
}

db_1row get_section_info "select c.course_id, s.section_name
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

set context [list [list [export_vars -base course-info { course_id }] $section_name] "Participants and Patrons"]
