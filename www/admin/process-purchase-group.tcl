# packages/dotlrn-ecommerce/www/admin/participant-purchase-group.tcl

ad_page_contract {
    
    Separate page for group purchase
    
    @author Roel Canicula (roelmc@pldtdsl.net)
    @creation-date 2005-08-16
    @arch-tag: 2df2c4c6-a1cc-4bc3-b62b-a26d1c9327bd
    @cvs-id $Id$
} {
    user_id:integer,notnull
    section_id:integer,notnull
    return_url:notnull
} -properties {
} -validate {
} -errors {
}

set available_slots [dotlrn_ecommerce::section::available_slots $section_id]

lappend validate {name
    { ! [empty_string_p $name] }
    "[_ dotlrn-ecommerce.lt_Please_enter_a_name_f]"
} {num_members
    { ! [empty_string_p $num_members] }
    "[_ dotlrn-ecommerce.lt_Please_enter_the_numb]"
} {num_members
    { $num_members <= $available_slots }
    "[subst [_ dotlrn-ecommerce.lt_The_course_only_has_a]]"
}

ad_form -name group_purchase -export { user_id section_id return_url } -validate $validate -form {
    {-section "Group Purchase"}
    {name:text,optional {label "Group Name"} {html {size 30}}}
    {num_members:integer(text),optional {label "Number of attendees"} {html {size 30}}}
    {gsubmit:text(submit) {label "[_ dotlrn-ecommerce.Continue]"}}
} -on_submit {
    set item_count 1
    set group_id [db_nextval acs_object_id_seq]
    set unique_group_name "${name}_${group_id}"

    db_1row product {
	select product_id
	from dotlrn_ecommerce_section
	where section_id = :section_id
    }

    # Test once then give up
    if { [db_string group {select 1 from groups where group_name = :unique_group_name} -default 0] } {
	set group_id [db_nextval acs_object_id_seq]
	set unique_group_name "${name}_${group_id}"
    }

    group::new -group_id $group_id -group_name $unique_group_name
    set section_community_id [db_string get_community_id "select community_id from dotlrn_ecommerce_section where section_id=:section_id" -default ""]
    if {[string equal "" $section_community_id]} {
	# FIXME error, do something clever here
    }
    for { set i 1 } { $i <= $num_members } { incr i } {
	array set new_user [auth::create_user \
				-username "${name} ${group_id} Attendee $i" \
				-email "[util_text_to_url -text ${name}-${group_id}-attendee-${i}]@mos.zill.net" \
				-first_names "$name" \
				-last_name "Attendee $i" \
				-nologin]
	
	if { [info exists new_user(user_id)] } {
	    relation_add -member_state approved membership_rel $group_id $new_user(user_id)
	} else {
	    ad_return_complaint 1 "There was a problem creating the account \"$name $group_id Attendee $i\"."
	    ad_script_abort
	}
    }
    relation_add relationship $group_id $section_community_id

    set participant_id $group_id
    set item_count $num_members

    ad_returnredirect [export_vars -base "../ecommerce/shopping-cart-add" { product_id user_id participant_id item_count return_url }]
    ad_script_abort
}