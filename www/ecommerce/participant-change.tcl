# packages/dotlrn-ecommerce/www/ecommerce/participant-change.tcl

ad_page_contract {
    
    Select participant for ordinary users
    
    @author  (mgh@localhost.localdomain)
    @creation-date 2005-07-08
    @arch-tag: f24b7927-abe0-463d-bcd0-a96b6c6b5cdb
    @cvs-id $Id$
} {
    product_id:integer,notnull,optional
    next_url:optional
    return_url:optional
} -properties {
} -validate {
} -errors {
}

set patron_id [ad_conn user_id]

if { $patron_id == 0 } {
    ad_returnredirect [export_vars -base login { {return_url "[ad_return_url]"} }]
    ad_script_abort
}

if { [exists_and_not_null product_id] } {
    # Check if the section is full and if it allows waiting lists
    db_1row section_info {
	select section_id, community_id
	from dotlrn_ecommerce_section
	where product_id = :product_id
    }

if { [exists_and_not_null product_id] } {
#     db_1row order {
# 	select user_id,
# 	participant_id
# 	from dotlrn_ecommerce_orders
# 	where item_id = :item_id
#     }
    
    template::list::create \
	-name "relations" \
	-multirow "relations" \
	-no_data "No related users" \
	-elements {
	    ruser {
		label "Related User"
	    }
	    email {
		label "Email"
	    }
	    actions {
		label ""
		display_template {
		    <if @relations.member_state@ eq "approved">
		    Already Participating
		    </if>
		    <else>
		    <if @relations.member_state@ eq "">
		    <a href="@relations.participant_change_url;noquote@" class="button">[_ dotlrn-ecommerce.Choose_Participant]</a>
		    </if>
		    <else>
		    Application Pending
		    </else>
		    </else>
		}
	    }
	}

    set locale [ad_conn locale]
    db_multirow -extend { participant_change_url } relations relations {
	select *
	from (
	      select u.first_names||' '||u.last_name as ruser, u.user_id, u.email,
	      (select m.member_state
	       from acs_rels r,
	       membership_rels m
	       where r.rel_id = m.rel_id
	       and r.object_id_one = :community_id
	       and r.object_id_two = u.user_id) as member_state 
	      from acs_rels r, dotlrn_users u
	      where r.object_id_two = u.user_id
	      and r.rel_type = 'patron_rel'
	      and r.object_id_one = :patron_id

	      union

	      select u.first_names||' '||u.last_name as ruser, u.user_id, u.email,
	      (select m.member_state
	       from acs_rels r,
	       membership_rels m
	       where r.rel_id = m.rel_id
	       and r.object_id_one = :community_id
	       and r.object_id_two = u.user_id) as member_state 
	      from acs_rels r, dotlrn_users u
	      where r.object_id_one = u.user_id
	      and r.rel_type = 'patron_rel'
	      and r.object_id_two = :patron_id
	      and not r.object_id_one in (select object_id_two
					  from acs_rels r
					  where rel_type = 'patron_rel'
					  and object_id_one = :patron_id)
	      ) r
	where not ruser is null
    } {
	set participant_change_url [export_vars -base participant-change-2 { product_id user_id patron_id return_url }]
    }

    set next_url [export_vars -base participant-change-2 { product_id patron_id return_url {new_user_p 1} }]
    set patron_name [person::name -person_id $patron_id]
    set participant_pays_url [export_vars -base participant-change-2 { product_id {user_id $patron_id} patron_id return_url }]
    set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]

    set member_state [db_string awaiting_approval {
	select m.member_state
	from acs_rels r,
	membership_rels m
	where r.rel_id = m.rel_id
	and r.object_id_one = :community_id
	and r.object_id_two = :patron_id
	limit 1
    } -default ""]
}
