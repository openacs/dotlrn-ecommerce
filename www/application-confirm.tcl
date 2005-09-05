ad_page_contract {
} {
    {product_id:notnull}
    member_state:notnull
}

if { [db_0or1row get_name {
    select c.course_name||': '||s.section_name as section_name, s.community_id
    from dotlrn_ecommerce_section s, dotlrn_catalogi c, cr_items i
    where product_id = :product_id
          and c.item_id = s.course_id
    and i.live_revision = c.revision_id
}] } {

    set user_id [ad_conn user_id]
    
    if { ! [dotlrn::user_p -user_id $user_id] } {

	db_transaction {
	    # This is a newly created user and if this page is reached, that
	    # means a new user answered a course application and should be put
	    # on the approval list
	    dotlrn::user_add -user_id $user_id
	    
	    # Adding a user removes an existing entry in member_rels and
	    # creates a new one with the default member_state so set the
	    # proper member state here
	    if { [db_0or1row get_rel {
		select rel_id
		from dotlrn_member_rels_full
		where user_id = :user_id
		and community_id = :community_id
		limit 1
	    }] } {
		db_dml set_member_state {
		    update membership_rels
		    set member_state = :member_state
		    where rel_id = :rel_id
		}
	    }
	}
    }

} else {
    set section_name ""
}