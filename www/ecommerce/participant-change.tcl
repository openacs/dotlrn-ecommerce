# packages/dotlrn-ecommerce/www/ecommerce/participant-change.tcl

ad_page_contract {
    
    Select participant for ordinary users
    
    @author  (mgh@localhost.localdomain)
    @creation-date 2005-07-08
    @arch-tag: f24b7927-abe0-463d-bcd0-a96b6c6b5cdb
    @cvs-id $Id$
} {
    item_id:integer,notnull,optional
} -properties {
} -validate {
} -errors {
}

if { [exists_and_not_null item_id] } {
    db_1row order {
	select patron_id,
	participant_id
	from dotlrn_ecommerce_orders
	where item_id = :item_id
    }

    template::list::create \
	-name "relations" \
	-multirow "relations" \
	-no_data "No related users" \
	-pass_properties participant_id \
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
		    <if @participant_id@ eq @relations.user_id@>
		    [_ dotlrn-ecommerce.Currently_Selected]
		    </if>
		    <else>
		    <a href="@relations.participant_change_url;noquote@" class="button">[_ dotlrn-ecommerce.Choose_Participant]</a>
		    </else>
		}
	    }
	}

    set locale [ad_conn locale]
    db_multirow -extend { participant_change_url } relations relations {
	select *
	from (
	      select u.first_names||' '||u.last_name as ruser, u.user_id, u.email
	      from acs_rels r, dotlrn_users u
	      where r.object_id_two = u.user_id
	      and r.rel_type = 'patron_rel'
	      and r.object_id_one = :patron_id

	      union

	      select u.first_names||' '||u.last_name as ruser, u.user_id, u.email
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
	set participant_change_url [export_vars -base participant-change-2 { item_id user_id patron_id }]
    }
}

set next_url [export_vars -base participant-change-2 { item_id patron_id }]
set patron_name [person::name -person_id $patron_id]
set participant_pays_url [export_vars -base participant-change-2 { item_id {user_id $patron_id} patron_id}]
set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]
