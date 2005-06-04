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
	relationship {
	    label Relationship
	    display_template {
		@patrons.relationship;noquote@
	    }
	}
	patron {
	    label "Related User"
	    display_template {
		<if @patrons.phone@ not nil>
		@patrons.patron@<br />Phone: @patrons.phone@
		</if>
		<else>
		@patrons.patron@
		</else>
	    }
	}
	patron_p {
	    label "Patron for this Section"
	    display_template {
		<if @patrons.patron_p@ not nil>
		Yes
		</if>
	    }
	    html { align center }
	}
    }

db_multirow -extend { relationship } patrons patrons {
    select rels.rel_id, rels.patron_rel_id, rels.participant, rels.patron, rels.direction, r.rel_id as patron_p, a.phone
    from (

	  select d.rel_id, 
	  r.rel_id as patron_rel_id,
	  (select first_names||' '||last_name||' ('||email||')' from dotlrn_users where user_id = d.user_id) as participant, 
	  (select first_names||' '||last_name||' ('||email||')' from dotlrn_users where user_id = r.object_id_two) as patron,
	  1 as direction,
	  d.community_id,
	  r.object_id_two as patron_id
	  from acs_rels r, dotlrn_member_rels_full d
	  where r.object_id_one = d.user_id
	  and r.rel_type = 'patron_rel'
	  and d.community_id = (select community_id
				from dotlrn_ecommerce_section
				where section_id = :section_id)

	  union
	  
	  select d.rel_id,
	  r.rel_id as patron_rel_id,
	  (select first_names||' '||last_name||' ('||email||')' from dotlrn_users where user_id = d.user_id) as participant,
	  (select first_names||' '||last_name||' ('||email||')' from dotlrn_users where user_id = r.object_id_one) as patron,
	  2 as direction,
	  d.community_id,
	  r.object_id_one as patron_id
	  from acs_rels r, dotlrn_member_rels_full d
	  where r.object_id_two = d.user_id
	  and r.rel_type = 'patron_rel'
	  and d.community_id = (select community_id
				from dotlrn_ecommerce_section
				where section_id = :section_id)
	  and not r.object_id_one in (select r.object_id_two
				      from acs_rels r, dotlrn_member_rels_full d
				      where r.object_id_one = d.user_id
				      and r.rel_type = 'patron_rel'
				      and d.community_id = (select community_id
							    from dotlrn_ecommerce_section
							    where section_id = :section_id))

) rels left join acs_rels r
on (rels.rel_id = r.object_id_one and r.rel_type = 'membership_patron_rel' and rels.patron_id = r.object_id_two)
left join ec_addresses a
on (r.object_id_two = a.user_id)

    order by lower(rels.participant)
} {
    foreach category [category::get_mapped_categories $patron_rel_id] {
	lappend relationship [category::get_name $category]
    }

    set relationship [join $relationship ", "]

    if { $direction == 1 } {
	set relationship "$relationship <big>&raquo;</big>"
    } else {
	set relationship "&laquo; $relationship"
    }
}

db_1row get_section_info "select c.course_id, s.section_name
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items ci
    where s.course_id = c.item_id
    and ci.live_revision=c.revision_id
    and s.section_id = :section_id"

set context [list [list [export_vars -base course-info { course_id }] $section_name] "Participants and Patrons"]
