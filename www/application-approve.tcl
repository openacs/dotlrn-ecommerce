# packages/dotlrn-ecommerce/www/admin/application-approve.tcl

ad_page_contract {
    
    
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-06-23
    @arch-tag: 93f47ba6-c04e-419a-bcd6-60bb95553236
    @cvs-id $Id$
} {
    community_id:integer,notnull
    user_id:integer,notnull
    {type full}
    {return_url "applications"}
} -properties {
} -validate {
} -errors {
}

### Check for security

switch $type {
    full {
	set new_member_state "waitinglist approved"
	set old_member_state "needs approval"
    }
    prereq {
	set new_member_state "request approved"
	set old_member_state "request approval"

    }
    payment {
	set new_member_state "payment received"
	set old_member_state "awaiting payment"
    }
}

set actor_id [ad_conn user_id]
set section_id [db_string section {
    select section_id
    from dotlrn_ecommerce_section
    where community_id = :community_id
}]

dotlrn_ecommerce::section::flush_cache $section_id

if { $user_id == $actor_id } {

    db_transaction {
	set rels [db_list rels {
	    select r.rel_id
	    from acs_rels r,
	    membership_rels m
	    where r.rel_id = m.rel_id
	    and r.object_id_one = :community_id
	    and r.object_id_two = :user_id
	    and m.member_state = :old_member_state
	}]

	db_dml approve_request [subst {
	    update membership_rels
	    set member_state = :new_member_state
	    where rel_id in ([join $rels ,])
	}]

	db_dml update_objects [subst {
	    update acs_objects
	    set last_modified = current_timestamp
	    where object_id in ([join $rels ,])
	}]
    } on_error {
    }

    ad_returnredirect $return_url
} else {
    if { $type == "prereq" } {
        ad_form \
            -name email_form \
	    -export { application_type } \
            -form {
                {user_id:text(hidden)}
                {community_id:text(hidden)}
                {type:text(hidden)}
                {reason:text(textarea),optional {label "[_ dotlrn-ecommerce.Reason]"} {html {rows 10 cols 60}}}
            } \
            -on_request {
            } \
            -on_submit {
		db_transaction {
		    set rels [db_list rels {
			select r.rel_id
			from acs_rels r,
			membership_rels m
			where r.rel_id = m.rel_id
			and r.object_id_one = :community_id
			and r.object_id_two = :user_id
			and m.member_state = :old_member_state
		    }]

		    db_dml approve_request [subst {
			update membership_rels
			set member_state = :new_member_state
			where rel_id in ([join $rels ,])
		    }]

		    db_dml update_objects [subst {
			update acs_objects
			set last_modified = current_timestamp
			where object_id in ([join $rels ,])
		    }]
		} on_error {
		}

                set applicant_email [cc_email_from_party $user_id]
                set actor_email [cc_email_from_party $actor_id]
                set community_name [dotlrn_community::get_community_name $community_id]
                set subject "[_ dotlrn-ecommerce.Application_prereq_approved]"
                set body "[_ dotlrn-ecommerce.lt_Your_prereq_approved]"
                if {![empty_string_p [string trim $reason]]} {
                    append body "
[_ dotlrn-ecommerce.Reason]:
[string trim $reason]"
                }
                acs_mail_lite::send \
                    -to_addr $applicant_email \
                    -from_addr $actor_email \
                    -subject $subject \
                    -body $body
            } \
            -after_submit {
                ad_returnredirect $return_url
            }

    } else {
db_transaction {
    set rels [db_list rels {
	select r.rel_id
	from acs_rels r,
	membership_rels m
	where r.rel_id = m.rel_id
	and r.object_id_one = :community_id
	and r.object_id_two = :user_id
	and m.member_state = :old_member_state
    }]

    db_dml approve_request [subst {
	update membership_rels
	set member_state = :new_member_state
	where rel_id in ([join $rels ,])
    }]

    db_dml update_objects [subst {
	update acs_objects
	set last_modified = current_timestamp
	where object_id in ([join $rels ,])
    }]
} on_error {
}

# Send email to applicant
set applicant_email [cc_email_from_party $user_id]
set actor_email [cc_email_from_party $actor_id]
set community_name [dotlrn_community::get_community_name $community_id]

# could be from waiting list 
if {$new_member_state eq "waitinglist approved"} {
    # site wide template
    acs_mail_lite::send \
        -to_addr $applicant_email \
        -from_addr $actor_email \
        -subject [subst "[_ dotlrn-ecommerce.lt_A_space_has_opened_up]"] \
        -body [subst "[_ dotlrn-ecommerce.lt_A_space_has_opened_up_1]"]
} else {
    if {![dotlrn_community::send_member_email -community_id $community_id -to_user $user_id -type "on approval"]} {
        acs_mail_lite::send \
            -to_addr $applicant_email \
            -from_addr $actor_email \
            -subject [subst "[_ dotlrn-ecommerce.Application_approved]"] \
            -body [subst "[_ dotlrn-ecommerce.lt_Your_application_to_j]"]
    }
}
ad_returnredirect $return_url
}
}